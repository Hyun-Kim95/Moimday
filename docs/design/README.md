# Design 문서

UI·UX 스펙 및 목업 단계 안내입니다.

| 문서 | 설명 | 상태 |
|------|------|------|
| [screen-spec-mvp.md](./screen-spec-mvp.md) | 화면 ID·진입·핵심 동작 | 목업 착수용 |
| [ui-states-mvp.md](./ui-states-mvp.md) | 화면별 상태 UI 매트릭스 (v0.2) | Gate 2 초안 |
| [push-notification-mvp.md](./push-notification-mvp.md) | FCM/APNs·딥링크 | Gate 2 초안 |
| [mock-2a-report.md](./mock-2a-report.md) | **2A 자체 목업** 산출 | **완료** |
| [stitch-2b-track.md](./stitch-2b-track.md) | **2B Stitch** 진행·프롬프트 | 2C 선택 완료 |
| [design-choice-2c.md](./design-choice-2c.md) | **2C** 디자인 선택 기록 | Stitch 채택 |
| [design-tokens-stitch.md](./design-tokens-stitch.md) | Stitch → 앱 토큰 | Stage 3 SSOT |
| [stitch-cli-workflow.md](./stitch-cli-workflow.md) | **2B CLI** 인증·명령 매핑 | 참고 |

**근거 PRD:** §7, §8.7, product-ui-core

## 목업 단계 (PRD 승인 후)

### 2A 실행

```bash
npx --yes serve mock-internal -p 5173
```

경로: [`mock-internal/`](../../mock-internal/)

### 2B

`stitch-design-cli` + `~/.cursor/mcp.json`의 `STITCH_API_KEY`로 [stitch-cli-workflow.md](./stitch-cli-workflow.md) · [stitch-2b-track.md](./stitch-2b-track.md) 순서 진행.

## 2C · 디자인 선택

- **결정(2026-05-20):** **Stitch(2B)** — [design-choice-2c.md](./design-choice-2c.md)
- 다음: Gate 2 확정 → 제품 앱 구현 (`parallel-delivery`)
