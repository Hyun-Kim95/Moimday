import type { FastifyInstance } from 'fastify';
import { prisma } from '../lib/prisma.js';
import { getAuthUser } from '../lib/auth.js';

export async function notificationRoutes(app: FastifyInstance) {
  app.get('/notifications', async (req) => {
    const user = await getAuthUser(req);
    const unreadOnly = (req.query as { unreadOnly?: string }).unreadOnly === 'true';

    const items = await prisma.notification.findMany({
      where: {
        userId: user.id,
        ...(unreadOnly ? { readAt: null } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    return {
      items: items.map((n) => ({
        id: n.id,
        type: n.type,
        eventId: n.eventId,
        title: n.title,
        body: n.body,
        readAt: n.readAt?.toISOString() ?? null,
        createdAt: n.createdAt.toISOString(),
      })),
    };
  });

  app.patch('/notifications/:id/read', async (req) => {
    const user = await getAuthUser(req);
    const { id } = req.params as { id: string };
    await prisma.notification.updateMany({
      where: { id, userId: user.id },
      data: { readAt: new Date() },
    });
    return { ok: true };
  });

  app.post('/notifications/read-all', async (req) => {
    const user = await getAuthUser(req);
    await prisma.notification.updateMany({
      where: { userId: user.id, readAt: null },
      data: { readAt: new Date() },
    });
    return { ok: true };
  });
}
