import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiResponse } from "../utils/apiResponse";
import ApiError from "../utils/apiError";
import { Farmer } from "../models/farmer.model";
import { CreateFarmerInput, UpdateFarmerInput } from "../validators/farmer.validator";

/**
 * POST /api/v1/farmers
 * Registers a new farmer. Uses the static `registerFarmer` which
 * handles Aadhaar hashing + duplicate check internally.
 */
const createFarmer = asyncHandler(async (req: Request, res: Response) => {
  const { name, phone, aadhaarNumber, address } =
    req.body as CreateFarmerInput;

  const farmer = await Farmer.registerFarmer({
    farmerId: "", // auto-generated _id
    name,
    phone,
    rawAadhaar: aadhaarNumber,
    address,
  });

  return res.status(201).json(
    new ApiResponse(201, farmer.toSafeJSON(), "Farmer registered successfully."),
  );
});

/**
 * GET /api/v1/farmers
 * Lists all farmers with optional filtering by state/district.
 * Query params: ?state=...&district=...&page=1&limit=20
 */
const getAllFarmers = asyncHandler(async (req: Request, res: Response) => {
  const { state, district, page = "1", limit = "20" } = req.query;

  const filter: Record<string, unknown> = { isActive: true };
  if (state) filter["address.state"] = state;
  if (district) filter["address.district"] = district;

  const pageNum = Math.max(1, Number(page));
  const limitNum = Math.min(100, Math.max(1, Number(limit)));
  const skip = (pageNum - 1) * limitNum;

  const [farmers, total] = await Promise.all([
    Farmer.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limitNum),
    Farmer.countDocuments(filter),
  ]);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        farmers,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          totalPages: Math.ceil(total / limitNum),
        },
      },
      "Farmers fetched successfully.",
    ),
  );
});

/**
 * GET /api/v1/farmers/:id
 * Gets a single farmer by MongoDB _id.
 */
const getFarmerById = asyncHandler(async (req: Request, res: Response) => {
  const farmer = await Farmer.findById(req.params.id);
  if (!farmer) {
    throw new ApiError(404, "Farmer not found.");
  }

  return res.status(200).json(
    new ApiResponse(200, farmer.toSafeJSON(), "Farmer fetched successfully."),
  );
});

/**
 * GET /api/v1/farmers/phone/:phone
 * Looks up a farmer by phone number.
 */
const getFarmerByPhone = asyncHandler(async (req: Request, res: Response) => {
  const farmer = await Farmer.findByPhone(req.params.phone as string);
  if (!farmer) {
    throw new ApiError(404, "No active farmer found with this phone number.");
  }

  return res.status(200).json(
    new ApiResponse(200, farmer.toSafeJSON(), "Farmer fetched successfully."),
  );
});

/**
 * PATCH /api/v1/farmers/:id
 * Partially updates farmer profile (cannot change Aadhaar).
 */
const updateFarmer = asyncHandler(async (req: Request, res: Response) => {
  const updates = req.body as UpdateFarmerInput;
  const farmer = await Farmer.findById(req.params.id);

  if (!farmer) {
    throw new ApiError(404, "Farmer not found.");
  }

  // Merge name fields
  if (updates.name) {
    if (updates.name.first) farmer.name.first = updates.name.first;
    if (updates.name.last) farmer.name.last = updates.name.last;
  }

  // Merge address fields
  if (updates.address) {
    if (updates.address.state) farmer.address.state = updates.address.state;
    if (updates.address.district) farmer.address.district = updates.address.district;
    if (updates.address.village) farmer.address.village = updates.address.village;
  }

  if (updates.phone !== undefined) farmer.phone = updates.phone;
  if (updates.isActive !== undefined) farmer.isActive = updates.isActive;

  await farmer.save();

  return res.status(200).json(
    new ApiResponse(200, farmer.toSafeJSON(), "Farmer updated successfully."),
  );
});

/**
 * DELETE /api/v1/farmers/:id
 * Soft-deletes a farmer by setting isActive = false.
 */
const deleteFarmer = asyncHandler(async (req: Request, res: Response) => {
  const farmer = await Farmer.findById(req.params.id);
  if (!farmer) {
    throw new ApiError(404, "Farmer not found.");
  }

  farmer.isActive = false;
  await farmer.save();

  return res.status(200).json(
    new ApiResponse(200, null, "Farmer deactivated successfully."),
  );
});

export {
  createFarmer,
  getAllFarmers,
  getFarmerById,
  getFarmerByPhone,
  updateFarmer,
  deleteFarmer,
};
