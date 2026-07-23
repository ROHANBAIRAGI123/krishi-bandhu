import express from 'express';
import cors from 'cors';
import healthCheckRouter from './routers/healthCheck.router';
// import "./config/env"

const app = express();

app.use(
  cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
  }),
);

app.use(express.json({ limit: '16kb' }));
app.use(express.urlencoded({ extended: true, limit: '16kb' }));

app.use('/api/v1/health', healthCheckRouter);

app.get('/', (_req, res) => {
  res.send('Hello World!!');
});

app.get('/about', (_req, res) => {
  res.send('This is an About Page');
});

export { app };
