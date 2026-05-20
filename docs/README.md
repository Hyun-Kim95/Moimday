# Moimday 문서 허브

가족 일정·모임 조율 앱 **Moimday** 프로젝트 문서입니다.

## SSOT (단일 출처)

| 문서 | 역할 |
|------|------|
| [requirements/moimday-prd.md](./requirements/moimday-prd.md) | 제품 PRD **v0.6** (요구·정책·범위) |
| [document-crosswalk.md](./document-crosswalk.md) | PRD↔API↔화면↔테스트 매핑 |
| [consistency-audit.md](./consistency-audit.md) | 문서 정합성 점검 기록 |

PRD와 하위 문서가 충돌하면 **PRD 우선**. API·화면 세부는 Gate 2 확정 시 본 문서 세트를 갱신한다.

## 문서 맵

```
docs/
├── README.md                 ← 이 파일
├── requirements/             요구사항
│   ├── moimday-prd.md
│   └── README.md
├── document-crosswalk.md     교차 참조·SSOT 우선순위
├── consistency-audit.md      정합성 점검 기록
├── glossary.md               용어집
├── api/                      API·데이터 계약 (Gate 2 초안)
│   ├── README.md
│   ├── api-contract-mvp.md
│   ├── data-model.md
│   └── error-catalog.md
├── design/                   화면·UX (목업 전 스펙)
│   ├── README.md
│   ├── screen-spec-mvp.md
│   ├── ui-states-mvp.md
│   └── push-notification-mvp.md
├── legal/                    약관·개인정보 (플레이스홀더)
│   └── README.md
├── qa/                       검증·체크리스트
│   ├── README.md
│   ├── mvp-test-plan.md
│   └── stage3-entry-checklist.md
├── decisions/                의사결정 기록 (ADR)
│   ├── README.md
│   ├── 0001-mvp-product-decisions.md
│   └── 0002-cross-platform-stack.md
└── changelog/                변경 이력
    ├── README.md
    └── 2026-05-20-initial-doc-set.md
```

## 현재 단계

| 단계 | 상태 | 다음 산출 |
|------|------|-----------|
| Gate 1 (PRD) | v0.6 **승인 완료** (2026-05-20) | — |
| 단계 2A (자체 목업) | **완료** | [`mock-internal/`](./mock-internal/) · [mock-2a-report](design/mock-2a-report.md) |
| 단계 2B (Stitch) | **완료** (CLI) | [stitch-2b-track](design/stitch-2b-track.md) |
| 단계 2C (정합·선택) | **Stitch 선택** | [design-choice-2c](design/design-choice-2c.md) |
| Gate 2 (API·상태 UI) | 초안 → **확정 착수** | [stage3-entry-checklist](qa/stage3-entry-checklist.md) |
| Stage 3 (제품 구현) | **1차 구현 완료** | [README](../README.md), `apps/mobile`, `services/api` |

## 빠른 링크

- 정책·엣지케이스: PRD §8
- API 엔드포인트: [api/api-contract-mvp.md](./api/api-contract-mvp.md)
- 화면 ID·상태: [design/screen-spec-mvp.md](./design/screen-spec-mvp.md)
- MVP 테스트: [qa/mvp-test-plan.md](./qa/mvp-test-plan.md)
