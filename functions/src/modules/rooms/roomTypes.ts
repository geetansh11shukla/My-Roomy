export type ListingStatus = 'draft' | 'pending_review' | 'published' | 'rejected' | 'suspended';

export interface RoomDocument {
  roomId: string;
  ownerId: string;
  title: string;
  description: string;
  roomType: string;
  country: string;
  state: string;
  city: string;
  locality: string;
  address: string; // Restricted to confirmed guests and owner/admin
  latitude: number;
  longitude: number;
  photoUrls: string[];
  coverPhotoUrl: string;
  amenities: string[];
  maxGuests: number;
  bedCount: number;
  bathroomCount: number;
  pricePerNightPaise: number; // Integer minor currency units (paise)
  currency: string;
  cleaningFeePaise: number; // Integer minor currency units (paise)
  securityDepositPaise: number; // Integer minor currency units (paise)
  checkInTime: string;
  checkOutTime: string;
  houseRules: string[];
  cancellationPolicyId: string;
  listingStatus: ListingStatus;
  ownerVerificationStatus: string;
  averageRating: number;
  reviewCount: number;
  digitalPin: string;
  bookedDates: string[];
  createdAt: string;
  updatedAt: string;
}

export type PublicRoomSummary = Omit<RoomDocument, 'address' | 'digitalPin' | 'ownerId'> & {
  pricePerNight: number; // Converted to rupees for frontend display
};

