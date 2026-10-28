import { Router } from "express";
import {
  createFarmer,
  getAllFarmers,
  getFarmerById,
  getFarmerByPhone,
  updateFarmer,
  deleteFarmer,
} from "../controllers/farmer.controller";
import { validate } from "../middlewares/validate.middleware";
import { authenticate } from "../middlewares/auth.middleware";
import {
  createFarmerSchema,
  updateFarmerSchema,
} from "../validators/farmer.validator";

const router = Router();

// All farmer routes require officer authentication
router.use(authenticate);

router.post("/", validate(createFarmerSchema), createFarmer);
router.get("/", getAllFarmers);
router.get("/phone/:phone", getFarmerByPhone);
router.get("/:id", getFarmerById);
router.patch("/:id", validate(updateFarmerSchema), updateFarmer);
router.delete("/:id", deleteFarmer);

export default router;
