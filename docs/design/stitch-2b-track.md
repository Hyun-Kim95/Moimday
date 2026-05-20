# 2B Stitch 트랙 — 진행 메모

| 항목 | 내용 |
|------|------|
| 상태 | **2C 선택 완료** — Stitch 채택 → Stage 3 구현 |
| 워크플로 | [stitch-cli-workflow.md](./stitch-cli-workflow.md) |
| Kit MCP SOP (참고) | [stitch-sop.md](../../vendor/cursor-workspace-kit/docs/design/stitch-sop.md) |

## 인증 (CLI)

- `STITCH_API_KEY`: `~/.cursor/mcp.json` → `mcpServers.stitch.env.STITCH_API_KEY` (레포에 기록 금지)
- 점검: `npx -y stitch-design-cli doctor`

## Stitch CLI 순서

1. `stitch project create --title "Moimday" --json` (또는 기존 프로젝트 재사용)
2. 공통 스타일 블록을 각 프롬프트에 포함 (`stitch screen generate`, `--device-type MOBILE`)
3. `stitch screen list` / `get`으로 ID·URL 확인 후 아래 체크리스트 갱신

> 디자인 시스템은 CLI에 별도 명령이 없을 수 있어, MCP SOP의 `create_design_system` 단계는 **프롬프트 내 스타일 블록**으로 대체한다.

## 화면별 프롬프트 (복붙용)

### 공통 스타일 블록

```text
Moimday — Korean family scheduling app.
Style: warm, calm, trustworthy. Primary teal #2B8C7E. Rounded 12px cards.
Platform: mobile 390px. Korean labels.
States to consider: default (show default state in this screen).
Accessibility: clear button labels, no icon-only actions.
Dark mode capable. Minimal decoration.
```

### S04 홈

```text
[Attach common style block]
Screen: Home dashboard.
Sections: (1) "내가 할 일" cards with badges "투표 필요" and "참석 답변",
(2) "다가오는 확정 일정" list,
(3) "가족 미완료" showing names who have not voted/responded (non-judgmental).
Bottom tab bar: 홈, 모임, 일정, 알림, 설정.
```

### S07 모임 상세 (투표)

```text
[Attach common style block]
Screen: Event detail — date poll phase.
Header: event title, chip "날짜 투표 중", deadline.
CTA: "날짜 투표하기", link "투표 현황".
Section: pending family members avatars.
Organizer actions: "일시 확정", "독촉 보내기".
Comment thread at bottom.
```

### S02 OTP 로그인

```text
[Attach common style block]
Screen: Phone OTP login.
Fields: phone number, 6-digit OTP, checkbox 14+ age and terms.
Buttons: send OTP, confirm.
```

## 2B 실행 기록 (2026-05-20, CLI)

| 항목 | 값 |
|------|-----|
| `projectId` | `5575514198874046733` |
| 프로젝트 제목 | Moimday |
| 디자인 시스템 | **Serene Kinship** (프로젝트 `designTheme`, primary `#2B8C7E`) — CLI 별도 DS 명령 없음 |
| Stitch 웹 | 사용자 계정에서 프로젝트 **Moimday** 열람 (ID 위 참조) |

### PRD 대응 화면 (핵심 3종)

| 화면 | screenId | Stitch 제목(생성) | 비고 |
|------|----------|-------------------|------|
| **S04** 홈 | `ca239bac0a444e6ebbd177c4322a0801` | 홈 대시보드 | 1차 생성 시 장보기·할일 등 **PRD 외 화면 3종 추가** — 2C에서 범위 정리 |
| **S07** 모임 상세(투표) | `66301c45bc5943efb1ec87957a1a12bb` | 가족 모임 일정 투표 | `screen edit`로 프로필 화면 대체·보정 |
| **S02** OTP 로그인 | `9600d8a72fa4495f840a7835f7f7aa5d` | 휴대폰 OTP 로그인 | |

스크린샷·HTML은 `stitch screen get --include-html --include-image`로 재조회. (URL은 만료될 수 있음.)

### CLI 재현 예시

```powershell
$cfg = Get-Content "$env:USERPROFILE\.cursor\mcp.json" -Raw | ConvertFrom-Json
$env:STITCH_API_KEY = $cfg.mcpServers.stitch.env.STITCH_API_KEY
npx -y stitch-design-cli screen get --project-id 5575514198874046733 --screen-id ca239bac0a444e6ebbd177c4322a0801 --include-html --include-image --json
```

## 2B 완료 체크리스트

- [x] `projectId` 확정
- [x] 디자인 톤(프로젝트 DS) 적용
- [x] Screen IDs: S04, S07, S02
- [x] Stitch 웹 열람·선택 (HUMAN: 「스티치안이 좋아」)
- [x] 2C 정합·디자인 선택 — [design-choice-2c.md](./design-choice-2c.md)

## 2C 결과

- **선택:** Stitch 2B (Serene Kinship, `#2B8C7E`)
- **미선택:** 2A `mock-internal` (참고만)
- **구현 SSOT:** PRD + Stitch 토큰 [design-tokens-stitch.md](./design-tokens-stitch.md)
