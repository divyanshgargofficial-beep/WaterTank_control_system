import { Router } from 'express';
import { login } from '../controllers/authController.js';

export const authRoutes = Router();

authRoutes.post('/login', login);
