# 데이터 모델 (MVP)

**버전:** 0.2 (교차 점검 반영)  
**근거:** [moimday-prd.md](../requirements/moimday-prd.md) §9, §8.2~8.3

---

## 1. 엔티티 관계 (개요)

```
User 1──* Membership *──1 FamilyGroup
User 1──* Event (as organizerId)
FamilyGroup 1──* Event
Event 1──* DateOption (poll mode)
Event 1──* DateVote
Event 1──* EventResponse
Event 1──* Comment
User 1──* Notification
```

---

## 2. 엔티티

### User
| 필드 | 타입 | 비고 |
|------|------|------|
| id | UUID | |
| phoneE164 | string | KR 휴대폰, unique |
| displayName | string | 1~20자 |
| avatarUrl | string? | |
| autoReminderEnabled | boolean | default true (P-N6) |
| ageConfirmedAt | datetime | 만 14세 이상 (P-E5) |
| createdAt | datetime | |

### FamilyGroup
| 필드 | 타입 | 비고 |
|------|------|------|
| id | UUID | |
| name | string | 예: "우리 가족" |
| adminUserId | UUID | 그룹 생성자 |
| memberCount | int | max 10 |
| createdAt | datetime | |

### Membership
| 필드 | 타입 | 비고 |
|------|------|------|
| id | UUID | |
| groupId | UUID | |
| userId | UUID | |
| nickname | string? | 그룹 내 호칭 |
| joinedAt | datetime | |

### Invite
| 필드 | 타입 | 비고 |
|------|------|------|
| id | UUID | |
| groupId | UUID | |
| token | string | URL token |
| expiresAt | datetime | +7일 (P-G5) |
| revokedAt | datetime? | 재발급 시 |
| status | enum | `pending` \| `expired` \| `revoked` |

### Event
| 필드 | 타입 | 비고 |
|------|------|------|
| id | UUID | |
| groupId | UUID | |
| organizerId | UUID | 모임 생성자 |
| title | string | |
| mode | enum | `poll` \| `fixed` |
| status | enum | §3 상태 |
| place | string? | |
| memo | string? | |
| confirmedStartsAt | datetime? | 일시 확정 후 |
| isAllDay | boolean | |
| pollDeadlineAt | datetime? | poll only |
| attendanceDeadlineAt | datetime? | 일시 확정 후 활성 |
| targetMemberIds | UUID[] | 생성 시 스냅샷 (P-E13) |
| version | int | optimistic lock (X-5) |
| cancelledAt | datetime? | |
| finalizedAt | datetime? | 모임 확정 |
| createdAt | datetime | |
| updatedAt | datetime | |

### DateOption
| 필드 | 타입 | 비고 |
|------|------|------|
| id | UUID | |
| eventId | UUID | |
| startsAt | datetime | |
| isAllDay | boolean | |
| sortOrder | int | |

### DateVote
| 필드 | 타입 | 비고 |
|------|------|------|
| id | UUID | |
| eventId | UUID | |
| optionId | UUID | |
| userId | UUID | |
| value | enum | `yes` \| `no` \| `maybe` |
| updatedAt | datetime | |

### EventResponse
| 필드 | 타입 | 비고 |
|------|------|------|
| id | UUID | |
| eventId | UUID | |
| userId | UUID | |
| value | enum | `attend` \| `decline` \| `maybe` |
| note | string? | 한 줄 메모 |
| updatedAt | datetime | |

### Comment
| 필드 | 타입 | 비고 |
|------|------|------|
| id | UUID | |
| eventId | UUID | |
| authorId | UUID | |
| body | string | max 500 |
| createdAt | datetime | |

### Notification (in-app)
| 필드 | 타입 | 비고 |
|------|------|------|
| id | UUID | |
| userId | UUID | |
| type | enum | §4 |
| eventId | UUID? | |
| title | string | KO |
| body | string | KO |
| readAt | datetime? | |
| createdAt | datetime | |

---

## 3. Event.status 전이

```
                    ┌─────────┐
                    │  draft  │ (내부, 생성 직후 즉시 poll/fixed로)
                    └────┬────┘
         poll mode       │        fixed mode
              ┌─────────▼─────────┐
              │   poll_open       │  날짜 투표 중
              └─────────┬─────────┘
                        │ confirm-datetime
              ┌─────────▼─────────┐
              │ attendance_open   │  참석 수집 중 (UI: 일시 확정 직후)
              └─────────┬─────────┘
                        │ finalize
              ┌─────────▼─────────┐
              │    finalized      │  모임 확정 → 캘린더
              └───────────────────┘

   any (before finalized) ──► cancelled
```

| PRD/UI 용어 | API enum |
|-------------|----------|
| 날짜 투표 중 | `poll_open` |
| 일시 확정됨 (UI 칩) | `attendance_open` (초기) |
| 참석 수집 중 | `attendance_open` |
| 모임 확정 | `finalized` |
| 취소 | `cancelled` |

**fixed 모드 (P-E9):** 생성 직후 `attendance_open`. `confirmedStartsAt`·`attendanceDeadlineAt` 즉시 설정. `poll_open`·`datetime_locked` **거치지 않음**.

**P-E7 검증:** `pollDeadlineAt` < 모든 `option.startsAt`; `pollDeadlineAt` > now.

---

## 4. Notification.type (예시)

`event_created`, `poll_reminder`, `attendance_reminder`, `datetime_confirmed`, `event_finalized`, `event_cancelled`, `manual_nudge`, `comment_added`

---

## 5. 집계 뷰

### CalendarEntry (read model)
- `eventId`, `title`, `startsAt`, `place`, `organizerDisplayName`
- source: `Event.status = finalized` only (P-E6)

### HomeSummary
- `actionRequired[]` — 본인 미투표/미참석
- `upcomingFinalized[]` — 다가오는 확정 일정
- `familyPendingByEvent[]` — 모임별 미완료 명단 (P-G4)
