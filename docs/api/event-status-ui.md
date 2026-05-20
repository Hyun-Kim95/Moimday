# Event.status ↔ UI 매핑 (Gate 2 SSOT)

**버전:** 1.0  
**근거:** [data-model.md](./data-model.md) §3, [screen-spec-mvp.md](../design/screen-spec-mvp.md) S07

## 상태 enum

| status | 한국어 칩 | 설명 |
|--------|-----------|------|
| `poll_open` | 날짜 투표 중 | 후보 투표 수집 |
| `attendance_open` | 일시 확정 · 참석 답변 | `confirmedStartsAt` 설정됨 |
| `finalized` | 모임 확정 | 캘린더 노출 |
| `cancelled` | 취소됨 | 읽기 전용 |

## S07 CTA 매핑

| status | 일반 구성원 | 모임 생성자 |
|--------|-------------|-------------|
| `poll_open` | `날짜 투표하기` → S08 poll | `일시 확정` S14, `투표 마감 연장`, `독촉 보내기`, `투표 현황` S13 |
| `attendance_open` | `참석 답변하기` → S08 attend | `모임 확정`, `독촉 보내기`, 편집(제목·장소·메모) |
| `finalized` | 조회만 | 조회만 |
| `cancelled` | 읽기 전용 + 칩 | — |

## mode 분기

| mode | 생성 직후 status |
|------|------------------|
| `poll` | `poll_open` |
| `fixed` | `attendance_open` (P-E9) |

## API 전이

| 액션 | endpoint | from → to |
|------|----------|-----------|
| 일시 확정 | `POST .../confirm-datetime` | `poll_open` → `attendance_open` |
| 모임 확정 | `POST .../finalize` | `attendance_open` → `finalized` |
| 취소 | `POST .../cancel` | * → `cancelled` |

## Flutter

- `EventStatusChip(status)` — 칩 라벨
- `EventDetailActions` — status·isOrganizer 기반 CTA
