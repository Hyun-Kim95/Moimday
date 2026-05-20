import type { FastifyInstance } from 'fastify';

import { prisma } from '../lib/prisma.js';

import { ERRORS } from '../lib/errors.js';

import { getAuthUser } from '../lib/auth.js';

import { maskPhone } from '../lib/phone.js';

import {

  getUserMemberships,

  resolveActiveGroupId,

  setActiveGroup,

} from '../lib/group-membership.js';

import { memberCount } from '../lib/event-helpers.js';



async function buildMeResponse(userId: string) {

  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });

  const memberships = await getUserMemberships(userId);

  const activeGroupId = await resolveActiveGroupId(user.id, user.lastActiveGroupId);



  const groups = await Promise.all(

    memberships.map(async (m) => ({

      id: m.groupId,

      name: m.group.name,

      isAdmin: m.group.adminUserId === user.id,

      memberCount: await memberCount(m.groupId),

    })),

  );



  const activeMembership = memberships.find((m) => m.groupId === activeGroupId);



  return {

    id: user.id,

    displayName: user.displayName,

    phoneMasked: user.phoneE164 ? maskPhone(user.phoneE164) : null,

    autoReminderEnabled: user.autoReminderEnabled,

    activeGroupId,

    groupId: activeGroupId,

    groups,

    isGroupAdmin: activeMembership

      ? activeMembership.group.adminUserId === user.id

      : false,

  };

}



export async function userRoutes(app: FastifyInstance) {

  app.get('/users/me', async (req) => {

    const user = await getAuthUser(req);

    return buildMeResponse(user.id);

  });



  app.patch('/users/me/active-group', async (req) => {

    const user = await getAuthUser(req);

    const body = req.body as { groupId?: string };

    if (!body?.groupId) throw ERRORS.VALIDATION_ERROR();

    await setActiveGroup(user.id, body.groupId);

    return buildMeResponse(user.id);

  });



  app.patch('/users/me', async (req) => {

    const user = await getAuthUser(req);

    const body = req.body as { displayName?: string; autoReminderEnabled?: boolean };

    const updated = await prisma.user.update({

      where: { id: user.id },

      data: {

        ...(body.displayName ? { displayName: body.displayName.slice(0, 20) } : {}),

        ...(typeof body.autoReminderEnabled === 'boolean'

          ? { autoReminderEnabled: body.autoReminderEnabled }

          : {}),

      },

    });

    return {

      id: updated.id,

      displayName: updated.displayName,

      autoReminderEnabled: updated.autoReminderEnabled,

    };

  });



  app.delete('/users/me', async (req, reply) => {

    const user = await getAuthUser(req);

    await prisma.user.delete({ where: { id: user.id } });

    return reply.status(202).send({ ok: true });

  });



  app.put('/users/me/push-token', async (req) => {

    const user = await getAuthUser(req);

    const body = req.body as { platform?: string; token?: string };

    if (!body?.platform || !body?.token) throw ERRORS.VALIDATION_ERROR();

    if (!['ios', 'android'].includes(body.platform)) throw ERRORS.VALIDATION_ERROR();



    await prisma.pushToken.upsert({

      where: { userId_platform: { userId: user.id, platform: body.platform } },

      create: { userId: user.id, platform: body.platform, token: body.token },

      update: { token: body.token },

    });



    req.log.info({ userId: user.id, platform: body.platform }, 'Push token registered');

    return { ok: true };

  });

}

