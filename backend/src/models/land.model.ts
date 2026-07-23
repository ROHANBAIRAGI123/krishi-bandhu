import { Schema, model, Document, Model, Types } from "mongoose";

export interface ILand extends Document {
  _id: Types.ObjectId;
  farmerId: Types.ObjectId;
  surveyNumber: string;
  areaAcres: number;
  cropType: string;
  season: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface ILandMethods {
  /** Converts the stored acreage to hectares (1 acre = 0.404686 ha). */
  toHectares(): number;
}

type LandModel = Model<ILand, {}, ILandMethods> & {
  /** All land parcels belonging to a farmer. */
  findByFarmer(farmerId: Types.ObjectId): Promise<(ILand & ILandMethods)[]>;
  getTotalAreaAcres(farmerId: Types.ObjectId): Promise<number>;
};

const LandSchema = new Schema<ILand, LandModel, ILandMethods>(
  {
    farmerId: { type: Schema.Types.ObjectId, ref: "Farmer", required: true, index: true },
    surveyNumber: { type: String, required: true },
    areaAcres: { type: Number, required: true, min: 0 },
    cropType: { type: String, required: true },
    season: { type: String, required: true },
  },
  { timestamps: true },
);

// A farmer cannot register the same survey number twice.
LandSchema.index({ farmerId: 1, surveyNumber: 1 }, { unique: true });

LandSchema.methods.toHectares = function (this: ILand): number {
  return Number((this.areaAcres * 0.404686).toFixed(4));
};

LandSchema.statics.findByFarmer = function (farmerId: Types.ObjectId) {
  return this.find({ farmerId }).sort({ createdAt: -1 });
};

LandSchema.statics.getTotalAreaAcres = async function (farmerId: Types.ObjectId) {
  const result = await this.aggregate([
    { $match: { farmerId } },
    { $group: { _id: "$farmerId", total: { $sum: "$areaAcres" } } },
  ]);
  return result.length ? result[0].total : 0;
};

export const Land = model<ILand, LandModel>("Land", LandSchema, "lands");