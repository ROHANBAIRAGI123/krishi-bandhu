import { asyncHandler } from "../utils/asyncHandler";
import { Request, Response } from "express";
import { ApiResponse } from "../utils/api-response";

const healthCheck = asyncHandler(async (req: Request, res: Response) => {
    console.log(`Request Method: ${req.method}, URL: ${req.url}`);
    return res
        .status(200)
        .json(new ApiResponse(200, "OK", "healthCheck passed succesfully"));
});

export { healthCheck };