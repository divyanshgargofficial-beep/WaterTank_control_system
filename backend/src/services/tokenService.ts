import crypto from 'crypto';
import jwt, { SignOptions } from 'jsonwebtoken';
import { User } from '@prisma/client';
import { env } from '../config/env.js';

export interface JwtPayload {
  sub: string;
  role: string;
  email: string;
}

export function signUserToken(user: User): string {
  const options: SignOptions = {
    subject: user.id,
    expiresIn: env.JWT_EXPIRES_IN as SignOptions['expiresIn']
  };
  return jwt.sign(
    { role: user.role, email: user.email },
    env.JWT_SECRET,
    options
  );
}

export function verifyUserToken(token: string): JwtPayload {
  return jwt.verify(token, env.JWT_SECRET) as JwtPayload;
}

export function hashToken(value: string): string {
  return crypto.createHash('sha256').update(value).digest('hex');
}
