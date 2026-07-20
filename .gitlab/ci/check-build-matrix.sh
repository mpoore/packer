#!/usr/bin/env bash
# Fails loudly if the static run_builds matrix in .gitlab-ci.yml and the
# actual vsphere/*/* build directories have drifted apart, in either
# direction. The matrix is deliberately not auto-generated (see
# .gitlab-ci.yml) - this is the safety net that catches a directory being
# added or removed without the matrix being updated to match.
set -euo pipefail

known="$(grep -oE '^[[:space:]]*- vsphere/[A-Za-z0-9_/]+' .gitlab-ci.yml | sed -E 's/^[[:space:]]*-[[:space:]]*//' | sort -u)"

actual="$(
    find vsphere -mindepth 2 -maxdepth 2 -type d ! -path 'vsphere/archive/*' | sort |
        while read -r dir; do
            name="$(basename "$dir")"
            [[ -f "${dir}/${name}.pkr.hcl" ]] && echo "$dir"
        done
)"

missing="$(comm -13 <(echo "$known") <(echo "$actual"))"
stale="$(comm -23 <(echo "$known") <(echo "$actual"))"

ok=1
if [[ -n "$missing" ]]; then
    ok=0
    echo "Build directories found on disk but missing from the run_builds matrix in .gitlab-ci.yml:"
    echo "$missing" | sed 's/^/  - /'
fi
if [[ -n "$stale" ]]; then
    ok=0
    echo "Matrix entries in .gitlab-ci.yml with no matching build directory on disk:"
    echo "$stale" | sed 's/^/  - /'
fi

if [[ "$ok" -eq 0 ]]; then
    echo
    echo "Update the run_builds matrix list in .gitlab-ci.yml to match."
    exit 1
fi

echo "Build matrix in .gitlab-ci.yml matches the vsphere/ directory tree."
