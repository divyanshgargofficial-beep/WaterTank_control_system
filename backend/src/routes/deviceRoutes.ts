import { Router } from 'express';
import { requireDeviceAuth } from '../middleware/deviceAuth.js';
import * as deviceController from '../controllers/deviceController.js';

export const deviceRoutes = Router();

deviceRoutes.post('/status', requireDeviceAuth, deviceController.postStatus);
deviceRoutes.get('/command', requireDeviceAuth, deviceController.getCommand);
deviceRoutes.post('/ack', requireDeviceAuth, deviceController.ackCommand);
