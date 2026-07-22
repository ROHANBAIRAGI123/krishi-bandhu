import { Schema, model, Document, Model, Types } from "mongoose";
import { ClaimStatus } from "../types/common.types";

export interface IClaim extends Document {
    _id: Types.ObjectId;
    farmerId: Types.ObjectId;
    landId: Types.ObjectId;
    cropName: string;
    damageReason: string;
    incidentDate: Date;
    estimatedLossPercentage: number;
    description: string;
    supportingImages: Types.ObjectId[];
    claimAmount: number;
    status: ClaimStatus;
    approvedAmount?: number;
    reviewerComments?: string;
    reviewedBy?: Types.ObjectId;
    reviewedAt?: Date;
    createdAt: Date;
    updatedAt: Date;
}

export interface IClaimMethods {
    // Moves a Draft claim into Submitted, locking it for farmer edits. 
    submit(): Promise<void>;
    // Approves the claim with a final payable amount. 
    approve(officerId: Types.ObjectId, approvedAmount: number, comments?: string): Promise<void>;
    // Rejects the claim with a required reason. 
    reject(officerId: Types.ObjectId, comments: string): Promise<void>;
    // Marks an approved claim as paid out. 
    markPaid(): Promise<void>;
}

type ClaimModel = Model<IClaim, {}, IClaimMethods> & {
    findByFarmer(farmerId: Types.ObjectId): Promise<(IClaim & IClaimMethods)[]>;
    findByStatus(status: ClaimStatus): Promise<(IClaim & IClaimMethods)[]>;
};

const ClaimSchema = new Schema<IClaim, ClaimModel, IClaimMethods>(
    {
        farmerId: { type: Schema.Types.ObjectId, ref: "Farmer", required: true, index: true },
        landId: { type: Schema.Types.ObjectId, ref: "Land", required: true, index: true },
        cropName: { type: String, required: true },
        damageReason: {
            type: String,
            enum: [
                "Flood",
                "Drought",
                "Heavy Rain",
                "Hailstorm",
                "Pest Attack",
                "Disease",
                "Cyclone",
                "Other",
            ],
        },
        incidentDate: { type: Date, required: true },
        estimatedLossPercentage: { type: Number, required: true, min: 0, max: 100 },
        description: { type: String, required: true, maxlength: 2000 },
        supportingImages: [{ type: Schema.Types.ObjectId, ref: "CropImage" }],
        claimAmount: { type: Number, required: true, min: 0 },
        status: {
            type: String,
            enum: ["Draft", "Submitted", "Under Review", "Approved", "Rejected", "Paid"],
            default: "Draft",
            index: true,
        },
        approvedAmount: { type: Number, min: 0 },
        reviewerComments: { type: String, maxlength: 500 },
        reviewedBy: { type: Schema.Types.ObjectId, ref: "Officer", index: true },
        reviewedAt: { type: Date },
    },
    { timestamps: true },
);

function assertTransition(current: ClaimStatus, allowed: ClaimStatus[]) {
    if (!allowed.includes(current)) {
        throw new Error(`Cannot transition claim from status "${current}".`);
    }
}

ClaimSchema.methods.submit = async function (this: IClaim) {
    assertTransition(this.status, ["Draft"]);
    this.status = "Submitted";
    await this.save();
};

ClaimSchema.methods.approve = async function (
    this: IClaim,
    officerId: Types.ObjectId,
    approvedAmount: number,
    comments?: string,
) {
    if (approvedAmount > this.claimAmount) {
        throw new Error(
            "Approved amount cannot exceed claim amount."
        );
    }

    assertTransition(this.status, ["Submitted", "Under Review"]);
    this.status = "Approved";
    this.approvedAmount = approvedAmount;
    this.reviewerComments = comments;
    this.reviewedBy = officerId;
    this.reviewedAt = new Date();
    await this.save();
};

ClaimSchema.methods.reject = async function (
    this: IClaim,
    officerId: Types.ObjectId,
    comments: string,
) {
    assertTransition(this.status, ["Submitted", "Under Review"]);
    this.status = "Rejected";
    this.reviewerComments = comments;
    this.reviewedBy = officerId;
    this.reviewedAt = new Date();
    await this.save();
};

ClaimSchema.methods.markPaid = async function (this: IClaim) {
    assertTransition(this.status, ["Approved"]);
    this.status = "Paid";
    await this.save();
};

ClaimSchema.statics.findByFarmer = function (farmerId: Types.ObjectId) {
    return this.find({ farmerId }).sort({ createdAt: -1 });
};

ClaimSchema.statics.findByStatus = function (status: ClaimStatus) {
    return this.find({ status }).sort({ createdAt: -1 });
};

export const Claim = model<IClaim, ClaimModel>("Claim", ClaimSchema, "claims");