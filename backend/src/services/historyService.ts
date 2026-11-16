import { prisma } from '../config/prisma.js';

export async function getHistory(deviceId: string) {
  return prisma.commandHistory.findMany({
    where: { deviceId },
    orderBy: { createdAt: 'desc' },
    take: 50,
  });
}
