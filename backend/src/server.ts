import { env } from './config/env.js';
import { prisma } from './config/prisma.js';
import { createApp } from './app.js';
import { ensureDefaultDevice } from './services/deviceService.js';
import { ensureDefaultUsers } from './services/userService.js';

const app = createApp();

await ensureDefaultDevice();
await ensureDefaultUsers();

const server = app.listen(env.PORT, () => {
  console.log(`Water tank cloud backend listening on ${env.PORT}`);
});

async function shutdown() {
  server.close();
  await prisma.$disconnect();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
