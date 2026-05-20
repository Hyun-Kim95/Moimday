# Moimday

??·??? ?? ??·?? ?? MVP (Flutter + REST API).

- ?? ?? **30?**, 1? ?? **10??**, **?? ??** ?? ([ADR-0003](docs/decisions/0003-multi-group-30-members.md))

## ??

| ?? | ?? |
|------|------|
| [apps/mobile/](apps/mobile/) | Flutter iOS/Android |
| [services/api/](services/api/) | Fastify + Prisma API |
| [docs/](docs/) | PRD, API, ??? |
| [mock-internal/](mock-internal/) | 2A ?? ?? (???) |

## ?? ??

### 1. API (SQLite dev DB ??)

PostgreSQL? `docker compose up -d` ? `.env`? `DATABASE_URL`? Postgres URL? ??.

### 2. API

```bash
cd services/api
cp .env.example .env
npm install
npx prisma generate
npx prisma db push
npm run dev
```

???: **??? / Google / Apple** ? [apps/mobile/docs/oauth-setup.md](apps/mobile/docs/oauth-setup.md)  
`flutter run --dart-define=KAKAO_NATIVE_APP_KEY=... --dart-define=GOOGLE_OAUTH_CLIENT_ID=...`

**?? ???** (30?·??·?? ??):

```bash
cd services/api
npm run db:seed
# ???: npm run db:seed -- --reset
```

**?? ???** (?? DB `moimday_test`):

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

Android ????? API: `http://10.0.2.2:3000/v1` (???)  
iOS ?????: `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/v1`

## ??

- **Flutter** ? Riverpod, go_router, dio ([ADR-0002](docs/decisions/0002-cross-platform-stack.md))
- **API** ? Node 20, Fastify, Prisma, PostgreSQL
- **???** ? Stitch Serene Kinship `#2B8C7E`
