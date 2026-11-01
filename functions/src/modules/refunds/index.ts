import { Router } from 'express';
import { cancellationRefundService } from './cancellationRefundService';
import { authenticate } from '../../middleware/authenticate';

export const refundsRouter = Router();

/**
 * POST /refunds/cancel-booking
 * Comprehensive endpoint to cancel a stay with policy evaluation and automated refund dispatch.
 */
refundsRouter.post('/cancel-booking', authenticate, async (req, res) => {
  try {
    const { bookingId, reason } = req.body;
    if (!bookingId) {
      return res.status(400).json({ success: false, message: 'bookingId is required.' });
    }
    const requestedByUid = (req as any).user.uid;
    const userRole = (req as any).user.role || 'customer';

    const result = await cancellationRefundService.cancelBooking({
      bookingId,
      requestedByUid,
      reason: reason || 'Customer requested stay cancellation',
      userRole,
    });

    return res.json({ success: true, result });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * GET /refunds/policies/:policyId
 * Retrieve configuration of a specific cancellation policy.
 */
refundsRouter.get('/policies/:policyId', async (req, res) => {
  try {
    const { policyId } = req.params;
    const policy = await cancellationRefundService.getPolicy(policyId);
    return res.json({ success: true, policy });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

