import { prisma } from './prisma.js';
import { ERRORS } from './errors.js';
import { MAX_GROUPS_PER_USER } from './event-helpers.js';

export async function getUserMemberships(userId: string) {
  return prisma.membership.findMany({
    where: { userId },
    include: { group: { select: { id: true, name: true, adminUserId: true } } },
    orderBy: { joinedAt: 'asc' },
  });
}

export async function countUserGroups(userId: string) {
  return prisma.membership.count({ where: { userId } });
}

export async function assertUnderGroupLimit(userId: string) {
  if ((await countUserGroups(userId)) >= MAX_GROUPS_PER_USER) {
    throw ERRORS.USER_GROUP_LIMIT();
  }
}

export async function resolveActiveGroupId(
  userId: string,
  lastActiveGroupId: string | null,
): Promise<string | null> {
  const memberships = await getUserMemberships(userId);
  if (!memberships.length) return null;

  if (lastActiveGroupId) {
    const ok = memberships.some((m) => m.groupId === lastActiveGroupId);
    if (ok) return lastActiveGroupId;
  }

  return memberships[0]!.groupId;
}

export async function setActiveGroup(userId: string, groupId: string) {
  const m = await prisma.membership.findUnique({
    where: { groupId_userId: { groupId, userId } },
  });
  if (!m) throw ERRORS.FORBIDDEN();

  await prisma.user.update({
    where: { id: userId },
    data: { lastActiveGroupId: groupId },
  });
}
