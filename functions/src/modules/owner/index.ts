import { Router } from 'express';
import { ownerDomainService } from './ownerDomainService';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';

export const ownerRouter = Router();

/**
 * 1. POST /owner/apply
 */
ownerRouter.post('/apply', authenticate, async (req, res) => {
  try {
    const userId = (req as any).user.uid;
    const { propertyAddress, taxIdentifierMasked, bankAccountNumberMasked, bankIfsc } = req.body;
    const result = await ownerDomainService.submitOwnerApplication({
      userId,
      propertyAddress,
      taxIdentifierMasked,
      bankAccountNumberMasked,
      bankIfsc,
    });
    return res.status(201).json({ success: true, result });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 2. GET /owner/dashboard
 */
ownerRouter.get('/dashboard', authenticate, authorize(['owner', 'admin']), async (req, res) => {
  try {
    const ownerId = (req as any).user.uid;
    const metrics = await ownerDomainService.getOwnerDashboard(ownerId);
    return res.json({ success: true, metrics });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 3. GET /owner/rooms
 */
ownerRouter.get('/rooms', authenticate, authorize(['owner', 'admin']), async (req, res) => {
  try {
    const ownerId = (req as any).user.uid;
    const rooms = await ownerDomainService.getOwnerRooms(ownerId);
    return res.json({ success: true, rooms });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 4. GET /owner/bookings
 */
ownerRouter.get('/bookings', authenticate, authorize(['owner', 'admin']), async (req, res) => {
  try {
    const ownerId = (req as any).user.uid;
    const bookings = await ownerDomainService.getOwnerBookings(ownerId);
    return res.json({ success: true, bookings });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 5. GET /owner/earnings
 */
ownerRouter.get('/earnings', authenticate, authorize(['owner', 'admin']), async (req, res) => {
  try {
    const ownerId = (req as any).user.uid;
    const earnings = await ownerDomainService.getOwnerEarnings(ownerId);
    return res.json({ success: true, earnings });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 6. GET /owner/payouts
 */
ownerRouter.get('/payouts', authenticate, authorize(['owner', 'admin']), async (req, res) => {
  try {
    const ownerId = (req as any).user.uid;
    const payouts = await ownerDomainService.getOwnerPayouts(ownerId);
    return res.json({ success: true, payouts });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 7. POST /owner/blocks
 */
ownerRouter.post('/blocks', authenticate, authorize(['owner', 'admin']), async (req, res) => {
  try {
    const ownerId = (req as any).user.uid;
    const { roomId, startDate, endDate, reason } = req.body;
    const block = await ownerDomainService.createRoomBlock({
      roomId,
      ownerId,
      startDate,
      endDate,
      reason: reason || 'owner_block',
    });
    return res.status(201).json({ success: true, block });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 8. DELETE /owner/blocks/:blockId
 */
ownerRouter.delete('/blocks/:blockId', authenticate, authorize(['owner', 'admin']), async (req, res) => {
  try {
    const ownerId = (req as any).user.uid;
    const { blockId } = req.params;
    await ownerDomainService.releaseRoomBlock(blockId, ownerId);
    return res.json({ success: true, message: 'Room block released.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 9. GET /owner/reviews
 */
ownerRouter.get('/reviews', authenticate, authorize(['owner', 'admin']), async (req, res) => {
  try {
    const ownerId = (req as any).user.uid;
    const reviews = await ownerDomainService.getOwnerReviews(ownerId);
    return res.json({ success: true, reviews });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

