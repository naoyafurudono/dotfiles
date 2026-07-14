#!/bin/sh

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "${repo_root}"

find config scripts -type f -name '*.sh' -print |
while IFS= read -r script; do
    if head -n 1 "${script}" | grep -q 'bash'; then
        bash -n "${script}"
    else
        sh -n "${script}"
    fi
done

find config -type f -name '*.fish' -print |
while IFS= read -r script; do
    fish --no-execute "${script}"
done

if command -v shellcheck >/dev/null 2>&1; then
    find config scripts -type f -name '*.sh' -print0 | xargs -0 shellcheck -o all
else
    echo "warning: shellcheck is not installed; skipped shellcheck" >&2
fi

git diff --check
