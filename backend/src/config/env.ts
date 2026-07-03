import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const schema = z.object({
  NODE_ENV: z.string().default('development'),
  PORT: z.coerce.number().default(8080),
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(24),
  JWT_EXPIRES_IN: z.string().default('12h'),
  DEVICE_TOKEN: z.string().min(16),
  DEFAULT_DEVICE_ID: z.string().default('package-1'),
  DEFAULT_DEVICE_NAME: z.string().default('Home Water Tank'),
  ADMIN_EMAIL: z.string().email().default('admin@example.com'),
  ADMIN_PASSWORD: z.string().min(6).default('admin123'),
  FAMILY_EMAIL: z.string().email().default('family@example.com'),
  FAMILY_PASSWORD: z.string().min(6).default('family123'),
  CORS_ORIGIN: z.string().default('*')
});

export const env = schema.parse(process.env);
