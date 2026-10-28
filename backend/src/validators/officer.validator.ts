import { z } from "zod";

/** POST /api/v1/officers/register */
export const registerOfficerSchema = z.object({
  role: z.enum(["admin", "field_officer", "data_annotator"]),
  name: z.object({
    first: z.string().min(1, "First name is required").trim(),
    last: z.string().min(1, "Last name is required").trim(),
  }),
  phone: z
    .string()
    .regex(/^\d{10}$/, "Phone number must be exactly 10 digits"),
  email: z.string().email("Invalid email address").trim().toLowerCase(),
  password: z.string().min(8, "Password must be at least 8 characters"),
  assignedDistrict: z.string().optional(),
});

/** POST /api/v1/officers/login */
export const loginOfficerSchema = z.object({
  email: z.string().email("Invalid email address").trim().toLowerCase(),
  password: z.string().min(1, "Password is required"),
});

export type RegisterOfficerInput = z.infer<typeof registerOfficerSchema>;
export type LoginOfficerInput = z.infer<typeof loginOfficerSchema>;
