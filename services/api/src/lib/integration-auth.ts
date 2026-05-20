import { prisma } from './prisma.js';
import { signAccessToken } from './auth.js';

const TEST_PROVIDER = 'google';

/** 통합 테스트 전용 — OAuth HTTP 없이 JWT 발급 */
export async function issueTestAccessToken(subject: string, displayName: string): Promise<string> {
  const existing = await prisma.oAuthAccount.findUnique({
    where: { provider_subject: { provider: TEST_PROVIDER, subject } },
  });

  let userId = existing?.userId;
  if (!userId) {
    const created = await prisma.user.create({
      data: {
        displayName,
        ageConfirmedAt: new Date(),
        oauthAccounts: { create: { provider: TEST_PROVIDER, subject } },
      },
    });
    userId = created.id;
  }

  const user = await prisma.user.update({
    where: { id: userId },
    data: { sessionVersion: { increment: 1 }, displayName },
  });

  return signAccessToken(user.id, user.sessionVersion);
}
