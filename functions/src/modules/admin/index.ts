import { Router } from 'express';
import { adminDomainService } from './adminDomainService';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';

export const adminRouter = Router();

// Secure all admin endpoints server-side with strict admin role enforcement
adminRouter.use(authenticate, authorize(['admin']));

/**
 * 1. GET /admin/dashboard
 */
adminRouter.get('/dashboard', async (req, res) => {
  try {
    const metrics = await adminDomainService.getAdminDashboard();
    return res.json({ success: true, metrics });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 2. GET /admin/users
 */
adminRouter.get('/users', async (req, res) => {
  try {
    const { role, accountStatus, limit } = req.query;
    const users = await adminDomainService.getUsers({
      role: role as any,
      accountStatus: accountStatus as any,
      limit: limit ? parseInt(limit as string, 10) : undefined,
    });
    return res.json({ success: true, users });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 3. POST /admin/users/:userId/suspend
 */
adminRouter.post('/users/:userId/suspend', async (req, res) => {
  try {
    const adminId = (req as any).user.uid;
    const { userId } = req.params;
    const { reason } = req.body;
    await adminDomainService.suspendUser(userId, adminId, reason || 'Administrative suspension');
    return res.json({ success: true, message: 'User suspended.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 4. POST /admin/users/:userId/restore
 */
adminRouter.post('/users/:userId/restore', async (req, res) => {
  try {
    const adminId = (req as any).user.uid;
    const { userId } = req.params;
    await adminDomainService.restoreUser(userId, adminId);
    return res.json({ success: true, message: 'User restored.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 5. GET /admin/rooms/pending
 */
adminRouter.get('/rooms/pending', async (req, res) => {
  try {
    const rooms = await adminDomainService.getPendingRoomApprovals();
    return res.json({ success: true, rooms });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 6. POST /admin/rooms/:roomId/review
 */
adminRouter.post('/rooms/:roomId/review', async (req, res) => {
  try {
    const adminId = (req as any).user.uid;
    const { roomId } = req.params;
    const { action, rejectionReason } = req.body;
    await adminDomainService.reviewRoomApproval({ roomId, adminId, action, rejectionReason });
    return res.json({ success: true, message: `Room ${action}ed.` });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 7. GET /admin/verification-queue
 */
adminRouter.get('/verification-queue', async (req, res) => {
  try {
    const queue = await adminDomainService.getVerificationQueue();
    return res.json({ success: true, queue });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 8. GET /admin/disputes
 */
adminRouter.get('/disputes', async (req, res) => {
  try {
    const disputes = await adminDomainService.getBookingDisputes();
    return res.json({ success: true, disputes });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 9. POST /admin/refunds/:refundId/review
 */
adminRouter.post('/refunds/:refundId/review', async (req, res) => {
  try {
    const adminId = (req as any).user.uid;
    const { refundId } = req.params;
    const { action, notes } = req.body;
    await adminDomainService.reviewRefund({ refundId, adminId, action, notes });
    return res.json({ success: true, message: `Refund review complete: ${action}.` });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 10. GET /admin/reconciliation-queue
 */
adminRouter.get('/reconciliation-queue', async (req, res) => {
  try {
    const discrepancies = await adminDomainService.getPaymentReconciliationQueue();
    return res.json({ success: true, discrepancies });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 11. GET /admin/support-queue
 */
adminRouter.get('/support-queue', async (req, res) => {
  try {
    const tickets = await adminDomainService.getSupportQueue();
    return res.json({ success: true, tickets });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 12. POST /admin/reports/:reportId/review
 */
adminRouter.post('/reports/:reportId/review', async (req, res) => {
  try {
    const adminId = (req as any).user.uid;
    const { reportId } = req.params;
    const { action, resolution } = req.body;
    await adminDomainService.reviewReport(reportId, adminId, action, resolution);
    return res.json({ success: true, message: 'Report reviewed.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 13. GET /admin/audit-logs
 */
adminRouter.get('/audit-logs', async (req, res) => {
  try {
    const logs = await adminDomainService.getAuditLogs();
    return res.json({ success: true, logs });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 14. PUT /admin/config
 */
adminRouter.put('/config', async (req, res) => {
  try {
    const adminId = (req as any).user.uid;
    const updated = await adminDomainService.updateApprovedAppConfiguration(adminId, req.body);
    return res.json({ success: true, config: updated });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

