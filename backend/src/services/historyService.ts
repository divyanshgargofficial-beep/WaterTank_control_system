import { HistoryType, NotificationType } from '@prisma/client';
import { prisma } from '../config/prisma.js';

export async function addHistory(deviceId: string, type: HistoryType, message: string, metadata?: object, userId?: string) {
  return prisma.history.create({
    data: { deviceId, userId, type, message, metadata: metadata ?? undefined }
  });
}

export async function addNotification(deviceId: string, type: NotificationType, title: string, body: string, userId?: string) {
  return prisma.notification.create({
    data: { deviceId, userId, type, title, body }
  });
}
