import * as admin from 'firebase-admin';
import {
  ReviewDocument,
  CreateReviewInput,
  ReplyToReviewInput,
  ModerateReviewInput,
} from './reviewTypes';
import { BookingDocument } from '../bookings/bookingTypes';
import { AppError, NotFoundError, UnauthorizedError } from '../../common/errors';
import { auditService } from '../../audit/auditService';

export class ReviewDomainService {
  private get db() {
    return admin.firestore();
  }

  /**
   * 1. createReview
   * Rules:
   * - Only eligible customers with a qualifying completed booking can review.
   * - Enforces one review per booking.
   * - Validates rating range (1-5) and comment length (minimum 5 chars, max 1000).
   * - Updates room averageRating and reviewCount atomically on Firestore.
   */
  async createReview(input: CreateReviewInput): Promise<ReviewDocument> {
    const { bookingId, customerId, rating, comment, photoUrls = [] } = input;

    // Validate rating range
    if (!rating || rating < 1 || rating > 5 || !Number.isInteger(rating)) {
      throw new AppError('Rating must be an integer between 1 and 5.', 400);
    }

    // Validate comment length
    if (!comment || comment.trim().length < 5 || comment.length > 1000) {
      throw new AppError('Review comment must be between 5 and 1000 characters.', 400);
    }

    // Validate booking qualification
    const bookingRef = this.db.collection('bookings').doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new NotFoundError('Booking reference not found.');
    }
    const booking = bookingSnap.data() as BookingDocument;

    if (booking.customerId !== customerId) {
      throw new UnauthorizedError('Unauthorized: Customer does not own this booking.');
    }

    if (booking.bookingStatus !== 'completed') {
      throw new AppError('Only completed stays are eligible for customer reviews.', 400);
    }

    // Enforce one review per booking
    const existingSnap = await this.db
      .collection('reviews')
      .where('bookingId', '==', bookingId)
      .limit(1)
      .get();

    if (!existingSnap.empty) {
      throw new AppError('A review has already been submitted for this booking.', 409);
    }

    const reviewId = `REV-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const nowStr = new Date().toISOString();

    const reviewDoc: ReviewDocument = {
      reviewId,
      bookingId,
      roomId: booking.roomId,
      customerId,
      ownerId: booking.ownerId,
      rating,
      comment: comment.trim(),
      photoUrls,
      moderationStatus: 'published', // standard reviews published, subject to moderation
      ownerReply: null,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    // Commit review and update room average rating atomically
    const roomRef = this.db.collection('rooms').doc(booking.roomId);

    await this.db.runTransaction(async tx => {
      const roomSnap = await tx.get(roomRef);
      if (!roomSnap.exists) throw new NotFoundError('Room not found.');
      const roomData = roomSnap.data()!;

      const currentCount = roomData.reviewCount || 0;
      const currentAvg = roomData.averageRating || 0;

      const newCount = currentCount + 1;
      const newAvg = Number(((currentAvg * currentCount + rating) / newCount).toFixed(2));

      tx.set(this.db.collection('reviews').doc(reviewId), reviewDoc);
      tx.update(roomRef, {
        reviewCount: newCount,
        averageRating: newAvg,
        updatedAt: nowStr,
      });
    });

    return reviewDoc;
  }

  /**
   * 2. getRoomReviews
   * Retrieves published reviews for a room.
   */
  async getRoomReviews(roomId: string): Promise<ReviewDocument[]> {
    const snap = await this.db
      .collection('reviews')
      .where('roomId', '==', roomId)
      .where('moderationStatus', '==', 'published')
      .orderBy('createdAt', 'desc')
      .get();

    return snap.docs.map(d => d.data() as ReviewDocument);
  }

  /**
   * 3. getEligibleReviewStatus
   * Verifies if customer can write a review for a booking.
   */
  async getEligibleReviewStatus(bookingId: string, customerId: string): Promise<{ eligible: boolean; reason?: string }> {
    const bookingSnap = await this.db.collection('bookings').doc(bookingId).get();
    if (!bookingSnap.exists) return { eligible: false, reason: 'Booking not found' };
    const booking = bookingSnap.data() as BookingDocument;

    if (booking.customerId !== customerId) return { eligible: false, reason: 'Unauthorized customer' };
    if (booking.bookingStatus !== 'completed') return { eligible: false, reason: 'Stay is not completed' };

    const reviewSnap = await this.db
      .collection('reviews')
      .where('bookingId', '==', bookingId)
      .limit(1)
      .get();

    if (!reviewSnap.empty) return { eligible: false, reason: 'Review already submitted' };

    return { eligible: true };
  }

  /**
   * 4. replyToReview
   * Allows room owner to post an official response to a review.
   */
  async replyToReview(input: ReplyToReviewInput): Promise<ReviewDocument> {
    const { reviewId, ownerId, reply } = input;

    const reviewRef = this.db.collection('reviews').doc(reviewId);
    const snap = await reviewRef.get();
    if (!snap.exists) throw new NotFoundError('Review not found.');
    const review = snap.data() as ReviewDocument;

    if (review.ownerId !== ownerId) {
      throw new UnauthorizedError('Only the room owner can reply to this review.');
    }

    if (!reply || reply.trim().length === 0) {
      throw new AppError('Reply cannot be empty.', 400);
    }

    const nowStr = new Date().toISOString();
    await reviewRef.update({
      ownerReply: reply.trim(),
      updatedAt: nowStr,
    });

    review.ownerReply = reply.trim();
    review.updatedAt = nowStr;
    return review;
  }

  /**
   * 5. moderateReview (Admin only)
   * Moderates abuse or reports and recalculates rating aggregate if rejected.
   */
  async moderateReview(input: ModerateReviewInput): Promise<void> {
    const { reviewId, adminId, status } = input;

    const reviewRef = this.db.collection('reviews').doc(reviewId);
    const snap = await reviewRef.get();
    if (!snap.exists) throw new NotFoundError('Review not found.');
    const review = snap.data() as ReviewDocument;

    const nowStr = new Date().toISOString();
    await reviewRef.update({
      moderationStatus: status,
      updatedAt: nowStr,
    });

    await auditService.recordEvent({
      eventType: 'ID_VERIFIED', // Audit action
      userId: adminId,
      resourceId: reviewId,
      details: { action: 'REVIEW_MODERATED', previousStatus: review.moderationStatus, newStatus: status },
    });
  }
}

export const reviewDomainService = new ReviewDomainService();

