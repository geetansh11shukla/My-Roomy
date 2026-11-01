export type VerificationType = 'aadhaar' | 'driving_license' | 'passport' | 'voter_id';

export type VerificationStatus =
  | 'not_started'
  | 'pending'
  | 'verified'
  | 'rejected'
  | 'expired'
  | 'manual_review';

export interface VerificationCaseDocument {
  verificationId: string;
  userId: string;
  verificationType: VerificationType;
  provider: 'digilocker' | 'hyperverge' | 'mock';
  providerReference: string;
  status: VerificationStatus;
  submittedAt: string;
  reviewedAt: string | null;
  reviewedBy: string | null;
  rejectionReasonCode: string | null;
  expiresAt: string | null;
  retentionUntil: string; // ISO 8601 for compliance-driven automated deletion
  consentVersion: string;
  minimumAgeRequired: number; // Configurable minimum age (e.g. 18)
  ageVerified: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface StartVerificationInput {
  userId: string;
  verificationType: VerificationType;
  consentVersion: string;
  documentNumberMasked: string; // Stored securely/masked, no raw ID in logs
  dateOfBirth?: string; // YYYY-MM-DD
  minimumAgePolicy?: number; // Configurable, not hard-coded legal conclusion
}

export interface StartVerificationResult {
  verificationId: string;
  status: VerificationStatus;
  providerSessionUrl?: string;
  ageEligible: boolean;
  requiresManualReview: boolean;
}

export interface AdminReviewInput {
  verificationId: string;
  adminUid: string;
  decision: 'approve' | 'reject';
  rejectionReasonCode?: string;
}

