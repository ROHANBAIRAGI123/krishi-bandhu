export type ClaimStatus = 'Submitted' | 'Under Review' | 'Approved' | 'Rejected' | 'Paid';
export type VerificationStatus = 'Pending' | 'Verified' | 'Flagged' | 'Rejected';
export type Season = 'Kharif 2026' | 'Rabi 2025–26';
export interface Farmer {
  id: string;
  name: string;
  phone: string;
  village: string;
  district: string;
  state: string;
  hectares: number;
  crop: string;
  enrolled: string;
}
export interface Claim {
  id: string;
  farmerId: string;
  cropName: string;
  damageReason: string;
  incidentDate: string;
  createdAt: string;
  season: Season;
  estimatedLossPercentage: number;
  claimAmount: number;
  status: ClaimStatus;
  description: string;
  approvedAmount?: number;
  reviewerComments?: string;
  reviewedAt?: string;
}
export interface CropImage {
  id: string;
  farmerId: string;
  cropName: string;
  season: Season;
  imageUrl: string;
  location: { latitude: number; longitude: number };
  verificationStatus: VerificationStatus;
  createdAt: string;
  remarks?: string;
}
export interface Activity {
  id: string;
  message: string;
  detail: string;
  date: string;
}
export interface DemoData {
  version: 1;
  farmers: Farmer[];
  claims: Claim[];
  images: CropImage[];
  activities: Activity[];
}
