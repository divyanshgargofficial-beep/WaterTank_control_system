import { Request, Response } from 'express';
import { updateDeviceStatus, getNextCommand, recordCommandAck } from '../services/deviceService.js';

export async function postStatus(req: Request, res: Response) {
  await updateDeviceStatus(req.body);
  res.json({ success: true });
}

export async function getCommand(req: Request, res: Response) {
  const deviceId = req.query.deviceId as string;
  const command = await getNextCommand(deviceId);
  res.json(command ?? { command: 'NONE' });
}

export async function postAck(req: Request, res: Response) {
  await recordCommandAck(req.body);
  res.json({ success: true });
}
