import dotenv from 'dotenv';

dotenv.config({
  path: './.env',
});

import { app } from './app';
import connectDB from './config/connect';

const PORT: number = Number(process.env.PORT) || 8001;

console.log('Starting server...');

connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`Server is running at Port: ${PORT}`);
  });
});
