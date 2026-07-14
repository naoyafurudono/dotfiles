#!/usr/bin/env python3
"""Claude Code PreToolUse hook: 危険な Bash コマンドをブロックする。

settings.json の permissions.deny はプレフィックスマッチのため、
`git push origin main --force` のような語順ではすり抜ける。
この hook はトークン単位で判定することでそれを防ぐ（deny リストとの二段構え）。

ルール:
- gh --admin の禁止（旧インライン hook を移設）
- git push の force 系オプション禁止（--force / -f / --force-with-lease / +refspec）
- kubectl の変更系サブコマンド禁止
- argo の変更系サブコマンド禁止

外部アップロードサービスのブロックは managed 側の
/usr/local/share/claude-hooks/block-external-upload.sh が担う（ここでは重複させない）。

ブロック時: exit 2 + stderr にメッセージ（Claude Code がツール実行を中止する）
"""

import json
import re
import shlex
import sys

GIT_FORCE_TOKENS = {"--force", "-f", "--force-with-lease"}

KUBECTL_MUTATING_VERBS = {
    "delete", "apply", "create", "edit", "patch", "replace", "scale",
    "rollout", "exec", "port-forward", "proxy", "drain", "cordon",
    "uncordon", "taint", "run", "debug", "set", "attach", "cp",
    "annotate", "label",
}
KUBECTL_MUTATING_CONFIG_SUBS = {
    "use-context", "set-context", "delete-context", "rename-context",
    "set", "unset",
}
# 値を取るフラグ（次のトークンを verb と誤認しないためスキップする）
KUBECTL_VALUE_FLAGS = {
    "--context", "--namespace", "-n", "--kubeconfig", "--cluster",
    "--user", "-s", "--server",
}

ARGO_MUTATING_VERBS = {
    "submit", "delete", "retry", "resubmit", "terminate", "stop",
    "suspend", "resume",
}
ARGO_MUTATING_SUBS = {  # argo cron / argo template のサブコマンド
    "create", "delete", "suspend", "resume",
}

WRAPPER_COMMANDS = {"env", "command", "nohup", "sudo", "time"}


def split_segments(cmd: str) -> list[str]:
    """シェルの区切り（; && || | & 改行）でコマンドを分割する。"""
    return [s for s in re.split(r"(?<!>)[;&|]+|\n", cmd) if s.strip()]


def tokenize(segment: str) -> list[str]:
    try:
        return shlex.split(segment, posix=True)
    except ValueError:
        return segment.split()


def strip_wrappers(tokens: list[str]) -> list[str]:
    """env VAR=x / command / sudo / timeout N 等のラッパを剥がす。"""
    i = 0
    while i < len(tokens):
        t = tokens[i]
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
            i += 1
        elif t in WRAPPER_COMMANDS:
            i += 1
        elif t == "timeout" and i + 1 < len(tokens):
            i += 2  # timeout <duration>
        else:
            break
    return tokens[i:]


def first_verb(args: list[str], value_flags: set[str]) -> tuple[str, list[str]]:
    """フラグをスキップして最初のサブコマンドと残りを返す。"""
    i = 0
    while i < len(args):
        t = args[i]
        if t.startswith("-"):
            if t in value_flags and "=" not in t:
                i += 2
            else:
                i += 1
        else:
            return t, args[i + 1:]
    return "", []


def check_git(args: list[str]) -> str | None:
    if "push" not in args:
        return None
    push_args = args[args.index("push"):]
    for t in push_args:
        if t in GIT_FORCE_TOKENS or t.startswith("--force-with-lease="):
            return f"git push の force 系オプション ({t}) は禁止されています"
        if re.match(r"^\+\S", t):
            return f"git push の +refspec ({t}) は force push のため禁止されています"
    return None


def check_kubectl(args: list[str]) -> str | None:
    verb, rest = first_verb(args, KUBECTL_VALUE_FLAGS)
    if verb == "config":
        sub, _ = first_verb(rest, KUBECTL_VALUE_FLAGS)
        if sub in KUBECTL_MUTATING_CONFIG_SUBS:
            return f"kubectl config {sub} は禁止されています"
    elif verb in KUBECTL_MUTATING_VERBS:
        return f"kubectl {verb} は禁止されています（参照系のみ許可）"
    return None


def check_argo(args: list[str]) -> str | None:
    verb, rest = first_verb(args, set())
    if verb in ARGO_MUTATING_VERBS:
        return f"argo {verb} は禁止されています（参照系のみ許可）"
    if verb in ("cron", "template"):
        sub, _ = first_verb(rest, set())
        if sub in ARGO_MUTATING_SUBS:
            return f"argo {verb} {sub} は禁止されています（参照系のみ許可）"
    return None


def check_gh(args: list[str]) -> str | None:
    if "--admin" in args:
        return "gh コマンドの --admin オプションはセキュリティポリシーにより禁止されています"
    return None


CHECKERS = {"git": check_git, "kubectl": check_kubectl, "argo": check_argo, "gh": check_gh}


def check_command(cmd: str) -> str | None:
    for segment in split_segments(cmd):
        tokens = strip_wrappers(tokenize(segment))
        # xargs 経由等も拾うため、対象プログラム名のトークン位置から判定する
        for i, t in enumerate(tokens):
            prog = t.rsplit("/", 1)[-1]
            if prog in CHECKERS:
                reason = CHECKERS[prog](tokens[i + 1:])
                if reason:
                    return reason
    return None


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0
    cmd = (payload.get("tool_input") or {}).get("command") or ""
    if not cmd:
        return 0
    reason = check_command(cmd)
    if reason:
        print(f"BLOCKED: {reason}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
