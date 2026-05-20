import { OAuth2Client } from 'google-auth-library';
import { ERRORS } from '../errors.js';
import type { OAuthProfile } from './types.js';

const clientIds = (process.env.GOOGLE_OAUTH_CLIENT_IDS ?? process.env.GOOGLE_OAUTH_CLIENT_ID ?? '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

export async function verifyGoogleIdToken(idToken: string): Promise<OAuthProfile> {
  if (!clientIds.length) throw ERRORS.SERVICE_UNAVAILABLE('Google OAuth not configured');
  const client = new OAuth2Client(clientIds[0]);
  const ticket = await client.verifyIdToken({
    idToken,
    audience: clientIds,
  });
  const payload = ticket.getPayload();
  if (!payload?.sub) throw ERRORS.UNAUTHORIZED();
  return {
    subject: payload.sub,
    email: payload.email ?? undefined,
    displayName: payload.name ?? undefined,
  };
}
