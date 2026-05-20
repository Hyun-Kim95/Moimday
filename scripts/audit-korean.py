#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SKIP = {"vendor", "node_modules", "dist", ".dart_tool", ".git", "build", ".gradle", "ephemeral", ".idea"}
EXT = {".md", ".html", ".dart", ".yaml", ".yml", ".ts", ".json", ".css", ".js", ".plist", ".kt", ".example", ".prisma", ".mdc"}

# UTF-8 Korean misread as Latin-1 then saved: contains these without enough hangul
MOJI_CHARS = set("êëìíîïðñòóùúàáâãäåæçèé")
MOJI_RE = re.compile(r"[êëìíîïðñòóùúàáâãäåæçèé]{2,}")


def audit(path: Path) -> list[str]:
    raw = path.read_bytes()
    issues = []
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        return ["invalid-utf-8"]

    hangul = sum(1 for c in text if "\uac00" <= c <= "\ud7a3")
    moji = len(MOJI_RE.findall(text))
    if moji >= 2 and hangul < moji * 3:
        issues.append(f"mojibake-utf8 ({moji} spans, hangul={hangul})")
    if "\ufffd" in text:
        issues.append("replacement-char")

    if path.suffix == ".md" or path.name == "README":
        for i, line in enumerate(text.splitlines(), 1):
            if line.count("?") >= 4 and "http" not in line and "string?" not in line:
                if "??" in line:
                    issues.append(f"line{i}-qmarks: {line[:60]}")
                    break

    return issues


def main():
    bad = []
    for p in sorted(ROOT.rglob("*")):
        if not p.is_file() or any(s in p.parts for s in SKIP):
            continue
        if p.suffix.lower() not in EXT and p.name != "README":
            continue
        iss = audit(p)
        if iss:
            bad.append((str(p.relative_to(ROOT)), iss))

    print(f"Problems: {len(bad)}")
    for rel, iss in bad:
        print(f"  {rel}: {', '.join(iss)}")


if __name__ == "__main__":
    main()
