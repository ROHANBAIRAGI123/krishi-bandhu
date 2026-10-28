import { z } from "zod";

/** POST /api/v1/farmers */
export const createFarmerSchema = z.object({
  name: z.object({
    first: z.string().min(1, "First name is required").trim(),
    last: z.string().min(1, "Last name is required").trim(),
  }),
  phone: z
    .string()
    .regex(/^\d{10}$/, "Phone number must be exactly 10 digits"),
  aadhaarNumber: z
    .string()
    .regex(/^\d{12}$/, "Aadhaar number must be exactly 12 digits"),
  address: z.object({
    state: z.string().min(1, "State is required"),
    district: z.string().min(1, "District is required"),
    village: z.string().min(1, "Village is required"),
  }),
});

/** PATCH /api/v1/farmers/:id */
export const updateFarmerSchema = z.object({
  name: z
    .object({
      first: z.string().min(1).trim().optional(),
      last: z.string().min(1).trim().optional(),
    })
    .optional(),
  phone: z
    .string()
    .regex(/^\d{10}$/, "Phone number must be exactly 10 digits")
    .optional(),
  address: z
    .object({
      state: z.string().min(1).optional(),
      district: z.string().min(1).optional(),
      village: z.string().min(1).optional(),
    })
    .optional(),
  isActive: z.boolean().optional(),
});

export type CreateFarmerInput = z.infer<typeof createFarmerSchema>;
export type UpdateFarmerInput = z.infer<typeof updateFarmerSchema>;
