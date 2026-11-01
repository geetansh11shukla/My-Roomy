import { Router } from 'express';
import { supportDomainService } from './supportDomainService';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';

export const supportRouter = Router();

/**
 * 1. POST /support/tickets
 * Create new support ticket.
 */
supportRouter.post('/tickets', authenticate, async (req, res) => {
  try {
    const userId = (req as any).user.uid;
    const { bookingId, category, subject, description, attachmentUrls, priority } = req.body;

    const ticket = await supportDomainService.createSupportTicket({
      userId,
      bookingId,
      category,
      subject,
      description,
      attachmentUrls,
      priority,
    });

    return res.status(201).json({ success: true, ticket });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 2. GET /support/tickets
 * List user support tickets.
 */
supportRouter.get('/tickets', authenticate, async (req, res) => {
  try {
    const userId = (req as any).user.uid;
    const tickets = await supportDomainService.getMySupportTickets(userId);
    return res.json({ success: true, tickets });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 3. GET /support/tickets/:ticketId
 */
supportRouter.get('/tickets/:ticketId', authenticate, async (req, res) => {
  try {
    const viewerId = (req as any).user.uid;
    const userRole = (req as any).user.role || 'customer';
    const { ticketId } = req.params;

    const data = await supportDomainService.getSupportTicket(ticketId, viewerId, userRole);
    return res.json({ success: true, ...data });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 4. POST /support/tickets/:ticketId/reply
 */
supportRouter.post('/tickets/:ticketId/reply', authenticate, async (req, res) => {
  try {
    const senderId = (req as any).user.uid;
    const senderRole = (req as any).user.role || 'customer';
    const { ticketId } = req.params;
    const { message, attachmentUrls } = req.body;

    const reply = await supportDomainService.addSupportReply({
      ticketId,
      senderId,
      senderRole,
      message,
      attachmentUrls,
    });

    return res.status(201).json({ success: true, reply });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 5. POST /support/tickets/:ticketId/assign
 */
supportRouter.post('/tickets/:ticketId/assign', authenticate, authorize(['admin']), async (req, res) => {
  try {
    const adminId = (req as any).user.uid;
    const { ticketId } = req.params;

    await supportDomainService.assignSupportTicket(ticketId, adminId);
    return res.json({ success: true, message: 'Ticket assigned.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 6. POST /support/tickets/:ticketId/resolve
 */
supportRouter.post('/tickets/:ticketId/resolve', authenticate, authorize(['admin']), async (req, res) => {
  try {
    const adminId = (req as any).user.uid;
    const { ticketId } = req.params;
    const { resolution } = req.body;

    await supportDomainService.resolveSupportTicket(ticketId, adminId, resolution || 'Resolved by admin');
    return res.json({ success: true, message: 'Ticket resolved.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 7. POST /support/reports
 * Submit report regarding room or user abuse/safety.
 */
supportRouter.post('/reports', authenticate, async (req, res) => {
  try {
    const reporterId = (req as any).user.uid;
    const { targetType, targetId, reportCategory, description, evidenceReferences } = req.body;

    const report = await supportDomainService.createReport({
      reporterId,
      targetType,
      targetId,
      reportCategory,
      description,
      evidenceReferences,
    });

    return res.status(201).json({ success: true, report });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

