import * as admin from 'firebase-admin';
import {
  SupportTicketDocument,
  SupportReply,
  ReportDocument,
  CreateSupportTicketInput,
  CreateReportInput,
} from './supportTypes';
import { AppError, NotFoundError, UnauthorizedError } from '../../common/errors';
import { auditService } from '../../audit/auditService';

export class SupportDomainService {
  private get db() {
    return admin.firestore();
  }

  /**
   * 1. createSupportTicket
   */
  async createSupportTicket(input: CreateSupportTicketInput): Promise<SupportTicketDocument> {
    const { userId, bookingId = null, category, subject, description, attachmentUrls = [], priority = 'medium' } = input;

    if (!subject || subject.trim().length < 3) {
      throw new AppError('Ticket subject is required.', 400);
    }
    if (!description || description.trim().length < 10) {
      throw new AppError('Please provide a detailed description (minimum 10 characters).', 400);
    }

    const ticketId = `TCK-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const nowStr = new Date().toISOString();

    const ticketDoc: SupportTicketDocument = {
      ticketId,
      userId,
      bookingId: bookingId || null,
      category,
      subject: subject.trim(),
      description: description.trim(),
      attachmentUrls,
      priority,
      status: 'open',
      assignedAdminId: null,
      resolution: null,
      createdAt: nowStr,
      updatedAt: nowStr,
      resolvedAt: null,
    };

    await this.db.collection('support_tickets').doc(ticketId).set(ticketDoc);

    return ticketDoc;
  }

  /**
   * 2. getMySupportTickets
   */
  async getMySupportTickets(userId: string): Promise<SupportTicketDocument[]> {
    const snap = await this.db
      .collection('support_tickets')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .get();

    return snap.docs.map(d => d.data() as SupportTicketDocument);
  }

  /**
   * 3. getSupportTicket
   * Access restricted to ticket owner or platform admins.
   */
  async getSupportTicket(ticketId: string, viewerId: string, userRole: string): Promise<{ ticket: SupportTicketDocument; replies: SupportReply[] }> {
    const ticketRef = this.db.collection('support_tickets').doc(ticketId);
    const snap = await ticketRef.get();
    if (!snap.exists) throw new NotFoundError('Support ticket not found.');
    const ticket = snap.data() as SupportTicketDocument;

    if (ticket.userId !== viewerId && userRole !== 'admin') {
      throw new UnauthorizedError('Unauthorized ticket access.');
    }

    const repliesSnap = await ticketRef.collection('replies').orderBy('createdAt', 'asc').get();
    const replies = repliesSnap.docs.map(d => d.data() as SupportReply);

    return { ticket, replies };
  }

  /**
   * 4. addSupportReply
   */
  async addSupportReply(params: {
    ticketId: string;
    senderId: string;
    senderRole: 'customer' | 'owner' | 'admin';
    message: string;
    attachmentUrls?: string[];
  }): Promise<SupportReply> {
    const { ticketId, senderId, senderRole, message, attachmentUrls = [] } = params;

    const ticketRef = this.db.collection('support_tickets').doc(ticketId);
    const snap = await ticketRef.get();
    if (!snap.exists) throw new NotFoundError('Support ticket not found.');
    const ticket = snap.data() as SupportTicketDocument;

    if (ticket.userId !== senderId && senderRole !== 'admin') {
      throw new UnauthorizedError('Unauthorized reply attempt.');
    }

    const replyId = `REP-${Date.now()}`;
    const nowStr = new Date().toISOString();

    const replyDoc: SupportReply = {
      replyId,
      ticketId,
      senderId,
      senderRole,
      message: message.trim(),
      attachmentUrls,
      createdAt: nowStr,
    };

    await ticketRef.collection('replies').doc(replyId).set(replyDoc);

    // Update ticket status
    await ticketRef.update({
      status: senderRole === 'admin' ? 'waiting_user' : 'in_progress',
      updatedAt: nowStr,
    });

    return replyDoc;
  }

  /**
   * 5. assignSupportTicket (Admin only)
   */
  async assignSupportTicket(ticketId: string, adminId: string): Promise<void> {
    const ticketRef = this.db.collection('support_tickets').doc(ticketId);
    const snap = await ticketRef.get();
    if (!snap.exists) throw new NotFoundError('Ticket not found.');

    await ticketRef.update({
      assignedAdminId: adminId,
      status: 'in_progress',
      updatedAt: new Date().toISOString(),
    });
  }

  /**
   * 6. resolveSupportTicket (Admin only)
   */
  async resolveSupportTicket(ticketId: string, adminId: string, resolution: string): Promise<void> {
    const ticketRef = this.db.collection('support_tickets').doc(ticketId);
    const snap = await ticketRef.get();
    if (!snap.exists) throw new NotFoundError('Ticket not found.');

    const nowStr = new Date().toISOString();
    await ticketRef.update({
      status: 'resolved',
      assignedAdminId: adminId,
      resolution,
      resolvedAt: nowStr,
      updatedAt: nowStr,
    });
  }

  /**
   * 7. createReport
   * File a safety, harassment, or listing fraud report.
   */
  async createReport(input: CreateReportInput): Promise<ReportDocument> {
    const { reporterId, targetType, targetId, reportCategory, description, evidenceReferences = [] } = input;

    const reportId = `RPT-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const nowStr = new Date().toISOString();

    const reportDoc: ReportDocument = {
      reportId,
      reporterId,
      targetType,
      targetId,
      reportCategory,
      description: description.trim(),
      evidenceReferences,
      reviewStatus: 'pending',
      assignedReviewer: null,
      resolution: null,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    await this.db.collection('reports').doc(reportId).set(reportDoc);

    await auditService.recordEvent({
      eventType: 'ID_VERIFIED', // Audit logging action
      userId: reporterId,
      resourceId: reportId,
      details: { targetType, targetId, reportCategory },
    });

    return reportDoc;
  }
}

export const supportDomainService = new SupportDomainService();

