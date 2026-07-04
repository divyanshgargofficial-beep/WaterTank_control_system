import bcrypt from 'bcryptjs';
import { CommandStatus, CommandType, HistoryType, NotificationType } from '@prisma/client';
import { env } from '../config/env.js';
import { prisma } from '../config/prisma.js';
import { deviceStatusSchema } from '../models/api.js';
import { addHistory, addNotification } from './historyService.js';

export async function ensureDefaultDevice() {
  const existing = await prisma.device.findUnique({
    where: { deviceId: env.DEFAULT_DEVICE_ID }
  });
  if (existing) {
    return existing;
  }

  return prisma.device.create({
    data: {
      deviceId: env.DEFAULT_DEVICE_ID,
      deviceName: env.DEFAULT_DEVICE_NAME,
      deviceTokenHash: await bcrypt.hash(env.DEVICE_TOKEN, 12)
    }
  });
}

export async function findDeviceByPublicId(deviceId: string) {
  return prisma.device.findUnique({ where: { deviceId } });
}

export async function validateDeviceToken(deviceId: string, token: string) {
  const device = await findDeviceByPublicId(deviceId);
  if (!device) return null;
  const valid = await bcrypt.compare(token, device.deviceTokenHash);
  return valid ? device : null;
}

export async function recordStatus(input: unknown) {
  const status = deviceStatusSchema.parse(input);
  let device = await findDeviceByPublicId(status.deviceId);
  if (!device) {
    device = await prisma.device.create({
      data: {
        deviceId: status.deviceId,
        deviceName: status.deviceName ?? status.deviceId,
        firmwareVersion: status.firmwareVersion,
        deviceTokenHash: await bcrypt.hash(env.DEVICE_TOKEN, 12)
      }
    });
  }

  const wasOnline = device.online;
  const wasPumpRunning = device.pumpRunning;
  const wasTankFull = device.tankFull;
  const wasLockout = device.lockout;

  const updated = await prisma.device.update({
    where: { id: device.id },
    data: {
      deviceName: status.deviceName ?? device.deviceName,
      firmwareVersion: status.firmwareVersion ?? device.firmwareVersion,
      lastSeen: new Date(),
      online: true,
      pumpRunning: status.pumpRunning,
      tankFull: status.tankFull,
      lockout: status.lockout,
      runtime: status.runtime,
      totalRuntime: status.totalRuntime,
      wifiRSSI: status.wifiRSSI,
      ipAddress: status.ipAddress
    }
  });

  await prisma.deviceStatus.create({
    data: {
      deviceId: device.id,
      pumpRunning: status.pumpRunning,
      tankFull: status.tankFull,
      lockout: status.lockout,
      runtime: status.runtime,
      totalRuntime: status.totalRuntime,
      wifiRSSI: status.wifiRSSI,
      ipAddress: status.ipAddress
    }
  });

  if (!wasOnline) {
    await addHistory(device.id, HistoryType.CONTROLLER_ONLINE, 'Controller online');
    await addNotification(device.id, NotificationType.CONTROLLER_ONLINE, 'Controller Online', 'Package 1 is connected to cloud.');
  }
  if (!wasPumpRunning && status.pumpRunning) {
    await addHistory(device.id, HistoryType.PUMP_STARTED, 'Pump started');
    await addNotification(device.id, NotificationType.PUMP_STARTED, 'Pump Started', 'Water pump is now running.');
  }
  if (wasPumpRunning && !status.pumpRunning) {
    await addHistory(device.id, HistoryType.PUMP_STOPPED, 'Pump stopped');
    await addNotification(device.id, NotificationType.PUMP_STOPPED, 'Pump Stopped', 'Water pump has stopped.');
  }
  if (!wasTankFull && status.tankFull) {
    await addHistory(device.id, HistoryType.TANK_FULL, 'Tank full');
    await addNotification(device.id, NotificationType.TANK_FULL, 'Tank Full', 'The tank full condition is active.');
  }
  if (!wasLockout && status.lockout) {
    await addHistory(device.id, HistoryType.LOCKOUT_ACTIVATED, 'Lockout activated');
    await addNotification(device.id, NotificationType.LOCKOUT_ACTIVATED, 'Lockout Activated', 'Pump start is locked until reset.');
  }

  await settleDeliveredCommandFromStatus(device.id, status);

  return updated;
}

async function settleDeliveredCommandFromStatus(
  deviceRowId: string,
  status: {
    pumpRunning: boolean;
    tankFull: boolean;
    lockout: boolean;
  }
) {
  const command = await prisma.command.findFirst({
    where: {
      deviceId: deviceRowId,
      status: CommandStatus.DELIVERED
    },
    orderBy: { createdAt: 'asc' }
  });

  if (!command) return null;

  let matched = false;
  let message = '';

  switch (command.type) {
    case CommandType.PUMP_ON:
      matched = status.pumpRunning && !status.lockout;
      message = 'pump started';
      break;
    case CommandType.PUMP_OFF:
      matched = !status.pumpRunning && status.tankFull && status.lockout;
      message = 'pump stopped';
      break;
    case CommandType.RESET_LOCKOUT:
      matched = !status.lockout && !status.tankFull;
      message = 'lockout reset';
      break;
  }

  if (!matched) return null;

  console.log('[DeviceStatus] auto-acking delivered command from status', {
    commandId: command.id,
    type: command.type,
    statusSnapshot: {
      pumpRunning: status.pumpRunning,
      tankFull: status.tankFull,
      lockout: status.lockout
    }
  });

  const updated = await prisma.command.update({
    where: { id: command.id },
    data: {
      status: CommandStatus.ACKED,
      ackedAt: new Date(),
      error: null
    }
  });

  await addHistory(deviceRowId, HistoryType.COMMAND_ACKED, `Command ${command.type} auto-acked from status`, {
    commandId: command.id,
    message
  });

  return updated;
}

export function toWireCommand(type: CommandType) {
  switch (type) {
    case CommandType.PUMP_ON:
      return 'ON';
    case CommandType.PUMP_OFF:
      return 'OFF';
    case CommandType.RESET_LOCKOUT:
      return 'RESET';
  }
}

export async function nextCommand(deviceId: string) {
  const device = await findDeviceByPublicId(deviceId);
  if (!device) {
    console.log('[DeviceCommand] device not found', { deviceId });
    return null;
  }
  await expireStaleActiveCommands(device.id);
  const command = await prisma.command.findFirst({
    where: {
      deviceId: device.id,
      status: CommandStatus.PENDING
    },
    orderBy: { createdAt: 'desc' }
  });
  if (!command) return null;
  console.log('[DeviceCommand] command selected', {
    publicDeviceId: deviceId,
    deviceRowId: device.id,
    commandId: command.id,
    type: command.type,
    previousStatus: command.status
  });
  return prisma.command.update({
    where: { id: command.id },
    data: { status: CommandStatus.DELIVERED, deliveredAt: new Date() }
  });
}

async function expireStaleActiveCommands(deviceRowId: string) {
  const staleBefore = new Date(Date.now() - 60_000);
  const result = await prisma.command.updateMany({
    where: {
      deviceId: deviceRowId,
      OR: [
        {
          status: CommandStatus.PENDING,
          createdAt: { lt: staleBefore }
        },
        {
          status: CommandStatus.DELIVERED,
          deliveredAt: { lt: new Date(Date.now() - 20_000) }
        }
      ]
    },
    data: {
      status: CommandStatus.FAILED,
      ackedAt: new Date(),
      error: 'Command expired before controller confirmation'
    }
  });
  if (result.count > 0) {
    console.log('[DeviceCommand] expired stale active commands', {
      deviceRowId,
      count: result.count
    });
  }
}

export async function acknowledgeCommand(devicePublicId: string, commandId: string, success: boolean, message?: string) {
  const device = await findDeviceByPublicId(devicePublicId);
  if (!device) throw new Error('Device not found');
  const command = await prisma.command.update({
    where: { id: commandId },
    data: {
      status: success ? CommandStatus.ACKED : CommandStatus.FAILED,
      ackedAt: new Date(),
      error: success ? null : message ?? 'Command failed'
    }
  });
  await addHistory(device.id, HistoryType.COMMAND_ACKED, `Command ${command.type} ${success ? 'acked' : 'failed'}`, {
    commandId,
    message
  });
  return command;
}

export async function queueCommand(type: CommandType, userId: string, requestedDeviceId?: string) {
  const device = requestedDeviceId
    ? await findDeviceByPublicId(requestedDeviceId)
    : await ensureDefaultDevice();
  if (!device) {
    console.log('[AppCommand] requested device not found', { requestedDeviceId, type, userId });
    throw new Error('Device not found');
  }
  console.log('[AppCommand] queueCommand', {
    type,
    userId,
    publicDeviceId: device.deviceId,
    deviceRowId: device.id
  });
  const superseded = await prisma.command.updateMany({
    where: {
      deviceId: device.id,
      OR: [
        { status: CommandStatus.PENDING },
        { status: CommandStatus.DELIVERED }
      ]
    },
    data: {
      status: CommandStatus.FAILED,
      ackedAt: new Date(),
      error: `Superseded by newer ${type} command`
    }
  });
  if (superseded.count > 0) {
    console.log('[AppCommand] superseded active commands', {
      type,
      userId,
      publicDeviceId: device.deviceId,
      count: superseded.count
    });
  }
  return prisma.command.create({
    data: {
      deviceId: device.id,
      requestedBy: userId,
      type
    }
  });
}

export async function getCommandForApp(commandId: string, userId: string) {
  return prisma.command.findFirst({
    where: {
      id: commandId,
      requestedBy: userId
    },
    select: {
      id: true,
      type: true,
      status: true,
      error: true,
      deliveredAt: true,
      ackedAt: true,
      createdAt: true,
      device: {
        select: {
          deviceId: true,
          pumpRunning: true,
          tankFull: true,
          lockout: true,
          runtime: true,
          totalRuntime: true,
          lastSeen: true
        }
      }
    }
  });
}

export async function getCurrentDevice() {
  return ensureDefaultDevice();
}

export async function getAppStatus() {
  const device = await ensureDefaultDevice();
  return {
    pumpRunning: device.pumpRunning,
    tankFull: device.tankFull,
    lockout: device.lockout,
    currentRuntimeSeconds: device.runtime,
    totalRuntimeSeconds: device.totalRuntime,
    wifiConnected: device.online,
    receivedAt: device.lastSeen,
    connection: 'cloud'
  };
}
