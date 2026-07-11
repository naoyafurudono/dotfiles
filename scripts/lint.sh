#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

find home scripts -type f \( -name '*.sh' -o -name '*.sh.tmpl' \) -print |
while IFS= read -r script; do
    if [ "${script%.tmpl}" != "$script" ]; then
        chezmoi --source "$repo_root/home" execute-template < "$script" | sh -n
    elif head -n 1 "$script" | grep -q 'bash'; then
        bash -n "$script"
    else
        sh -n "$script"
    fi
done

find home -type f -name '*.fish' -print |
while IFS= read -r script; do
    fish --no-execute "$script"
done

if command -v shellcheck >/dev/null 2>&1; then
    find home scripts -type f -name '*.sh' -print0 | xargs -0 shellcheck -o all
else
    echo "warning: shellcheck is not installed; skipped shellcheck" >&2
fi

git diff --check
