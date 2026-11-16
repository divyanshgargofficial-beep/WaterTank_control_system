import { Router } from 'express';
import { postStatus, getCommand, postAck } from '../controllers/deviceController.js';
import { requireDeviceAuth } from '../middleware/deviceAuth.js';

export const deviceRoutes = Router();

deviceRoutes.use(requireDeviceAuth);
deviceRoutes.post('/status', postStatus);
deviceRoutes.get('/command', getCommand);
deviceRoutes.post('/ack', postAck);
