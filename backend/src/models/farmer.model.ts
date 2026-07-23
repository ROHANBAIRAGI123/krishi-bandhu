import { Schema, model, Document, Model, Types } from "mongoose";
import { hashAadhaar, maskAadhaar } from "../utils/aadhaar.util";

export interface IFarmerName {
  first: string;
  last: string;
}

export interface IFarmerAddress {
  state: string;
  district: string;
  village: string;
}

export interface IFarmer extends Document {
  _id: Types.ObjectId;
  name: IFarmerName;
  phone: string;
  aadhaarNumberHash: string;
  displayAadhaar: string; // Masked, e.g. "xxxx-xxxx-1234"
  address: IFarmerAddress;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface IFarmerMethods {
  getFullName(): string;
  toSafeJSON(): Record<string, unknown>;
}

type FarmerModel = Model<IFarmer, {}, IFarmerMethods> & {
  findByPhone(phone: string): Promise<(IFarmer & IFarmerMethods) | null>;
  findByAadhaar(rawAadhaar: string): Promise<(IFarmer & IFarmerMethods) | null>;

  registerFarmer(input: {
    farmerId: string;
    name: IFarmerName;
    phone: string;
    rawAadhaar: string;
    address: IFarmerAddress;
  }): Promise<IFarmer & IFarmerMethods>;
};

const FarmerSchema = new Schema<IFarmer, FarmerModel, IFarmerMethods>(
  {
    name: {
      first: { type: String, required: true, trim: true },
      last: { type: String, required: true, trim: true },
    },
    phone: {
      type: String,
      required: true,
      index: true,
      match: [/^\d{10}$/, "Phone number must be 10 digits."],
    },
    aadhaarNumberHash: { type: String, required: true, unique: true },
    displayAadhaar: { type: String, required: true },
    address: {
      state: { type: String, required: true },
      district: { type: String, required: true },
      village: { type: String, required: true },
    },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true },
);

FarmerSchema.methods.getFullName = function (this: IFarmer): string {
  return `${this.name.first} ${this.name.last}`.trim();
};

FarmerSchema.methods.toSafeJSON = function (this: IFarmer) {
  return {
    _id: this._id,
    name: this.name,
    phone: this.phone,
    displayAadhaar: this.displayAadhaar,
    address: this.address,
    isActive: this.isActive,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

FarmerSchema.statics.findByPhone = function (phone: string) {
  return this.findOne({ phone, isActive: true });
};

FarmerSchema.statics.findByAadhaar = function (rawAadhaar: string) {
  const hash = hashAadhaar(rawAadhaar);
  return this.findOne({ aadhaarNumberHash: hash });
};

FarmerSchema.statics.registerFarmer = async function (input) {
  const aadhaarNumberHash = hashAadhaar(input.rawAadhaar);
  const existing = await this.findOne({ aadhaarNumberHash });
  if (existing) {
    throw new Error("A farmer with this Aadhaar number is already registered.");
  }
  return this.create({
    name: input.name,
    phone: input.phone,
    aadhaarNumberHash,
    displayAadhaar: maskAadhaar(input.rawAadhaar),
    address: input.address,
  });
};

export const Farmer = model<IFarmer, FarmerModel>(
  "Farmer",
  FarmerSchema,
  "farmers",
);