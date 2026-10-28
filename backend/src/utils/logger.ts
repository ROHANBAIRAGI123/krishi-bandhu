import { createLogger, format, transports } from "winston";
import Transport from "winston-transport";
import fs from "fs";
import path from "path";

const { combine, timestamp, printf, colorize } = format;
const isProd = process.env.NODE_ENV === "production";

// Custom format for console logging
const consoleLogFormat = printf(({ level, message, timestamp }) => {
  return `\n${timestamp} [${level}]: ${message}`;
});

// Custom format for file logging (JSON)
const fileLogFormat = combine(
  timestamp(),
  format.errors({ stack: true }),
  format.json()
);

// Create logs directory path
const logsDir = path.join(__dirname, "../../logs");

// Ensure log directory exists for file transports.
fs.mkdirSync(logsDir, { recursive: true });

// Create a Winston logger
const loggerTransports: Transport[] = [
  // File transport
  new transports.File({
    filename: path.join(logsDir, "app.log"),
    format: fileLogFormat,
  }),
  // Error-only file transport
  new transports.File({
    filename: path.join(logsDir, "error.log"),
    level: "error",
    format: fileLogFormat,
  }),
];

if (!isProd) {
  loggerTransports.unshift(
    new transports.Console({
      format: combine(
        colorize(),
        timestamp({ format: "YYYY-MM-DD HH:mm:ss" }),
        consoleLogFormat
      ),
    })
  );
}

const logger = createLogger({
  level: isProd ? "info" : "debug",
  transports: loggerTransports,
  exceptionHandlers: [
    new transports.File({
      filename: path.join(logsDir, "exceptions.log"),
      format: fileLogFormat,
    }),
  ],
});

// Log unhandled promise rejections
process.on("unhandledRejection", (reason) => {
  logger.error("Unhandled Rejection:", reason);
});

export default logger;

/*
 * ===========================================================================================
 *                              NOTES — logger.ts
 * ===========================================================================================
 *
 * PURPOSE: Provides a centralized, robust logging system using Winston for tracking application events and errors.
 * ROLE IN ARCHITECTURE: Observability & Monitoring Layer. Used across all services, controllers, and utilities instead of `console.log`.
 * 
 * IMPORTS:
 * - `winston`: The core logging library.
 * - `winston-transport`: Type definitions for Winston transports.
 * - `fs`, `path`: Node.js built-ins for creating the log directory.
 * 
 * FUNCTION-BY-FUNCTION ANALYSIS:
 * - `Global Execution Context`
 *   - Does: 
 *     1. Creates a `logs` directory if it doesn't exist.
 *     2. Defines custom formats (JSON for files, colorized text for console).
 *     3. Configures Transports: `app.log` (all logs), `error.log` (only errors). Adds console output if not in production.
 *     4. Instantiates the `winston` logger with exception handlers.
 *     5. Catches `unhandledRejection` events globally and logs them.
 *   - Side effects: Creates directories, writes to the file system globally, mutates `process.on('unhandledRejection')`.
 * 
 * HOW THIS FILE CONNECTS TO OTHER FILES:
 * - Inbound: Imported everywhere (`app.ts`, `Passwords.ts`, etc.) to log information and errors.
 * - Outbound: Writes to `logs/app.log`, `logs/error.log`, `logs/exceptions.log`.
 * 
 * DESIGN PATTERNS:
 * - Singleton Logger Pattern: Configures Winston once and exports the instance, ensuring consistent log formatting and streams throughout the app.
 * - Observer Pattern: Hooks into the `process.on("unhandledRejection")` event to observe unhandled promise rejections.
 * 
 * POTENTIAL INTERVIEW QUESTIONS:
 * 1. Why use Winston instead of `console.log`?
 *    - Answer: `console.log` is synchronous, blocks the event loop, and is hard to manage. Winston provides log levels, log rotation, structured JSON logging (for log aggregators like Datadog/ELK), and multiple output destinations (transports).
 * 2. Why write logs to files in JSON format but use plain text for the console?
 *    - Answer: JSON is machine-readable, making it perfect for parsing and searching in log management tools. Plain text is human-readable, making it better for local developer debugging in the terminal.
 * 3. What is the difference between `exceptions.log` and `error.log` here?
 *    - Answer: `error.log` catches standard application errors manually passed to `logger.error()`. `exceptions.log` catches fatal, unhandled synchronous exceptions via Winston's built-in `exceptionHandlers`.
 */