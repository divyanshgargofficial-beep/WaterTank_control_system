import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import morgan from 'morgan';
import { env } from './config/env.js';
import { appRoutes } from './routes/appRoutes.js';
import { authRoutes } from './routes/authRoutes.js';
import { prisma } from './config/prisma.js';
import { deviceRoutes } from './routes/deviceRoutes.js';
import { errorHandler, notFound } from './middleware/errorHandler.js';

export function createApp() {
  const app = express();
  app.set('trust proxy', 1);
  app.use(helmet());
  app.use(cors({ origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN }));
  app.use(express.json({ limit: '64kb' }));
  app.use(morgan(env.NODE_ENV === 'production' ? 'combined' : 'dev'));
  app.use(rateLimit({ windowMs: 60_000, limit: 120 }));

  app.get('/health', (_req, res) => {
    res.json({ ok: true, service: 'water-tank-cloud-backend' });
  });

  app.get('/health/db', async (_req, res, next) => {
    try {
      await prisma.$queryRaw`SELECT 1`;
      res.json({ ok: true, database: 'connected' });
    } catch (error) {
      next(error);
    }
  });

  app.use('/auth', authRoutes);
  app.use('/device', deviceRoutes);
  app.use('/app', appRoutes);
  app.use(notFound);
  app.use(errorHandler);
  return app;
}
