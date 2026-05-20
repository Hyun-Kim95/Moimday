import { readFileSync } from 'fs';
import { prisma } from './prisma.js';

const FCM_ENABLED = process.env.FCM_ENABLED === 'true';
const FCM_PROJECT_ID = process.env.FCM_PROJECT_ID ?? '';

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
};

let cachedToken: { token: string; exp: number } | null = null;

function loadServiceAccount(): ServiceAccount | null {
  const json = process.env.FCM_SERVICE_ACCOUNT_JSON;
  const path = process.env.FCM_SERVICE_ACCOUNT_PATH;
  try {
    if (json) return JSON.parse(json) as ServiceAccount;
    if (path) return JSON.parse(readFileSync(path, 'utf8')) as ServiceAccount;
  } catch {
    return null;
  }
  return null;
}

async function getAccessToken(sa: ServiceAccount): Promise<string | null> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp > now + 60) return cachedToken.token;

  const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const claim = Buffer.from(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  ).toString('base64url');

  const crypto = await import('crypto');
  const signInput = `${header}.${claim}`;
  const signature = crypto
    .createSign('RSA-SHA256')
    .update(signInput)
    .sign(sa.private_key, 'base64url');

  const jwt = `${signInput}.${signature}`;
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) return null;
  const data = (await res.json()) as { access_token: string; expires_in: number };
  cachedToken = { token: data.access_token, exp: now + data.expires_in };
  return data.access_token;
}

export async function sendFcmToUser(
  userId: string,
  payload: { title: string; body: string; eventId?: string },
  log?: { warn: (o: unknown, msg?: string) => void },
): Promise<void> {
  if (!FCM_ENABLED) return;
  const sa = loadServiceAccount();
  const projectId = FCM_PROJECT_ID || sa?.project_id;
  if (!sa || !projectId) {
    log?.warn({}, 'FCM enabled but service account missing');
    return;
  }

  const tokens = await prisma.pushToken.findMany({ where: { userId } });
  if (!tokens.length) return;

  const access = await getAccessToken(sa);
  if (!access) return;

  for (const { token } of tokens) {
    await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${access}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: payload.title, body: payload.body },
          data: payload.eventId ? { eventId: payload.eventId } : {},
        },
      }),
    });
  }
}
