# ADR-0003: 정원 30명 · 1인 다중 그룹

**상태:** 확정 (2026-05-20)  
**근거:** 다중 그룹·동호회 등 확장 요청

## 결정

| 항목 | 값 |
|------|-----|
| 그룹 정원 | **30명** (활성 멤버 + 유효 초대 링크 합산, P-G3) |
| 1인 그룹 수 상한 | **10개** (`USER_GROUP_LIMIT`) |
| 활성 그룹 | `User.lastActiveGroupId` (DB, 기기 간 동기화) |
| 초대 수락 후 | 해당 그룹을 active로 설정 |
| 카피 | UI·에러 메시지 **「그룹」** 중립 (브랜드 Moimday 유지) |
| 성공 지표 | 참여율 **80%** 유지, 분모 30명 |

## API

- `GET /users/me`: `groups[]`, `activeGroupId`, `groupId`(호환), `isGroupAdmin`(active 기준)
- `PATCH /users/me/active-group`: `{ "groupId": "uuid" }`
- `POST /groups`, `POST /invites/:token/accept`: `ALREADY_IN_GROUP` 제거 → `USER_GROUP_LIMIT` / `ALREADY_MEMBER`

## 비목표 (본 ADR)

- 그룹별 닉네임, 통합 알림함, 그룹 타입(가족/친구) 필드
