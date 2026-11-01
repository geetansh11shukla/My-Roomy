import { Router } from 'express';
import { extensionDomainService } from './extensionDomainService';
import { authenticate } from '../../middleware/authenticate';

export const extensionsRouter = Router();

/**
 * 1. GET /extensions
 * List active eligible extension offers for the customer.
 */
extensionsRouter.get('/', authenticate, async (req, res) => {
  try {
    const customerId = (req as any).user.uid;
    const offers = await extensionDomainService.getEligibleExtensionOffers(customerId);
    return res.json({ success: true, offers });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 2. POST /extensions/create
 * Internal / trigger to issue an extension offer for a confirmed booking.
 */
extensionsRouter.post('/create', authenticate, async (req, res) => {
  try {
    const { bookingId, extensionNights, discountPercentage } = req.body;
    const offer = await extensionDomainService.createExtensionOffer({
      bookingId,
      extensionNights,
      discountPercentage,
    });
    return res.status(201).json({ success: true, offer });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 3. POST /extensions/:offerId/accept
 */
extensionsRouter.post('/:offerId/accept', authenticate, async (req, res) => {
  try {
    const customerId = (req as any).user.uid;
    const { offerId } = req.params;
    const offer = await extensionDomainService.acceptExtensionOffer(offerId, customerId);
    return res.json({ success: true, offer });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 4. POST /extensions/:offerId/decline
 */
extensionsRouter.post('/:offerId/decline', authenticate, async (req, res) => {
  try {
    const customerId = (req as any).user.uid;
    const { offerId } = req.params;
    await extensionDomainService.declineExtensionOffer(offerId, customerId);
    return res.json({ success: true, message: 'Extension offer declined.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 5. POST /extensions/:offerId/dates
 */
extensionsRouter.post('/:offerId/dates', authenticate, async (req, res) => {
  try {
    const customerId = (req as any).user.uid;
    const { offerId } = req.params;
    const { newRequestedCheckOut } = req.body;
    const updatedOffer = await extensionDomainService.requestExtensionDates({
      offerId,
      customerId,
      newRequestedCheckOut,
    });
    return res.json({ success: true, offer: updatedOffer });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 6. POST /extensions/:offerId/order
 */
extensionsRouter.post('/:offerId/order', authenticate, async (req, res) => {
  try {
    const customerId = (req as any).user.uid;
    const { offerId } = req.params;
    const order = await extensionDomainService.createExtensionPaymentOrder(offerId, customerId);
    return res.json({ success: true, order });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 7. POST /extensions/:offerId/confirm
 */
extensionsRouter.post('/:offerId/confirm', authenticate, async (req, res) => {
  try {
    const customerId = (req as any).user.uid;
    const { offerId } = req.params;
    const { paymentId } = req.body;
    const updatedBooking = await extensionDomainService.confirmExtension({
      offerId,
      customerId,
      paymentId,
    });
    return res.json({ success: true, booking: updatedBooking });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});
