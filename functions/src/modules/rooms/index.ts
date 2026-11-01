import { Router, Response } from 'express';
import { roomDomainService } from './roomDomainService';
import { authenticate, AuthenticatedRequest } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';

export const roomsRouter = Router();

// Public Room Discovery & Search
roomsRouter.get('/', async (req, res: Response) => {
  try {
    const { city, locality, roomType, minPrice, maxPrice, guestCount, minRating, sortBy, limit, offset } = req.query;
    const result = await roomDomainService.searchRooms({
      city: city as string,
      locality: locality as string,
      roomType: roomType as string,
      minPrice: minPrice ? Number(minPrice) : undefined,
      maxPrice: maxPrice ? Number(maxPrice) : undefined,
      guestCount: guestCount ? Number(guestCount) : undefined,
      minRating: minRating ? Number(minRating) : undefined,
      sortBy: sortBy as any,
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
    });
    return res.json({ success: true, count: result.total, data: result.rooms });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// Single Room Details (Public summary vs Authenticated details)
roomsRouter.get('/:roomId', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const room = await roomDomainService.getRoom(req.params.roomId, req.user?.uid, req.user?.role);
    return res.json({ success: true, data: room });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// Create Room Listing (Owner only, never trusting client owner IDs)
roomsRouter.post('/', authenticate, authorize(['owner', 'admin']), async (req: AuthenticatedRequest, res: Response) => {
  try {
    const room = await roomDomainService.createRoom(req.user!.uid, req.body);
    return res.status(201).json({ success: true, data: room });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// Update Room Listing (Owner only for own room)
roomsRouter.patch('/:roomId', authenticate, authorize(['owner', 'admin']), async (req: AuthenticatedRequest, res: Response) => {
  try {
    const room = await roomDomainService.updateRoom(req.params.roomId, req.user!.uid, req.body);
    return res.json({ success: true, data: room });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// Submit for Review
roomsRouter.post('/:roomId/submit', authenticate, authorize(['owner']), async (req: AuthenticatedRequest, res: Response) => {
  try {
    await roomDomainService.submitRoomForReview(req.params.roomId, req.user!.uid);
    return res.json({ success: true, message: 'Submitted for administrative review.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

// Admin Approval Actions
roomsRouter.post('/:roomId/approve', authenticate, authorize(['admin']), async (req, res: Response) => {
  try {
    await roomDomainService.approveRoom(req.params.roomId);
    return res.json({ success: true, message: 'Listing approved and published.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

roomsRouter.post('/:roomId/reject', authenticate, authorize(['admin']), async (req, res: Response) => {
  try {
    await roomDomainService.rejectRoom(req.params.roomId, req.body.reason || 'Did not meet listing standards.');
    return res.json({ success: true, message: 'Listing rejected.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

roomsRouter.post('/:roomId/suspend', authenticate, authorize(['admin']), async (req, res: Response) => {
  try {
    await roomDomainService.suspendRoom(req.params.roomId, req.body.reason || 'Suspended for policy review.');
    return res.json({ success: true, message: 'Listing suspended.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});
