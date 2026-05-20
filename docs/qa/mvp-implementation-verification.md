# MVP 구현 검증 체크리스트 (Gate 3)

**일자:** 2026-05-20 (다중 그룹·30명 반영)  
**범위:** Flutter `apps/mobile` + `services/api`  
**상세:** [multi-group-verification.md](./multi-group-verification.md)

## 자동·수동 확인

| ID | 항목 | 방법 | 결과 |
|----|------|------|------|
| T-API-01 | Health | `GET /health` | 수동 |
| T-API-02 | 소셜 OAuth | `POST /auth/oauth/{provider}` | **구현** |
| T-API-03 | Group + invite | POST `/groups`, accept | 수동 |
| T-API-04 | Poll E2E | create→vote→confirm→attend→finalize | 수동 |
| T-FE-01 | `flutter analyze` | 0 errors | **통과** |
| T-FE-02 | Login → group → home | 에뮬레이터 | 수동 |
| T-FE-03 | Push token PoC | dev token | 수동 |
| T-FE-04 | S06 날짜 피커 | poll/fixed 모두 피커 노출 | **구현** |
| T-FE-05 | 401 세션 | 만료 후 `/login` 고정 | **구현** |
| T-FE-06 | S14 0명 경고 | confirm 다이얼로그 | **구현** |
| T-FE-07 | 그룹 나가기·삭제 | 설정 화면 | **구현** |
| T-FE-08 | 딥링크 invite | `moimday://invite/{token}` | **구현** |
| T-FE-09 | 다중 그룹·스위처 | 2그룹 가입·전환 | **구현** |
| T-API-05 | 정원 30·USER_GROUP_LIMIT | ADR-0003 | **구현** |
| T-API-06 | `npm run test:integration` | 24 passed | **통과** |
| T-DEV-01 | `npm run db:seed` | 30명·2그룹 | **통과** |

## 상태 UI

- S02: 소셜 로그인·14세·약관 링크
- S04: 오프라인 배너(`connectivity_plus`)
- S06: `INVALID_DEADLINE` 인라인
- S07: poll 마감·연장·편집
- S08: 세그먼트 투표·날짜 포맷

## 후속

- FCM 프로덕션
- `extend-poll` 후보 add/remove UI 2차
- 실기기 Stitch 스크린샷 대조
- 30명 집계·푸시 부하 실측
