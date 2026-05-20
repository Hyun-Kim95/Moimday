#!/usr/bin/env python3
"""Rebuild moimday-prd.md by replaying transcript edits on family-talk-prd.md."""
from __future__ import annotations

import json
import re
from pathlib import Path

TRANSCRIPT = (
    Path.home()
    / ".cursor/projects/d-cursor-familyTalk/agent-transcripts"
    / "ec7d43be-be87-4fd5-91c6-0195efe87be7"
    / "ec7d43be-be87-4fd5-91c6-0195efe87be7.jsonl"
)
OUT = Path(__file__).resolve().parents[1] / "docs/requirements/moimday-prd.md"
PRD_PATH = re.compile(r"family-talk-prd\.md", re.I)


def moimday_patch(text: str) -> str:
    text = text.replace("# FamilyTalk PRD", "# Moimday PRD")
    text = text.replace("FamilyTalk", "Moimday")
    text = text.replace("familytalk://", "moimday://")
    text = text.replace("family-talk-prd.md", "moimday-prd.md")
    text = text.replace("family-talk", "moimday")
    text = text.replace("familytalk", "moimday")
    text = text.replace("가족톡", "Moimday")
    return text


def main() -> None:
    content: str | None = None

    with TRANSCRIPT.open(encoding="utf-8") as f:
        for line in f:
            obj = json.loads(line)
            for part in obj.get("message", {}).get("content", []):
                if part.get("type") != "tool_use":
                    continue
                inp = part.get("input", {})
                path = inp.get("path", "")
                if not PRD_PATH.search(path):
                    continue
                if part.get("name") == "Write":
                    content = inp.get("contents")
                elif part.get("name") == "StrReplace" and content:
                    old = inp.get("old_string")
                    new = inp.get("new_string")
                    if old and new and old in content:
                        content = content.replace(old, new, 1)

    if not content:
        raise SystemExit("PRD content not found in transcript")

    OUT.write_text(moimday_patch(content), encoding="utf-8")
    t = OUT.read_text(encoding="utf-8")
    hangul = sum(1 for c in t if "\uac00" <= c <= "\ud7a3")
    print(f"Wrote {OUT} ({len(t)} chars, {hangul} hangul syllables)")


if __name__ == "__main__":
    main()
