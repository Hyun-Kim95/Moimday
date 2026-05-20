import type { FastifyInstance } from 'fastify';
import crypto from 'crypto';
import { prisma } from '../lib/prisma.js';
import { ERRORS } from '../lib/errors.js';
import { getAuthUser } from '../lib/auth.js';
import {
  assertUnderGroupLimit,
  resolveActiveGroupId,
  setActiveGroup,
} from '../lib/group-membership.js';
import {
  assertMember,
  getGroupMemberIds,
  groupCapacityUsage,
  MAX_MEMBERS,
  memberCount,
  loadEvent,
  parseTargetIds,
  serializeEvent,
} from '../lib/event-helpers.js';
import { validateFixedCreate, validatePollCreate } from '../lib/event-deadline.js';

export async function groupRoutes(app: FastifyInstance) {
  app.post('/groups', async (req) => {
    const user = await getAuthUser(req);
    await assertUnderGroupLimit(user.id);
    const body = req.body as { name?: string };
    if (!body?.name?.trim()) throw ERRORS.VALIDATION_ERROR();

    const group = await prisma.familyGroup.create({
      data: {
        name: body.name.trim().slice(0, 30),
        adminUserId: user.id,
        memberships: { create: { userId: user.id } },
      },
    });

    await prisma.user.update({
      where: { id: user.id },
      data: { lastActiveGroupId: group.id },
    });

    const inviteToken = crypto.randomBytes(16).toString('hex');
    await prisma.invite.create({
      data: {
        groupId: group.id,
        token: inviteToken,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    return {
      group: {
        id: group.id,
        name: group.name,
        adminUserId: group.adminUserId,
        inviteUrl: `moimday://invite/${inviteToken}`,
      },
    };
  });

  app.get('/groups/:groupId', async (req) => {
    const user = await getAuthUser(req);
    const { groupId } = req.params as { groupId: string };
    await assertMember(groupId, user.id);

    const group = await prisma.familyGroup.findUnique({
      where: { id: groupId },
      include: {
        memberships: { include: { user: true } },
        invites: { where: { revokedAt: null, expiresAt: { gt: new Date() } } },
      },
    });
    if (!group) throw ERRORS.NOT_FOUND();

    return {
      id: group.id,
      name: group.name,
      adminUserId: group.adminUserId,
      maxMembers: MAX_MEMBERS,
      memberCount: group.memberships.length,
      capacityUsed: await groupCapacityUsage(groupId),
      pendingInviteCount: group.invites.length,
      members: group.memberships.map((m) => ({
        userId: m.userId,
        displayName: m.nickname ?? m.user.displayName,
        isAdmin: m.userId === group.adminUserId,
      })),
    };
  });

  app.post('/groups/:groupId/invites', async (req) => {
    const user = await getAuthUser(req);
    const { groupId } = req.params as { groupId: string };
    const group = await prisma.familyGroup.findUnique({ where: { id: groupId } });
    if (!group || group.adminUserId !== user.id) throw ERRORS.FORBIDDEN();
    if ((await groupCapacityUsage(groupId)) >= MAX_MEMBERS) throw ERRORS.GROUP_FULL();

    const token = crypto.randomBytes(16).toString('hex');
    const invite = await prisma.invite.create({
      data: {
        groupId,
        token,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });
    return {
      inviteUrl: `moimday://invite/${invite.token}`,
      expiresAt: invite.expiresAt.toISOString(),
    };
  });

  app.post('/invites/:token/accept', async (req) => {
    const user = await getAuthUser(req);
    const { token } = req.params as { token: string };

    const invite = await prisma.invite.findUnique({ where: { token } });
    if (!invite || invite.revokedAt) throw ERRORS.NOT_FOUND();
    if (invite.expiresAt < new Date()) throw ERRORS.INVITE_EXPIRED();

    const already = await prisma.membership.findUnique({
      where: { groupId_userId: { groupId: invite.groupId, userId: user.id } },
    });
    if (already) {
      await setActiveGroup(user.id, invite.groupId);
      return { groupId: invite.groupId, alreadyMember: true };
    }

    await assertUnderGroupLimit(user.id);
    if ((await groupCapacityUsage(invite.groupId)) >= MAX_MEMBERS) throw ERRORS.GROUP_FULL();

    await prisma.membership.create({
      data: { groupId: invite.groupId, userId: user.id },
    });
    await setActiveGroup(user.id, invite.groupId);
    return { groupId: invite.groupId, alreadyMember: false };
  });

  app.get('/groups/:groupId/home', async (req) => {
    const user = await getAuthUser(req);
    const { groupId } = req.params as { groupId: string };
    await assertMember(groupId, user.id);

    const events = await prisma.event.findMany({
      where: { groupId, status: { not: 'cancelled' } },
      include: { organizer: true, dateOptions: true, dateVotes: true, eventResponses: true },
    });

    const memberIds = await getGroupMemberIds(groupId);
    const members = await prisma.user.findMany({
      where: { id: { in: memberIds } },
    });
    const nameMap = Object.fromEntries(members.map((m) => [m.id, m.displayName]));

    const actionRequired: unknown[] = [];
    const upcomingFinalized: unknown[] = [];
    const familyPending: unknown[] = [];

    for (const e of events) {
      const targets = parseTargetIds(e.targetMemberIds).length
        ? parseTargetIds(e.targetMemberIds)
        : memberIds;
      if (e.status === 'poll_open') {
        const voted = new Set(e.dateVotes.filter((v) => v.userId === user.id).map((v) => v.optionId));
        const needsPoll = e.dateOptions.some((o) => !voted.has(o.id));
        if (needsPoll) {
          actionRequired.push({
            eventId: e.id,
            title: e.title,
            actionType: 'poll',
            deadlineAt: e.pollDeadlineAt?.toISOString(),
          });
        }
        const pendingIds = targets.filter(
          (uid) => !e.dateVotes.some((v) => v.userId === uid),
        );
        if (pendingIds.length) {
          familyPending.push({
            eventId: e.id,
            eventTitle: e.title,
            phase: 'poll',
            pendingMemberIds: pendingIds,
            pendingDisplayNames: pendingIds.map((id) => nameMap[id] ?? ''),
          });
        }
      }
      if (e.status === 'attendance_open') {
        const responded = e.eventResponses.some((r) => r.userId === user.id);
        if (!responded) {
          actionRequired.push({
            eventId: e.id,
            title: e.title,
            actionType: 'attendance',
            deadlineAt: e.attendanceDeadlineAt?.toISOString(),
          });
        }
        const pendingIds = targets.filter(
          (uid) => !e.eventResponses.some((r) => r.userId === uid),
        );
        if (pendingIds.length) {
          familyPending.push({
            eventId: e.id,
            eventTitle: e.title,
            phase: 'attendance',
            pendingMemberIds: pendingIds,
            pendingDisplayNames: pendingIds.map((id) => nameMap[id] ?? ''),
          });
        }
      }
      if (e.status === 'finalized' && e.confirmedStartsAt) {
        upcomingFinalized.push({
          eventId: e.id,
          title: e.title,
          startsAt: e.confirmedStartsAt.toISOString(),
          place: e.place,
        });
      }
    }

    upcomingFinalized.sort(
      (a, b) =>
        new Date((a as { startsAt: string }).startsAt).getTime() -
        new Date((b as { startsAt: string }).startsAt).getTime(),
    );

    return { actionRequired, upcomingFinalized, familyPending };
  });

  app.get('/groups/:groupId/calendar', async (req) => {
    const user = await getAuthUser(req);
    const { groupId } = req.params as { groupId: string };
    await assertMember(groupId, user.id);
    const q = req.query as { from?: string; to?: string };

    const events = await prisma.event.findMany({
      where: {
        groupId,
        status: 'finalized',
        confirmedStartsAt: { not: null },
      },
    });

    let items = events.map((e) => ({
      eventId: e.id,
      title: e.title,
      startsAt: e.confirmedStartsAt!.toISOString(),
      place: e.place,
      isAllDay: e.isAllDay,
    }));

    if (q.from) {
      const from = new Date(q.from);
      items = items.filter((i) => new Date(i.startsAt) >= from);
    }
    if (q.to) {
      const to = new Date(q.to);
      items = items.filter((i) => new Date(i.startsAt) <= to);
    }

    return { items };
  });

  app.get('/groups/:groupId/events', async (req) => {
    const user = await getAuthUser(req);
    const { groupId } = req.params as { groupId: string };
    await assertMember(groupId, user.id);
    const filter = (req.query as { filter?: string }).filter ?? 'all';

    const events = await prisma.event.findMany({
      where: { groupId },
      orderBy: { createdAt: 'desc' },
      include: { dateVotes: true, eventResponses: true },
    });

    const mapped = events
      .map((e) => {
        const needsAction =
          (e.status === 'poll_open' && !e.dateVotes.some((v) => v.userId === user.id)) ||
          (e.status === 'attendance_open' &&
            !e.eventResponses.some((r) => r.userId === user.id));
        return {
          id: e.id,
          title: e.title,
          status: e.status,
          mode: e.mode,
          pollDeadlineAt: e.pollDeadlineAt?.toISOString() ?? null,
          attendanceDeadlineAt: e.attendanceDeadlineAt?.toISOString() ?? null,
          confirmedStartsAt: e.confirmedStartsAt?.toISOString() ?? null,
          needsAction,
        };
      })
      .filter((e) => (filter === 'my_pending' ? e.needsAction : true));

    return { events: mapped };
  });

  app.post('/groups/:groupId/events', async (req, reply) => {
    const user = await getAuthUser(req);
    const { groupId } = req.params as { groupId: string };
    await assertMember(groupId, user.id);
    const body = req.body as Record<string, unknown>;

    const memberIds = await getGroupMemberIds(groupId);
    const targetMemberIds = (body.targetMemberIds as string[] | null) ?? memberIds;

    if (body.mode === 'poll') {
      const options = body.options as { startsAt: string; isAllDay?: boolean }[];
      if (!body.title || !options?.length || options.length < 2 || options.length > 5) {
        throw ERRORS.VALIDATION_ERROR();
      }
      if (!body.pollDeadlineAt) throw ERRORS.VALIDATION_ERROR();
      validatePollCreate(String(body.pollDeadlineAt), options);
      const event = await prisma.event.create({
        data: {
          groupId,
          organizerId: user.id,
          title: String(body.title).slice(0, 50),
          mode: 'poll',
          status: 'poll_open',
          place: body.place ? String(body.place) : null,
          memo: body.memo ? String(body.memo) : null,
          pollDeadlineAt: new Date(String(body.pollDeadlineAt)),
          targetMemberIds,
          dateOptions: {
            create: options.map((o, i) => ({
              startsAt: new Date(o.startsAt),
              isAllDay: !!o.isAllDay,
              sortOrder: i,
            })),
          },
        },
        include: { dateOptions: { orderBy: { sortOrder: 'asc' } }, organizer: true },
      });
      const loadedPoll = await loadEvent(event.id);
      return reply.status(201).send(serializeEvent(loadedPoll!));
    }

    if (body.mode === 'fixed') {
      if (!body.title || !body.confirmedStartsAt || !body.attendanceDeadlineAt) {
        throw ERRORS.VALIDATION_ERROR();
      }
      validateFixedCreate(
        String(body.confirmedStartsAt),
        String(body.attendanceDeadlineAt),
      );
      const event = await prisma.event.create({
        data: {
          groupId,
          organizerId: user.id,
          title: String(body.title).slice(0, 50),
          mode: 'fixed',
          status: 'attendance_open',
          place: body.place ? String(body.place) : null,
          memo: body.memo ? String(body.memo) : null,
          confirmedStartsAt: new Date(String(body.confirmedStartsAt)),
          isAllDay: !!body.isAllDay,
          attendanceDeadlineAt: new Date(String(body.attendanceDeadlineAt)),
          targetMemberIds,
        },
        include: { dateOptions: true, organizer: true },
      });
      const loadedFixed = await loadEvent(event.id);
      return reply.status(201).send(serializeEvent(loadedFixed!));
    }

    throw ERRORS.VALIDATION_ERROR();
  });

  app.post('/groups/:groupId/leave', async (req) => {
    const user = await getAuthUser(req);
    const { groupId } = req.params as { groupId: string };
    await assertMember(groupId, user.id);
    const group = await prisma.familyGroup.findUnique({ where: { id: groupId } });
    if (!group) throw ERRORS.NOT_FOUND();

    const body = req.body as { transferAdminToUserId?: string } | undefined;
    if (group.adminUserId === user.id) {
      const transferTo = body?.transferAdminToUserId;
      if (!transferTo) throw ERRORS.ADMIN_TRANSFER_REQUIRED();
      const targetMember = await prisma.membership.findUnique({
        where: { groupId_userId: { groupId, userId: transferTo } },
      });
      if (!targetMember || transferTo === user.id) throw ERRORS.VALIDATION_ERROR();
      await prisma.familyGroup.update({
        where: { id: groupId },
        data: { adminUserId: transferTo },
      });
    }

    await prisma.membership.delete({
      where: { groupId_userId: { groupId, userId: user.id } },
    });

    const current = await prisma.user.findUnique({ where: { id: user.id } });
    if (current?.lastActiveGroupId === groupId) {
      const next = await resolveActiveGroupId(user.id, null);
      await prisma.user.update({
        where: { id: user.id },
        data: { lastActiveGroupId: next },
      });
    }

    return { ok: true };
  });

  app.post('/groups/:groupId/admin/transfer', async (req) => {
    const user = await getAuthUser(req);
    const { groupId } = req.params as { groupId: string };
    const group = await prisma.familyGroup.findUnique({ where: { id: groupId } });
    if (!group || group.adminUserId !== user.id) throw ERRORS.FORBIDDEN();

    const body = req.body as { newAdminUserId?: string };
    if (!body?.newAdminUserId) throw ERRORS.VALIDATION_ERROR();
    const target = await prisma.membership.findUnique({
      where: { groupId_userId: { groupId, userId: body.newAdminUserId } },
    });
    if (!target) throw ERRORS.VALIDATION_ERROR();

    await prisma.familyGroup.update({
      where: { id: groupId },
      data: { adminUserId: body.newAdminUserId },
    });
    return { adminUserId: body.newAdminUserId };
  });

  app.delete('/groups/:groupId/members/:userId', async (req) => {
    const user = await getAuthUser(req);
    const { groupId, userId: targetUserId } = req.params as { groupId: string; userId: string };
    const group = await prisma.familyGroup.findUnique({ where: { id: groupId } });
    if (!group || group.adminUserId !== user.id) throw ERRORS.FORBIDDEN();
    if (targetUserId === user.id) throw ERRORS.VALIDATION_ERROR();

    await prisma.membership.delete({
      where: { groupId_userId: { groupId, userId: targetUserId } },
    });
    return { ok: true };
  });

  app.delete('/groups/:groupId', async (req) => {
    const user = await getAuthUser(req);
    const { groupId } = req.params as { groupId: string };
    const group = await prisma.familyGroup.findUnique({ where: { id: groupId } });
    if (!group || group.adminUserId !== user.id) throw ERRORS.FORBIDDEN();

    await prisma.event.updateMany({
      where: { groupId, status: { notIn: ['cancelled', 'finalized'] } },
      data: { status: 'cancelled', cancelledAt: new Date() },
    });
    await prisma.familyGroup.delete({ where: { id: groupId } });
    return { ok: true };
  });
}
