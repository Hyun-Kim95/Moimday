import type { FastifyInstance } from 'fastify';
import { hashToken, signAccessToken, signRefreshToken } from '../lib/auth.js';
import { ERRORS } from '../lib/errors.js';
import { prisma } from '../lib/prisma.js';
import { verifyAppleIdToken } from '../lib/oauth/apple.js';
import { verifyGoogleIdToken } from '../lib/oauth/google.js';
import { verifyKakaoAccessToken } from '../lib/oauth/kakao.js';
import { findOrCreateOAuthUser, issueSessionForUser } from '../lib/oauth/issue-session.js';
import type { OAuthProvider } from '../lib/oauth/types.js';

const PROVIDERS: OAuthProvider[] = ['kakao', 'google', 'apple'];

function parseProvider(raw: string): OAuthProvider {
  if (PROVIDERS.includes(raw as OAuthProvider)) return raw as OAuthProvider;
  throw ERRORS.OAUTH_PROVIDER_INVALID();
}

export async function authRoutes(app: FastifyInstance) {
  app.post('/auth/oauth/:provider', async (req) => {
    const provider = parseProvider((req.params as { provider: string }).provider);
    const body = req.body as { idToken?: string; accessToken?: string };

    let profile;
    if (provider === 'kakao') {
      if (!body.accessToken?.trim()) throw ERRORS.VALIDATION_ERROR();
      profile = await verifyKakaoAccessToken(body.accessToken.trim());
    } else {
      if (!body.idToken?.trim()) throw ERRORS.VALIDATION_ERROR();
      profile =
        provider === 'google'
          ? await verifyGoogleIdToken(body.idToken.trim())
          : await verifyAppleIdToken(body.idToken.trim());
    }

    const user = await findOrCreateOAuthUser(provider, profile);
    return issueSessionForUser(user.id);
  });

  app.post('/auth/token/refresh', async (req, reply) => {
    const body = req.body as { refreshToken?: string };
    if (!body?.refreshToken) throw ERRORS.UNAUTHORIZED();
    const stored = await prisma.refreshToken.findUnique({
      where: { tokenHash: hashToken(body.refreshToken) },
      include: { user: true },
    });
    if (!stored || stored.expiresAt < new Date()) throw ERRORS.UNAUTHORIZED();
    const accessToken = signAccessToken(stored.user.id, stored.user.sessionVersion);
    return { accessToken, expiresInSec: 3600 };
  });
}
