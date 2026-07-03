import { Request, Response } from 'express';
import { loginSchema } from '../models/api.js';
import * as authService from '../services/authService.js';

export async function login(req: Request, res: Response) {
  const input = loginSchema.parse(req.body);
  const result = await authService.login(input.email, input.password, {
    userAgent: req.header('user-agent') ?? undefined,
    ipAddress: req.ip
  });
  res.json(result);
}
