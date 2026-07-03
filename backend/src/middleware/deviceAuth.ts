import { NextFunction, Request, Response } from 'express';
import { validateDeviceToken } from '../services/deviceService.js';

export async function requireDeviceAuth(req: Request, res: Response, next: NextFunction) {
  const deviceId = `${req.header('x-device-id') ?? req.query.deviceId ?? req.body?.deviceId ?? ''}`;
  const token = `${req.header('x-device-token') ?? ''}`;
  if (!deviceId || !token) {
    return res.status(401).json({ error: 'Missing device credentials' });
  }
  const device = await validateDeviceToken(deviceId, token);
  if (!device) {
    return res.status(401).json({ error: 'Invalid device credentials' });
  }
  req.device = device;
  return next();
}
