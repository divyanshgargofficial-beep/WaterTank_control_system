import { NextFunction, Request, Response } from 'express';
import { UserRole } from '@prisma/client';
import { prisma } from '../config/prisma.js';
import { verifyUserToken } from '../services/tokenService.js';

export async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.header('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.substring(7) : '';
  if (!token) return res.status(401).json({ error: 'Missing bearer token' });
  try {
    const payload = verifyUserToken(token);
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user || !user.active) return res.status(401).json({ error: 'Invalid bearer token' });
    req.user = user;
    return next();
  } catch {
    return res.status(401).json({ error: 'Invalid bearer token' });
  }
}

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  if (req.user?.role !== UserRole.ADMIN) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  return next();
}
