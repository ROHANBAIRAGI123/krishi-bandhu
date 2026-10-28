import { Router } from "express";
import {
  registerOfficer,
  loginOfficer,
  getMe,
  getAllOfficers,
} from "../controllers/officer.controller";
import { validate } from "../middlewares/validate.middleware";
import { authenticate, authorize } from "../middlewares/auth.middleware";
import {
  registerOfficerSchema,
  loginOfficerSchema,
} from "../validators/officer.validator";

const router = Router();

// ── Public ────────────────────────────────────────────────
router.post("/register", validate(registerOfficerSchema), registerOfficer);
router.post("/login", validate(loginOfficerSchema), loginOfficer);

// ── Protected ─────────────────────────────────────────────
router.get("/me", authenticate, getMe);
router.get("/", authenticate, authorize("admin"), getAllOfficers);

export default router;
