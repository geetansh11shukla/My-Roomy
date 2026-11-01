import { Router, Response } from 'express';
import { bookingDomainService } from './bookingDomainService';
import { authenticate, AuthenticatedRequest } from '../../middleware/authenticate';
import { validateRequest } from '../../middleware/validateRequest';
import { idempotency } from '../../middleware/idempotency';
import { authorize } from '../../middleware/authorize';

export const bookingsRouter = Router();

// Create 10-Minute Booking Hold
bookingsRouter.post(
  '/hold',
  authenticate,
  idempotency,
  validateRequest(['roomId', 'checkIn', 'checkOut', 'guestCount']),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const { roomId, checkIn, checkOut, guestCount } = req.body;
      const quote = await bookingDomainService.createBookingHold({
        customerUid: req.user!.uid, // Extracted from verified auth token
        roomId,
        checkIn,
        checkOut,
        guestCount: Number(guestCount),
        idempotencyKey: req.headers['idempotency-key'] as string,
      });
      return res.status(201).json({ success: true, data: quote });
    } catch (err: any) {
      return res.status(err.statusCode || 500).json({ error: err.message });
    }
  }
);

// Confirm Booking from Hold
bookingsRouter.post(
  '/confirm',
  authenticate,
  idempotency,
  validateRequest(['holdId', 'paymentId']),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const { holdId, paymentId } = req.body;
      const booking = await bookingDomainService.confirmBookingFromHold(
        holdId,
        paymentId,
        req.user!.uid
      );
      return res.status(201).json({ success: true, data: booking });
    } catch (err: any) {
      return res.status(err.statusCode || 500).json({ error: err.message });
    }
  }
);

// Customer Bookings
bookingsRouter.get('/my', authenticate, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const list = await bookingDomainService.getMyBookings(req.user!.uid);
    return res.json({ success: true, count: list.length, data: list });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// Single Booking Details
bookingsRouter.get('/:bookingId', authenticate, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const booking = await bookingDomainService.getBookingDetails(
      req.params.bookingId,
      req.user!.uid,
      req.user!.role
    );
    return res.json({ success: true, data: booking });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// Digital Booking Ticket & Access PIN
bookingsRouter.get('/:bookingId/ticket', authenticate, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const ticket = await bookingDomainService.getBookingTicket(req.params.bookingId, req.user!.uid);
    return res.json({ success: true, data: ticket });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// Owner Bookings
bookingsRouter.get('/owner/list', authenticate, authorize(['owner', 'admin']), async (req: AuthenticatedRequest, res: Response) => {
  try {
    const list = await bookingDomainService.getOwnerBookings(req.user!.uid);
    return res.json({ success: true, count: list.length, data: list });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// Cancel Booking
bookingsRouter.post('/:bookingId/cancel', authenticate, async (req: AuthenticatedRequest, res: Response) => {
  try {
    await bookingDomainService.cancelBooking(
      req.params.bookingId,
      req.user!.uid,
      req.body.reason || 'Guest requested cancellation'
    );
    return res.json({ success: true, message: 'Booking cancelled and refund initiated.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

