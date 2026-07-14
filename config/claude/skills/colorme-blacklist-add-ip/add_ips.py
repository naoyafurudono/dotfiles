#!/usr/bin/env python3
"""colorme-www app/configs/blacklist.yml に IPv4 を追加する補助スクリプト。

使い方:
  add_ips.py --check IP [IP ...]
  add_ips.py --apply IP [IP ...]
  add_ips.py [--file PATH] ...   # 対象 yml を上書き指定（既定: カレントの app/configs/blacklist.yml）

出力:
  --check: 標準出力に JSON で {valid: [...], invalid: [...], duplicate: [...], new: [...]}
  --apply: 上記に加えてファイルを書き換え、終了コード 0
"""
from __future__ import annotations

import argparse
import ipaddress
import json
import re
import sys
from pathlib import Path

DEFAULT_PATH = Path("app/configs/blacklist.yml")


def parse_yaml(text: str) -> tuple[list[str], list[str], list[str]]:
    """blacklist.yml を email セクションと ip セクションに分けて返す。

    Returns: (email_entries, ip_entries, header_lines)
    header_lines は最初の `email:` 行までを含めた前置き（通常空）。
    フォーマットが複雑な YAML は対象外。`email:` `ip:` の 2 セクションのみ想定。
    """
    lines = text.splitlines()
    email: list[str] = []
    ips: list[str] = []
    section: str | None = None
    for line in lines:
        if line.strip() == "email:":
            section = "email"
            continue
        if line.strip() == "ip:":
            section = "ip"
            continue
        m = re.match(r"^\s*-\s+(.+?)\s*$", line)
        if not m:
            continue
        value = m.group(1)
        if section == "email":
            email.append(value)
        elif section == "ip":
            ips.append(value)
    return email, ips, []


def render_yaml(emails: list[str], ips: list[str]) -> str:
    out = ["email:"]
    for e in emails:
        out.append(f"  - {e}")
    out.append("ip:")
    for ip in ips:
        out.append(f"  - {ip}")
    return "\n".join(out) + "\n"


def is_valid_ipv4(ip: str) -> bool:
    try:
        addr = ipaddress.IPv4Address(ip)
        return not (addr.is_private or addr.is_loopback or addr.is_link_local or addr.is_multicast or addr.is_unspecified)
    except ValueError:
        return False


def main() -> int:
    p = argparse.ArgumentParser()
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--check", action="store_true")
    g.add_argument("--apply", action="store_true")
    p.add_argument("--file", default=str(DEFAULT_PATH))
    p.add_argument("ips", nargs="+")
    args = p.parse_args()

    raw_inputs: list[str] = []
    for token in args.ips:
        for piece in re.split(r"[\s,]+", token):
            if piece:
                raw_inputs.append(piece)

    valid: list[str] = []
    invalid: list[str] = []
    seen: set[str] = set()
    for ip in raw_inputs:
        if ip in seen:
            continue
        seen.add(ip)
        if is_valid_ipv4(ip):
            valid.append(ip)
        else:
            invalid.append(ip)

    target = Path(args.file)
    if not target.exists():
        print(f"file not found: {target}", file=sys.stderr)
        return 2

    text = target.read_text(encoding="utf-8")
    emails, existing_ips, _ = parse_yaml(text)
    existing_set = set(existing_ips)
    duplicate = [ip for ip in valid if ip in existing_set]
    new = [ip for ip in valid if ip not in existing_set]

    report = {
        "file": str(target),
        "valid": valid,
        "invalid": invalid,
        "duplicate": duplicate,
        "new": new,
        "count_existing": len(existing_ips),
    }

    if args.check:
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return 0 if not invalid else 1

    # --apply
    if invalid:
        print(json.dumps(report, indent=2, ensure_ascii=False), file=sys.stderr)
        print("invalid IPs present; aborting", file=sys.stderr)
        return 1
    if not new:
        print(json.dumps(report, indent=2, ensure_ascii=False))
        print("nothing to add", file=sys.stderr)
        return 0

    merged = sorted(set(existing_ips) | set(new))
    target.write_text(render_yaml(emails, merged), encoding="utf-8")
    report["count_after"] = len(merged)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
