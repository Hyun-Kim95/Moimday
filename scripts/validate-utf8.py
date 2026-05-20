#!/usr/bin/env python3
"""Validate all git-tracked text files decode as UTF-8."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BINARY_EXT = {".png", ".ico", ".jpg", ".jpeg", ".gif", ".webp", ".woff", ".woff2", ".ttf", ".eot", ".db", ".jar", ".bin", ".pdf"}


def main() -> int:
    out = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True)
    bad = []
    for rel in out.splitlines():
        if not rel:
            continue
        p = ROOT / rel
        if not p.is_file():
            continue
        if p.suffix.lower() in BINARY_EXT:
            continue
        try:
            p.read_bytes().decode("utf-8")
        except UnicodeDecodeError as e:
            bad.append((rel, str(e)))
    if bad:
        print("Invalid UTF-8 in git-tracked files:")
        for rel, err in bad:
            print(f"  {rel}: {err}")
        return 1
    print(f"OK: {len(out.splitlines())} tracked paths checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
