export type ReviewModerationStatus = 'pending' | 'published' | 'flagged' | 'rejected';

export interface ReviewDocument {
  reviewId: string;
  bookingId: string;
  roomId: string;
  customerId: string;
  ownerId: string;
  rating: number; // Integer between 1 and 5
  comment: string;
  photoUrls: string[];
  moderationStatus: ReviewModerationStatus;
  ownerReply: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CreateReviewInput {
  bookingId: string;
  customerId: string;
  rating: number;
  comment: string;
  photoUrls?: string[];
}

export interface ReplyToReviewInput {
  reviewId: string;
  ownerId: string;
  reply: string;
}

export interface ModerateReviewInput {
  reviewId: string;
  adminId: string;
  status: ReviewModerationStatus;
}

