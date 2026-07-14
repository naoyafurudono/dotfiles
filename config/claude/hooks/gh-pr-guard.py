#!/usr/bin/env python3
"""PreToolUse guard for `gh pr create` (and its alias `gh pr new`).

Policy enforced:
- `--draft` / `-d` is required.
- `--reviewer` / `-r` is forbidden.
- `--help` / `-h` invocations are passed through.

Reads Claude Code PreToolUse JSON on stdin. Exits 2 to block, 0 to allow.
"""
from __future__ import annotations

import json
import shlex
import sys


SEPARATORS = {"|", "||", "&&", ";", "&", "(", ")"}


def normalize_alias(tokens: list[str]) -> list[str]:
    """Treat `gh pr new` as `gh pr create`."""
    out = list(tokens)
    for i in range(2, len(out)):
        if out[i] == "new" and out[i - 1] == "pr" and out[i - 2] == "gh":
            out[i] = "create"
    return out


def find_invocations(tokens: list[str]):
    """Yield argument lists for each `gh pr create` invocation in a command line."""
    i = 0
    n = len(tokens)
    while i + 2 < n:
        if tokens[i] == "gh" and tokens[i + 1] == "pr" and tokens[i + 2] == "create":
            j = i + 3
            args: list[str] = []
            while j < n and tokens[j] not in SEPARATORS:
                args.append(tokens[j])
                j += 1
            yield args
            i = j
        else:
            i += 1


def evaluate(args: list[str]) -> list[str]:
    """Return human-readable violation messages for one invocation."""
    if any(a in {"--help", "-h"} for a in args):
        return []
    has_draft = any(a == "--draft" or a == "-d" for a in args)
    has_reviewer = any(
        a == "--reviewer" or a.startswith("--reviewer=") or a == "-r"
        for a in args
    )
    issues: list[str] = []
    if has_reviewer:
        issues.append(
            "BLOCKED: `gh pr create` で `--reviewer` / `-r` の指定は禁止です。"
            "レビュワーを指定せずに PR を作成してください。"
        )
    if not has_draft:
        issues.append(
            "BLOCKED: `gh pr create` には常に `--draft` / `-d` を付けてください。"
            "ready にするときは別途 `gh pr ready` を使います。"
        )
    return issues


def decide(command: str) -> tuple[int, list[str]]:
    """Decide exit code and stderr lines for a given shell command."""
    if "gh pr create" not in command and "gh pr new" not in command:
        return 0, []
    try:
        tokens = shlex.split(command, posix=True)
    except ValueError:
        return 0, []
    tokens = normalize_alias(tokens)

    seen: set[str] = set()
    messages: list[str] = []
    for args in find_invocations(tokens):
        for msg in evaluate(args):
            if msg not in seen:
                seen.add(msg)
                messages.append(msg)
    return (2 if messages else 0), messages


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    if payload.get("tool_name") != "Bash":
        return 0
    command = (payload.get("tool_input") or {}).get("command", "") or ""
    code, messages = decide(command)
    for line in messages:
        print(line, file=sys.stderr)
    return code


if __name__ == "__main__":
    sys.exit(main())
