#!/usr/bin/env python3
"""Fix UTF-8 Korean text corrupted by PowerShell default encoding."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP_DIRS = {
    "vendor",
    "node_modules",
    "dist",
    ".dart_tool",
    ".git",
    "build",
    ".gradle",
    "ephemeral",
}
EXTENSIONS = {
    ".md",
    ".dart",
    ".yaml",
    ".yml",
    ".json",
    ".ts",
    ".html",
    ".css",
    ".js",
    ".kt",
    ".xml",
    ".plist",
    ".kts",
    ".example",
    ".env.example",
    ".rc",
    ".cpp",
    ".cc",
    ".cmake",
    ".txt",
    ".xconfig",
    ".pbxproj",
    ".xcscheme",
    ".iml",
    ".prisma",
}

# Mojibake / replacement-char heuristics
CORRUPT_RE = re.compile(
    r"[\uFFFD]|"
    r"\?{2,}|"
    r"[\u0080-\u00ff]{3,}|"
    r"êµ|ìš|ë§|í˜|ì„|ë°|ìž|í•|ê°|ìƒ|ë¥|ìš|ì›|ìš|ìš"
)


def should_skip(path: Path) -> bool:
    parts = set(path.parts)
    if parts & SKIP_DIRS:
        return True
    if path.name.endswith(".plan.md"):
        return True
    return path.suffix.lower() not in EXTENSIONS and path.name != ".env.example"


def try_fix(text: str) -> str | None:
    for enc in ("latin-1", "cp1252"):
        try:
            fixed = text.encode(enc).decode("utf-8")
        except (UnicodeDecodeError, UnicodeEncodeError):
            continue
        if fixed != text and not CORRUPT_RE.search(fixed):
            return fixed
        # partial improvement: fewer replacement chars
        if fixed != text and fixed.count("\ufffd") + fixed.count("?") < text.count("\ufffd") + text.count("?"):
            return fixed
    return None


def fix_file(path: Path) -> bool:
    raw = path.read_bytes()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("utf-8", errors="replace")

    if not CORRUPT_RE.search(text):
        return False

    fixed = try_fix(text)
    if fixed is None:
        return False

    path.write_text(fixed, encoding="utf-8", newline="\n")
    return True


def main() -> int:
    changed: list[str] = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or should_skip(path):
            continue
        if fix_file(path):
            changed.append(str(path.relative_to(ROOT)))

    print(f"Fixed {len(changed)} files")
    for p in sorted(changed)[:50]:
        print(f"  {p}")
    if len(changed) > 50:
        print(f"  ... and {len(changed) - 50} more")
    return 0


if __name__ == "__main__":
    sys.exit(main())
