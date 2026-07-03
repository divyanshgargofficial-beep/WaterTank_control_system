import bcrypt from 'bcryptjs';
import { UserRole } from '@prisma/client';
import { env } from '../config/env.js';
import { prisma } from '../config/prisma.js';

async function upsertUser(email: string, name: string, role: UserRole, password: string) {
  const passwordHash = await bcrypt.hash(password, 12);
  await prisma.user.upsert({
    where: { email },
    update: { name, role, active: true },
    create: { email, name, role, passwordHash }
  });
}

export async function ensureDefaultUsers() {
  await upsertUser(env.ADMIN_EMAIL, 'Administrator', UserRole.ADMIN, env.ADMIN_PASSWORD);
  await upsertUser(env.FAMILY_EMAIL, 'Family Member', UserRole.FAMILY, env.FAMILY_PASSWORD);
}
