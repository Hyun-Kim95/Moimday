export type OAuthProvider = 'kakao' | 'google' | 'apple';

export type OAuthProfile = {
  subject: string;
  displayName?: string;
  email?: string;
};
