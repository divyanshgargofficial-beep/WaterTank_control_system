import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';

export function verifyToken(token: string) {
  return jwt.verify(token, env.JWT_SECRET);
}
