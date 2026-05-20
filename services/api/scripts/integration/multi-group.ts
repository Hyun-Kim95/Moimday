/**
 * 다중 그룹·30명 정책 통합 테스트 (Fastify inject, 별도 SQLite DB)
 *
 * npm run test:integration
 */
import { execSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import { PrismaClient } from '@prisma/client';
import { buildApp } from '../../src/app.js';
import { issueTestAccessToken } from '../../src/lib/integration-auth.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** 별도 DB 권장 — 본인 dev DB와 분리 (예: moimday_test) */
process.env.DATABASE_URL =
  process.env.TEST_DATABASE_URL ??
  'postgresql://moimday_app:moimday_app@localhost:5432/moimday_test?schema=public';
process.env.JWT_SECRET = 'integration-test-secret';
process.env.GOOGLE_OAUTH_CLIENT_IDS = 'integration-test-client';

const prisma = new PrismaClient();
let passed = 0;
let failed = 0;

function assert(cond: boolean, msg: string) {
  if (cond) {
    passed++;
    console.log(`  ✓ ${msg}`);
  } else {
    failed++;
    console.error(`  ✗ ${msg}`);
  }
}

async function login(_app: Awaited<ReturnType<typeof buildApp>>, subject: string, label: string) {
  const accessToken = await issueTestAccessToken(subject, label);
  assert(!!accessToken, `${label} login`);
  return accessToken;
}

function authHeader(token: string) {
  return { authorization: `Bearer ${token}` };
}

async function main() {
  console.log('[integration] DB push…');
  execSync('npx prisma db push --skip-generate', {
    cwd: path.join(__dirname, '../..'),
    stdio: 'inherit',
    env: { ...process.env, DATABASE_URL: process.env.DATABASE_URL },
  });

  await prisma.refreshToken.deleteMany();
  await prisma.dateVote.deleteMany();
  await prisma.eventResponse.deleteMany();
  await prisma.comment.deleteMany();
  await prisma.dateOption.deleteMany();
  await prisma.event.deleteMany();
  await prisma.invite.deleteMany();
  await prisma.oAuthAccount.deleteMany();
  await prisma.membership.deleteMany();
  await prisma.familyGroup.deleteMany();
  await prisma.user.deleteMany();

  const app = await buildApp();

  const adminToken = await login(app, 'integration-admin', '통합관리자');
  const user2Token = await login(app, 'integration-user2', '통합유저2');

  // 그룹 1
  const g1 = await app.inject({
    method: 'POST',
    url: '/v1/groups',
    headers: authHeader(adminToken),
    payload: { name: '통합테스트 A' },
  });
  assert(g1.statusCode === 200 || g1.statusCode === 201, 'create group A');
  const groupAId = (g1.json() as { group: { id: string } }).group.id;

  // user2 가입
  const inv = await app.inject({
    method: 'POST',
    url: `/v1/groups/${groupAId}/invites`,
    headers: authHeader(adminToken),
  });
  const inviteUrl = (inv.json() as { inviteUrl: string }).inviteUrl;
  const token = inviteUrl.split('/').pop()!;

  const join = await app.inject({
    method: 'POST',
    url: `/v1/invites/${token}/accept`,
    headers: authHeader(user2Token),
  });
  assert(join.statusCode === 200, 'user2 joins group A');

  // 그룹 2 — 다중 소속
  const g2 = await app.inject({
    method: 'POST',
    url: '/v1/groups',
    headers: authHeader(user2Token),
    payload: { name: '통합테스트 B' },
  });
  assert(g2.statusCode === 200 || g2.statusCode === 201, 'user2 creates group B');

  const me2 = await app.inject({
    method: 'GET',
    url: '/v1/users/me',
    headers: authHeader(user2Token),
  });
  const meBody = me2.json() as { groups: { id: string }[]; activeGroupId: string };
  assert(meBody.groups.length >= 2, 'user2 has 2+ groups');

  const groupBId = meBody.groups.find((g) => g.id !== groupAId)?.id ?? meBody.activeGroupId;
  const switchRes = await app.inject({
    method: 'PATCH',
    url: '/v1/users/me/active-group',
    headers: authHeader(user2Token),
    payload: { groupId: groupAId },
  });
  assert(switchRes.statusCode === 200, 'switch active to A');
  assert((switchRes.json() as { activeGroupId: string }).activeGroupId === groupAId, 'activeGroupId is A');

  // 10그룹 상한
  for (let i = 0; i < 9; i++) {
    await app.inject({
      method: 'POST',
      url: '/v1/groups',
      headers: authHeader(adminToken),
      payload: { name: `한도테스트 ${i}` },
    });
  }
  const limitHit = await app.inject({
    method: 'POST',
    url: '/v1/groups',
    headers: authHeader(adminToken),
    payload: { name: '한도테스트 초과' },
  });
  assert(limitHit.statusCode === 409, '11th group returns 409');
  assert(
    (limitHit.json() as { error: { code: string } }).error.code === 'USER_GROUP_LIMIT',
    'code USER_GROUP_LIMIT',
  );

  // 30명 정원 — DB로 멤버 채운 뒤 API로 31번째 거부 검증
  for (let i = 0; i < 28; i++) {
    const subject = `integration-fill-${String(i).padStart(4, '0')}`;
    const existing = await prisma.oAuthAccount.findUnique({
      where: { provider_subject: { provider: 'google', subject } },
    });
    let userId = existing?.userId;
    if (!userId) {
      const u = await prisma.user.create({
        data: {
          displayName: `필러${i}`,
          ageConfirmedAt: new Date(),
          oauthAccounts: { create: { provider: 'google', subject } },
        },
      });
      userId = u.id;
    }
    await prisma.membership.upsert({
      where: { groupId_userId: { groupId: groupAId, userId } },
      create: { groupId: groupAId, userId },
      update: {},
    });
  }

  const countRes = await app.inject({
    method: 'GET',
    url: `/v1/groups/${groupAId}`,
    headers: authHeader(adminToken),
  });
  const memberCount = (countRes.json() as { memberCount: number }).memberCount;
  assert(memberCount === 30, `group A has 30 members (got ${memberCount})`);

  const capInvite = await app.inject({
    method: 'POST',
    url: `/v1/groups/${groupAId}/invites`,
    headers: authHeader(adminToken),
  });
  assert(capInvite.statusCode === 409, 'invite when at capacity returns 409');
  assert(
    (capInvite.json() as { error: { code: string } }).error.code === 'GROUP_FULL',
    'full group cannot create invite',
  );

  await prisma.invite.create({
    data: {
      groupId: groupAId,
      token: 'overflow-test-token',
      expiresAt: new Date(Date.now() + 86400000),
    },
  });
  const overflowToken = await login(app, 'integration-overflow', '통합초과유저');
  const fullJoin = await app.inject({
    method: 'POST',
    url: '/v1/invites/overflow-test-token/accept',
    headers: authHeader(overflowToken),
  });
  assert(fullJoin.statusCode === 409, '31st member rejected');
  assert(
    (fullJoin.json() as { error: { code: string } }).error.code === 'GROUP_FULL',
    'code GROUP_FULL',
  );

  // poll summary buckets
  const pollCreate = await app.inject({
    method: 'POST',
    url: `/v1/groups/${groupAId}/events`,
    headers: authHeader(adminToken),
    payload: {
      mode: 'poll',
      title: '통합 투표',
      pollDeadlineAt: new Date(Date.now() + 86400000).toISOString(),
      options: [
        { startsAt: new Date(Date.now() + 172800000).toISOString() },
        { startsAt: new Date(Date.now() + 259200000).toISOString() },
      ],
    },
  });
  assert(pollCreate.statusCode === 201, 'create poll event');
  const eventId = (pollCreate.json() as { id: string }).id;

  const summary = await app.inject({
    method: 'GET',
    url: `/v1/events/${eventId}/date-poll-summary`,
    headers: authHeader(adminToken),
  });
  assert(summary.statusCode === 200, 'poll summary 200');
  const opt = (summary.json() as { options: Record<string, unknown>[] }).options[0] as {
    pendingMembers: unknown[];
    yesMembers: unknown[];
    noMembers: unknown[];
    maybeMembers: unknown[];
  };
  assert(Array.isArray(opt.pendingMembers), 'pendingMembers array');
  assert(Array.isArray(opt.noMembers), 'noMembers array');
  assert(
    opt.pendingMembers.length + opt.yesMembers.length + opt.noMembers.length + opt.maybeMembers.length >=
      0,
    'member buckets present',
  );

  const extend = await app.inject({
    method: 'POST',
    url: `/v1/events/${eventId}/extend-poll-deadline`,
    headers: authHeader(adminToken),
    payload: {
      pollDeadlineAt: new Date(Date.now() + 7200000).toISOString(),
      optionChanges: {
        add: [{ startsAt: new Date(Date.now() + 432000000).toISOString(), isAllDay: false }],
      },
    },
  });
  assert(extend.statusCode === 200, 'extend poll with addOptions');

  const comment = await app.inject({
    method: 'POST',
    url: `/v1/events/${eventId}/comments`,
    headers: authHeader(user2Token),
    payload: { body: '통합 테스트 댓글' },
  });
  assert(comment.statusCode === 201, 'create comment');
  const commentId = (comment.json() as { id: string }).id;

  const delComment = await app.inject({
    method: 'DELETE',
    url: `/v1/comments/${commentId}`,
    headers: authHeader(adminToken),
  });
  assert(delComment.statusCode === 200, 'admin deletes comment');

  await app.close();

  console.log(`\n[integration] ${passed} passed, ${failed} failed`);
  if (failed > 0) process.exit(1);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
