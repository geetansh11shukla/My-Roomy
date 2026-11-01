export interface UserRecord {
  uid: string;
  fullName: string;
  email: string;
  phoneNumber: string;
  role: 'customer' | 'owner' | 'admin';
  accountStatus: 'active' | 'suspended' | 'pending_review';
  profilePhotoUrl?: string;
  dateOfBirth?: string;
  ageEligibilityStatus: 'eligible_18_plus' | 'underage' | 'unverified';
  identityVerificationStatus: 'not_started' | 'pending' | 'verified' | 'rejected';
  fcmTokens?: string[];
  preferredLanguage: string;
  notificationPreferences: Record<string, boolean>;
  createdAt: string;
  updatedAt: string;
}

export interface RoomRecord {
  roomId: string;
  ownerId: string;
  title: string;
  description: string;
  roomType: string;
  country: string;
  state: string;
  city: string;
  locality: string;
  address: string;
  latitude: number;
  longitude: number;
  photoUrls: string[];
  coverPhotoUrl: string;
  amenities: string[];
  maxGuests: number;
  bedCount: number;
  bathroomCount: number;
  pricePerNight: number;
  currency: string;
  cleaningFee: number;
  securityDeposit: number;
  checkInTime: string;
  checkOutTime: string;
  houseRules: string[];
  cancellationPolicyId: string;
  listingStatus: 'draft' | 'pending' | 'published' | 'rejected' | 'suspended';
  ownerVerificationStatus: 'unverified' | 'pending' | 'verified';
  averageRating: number;
  reviewCount: number;
  digitalPin: string;
  bookedDates: string[];
  createdAt: string;
  updatedAt: string;
}

export interface BookingRecord {
  bookingId: string;
  roomId: string;
  customerId: string;
  ownerId: string;
  roomTitleSnapshot: string;
  checkIn: string;
  checkOut: string;
  guestCount: number;
  nightCount: number;
  pricePerNightSnapshot: number;
  subtotal: number;
  fees: number;
  taxAmount: number;
  discountAmount: number;
  totalAmount: number;
  currency: string;
  bookingStatus: 'pendingPayment' | 'confirmed' | 'cancelled' | 'completed' | 'extended';
  paymentStatus: 'pending' | 'captured' | 'failed' | 'refunded';
  cancellationReason: string;
  accessPin: string;
  locationUrl: string;
  priorityExtensionEligible: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface PaymentOrder {
  orderId: string;
  amount: number;
  currency: string;
  provider: 'razorpay' | 'mock';
  bookingId: string;
  status: 'created' | 'paid' | 'failed';
}

export interface ExtensionOfferRecord {
  offerId: string;
  bookingId: string;
  roomId: string;
  customerId: string;
  ownerId: string;
  offeredAt: string;
  expiresAt: string;
  requestedCheckIn: string;
  requestedCheckOut: string;
  quotedAmount: number;
  status: 'offered' | 'accepted' | 'pendingPayment' | 'confirmed' | 'declined' | 'expired';
  reminderScheduledAt?: string;
  reminderSentAt?: string;
  createdAt: string;
  updatedAt: string;
}

