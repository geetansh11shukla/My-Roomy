import * as admin from 'firebase-admin';
import {
  CancellationPolicyDocument,
  RefundDocument,
  CancelBookingInput,
  CancelBookingResult,
  RefundStatus,
} from './refundTypes';
import { BookingDocument } from '../bookings/bookingTypes';
import { BookingStateMachine } from '../bookings/bookingStateMachine';
import { paymentGateway } from '../../services/paymentService';
import { inventoryLockService } from '../availability/inventoryLockService';
import { whatsAppMessenger } from '../../services/whatsappService';
import { auditService } from '../../audit/auditService';
import { NotFoundError, UnauthorizedError } from '../../common/errors';

export class CancellationRefundService {
  private get db() {
    return admin.firestore();
  }

  /**
   * Seed / Get Standard Cancellation Policies
   */
  async getPolicy(policyId: string): Promise<CancellationPolicyDocument> {
    const doc = await this.db.collection('cancellation_policies').doc(policyId).get();
    if (doc.exists) {
      return doc.data() as CancellationPolicyDocument;
    }

    // Default flexible fallback policy if not yet written to Firestore
    return {
      policyId,
      name: policyId === 'strict' ? 'Strict Policy' : 'Flexible 24-Hour Policy',
      description: 'Full refund if cancelled at least 24 hours prior to check-in.',
      rules:
        policyId === 'strict'
          ? [
              { hoursBeforeCheckIn: 72, refundPercentage: 50 },
              { hoursBeforeCheckIn: 0, refundPercentage: 0 },
            ]
          : [
              { hoursBeforeCheckIn: 24, refundPercentage: 100 },
              { hoursBeforeCheckIn: 12, refundPercentage: 50 },
              { hoursBeforeCheckIn: 0, refundPercentage: 0 },
            ],
      effectiveFrom: new Date('2026-01-01').toISOString(),
      effectiveTo: null,
      active: true,
    };
  }

  /**
   * Calculate refund amount based on saved policy snapshot and hours remaining before check-in.
   */
  calculateRefundEligibility(
    booking: BookingDocument,
    policy: CancellationPolicyDocument,
    cancellationTime: Date = new Date()
  ): { refundAmountPaise: number; refundPercentage: number } {
    const checkInDate = new Date(booking.checkIn);
    const diffHours = (checkInDate.getTime() - cancellationTime.getTime()) / (1000 * 60 * 60);

    // Sort rules descending by hoursBeforeCheckIn
    const sortedRules = [...policy.rules].sort((a, b) => b.hoursBeforeCheckIn - a.hoursBeforeCheckIn);

    let applicablePercentage = 0;
    let deductFlatFeePaise = 0;

    for (const rule of sortedRules) {
      if (diffHours >= rule.hoursBeforeCheckIn) {
        applicablePercentage = rule.refundPercentage;
        deductFlatFeePaise = rule.deductFlatFeePaise || 0;
        break;
      }
    }

    const calculatedRefund = Math.floor((booking.totalAmountPaise * applicablePercentage) / 100);
    const finalRefund = Math.max(0, calculatedRefund - deductFlatFeePaise);

    return {
      refundAmountPaise: finalRefund,
      refundPercentage: applicablePercentage,
    };
  }

  /**
   * cancelBooking
   * Orchestrates policy snapshot evaluation, payment provider refund, status transitions, inventory release, and notifications.
   */
  async cancelBooking(input: CancelBookingInput): Promise<CancelBookingResult> {
    const { bookingId, requestedByUid, reason, userRole } = input;

    // 1. Fetch booking
    const bookingRef = this.db.collection('bookings').doc(bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) {
      throw new NotFoundError('Booking reference not found.');
    }
    const booking = bookingSnap.data() as BookingDocument;

    // 2. Permission check: Customer, Room Owner, or Admin
    const isCustomer = booking.customerId === requestedByUid;
    const isOwner = booking.ownerId === requestedByUid;
    const isAdmin = userRole === 'admin';

    if (!isCustomer && !isOwner && !isAdmin) {
      throw new UnauthorizedError('Unauthorized cancellation attempt.');
    }

    // 3. Verify booking is in a cancellable state
    BookingStateMachine.assertTransition(booking.bookingStatus, 'cancelled');

    // 4. Fetch the policy snapshot that applied to this booking
    const policy = await this.getPolicy(booking.cancellationPolicySnapshot || 'flexible');

    // 5. Calculate refund eligibility
    const now = new Date();
    const nowStr = now.toISOString();
    const { refundAmountPaise } = this.calculateRefundEligibility(booking, policy, now);

    let refundStatus: RefundStatus | 'no_refund' = 'no_refund';
    let refundId: string | null = null;
    let providerRefundId: string | null = null;
    let refundFailureReason: string | null = null;

    // 6. If refund eligible and payment was captured, create and execute refund
    if (refundAmountPaise > 0 && booking.paymentId) {
      refundId = `RFND-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
      refundStatus = 'pending';

      const paymentSnap = await this.db.collection('payments').doc(booking.paymentId).get();
      const paymentData = paymentSnap.exists ? paymentSnap.data() : null;
      const providerPaymentId = paymentData?.providerPaymentId || null;

      if (providerPaymentId) {
        try {
          refundStatus = 'processing';
          const refundRes = await paymentGateway.initiateRefund(providerPaymentId, refundAmountPaise, {
            bookingId,
            refundId,
            reason,
            requestedBy: requestedByUid,
          });

          providerRefundId = refundRes.id;
          refundStatus = refundRes.status === 'processed' ? 'succeeded' : 'processing';
        } catch (err: any) {
          refundStatus = 'failed';
          refundFailureReason = err.message || 'Payment gateway refund request error.';
        }
      } else {
        refundStatus = 'manual_review';
        refundFailureReason = 'Missing providerPaymentId on captured payment.';
      }

      // Save authoritative refund record
      const refundDoc: RefundDocument = {
        refundId,
        bookingId,
        paymentId: booking.paymentId,
        amount: refundAmountPaise,
        currency: 'INR',
        reason,
        providerRefundId,
        status: refundStatus,
        requestedBy: requestedByUid,
        requestedAt: nowStr,
        processedAt: refundStatus === 'succeeded' ? nowStr : null,
        failureReason: refundFailureReason,
        createdAt: nowStr,
        updatedAt: nowStr,
      };

      await this.db.collection('refunds').doc(refundId).set(refundDoc);
    }

    // 7. Transition booking state
    await bookingRef.update({
      bookingStatus: 'cancelled',
      paymentStatus: refundStatus === 'succeeded' ? 'refunded' : refundStatus === 'failed' ? 'refund_failed' : 'refund_pending',
      cancellationReason: reason,
      cancelledBy: requestedByUid,
      cancelledAt: nowStr,
      updatedAt: nowStr,
    });

    // 8. Release nightly inventory locks atomically
    const nightlyDates = inventoryLockService.generateNightlyDates(booking.checkIn, booking.checkOut);
    const batch = this.db.batch();
    nightlyDates.forEach(d => {
      const lockRef = this.db.collection('room_date_locks').doc(`${booking.roomId}_${d}`);
      batch.delete(lockRef);
    });
    await batch.commit();

    // 9. Notify customer and owner
    try {
      const custDoc = await this.db.collection('users').doc(booking.customerId).get();
      const customerPhone = custDoc.exists ? custDoc.data()?.phoneNumber : '+919876543210';
      await whatsAppMessenger.sendNotification(
        customerPhone,
        `Your RoomWala booking for ${booking.roomTitleSnapshot} has been cancelled. Refund status: ${refundStatus}.`
      );
    } catch {
      // Non-blocking notification delivery
    }

    // 10. Audit event
    await auditService.recordEvent({
      eventType: 'BOOKING_CANCELLED',
      userId: requestedByUid,
      resourceId: bookingId,
      details: { refundAmountPaise, refundStatus, refundId, reason },
    });

    return {
      bookingId,
      bookingStatus: 'cancelled',
      refundStatus,
      refundAmountPaise,
      refundId,
      inventoryReleased: true,
    };
  }

  /**
   * Process Provider Webhook for asynchronous refund updates
   */
  async handleRefundWebhook(
    providerRefundId: string,
    status: 'succeeded' | 'failed',
    failureReason?: string
  ): Promise<void> {
    const refundQuery = await this.db
      .collection('refunds')
      .where('providerRefundId', '==', providerRefundId)
      .limit(1)
      .get();

    if (refundQuery.empty) return;

    const refundDoc = refundQuery.docs[0];
    const nowStr = new Date().toISOString();

    await refundDoc.ref.update({
      status,
      processedAt: status === 'succeeded' ? nowStr : null,
      failureReason: failureReason || null,
      updatedAt: nowStr,
    });

    const refundData = refundDoc.data() as RefundDocument;
    if (refundData.bookingId) {
      await this.db.collection('bookings').doc(refundData.bookingId).update({
        paymentStatus: status === 'succeeded' ? 'refunded' : 'refund_failed',
        updatedAt: nowStr,
      });
    }
  }
}

export const cancellationRefundService = new CancellationRefundService();
