export type CropHealthStatus = "Good" | "Moderate" | "Poor";

export type VerificationStatus = "Pending" | "Verified" | "Flagged" | "Rejected";

export type OfficerRole = "admin" | "field_officer" | "data_annotator";

export type ClaimStatus =
    | "Draft"
    | "Submitted"
    | "Under Review"
    | "Approved"
    | "Rejected"
    | "Paid";