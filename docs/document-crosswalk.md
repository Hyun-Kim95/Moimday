# 문서 교차 참조 (Crosswalk)

**버전:** 0.1  
**목적:** PRD ↔ API ↔ 화면 ↔ 테스트 ↔ 정책 간 정합·SSOT 역할 명시

## SSOT 우선순위

1. **요구·정책·엣지** → [moimday-prd.md](./requirements/moimday-prd.md)
2. **API·데이터** → [api/api-contract-mvp.md](./api/api-contract-mvp.md) + [data-model.md](./api/data-model.md) (Gate 2)
3. **오류 code·메시지** → [api/error-catalog.md](./api/error-catalog.md)
4. **화면·상태 UI** → [design/screen-spec-mvp.md](./design/screen-spec-mvp.md) + [ui-states-mvp.md](./design/ui-states-mvp.md)
5. **검증** → [qa/mvp-test-plan.md](./qa/mvp-test-plan.md)

충돌 시: **PRD(정책)** > **API 계약(기술)** > 화면 스펙. 해결 후 [changelog](./changelog/) 기록.

---

## 기능 → 문서 매핑

| PRD | API (대표) | 화면 | 테스트 |
|-----|------------|------|--------|
| F1 OTP | `POST /auth/otp/*`, `PATCH /users/me` | S02 | T-F1-01~02 |
| F1 그룹 | `POST /groups`, `POST /invites/.../accept` | S03 | T-F1-03~06 |
| F2 홈 | `GET .../home` | S04 | T-F2-01 |
| F3 모임 | `POST/PATCH /events`, poll/attendance | S05~S08, S13~S14 | T-F3-* |
| F4 일정 | `GET .../calendar` | S09 | T-F4-01 |
| F5 알림 | `GET /notifications` | S10 | T-F5-01 |
| F6 댓글 | `GET/POST /events/.../comments` | S07 | T-F6-01 |

---

## 상태값 정합

| PRD §6 상태 | API `Event.status` | UI 칩(예) |
|-------------|-------------------|-----------|
| 날짜 투표 중 | `poll_open` | 투표 중 |
| 일시 확정됨 (UI) | `attendance_open` (초기) | 일시 확정 |
| 참석 수집 중 | `attendance_open` | 참석 받는 중 |
| 모임 확정 | `finalized` | 확정 |
| 취소 | `cancelled` | 취소됨 |

**fixed 모드:** 생성 직후 `attendance_open` (투표 단계 생략). [data-model.md](./api/data-model.md) §3.

---

## HTTP 메서드 정합 (v0.6)

| 동작 | 메서드 | 비고 |
|------|--------|------|
| 날짜 투표 제출 | `PUT /events/{id}/date-votes` | 멱등 upsert |
| 참석 응답 | `PUT /events/{id}/responses` | 멱등 upsert |
| 모임 수정 | `PATCH /events/{id}` | `If-Match: version` |

※ PRD §9 구 표기는 v0.6에서 API 문서와 동기화됨.

---

## 정책 ID → 구현 체크

| 정책 | API | UI | 테스트 |
|------|-----|-----|--------|
| P-E13 대상 스냅샷 | `targetMemberIds` at create | — | T-E-07 |
| P-E16 전 후보 투표 | `INCOMPLETE_POLL` | S08 | T-F3-03 |
| P-N10 리마인더 취소 | 서버 스케줄러 | — | T-E-05 |
| P-G7 관리자 이관 | `POST .../admin/transfer` | S11 | T-F1-07 |
| P-E11 마감 연장 | `POST .../extend-poll-deadline` | S07 | T-F3-08 |

전체: PRD §8, [glossary.md](./glossary.md)
