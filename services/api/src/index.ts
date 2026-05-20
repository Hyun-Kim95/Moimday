import { buildApp } from './app.js';
import { startReminderJobs } from './jobs/reminders.js';

const port = Number(process.env.PORT ?? 3000);

const app = await buildApp();
startReminderJobs(app.log);

await app.listen({ port, host: '0.0.0.0' });
console.log(`Moimday API listening on http://localhost:${port}/v1`);
