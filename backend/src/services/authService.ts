import bcrypt from 'bcryptjs';
import { prisma } from '../config/prisma.js';
import { signUserToken, hashToken } from './tokenService.js';

export async function login(email: string, password: string, context: {
  userAgent?: string;
  ipAddress?: string;
}) {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || !user.active) {
    throw new Error('Invalid credentials');
  }

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    throw new Error('Invalid credentials');
  }

  const token = signUserToken(user);
  const expiresAt = new Date(Date.now() + 12 * 60 * 60 * 1000);
  await prisma.session.create({
    data: {
      userId: user.id,
      tokenHash: hashToken(token),
      userAgent: context.userAgent,
      ipAddress: context.ipAddress,
      expiresAt
    }
  });

  return {
    token,
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role
    }
  };
}
