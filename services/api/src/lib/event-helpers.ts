import { prisma } from './prisma.js';
import { ERRORS } from './errors.js';

export const MAX_MEMBERS = 30;
export const MAX_GROUPS_PER_USER = 10;

export async function getGroupMemberIds(groupId: string): Promise<string[]> {
  const members = await prisma.membership.findMany({
    where: { groupId },
    select: { userId: true },
  });
  return members.map((m) => m.userId);
}

export async function assertMember(groupId: string, userId: string) {
  const m = await prisma.membership.findUnique({
    where: { groupId_userId: { groupId, userId } },
  });
  if (!m) throw ERRORS.FORBIDDEN();
}

/** Active members only (for targets, lists). */
export async function memberCount(groupId: string) {
  return prisma.membership.count({ where: { groupId } });
}

/** P-G3: members + non-expired, non-revoked invites. */
export async function groupCapacityUsage(groupId: string) {
  const members = await memberCount(groupId);
  const pendingInvites = await prisma.invite.count({
    where: {
      groupId,
      revokedAt: null,
      expiresAt: { gt: new Date() },
    },
  });
  return members + pendingInvites;
}

export function parseTargetIds(raw: unknown): string[] {
  if (Array.isArray(raw)) return raw as string[];
  if (typeof raw === 'string') {
    try {
      const parsed = JSON.parse(raw) as unknown;
      return Array.isArray(parsed) ? (parsed as string[]) : [];
    } catch {
      return [];
    }
  }
  return [];
}

export function serializeEvent(event: Awaited<ReturnType<typeof loadEvent>>) {
  if (!event) return null;
  return {
    id: event.id,
    groupId: event.groupId,
    organizerId: event.organizerId,
    groupAdminId: event.group.adminUserId,
    title: event.title,
    mode: event.mode,
    status: event.status,
    place: event.place,
    memo: event.memo,
    confirmedStartsAt: event.confirmedStartsAt?.toISOString() ?? null,
    isAllDay: event.isAllDay,
    pollDeadlineAt: event.pollDeadlineAt?.toISOString() ?? null,
    attendanceDeadlineAt: event.attendanceDeadlineAt?.toISOString() ?? null,
    targetMemberIds: parseTargetIds(event.targetMemberIds),
    version: event.version,
    cancelledAt: event.cancelledAt?.toISOString() ?? null,
    finalizedAt: event.finalizedAt?.toISOString() ?? null,
    options: event.dateOptions.map((o) => ({
      id: o.id,
      startsAt: o.startsAt.toISOString(),
      isAllDay: o.isAllDay,
      sortOrder: o.sortOrder,
    })),
    organizerDisplayName: event.organizer.displayName,
  };
}

export async function loadEvent(eventId: string) {
  return prisma.event.findUnique({
    where: { id: eventId },
    include: {
      dateOptions: { orderBy: { sortOrder: 'asc' } },
      organizer: true,
      group: true,
      dateVotes: true,
      eventResponses: true,
    },
  });
}
