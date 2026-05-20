#!/usr/bin/env python3
"""Restore file contents from agent transcript Write/StrReplace (pre-encoding corruption)."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRANSCRIPT = (
    Path.home()
    / ".cursor/projects/d-cursor-familyTalk/agent-transcripts"
    / "ec7d43be-be87-4fd5-91c6-0195efe87be7"
    / "ec7d43be-be87-4fd5-91c6-0195efe87be7.jsonl"
)

PATH_RE = re.compile(r"d:\\cursor\\familyTalk\\(.+)", re.I)
CORRUPT_HINT = re.compile(r"[\u0080-\u00ff]{2,}|\?{2,}|\ufffd")


def normalize_path(p: str) -> Path:
    p = p.replace("\\", "/")
    if p.startswith("familyTalk/"):
        p = p.split("/", 1)[1]
    return ROOT / p


def moimday_patch(text: str, rel: str) -> str:
    text = text.replace("FamilyTalk", "Moimday")
    text = text.replace("familytalk://", "moimday://")
    text = text.replace("familytalk_mobile", "moimday_mobile")
    text = text.replace("family-talk-prd.md", "moimday-prd.md")
    text = text.replace("family-talk", "moimday")
    text = text.replace("familytalk", "moimday")
    text = text.replace("com.familytalk", "com.moimday")
    return text


def is_corrupted(path: Path) -> bool:
    if not path.is_file():
        return False
    raw = path.read_bytes()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        return True
    return bool(CORRUPT_HINT.search(text))


def main() -> int:
    if not TRANSCRIPT.exists():
        print("Transcript not found:", TRANSCRIPT, file=sys.stderr)
        return 1

    latest: dict[str, str] = {}

    with TRANSCRIPT.open(encoding="utf-8") as f:
        for line in f:
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            msg = obj.get("message", {})
            for part in msg.get("content", []):
                if part.get("type") != "tool_use":
                    continue
                name = part.get("name")
                if name not in ("Write", "StrReplace"):
                    continue
                inp = part.get("input", {})
                path_raw = inp.get("path", "")
                m = PATH_RE.search(path_raw)
                if not m:
                    continue
                rel = m.group(1).replace("\\", "/")
                if name == "Write":
                    contents = inp.get("contents")
                    if contents:
                        latest[rel] = contents
                elif name == "StrReplace":
                    old = rel
                    if rel not in latest:
                        # try read current from disk at restore time
                        disk = ROOT / rel
                        if disk.exists():
                            try:
                                latest[rel] = disk.read_text(encoding="utf-8", errors="replace")
                            except OSError:
                                continue
                        else:
                            continue
                    new_string = inp.get("new_string")
                    old_string = inp.get("old_string")
                    if new_string is not None and old_string is not None:
                        if old_string in latest[rel]:
                            latest[rel] = latest[rel].replace(old_string, new_string, 1)

    restored = []
    skipped = []
    for rel, content in sorted(latest.items()):
        target = ROOT / rel
        if not target.exists():
            continue
        if not is_corrupted(target):
            continue
        # only restore text-like sources we care about
        if target.suffix.lower() not in {
            ".md", ".dart", ".ts", ".yaml", ".yml", ".html", ".json", ".js", ".css", ".kt", ".xml", ".plist", ".kts", ".example", ".prisma"
        } and target.name != ".env.example":
            continue
        patched = moimday_patch(content, rel)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(patched, encoding="utf-8")
        restored.append(rel)

    print(f"Restored {len(restored)} files from transcript")
    for r in restored[:60]:
        print(f"  {r}")
    if len(restored) > 60:
        print(f"  ... +{len(restored) - 60} more")

    still_bad = []
    for rel in restored:
        if is_corrupted(ROOT / rel):
            still_bad.append(rel)
    if still_bad:
        print(f"Still corrupted after restore: {len(still_bad)}")
        for r in still_bad[:20]:
            print(f"  {r}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
