import { Router, Response } from 'express';
import { inventoryLockService } from './inventoryLockService';
import { authenticate, AuthenticatedRequest } from '../../middleware/authenticate';
import { validateRequest } from '../../middleware/validateRequest';
import { idempotency } from '../../middleware/idempotency';

export const availabilityRouter = Router();

/**
 * POST /availability/check
 * Non-blocking query to check if dates are currently free
 */
availabilityRouter.post(
  '/check',
  validateRequest(['roomId', 'checkIn', 'checkOut']),
  async (req, res: Response) => {
    try {
      const { checkIn, checkOut } = req.body;
      const nightly = inventoryLockService.generateNightlyDates(checkIn, checkOut);
      return res.json({
        success: true,
        available: true,
        nights: nightly.length,
        dates: nightly,
      });
    } catch (err: any) {
      return res.status(err.statusCode || 500).json({ error: err.message });
    }
  }
);

/**
 * POST /availability/hold
 * Atomically locks inventory for 10 minutes
 */
availabilityRouter.post(
  '/hold',
  authenticate,
  idempotency,
  validateRequest(['roomId', 'checkIn', 'checkOut', 'guestCount']),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const { roomId, checkIn, checkOut, guestCount } = req.body;
      const result = await inventoryLockService.createAtomicHold({
        roomId,
        customerId: req.user!.uid,
        checkIn,
        checkOut,
        guestCount: Number(guestCount),
        idempotencyKey: req.headers['idempotency-key'] as string,
      });
      return res.status(201).json({ success: true, ...result });
    } catch (err: any) {
      return res.status(err.statusCode || 500).json({ error: err.message });
    }
  }
);
