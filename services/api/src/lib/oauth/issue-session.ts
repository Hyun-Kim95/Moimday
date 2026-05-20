import { prisma } from '../prisma.js';
import { hashToken, signAccessToken, signRefreshToken } from '../auth.js';
import type { OAuthProfile, OAuthProvider } from './types.js';

function defaultDisplayName(profile: OAuthProfile): string {
  if (profile.displayName?.trim()) return profile.displayName.trim().slice(0, 30);
  const tail = profile.subject.replace(/\D/g, '').slice(-4) || profile.subject.slice(0, 4);
  return `가족${tail}`;
}

export async function issueSessionForUser(userId: string) {
  const user = await prisma.user.update({
    where: { id: userId },
    data: { sessionVersion: { increment: 1 } },
  });
  const groupCount = await prisma.membership.count({ where: { userId: user.id } });
  const accessToken = signAccessToken(user.id, user.sessionVersion);
  const refreshToken = signRefreshToken(user.id, user.sessionVersion);
  await prisma.refreshToken.create({
    data: {
      userId: user.id,
      tokenHash: hashToken(refreshToken),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    },
  });
  return {
    accessToken,
    refreshToken,
    expiresInSec: 3600,
    user: {
      id: user.id,
      displayName: user.displayName,
      hasGroup: groupCount > 0,
    },
  };
}

export async function findOrCreateOAuthUser(
  provider: OAuthProvider,
  profile: OAuthProfile,
) {
  const existing = await prisma.oAuthAccount.findUnique({
    where: { provider_subject: { provider, subject: profile.subject } },
    include: { user: true },
  });
  if (existing) return existing.user;

  const email = profile.email?.trim() || null;
  if (email) {
    const byEmail = await prisma.user.findUnique({ where: { email } });
    if (byEmail) {
      await prisma.oAuthAccount.create({
        data: { provider, subject: profile.subject, userId: byEmail.id },
      });
      return byEmail;
    }
  }

  const user = await prisma.user.create({
    data: {
      displayName: defaultDisplayName(profile),
      email,
      ageConfirmedAt: new Date(),
      oauthAccounts: {
        create: { provider, subject: profile.subject },
      },
    },
  });
  return user;
}
