import { asyncHandler } from '../utils/asyncHandler';
import { Request, Response } from 'express';
import { ApiResponse } from '../utils/apiResponse';

const healthCheck = asyncHandler(async (_req: Request, res: Response) => {
  return res.status(200).json(new ApiResponse(200, 'OK', 'healthCheck passed succesfully'));
});

export { healthCheck };
