#!/usr/bin/env bash
# Decides whether $1 (a build directory, e.g. vsphere/linux/rocky9) should
# be built for this pipeline. Exits 0 to build, 1 to skip.
#
# Scheduled pipelines always build everything. Push pipelines only build
# directories with changes since the previous commit on the branch - if
# the previous commit is unknown (e.g. first push on a new branch), the
# safe default is to build rather than silently skip.
set -euo pipefail

build_dir="$1"
zero_sha="0000000000000000000000000000000000000000"

[[ "${CI_PIPELINE_SOURCE:-}" == "schedule" ]] && exit 0

before="${CI_COMMIT_BEFORE_SHA:-$zero_sha}"

if [[ "$before" == "$zero_sha" ]] || ! git cat-file -e "${before}^{commit}" 2>/dev/null; then
    exit 0
fi

git diff --name-only "$before" "$CI_COMMIT_SHA" | grep -q "^${build_dir}/"
