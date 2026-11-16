import { Router } from 'express';
import { getStatus, startPump, stopPump, resetLockout } from '../controllers/appController.js';
import { requireAuth } from '../middleware/auth.js';

export const appRoutes = Router();

appRoutes.use(requireAuth);
appRoutes.get('/status', getStatus);
appRoutes.post('/pump/on', startPump);
appRoutes.post('/pump/off', stopPump);
appRoutes.post('/pump/reset', resetLockout);
