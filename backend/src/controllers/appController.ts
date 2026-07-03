import { Request, Response } from 'express';
import { CommandType } from '@prisma/client';
import { prisma } from '../config/prisma.js';
import * as deviceService from '../services/deviceService.js';

export async function pumpOn(req: Request, res: Response) {
  const deviceId = typeof req.body?.deviceId === 'string' ? req.body.deviceId : undefined;
  console.log('[AppCommand] pumpOn request', { userId: req.user!.id, deviceId, body: req.body });
  const command = await deviceService.queueCommand(CommandType.PUMP_ON, req.user!.id, deviceId);
  console.log('[AppCommand] pumpOn queued', { commandId: command.id, deviceRowId: command.deviceId, status: command.status });
  res.json({ success: true, commandId: command.id });
}

export async function pumpOff(req: Request, res: Response) {
  const deviceId = typeof req.body?.deviceId === 'string' ? req.body.deviceId : undefined;
  console.log('[AppCommand] pumpOff request', { userId: req.user!.id, deviceId, body: req.body });
  const command = await deviceService.queueCommand(CommandType.PUMP_OFF, req.user!.id, deviceId);
  console.log('[AppCommand] pumpOff queued', { commandId: command.id, deviceRowId: command.deviceId, status: command.status });
  res.json({ success: true, commandId: command.id });
}

export async function reset(req: Request, res: Response) {
  const deviceId = typeof req.body?.deviceId === 'string' ? req.body.deviceId : undefined;
  console.log('[AppCommand] reset request', { userId: req.user!.id, deviceId, body: req.body });
  const command = await deviceService.queueCommand(CommandType.RESET_LOCKOUT, req.user!.id, deviceId);
  console.log('[AppCommand] reset queued', { commandId: command.id, deviceRowId: command.deviceId, status: command.status });
  res.json({ success: true, commandId: command.id });
}

export async function status(_req: Request, res: Response) {
  res.json(await deviceService.getAppStatus());
}

export async function history(_req: Request, res: Response) {
  const device = await deviceService.getCurrentDevice();
  const rows = await prisma.history.findMany({
    where: { deviceId: device.id },
    orderBy: { createdAt: 'desc' },
    take: 150
  });
  res.json({ events: rows });
}

export async function device(_req: Request, res: Response) {
  res.json(await deviceService.getCurrentDevice());
}
