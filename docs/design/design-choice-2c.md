# 2C 디자인 선택 기록

| 항목 | 내용 |
|------|------|
| 일시 | 2026-05-20 |
| HUMAN 결정 | **Stitch 기반(2B)** 채택 |
| 근거 | 채팅 「스티치안이 좋아」 |
| 비교 대상 | 2A 자체 목업 [`mock-internal/`](../../mock-internal/) |
| 미채택 | 2A — 레이아웃·IA 참고용으로만 유지 |

## 선택안 SSOT

| 구분 | 값 |
|------|-----|
| Stitch 프로젝트 | **Moimday** |
| `projectId` | `5575514198874046733` |
| 디자인 시스템 | **Serene Kinship**, primary `#2B8C7E` |
| 핵심 화면 ID | S04 `ca239bac0a444e6ebbd177c4322a0801`, S07 `66301c45bc5943efb1ec87957a1a12bb`, S02 `9600d8a72fa4495f840a7835f7f7aa5d` |
| 상세 | [stitch-2b-track.md](./stitch-2b-track.md), [stitch-cli-workflow.md](./stitch-cli-workflow.md) |

## 구현 이관 원칙

- **제품 앱** 라우트·컴포넌트에 Stitch 톤·레이아웃을 반영한다. `mock-internal/`은 비교·회귀 참고만.
- PRD·[screen-spec-mvp.md](./screen-spec-mvp.md)·[ui-states-mvp.md](./ui-states-mvp.md)가 기능·상태의 SSOT이다. Stitch에만 있고 PRD에 없는 화면(장보기·할일 등)은 **구현하지 않는다**.
- S07은 Stitch 「가족 모임 일정 투표」를 기준으로 하되, PRD의 모임 상세·댓글·주최자 액션은 구현 단계에서 스펙에 맞게 보완한다.

## 승인 의미

`.cursor/rules/70-client-lifecycle-default.mdc`에 따라 **디자인 선택 = 구현 착수 승인**. 별도 「구현만 승인」은 요구하지 않는다.

## 다음 단계

1. [stage3-entry-checklist.md](../qa/stage3-entry-checklist.md) Gate 2·구현 경로 확정
2. 크로스플랫폼 스택 확정([ADR-0002](../decisions/0002-cross-platform-stack.md))
3. `parallel-delivery` — FE(앱 UI) + BE(API·푸시·OTP)
