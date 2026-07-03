import { prisma } from '../src/config/prisma.js';
import { ensureDefaultDevice } from '../src/services/deviceService.js';
import { ensureDefaultUsers } from '../src/services/userService.js';

await ensureDefaultUsers();
await ensureDefaultDevice();
await prisma.$disconnect();
