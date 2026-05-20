# Moimday API

Node 20 + Fastify + Prisma.

## Setup (로컬 SQLite)

```bash
cd services/api
cp .env.example .env
npm install
npx prisma generate
npx prisma db push
npm run dev
```

Auth: 소셜 OAuth — `KAKAO_REST_API_KEY`, `GOOGLE_OAUTH_CLIENT_IDS`, `APPLE_CLIENT_IDS` ([.env.example](.env.example)).

Health: `GET http://localhost:3000/health`

## PostgreSQL (스테이징·운영)

레포 루트에서:

```bash
docker compose up -d postgres
```

`services/api/.env`:

```env
DATABASE_URL="postgresql://moimday:moimday@localhost:5432/moimday"
```

```bash
npx prisma migrate deploy   # 또는 최초: npx prisma db push
npm run dev
```

통합 테스트는 별도 SQLite DB를 사용합니다: `npm run test:integration`.

## 시드·통합 테스트

```bash
npm run db:seed
npm run test:integration
```

## 환경 변수 (요약)

| 변수 | 설명 |
|------|------|
| `JWT_SECRET` | 필수 (프로덕션 강한 값) |
| `OTP_DEV_MODE` | `false` 시 실 SMS (`SMS_PROVIDER`) |
| `SMS_PROVIDER` | `none` \| `console` \| `ncp` |
| `FCM_ENABLED` | `true` + service account 시 푸시 발송 |
| `FCM_PROJECT_ID` / `FCM_SERVICE_ACCOUNT_JSON` | FCM HTTP v1 |

시크릿은 레포에 커밋하지 마세요. Human: 벤더 계정·발신번호·Firebase 프로젝트.

## 리마인더

15분 cron (`src/jobs/reminders.ts`). 정책: [ADR-0004](../../docs/decisions/0004-reminder-policy-mvp.md) (48h/24h/1h, 야간 이월, 응답 완료 스킵).

단일 API 인스턴스에서 cron 중복을 피하거나, 다중 인스턴스 시 리더 선출이 필요합니다.
