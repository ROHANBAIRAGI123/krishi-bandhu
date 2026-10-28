import { Request, Response, NextFunction } from "express";
import ApiError from "../utils/apiError";

/**
 * Global error-handling middleware.
 * Must be registered AFTER all routes so Express can funnel errors here.
 */
const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void => {
  if (err instanceof ApiError) {
    res.status(err.statusCode).json({
      success: false,
      statusCode: err.statusCode,
      message: err.message,
    });
    return;
  }

  // Mongoose validation errors
  if (err.name === "ValidationError") {
    res.status(400).json({
      success: false,
      statusCode: 400,
      message: err.message,
    });
    return;
  }

  // Mongoose duplicate key
  if ((err as any).code === 11000) {
    const field = Object.keys((err as any).keyValue || {})[0] || "field";
    res.status(409).json({
      success: false,
      statusCode: 409,
      message: `Duplicate value for "${field}". This record already exists.`,
    });
    return;
  }

  // Mongoose CastError (invalid ObjectId, etc.)
  if (err.name === "CastError") {
    res.status(400).json({
      success: false,
      statusCode: 400,
      message: "Invalid ID format.",
    });
    return;
  }

  // Fallback — unexpected errors
  console.error("Unhandled error:", err);
  res.status(500).json({
    success: false,
    statusCode: 500,
    message: process.env.NODE_ENV === "production"
      ? "Internal server error."
      : err.message || "Internal server error.",
  });
};

export { errorHandler };
