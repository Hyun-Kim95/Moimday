# ADR-0002: 크로스플랫폼 모바일 스택

**상태:** Accepted  
**날짜:** 2026-05-20  
**확정:** 2026-05-20 (Flutter + 전용 REST API)  
**근거:** PRD §4.2

## 컨텍스트

Android·iOS 동시 제공이 필수다. MVP는 소규모 가족 앱이며 팀 규모·유지보수를 고려해야 한다.

## 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| **A. React Native (Expo)** | TS 생태계, 푸시·OTA 문서, 빠른 PoC | 네이티브 이슈 시 복잡도 |
| **B. Flutter** | UI 일관성, 단일 UI 스택 | Dart 스택, 팀 학습 |
| **C. Kotlin + Swift** | 최적 네이티브 | 비용 2배, MVP에 과함 |

## 결정

- **모바일:** **B. Flutter** (Dart 3.x, Riverpod, go_router, dio)
- **백엔드:** **전용 REST API** — Node 20 + Fastify + Prisma + PostgreSQL
- **배포:** Railway(권장), FCM/APNs, 개발 SMS 스텁

## 결과

- 앱 패키지 경로: `apps/mobile/`
- 백엔드 경로: `services/api/`
- API 계약 SSOT: `docs/api/openapi-mvp.yaml` (v1.0)
