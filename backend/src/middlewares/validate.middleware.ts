import { Request, Response, NextFunction } from "express";
import { z } from "zod";
import ApiError from "../utils/apiError";

/**
 * Factory that returns an Express middleware validating `req.body`
 * against the given Zod schema.
 *
 * Usage:
 *   router.post("/", validate(createFarmerSchema), controller.create);
 */
const validate = (schema: z.ZodType) => {
  return (req: Request, _res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      const messages = result.error.issues.map(
        (issue: { path: PropertyKey[]; message: string }) =>
          `${issue.path.join(".")}: ${issue.message}`,
      );
      throw new ApiError(400, `Validation failed — ${messages.join("; ")}`);
    }

    req.body = result.data;
    next();
  };
};

export { validate };
