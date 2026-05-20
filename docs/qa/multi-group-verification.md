# 다중 그룹 · 30명 — 구현 검증

**날짜:** 2026-05-20  
**ADR:** [0003-multi-group-30-members.md](../decisions/0003-multi-group-30-members.md)

## API

| 항목 | 상태 |
|------|------|
| `MAX_MEMBERS=30`, `groupCapacityUsage` | 구현 |
| `MAX_GROUPS_PER_USER=10` | 구현 |
| `GET /users/me` groups + activeGroupId | 구현 |
| `PATCH /users/me/active-group` | 구현 |
| 초대 수락 시 active 설정 | 구현 |
| 탈퇴 시 active 재지정 | 구현 |

## 앱

| 항목 | 상태 |
|------|------|
| Session.groups + activeGroupId | 구현 |
| GroupSwitcherAction (2+ 그룹) | 구현 |
| S03 그룹 목록·생성·가입 | 구현 |
| 카피 중립화(그룹/멤버) | 구현 |

## 수동 스모크

1. 계정 A: 그룹1 생성 → 그룹2 초대 링크로 B 가입
2. A: 스위처로 그룹2 선택 → 모임 생성 → 그룹1 홈에 없음
3. 정원: 멤버+초대 30 도달 시 `GROUP_FULL`

## 2차 (UI·계약)

| 항목 | 상태 |
|------|------|
| OpenAPI v1.1 핵심 경로 | 구현 |
| S13 전체 보기·접기 | 구현 |
| 홈 미완료 4명 요약 + 시트 | 구현 |
| 이벤트 상세 미응답 전체 보기 | 구현 |

## 자동화

| 항목 | 명령 | 결과 |
|------|------|------|
| 통합 테스트 | `cd services/api && npm run test:integration` | 21 assertions |
| 개발 시드 | `npm run db:seed` (--reset) | 30명·2그룹·투표 샘플 |

## 미완

- 실기기 30명 부하·집계 1초 체감 측정
