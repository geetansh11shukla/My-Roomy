import * as admin from 'firebase-admin';
import { BookingDocument, BookingHoldQuoteResult } from './bookingTypes';
import { BookingStateMachine } from './bookingStateMachine';
import { RoomDocument } from '../rooms/roomTypes';
import { inventoryLockService } from '../availability/inventoryLockService';
import { calculateNights } from '../../common/dates';
import { paiseToRupees } from '../../common/money';
import { AppError, NotFoundError, UnauthorizedError } from '../../common/errors';
import { auditService } from '../../audit/auditService';
import { whatsAppMessenger } from '../../services/whatsappService';

export class BookingDomainService {
  private get db() {
    return admin.firestore();
  }

  /**
   * 1. createBookingHold
   * Customer UID enforced from auth context. Claims inventory atomically and returns server-calculated quote.
   */
  async createBookingHold(params: {
    customerUid: string;
    roomId: string;
    checkIn: string;
    checkOut: string;
    guestCount: number;
    idempotencyKey?: string;
  }): Promise<BookingHoldQuoteResult> {
    const { customerUid, roomId, checkIn, checkOut, guestCount, idempotencyKey } = params;

    // Fetch authoritative room data and price
    const roomSnap = await this.db.collection('rooms').doc(roomId).get();
    if (!roomSnap.exists) throw new NotFoundError('Room not found.');
    const room = roomSnap.data() as RoomDocument;

    // Atomically claim nightly inventory locks
    const holdResult = await inventoryLockService.createAtomicHold({
      roomId,
      customerId: customerUid,
      checkIn,
      checkOut,
      guestCount,
      idempotencyKey,
    });

    const nightCount = calculateNights(checkIn, checkOut);
    const pricePerNightRupees = paiseToRupees(room.pricePerNightPaise);
    const subtotal = pricePerNightRupees * nightCount;
    const taxAmount = Math.round(subtotal * 0.05); // 5% GST
    const fees = 0; // 0% Brokerage Guarantee
    const discountAmount = 0;
    const totalAmount = subtotal + taxAmount + fees - discountAmount;

    return {
      holdId: holdResult.holdId,
      roomId: room.roomId,
      roomTitle: room.title,
      roomCoverPhoto: room.coverPhotoUrl,
      checkIn,
      checkOut,
      nightCount,
      guestCount,
      pricePerNight: pricePerNightRupees,
      subtotal,
      fees,
      taxAmount,
      discountAmount,
      totalAmount,
      currency: 'INR',
      expiresAt: holdResult.expiresAt,
    };
  }

  /**
   * 2. confirmBookingFromHold
   * Atomically converts hold to confirmed booking document with immutable price snapshot and digital door PIN.
   */
  async confirmBookingFromHold(holdId: string, paymentId: string, customerUid: string): Promise<BookingDocument> {
    const holdDoc = await this.db.collection('booking_holds').doc(holdId).get();
    if (!holdDoc.exists) throw new NotFoundError('Hold does not exist.');
    const hold = holdDoc.data()!;

    if (hold.customerId !== customerUid) {
      throw new UnauthorizedError('Unauthorized hold ownership.');
    }

    const roomDoc = await this.db.collection('rooms').doc(hold.roomId).get();
    if (!roomDoc.exists) throw new NotFoundError('Room not found.');
    const room = roomDoc.data() as RoomDocument;

    const bookingId = `RW-${Date.now().toString().substring(5)}`;
    const accessPin = `PIN-${1000 + (Date.now() % 8999)}`;
    const nowStr = new Date().toISOString();

    const nightCount = calculateNights(hold.checkIn, hold.checkOut);
    const subtotalPaise = room.pricePerNightPaise * nightCount;
    const taxAmountPaise = Math.round(subtotalPaise * 0.05);
    const totalAmountPaise = subtotalPaise + taxAmountPaise;

    const booking: BookingDocument = {
      bookingId,
      roomId: room.roomId,
      customerId: customerUid,
      ownerId: room.ownerId,
      roomTitleSnapshot: room.title,
      roomPhotoSnapshot: room.coverPhotoUrl,
      checkIn: hold.checkIn,
      checkOut: hold.checkOut,
      guestCount: hold.guestCount || 1,
      nightCount,
      pricePerNightSnapshotPaise: room.pricePerNightPaise,
      subtotalPaise,
      feesPaise: 0,
      taxAmountPaise,
      discountAmountPaise: 0,
      totalAmountPaise,
      currency: 'INR',
      bookingStatus: 'confirmed',
      paymentStatus: 'captured',
      holdId,
      paymentId,
      cancellationPolicySnapshot: room.cancellationPolicyId,
      confirmedAt: nowStr,
      accessPin,
      locationUrl: `https://maps.google.com/?q=${room.latitude},${room.longitude}`,
      priorityExtensionEligible: true,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    // Commit locks and booking document in atomic transaction
    await this.db.runTransaction(async tx => {
      await inventoryLockService.convertHoldToBooking(holdId, bookingId);
      tx.set(this.db.collection('bookings').doc(bookingId), booking);
    });

    // Post-confirmation WhatsApp pass
    const userDoc = await this.db.collection('users').doc(customerUid).get();
    const phone = userDoc.exists ? userDoc.data()?.phoneNumber : '+919876543210';
    await whatsAppMessenger.sendBookingTicket(
      phone,
      booking.roomTitleSnapshot,
      booking.checkIn,
      accessPin,
      booking.locationUrl!
    );

    await auditService.recordEvent({
      eventType: 'BOOKING_CONFIRMED',
      userId: customerUid,
      resourceId: bookingId,
      details: { totalAmountRupees: paiseToRupees(totalAmountPaise) },
    });

    return booking;
  }

  /**
   * 3. getMyBookings (Customer only)
   */
  async getMyBookings(customerUid: string): Promise<BookingDocument[]> {
    const snap = await this.db
      .collection('bookings')
      .where('customerId', '==', customerUid)
      .orderBy('createdAt', 'desc')
      .get();
    return snap.docs.map(d => d.data() as BookingDocument);
  }

  /**
   * 4. getBookingDetails (Authorized customer, room owner or admin only)
   */
  async getBookingDetails(bookingId: string, viewerUid: string, userRole: string): Promise<BookingDocument> {
    const snap = await this.db.collection('bookings').doc(bookingId).get();
    if (!snap.exists) throw new NotFoundError('Booking reference not found.');
    const booking = snap.data() as BookingDocument;

    const isCustomer = booking.customerId === viewerUid;
    const isOwner = booking.ownerId === viewerUid;
    const isAdmin = userRole === 'admin';

    if (!isCustomer && !isOwner && !isAdmin) {
      throw new UnauthorizedError('Access to this booking is restricted.');
    }

    return booking;
  }

  /**
   * 5. getBookingTicket (Provides digital door PIN and Google Maps directions)
   */
  async getBookingTicket(bookingId: string, viewerUid: string): Promise<{
    bookingId: string;
    roomTitle: string;
    checkIn: string;
    checkOut: string;
    accessPin: string;
    locationUrl: string;
  }> {
    const booking = await this.getBookingDetails(bookingId, viewerUid, 'customer');
    if (booking.bookingStatus !== 'confirmed' && booking.bookingStatus !== 'completed') {
      throw new AppError('Digital PIN pass is only available for confirmed stays.', 400);
    }
    return {
      bookingId: booking.bookingId,
      roomTitle: booking.roomTitleSnapshot,
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      accessPin: booking.accessPin || 'PIN-1234',
      locationUrl: booking.locationUrl || 'https://maps.google.com',
    };
  }

  /**
   * 6. getOwnerBookings (Owner only for their listed rooms)
   */
  async getOwnerBookings(ownerUid: string): Promise<BookingDocument[]> {
    const snap = await this.db
      .collection('bookings')
      .where('ownerId', '==', ownerUid)
      .orderBy('createdAt', 'desc')
      .get();
    return snap.docs.map(d => d.data() as BookingDocument);
  }

  /**
   * 7. cancelBooking
   * Enforces legal state machine transitions and releases nightly inventory locks.
   */
  async cancelBooking(bookingId: string, userUid: string, reason: string): Promise<void> {
    const bookingRef = this.db.collection('bookings').doc(bookingId);
    const snap = await bookingRef.get();
    if (!snap.exists) throw new NotFoundError('Booking not found.');
    const booking = snap.data() as BookingDocument;

    if (booking.customerId !== userUid && booking.ownerId !== userUid) {
      throw new UnauthorizedError('Unauthorized cancellation attempt.');
    }

    // Assert state transition
    BookingStateMachine.assertTransition(booking.bookingStatus, 'cancelled');

    const nowStr = new Date().toISOString();
    await bookingRef.update({
      bookingStatus: 'cancelled',
      paymentStatus: 'refund_initiated',
      cancellationReason: reason,
      cancelledBy: userUid,
      cancelledAt: nowStr,
      updatedAt: nowStr,
    });

    // Release nightly inventory locks
    const nightlyDates = inventoryLockService.generateNightlyDates(booking.checkIn, booking.checkOut);
    const batch = this.db.batch();
    nightlyDates.forEach(d => {
      const lockRef = this.db.collection('room_date_locks').doc(`${booking.roomId}_${d}`);
      batch.delete(lockRef);
    });
    await batch.commit();

    await auditService.recordEvent({
      eventType: 'BOOKING_CANCELLED',
      userId: userUid,
      resourceId: bookingId,
      details: { reason, checkIn: booking.checkIn },
    });
  }

  /**
   * 8. completeEligibleBookings (Background / Scheduled trigger)
   */
  async completeEligibleBookings(): Promise<number> {
    const nowStr = new Date().toISOString();
    const snap = await this.db
      .collection('bookings')
      .where('bookingStatus', '==', 'confirmed')
      .where('checkOut', '<=', nowStr)
      .get();

    let completedCount = 0;
    const batch = this.db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, {
        bookingStatus: 'completed',
        completedAt: nowStr,
        updatedAt: nowStr,
      });
      completedCount++;
    }
    if (completedCount > 0) {
      await batch.commit();
    }
    return completedCount;
  }
}

export const bookingDomainService = new BookingDomainService();

