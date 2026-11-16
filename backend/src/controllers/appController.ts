import { Request, Response } from 'express';
import { getDeviceStatus, queueCommand } from '../services/deviceService.js';

export async function getStatus(req: Request, res: Response) {
  const status = await getDeviceStatus('package-1');
  res.json({ device: status });
}

export async function startPump(req: Request, res: Response) {
  await queueCommand('package-1', 'PUMP_ON');
  res.json({ success: true });
}

export async function stopPump(req: Request, res: Response) {
  await queueCommand('package-1', 'PUMP_OFF');
  res.json({ success: true });
}

export async function resetLockout(req: Request, res: Response) {
  await queueCommand('package-1', 'RESET_LOCKOUT');
  res.json({ success: true });
}
