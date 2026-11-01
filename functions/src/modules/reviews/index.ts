import { Router } from 'express';
import { reviewDomainService } from './reviewDomainService';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';

export const reviewsRouter = Router();

/**
 * 1. POST /reviews
 * Customer creates a review for a completed stay.
 */
reviewsRouter.post('/', authenticate, async (req, res) => {
  try {
    const customerId = (req as any).user.uid;
    const { bookingId, rating, comment, photoUrls } = req.body;

    const review = await reviewDomainService.createReview({
      bookingId,
      customerId,
      rating,
      comment,
      photoUrls,
    });

    return res.status(201).json({ success: true, review });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 2. GET /reviews/room/:roomId
 * Public room reviews list.
 */
reviewsRouter.get('/room/:roomId', async (req, res) => {
  try {
    const { roomId } = req.params;
    const reviews = await reviewDomainService.getRoomReviews(roomId);
    return res.json({ success: true, reviews });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 3. GET /reviews/eligibility/:bookingId
 * Check if the customer can review this booking.
 */
reviewsRouter.get('/eligibility/:bookingId', authenticate, async (req, res) => {
  try {
    const customerId = (req as any).user.uid;
    const { bookingId } = req.params;
    const result = await reviewDomainService.getEligibleReviewStatus(bookingId, customerId);
    return res.json({ success: true, ...result });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 4. POST /reviews/:reviewId/reply
 * Room owner posts official response to a review.
 */
reviewsRouter.post('/:reviewId/reply', authenticate, authorize(['owner', 'admin']), async (req, res) => {
  try {
    const ownerId = (req as any).user.uid;
    const { reviewId } = req.params;
    const { reply } = req.body;

    const review = await reviewDomainService.replyToReview({
      reviewId,
      ownerId,
      reply,
    });

    return res.json({ success: true, review });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 5. POST /reviews/:reviewId/moderate
 * Admin moderates a review.
 */
reviewsRouter.post('/:reviewId/moderate', authenticate, authorize(['admin']), async (req, res) => {
  try {
    const adminId = (req as any).user.uid;
    const { reviewId } = req.params;
    const { status } = req.body;

    await reviewDomainService.moderateReview({
      reviewId,
      adminId,
      status,
    });

    return res.json({ success: true, message: 'Review moderation updated.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

