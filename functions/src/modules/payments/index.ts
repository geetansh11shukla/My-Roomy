import { Router } from 'express';
import { paymentDomainService } from './paymentDomainService';
import { authenticate } from '../../middleware/authenticate';

export const paymentsRouter = Router();

/**
 * 1. POST /payments/order
 * Creates payment order for an active hold.
 */
paymentsRouter.post('/order', authenticate, async (req, res) => {
  try {
    const { holdId } = req.body;
    if (!holdId) {
      return res.status(400).json({ success: false, message: 'holdId is required.' });
    }
    const customerUid = (req as any).user.uid;
    const order = await paymentDomainService.createPaymentOrder(holdId, customerUid);
    return res.status(201).json({ success: true, order });
  } catch (error: any) {
    return res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
});

/**
 * 2. POST /payments/verify
 * Cryptographically verifies Razorpay checkout payment and confirms booking.
 */
paymentsRouter.post('/verify', authenticate, async (req, res) => {
  try {
    const { paymentId, providerOrderId, providerPaymentId, signature } = req.body;
    if (!paymentId || !providerOrderId || !providerPaymentId || !signature) {
      return res.status(400).json({
        success: false,
        message: 'paymentId, providerOrderId, providerPaymentId, and signature are required.',
      });
    }

    const customerUid = (req as any).user.uid;
    const result = await paymentDomainService.verifyPayment({
      paymentId,
      providerOrderId,
      providerPaymentId,
      signature,
      customerUid,
    });

    return res.json({ success: result.success, bookingId: result.bookingId });
  } catch (error: any) {
    return res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
});

/**
 * 3. POST /payments/webhook
 * Razorpay webhook endpoint with HMAC signature check and event deduplication.
 */
paymentsRouter.post('/webhook', async (req, res) => {
  try {
    const signature = req.headers['x-razorpay-signature'] as string;
    const eventId = (req.headers['x-razorpay-event-id'] as string) || `evt_${Date.now()}`;
    const rawBody = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);

    const result = await paymentDomainService.paymentWebhook(rawBody, signature, eventId);
    return res.json(result);
  } catch (error: any) {
    return res.status(error.statusCode || 400).json({ success: false, message: error.message });
  }
});

/**
 * 4. GET /payments/:paymentId
 * Retrieves payment status for authorized user.
 */
paymentsRouter.get('/:paymentId', authenticate, async (req, res) => {
  try {
    const { paymentId } = req.params;
    const viewerUid = (req as any).user.uid;
    const userRole = (req as any).user.role || 'customer';

    const payment = await paymentDomainService.getPaymentStatus(paymentId, viewerUid, userRole);
    return res.json({ success: true, payment });
  } catch (error: any) {
    return res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
});

/**
 * 5. POST /payments/:paymentId/refund
 * Initiates refund for a payment.
 */
paymentsRouter.post('/:paymentId/refund', authenticate, async (req, res) => {
  try {
    const { paymentId } = req.params;
    const { reason, amountPaise } = req.body;
    const requestedByUid = (req as any).user.uid;

    const refund = await paymentDomainService.initiateRefund({
      paymentId,
      reason: reason || 'Customer requested refund',
      requestedByUid,
      amountPaise,
    });

    return res.json({ success: true, refund });
  } catch (error: any) {
    return res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
});

/**
 * 6. GET /payments/refunds/:refundId
 * Retrieves refund status.
 */
paymentsRouter.get('/refunds/:refundId', authenticate, async (req, res) => {
  try {
    const { refundId } = req.params;
    const refund = await paymentDomainService.getRefundStatus(refundId);
    return res.json({ success: true, refund });
  } catch (error: any) {
    return res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
});

/**
 * 7. POST /payments/reconcile
 * Trigger payment reconciliation routine.
 */
paymentsRouter.post('/reconcile', authenticate, async (req, res) => {
  try {
    const result = await paymentDomainService.reconcilePendingPayments();
    return res.json({ success: true, result });
  } catch (error: any) {
    return res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
});
