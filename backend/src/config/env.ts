import fs from "fs";
import path from "path";
import dotenv from "dotenv";

const envFiles = [".env.local", ".env"];

for (const envFile of envFiles) {
    const fullPath = path.join(process.cwd(), envFile);
    if (fs.existsSync(fullPath)) {
        dotenv.config({ path: fullPath });
        break;
    }
}

/*
 * ===========================================================================================
 *                              NOTES — env.ts
 * ===========================================================================================
 *
 * PURPOSE: Automatically loads environment variables from `.env.local` or `.env` files into `process.env`.
 * ROLE IN ARCHITECTURE: Configuration Layer. Executed early in the application lifecycle to ensure configuration variables are available.
 * 
 * IMPORTS:
 * - `fs`, `path`: Node.js built-ins for file system checks and path resolution.
 * - `dotenv`: Library for parsing `.env` files.
 * 
 * FUNCTION-BY-FUNCTION ANALYSIS:
 * - `Global Execution Context`
 *   - Does: Iterates over a prioritized list of environment filenames (`.env.local` first, then `.env`). It checks if the file exists using `fs.existsSync`. As soon as it finds one, it calls `dotenv.config` to load it and immediately `break`s the loop.
 *   - Side effects: Mutates the global `process.env` object. Performs synchronous file I/O operations upon initialization.
 * 
 * HOW THIS FILE CONNECTS TO OTHER FILES:
 * - Inbound: Imported at the very top of application entry points (e.g., `index.ts` or `app.ts`) before any other files that require environment variables.
 * - Outbound: Calls Node built-ins and `dotenv`.
 * 
 * DESIGN PATTERNS:
 * - Environment Configuration Pattern: Prioritizes local overrides (`.env.local`) over standard configurations (`.env`), similar to Next.js's env loading strategy.
 * 
 * POTENTIAL INTERVIEW QUESTIONS:
 * 1. Why prioritize `.env.local` over `.env`?
 *    - Answer: `.env` often contains default variables that might be committed to version control, while `.env.local` is strictly ignored and contains developer-specific secrets or overrides.
 * 2. Why use synchronous file reading (`fs.existsSync`) instead of async here?
 *    - Answer: This script runs exactly once during server startup. Environment variables MUST be loaded synchronously before the rest of the application code is evaluated, otherwise imports might fail or get `undefined` env vars.
 * 3. What happens if neither file exists?
 *    - Answer: The loop completes without loading anything. The application will rely solely on variables passed directly via the host OS or Docker environment.
 */