import { Request, Response } from 'express';
import { ackSchema } from '../models/api.js';
import * as deviceService from '../services/deviceService.js';

export async function postStatus(req: Request, res: Response) {
  const device = await deviceService.recordStatus(req.body);
  res.json({ success: true, deviceId: device.deviceId, online: device.online });
}

export async function getCommand(req: Request, res: Response) {
  const deviceId = `${req.query.deviceId ?? req.device?.deviceId ?? ''}`;
  const command = await deviceService.nextCommand(deviceId);
  if (!command) {
    return res.json({ command: 'NONE' });
  }
  res.json({
    commandId: command.id,
    command: command.type,
    payload: command.payload ?? {}
  });
}

export async function ackCommand(req: Request, res: Response) {
  const input = ackSchema.parse(req.body);
  const command = await deviceService.acknowledgeCommand(
    input.deviceId,
    input.commandId,
    input.success,
    input.message
  );
  res.json({ success: true, status: command.status });
}
