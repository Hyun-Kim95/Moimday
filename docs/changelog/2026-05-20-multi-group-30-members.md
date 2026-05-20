# 2026-05-20 — 다중 그룹 · 정원 30명

## 요약

- 그룹 정원 **10 → 30** (멤버 + 유효 초대 합산, P-G3)
- 1인 **최대 10그룹** 동시 소속, **활성 그룹** 전환 (`User.lastActiveGroupId`)
- API: `GET /users/me`에 `groups[]`, `PATCH /users/me/active-group`
- 앱: 홈·모임 **그룹 스위처**, S03 그룹 목록·생성·가입 통합

## 영향

- `ALREADY_IN_GROUP` 제거 → `USER_GROUP_LIMIT`, `ALREADY_MEMBER`
- Prisma: `User.lastActiveGroupId`

## 확인

- [ ] 2그룹 생성·초대 가입·스위처 전환
- [ ] 31번째 멤버(또는 초대 합산) `GROUP_FULL`
- [ ] 11번째 그룹 `USER_GROUP_LIMIT`
- [ ] 탈퇴 후 active 자동 재지정

## 2차

- OpenAPI v1.1, `date-poll-summary` 멤버 버킷 확장
- S13·홈·상세 **전체 보기** UI (`FtExpandableNameList`)
- API `tsc` 정리 (`serializeEvent` 전 `loadEvent`)

## 3차

- `npm run db:seed` / `npm run test:integration`
- README 시드·테스트 안내

## 근거

- [ADR-0003](../decisions/0003-multi-group-30-members.md)
