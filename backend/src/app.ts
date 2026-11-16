import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { appRoutes } from './routes/appRoutes.js';
import { authRoutes } from './routes/authRoutes.js';
import { deviceRoutes } from './routes/deviceRoutes.js';
import { errorHandler } from './middleware/errorHandler.js';

export const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.use('/auth', authRoutes);
app.use('/app', appRoutes);
app.use('/device', deviceRoutes);

app.use(errorHandler);
