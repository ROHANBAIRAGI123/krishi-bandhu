import { Request, Response } from "express";
import { Types } from "mongoose";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiResponse } from "../utils/apiResponse";
import ApiError from "../utils/apiError";
import { Claim } from "../models/claim.model";
import { Farmer } from "../models/farmer.model";
import { Land } from "../models/land.model";
import { CreateClaimInput } from "../validators/claim.validator";

/**
 * POST /api/v1/claims
 * Files a new insurance claim (initially in Draft status).
 */
const createClaim = asyncHandler(async (req: Request, res: Response) => {
  const body = req.body as CreateClaimInput;

  // Verify farmer exists
  const farmer = await Farmer.findById(body.farmerId);
  if (!farmer || !farmer.isActive) {
    throw new ApiError(404, "Farmer not found or is inactive.");
  }

  // Verify land belongs to the farmer
  const land = await Land.findOne({
    _id: body.landId,
    farmerId: body.farmerId,
  });
  if (!land) {
    throw new ApiError(404, "Land parcel not found for this farmer.");
  }

  const claim = await Claim.create({
    farmerId: new Types.ObjectId(body.farmerId),
    landId: new Types.ObjectId(body.landId),
    cropName: body.cropName,
    damageReason: body.damageReason,
    incidentDate: new Date(body.incidentDate),
    estimatedLossPercentage: body.estimatedLossPercentage,
    description: body.description,
    claimAmount: body.claimAmount,
    status: "Draft",
  });

  return res.status(201).json(
    new ApiResponse(201, claim, "Claim created successfully."),
  );
});

/**
 * GET /api/v1/claims
 * Lists claims with optional filtering by status, farmerId.
 * Query params: ?status=...&farmerId=...&page=1&limit=20
 */
const getAllClaims = asyncHandler(async (req: Request, res: Response) => {
  const { status, farmerId, page = "1", limit = "20" } = req.query;

  const filter: Record<string, unknown> = {};
  if (status) filter.status = status;
  if (farmerId) filter.farmerId = new Types.ObjectId(farmerId as string);

  const pageNum = Math.max(1, Number(page));
  const limitNum = Math.min(100, Math.max(1, Number(limit)));
  const skip = (pageNum - 1) * limitNum;

  const [claims, total] = await Promise.all([
    Claim.find(filter)
      .populate("farmerId", "name phone displayAadhaar")
      .populate("landId", "surveyNumber areaAcres cropType")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum),
    Claim.countDocuments(filter),
  ]);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        claims,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          totalPages: Math.ceil(total / limitNum),
        },
      },
      "Claims fetched successfully.",
    ),
  );
});

/**
 * GET /api/v1/claims/:id
 * Gets a single claim with populated references.
 */
const getClaimById = asyncHandler(async (req: Request, res: Response) => {
  const claim = await Claim.findById(req.params.id)
    .populate("farmerId", "name phone displayAadhaar address")
    .populate("landId", "surveyNumber areaAcres cropType season")
    .populate("reviewedBy", "name email role");

  if (!claim) {
    throw new ApiError(404, "Claim not found.");
  }

  return res.status(200).json(
    new ApiResponse(200, claim, "Claim fetched successfully."),
  );
});

/**
 * PATCH /api/v1/claims/:id/submit
 * Farmer submits a draft claim for review.
 */
const submitClaim = asyncHandler(async (req: Request, res: Response) => {
  const claim = await Claim.findById(req.params.id);
  if (!claim) {
    throw new ApiError(404, "Claim not found.");
  }

  await claim.submit();

  return res.status(200).json(
    new ApiResponse(200, claim, "Claim submitted for review."),
  );
});

/**
 * PATCH /api/v1/claims/:id/review
 * Officer approves or rejects a claim.
 */
const reviewClaim = asyncHandler(async (req: Request, res: Response) => {
  const { action, approvedAmount, comments } = req.body;
  const officerId = new Types.ObjectId(req.officer!.id);

  const claim = await Claim.findById(req.params.id);
  if (!claim) {
    throw new ApiError(404, "Claim not found.");
  }

  if (action === "approve") {
    await claim.approve(officerId, approvedAmount, comments);
  } else {
    await claim.reject(officerId, comments);
  }

  return res.status(200).json(
    new ApiResponse(200, claim, `Claim ${action}d successfully.`),
  );
});

/**
 * GET /api/v1/claims/farmer/:farmerId
 * Gets all claims for a specific farmer.
 */
const getClaimsByFarmer = asyncHandler(async (req: Request, res: Response) => {
  const claims = await Claim.findByFarmer(
    new Types.ObjectId(req.params.farmerId as string),
  );

  return res.status(200).json(
    new ApiResponse(200, claims, "Claims fetched successfully."),
  );
});

export {
  createClaim,
  getAllClaims,
  getClaimById,
  submitClaim,
  reviewClaim,
  getClaimsByFarmer,
};
