#!/usr/bin/env bash
# Discovers vsphere/*/* packer build directories and emits a child-pipeline
# YAML that builds all of them (scheduled pipelines) or only the ones with
# changed files (push pipelines). Concurrency is capped by the runner, not
# this script.
set -euo pipefail

ZERO_SHA="0000000000000000000000000000000000000000"

discover_build_dirs() {
    find vsphere -mindepth 2 -maxdepth 2 -type d ! -path 'vsphere/archive/*' | sort |
        while read -r dir; do
            name="$(basename "$dir")"
            if [[ -f "${dir}/${name}.pkr.hcl" ]]; then
                echo "$dir"
            fi
        done
}

changed_build_dirs() {
    local before="${CI_COMMIT_BEFORE_SHA:-$ZERO_SHA}"
    local after="${CI_COMMIT_SHA:?CI_COMMIT_SHA is required}"

    if [[ "$before" == "$ZERO_SHA" ]] || ! git cat-file -e "${before}^{commit}" 2>/dev/null; then
        # New branch / unknown parent (e.g. first push) - safest default is
        # to build everything rather than silently building nothing.
        discover_build_dirs
        return
    fi

    local changed_files
    changed_files="$(git diff --name-only "${before}" "${after}")"

    discover_build_dirs | while read -r dir; do
        if grep -q "^${dir}/" <<<"$changed_files"; then
            echo "$dir"
        fi
    done
}

build_list_file="$(mktemp)"
trap 'rm -f "$build_list_file"' EXIT

if [[ "${CI_PIPELINE_SOURCE:-}" == "schedule" ]]; then
    discover_build_dirs > "$build_list_file"
else
    changed_build_dirs > "$build_list_file"
fi

cat <<'EOF'
stages:
  - build

EOF

# Inlined rather than pulled in via `include: local:` - dynamic child
# pipelines (config sourced from a job artifact) have version-dependent
# rough edges with nested local includes, so the job template is embedded
# directly to keep the generated pipeline fully self-contained.
cat .gitlab/ci/packer-build.yml
echo

if [[ ! -s "$build_list_file" ]]; then
    cat <<'EOF'
no_builds:
  stage: build
  image: alpine:latest
  script:
    - echo "No packer build changes detected - nothing to do."
EOF
    exit 0
fi

while read -r dir; do
    name="$(basename "$dir")"
    cat <<EOF
build:${name}:
  extends: .packer_build
  variables:
    BUILD: "${dir}"

EOF
done < "$build_list_file"