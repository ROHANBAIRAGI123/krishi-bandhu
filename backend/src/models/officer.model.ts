import { Schema, model, Document, Model, Types } from "mongoose";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { OfficerRole } from "../types/common.types";

export interface IOfficerName {
    first: string;
    last: string;
}

export interface IOfficer extends Document {
    _id: Types.ObjectId;
    role: OfficerRole;
    name: IOfficerName;
    phone: string;
    email: string;
    passwordHash: string;
    assignedDistrict?: string;
    lastLogin?: Date;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}

interface IOfficerDocument extends IOfficer {
    _plainPassword?: string;
}

export interface IOfficerMethods {
    /** Compares a plaintext password against the stored hash. */
    comparePassword(candidate: string): Promise<boolean>;
    /** Issues a signed JWT for this officer (expects process.env.JWT_SECRET). */
    generateAuthToken(): string;
    /** Updates lastLogin to now and persists it. */
    recordLogin(): Promise<void>;
    toSafeJSON(): Record<string, unknown>;
}

type OfficerModel = Model<IOfficerDocument, {}, IOfficerMethods> & {
    findByEmail(email: string): Promise<(IOfficerDocument & IOfficerMethods) | null>;
    findActiveByRole(role: OfficerRole): Promise<(IOfficerDocument & IOfficerMethods)[]>;
};

const OfficerSchema = new Schema<IOfficer, OfficerModel, IOfficerMethods>(
    {
        role: {
            type: String,
            enum: ["admin", "field_officer", "data_annotator"],
            required: true,
        },
        name: {
            first: { type: String, required: true, trim: true },
            last: { type: String, required: true, trim: true },
        },
        phone: {
            type: String,
            required: true,
            unique: true,
            index: true,
            match: [/^\d{10}$/, "Phone number must be 10 digits."]
        },
        email: {
            type: String,
            required: true,
            unique: true,
            lowercase: true,
            trim: true,
            match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, "Invalid email address."]
        },
        passwordHash: { type: String, required: true, select: false },
        assignedDistrict: { type: String },
        lastLogin: { type: Date },
        isActive: { type: Boolean, default: true },
    },
    { timestamps: true },
);

// Virtual setter: allows `officer.password = "plaintext"` to transparently
// hash into passwordHash, instead of every caller needing to bcrypt inline.
OfficerSchema.virtual("password").set(function (this: IOfficerDocument, plain: string) {
    if (plain.length < 8) {
        throw new Error("Password must be at least 8 characters.");
    }

    this._plainPassword = plain;
});

OfficerSchema.pre("save", async function (this: IOfficerDocument) {
    const plain = this._plainPassword;
    if (!plain) return;

    const salt = await bcrypt.genSalt(12);
    this.passwordHash = await bcrypt.hash(plain, salt);
});

OfficerSchema.methods.comparePassword = function (
    this: IOfficer,
    candidate: string,
) {
    return bcrypt.compare(candidate, this.passwordHash);
};

OfficerSchema.methods.generateAuthToken = function (this: IOfficer): string {
    const secret = process.env.JWT_SECRET;
    if (!secret) throw new Error("JWT_SECRET is not set.");
    return jwt.sign(
        { id: this._id, role: this.role },
        secret,
        { expiresIn: "12h" },
    );
};

OfficerSchema.methods.recordLogin = async function (this: IOfficer) {
    this.lastLogin = new Date();
    await this.save();
};

OfficerSchema.methods.toSafeJSON = function () {
    return {
        _id: this._id,
        role: this.role,
        name: this.name,
        phone: this.phone,
        email: this.email,
        assignedDistrict: this.assignedDistrict,
        lastLogin: this.lastLogin,
        isActive: this.isActive
    }
}

OfficerSchema.statics.findByEmail = function (email: string) {
    return this.findOne({ email: email.toLowerCase(), isActive: true }).select("+passwordHash");
};

OfficerSchema.statics.findActiveByRole = function (role: OfficerRole) {
    return this.find({ role, isActive: true });
};

export const Officer = model<IOfficer, OfficerModel>(
    "Officer",
    OfficerSchema,
    "officials",
);