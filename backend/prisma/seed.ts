import bcrypt from 'bcryptjs';
import { UserRole } from '@prisma/client';
import { env } from '../src/config/env.js';
import { prisma } from '../src/config/prisma.js';
import { ensureDefaultDevice } from '../src/services/deviceService.js';

async function upsertUser(email: string, name: string, role: UserRole, password: string) {
  const passwordHash = await bcrypt.hash(password, 12);
  await prisma.user.upsert({
    where: { email },
    update: { name, role, passwordHash, active: true },
    create: { email, name, role, passwordHash }
  });
}

await upsertUser(env.ADMIN_EMAIL, 'Administrator', UserRole.ADMIN, env.ADMIN_PASSWORD);
await upsertUser(env.FAMILY_EMAIL, 'Family Member', UserRole.FAMILY, env.FAMILY_PASSWORD);
await ensureDefaultDevice();
await prisma.$disconnect();
