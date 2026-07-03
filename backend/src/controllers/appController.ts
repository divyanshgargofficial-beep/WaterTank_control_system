import { Request, Response } from 'express';
import { CommandType } from '@prisma/client';
import { prisma } from '../config/prisma.js';
import * as deviceService from '../services/deviceService.js';

export async function pumpOn(req: Request, res: Response) {
  const command = await deviceService.queueCommand(CommandType.PUMP_ON, req.user!.id);
  res.json({ success: true, commandId: command.id });
}

export async function pumpOff(req: Request, res: Response) {
  const command = await deviceService.queueCommand(CommandType.PUMP_OFF, req.user!.id);
  res.json({ success: true, commandId: command.id });
}

export async function reset(req: Request, res: Response) {
  const command = await deviceService.queueCommand(CommandType.RESET_LOCKOUT, req.user!.id);
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
