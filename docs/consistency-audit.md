# 문서 정합성 점검 기록

**점검일:** 2026-05-20  
**범위:** PRD v0.6 + `docs/` 초기 세트

## 해결한 충돌

| # | 항목 | 이전 | 조치 |
|---|------|------|------|
| C1 | 투표·참석 HTTP 메서드 | PRD `POST` / api `PUT` | **PUT** 통일, PRD v0.6 |
| C2 | fixed 모드 초기 상태 | `datetime_locked` 경유 | **`attendance_open` 직행** |
| C3 | confirm-datetime | `POLL_CLOSED` 409 | **poll_open** 중 조기 확정 허용(P-E4) |
| C4 | confirm 후 API 상태 | `datetime_locked` 단계 | **`attendance_open` 직행** (UI 칩만 「일시 확정」) |
| C5 | PRD §6 vs data-model 상태 | 이원 표기 | 제품 4단계 + API enum crosswalk |

## 보완한 누락

| # | 항목 | 문서 |
|---|------|------|
| G1 | API 엔드포인트 (연장·이관·멤버·users/me) | api-contract v0.2 |
| G2 | 오류 code·한국어 메시지 SSOT | error-catalog.md |
| G3 | PRD↔API↔화면↔테스트 매핑 | document-crosswalk.md |
| G4 | 용어·역할 정의 | glossary.md |
| G5 | 푸시 페이로드·딥링크 | push-notification-mvp.md |
| G6 | 약관·개인정보 플레이스홀더 | legal/README.md |
| G7 | KST·멱등·If-Match | api-contract §1 |
| G8 | 화면·테스트 (S03,S05,F2,연장,이관) | screen-spec, ui-states, test-plan v0.2 |

## 잔여 (의도적 미확정)

| 항목 | 문서 | 비고 |
|------|------|------|
| OpenAPI YAML | api/README | Gate 2 |
| 크로스플랫폼 스택 | ADR-0002 | PoC 후 |
| PRD HUMAN 승인 | stage3 checklist §1 | 사용자 |
| 이용약관 본문 | legal/ | 법무 |
| 페이지네이션·rate limit 수치 | api-contract §9 | 구현 전 |

## 다음 점검 시점

- PRD **승인** 직후
- **디자인 선택** 후 (화면↔API 필드 1:1)
- Gate 2 **확정** 시 OpenAPI 생성·본 audit 갱신
