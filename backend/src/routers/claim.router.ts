import { Router } from "express";
import {
  createClaim,
  getAllClaims,
  getClaimById,
  submitClaim,
  reviewClaim,
  getClaimsByFarmer,
} from "../controllers/claim.controller";
import { validate } from "../middlewares/validate.middleware";
import { authenticate, authorize } from "../middlewares/auth.middleware";
import {
  createClaimSchema,
  reviewClaimSchema,
} from "../validators/claim.validator";

const router = Router();

// All claim routes require officer authentication
router.use(authenticate);

router.post("/", validate(createClaimSchema), createClaim);
router.get("/", getAllClaims);
router.get("/farmer/:farmerId", getClaimsByFarmer);
router.get("/:id", getClaimById);
router.patch("/:id/submit", submitClaim);
router.patch(
  "/:id/review",
  authorize("admin", "field_officer"),
  validate(reviewClaimSchema),
  reviewClaim,
);

export default router;
