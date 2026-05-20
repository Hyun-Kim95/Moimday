# Legal (MVP)

PRD D-6, D-7, P-E5 · [ADR-0005](../decisions/0005-social-oauth-auth.md)

| 문서 | 상태 | 비고 |
|------|------|------|
| 이용약관 (KO) | **미작성** | 만 14세 이상, 그룹·모임 서비스 |
| 개인정보처리방침 (KO) | **미작성** | 카카오·Google·Apple 로그인, 푸시 토큰, 표시 이름 |
| 마케팅 수신 동의 | **비포함** (MVP) |

## 제3자 제공 (로그인)

- **카카오**: 카카오 로그인 (식별자·프로필)
- **Google**: Google Sign-In (식별자·이메일·이름)
- **Apple**: Sign in with Apple (식별자·이메일 선택)

스토어·파일럿 전 법무 검토 권장. 앱 로그인 화면에 **공개 HTTPS URL** 링크 필요 (`TERMS_URL`, `PRIVACY_URL` dart-define).

## Human

- 약관·개인정보 본문 작성 및 호스팅 URL
- 각 제공자 개발자 콘솔 약관·데이터 처리 동의
