import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env.js';

export function requireDeviceAuth(req: Request, res: Response, next: NextFunction) {
  const token = req.headers['x-device-token'];
  if (token !== env.DEVICE_TOKEN) {
    return res.status(401).json({ error: 'Unauthorized device' });
  }
  next();
}
