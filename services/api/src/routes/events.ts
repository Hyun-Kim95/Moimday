import type { FastifyInstance } from 'fastify';
import { prisma } from '../lib/prisma.js';
import { ERRORS } from '../lib/errors.js';
import { getAuthUser } from '../lib/auth.js';
import {
  assertMember,
  getGroupMemberIds,
  loadEvent,
  parseTargetIds,
  serializeEvent,
} from '../lib/event-helpers.js';
import {
  assertFutureDate,
  defaultAttendanceDeadline,
  validatePollDeadlineExtension,
  validatePollCreate,
  validateFixedCreate,
} from '../lib/event-deadline.js';

export async function eventRoutes(app: FastifyInstance) {
  app.get('/events/:eventId', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    await assertMember(event.groupId, user.id);

    const memberIds = parseTargetIds(event.targetMemberIds).length
      ? parseTargetIds(event.targetMemberIds)
      : await getGroupMemberIds(event.groupId);
    const members = await prisma.user.findMany({ where: { id: { in: memberIds } } });
    const nameMap = Object.fromEntries(members.map((m) => [m.id, m.displayName]));

    const myVotes = event.dateVotes.filter((v) => v.userId === user.id);
    const myResponse = event.eventResponses.find((r) => r.userId === user.id);

    const pendingPoll = memberIds.filter(
      (id) => !event.dateVotes.some((v) => v.userId === id),
    );
    const pendingAttend = memberIds.filter(
      (id) => !event.eventResponses.some((r) => r.userId === id),
    );

    return {
      ...serializeEvent(event),
      isOrganizer: event.organizerId === user.id,
      myVotes: myVotes.map((v) => ({ optionId: v.optionId, value: v.value })),
      myResponse: myResponse
        ? { value: myResponse.value, note: myResponse.note }
        : null,
      pendingPollMemberIds: event.status === 'poll_open' ? pendingPoll : [],
      pendingPollDisplayNames: pendingPoll.map((id) => nameMap[id] ?? ''),
      pendingAttendMemberIds: event.status === 'attendance_open' ? pendingAttend : [],
      pendingAttendDisplayNames: pendingAttend.map((id) => nameMap[id] ?? ''),
    };
  });

  app.patch('/events/:eventId', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    if (event.status === 'cancelled') throw ERRORS.EVENT_CANCELLED();
    if (event.organizerId !== user.id) throw ERRORS.FORBIDDEN();

    const ifMatch = req.headers['if-match'];
    const body = req.body as Record<string, unknown>;
    const version = Number(ifMatch);
    if (!version || version !== event.version) throw ERRORS.VERSION_MISMATCH();

    if (body.pollDeadlineAt && event.status === 'poll_open') {
      const opts = event.dateOptions.map((o) => o.startsAt);
      validatePollDeadlineExtension(String(body.pollDeadlineAt), opts);
    }
    if (body.attendanceDeadlineAt && event.status === 'attendance_open' && event.confirmedStartsAt) {
      validateFixedCreate(event.confirmedStartsAt, String(body.attendanceDeadlineAt));
    }

    const updated = await prisma.event.update({
      where: { id: eventId },
      data: {
        title: body.title ? String(body.title).slice(0, 50) : undefined,
        place: body.place !== undefined ? (body.place ? String(body.place) : null) : undefined,
        memo: body.memo !== undefined ? (body.memo ? String(body.memo) : null) : undefined,
        pollDeadlineAt: body.pollDeadlineAt
          ? new Date(String(body.pollDeadlineAt))
          : undefined,
        attendanceDeadlineAt: body.attendanceDeadlineAt
          ? new Date(String(body.attendanceDeadlineAt))
          : undefined,
        version: { increment: 1 },
      },
      include: { dateOptions: { orderBy: { sortOrder: 'asc' } }, organizer: true },
    });
    const refreshed = await loadEvent(eventId);
    return serializeEvent(refreshed!);
  });

  app.post('/events/:eventId/cancel', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    if (event.organizerId !== user.id) throw ERRORS.FORBIDDEN();

    const updated = await prisma.event.update({
      where: { id: eventId },
      data: { status: 'cancelled', cancelledAt: new Date(), version: { increment: 1 } },
      include: { dateOptions: true, organizer: true },
    });
    const refreshedCancel = await loadEvent(eventId);
    return serializeEvent(refreshedCancel!);
  });

  app.post('/events/:eventId/confirm-datetime', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const body = req.body as { optionId?: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    if (event.organizerId !== user.id) throw ERRORS.FORBIDDEN();
    if (event.status !== 'poll_open') throw ERRORS.POLL_CLOSED();

    const option = event.dateOptions.find((o) => o.id === body.optionId);
    if (!option) throw ERRORS.VALIDATION_ERROR();
    assertFutureDate(option.startsAt, '확정 일시');

    const deadline = defaultAttendanceDeadline(option.startsAt);

    const updated = await prisma.event.update({
      where: { id: eventId },
      data: {
        status: 'attendance_open',
        confirmedStartsAt: option.startsAt,
        isAllDay: option.isAllDay,
        attendanceDeadlineAt: deadline,
        version: { increment: 1 },
      },
      include: { dateOptions: true, organizer: true },
    });
    const refreshedConfirm = await loadEvent(eventId);
    return serializeEvent(refreshedConfirm!);
  });

  app.post('/events/:eventId/finalize', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    if (event.organizerId !== user.id) throw ERRORS.FORBIDDEN();
    if (event.status !== 'attendance_open') throw ERRORS.VALIDATION_ERROR('참석 수집 중인 모임만 확정할 수 있어요.');

    const updated = await prisma.event.update({
      where: { id: eventId },
      data: {
        status: 'finalized',
        finalizedAt: new Date(),
        version: { increment: 1 },
      },
      include: { dateOptions: true, organizer: true },
    });
    const refreshedFinalize = await loadEvent(eventId);
    return serializeEvent(refreshedFinalize!);
  });

  app.post('/events/:eventId/extend-poll-deadline', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const body = req.body as {
      pollDeadlineAt?: string;
      optionChanges?: { add?: { startsAt: string; isAllDay?: boolean }[] };
    };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    if (event.organizerId !== user.id) throw ERRORS.FORBIDDEN();
    if (event.status !== 'poll_open') throw ERRORS.POLL_CLOSED();

    if (!body.pollDeadlineAt) throw ERRORS.VALIDATION_ERROR();
    const optionStarts = event.dateOptions.map((o) => o.startsAt);
    validatePollDeadlineExtension(body.pollDeadlineAt, optionStarts);

    const adds = body.optionChanges?.add ?? [];
    if (event.dateOptions.length + adds.length > 5) throw ERRORS.VALIDATION_ERROR();
    for (const a of adds) assertFutureDate(new Date(a.startsAt), '후보 일시');

    await prisma.$transaction(async (tx) => {
      if (adds.length) {
        const baseOrder = event.dateOptions.length;
        await tx.dateOption.createMany({
          data: adds.map((a, i) => ({
            eventId,
            startsAt: new Date(a.startsAt),
            isAllDay: !!a.isAllDay,
            sortOrder: baseOrder + i,
          })),
        });
      }
      await tx.event.update({
        where: { id: eventId },
        data: {
          pollDeadlineAt: new Date(body.pollDeadlineAt!),
          version: { increment: 1 },
        },
      });
    });

    const refreshed = await loadEvent(eventId);
    return serializeEvent(refreshed!);
  });

  app.put('/events/:eventId/date-options', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const body = req.body as { options?: { startsAt: string; isAllDay?: boolean }[] };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    if (event.organizerId !== user.id) throw ERRORS.FORBIDDEN();
    if (event.status !== 'poll_open') throw ERRORS.POLL_CLOSED();

    const options = body.options ?? [];
    if (options.length < 2 || options.length > 5) throw ERRORS.VALIDATION_ERROR();
    if (!event.pollDeadlineAt) throw ERRORS.VALIDATION_ERROR();
    validatePollCreate(event.pollDeadlineAt, options);

    await prisma.$transaction([
      prisma.dateVote.deleteMany({ where: { eventId } }),
      prisma.dateOption.deleteMany({ where: { eventId } }),
      prisma.dateOption.createMany({
        data: options.map((o, i) => ({
          eventId,
          startsAt: new Date(o.startsAt),
          isAllDay: !!o.isAllDay,
          sortOrder: i,
        })),
      }),
      prisma.event.update({
        where: { id: eventId },
        data: { version: { increment: 1 } },
      }),
    ]);

    const refreshed = await loadEvent(eventId);
    return serializeEvent(refreshed!);
  });

  app.put('/events/:eventId/date-votes', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    if (event.status !== 'poll_open') throw ERRORS.POLL_CLOSED();
    if (event.pollDeadlineAt && event.pollDeadlineAt.getTime() <= Date.now()) {
      throw ERRORS.POLL_CLOSED();
    }

    const body = req.body as { votes?: { optionId: string; value: string }[] };
    if (!body.votes?.length) throw ERRORS.VALIDATION_ERROR();
    const optionIds = new Set(event.dateOptions.map((o) => o.id));
    if (body.votes.length !== event.dateOptions.length) throw ERRORS.INCOMPLETE_POLL();
    for (const v of body.votes) {
      if (!optionIds.has(v.optionId)) throw ERRORS.VALIDATION_ERROR();
    }

    await prisma.$transaction(
      body.votes.map((v) =>
        prisma.dateVote.upsert({
          where: { optionId_userId: { optionId: v.optionId, userId: user.id } },
          create: {
            eventId,
            optionId: v.optionId,
            userId: user.id,
            value: v.value,
          },
          update: { value: v.value },
        }),
      ),
    );
    return { ok: true };
  });

  app.get('/events/:eventId/date-poll-summary', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    await assertMember(event.groupId, user.id);

    const memberIds = event.targetMemberIds.length
      ? event.targetMemberIds
      : await getGroupMemberIds(event.groupId);
    const members = await prisma.user.findMany({ where: { id: { in: memberIds } } });
    const nameMap = Object.fromEntries(members.map((m) => [m.id, m.displayName]));

    const mapMembers = (votes: typeof event.dateVotes, value: 'yes' | 'no' | 'maybe' | null) =>
      memberIds
        .filter((uid) => {
          const v = votes.find((x) => x.userId === uid);
          if (value === null) return !v;
          return v?.value === value;
        })
        .map((uid) => ({ userId: uid, displayName: nameMap[uid] ?? '' }));

    const options = event.dateOptions.map((o) => {
      const votes = event.dateVotes.filter((v) => v.optionId === o.id);
      const counts = { yes: 0, no: 0, maybe: 0, pending: 0 };
      for (const uid of memberIds) {
        const v = votes.find((x) => x.userId === uid);
        if (!v) counts.pending++;
        else if (v.value === 'yes') counts.yes++;
        else if (v.value === 'no') counts.no++;
        else counts.maybe++;
      }
      const yesMembers = mapMembers(votes, 'yes');
      const noMembers = mapMembers(votes, 'no');
      const maybeMembers = mapMembers(votes, 'maybe');
      const pendingMembers = mapMembers(votes, null);
      return {
        optionId: o.id,
        startsAt: o.startsAt.toISOString(),
        counts,
        yesMembers,
        noMembers,
        maybeMembers,
        pendingMembers,
        recommended: counts.yes === Math.max(counts.yes, counts.no, counts.maybe),
      };
    });

    return {
      options,
      pollDeadlineAt: event.pollDeadlineAt?.toISOString(),
      status: event.status,
    };
  });

  app.put('/events/:eventId/responses', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    if (event.status === 'cancelled') throw ERRORS.EVENT_CANCELLED();
    if (event.status === 'poll_open') throw ERRORS.DATETIME_NOT_CONFIRMED();
    if (event.status !== 'attendance_open') throw ERRORS.ATTENDANCE_CLOSED();

    const body = req.body as { value?: string; note?: string };
    if (!body.value) throw ERRORS.VALIDATION_ERROR();

    await prisma.eventResponse.upsert({
      where: { eventId_userId: { eventId, userId: user.id } },
      create: {
        eventId,
        userId: user.id,
        value: body.value,
        note: body.note?.slice(0, 100) ?? null,
      },
      update: { value: body.value, note: body.note?.slice(0, 100) ?? null },
    });
    return { ok: true };
  });

  app.post('/events/:eventId/nudge', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    if (event.organizerId !== user.id) throw ERRORS.FORBIDDEN();
    if (event.lastNudgeAt) {
      const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      if (event.lastNudgeAt > dayAgo) throw ERRORS.NUDGE_RATE_LIMITED();
    }

    const memberIds = await getGroupMemberIds(event.groupId);
    let sentCount = 0;
    for (const uid of memberIds) {
      if (uid === user.id) continue;
      const needs =
        event.status === 'poll_open'
          ? !event.dateVotes.some((v) => v.userId === uid)
          : !event.eventResponses.some((r) => r.userId === uid);
      if (needs) {
        await prisma.notification.create({
          data: {
            userId: uid,
            type: 'nudge',
            eventId,
            title: '가족 모임 알림',
            body: `「${event.title}」에 아직 응답하지 않았어요.`,
          },
        });
        sentCount++;
      }
    }
    await prisma.event.update({
      where: { id: eventId },
      data: { lastNudgeAt: new Date() },
    });
    return { sentCount };
  });

  app.get('/events/:eventId/comments', async (req) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    await assertMember(event.groupId, user.id);

    const comments = await prisma.comment.findMany({
      where: { eventId },
      orderBy: { createdAt: 'asc' },
      include: { author: true },
    });
    return {
      items: comments.map((c) => ({
        id: c.id,
        authorId: c.authorId,
        authorDisplayName: c.author.displayName,
        body: c.body,
        createdAt: c.createdAt.toISOString(),
      })),
    };
  });

  app.post('/events/:eventId/comments', async (req, reply) => {
    const user = await getAuthUser(req);
    const { eventId } = req.params as { eventId: string };
    const event = await loadEvent(eventId);
    if (!event) throw ERRORS.EVENT_NOT_FOUND();
    if (event.status === 'cancelled') throw ERRORS.EVENT_CANCELLED();

    const body = req.body as { body?: string };
    if (!body.body?.trim()) throw ERRORS.VALIDATION_ERROR();

    const comment = await prisma.comment.create({
      data: {
        eventId,
        authorId: user.id,
        body: body.body.trim().slice(0, 500),
      },
      include: { author: true },
    });
    return reply.status(201).send({
      id: comment.id,
      authorDisplayName: comment.author.displayName,
      body: comment.body,
      createdAt: comment.createdAt.toISOString(),
    });
  });

  app.delete('/comments/:commentId', async (req) => {
    const user = await getAuthUser(req);
    const { commentId } = req.params as { commentId: string };
    const comment = await prisma.comment.findUnique({
      where: { id: commentId },
      include: { event: { include: { group: true } } },
    });
    if (!comment) throw ERRORS.NOT_FOUND();
    const canDelete =
      comment.authorId === user.id ||
      comment.event.organizerId === user.id ||
      comment.event.group.adminUserId === user.id;
    if (!canDelete) throw ERRORS.FORBIDDEN();
    await prisma.comment.delete({ where: { id: commentId } });
    return { ok: true };
  });
}
