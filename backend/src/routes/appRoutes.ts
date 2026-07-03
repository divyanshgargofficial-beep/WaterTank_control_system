import { Router } from 'express';
import { requireAdmin, requireAuth } from '../middleware/auth.js';
import * as appController from '../controllers/appController.js';

export const appRoutes = Router();

appRoutes.get('/status', requireAuth, appController.status);
appRoutes.get('/history', requireAuth, appController.history);
appRoutes.get('/device', requireAuth, appController.device);
appRoutes.post('/pump/on', requireAuth, requireAdmin, appController.pumpOn);
appRoutes.post('/pump/off', requireAuth, requireAdmin, appController.pumpOff);
appRoutes.post('/reset', requireAuth, requireAdmin, appController.reset);
