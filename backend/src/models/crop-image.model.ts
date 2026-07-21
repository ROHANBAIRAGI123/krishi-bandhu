import { Schema, model, Document, Model, Types } from "mongoose";
import { CropHealthStatus, VerificationStatus } from "../types/common.types";

export interface ICropImageLocation {
  latitude: number;
  longitude: number;
}

export interface ICropInfo {
  cropName: string;
  growthStage?: string;
  healthStatus?: CropHealthStatus;
}

export interface ICropImage extends Document {
  _id: Types.ObjectId;
  farmerId: Types.ObjectId;
  landId: Types.ObjectId;
  imageUrl: string[];
  thumbnailUrl?: string;
  location: ICropImageLocation;
  cropInfo: ICropInfo;
  mlConfidenceScore?: number;
  verificationStatus: VerificationStatus;
  verifiedBy?: Types.ObjectId; // Officer ID
  remarks?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface ICropImageMethods {
  /** Marks the image verified by a given officer, with optional remarks. */
  verify(officerId: Types.ObjectId, remarks?: string): Promise<void>;

  /** Flags the image for review, with a required reason. */
  flag(officerId: Types.ObjectId, remarks: string): Promise<void>;

  /** Rejects the image, with a required reason. */
  reject(officerId: Types.ObjectId, remarks: string): Promise<void>;
}

type CropImageModel = Model<ICropImage, {}, ICropImageMethods> & {
  findByFarmer(farmerId: Types.ObjectId): Promise<(ICropImage & ICropImageMethods)[]>;
  findPendingVerification(): Promise<(ICropImage & ICropImageMethods)[]>;
};

const CropImageSchema = new Schema<ICropImage, CropImageModel, ICropImageMethods>(
  {
    farmerId: { type: Schema.Types.ObjectId, ref:"Farmer", required: true, index: true },
    landId: { type: Schema.Types.ObjectId, ref:"Land", required: true },
    imageUrl: {
      type: [String],
      required: true,
      validate: {
        validator: (v: string[]) => Array.isArray(v) && v.length > 0,
        message: "At least one imageUrl is required.",
      },
    },
    thumbnailUrl: { type: String },
    location: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
    },
    cropInfo: {
      cropName: { type: String, required: true },
      growthStage: { type: String },
      healthStatus: { type: String, enum: ["Good", "Moderate", "Poor"] },
    },
    mlConfidenceScore: { type: Number, min: 0, max: 1 },
    verificationStatus: {
      type: String,
      enum: ["Pending", "Verified", "Flagged", "Rejected"],
      default: "Pending",
      index: true,
    },
    verifiedBy: { type: Types.ObjectId, ref:"Officer" },
    remarks: { type: String },
  },
  { timestamps: true },
);

async function setStatus(
  doc: ICropImage,
  status: VerificationStatus,
  officerId: Types.ObjectId,
  remarks?: string,
) {
  doc.verificationStatus = status;
  doc.verifiedBy = officerId;
  if (remarks) doc.remarks = remarks;
  await doc.save();
}

CropImageSchema.methods.verify = function (
  this: ICropImage,
  officerId: Types.ObjectId,
  remarks?: string,
) {
  return setStatus(this, "Verified", officerId, remarks);
};

CropImageSchema.methods.flag = function (
  this: ICropImage,
  officerId: Types.ObjectId,
  remarks: string,
) {
  return setStatus(this, "Flagged", officerId, remarks);
};

CropImageSchema.methods.reject = function (
  this: ICropImage,
  officerId: Types.ObjectId,
  remarks: string,
) {
  return setStatus(this, "Rejected", officerId, remarks);
};

CropImageSchema.statics.findByFarmer = function (farmerId: Types.ObjectId) {
  return this.find({ farmerId }).sort({ uploadedAt: -1 });
};

CropImageSchema.statics.findPendingVerification = function () {
  return this.find({ verificationStatus: "Pending" }).sort({ uploadedAt: 1 });
};

export const CropImage = model<ICropImage, CropImageModel>(
  "CropImage",
  CropImageSchema,
  "crop_images",
);