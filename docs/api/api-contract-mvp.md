# API 계약 (MVP)

**버전:** 1.0 (Gate 2 확정 — OpenAPI: [openapi-mvp.yaml](./openapi-mvp.yaml))  
**Base URL:** `https://api.moimday.example/v1` (환경별 치환)  
**근거:** [moimday-prd.md](../requirements/moimday-prd.md) §9, §8.6~8.7

---

## 1. 공통

### 인증
- `Authorization: Bearer <access_token>`
- 그룹·모임 API는 **멤버십** 검증 필수.

### 시간대
- 모든 `datetime` 필드: **ISO 8601**, 타임존 **`+09:00`(KST)** 명시.

### 헤더
| 헤더 | 용도 |
|------|------|
| `Idempotency-Key` | `PUT .../date-votes`, `PUT .../responses` (UUID) |
| `If-Match` | `PATCH /events/{id}` — `version` 정수 (409 `VERSION_MISMATCH`) |

### 오류 응답
```json
{
  "error": {
    "code": "POLL_CLOSED",
    "message": "투표가 마감되었어요. 화면을 새로고침해 주세요."
  }
}
```

### HTTP ↔ code
| HTTP | code 예 |
|------|---------|
| 400 | `VALIDATION_ERROR`, `INVALID_PHONE`, `DATE_IN_PAST`, `INVALID_DEADLINE`, `INCOMPLETE_POLL` |
| 401 | `UNAUTHORIZED` |
| 403 | `FORBIDDEN` |
| 404 | `NOT_FOUND`, `EVENT_NOT_FOUND` |
| 409 | `VERSION_MISMATCH`, `CONFLICT` |
| 429 | `OTP_RATE_LIMITED`, `RATE_LIMITED` |
| 503 | `SERVICE_UNAVAILABLE` |

전체 code·한국어 메시지: [error-catalog.md](./error-catalog.md)

---

## 2. Auth (소셜 · v1.3)

### POST `/auth/oauth/{provider}`
`provider`: `kakao` | `google` | `apple`

**Kakao** — Body `{ "accessToken": "..." }`  
**Google / Apple** — Body `{ "idToken": "..." }`

**200**
```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "expiresInSec": 3600,
  "user": { "id": "uuid", "displayName": "철수", "hasGroup": false }
}
```
**400** `VALIDATION_ERROR` · `OAUTH_PROVIDER_INVALID` · **401** `UNAUTHORIZED` · **503** `SERVICE_UNAVAILABLE` (미설정)

### POST `/auth/token/refresh`
**Body** `{ "refreshToken": "..." }`  
**200** accessToken 갱신 · **401** `UNAUTHORIZED`

### GET `/users/me`
**200** `{ "id", "displayName", "phoneMasked": null|string, "autoReminderEnabled", "activeGroupId"?, "groupId"?(호환), "groups": [...], "isGroupAdmin" }` — 소셜-only 가입 시 `phoneMasked` null

### PATCH `/users/me/active-group`
**Body** `{ "groupId": "uuid" }`  
**200** `GET /users/me`와 동일 형태 · **403** `FORBIDDEN` (비멤버)

### PATCH `/users/me`
**Body** `{ "displayName": "...", "autoReminderEnabled": true }`

### DELETE `/users/me`
계정 삭제 요청 (P-E3) → **202**

---

## 3. Groups

### POST `/groups`
**Body** `{ "name": "우리 가족" }`  
**201** `{ "group": { "id", "name", "adminUserId", "inviteUrl" } }`  
**409** `USER_GROUP_LIMIT`

### GET `/groups/{groupId}`
**200** 그룹 + 멤버 목록 + `pendingInviteCount` (표시 이름; 타인 전화번호 비노출 P-G6)

### PATCH `/groups/{groupId}/members/{userId}`
**Body** `{ "nickname": "큰아들" }` — 본인 또는 관리자

### DELETE `/groups/{groupId}/members/{userId}`
멤버보내기 (**그룹 관리자**). 진행 중 모임 **대상 스냅샷에서 제외**(신규 액션 불가).

### POST `/groups/{groupId}/admin/transfer`
**Body** `{ "newAdminUserId": "uuid" }` — **현재 관리자**만

### POST `/groups/{groupId}/invites`
**201** `{ "inviteUrl", "expiresAt" }`  
**409** `GROUP_FULL`

### POST `/invites/{token}/accept`
**200** `{ "groupId" }`  
**400** `INVITE_EXPIRED` · **409** `GROUP_FULL` · **409** `USER_GROUP_LIMIT` · **409** `ALREADY_MEMBER`

### POST `/groups/{groupId}/leave`
**Body** (관리자 시) `{ "transferAdminToUserId": "uuid" }`  
**403** `ADMIN_TRANSFER_REQUIRED` if admin without transfer

### DELETE `/groups/{groupId}`
그룹 해체 (관리자) — 진행 중 모임 일괄 취소

---

## 4. Home & Calendar

### GET `/groups/{groupId}/home`
**200**
```json
{
  "actionRequired": [
    {
      "eventId": "uuid",
      "title": "생신 식사",
      "actionType": "poll" | "attendance",
      "deadlineAt": "2026-06-01T12:00:00+09:00"
    }
  ],
  "upcomingFinalized": [
    { "eventId", "title", "startsAt", "place" }
  ],
  "familyPending": [
    {
      "eventId": "uuid",
      "phase": "poll" | "attendance",
      "pendingMemberIds": ["uuid"],
      "pendingDisplayNames": ["동생"]
    }
  ]
}
```

### GET `/groups/{groupId}/calendar?from=2026-06-01&to=2026-06-30`
**200** `{ "items": [ CalendarEntry ] }` — `finalized` only

---

## 5. Events

### GET `/groups/{groupId}/events?filter=all|my_pending`
**200** `{ "events": [ EventSummary ] }`

### POST `/groups/{groupId}/events`
**Body (poll)**
```json
{
  "title": "생신 식사",
  "mode": "poll",
  "place": "본가",
  "memo": "",
  "pollDeadlineAt": "2026-05-25T18:00:00+09:00",
  "options": [
    { "startsAt": "2026-05-30T18:00:00+09:00", "isAllDay": false },
    { "startsAt": "2026-05-31T12:00:00+09:00", "isAllDay": false }
  ],
  "targetMemberIds": null
}
```
`targetMemberIds` null → 생성 시점 전원 스냅샷.

**Body (fixed)**
```json
{
  "title": "저녁 약속",
  "mode": "fixed",
  "confirmedStartsAt": "2026-05-30T18:00:00+09:00",
  "isAllDay": false,
  "attendanceDeadlineAt": "2026-05-29T18:00:00+09:00"
}
```

**201** Event + `version: 1`  
- `poll` → `status: poll_open`  
- `fixed` → `status: attendance_open` (투표 생략, P-E9)

**400** `VALIDATION_ERROR`, `INVALID_DEADLINE`, `DATE_IN_PAST`

### GET `/events/{eventId}`
**200** Event 상세 + options + 본인 vote/response + pending 집계

### PATCH `/events/{eventId}`
**Headers** `If-Match: <version>`  
**Body** 제목·장소·메모·`pollDeadlineAt`·`attendanceDeadlineAt`(정책·상태별 허용, P-E7·P-E11)  
**409** `VERSION_MISMATCH` · **403** · **409** `EVENT_CANCELLED`

### PUT `/events/{eventId}/date-options`
**Body** `{ "options": [...] }` — **poll_open**·생성자만; 2~5개 (P-E11: 마감 연장 후 변경)

### POST `/events/{eventId}/extend-poll-deadline`
**Body** `{ "pollDeadlineAt": "...", "optionChanges": { "add": [], "remove": [] } }`  
투표 마감 **연장** + (선택) 후보 변경(P-E11). **409** `POLL_CLOSED` 아님 — 연장 목적.

### POST `/events/{eventId}/cancel`
**403** not organizer · **200** status `cancelled`

### POST `/events/{eventId}/confirm-datetime`
**Body** `{ "optionId": "uuid" }` (poll)  
**권한:** 모임 생성자 · **상태:** `poll_open` (마감 **전 조기 확정** 허용, P-E4)  
**200** → `attendance_open` + `attendanceDeadlineAt` 설정(미설정 시 기본 P-E8)  
**403** · **409** `EVENT_CANCELLED` · **409** `ORGANIZER_UNAVAILABLE` · **400** `DATE_IN_PAST`

### POST `/events/{eventId}/finalize`
**200** → `finalized` (P-E10)  
**403** not organizer

### POST `/events/{eventId}/nudge`
**Body** `{ "phase": "poll" | "attendance" }`  
**200** `{ "sentCount": 3 }` — 미완료 대상만 (P-N11)  
**429** `NUDGE_RATE_LIMITED`

---

## 6. Poll & Attendance

### PUT `/events/{eventId}/date-votes`
**Headers** `Idempotency-Key`  
**Body**
```json
{
  "votes": [
    { "optionId": "uuid", "value": "yes" },
    { "optionId": "uuid", "value": "no" }
  ]
}
```
전 후보 필수 (P-E16).  
**400** `INCOMPLETE_POLL` · **409** `POLL_CLOSED`

### GET `/events/{eventId}/date-poll-summary`
**200**
```json
{
  "options": [
    {
      "optionId": "uuid",
      "startsAt": "...",
      "counts": { "yes": 6, "no": 1, "maybe": 1, "pending": 2 },
      "yesMembers": [{ "userId", "displayName" }],
      "noMembers": [{ "userId", "displayName" }],
      "maybeMembers": [{ "userId", "displayName" }],
      "pendingMembers": [{ "userId", "displayName" }],
      "recommended": true
    }
  ],
  "pollDeadlineAt": "...",
  "status": "poll_open"
}
```

### PUT `/events/{eventId}/responses`
**Headers** `Idempotency-Key`  
**Body** `{ "value": "attend", "note": "늦을 수 있어요" }`  
**409** `ATTENDANCE_CLOSED` · **409** `DATETIME_NOT_CONFIRMED`

---

## 7. Comments & Notifications

### GET `/events/{eventId}/comments?cursor=`
### POST `/events/{eventId}/comments`
**Body** `{ "body": "6시로 바꿔요" }` — max 500, **409** `EVENT_CANCELLED`

### DELETE `/comments/{commentId}`
작성자·모임 생성자·그룹 관리자 (§8.5)

### GET `/notifications?unreadOnly=true`
**PATCH** `/notifications/{id}/read` · **POST** `/notifications/read-all`

---

## 8. Push (서버 내부)

클라이언트 직접 호출 없음. FCM/APNs 토큰 등록:

### PUT `/users/me/push-token`
**Body** `{ "platform": "ios"|"android", "token": "..." }`

---

## 9. Gate 2 미확정 (구현 전 확정)

| 항목 | 후보 |
|------|------|
| 페이지네이션 | cursor vs offset |
| Webhook | 없음 (MVP) |
| Rate limit 수치 | 예: 100 req/min/user |
