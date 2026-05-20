# Flutter API 오류 처리 (Gate 2)

**근거:** [error-catalog.md](./error-catalog.md), PRD §8.7

## ApiException

```dart
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;
}
```

## 처리 규칙

| HTTP | 처리 |
|------|------|
| 401 | 토큰 삭제 → `/login` |
| 403 | 스낵바 + 뒤로(권한) |
| 409 `VERSION_MISMATCH` | 다이얼로그 + `ref.invalidate` |
| 409 기타 | 스낵바 + 메시지 |
| 429 | 스낵바 + 타이머(OTP/NUDGE) |
| 5xx / timeout | 배너 + 재시도 |

알 수 없는 `code` → 「일시적인 오류가 발생했어요.」
