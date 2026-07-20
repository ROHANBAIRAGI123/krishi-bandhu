import crypto from "crypto";

export function hashAadhaar(rawAadhaar: string): string {
  const secret = process.env.AADHAAR_HASH_SECRET;
  if (!secret) {
    throw new Error(
      "AADHAAR_HASH_SECRET is not set. Refusing to hash Aadhaar without a secret.",
    );
  }
  const digits = rawAadhaar.replace(/\D/g, "");
  if (digits.length !== 12) {
    throw new Error("Aadhaar number must be exactly 12 digits.");
  }
  return crypto.createHmac("sha256", secret).update(digits).digest("hex");
}


export function maskAadhaar(rawAadhaar: string): string {
  const digits = rawAadhaar.replace(/\D/g, "");
  if (digits.length !== 12) {
    throw new Error("Aadhaar number must be exactly 12 digits.");
  }
  const last4 = digits.slice(-4);
  return `xxxx-xxxx-${last4}`;
}