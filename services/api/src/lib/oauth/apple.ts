import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';
import { ERRORS } from '../errors.js';
import type { OAuthProfile } from './types.js';

const appleClient = jwksClient({
  jwksUri: 'https://appleid.apple.com/auth/keys',
  cache: true,
});

function getAppleAudience(): string[] {
  const raw = process.env.APPLE_CLIENT_IDS ?? process.env.APPLE_CLIENT_ID ?? '';
  return raw
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

export async function verifyAppleIdToken(idToken: string): Promise<OAuthProfile> {
  const audiences = getAppleAudience();
  if (!audiences.length) throw ERRORS.SERVICE_UNAVAILABLE('Apple Sign In not configured');

  const decoded = jwt.decode(idToken, { complete: true });
  if (!decoded || typeof decoded === 'string' || !decoded.header.kid) {
    throw ERRORS.UNAUTHORIZED();
  }

  const key = await appleClient.getSigningKey(decoded.header.kid);
  const signingKey = key.getPublicKey();

  const audience: string | [string, ...string[]] =
    audiences.length === 1 ? audiences[0]! : [audiences[0]!, ...audiences.slice(1)];

  const payload = jwt.verify(idToken, signingKey, {
    algorithms: ['RS256'],
    issuer: 'https://appleid.apple.com',
    audience,
  }) as jwt.JwtPayload;

  if (!payload.sub) throw ERRORS.UNAUTHORIZED();

  return {
    subject: payload.sub,
    email: typeof payload.email === 'string' ? payload.email : undefined,
    displayName: undefined,
  };
}
