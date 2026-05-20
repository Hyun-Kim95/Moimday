#!/usr/bin/env python3
"""Fix UTF-8 text that was mis-decoded as Latin-1/CP1252 and re-saved as UTF-8."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP_DIRS = {"vendor", "node_modules", "dist", ".dart_tool", ".git", "build", ".gradle", "ephemeral", ".idea"}
EXT = {
    ".md", ".html", ".dart", ".yaml", ".yml", ".ts", ".json", ".css", ".js",
    ".plist", ".kt", ".kts", ".example", ".prisma", ".mdc",
}

MOJI_RE = re.compile(r"[êëìíîïðñòóùúàáâãäåæçèé][\u0080-\u00ff]{1,3}")


def try_unmojibake(text: str) -> str | None:
    for enc in ("latin-1", "cp1252"):
        try:
            fixed = text.encode(enc).decode("utf-8")
        except (UnicodeDecodeError, UnicodeEncodeError):
            continue
        if fixed == text:
            continue
        h0 = sum(1 for c in text if "\uac00" <= c <= "\ud7a3")
        h1 = sum(1 for c in fixed if "\uac00" <= c <= "\ud7a3")
        m0 = len(MOJI_RE.findall(text))
        m1 = len(MOJI_RE.findall(fixed))
        if h1 > h0 or (m1 < m0 and h1 >= h0):
            return fixed
    return None


def main() -> int:
    changed = []
    for p in sorted(ROOT.rglob("*")):
        if not p.is_file() or any(s in p.parts for s in SKIP_DIRS):
            continue
        if p.suffix.lower() not in EXT and p.name != "README":
            continue
        raw = p.read_bytes()
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError:
            continue
        if not MOJI_RE.search(text):
            continue
        fixed = try_unmojibake(text)
        if fixed:
            p.write_text(fixed, encoding="utf-8")
            changed.append(str(p.relative_to(ROOT)))

    print(f"Unmojibake fixed: {len(changed)}")
    for c in changed:
        print(f"  {c}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
