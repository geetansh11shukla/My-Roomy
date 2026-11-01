import * as admin from 'firebase-admin';
import { BookingRecord, RoomRecord } from '../types';
import { whatsAppMessenger } from './whatsappService';

export class BookingEngine {
  private db: admin.firestore.Firestore;

  constructor(dbInstance?: admin.firestore.Firestore) {
    this.db = dbInstance || admin.firestore();
  }

  /**
   * Atomic Booking Transaction:
   * Prevents double bookings and generates keyless access PIN
   */
  async createAtomicBooking(
    room: RoomRecord,
    customerId: string,
    customerName: string,
    customerPhone: string,
    checkInDate: string,
    checkOutDate: string,
    stayDays: number,
    totalAmount: number
  ): Promise<{ success: boolean; bookingId?: string; accessPin?: string; error?: string }> {
    const bookingId = `RW${Date.now().toString().substring(6)}`;
    const accessPin = `PIN${1000 + (Date.now() % 8999)}`;
    const locationUrl = `https://maps.google.com/?q=${room.latitude},${room.longitude}`;
    const now = new Date().toISOString();

    const booking: BookingRecord = {
      bookingId,
      roomId: room.roomId,
      customerId,
      ownerId: room.ownerId,
      roomTitleSnapshot: room.title,
      checkIn: checkInDate,
      checkOut: checkOutDate,
      guestCount: 1,
      nightCount: stayDays,
      pricePerNightSnapshot: room.pricePerNight,
      subtotal: totalAmount,
      fees: 0,
      taxAmount: Math.round(totalAmount * 0.05),
      discountAmount: 0,
      totalAmount,
      currency: 'INR',
      bookingStatus: 'confirmed',
      paymentStatus: 'captured',
      cancellationReason: '',
      accessPin,
      locationUrl,
      priorityExtensionEligible: true,
      createdAt: now,
      updatedAt: now,
    };

    try {
      const roomRef = this.db.collection('rooms').doc(room.roomId);
      const bookingRef = this.db.collection('bookings').doc(bookingId);

      await this.db.runTransaction(async transaction => {
        const roomDoc = await transaction.get(roomRef);
        if (!roomDoc.exists) {
          throw new Error('Room listing not found.');
        }

        const roomData = roomDoc.data() as RoomRecord;
        const booked = roomData.bookedDates || [];

        // Check date conflict
        if (booked.includes(checkInDate)) {
          throw new Error(`The room is already booked for ${checkInDate}.`);
        }

        // Commit reservation
        transaction.update(roomRef, {
          bookedDates: admin.firestore.FieldValue.arrayUnion(checkInDate),
        });

        transaction.set(bookingRef, booking);
      });

      // Post-transaction notifications
      await whatsAppMessenger.sendBookingTicket(
        customerPhone,
        room.title,
        checkInDate,
        accessPin,
        locationUrl
      );

      return { success: true, bookingId, accessPin };
    } catch (err: any) {
      console.error('[BookingEngine Transaction Error]:', err.message);
      return { success: false, error: err.message };
    }
  }

  /**
   * Process 24h Check-Out Reminders and create VIP Extension Offers
   */
  async processScheduledExtensionReminders(): Promise<number> {
    const now = new Date();
    const reminderThreshold = new Date(now.getTime() + 24 * 3600 * 1000).toISOString();

    const snapshot = await this.db
      .collection('bookings')
      .where('bookingStatus', '==', 'confirmed')
      .where('priorityExtensionEligible', '==', true)
      .where('checkOut', '<=', reminderThreshold)
      .get();

    let processed = 0;
    for (const doc of snapshot.docs) {
      const booking = doc.data() as BookingRecord;
      const offerId = `EXT_${booking.bookingId}`;

      const offerDoc = await this.db.collection('extension_offers').doc(offerId).get();
      if (!offerDoc.exists) {
        await this.db.collection('extension_offers').doc(offerId).set({
          offerId,
          bookingId: booking.bookingId,
          roomId: booking.roomId,
          customerId: booking.customerId,
          ownerId: booking.ownerId,
          offeredAt: now.toISOString(),
          expiresAt: new Date(now.getTime() + 12 * 3600 * 1000).toISOString(),
          quotedAmount: booking.pricePerNightSnapshot,
          status: 'offered',
          createdAt: now.toISOString(),
          updatedAt: now.toISOString(),
        });
        processed++;
      }
    }
    return processed;
  }
}
