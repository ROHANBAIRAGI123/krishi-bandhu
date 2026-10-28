import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiResponse } from "../utils/apiResponse";
import ApiError from "../utils/apiError";
import { Officer } from "../models/officer.model";
import { RegisterOfficerInput, LoginOfficerInput } from "../validators/officer.validator";

/**
 * POST /api/v1/officers/register
 * Creates a new officer account.
 */
const registerOfficer = asyncHandler(async (req: Request, res: Response) => {
  const { role, name, phone, email, password, assignedDistrict } =
    req.body as RegisterOfficerInput;

  // Check for existing officer with same email
  const existing = await Officer.findOne({ email: email.toLowerCase() });
  if (existing) {
    throw new ApiError(409, "An officer with this email already exists.");
  }

  const officer = new Officer({
    role,
    name,
    phone,
    email,
    assignedDistrict,
  });

  // Virtual setter triggers bcrypt hashing in the pre-save hook
  (officer as any).password = password;

  await officer.save();

  const token = officer.generateAuthToken();

  return res.status(201).json(
    new ApiResponse(
      201,
      {
        officer: officer.toSafeJSON(),
        token,
      },
      "Officer registered successfully.",
    ),
  );
});

/**
 * POST /api/v1/officers/login
 * Authenticates an officer and returns a JWT.
 */
const loginOfficer = asyncHandler(async (req: Request, res: Response) => {
  const { email, password } = req.body as LoginOfficerInput;

  // findByEmail selects +passwordHash
  const officer = await Officer.findByEmail(email);
  if (!officer) {
    throw new ApiError(401, "Invalid email or password.");
  }

  const isMatch = await officer.comparePassword(password);
  if (!isMatch) {
    throw new ApiError(401, "Invalid email or password.");
  }

  await officer.recordLogin();

  const token = officer.generateAuthToken();

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        officer: officer.toSafeJSON(),
        token,
      },
      "Login successful.",
    ),
  );
});

/**
 * GET /api/v1/officers/me
 * Returns the currently authenticated officer's profile.
 */
const getMe = asyncHandler(async (req: Request, res: Response) => {
  const officer = await Officer.findById(req.officer!.id);
  if (!officer) {
    throw new ApiError(404, "Officer not found.");
  }

  return res.status(200).json(
    new ApiResponse(200, officer.toSafeJSON(), "Officer profile fetched."),
  );
});

/**
 * GET /api/v1/officers
 * Lists all officers (admin only).
 */
const getAllOfficers = asyncHandler(async (_req: Request, res: Response) => {
  const officers = await Officer.find().sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, officers, "Officers fetched successfully."),
  );
});

export { registerOfficer, loginOfficer, getMe, getAllOfficers };
