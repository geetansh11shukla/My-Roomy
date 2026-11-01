import * as admin from 'firebase-admin';
import { RoomRecord, BookingRecord, UserRecord, ExtensionOfferRecord } from '../types';
import { IRoomRepository, IBookingRepository, IUserRepository, IExtensionOfferRepository } from './interfaces';

export class FirestoreRoomRepository implements IRoomRepository {
  private get collection() {
    return admin.firestore().collection('rooms');
  }

  async findById(roomId: string): Promise<RoomRecord | null> {
    const doc = await this.collection.doc(roomId).get();
    return doc.exists ? (doc.data() as RoomRecord) : null;
  }

  async search(params: { city?: string; locality?: string; maxPrice?: number; roomType?: string }): Promise<RoomRecord[]> {
    let query: admin.firestore.Query = this.collection.where('listingStatus', '==', 'published');
    if (params.city && params.city !== 'All') {
      query = query.where('city', '==', params.city);
    }
    const snap = await query.get();
    let results = snap.docs.map(d => d.data() as RoomRecord);

    if (params.locality) {
      results = results.filter(r => r.locality.toLowerCase().includes(params.locality!.toLowerCase()));
    }
    if (params.maxPrice) {
      results = results.filter(r => r.pricePerNight <= params.maxPrice!);
    }
    if (params.roomType && params.roomType !== 'All') {
      results = results.filter(r => r.roomType.toLowerCase() === params.roomType!.toLowerCase());
    }
    return results;
  }

  async create(room: RoomRecord): Promise<void> {
    await this.collection.doc(room.roomId).set(room);
  }

  async updateBookedDates(roomId: string, datesToAdd: string[]): Promise<void> {
    await this.collection.doc(roomId).update({
      bookedDates: admin.firestore.FieldValue.arrayUnion(...datesToAdd),
    });
  }

  async removeBookedDates(roomId: string, datesToRemove: string[]): Promise<void> {
    await this.collection.doc(roomId).update({
      bookedDates: admin.firestore.FieldValue.arrayRemove(...datesToRemove),
    });
  }
}

export class FirestoreBookingRepository implements IBookingRepository {
  private get collection() {
    return admin.firestore().collection('bookings');
  }

  async findById(bookingId: string): Promise<BookingRecord | null> {
    const doc = await this.collection.doc(bookingId).get();
    return doc.exists ? (doc.data() as BookingRecord) : null;
  }

  async findByCustomerId(customerId: string): Promise<BookingRecord[]> {
    const snap = await this.collection.where('customerId', '==', customerId).get();
    return snap.docs.map(d => d.data() as BookingRecord);
  }

  async findByOwnerId(ownerId: string): Promise<BookingRecord[]> {
    const snap = await this.collection.where('ownerId', '==', ownerId).get();
    return snap.docs.map(d => d.data() as BookingRecord);
  }

  async create(booking: BookingRecord): Promise<void> {
    await this.collection.doc(booking.bookingId).set(booking);
  }

  async updateStatus(bookingId: string, status: BookingRecord['bookingStatus'], cancellationReason?: string): Promise<void> {
    await this.collection.doc(bookingId).update({
      bookingStatus: status,
      cancellationReason: cancellationReason || '',
      updatedAt: new Date().toISOString(),
    });
  }

  async updateCheckOut(bookingId: string, newCheckOut: string, additionalAmount: number): Promise<void> {
    await this.collection.doc(bookingId).update({
      checkOut: newCheckOut,
      totalAmount: admin.firestore.FieldValue.increment(additionalAmount),
      bookingStatus: 'extended',
      updatedAt: new Date().toISOString(),
    });
  }
}

export class FirestoreUserRepository implements IUserRepository {
  private get collection() {
    return admin.firestore().collection('users');
  }

  async findById(userId: string): Promise<UserRecord | null> {
    const doc = await this.collection.doc(userId).get();
    return doc.exists ? (doc.data() as UserRecord) : null;
  }

  async createOrUpdate(user: UserRecord): Promise<void> {
    await this.collection.doc(user.uid).set(user, { merge: true });
  }

  async updateVerificationStatus(userId: string, status: UserRecord['identityVerificationStatus']): Promise<void> {
    await this.collection.doc(userId).update({
      identityVerificationStatus: status,
      updatedAt: new Date().toISOString(),
    });
  }
}

export class FirestoreExtensionOfferRepository implements IExtensionOfferRepository {
  private get collection() {
    return admin.firestore().collection('extension_offers');
  }

  async findById(offerId: string): Promise<ExtensionOfferRecord | null> {
    const doc = await this.collection.doc(offerId).get();
    return doc.exists ? (doc.data() as ExtensionOfferRecord) : null;
  }

  async findByBookingId(bookingId: string): Promise<ExtensionOfferRecord | null> {
    const snap = await this.collection.where('bookingId', '==', bookingId).limit(1).get();
    return snap.empty ? null : (snap.docs[0].data() as ExtensionOfferRecord);
  }

  async create(offer: ExtensionOfferRecord): Promise<void> {
    await this.collection.doc(offer.offerId).set(offer);
  }

  async updateStatus(offerId: string, status: ExtensionOfferRecord['status']): Promise<void> {
    await this.collection.doc(offerId).update({
      status,
      updatedAt: new Date().toISOString(),
    });
  }
}

