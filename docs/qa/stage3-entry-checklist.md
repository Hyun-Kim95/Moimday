# Stage 3 Entry Checklist — Moimday

디자인 선택 이후 병렬 구현(Gate 2) 착수 전 체크리스트.  
템플릿: `vendor/cursor-workspace-kit/docs/qa/stage3-entry-checklist.md`

---

## 1) PRD 확정 여부

- [x] PRD 문서 경로: `docs/requirements/moimday-prd.md`
- [x] PRD 버전/최종 수정 시각: **v0.6 / 2026-05-20**
- [x] 문서 교차 참조: [document-crosswalk.md](../document-crosswalk.md), [consistency-audit.md](../consistency-audit.md)
- [x] 목표/핵심 흐름/범위(핵심·선택)/정책·예외/미확정 항목이 명시됨
- [x] 원본 요구사항과 PRD 간 불일치 항목이 정리됨 (부록 A·C·D)
- [x] **HUMAN PRD 승인** 완료 (승인 일시: **2026-05-20**, 채팅 「승인」)

## 2) 디자인 기준 확정 여부

- [x] 선택안: **`Stitch 기반` (2B)** — 2026-05-20, 채팅 「스티치안이 좋아」
- [x] 2A 산출: [`mock-internal/`](../../mock-internal/) · [mock-2a-report.md](../design/mock-2a-report.md) — 참고·회귀만
- [x] 2B 산출: [stitch-2b-track.md](../design/stitch-2b-track.md) · CLI [stitch-cli-workflow.md](../design/stitch-cli-workflow.md)
- [x] 선택 근거: [design-choice-2c.md](../design/design-choice-2c.md), 토큰 [design-tokens-stitch.md](../design/design-tokens-stitch.md)
- [x] `projectId` `5575514198874046733`, S04/S07/S02 screen ID — stitch-2b-track §2B 실행 기록
- [x] 주요 화면 S04·S07·S02 등 2A 반영 — [ui-states-mvp.md](../design/ui-states-mvp.md)
- [x] 앱 대상 범위: **iOS + Android** 동시
- [x] 2A 라이트/다크 토글 목업 (`mock-internal`)

## 3) Gate 2 진입 준비 (API + 상태 UI)

- [x] API 계약 **v1.0** — [api-contract-mvp.md](../api/api-contract-mvp.md), [openapi-mvp.yaml](../api/openapi-mvp.yaml)
- [x] 상태 UI — [ui-states-mvp.md](../design/ui-states-mvp.md), [event-status-ui.md](../api/event-status-ui.md)
- [x] Flutter 오류 처리 — [flutter-api-errors.md](../api/flutter-api-errors.md)
- [x] FE/BE 분할·통합 Owner: **메인 에이전트(Integration)**

| 트랙 | 담당 | 범위 |
|------|------|------|
| FE | frontend-agent | `apps/mobile` S01~S14 |
| BE | backend-agent | `services/api` REST·OTP·푸시·스케줄러 |
| 통합 | 메인 에이전트 | OpenAPI·E2E |

## 4) 리스크/오픈 이슈

| 이슈 | 대응 | 담당 | 기한 |
|------|------|------|------|
| 크로스플랫폼 스택 | [ADR-0002](../decisions/0002-cross-platform-stack.md) **Accepted Flutter** | — | 완료 |
| OpenAPI 미생성 | Gate 2에서 `api/openapi-mvp.yaml` | | |
| SMS/OTP 업체 선택 | PoC | | |

- [x] 미확정(제품·정책): 없음 (PRD §3.4)
- [ ] 담당자/기한 지정 완료

## 5) 승인 기록

- [x] 작성자: 에이전트(2C 기록)
- [ ] 검토자: (팀 정책 시)
- [x] 승인 상태: **디자인 선택 승인** (Stitch 2B)
- [x] 승인 코멘트: 「스티치안이 좋아」
- [x] 승인 일시: **2026-05-20**

## 6) 구현 착수 (목업 금지)

- [x] **제품 구현 대상 경로**: `apps/mobile/`, `services/api/`
- [x] **mock 전용 경로 사용:** `아니오`(기본)
- [x] Gate 2 확정 — `parallel-delivery` 진입
- [x] API 연동·상태 UI 1차 구현 (`apps/mobile`, `services/api`)
- [x] 검증 문서: [mvp-implementation-verification.md](./mvp-implementation-verification.md)
