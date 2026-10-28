import { z } from "zod";

const damageReasons = [
  "Flood",
  "Drought",
  "Heavy Rain",
  "Hailstorm",
  "Pest Attack",
  "Disease",
  "Cyclone",
  "Other",
] as const;

/** POST /api/v1/claims */
export const createClaimSchema = z.object({
  farmerId: z.string().min(1, "farmerId is required"),
  landId: z.string().min(1, "landId is required"),
  cropName: z.string().min(1, "Crop name is required"),
  damageReason: z.enum(damageReasons),
  incidentDate: z.string().refine(
    (val) => !isNaN(Date.parse(val)),
    "incidentDate must be a valid date string",
  ),
  estimatedLossPercentage: z.number().min(0).max(100),
  description: z.string().min(1).max(2000),
  claimAmount: z.number().min(0, "Claim amount must be non-negative"),
});

/** PATCH /api/v1/claims/:id/review  (officer approves or rejects) */
export const reviewClaimSchema = z.object({
  action: z.enum(["approve", "reject"]),
  approvedAmount: z.number().min(0).optional(),
  comments: z.string().max(500).optional(),
}).refine(
  (data) => {
    if (data.action === "approve" && (data.approvedAmount === undefined || data.approvedAmount === null)) {
      return false;
    }
    if (data.action === "reject" && (!data.comments || data.comments.trim().length === 0)) {
      return false;
    }
    return true;
  },
  {
    message: "approvedAmount is required for approval; comments is required for rejection.",
  },
);

export type CreateClaimInput = z.infer<typeof createClaimSchema>;
export type ReviewClaimInput = z.infer<typeof reviewClaimSchema>;
