import Fastify from 'fastify';
import cors from '@fastify/cors';
import { ApiError } from './lib/errors.js';
import { authRoutes } from './routes/auth.js';
import { userRoutes } from './routes/users.js';
import { groupRoutes } from './routes/groups.js';
import { eventRoutes } from './routes/events.js';
import { notificationRoutes } from './routes/notifications.js';

export async function buildApp() {
  const app = Fastify({ logger: true });

  await app.register(cors, { origin: true });

  app.setErrorHandler((err, _req, reply) => {
    if (err instanceof ApiError) {
      return reply.status(err.statusCode).send(err.toJSON());
    }
    app.log.error(err);
    return reply.status(500).send({
      error: { code: 'SERVICE_UNAVAILABLE', message: '서비스에 연결할 수 없어요.' },
    });
  });

  app.get('/health', async () => ({ ok: true, service: 'moimday-api' }));

  await app.register(
    async (v1) => {
      await authRoutes(v1);
      await userRoutes(v1);
      await groupRoutes(v1);
      await eventRoutes(v1);
      await notificationRoutes(v1);
    },
    { prefix: '/v1' },
  );

  return app;
}
