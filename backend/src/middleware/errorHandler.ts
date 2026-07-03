import { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';

export function notFound(_req: Request, res: Response) {
  res.status(404).json({ error: 'Not found' });
}

export function errorHandler(error: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (error instanceof ZodError) {
    return res.status(400).json({ error: 'Validation failed', details: error.flatten() });
  }
  if (error instanceof Error) {
    const status = error.message === 'Forbidden' ? 403 : error.message.includes('credentials') ? 401 : 400;
    return res.status(status).json({ error: error.message });
  }
  return res.status(500).json({ error: 'Internal server error' });
}
