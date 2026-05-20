/**
 * 개발 DB 시드: 다중 그룹 · 30명 · 투표 샘플 (OAuth 시드 계정)
 *
 * 사용: npm run db:seed
 * 옵션: --members=30 --groups=2 --reset
 */
import crypto from 'crypto';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const SEED_GROUP_NAMES = ['시드·30명 그룹', '시드·두번째 그룹'];
const POLL_TITLE = '시드·날짜 투표 모임';
const SEED_PROVIDER = 'google';

function parseArg(name: string, fallback: string): string {
  const hit = process.argv.find((a) => a.startsWith(`--${name}=`));
  return hit ? hit.split('=')[1]! : fallback;
}

async function ensureOAuthUser(subject: string, displayName: string) {
  const existing = await prisma.oAuthAccount.findUnique({
    where: { provider_subject: { provider: SEED_PROVIDER, subject } },
    include: { user: true },
  });
  if (existing) {
    return prisma.user.update({
      where: { id: existing.userId },
      data: { displayName },
    });
  }
  return prisma.user.create({
    data: {
      displayName,
      ageConfirmedAt: new Date(),
      oauthAccounts: { create: { provider: SEED_PROVIDER, subject } },
    },
  });
}

async function resetSeedData() {
  const seedGroups = await prisma.familyGroup.findMany({
    where: { name: { in: SEED_GROUP_NAMES } },
    select: { id: true },
  });
  const groupIds = seedGroups.map((g) => g.id);

  if (groupIds.length) {
    await prisma.event.deleteMany({ where: { groupId: { in: groupIds } } });
    await prisma.membership.deleteMany({ where: { groupId: { in: groupIds } } });
    await prisma.invite.deleteMany({ where: { groupId: { in: groupIds } } });
    await prisma.familyGroup.deleteMany({ where: { id: { in: groupIds } } });
  }

  await prisma.oAuthAccount.deleteMany({
    where: { subject: { startsWith: 'seed-' } },
  });
  const orphanUsers = await prisma.user.findMany({
    where: { oauthAccounts: { none: {} }, phoneE164: null },
  });
  for (const u of orphanUsers) {
    await prisma.user.delete({ where: { id: u.id } }).catch(() => {});
  }
  console.log('[seed] reset 완료');
}

async function ensureGroup(name: string, adminId: string, memberUserIds: string[]) {
  let group = await prisma.familyGroup.findFirst({ where: { name } });
  if (!group) {
    group = await prisma.familyGroup.create({
      data: { name, adminUserId: adminId },
    });
  } else {
    group = await prisma.familyGroup.update({
      where: { id: group.id },
      data: { adminUserId: adminId },
    });
  }

  for (const userId of memberUserIds) {
    await prisma.membership.upsert({
      where: { groupId_userId: { groupId: group!.id, userId } },
      create: { groupId: group!.id, userId },
      update: {},
    });
  }

  return group;
}

async function main() {
  const memberTarget = Math.min(30, Math.max(2, Number(parseArg('members', '30'))));
  const groupCount = Math.min(10, Math.max(1, Number(parseArg('groups', '2'))));
  if (process.argv.includes('--reset')) await resetSeedData();

  const admin = await ensureOAuthUser('seed-admin', '시드관리자');
  const bulkUsers = [];
  for (let i = 1; i < memberTarget; i++) {
    bulkUsers.push(
      await ensureOAuthUser(`seed-member-${String(i).padStart(4, '0')}`, `멤버${i}`),
    );
  }
  const allMembers = [admin, ...bulkUsers];

  const groupA = await ensureGroup(
    SEED_GROUP_NAMES[0]!,
    admin.id,
    allMembers.map((u) => u.id),
  );

  await prisma.user.update({
    where: { id: admin.id },
    data: { lastActiveGroupId: groupA.id },
  });

  if (groupCount >= 2) {
    await ensureGroup(SEED_GROUP_NAMES[1]!, admin.id, [
      admin.id,
      bulkUsers[0]?.id,
      bulkUsers[1]?.id,
    ].filter(Boolean) as string[]);
  }

  const existingPoll = await prisma.event.findFirst({
    where: { groupId: groupA.id, title: POLL_TITLE },
  });

  if (!existingPoll) {
    const pollDeadline = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
    const event = await prisma.event.create({
      data: {
        groupId: groupA.id,
        organizerId: admin.id,
        title: POLL_TITLE,
        mode: 'poll',
        status: 'poll_open',
        pollDeadlineAt: pollDeadline,
        targetMemberIds: allMembers.map((u) => u.id),
        dateOptions: {
          create: [
            { startsAt: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000), sortOrder: 0 },
            { startsAt: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000), sortOrder: 1 },
          ],
        },
      },
      include: { dateOptions: true },
    });

    const [o1, o2] = event.dateOptions;
    const voters = allMembers.slice(0, Math.min(22, allMembers.length));
    for (let i = 0; i < voters.length; i++) {
      const u = voters[i]!;
      const optionId = i % 2 === 0 ? o1!.id : o2!.id;
      const value = i % 5 === 0 ? 'maybe' : i % 7 === 0 ? 'no' : 'yes';
      await prisma.dateVote.create({
        data: { eventId: event.id, optionId, userId: u.id, value },
      });
    }

    await prisma.invite.create({
      data: {
        groupId: groupA.id,
        token: `seed-${crypto.randomBytes(8).toString('hex')}`,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    console.log(
      `[seed] 투표 모임 생성 ${event.id} — 투표 ${voters.length}명, 미응답 ${allMembers.length - voters.length}명`,
    );
  }

  const countA = await prisma.membership.count({ where: { groupId: groupA.id } });
  console.log('\n=== 시드 완료 ===');
  console.log('로그인: 앱에서 Google/Kakao/Apple (시드 DB는 OAuth subject seed-*)');
  console.log(`통합 테스트: integration-admin / integration-user2 (google subject)`);
  console.log(`"${SEED_GROUP_NAMES[0]}": ${countA}명`);
  if (groupCount >= 2) console.log(`"${SEED_GROUP_NAMES[1]}": 다중 그룹 스위처용`);
  console.log('재시드: npm run db:seed -- --reset\n');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
