import { prisma } from '../config/prisma.js';
import { StatusPayload } from '../models/api.js';

export async function updateDeviceStatus(data: StatusPayload) {
  await prisma.deviceStatus.upsert({
    where: { deviceId: data.deviceId },
    update: {
      pumpRunning: data.pumpRunning,
      tankFull: data.tankFull,
      lockout: data.lockout,
      runtime: data.runtime,
      totalRuntime: data.totalRuntime,
      wifiRSSI: data.wifiRSSI,
      ipAddress: data.ipAddress,
      firmwareVersion: data.firmwareVersion,
    },
    create: {
      deviceId: data.deviceId,
      pumpRunning: data.pumpRunning,
      tankFull: data.tankFull,
      lockout: data.lockout,
      runtime: data.runtime,
      totalRuntime: data.totalRuntime,
      wifiRSSI: data.wifiRSSI,
      ipAddress: data.ipAddress,
      firmwareVersion: data.firmwareVersion,
    },
  });
}

export async function getDeviceStatus(deviceId: string) {
  return prisma.deviceStatus.findUnique({ where: { deviceId } });
}

export async function queueCommand(deviceId: string, command: any) {
  return prisma.deviceCommand.create({
    data: { deviceId, command, status: 'PENDING' },
  });
}

export async function getNextCommand(deviceId: string) {
  const cmd = await prisma.deviceCommand.findFirst({
    where: { deviceId, status: 'PENDING' },
    orderBy: { createdAt: 'asc' },
  });
  if (cmd) {
    await prisma.deviceCommand.update({
      where: { id: cmd.id },
      data: { status: 'DELIVERED' },
    });
    return { commandId: cmd.id, command: cmd.command };
  }
  return null;
}

export async function recordCommandAck(data: { commandId: string; success: boolean; message?: string }) {
  const cmd = await prisma.deviceCommand.findUnique({ where: { id: data.commandId } });
  if (cmd) {
    await prisma.commandHistory.create({
      data: {
        deviceId: cmd.deviceId,
        command: cmd.command,
        success: data.success,
        message: data.message,
      },
    });
    await prisma.deviceCommand.delete({ where: { id: data.commandId } });
  }
}
