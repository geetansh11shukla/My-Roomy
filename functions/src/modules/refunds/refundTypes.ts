export type RefundStatus =
  | 'pending'
  | 'processing'
  | 'succeeded'
  | 'failed'
  | 'manual_review';

export interface CancellationPolicyRule {
  hoursBeforeCheckIn: number; // e.g. 24, 48, 72
  refundPercentage: number; // e.g. 100 for full refund, 50 for half, 0 for none
  deductFlatFeePaise?: number; // Optional nominal processing charge
}

export interface CancellationPolicyDocument {
  policyId: string;
  name: string;
  description: string;
  rules: CancellationPolicyRule[];
  effectiveFrom: string; // ISO 8601
  effectiveTo: string | null; // ISO 8601 or null if ongoing
  active: boolean;
}

export interface RefundDocument {
  refundId: string;
  bookingId: string;
  paymentId: string;
  amount: number; // Integer minor units (paise)
  currency: string;
  reason: string;
  providerRefundId: string | null;
  status: RefundStatus;
  requestedBy: string;
  requestedAt: string;
  processedAt: string | null;
  failureReason: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CancelBookingInput {
  bookingId: string;
  requestedByUid: string;
  reason: string;
  userRole?: string;
}

export interface CancelBookingResult {
  bookingId: string;
  bookingStatus: string;
  refundStatus: RefundStatus | 'no_refund';
  refundAmountPaise: number;
  refundId: string | null;
  inventoryReleased: boolean;
}

