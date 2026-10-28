import express from 'express';
import cors from 'cors';

// ── Routers ───────────────────────────────────────────────
import healthCheckRouter from './routers/healthCheck.router';
import officerRouter from './routers/officer.router';
import farmerRouter from './routers/farmer.router';
import claimRouter from './routers/claim.router';

// ── Middleware ────────────────────────────────────────────
import { errorHandler } from './middlewares/error-handler.middleware';

const app = express();

app.use(
  cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
  }),
);

app.use(express.json({ limit: '16kb' }));
app.use(express.urlencoded({ extended: true, limit: '16kb' }));

// ── Routes ────────────────────────────────────────────────
app.use('/api/v1/health', healthCheckRouter);
app.use('/api/v1/officers', officerRouter);
app.use('/api/v1/farmers', farmerRouter);
app.use('/api/v1/claims', claimRouter);

app.get('/', (_req, res) => {
  res.send('Krishi Bandhu API — v1');
});

// ── Global Error Handler (must be LAST) ───────────────────
app.use(errorHandler);

export { app };
