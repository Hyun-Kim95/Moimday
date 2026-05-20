# Moimday

가족·소규모 그룹 일정·모임 조율 MVP (Flutter + REST API).

- 그룹 인원 **30명**, 1인 최대 **10그룹**, **활성 그룹** 전환 ([ADR-0003](docs/decisions/0003-multi-group-30-members.md))

## 구조

| 경로 | 설명 |
|------|------|
| [apps/mobile/](apps/mobile/) | Flutter iOS/Android |
| [services/api/](services/api/) | Fastify + Prisma API |
| [docs/](docs/) | PRD, API, 디자인 |
| [mock-internal/](mock-internal/) | 2A 참고 목업 (비제품) |

## 빠른 시작

### 1. API (SQLite dev DB 기본)

PostgreSQL은 `docker compose up -d` 후 `.env`의 `DATABASE_URL`을 Postgres URL로 변경.

### 2. API

```bash
cd services/api
cp .env.example .env
npm install
npx prisma generate
npx prisma db push
npm run dev
```

로그인: **카카오 / Google / Apple** — [apps/mobile/docs/oauth-setup.md](apps/mobile/docs/oauth-setup.md)  
`flutter run --dart-define=KAKAO_NATIVE_APP_KEY=... --dart-define=GOOGLE_OAUTH_CLIENT_ID=...`

**시드 데이터** (30명·그룹·투표 샘플):

```bash
cd services/api
npm run db:seed
# 재생성: npm run db:seed -- --reset
```

**통합 테스트** (별도 DB `moimday_test`):

```bash
cd services/api
npm run test:integration
```

### 3. Flutter

```bash
cd apps/mobile
flutter pub get
flutter run
```

Android 에뮬레이터 API: `http://10.0.2.2:3000/v1` (기본값)  
iOS 시뮬레이터: `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/v1`

## 스택

- **Flutter** — Riverpod, go_router, dio ([ADR-0002](docs/decisions/0002-cross-platform-stack.md))
- **API** — Node 20, Fastify, Prisma, PostgreSQL
- **디자인** — Stitch Serene Kinship `#2B8C7E`
