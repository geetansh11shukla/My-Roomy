export type BookingStatus =
  | 'pending_payment'
  | 'confirmed'
  | 'cancelled'
  | 'completed'
  | 'expired'
  | 'payment_failed'
  | 'refund_pending'
  | 'refunded';

export type PaymentLifecycleStatus =
  | 'unpaid'
  | 'authorized'
  | 'captured'
  | 'failed'
  | 'refund_initiated'
  | 'refunded';

export interface BookingDocument {
  bookingId: string;
  roomId: string;
  customerId: string;
  ownerId: string;
  roomTitleSnapshot: string;
  roomPhotoSnapshot: string;
  checkIn: string; // YYYY-MM-DD
  checkOut: string; // YYYY-MM-DD
  guestCount: number;
  nightCount: number;
  pricePerNightSnapshotPaise: number; // Integer minor currency units
  subtotalPaise: number;
  feesPaise: number; // 0 for zero-brokerage
  taxAmountPaise: number; // 5% GST
  discountAmountPaise: number;
  totalAmountPaise: number;
  currency: string;
  bookingStatus: BookingStatus;
  paymentStatus: PaymentLifecycleStatus;
  holdId: string;
  paymentId?: string;
  cancellationPolicySnapshot: string;
  cancellationReason?: string;
  cancelledBy?: string;
  cancelledAt?: string;
  confirmedAt?: string;
  completedAt?: string;
  accessPin?: string;
  locationUrl?: string;
  priorityExtensionEligible: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface BookingHoldQuoteResult {
  holdId: string;
  roomId: string;
  roomTitle: string;
  roomCoverPhoto: string;
  checkIn: string;
  checkOut: string;
  nightCount: number;
  guestCount: number;
  pricePerNight: number;
  subtotal: number;
  fees: number;
  taxAmount: number;
  discountAmount: number;
  totalAmount: number;
  currency: string;
  expiresAt: string;
}

