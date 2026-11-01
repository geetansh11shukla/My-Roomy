import * as admin from 'firebase-admin';
import {
  AdminDashboardMetrics,
  AdminUserQueryFilters,
  AdminRoomApprovalAction,
  AdminRefundReviewInput,
  AppConfigDocument,
} from './adminTypes';
import { UserProfileDocument } from '../users/userTypes';
import { RoomDocument } from '../rooms/roomTypes';
import { VerificationCaseDocument } from '../verification/verificationTypes';
import { SupportTicketDocument } from '../support/supportTypes';
import { RefundDocument } from '../refunds/refundTypes';
import { PaymentDocument } from '../payments/paymentTypes';
import { auditService } from '../../audit/auditService';
import { NotFoundError } from '../../common/errors';

export class AdminDomainService {
  private get db() {
    return admin.firestore();
  }

  /**
   * 1. getAdminDashboard
   * Computes authoritative global platform metrics.
   */
  async getAdminDashboard(): Promise<AdminDashboardMetrics> {
    const [
      usersSnap,
      roomsSnap,
      bookingsSnap,
      paymentsSnap,
      refundsSnap,
      verifSnap,
      supportSnap,
      extensionsSnap,
    ] = await Promise.all([
      this.db.collection('users').get(),
      this.db.collection('rooms').get(),
      this.db.collection('bookings').get(),
      this.db.collection('payments').get(),
      this.db.collection('refunds').get(),
      this.db.collection('verification_cases').where('status', '==', 'manual_review').get(),
      this.db.collection('support_tickets').where('status', 'in', ['open', 'in_progress']).get(),
      this.db.collection('extension_offers').get(),
    ]);

    let registeredCustomers = 0;
    let registeredOwners = 0;
    usersSnap.docs.forEach(doc => {
      const u = doc.data() as UserProfileDocument;
      if (u.role === 'customer') registeredCustomers++;
      if (u.role === 'owner') registeredOwners++;
    });

    let activeListings = 0;
    let pendingRoomApprovals = 0;
    roomsSnap.docs.forEach(doc => {
      const r = doc.data() as RoomDocument;
      if (r.listingStatus === 'published') activeListings++;
      if (r.listingStatus === 'pending_review') pendingRoomApprovals++;
    });

    let confirmedBookings = 0;
    let cancelledBookings = 0;
    bookingsSnap.docs.forEach(doc => {
      const b = doc.data();
      if (b.bookingStatus === 'confirmed' || b.bookingStatus === 'completed') confirmedBookings++;
      if (b.bookingStatus === 'cancelled') cancelledBookings++;
    });

    let grossPaymentVolumePaise = 0;
    let reconciliationDiscrepanciesCount = 0;
    paymentsSnap.docs.forEach(doc => {
      const p = doc.data() as PaymentDocument;
      if (p.status === 'captured') grossPaymentVolumePaise += p.amount || 0;
      if (p.status === 'reconciliation_required') reconciliationDiscrepanciesCount++;
    });

    let pendingRefundsCount = 0;
    refundsSnap.docs.forEach(doc => {
      const r = doc.data() as RefundDocument;
      if (r.status === 'pending' || r.status === 'processing' || r.status === 'manual_review') {
        pendingRefundsCount++;
      }
    });

    let activeExtensionOffersCount = 0;
    let expiredExtensionOffersCount = 0;
    const now = new Date();
    extensionsSnap.docs.forEach(doc => {
      const e = doc.data();
      if (e.status === 'offered' && new Date(e.expiresAt) > now) activeExtensionOffersCount++;
      if (e.status === 'expired' || (e.status === 'offered' && new Date(e.expiresAt) <= now)) {
        expiredExtensionOffersCount++;
      }
    });

    return {
      registeredCustomers,
      registeredOwners,
      activeListings,
      pendingRoomApprovals,
      confirmedBookings,
      cancelledBookings,
      grossPaymentVolumePaise,
      reconciliationDiscrepanciesCount,
      pendingRefundsCount,
      pendingIdentityReviewsCount: verifSnap.size,
      openSupportTicketsCount: supportSnap.size,
      activeExtensionOffersCount,
      expiredExtensionOffersCount,
      computedAt: now.toISOString(),
    };
  }

  /**
   * 2. getUsers
   */
  async getUsers(filters: AdminUserQueryFilters): Promise<UserProfileDocument[]> {
    let query: admin.firestore.Query = this.db.collection('users');
    if (filters.role) query = query.where('role', '==', filters.role);
    if (filters.accountStatus) query = query.where('accountStatus', '==', filters.accountStatus);
    query = query.limit(filters.limit || 50);

    const snap = await query.get();
    return snap.docs.map(d => d.data() as UserProfileDocument);
  }

  /**
   * 3. suspendUser
   */
  async suspendUser(targetUserId: string, adminId: string, reason: string): Promise<void> {
    const userRef = this.db.collection('users').doc(targetUserId);
    const snap = await userRef.get();
    if (!snap.exists) throw new NotFoundError('Target user not found.');

    const nowStr = new Date().toISOString();
    await userRef.update({
      accountStatus: 'suspended',
      updatedAt: nowStr,
    });

    await auditService.recordEvent({
      eventType: 'ID_VERIFIED', // Audit security event
      userId: adminId,
      resourceId: targetUserId,
      details: { action: 'USER_SUSPENDED', targetUserId, reason },
    });
  }

  /**
   * 4. restoreUser
   */
  async restoreUser(targetUserId: string, adminId: string): Promise<void> {
    const userRef = this.db.collection('users').doc(targetUserId);
    const snap = await userRef.get();
    if (!snap.exists) throw new NotFoundError('Target user not found.');

    const nowStr = new Date().toISOString();
    await userRef.update({
      accountStatus: 'active',
      updatedAt: nowStr,
    });

    await auditService.recordEvent({
      eventType: 'ID_VERIFIED',
      userId: adminId,
      resourceId: targetUserId,
      details: { action: 'USER_RESTORED', targetUserId },
    });
  }

  /**
   * 5. getPendingRoomApprovals
   */
  async getPendingRoomApprovals(): Promise<RoomDocument[]> {
    const snap = await this.db
      .collection('rooms')
      .where('listingStatus', '==', 'pending_review')
      .get();
    return snap.docs.map(d => d.data() as RoomDocument);
  }

  /**
   * 6. reviewRoomApproval (Approve / Reject)
   */
  async reviewRoomApproval(input: AdminRoomApprovalAction): Promise<void> {
    const { roomId, adminId, action, rejectionReason } = input;
    const roomRef = this.db.collection('rooms').doc(roomId);
    const snap = await roomRef.get();
    if (!snap.exists) throw new NotFoundError('Room not found.');

    const newStatus = action === 'approve' ? 'published' : 'rejected';
    const nowStr = new Date().toISOString();

    await roomRef.update({
      listingStatus: newStatus,
      updatedAt: nowStr,
    });

    await auditService.recordEvent({
      eventType: 'ROOM_CREATED',
      userId: adminId,
      resourceId: roomId,
      details: { action: `ROOM_${action.toUpperCase()}`, roomId, rejectionReason },
    });
  }

  /**
   * 7. getVerificationQueue
   */
  async getVerificationQueue(): Promise<VerificationCaseDocument[]> {
    const snap = await this.db
      .collection('verification_cases')
      .where('status', 'in', ['pending', 'manual_review'])
      .get();
    return snap.docs.map(d => d.data() as VerificationCaseDocument);
  }

  /**
   * 8. getBookingDisputes
   */
  async getBookingDisputes(): Promise<any[]> {
    const snap = await this.db
      .collection('reports')
      .where('targetType', '==', 'room')
      .where('reviewStatus', 'in', ['pending', 'under_review'])
      .get();
    return snap.docs.map(d => d.data());
  }

  /**
   * 9. reviewRefund
   */
  async reviewRefund(input: AdminRefundReviewInput): Promise<void> {
    const { refundId, adminId, action, notes } = input;
    const ref = this.db.collection('refunds').doc(refundId);
    const snap = await ref.get();
    if (!snap.exists) throw new NotFoundError('Refund record not found.');

    const newStatus = action === 'approve' ? 'succeeded' : 'failed';
    const nowStr = new Date().toISOString();

    await ref.update({
      status: newStatus,
      processedAt: newStatus === 'succeeded' ? nowStr : null,
      failureReason: action === 'reject' ? (notes || 'Rejected by administrator') : null,
      updatedAt: nowStr,
    });

    await auditService.recordEvent({
      eventType: 'REFUND_PROCESSED',
      userId: adminId,
      resourceId: refundId,
      details: { action, notes },
    });
  }

  /**
   * 10. getPaymentReconciliationQueue
   */
  async getPaymentReconciliationQueue(): Promise<PaymentDocument[]> {
    const snap = await this.db
      .collection('payments')
      .where('status', 'in', ['reconciliation_required', 'failed'])
      .get();
    return snap.docs.map(d => d.data() as PaymentDocument);
  }

  /**
   * 11. getSupportQueue
   */
  async getSupportQueue(): Promise<SupportTicketDocument[]> {
    const snap = await this.db
      .collection('support_tickets')
      .where('status', 'in', ['open', 'in_progress'])
      .orderBy('createdAt', 'asc')
      .get();
    return snap.docs.map(d => d.data() as SupportTicketDocument);
  }

  /**
   * 12. reviewReport
   */
  async reviewReport(reportId: string, adminId: string, action: 'action_taken' | 'dismissed', resolution: string): Promise<void> {
    const repRef = this.db.collection('reports').doc(reportId);
    const snap = await repRef.get();
    if (!snap.exists) throw new NotFoundError('Report not found.');

    const nowStr = new Date().toISOString();
    await repRef.update({
      reviewStatus: action,
      assignedReviewer: adminId,
      resolution,
      updatedAt: nowStr,
    });
  }

  /**
   * 13. getAuditLogs
   */
  async getAuditLogs(limit: number = 100): Promise<any[]> {
    const snap = await this.db
      .collection('audit_logs')
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .get();
    return snap.docs.map(d => d.data());
  }

  /**
   * 14. updateApprovedAppConfiguration
   */
  async updateApprovedAppConfiguration(adminId: string, patch: Partial<AppConfigDocument>): Promise<AppConfigDocument> {
    const configRef = this.db.collection('app_config').doc('global');
    const snap = await configRef.get();

    const nowStr = new Date().toISOString();
    const existing = snap.exists
      ? (snap.data() as AppConfigDocument)
      : {
          configId: 'global',
          platformFeePercentage: 0, // 0% brokerage promise
          defaultGstPercentage: 5,
          minBookingAdvanceHours: 2,
          defaultCancellationPolicyId: 'flexible',
          extensionOfferDiscountPercent: 15,
          maintenanceMode: false,
          updatedBy: adminId,
          updatedAt: nowStr,
        };

    const updatedConfig: AppConfigDocument = {
      ...existing,
      ...patch,
      configId: 'global',
      updatedBy: adminId,
      updatedAt: nowStr,
    };

    await configRef.set(updatedConfig);

    await auditService.recordEvent({
      eventType: 'ID_VERIFIED',
      userId: adminId,
      resourceId: 'global_app_config',
      details: { action: 'APP_CONFIG_UPDATED', patch },
    });

    return updatedConfig;
  }
}

export const adminDomainService = new AdminDomainService();
