/// Human: 스토어 제출 전 실제 HTTPS URL로 dart-define 설정.
const termsUrl = String.fromEnvironment(
  'TERMS_URL',
  defaultValue: 'https://example.com/moimday/terms',
);

const privacyUrl = String.fromEnvironment(
  'PRIVACY_URL',
  defaultValue: 'https://example.com/moimday/privacy',
);
