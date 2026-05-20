# MVP UX·플로우 전면 수정

**일자:** 2026-05-20

## 요약

날짜/마감 피커, 인증·라우팅, 이벤트·그룹·설정 플로우를 PRD·API 계약에 맞게 보완했습니다.

## 백엔드

- `event-deadline.ts`: P-E7/P-E8 검증, `INVALID_DEADLINE`, `DATE_IN_PAST`
- `extend-poll-deadline`, `PUT date-options`
- 그룹: `leave`, `admin/transfer`, `DELETE members`, `DELETE group`
- `confirm-datetime`: 참석 마감 기본값 확정 일시 24h 전

## 모바일

- `FtDateTimeField`, S06 poll/fixed 폼 전면 개편
- 401 시 토큰·세션 클리어, 온보딩 1회, 딥링크·초대 URL 파싱
- S08 세그먼트 투표, S14 0명 경고, S07 마감 연장·편집
- S11 프로필·나가기·계정 삭제
- S09 `table_calendar`, 홈 오프라인 배너, 알림 시각

## 확인

- `flutter analyze`: error 0
- `mvp-test-plan` T-F3-01/02 수동 스모크 권장
