import { ERRORS } from '../errors.js';
import type { OAuthProfile } from './types.js';

export async function verifyKakaoAccessToken(accessToken: string): Promise<OAuthProfile> {
  const res = await fetch('https://kapi.kakao.com/v2/user/me', {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) throw ERRORS.UNAUTHORIZED();
  const data = (await res.json()) as {
    id?: number;
    kakao_account?: { email?: string; profile?: { nickname?: string } };
    properties?: { nickname?: string };
  };
  if (data.id == null) throw ERRORS.UNAUTHORIZED();
  const nickname =
    data.kakao_account?.profile?.nickname ?? data.properties?.nickname ?? undefined;
  return {
    subject: String(data.id),
    email: data.kakao_account?.email,
    displayName: nickname,
  };
}
