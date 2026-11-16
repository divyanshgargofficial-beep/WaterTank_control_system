import { prisma } from '../config/prisma.js';

export async function getUserById(id: string) {
  return prisma.user.findUnique({ where: { id } });
}
