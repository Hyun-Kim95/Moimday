#!/usr/bin/env python3
"""Scan repo for broken Korean / UTF-8 encoding issues."""
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
    ".idea",
}
TEXT_EXT = {
    ".md", ".dart", ".ts", ".yaml", ".yml", ".json", ".html", ".css", ".js",
    ".kt", ".xml", ".plist", ".kts", ".example", ".prisma", ".rc", ".cpp",
    ".cc", ".cmake", ".txt", ".xconfig", ".pbxproj", ".xcscheme", ".iml",
    ".mdc", ".ps1", ".css", ".swift",
}


def should_scan(p: Path) -> bool:
    if any(s in p.parts for s in SKIP_DIRS):
        return False
    if p.suffix.lower() in TEXT_EXT or p.name in (".env.example", "README"):
        return True
    return False


def issues_for_text(text: str, path: str) -> list[str]:
    found = []
    if "\ufffd" in text:
        found.append("U+FFFD replacement char")
    # Broken UTF-8 saved as chars: common mojibake syllables without hangul nearby
    mojibake_re = re.compile(
        r"[êëìíîïðñòóôõöùúûüýþàáâãäåæçèé][\u0080-\u00bf]{2,}"
    )
    if mojibake_re.search(text):
        # exclude if file also has plenty of real hangul (might be false positive in code)
        hangul = sum(1 for c in text if "\uac00" <= c <= "\ud7a3")
        moji_hits = len(mojibake_re.findall(text))
        if moji_hits >= 2 or (moji_hits >= 1 and hangul < 5):
            found.append(f"mojibake-latin ({moji_hits} hits, hangul={hangul})")
    # PowerShell corruption: ? replacing multibyte
    if re.search(r"[\uac00-\ud7a3]\?[\uac00-\ud7a3]|[\uac00-\ud7a3]\?\?|^\| \?\?", text, re.M):
        found.append("hangul+? corruption")
    if "??" in text and path.endswith(".md"):
        lines = [ln for ln in text.splitlines() if "??" in ln and "http" not in ln]
        if lines and not all("??." in ln or "??? " in ln for ln in lines[:5]):
            # filter dart null coalescing in non-dart files
            if path.endswith(".md"):
                bad = [ln for ln in lines if not ln.strip().startswith("```")]
                if bad:
                    found.append(f"literal ?? in markdown ({len(bad)} lines)")
    # Orphan high bytes in comments/strings
    if re.search(r"\?{3,}", text) and path.endswith((".md", ".dart", ".html")):
        found.append("??? sequence")
    return found


def main() -> int:
    bad_files: list[tuple[str, list[str]]] = []
    invalid_utf8: list[str] = []

    for p in sorted(ROOT.rglob("*")):
        if not p.is_file() or not should_scan(p):
            continue
        rel = str(p.relative_to(ROOT))
        raw = p.read_bytes()
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError as e:
            invalid_utf8.append(f"{rel}: {e}")
            continue
        iss = issues_for_text(text, rel)
        if iss:
            bad_files.append((rel, iss))

    print("=== Invalid UTF-8 ===")
    for x in invalid_utf8:
        print(x)
    print(f"\n=== Suspect files ({len(bad_files)}) ===")
    for rel, iss in bad_files:
        print(f"{rel}: {', '.join(iss)}")

    # Also list files with low hangul in md but high ascii-latin mojibake
    return 1 if invalid_utf8 or bad_files else 0


if __name__ == "__main__":
    sys.exit(main())
