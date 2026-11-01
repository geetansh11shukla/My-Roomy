import * as admin from 'firebase-admin';
import {
  ExtensionOfferDocument,
  CreateExtensionOfferInput,
  RequestExtensionDatesInput,
  ConfirmExtensionInput,
} from './extensionTypes';
import { BookingDocument } from '../bookings/bookingTypes';
import { RoomDocument } from '../rooms/roomTypes';
import { inventoryLockService } from '../availability/inventoryLockService';
import { paymentGateway } from '../../services/paymentService';
import { calculateNights } from '../../common/dates';
import { auditService } from '../../audit/auditService';
import { AppError, NotFoundError, UnauthorizedError } from '../../common/errors';

export class ExtensionDomainService {
  private get db() {
    return admin.firestore();
  }

  /**
   * 1. createExtensionOffer
   * Creates a time-limited extension invitation after the original booking is confirmed.
   * Checks current availability and calculates quote using room pricing and discount.
   */
  async createExtensionOffer(input: CreateExtensionOfferInput): Promise<ExtensionOfferDocument> {
    const { bookingId, extensionNights = 1, discountPercentage = 15 } = input;

    const bookingSnap = await this.db.collection('bookings').doc(bookingId).get();
    if (!bookingSnap.exists) throw new NotFoundError('Booking not found.');
    const booking = bookingSnap.data() as BookingDocument;

    if (booking.bookingStatus !== 'confirmed') {
      throw new AppError('Stay extension offers can only be created for confirmed bookings.', 400);
    }

    // Determine extension date range: starts at existing booking's checkOut
    const requestedCheckIn = booking.checkOut;
    const checkOutDate = new Date(requestedCheckIn);
    checkOutDate.setDate(checkOutDate.getDate() + extensionNights);
    const requestedCheckOut = checkOutDate.toISOString().split('T')[0];

    // Check availability: Existing bookings, holds, owner blocks cannot be overridden
    const isAvailable = await inventoryLockService.checkNightlyAvailability(
      booking.roomId,
      requestedCheckIn,
      requestedCheckOut
    );

    if (!isAvailable) {
      throw new AppError('Extension dates are not available for this room.', 409);
    }

    // Fetch authoritative room pricing
    const roomSnap = await this.db.collection('rooms').doc(booking.roomId).get();
    if (!roomSnap.exists) throw new NotFoundError('Room not found.');
    const room = roomSnap.data() as RoomDocument;

    const standardPrice = room.pricePerNightPaise * extensionNights;
    const discountedPrice = Math.floor(standardPrice * (1 - discountPercentage / 100));
    const taxPaise = Math.round(discountedPrice * 0.05);
    const totalQuotedPaise = discountedPrice + taxPaise;

    const offerId = `EXT-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const now = new Date();
    const nowStr = now.toISOString();

    // 24 hour offer window
    const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString();

    // Reminder scheduled for 24h before original check-out
    const checkOutTime = new Date(booking.checkOut).getTime();
    const reminderScheduledAt = new Date(checkOutTime - 24 * 60 * 60 * 1000).toISOString();

    const offerDoc: ExtensionOfferDocument = {
      offerId,
      bookingId,
      roomId: booking.roomId,
      customerId: booking.customerId,
      ownerId: booking.ownerId,
      offeredAt: nowStr,
      expiresAt,
      requestedCheckIn,
      requestedCheckOut,
      quotedAmount: totalQuotedPaise,
      currency: 'INR',
      paymentId: null,
      status: 'offered',
      reminderScheduledAt,
      reminderSentAt: null,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    await this.db.collection('extension_offers').doc(offerId).set(offerDoc);

    return offerDoc;
  }

  /**
   * 2. getEligibleExtensionOffers
   * Retrieves active, non-expired offers for an authenticated customer.
   */
  async getEligibleExtensionOffers(customerId: string): Promise<ExtensionOfferDocument[]> {
    const snap = await this.db
      .collection('extension_offers')
      .where('customerId', '==', customerId)
      .where('status', 'in', ['offered', 'payment_pending'])
      .get();

    const now = new Date();
    const eligible: ExtensionOfferDocument[] = [];

    for (const doc of snap.docs) {
      const offer = doc.data() as ExtensionOfferDocument;
      if (new Date(offer.expiresAt) > now) {
        eligible.push(offer);
      } else {
        // Enforce backend expiration
        await doc.ref.update({ status: 'expired', updatedAt: now.toISOString() });
      }
    }

    return eligible;
  }

  /**
   * 3. acceptExtensionOffer
   */
  async acceptExtensionOffer(offerId: string, customerId: string): Promise<ExtensionOfferDocument> {
    const offerRef = this.db.collection('extension_offers').doc(offerId);
    const snap = await offerRef.get();
    if (!snap.exists) throw new NotFoundError('Offer not found.');
    const offer = snap.data() as ExtensionOfferDocument;

    if (offer.customerId !== customerId) {
      throw new UnauthorizedError('Unauthorized extension offer.');
    }

    if (new Date(offer.expiresAt) <= new Date()) {
      await offerRef.update({ status: 'expired', updatedAt: new Date().toISOString() });
      throw new AppError('Extension offer has expired.', 400);
    }

    if (offer.status !== 'offered') {
      throw new AppError(`Cannot accept offer in status ${offer.status}.`, 400);
    }

    // Re-verify availability
    const available = await inventoryLockService.checkNightlyAvailability(
      offer.roomId,
      offer.requestedCheckIn,
      offer.requestedCheckOut
    );

    if (!available) {
      await offerRef.update({ status: 'expired', updatedAt: new Date().toISOString() });
      throw new AppError('Requested extension dates are no longer available. You may choose different dates.', 409);
    }

    const nowStr = new Date().toISOString();
    await offerRef.update({
      status: 'accepted',
      updatedAt: nowStr,
    });

    offer.status = 'accepted';
    offer.updatedAt = nowStr;
    return offer;
  }

  /**
   * 4. declineExtensionOffer
   */
  async declineExtensionOffer(offerId: string, customerId: string): Promise<void> {
    const offerRef = this.db.collection('extension_offers').doc(offerId);
    const snap = await offerRef.get();
    if (!snap.exists) throw new NotFoundError('Offer not found.');
    const offer = snap.data() as ExtensionOfferDocument;

    if (offer.customerId !== customerId) {
      throw new UnauthorizedError('Unauthorized access.');
    }

    await offerRef.update({
      status: 'declined',
      updatedAt: new Date().toISOString(),
    });
  }

  /**
   * 5. requestExtensionDates
   * Customer requests custom extension dates. Re-quotes authoritative pricing.
   */
  async requestExtensionDates(input: RequestExtensionDatesInput): Promise<ExtensionOfferDocument> {
    const { offerId, customerId, newRequestedCheckOut } = input;

    const offerRef = this.db.collection('extension_offers').doc(offerId);
    const snap = await offerRef.get();
    if (!snap.exists) throw new NotFoundError('Offer not found.');
    const offer = snap.data() as ExtensionOfferDocument;

    if (offer.customerId !== customerId) {
      throw new UnauthorizedError('Unauthorized access.');
    }

    // Check availability of the custom date range
    const isAvailable = await inventoryLockService.checkNightlyAvailability(
      offer.roomId,
      offer.requestedCheckIn,
      newRequestedCheckOut
    );

    if (!isAvailable) {
      throw new AppError('Selected extension dates conflict with an existing reservation.', 409);
    }

    const roomSnap = await this.db.collection('rooms').doc(offer.roomId).get();
    const room = roomSnap.data() as RoomDocument;

    const nights = calculateNights(offer.requestedCheckIn, newRequestedCheckOut);
    const subtotal = room.pricePerNightPaise * nights;
    const discounted = Math.floor(subtotal * 0.85); // 15% discount
    const quotedAmount = discounted + Math.round(discounted * 0.05);

    const nowStr = new Date().toISOString();
    const updatedFields = {
      requestedCheckOut: newRequestedCheckOut,
      quotedAmount,
      status: 'offered' as const,
      updatedAt: nowStr,
    };

    await offerRef.update(updatedFields);
    return { ...offer, ...updatedFields };
  }

  /**
   * 6. createExtensionPaymentOrder
   */
  async createExtensionPaymentOrder(offerId: string, customerId: string): Promise<{ paymentId: string; providerOrderId: string; amountPaise: number }> {
    const offer = await this.acceptExtensionOffer(offerId, customerId);

    const paymentId = `PAY-EXT-${Date.now()}`;
    const orderRes = await paymentGateway.createOrder(
      offer.quotedAmount,
      `rcpt_ext_${offerId.substring(0, 20)}`,
      { offerId, bookingId: offer.bookingId, customerId }
    );

    const nowStr = new Date().toISOString();
    await this.db.collection('extension_offers').doc(offerId).update({
      paymentId,
      status: 'payment_pending',
      updatedAt: nowStr,
    });

    return {
      paymentId,
      providerOrderId: orderRes.id,
      amountPaise: offer.quotedAmount,
    };
  }

  /**
   * 7. confirmExtension
   * Atomically claims nightly inventory locks for the extended range, updates booking checkout & total amount,
   * cancels old 24h reminder and schedules the new reminder.
   */
  async confirmExtension(input: ConfirmExtensionInput): Promise<BookingDocument> {
    const { offerId, customerId, paymentId } = input;

    const offerRef = this.db.collection('extension_offers').doc(offerId);
    const snap = await offerRef.get();
    if (!snap.exists) throw new NotFoundError('Offer not found.');
    const offer = snap.data() as ExtensionOfferDocument;

    if (offer.customerId !== customerId) {
      throw new UnauthorizedError('Unauthorized access.');
    }

    const bookingRef = this.db.collection('bookings').doc(offer.bookingId);
    const bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) throw new NotFoundError('Booking not found.');
    const booking = bookingSnap.data() as BookingDocument;

    if (booking.bookingStatus === 'cancelled') {
      throw new AppError('Cannot extend a cancelled booking.', 400);
    }

    // Atomic extension lock
    const nightlyDates = inventoryLockService.generateNightlyDates(offer.requestedCheckIn, offer.requestedCheckOut);

    await this.db.runTransaction(async tx => {
      // Lock each extended date
      for (const d of nightlyDates) {
        const lockRef = this.db.collection('room_date_locks').doc(`${offer.roomId}_${d}`);
        const lockDoc = await tx.get(lockRef);
        if (lockDoc.exists) {
          throw new AppError(`Room night ${d} has already been reserved.`, 409);
        }
        tx.set(lockRef, {
          lockId: `${offer.roomId}_${d}`,
          roomId: offer.roomId,
          date: d,
          bookingId: booking.bookingId,
          customerId,
          status: 'confirmed',
          createdAt: new Date().toISOString(),
        });
      }

      const nowStr = new Date().toISOString();
      const updatedTotalPaise = booking.totalAmountPaise + offer.quotedAmount;
      const updatedNightCount = booking.nightCount + nightlyDates.length;

      // Update booking checkout & financials
      tx.update(bookingRef, {
        checkOut: offer.requestedCheckOut,
        nightCount: updatedNightCount,
        totalAmountPaise: updatedTotalPaise,
        updatedAt: nowStr,
      });

      // Update offer
      tx.update(offerRef, {
        paymentId,
        status: 'confirmed',
        updatedAt: nowStr,
      });
    });

    // Reschedule checkout reminder 24 hours before NEW checkOut
    await this.scheduleCheckoutReminder(booking.bookingId, offer.requestedCheckOut);

    await auditService.recordEvent({
      eventType: 'STAY_EXTENDED',
      userId: customerId,
      resourceId: booking.bookingId,
      details: { newCheckOut: offer.requestedCheckOut, addedAmountPaise: offer.quotedAmount },
    });

    const updatedBookingSnap = await bookingRef.get();
    return updatedBookingSnap.data() as BookingDocument;
  }

  /**
   * 8. expireExtensionOffers (Scheduled Cron/Worker)
   */
  async expireExtensionOffers(): Promise<number> {
    const nowStr = new Date().toISOString();
    const snap = await this.db
      .collection('extension_offers')
      .where('status', 'in', ['offered', 'payment_pending'])
      .where('expiresAt', '<=', nowStr)
      .get();

    const batch = this.db.batch();
    snap.docs.forEach(doc => {
      batch.update(doc.ref, {
        status: 'expired',
        updatedAt: nowStr,
      });
    });

    if (snap.size > 0) {
      await batch.commit();
    }
    return snap.size;
  }

  /**
   * 9. scheduleCheckoutReminder
   * Replaces/schedules checkout reminder for 24h prior to check-out.
   */
  async scheduleCheckoutReminder(bookingId: string, checkOut: string): Promise<void> {
    const checkOutTime = new Date(checkOut).getTime();
    const reminderTime = new Date(checkOutTime - 24 * 60 * 60 * 1000);
    const now = new Date();

    if (reminderTime > now) {
      await this.db.collection('notification_jobs').doc(`rem_${bookingId}`).set({
        jobId: `rem_${bookingId}`,
        bookingId,
        channel: 'whatsapp',
        scheduledAt: reminderTime.toISOString(),
        status: 'pending',
        attempts: 0,
        maxAttempts: 3,
        updatedAt: now.toISOString(),
      });
    }
  }
}

export const extensionDomainService = new ExtensionDomainService();

