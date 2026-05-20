# 운영/스토어 갭 구현 (2026-05-20)

## Phase 1 — 앱 제품 갭
- 투표 마감 연장 + 후보 추가 UI (`extend_poll_deadline_screen`)
- 날짜 후보 전면 교체 화면 (`event_date_options_screen`)
- 그룹 관리: 멤버 보내기, 해체, 관리자 이관, 나가기 (`group_admin_section`)
- 댓글 삭제 (작성자·주최자·그룹 관리자)
- 오프라인 쓰기 차단 (`offline_write_guard`)

## Phase 2 — 알림
- ADR-0004: 리마인더 48h/24h/1h, 야간 이월, 응답 완료 스킵
- FCM HTTP v1 (`lib/fcm.ts`, `FCM_ENABLED`)
- 15분 cron

## Phase 3 — 인프라
- SMS 추상화 (`lib/sms.ts`), `docker-compose.yml` Postgres
- API README 운영 절차

## Phase 4 — 출시
- Android/iOS `moimday://` 딥링크 매니페스트
- `share_plus` 초대 공유
- `hasGroup` = 멤버십 수

## Phase 5 — 검증·문서
- 통합 테스트: extend-poll body, 댓글 삭제
- OpenAPI 1.2.0 경로 동기화

## Human (미완)
- H1 SMS 벤더, H2 Firebase 실토큰, H4 스토어 빌드, H5 수동 QA 전량
