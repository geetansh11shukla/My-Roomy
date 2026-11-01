import * as admin from 'firebase-admin';
import {
  PaymentDocument,
  CreatePaymentOrderResult,
  VerifyPaymentInput,
  InitiateRefundInput,
  RefundResult,
} from './paymentTypes';
import { paymentGateway } from '../../services/paymentService';
import { bookingDomainService } from '../bookings/bookingDomainService';
import { RoomDocument } from '../rooms/roomTypes';
import { calculateNights } from '../../common/dates';
import { AppError, NotFoundError, UnauthorizedError } from '../../common/errors';
import { auditService } from '../../audit/auditService';

export class PaymentDomainService {
  private get db() {
    return admin.firestore();
  }

  /**
   * 1. createPaymentOrder
   * Reads the active booking hold, authoritative room pricing, generates order with payment gateway,
   * stores payment document in Firestore under `payments` collection.
   */
  async createPaymentOrder(holdId: string, customerUid: string): Promise<CreatePaymentOrderResult> {
    const holdDoc = await this.db.collection('booking_holds').doc(holdId).get();
    if (!holdDoc.exists) {
      throw new NotFoundError('Booking hold not found.');
    }
    const hold = holdDoc.data()!;

    if (hold.customerId !== customerUid) {
      throw new UnauthorizedError('Hold does not belong to the authenticated user.');
    }

    if (hold.status !== 'active') {
      throw new AppError(`Hold is not active (status: ${hold.status}).`, 400);
    }

    const now = new Date();
    if (new Date(hold.expiresAt) < now) {
      throw new AppError('Booking hold has expired. Please reserve your dates again.', 400);
    }

    // Authoritative room pricing
    const roomDoc = await this.db.collection('rooms').doc(hold.roomId).get();
    if (!roomDoc.exists) {
      throw new NotFoundError('Room for hold not found.');
    }
    const room = roomDoc.data() as RoomDocument;

    const nights = calculateNights(hold.checkIn, hold.checkOut);
    const subtotalPaise = room.pricePerNightPaise * nights;
    const taxPaise = Math.round(subtotalPaise * 0.05); // 5% GST
    const totalPaise = subtotalPaise + taxPaise;

    const paymentId = `PAY-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const gatewayOrder = await paymentGateway.createOrder(
      totalPaise,
      `rcpt_${holdId.substring(0, 30)}`,
      { holdId, customerId: customerUid, roomId: hold.roomId }
    );

    const nowStr = new Date().toISOString();
    const paymentDoc: PaymentDocument = {
      paymentId,
      bookingId: '', // populated once booking is confirmed
      customerId: customerUid,
      provider: 'razorpay',
      providerOrderId: gatewayOrder.id,
      providerPaymentId: null,
      amount: totalPaise,
      currency: 'INR',
      status: 'created',
      signatureVerified: false,
      webhookEventId: null,
      failureCode: null,
      failureMessage: null,
      paidAt: null,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    await this.db.collection('payments').doc(paymentId).set(paymentDoc);

    // Link paymentId with the hold
    await this.db.collection('booking_holds').doc(holdId).update({
      paymentId,
      updatedAt: nowStr,
    });

    await auditService.recordEvent({
      eventType: 'PAYMENT_ORDER_CREATED',
      userId: customerUid,
      resourceId: paymentId,
      details: { amountPaise: totalPaise, orderId: gatewayOrder.id },
    });

    return {
      paymentId,
      providerOrderId: gatewayOrder.id,
      amountPaise: totalPaise,
      currency: 'INR',
      keyId: paymentGateway.getKeyId(),
      bookingHoldId: holdId,
    };
  }

  /**
   * 2. verifyPayment
   * Verifies payment signature cryptographically with server secret.
   * Atomically confirms booking and converts inventory locks.
   */
  async verifyPayment(input: VerifyPaymentInput): Promise<{ success: boolean; bookingId?: string }> {
    const { paymentId, providerOrderId, providerPaymentId, signature, customerUid } = input;

    const paymentRef = this.db.collection('payments').doc(paymentId);
    const paymentSnap = await paymentRef.get();
    if (!paymentSnap.exists) {
      throw new NotFoundError('Payment reference not found.');
    }
    const payment = paymentSnap.data() as PaymentDocument;

    if (payment.customerId !== customerUid) {
      throw new UnauthorizedError('Payment does not belong to the authenticated user.');
    }

    if (payment.status === 'captured') {
      return { success: true, bookingId: payment.bookingId };
    }

    // Verify HMAC-SHA256 signature
    const isValidSignature = paymentGateway.verifyPaymentSignature(
      providerOrderId,
      providerPaymentId,
      signature
    );

    if (!isValidSignature) {
      const nowStr = new Date().toISOString();
      await paymentRef.update({
        signatureVerified: false,
        status: 'failed',
        failureCode: 'SIGNATURE_VERIFICATION_FAILED',
        failureMessage: 'Cryptographic signature mismatch.',
        updatedAt: nowStr,
      });
      throw new AppError('Payment signature verification failed.', 400);
    }

    // Find the hold associated with this payment
    const holdSnap = await this.db
      .collection('booking_holds')
      .where('paymentId', '==', paymentId)
      .limit(1)
      .get();

    if (holdSnap.empty) {
      throw new NotFoundError('Associated booking hold not found.');
    }
    const hold = holdSnap.docs[0].data();
    const holdId = holdSnap.docs[0].id;

    // Check if hold expired before payment was verified
    const isHoldExpired = new Date(hold.expiresAt) < new Date();
    if (isHoldExpired && hold.status !== 'converted') {
      // Inventory may have been reclaimed! Mark reconciliation_required
      const nowStr = new Date().toISOString();
      await paymentRef.update({
        signatureVerified: true,
        status: 'reconciliation_required',
        providerPaymentId,
        paidAt: nowStr,
        failureCode: 'HOLD_EXPIRED_PAYMENT_CAPTURED',
        failureMessage: 'Payment received after hold expiry. Inventory reconciliation required.',
        updatedAt: nowStr,
      });
      return { success: false };
    }

    // Confirm booking atomically from hold
    const booking = await bookingDomainService.confirmBookingFromHold(holdId, paymentId, customerUid);

    const nowStr = new Date().toISOString();
    await paymentRef.update({
      signatureVerified: true,
      status: 'captured',
      providerPaymentId,
      bookingId: booking.bookingId,
      paidAt: nowStr,
      updatedAt: nowStr,
    });

    await auditService.recordEvent({
      eventType: 'PAYMENT_VERIFIED',
      userId: customerUid,
      resourceId: paymentId,
      details: { bookingId: booking.bookingId, providerPaymentId },
    });

    return { success: true, bookingId: booking.bookingId };
  }

  /**
   * 3. paymentWebhook
   * Idempotent webhook handler verifying Razorpay webhook signature and deduplicating by webhookEventId.
   */
  async paymentWebhook(rawBody: string, signature: string, eventId: string): Promise<{ received: boolean; processed: boolean; reason?: string }> {
    // 1. Verify webhook signature
    const isValid = paymentGateway.verifyWebhookSignature(rawBody, signature);
    if (!isValid) {
      throw new UnauthorizedError('Invalid webhook signature.');
    }

    // 2. Check for duplicate event (idempotency)
    const existingEvents = await this.db
      .collection('payment_webhook_events')
      .doc(eventId)
      .get();

    if (existingEvents.exists) {
      return { received: true, processed: false, reason: 'Duplicate event already processed.' };
    }

    const payload = JSON.parse(rawBody);
    const eventType = payload.event;
    const nowStr = new Date().toISOString();

    // Store webhook event for audit and deduplication
    await this.db.collection('payment_webhook_events').doc(eventId).set({
      eventId,
      eventType,
      receivedAt: nowStr,
    });

    if (eventType === 'payment.captured') {
      const pEntity = payload.payload?.payment?.entity;
      if (!pEntity) return { received: true, processed: false };

      const providerOrderId = pEntity.order_id;
      const providerPaymentId = pEntity.id;

      const paymentQuery = await this.db
        .collection('payments')
        .where('providerOrderId', '==', providerOrderId)
        .limit(1)
        .get();

      if (!paymentQuery.empty) {
        const paymentDoc = paymentQuery.docs[0];
        const payment = paymentDoc.data() as PaymentDocument;

        if (payment.status !== 'captured') {
          // Find associated hold
          const holdSnap = await this.db
            .collection('booking_holds')
            .where('paymentId', '==', payment.paymentId)
            .limit(1)
            .get();

          if (!holdSnap.empty) {
            const hold = holdSnap.docs[0].data();
            const isHoldExpired = new Date(hold.expiresAt) < new Date();

            if (isHoldExpired && hold.status !== 'converted') {
              await paymentDoc.ref.update({
                status: 'reconciliation_required',
                providerPaymentId,
                webhookEventId: eventId,
                paidAt: nowStr,
                updatedAt: nowStr,
              });
            } else if (hold.status === 'active') {
              const booking = await bookingDomainService.confirmBookingFromHold(
                holdSnap.docs[0].id,
                payment.paymentId,
                payment.customerId
              );

              await paymentDoc.ref.update({
                status: 'captured',
                signatureVerified: true,
                providerPaymentId,
                bookingId: booking.bookingId,
                webhookEventId: eventId,
                paidAt: nowStr,
                updatedAt: nowStr,
              });
            }
          }
        }
      }
    } else if (eventType === 'payment.failed') {
      const pEntity = payload.payload?.payment?.entity;
      if (pEntity) {
        const providerOrderId = pEntity.order_id;
        const paymentQuery = await this.db
          .collection('payments')
          .where('providerOrderId', '==', providerOrderId)
          .limit(1)
          .get();

        if (!paymentQuery.empty) {
          await paymentQuery.docs[0].ref.update({
            status: 'failed',
            failureCode: pEntity.error_code || 'GATEWAY_DECLINE',
            failureMessage: pEntity.error_description || 'Payment failed at provider',
            webhookEventId: eventId,
            updatedAt: nowStr,
          });
        }
      }
    }

    return { received: true, processed: true };
  }

  /**
   * 4. getPaymentStatus
   * Authorized lookup by customer UID, booking owner, or admin.
   */
  async getPaymentStatus(paymentId: string, viewerUid: string, userRole: string = 'customer'): Promise<PaymentDocument> {
    const snap = await this.db.collection('payments').doc(paymentId).get();
    if (!snap.exists) {
      throw new NotFoundError('Payment document not found.');
    }
    const payment = snap.data() as PaymentDocument;

    if (payment.customerId !== viewerUid && userRole !== 'admin') {
      throw new UnauthorizedError('Unauthorized payment access.');
    }

    return payment;
  }

  /**
   * 5. initiateRefund
   * Initiates payment refund via gateway, updates status to `refund_pending` or `refunded`.
   */
  async initiateRefund(input: InitiateRefundInput): Promise<RefundResult> {
    const { paymentId, reason, requestedByUid, amountPaise } = input;

    const paymentRef = this.db.collection('payments').doc(paymentId);
    const snap = await paymentRef.get();
    if (!snap.exists) throw new NotFoundError('Payment not found.');
    const payment = snap.data() as PaymentDocument;

    if (!payment.providerPaymentId) {
      throw new AppError('Cannot refund a payment without providerPaymentId.', 400);
    }

    if (payment.status !== 'captured' && payment.status !== 'reconciliation_required') {
      throw new AppError(`Cannot refund payment in status ${payment.status}.`, 400);
    }

    const refundAmount = amountPaise || payment.amount;
    const refundRes = await paymentGateway.initiateRefund(payment.providerPaymentId, refundAmount, {
      paymentId,
      reason,
      requestedByUid,
    });

    const nowStr = new Date().toISOString();
    await paymentRef.update({
      status: 'refunded',
      updatedAt: nowStr,
    });

    if (payment.bookingId) {
      await this.db.collection('bookings').doc(payment.bookingId).update({
        paymentStatus: 'refunded',
        updatedAt: nowStr,
      });
    }

    const refundRecord = {
      refundId: refundRes.id,
      paymentId,
      bookingId: payment.bookingId,
      amountPaise: refundAmount,
      reason,
      status: refundRes.status as 'processed' | 'pending' | 'failed',
      requestedByUid,
      createdAt: nowStr,
    };

    await this.db.collection('refunds').doc(refundRes.id).set(refundRecord);

    await auditService.recordEvent({
      eventType: 'REFUND_PROCESSED',
      userId: requestedByUid,
      resourceId: refundRes.id,
      details: { paymentId, refundAmountPaise: refundAmount, reason },
    });

    return {
      refundId: refundRes.id,
      paymentId,
      amountPaise: refundAmount,
      status: refundRes.status as 'processed' | 'pending' | 'failed',
      createdAt: nowStr,
    };
  }

  /**
   * 6. getRefundStatus
   */
  async getRefundStatus(refundId: string): Promise<any> {
    const snap = await this.db.collection('refunds').doc(refundId).get();
    if (!snap.exists) throw new NotFoundError('Refund record not found.');
    return snap.data();
  }

  /**
   * 7. reconcilePendingPayments
   * Scheduled/Cron worker to reconcile payments that are 'created' or 'reconciliation_required'.
   */
  async reconcilePendingPayments(): Promise<{ reconciledCount: number }> {
    const snap = await this.db
      .collection('payments')
      .where('status', 'in', ['created', 'reconciliation_required'])
      .get();

    let count = 0;
    const now = new Date();

    for (const doc of snap.docs) {
      const payment = doc.data() as PaymentDocument;
      const createdTime = new Date(payment.createdAt).getTime();
      const elapsedMinutes = (now.getTime() - createdTime) / (1000 * 60);

      // If created more than 30 minutes ago without capture, mark failed
      if (payment.status === 'created' && elapsedMinutes > 30) {
        await doc.ref.update({
          status: 'failed',
          failureCode: 'ORDER_EXPIRED',
          failureMessage: 'Payment order was not completed in the permitted window.',
          updatedAt: now.toISOString(),
        });
        count++;
      }
    }

    return { reconciledCount: count };
  }
}

export const paymentDomainService = new PaymentDomainService();

