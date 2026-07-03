import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});

export const deviceStatusSchema = z.object({
  deviceId: z.string().min(1),
  deviceName: z.string().min(1).optional(),
  firmwareVersion: z.string().optional(),
  pumpRunning: z.boolean(),
  tankFull: z.boolean(),
  lockout: z.boolean(),
  runtime: z.coerce.number().int().min(0),
  totalRuntime: z.coerce.number().int().min(0),
  wifiRSSI: z.coerce.number().int().optional(),
  ipAddress: z.string().optional()
});

export const ackSchema = z.object({
  deviceId: z.string().min(1),
  commandId: z.string().min(1),
  success: z.boolean(),
  message: z.string().optional()
});
