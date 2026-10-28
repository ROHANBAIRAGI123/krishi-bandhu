import type { Claim, ClaimStatus, DemoData, VerificationStatus } from '@/types';

export function validateClaimDecision(
  claim: Claim,
  status: ClaimStatus,
  comments: string,
  amount?: number,
) {
  if (
    status === 'Paid'
      ? claim.status !== 'Approved'
      : !['Submitted', 'Under Review'].includes(claim.status) ||
        !['Under Review', 'Approved', 'Rejected'].includes(status)
  ) {
    throw new Error('This claim can no longer be changed with that action.');
  }
  if (comments.length > 500) throw new Error('Review notes must be 500 characters or fewer.');
  if (status === 'Rejected' && !comments.trim())
    throw new Error('Add a reason before rejecting this claim.');
  if (
    status === 'Approved' &&
    (amount === undefined || !Number.isFinite(amount) || amount < 0 || amount > claim.claimAmount)
  ) {
    throw new Error('Approved amount must be between zero and the requested amount.');
  }
}

// Restore only mutable demo fields. Never let saved data replace identities,
// financial baselines, evidence URLs, or relationships in the seed dataset.
export function restoreDemoData(value: unknown, seed: DemoData): DemoData {
  try {
    if (!value || typeof value !== 'object') return seed;
    const saved = value as DemoData;
    if (
      saved.version !== 1 ||
      !Array.isArray(saved.claims) ||
      !Array.isArray(saved.images) ||
      !Array.isArray(saved.activities) ||
      saved.claims.length !== seed.claims.length ||
      saved.images.length !== seed.images.length
    )
      return seed;
    const claims = seed.claims.map((claim) => {
      const match = saved.claims.find((c) => c.id === claim.id);
      if (
        !match ||
        !['Submitted', 'Under Review', 'Approved', 'Rejected', 'Paid'].includes(match.status)
      )
        throw new Error('Invalid claim');
      if (
        match.approvedAmount !== undefined &&
        (!Number.isFinite(match.approvedAmount) ||
          match.approvedAmount < 0 ||
          match.approvedAmount > claim.claimAmount)
      )
        throw new Error('Invalid amount');
      if (['Approved', 'Paid'].includes(match.status) && match.approvedAmount === undefined)
        throw new Error('Missing amount');
      if (
        match.reviewerComments !== undefined &&
        (typeof match.reviewerComments !== 'string' || match.reviewerComments.length > 500)
      )
        throw new Error('Invalid comments');
      if (
        match.reviewedAt !== undefined &&
        (typeof match.reviewedAt !== 'string' || !Number.isFinite(Date.parse(match.reviewedAt)))
      )
        throw new Error('Invalid date');
      return {
        ...claim,
        status: match.status as ClaimStatus,
        approvedAmount: match.approvedAmount,
        reviewerComments: match.reviewerComments,
        reviewedAt: match.reviewedAt,
      };
    });
    const images = seed.images.map((image) => {
      const match = saved.images.find((i) => i.id === image.id);
      if (
        !match ||
        !['Pending', 'Verified', 'Flagged', 'Rejected'].includes(match.verificationStatus) ||
        (match.remarks !== undefined &&
          (typeof match.remarks !== 'string' || match.remarks.length > 500))
      )
        throw new Error('Invalid image');
      return {
        ...image,
        verificationStatus: match.verificationStatus as VerificationStatus,
        remarks: match.remarks,
      };
    });
    if (
      !saved.activities.every(
        (a) =>
          a &&
          typeof a.id === 'string' &&
          typeof a.message === 'string' &&
          typeof a.detail === 'string' &&
          typeof a.date === 'string' &&
          Number.isFinite(Date.parse(a.date)),
      )
    )
      return seed;
    return {
      ...seed,
      claims,
      images,
      activities: saved.activities
        .slice(0, 30)
        .map((a) => ({ id: a.id, message: a.message, detail: a.detail, date: a.date })),
    };
  } catch {
    return seed;
  }
}
