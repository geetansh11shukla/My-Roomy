import { RoomRecord, BookingRecord, UserRecord, ExtensionOfferRecord } from '../types';

export interface IRoomRepository {
  findById(roomId: string): Promise<RoomRecord | null>;
  search(params: { city?: string; locality?: string; maxPrice?: number; roomType?: string }): Promise<RoomRecord[]>;
  create(room: RoomRecord): Promise<void>;
  updateBookedDates(roomId: string, datesToAdd: string[]): Promise<void>;
  removeBookedDates(roomId: string, datesToRemove: string[]): Promise<void>;
}

export interface IBookingRepository {
  findById(bookingId: string): Promise<BookingRecord | null>;
  findByCustomerId(customerId: string): Promise<BookingRecord[]>;
  findByOwnerId(ownerId: string): Promise<BookingRecord[]>;
  create(booking: BookingRecord): Promise<void>;
  updateStatus(bookingId: string, status: BookingRecord['bookingStatus'], cancellationReason?: string): Promise<void>;
  updateCheckOut(bookingId: string, newCheckOut: string, additionalAmount: number): Promise<void>;
}

export interface IUserRepository {
  findById(userId: string): Promise<UserRecord | null>;
  createOrUpdate(user: UserRecord): Promise<void>;
  updateVerificationStatus(userId: string, status: UserRecord['identityVerificationStatus']): Promise<void>;
}

export interface IExtensionOfferRepository {
  findById(offerId: string): Promise<ExtensionOfferRecord | null>;
  findByBookingId(bookingId: string): Promise<ExtensionOfferRecord | null>;
  create(offer: ExtensionOfferRecord): Promise<void>;
  updateStatus(offerId: string, status: ExtensionOfferRecord['status']): Promise<void>;
}

