# Stitch 정합 (MVP 전 화면)

**일자:** 2026-05-20

## 요약

Stitch(Serene Kinship) 디자인 토큰과 PRD S01~S14를 기준으로 Flutter UI를 정합했습니다. API 변경은 홈 `familyPending.eventTitle` 추가만 포함합니다.

## 영향 범위

- `apps/mobile`: 테마·공통 위젯·전 화면 레이아웃, S13/S14 신규 라우트, 이벤트 상세 위젯 분리
- `services/api`: `GET /groups/:id/home` 응답 `familyPending[].eventTitle`

## 확인 포인트

1. `flutter analyze` (errors 0)
2. 홈 가족 미완료에 UUID 미노출
3. 모임 상세 → 투표 현황 / 일시 확정 플로우
4. Debug: 설정 → 디자인 시스템 갤러리

## 후속

- 실기기 Stitch 스크린샷 대조
- Pretendard subset 폰트
- FCM 프로덕션 연동
