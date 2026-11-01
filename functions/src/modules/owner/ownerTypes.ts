export type PayoutStatus = 'pending' | 'processing' | 'completed' | 'failed';

export interface OwnerPayoutDocument {
  payoutId: string;
  ownerId: string;
  bookingId: string;
  grossAmount: number; // Integer minor units (paise)
  platformFee: number; // 0% brokerage in RoomWala, or minimal payment gateway fee
  netAmount: number; // Integer minor units (paise)
  currency: string;
  providerPayoutId: string | null;
  status: PayoutStatus;
  requestedAt: string;
  processedAt: string | null;
  failureReason: string | null;
}

export interface OwnerDashboardMetrics {
  totalListings: number;
  publishedListings: number;
  pendingListings: number;
  upcomingBookings: number;
  completedBookings: number;
  grossBookingValuePaise: number;
  platformFeesPaise: number;
  netEarningsPaise: number;
  pendingPayoutsPaise: number;
  completedPayoutsPaise: number;
}

export interface RoomBlockDocument {
  blockId: string;
  roomId: string;
  startDate: string; // YYYY-MM-DD
  endDate: string; // YYYY-MM-DD
  reason: 'maintenance' | 'owner_block' | 'other';
  createdBy: string;
  status: 'active' | 'released';
  createdAt: string;
  updatedAt: string;
}

export interface SubmitOwnerApplicationInput {
  userId: string;
  propertyAddress: string;
  taxIdentifierMasked?: string;
  bankAccountNumberMasked?: string;
  bankIfsc?: string;
}

