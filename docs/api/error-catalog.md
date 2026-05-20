# 오류 코드 카탈로그 (MVP)

**버전:** 0.1  
**SSOT:** 사용자 메시지·`code` 목록은 본 문서 + PRD §8.6. 구현 시 i18n 키로 매핑.

| code | HTTP | 사용자 메시지 (KO) |
|------|------|-------------------|
| `VALIDATION_ERROR` | 400 | 입력 내용을 확인해 주세요. |
| `INVALID_PHONE` | 400 | 올바른 휴대폰 번호를 입력해 주세요. |
| `OTP_EXPIRED` | 400 | 인증번호가 만료되었어요. 다시 받아 주세요. |
| `OTP_INVALID` | 400 | 인증번호가 맞지 않아요. |
| `OTP_RATE_LIMITED` | 429 | 오늘 인증 요청 횟수를 초과했어요. 내일 다시 시도해 주세요. |
| `UNAUTHORIZED` | 401 | 다시 로그인해 주세요. |
| `FORBIDDEN` | 403 | 권한이 없어요. |
| `NOT_FOUND` | 404 | 요청한 정보를 찾을 수 없어요. |
| `EVENT_NOT_FOUND` | 404 | 모임을 찾을 수 없어요. |
| `USER_GROUP_LIMIT` | 409 | 가입할 수 있는 그룹 수(10개)에 도달했어요. |
| `ALREADY_MEMBER` | 409 | 이미 이 그룹에 참여 중이에요. |
| `GROUP_FULL` | 409 | 그룹 정원(30명)이 가득 찼어요. |
| `INVITE_EXPIRED` | 400 | 초대 링크가 만료되었어요. |
| `ADMIN_TRANSFER_REQUIRED` | 403 | 그룹 관리자는 다른 분에게 관리자를 넘긴 뒤 탈퇴할 수 있어요. |
| `POLL_CLOSED` | 409 | 투표가 마감되었어요. 화면을 새로고침해 주세요. |
| `ATTENDANCE_CLOSED` | 409 | 참석 응답이 마감되었어요. |
| `INCOMPLETE_POLL` | 400 | 모든 날짜 후보에 응답해 주세요. |
| `DATETIME_NOT_CONFIRMED` | 409 | 아직 일시가 확정되지 않았어요. |
| `EVENT_CANCELLED` | 409 | 취소된 모임이에요. |
| `ORGANIZER_UNAVAILABLE` | 409 | 모임 생성자 확인이 필요해요. |
| `VERSION_MISMATCH` | 409 | 다른 기기에서 변경되었어요. 새로고침해 주세요. |
| `DATE_IN_PAST` | 400 | 과거 일시는 선택할 수 없어요. |
| `INVALID_DEADLINE` | 400 | 마감 시각을 확인해 주세요. |
| `NUDGE_RATE_LIMITED` | 429 | 오늘은 이미 독촉을 보냈어요. |
| `RATE_LIMITED` | 429 | 잠시 후 다시 시도해 주세요. |
| `SERVICE_UNAVAILABLE` | 503 | 서비스에 연결할 수 없어요. |

**클라이언트:** PRD §8.7 (X-1~X-7). 알 수 없는 `code` → “일시적인 오류가 발생했어요.” + 재시도.
