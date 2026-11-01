export type ExtensionOfferStatus =
  | 'offered'
  | 'accepted'
  | 'declined'
  | 'expired'
  | 'payment_pending'
  | 'confirmed';

export interface ExtensionOfferDocument {
  offerId: string;
  bookingId: string;
  roomId: string;
  customerId: string;
  ownerId: string;
  offeredAt: string;
  expiresAt: string;
  requestedCheckIn: string; // Original checkOut date (start of extension)
  requestedCheckOut: string; // New extended checkOut date
  quotedAmount: number; // Integer minor units (paise)
  currency: string; // 'INR'
  paymentId: string | null;
  status: ExtensionOfferStatus;
  reminderScheduledAt: string | null;
  reminderSentAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CreateExtensionOfferInput {
  bookingId: string;
  extensionNights?: number; // Default 1 night
  discountPercentage?: number; // E.g. 15% priority discount
}

export interface RequestExtensionDatesInput {
  offerId: string;
  customerId: string;
  newRequestedCheckOut: string;
}

export interface ConfirmExtensionInput {
  offerId: string;
  customerId: string;
  paymentId: string;
}

