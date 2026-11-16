import { Request, Response } from 'express';
import { authenticateUser } from '../services/authService.js';

export async function login(req: Request, res: Response) {
  const { email, password } = req.body;
  const token = await authenticateUser(email, password);
  res.json({ token });
}
