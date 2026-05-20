import cron from 'node-cron';
import { prisma } from '../lib/prisma.js';
import { parseTargetIds } from '../lib/event-helpers.js';
import { deferNightQuietKst } from '../lib/kst-time.js';
import { sendFcmToUser } from '../lib/fcm.js';

/** Hours-before-deadline windows (ADR-0004 추천안 A). */
const WINDOWS = [
  { key: '48h', minHours: 24, maxHours: 48 },
  { key: '24h', minHours: 1, maxHours: 24 },
  { key: '1h', minHours: 0, maxHours: 1 },
] as const;

function inWindow(hoursLeft: number, w: (typeof WINDOWS)[number]): boolean {
  return hoursLeft <= w.maxHours && hoursLeft > w.minHours;
}

export function startReminderJobs(log: { info: (o: unknown, msg?: string) => void }) {
  cron.schedule('*/15 * * * *', async () => {
    const now = new Date();
    const events = await prisma.event.findMany({
      where: { status: { in: ['poll_open', 'attendance_open'] } },
      include: { dateVotes: true, eventResponses: true },
    });

    for (const event of events) {
      const deadline =
        event.status === 'poll_open' ? event.pollDeadlineAt : event.attendanceDeadlineAt;
      if (!deadline || deadline <= now) continue;

      const hoursLeft = (deadline.getTime() - now.getTime()) / (60 * 60 * 1000);
      const window = WINDOWS.find((w) => inWindow(hoursLeft, w));
      if (!window) continue;

      const memberIds = parseTargetIds(event.targetMemberIds);
      const title = '응답이 필요해요';
      const body = `「${event.title}」마감이 다가오고 있어요.`;

      for (const uid of memberIds) {
        const user = await prisma.user.findUnique({ where: { id: uid } });
        if (!user?.autoReminderEnabled) continue;

        const pending =
          event.status === 'poll_open'
            ? !event.dateVotes.some((v) => v.userId === uid)
            : !event.eventResponses.some((r) => r.userId === uid);
        if (!pending) continue;

        const dedupeSince = new Date(Date.now() - 24 * 60 * 60 * 1000);
        const dedupeBody = `${window.key}:${event.id}`;
        const exists = await prisma.notification.findFirst({
          where: {
            userId: uid,
            eventId: event.id,
            type: 'reminder',
            body: dedupeBody,
            createdAt: { gte: dedupeSince },
          },
        });
        if (exists) continue;

        const deliverAt = deferNightQuietKst(now);
        if (deliverAt.getTime() > now.getTime() + 60_000) continue;

        await prisma.notification.create({
          data: {
            userId: uid,
            type: 'reminder',
            eventId: event.id,
            title,
            body: dedupeBody,
          },
        });

        await sendFcmToUser(uid, {
          title,
          body: `「${event.title}」마감이 다가오고 있어요.`,
          eventId: event.id,
        });
      }
    }
    log.info({}, 'Reminder job completed');
  });
}
