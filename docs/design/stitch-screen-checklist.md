# Stitch 화면 정합 체크리스트

**프로젝트:** Moimday `5575514198874046733` · **DS:** Serene Kinship `#2B8C7E`  
**용도:** Flutter 구현 리뷰 시 Stitch 스크린샷과 1:1 대조 (픽셀 완벽보다 **섹션·CTA·칩·탭**)

**최종 점검:** 2026-05-20 (코드 기준 — 실기기 스크린샷 대조는 후속)

## PRD에 없는 Stitch 요소 (구현 안 함)

- 장보기 목록, 가족 할일, 가족 달력(캘린더 탭은 PRD S09), 프로필 상세 등 1차 S04 batch 부가 화면

## S02 OTP — `9600d8a72fa4495f840a7835f7f7aa5d`

- [x] 브랜드 로고/타이틀 영역 (teal)
- [x] 휴대폰 번호 필드 (라벨 위)
- [x] OTP 6자리 필드
- [x] 만 14세 + 약관 체크
- [x] pill CTA: 인증번호 받기 / 로그인 확인
- [x] 재전송 카운트다운·RATE_LIMIT UI

## S04 홈 — `ca239bac0a444e6ebbd177c4322a0801`

- [x] 하단 탭 5개 (홈 활성 teal)
- [x] 섹션 「내가 할 일」+ 배지 투표 필요/참석 답변
- [x] 섹션 「다가오는 확정 일정」
- [x] 섹션 「가족 미완료」이름만 (UUID 금지)
- [x] 빈 상태 + 모임 만들기 CTA
- [x] 카드 12px, secondary wash 배경

## S07 모임 상세(투표) — `66301c45bc5943efb1ec87957a1a12bb`

- [x] 제목 + 칩 「날짜 투표 중」
- [x] 마감 표시
- [x] CTA 날짜 투표하기 / 투표 현황(S13)
- [x] 미완료 가족 아바타 행
- [x] 주최자: 일시 확정(S14)·독촉
- [x] 댓글 영역 (PRD)
- [x] 읽기전용 cancelled

## S01·S03·S05~S14

- [x] [screen-spec-mvp.md](./screen-spec-mvp.md) + DS 토큰 적용
- [x] S13·S14: `poll_summary_screen`, `confirm_datetime_screen`

## 스크린샷 재조회

```powershell
$cfg = Get-Content "$env:USERPROFILE\.cursor\mcp.json" -Raw | ConvertFrom-Json
$env:STITCH_API_KEY = $cfg.mcpServers.stitch.env.STITCH_API_KEY
npx -y stitch-design-cli screen get --project-id 5575514198874046733 `
  --screen-id ca239bac0a444e6ebbd177c4322a0801,9600d8a72fa4495f840a7835f7f7aa5d,66301c45bc5943efb1ec87957a1a12bb `
  --include-image --json
```

`imageUrl`은 Stitch 웹·로컬 캡처로 보관 (레포 미포함).
