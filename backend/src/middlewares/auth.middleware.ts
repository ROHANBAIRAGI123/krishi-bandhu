import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import ApiError from "../utils/apiError";

export interface AuthPayload {
  id: string;
  role: string;
}

/**
 * Extends Express Request to carry the decoded JWT payload
 * on `req.officer` after authentication.
 */
declare global {
  namespace Express {
    interface Request {
      officer?: AuthPayload;
    }
  }
}

/**
 * Middleware that verifies the `Authorization: Bearer <token>` header.
 * On success it attaches `req.officer` with `{ id, role }`.
 */
const authenticate = (req: Request, _res: Response, next: NextFunction): void => {
  const header = req.headers.authorization;

  if (!header || !header.startsWith("Bearer ")) {
    throw new ApiError(401, "Access denied. No token provided.");
  }

  const token = header.split(" ")[1];
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new ApiError(500, "JWT_SECRET is not configured on the server.");
  }

  try {
    const decoded = jwt.verify(token, secret) as AuthPayload;
    req.officer = decoded;
    next();
  } catch {
    throw new ApiError(401, "Invalid or expired token.");
  }
};

/**
 * Factory that restricts access to specific officer roles.
 *
 * Usage:
 *   router.get("/admin-only", authenticate, authorize("admin"), controller.fn);
 */
const authorize = (...roles: string[]) => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.officer) {
      throw new ApiError(401, "Authentication required.");
    }

    if (!roles.includes(req.officer.role)) {
      throw new ApiError(
        403,
        `Access denied. Required role(s): ${roles.join(", ")}.`,
      );
    }
    next();
  };
};

export { authenticate, authorize };
