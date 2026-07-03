import { Request, Response } from 'express';
import { ackSchema } from '../models/api.js';
import * as deviceService from '../services/deviceService.js';

export async function postStatus(req: Request, res: Response) {
  console.log('[DeviceStatus] incoming', {
    headerDeviceId: req.header('x-device-id'),
    body: req.body
  });
  const device = await deviceService.recordStatus(req.body);
  console.log('[DeviceStatus] stored', {
    deviceId: device.deviceId,
    pumpRunning: device.pumpRunning,
    tankFull: device.tankFull,
    lockout: device.lockout,
    runtime: device.runtime,
    totalRuntime: device.totalRuntime
  });
  res.json({ success: true, deviceId: device.deviceId, online: device.online });
}

export async function getCommand(req: Request, res: Response) {
  const deviceId = `${req.query.deviceId ?? req.device?.deviceId ?? ''}`;
  console.log('[DeviceCommand] poll', {
    queryDeviceId: req.query.deviceId,
    authDeviceId: req.device?.deviceId
  });
  const command = await deviceService.nextCommand(deviceId);
  if (!command) {
    console.log('[DeviceCommand] none', { deviceId });
    return res.json({ command: 'NONE' });
  }
  const wireCommand = deviceService.toWireCommand(command.type);
  console.log('[DeviceCommand] delivering', {
    deviceId,
    commandId: command.id,
    dbType: command.type,
    wireCommand,
    status: command.status
  });
  res.json({
    commandId: command.id,
    command: wireCommand,
    commandType: command.type,
    payload: command.payload ?? {}
  });
}

export async function ackCommand(req: Request, res: Response) {
  const input = ackSchema.parse(req.body);
  console.log('[DeviceAck] incoming', input);
  const command = await deviceService.acknowledgeCommand(
    input.deviceId,
    input.commandId,
    input.success,
    input.message
  );
  console.log('[DeviceAck] stored', {
    commandId: command.id,
    status: command.status,
    ackedAt: command.ackedAt,
    error: command.error
  });
  res.json({ success: true, status: command.status });
}
