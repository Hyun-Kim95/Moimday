import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import type { FastifyRequest } from 'fastify';
import { prisma } from './prisma.js';
import { ERRORS } from './errors.js';

const JWT_SECRET = process.env.JWT_SECRET ?? 'dev-secret-change-me';
const ACCESS_TTL = Number(process.env.JWT_ACCESS_TTL_SEC ?? 3600);
const REFRESH_TTL = Number(process.env.JWT_REFRESH_TTL_SEC ?? 2592000);

export type JwtPayload = { sub: string; sv: number };

export function signAccessToken(userId: string, sessionVersion: number): string {
  return jwt.sign({ sub: userId, sv: sessionVersion } satisfies JwtPayload, JWT_SECRET, {
    expiresIn: ACCESS_TTL,
  });
}

export function signRefreshToken(userId: string, sessionVersion: number): string {
  return jwt.sign(
    { sub: userId, sv: sessionVersion, typ: 'refresh' },
    JWT_SECRET,
    { expiresIn: REFRESH_TTL },
  );
}

export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export async function getAuthUser(req: FastifyRequest) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) throw ERRORS.UNAUTHORIZED();
  try {
    const payload = jwt.verify(header.slice(7), JWT_SECRET) as JwtPayload;
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user || user.sessionVersion !== payload.sv) throw ERRORS.UNAUTHORIZED();
    return user;
  } catch {
    throw ERRORS.UNAUTHORIZED();
  }
}

export async function getUserMembership(userId: string) {
  return prisma.membership.findFirst({
    where: { userId },
    include: { group: { select: { id: true, adminUserId: true, name: true } } },
  });
}
