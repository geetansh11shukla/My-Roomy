import * as admin from 'firebase-admin';
import { BookingHoldDocument, RoomBlockDocument, RoomDateLockDocument } from './availabilityTypes';
import { RoomDocument } from '../rooms/roomTypes';
import { UserProfileDocument } from '../users/userTypes';
import { AppError, ConflictError, NotFoundError } from '../../common/errors';
import { auditService } from '../../audit/auditService';

export class InventoryLockService {
  private get db(): admin.firestore.Firestore {
    return admin.firestore();
  }

  /**
   * Helper: expands a half-open date range [checkIn, checkOut) into list of nightly YYYY-MM-DD date strings.
   * Check-in is inclusive; checkout is exclusive.
   */
  generateNightlyDates(checkInStr: string, checkOutStr: string): string[] {
    const dates: string[] = [];
    const current = new Date(checkInStr);
    const end = new Date(checkOutStr);

    if (end <= current) {
      throw new AppError('Check-out date must be strictly after check-in date.', 400);
    }

    while (current < end) {
      const yyyy = current.getFullYear();
      const mm = String(current.getMonth() + 1).padStart(2, '0');
      const dd = String(current.getDate()).padStart(2, '0');
      dates.push(`${yyyy}-${mm}-${dd}`);
      current.setDate(current.getDate() + 1);
    }
    return dates;
  }

  /**
   * Evaluates if two half-open date intervals conflict:
   * requestedStart < existingEnd AND requestedEnd > existingStart
   */
  hasIntervalConflict(startA: string, endA: string, startB: string, endB: string): boolean {
    const aStart = new Date(startA).getTime();
    const aEnd = new Date(endA).getTime();
    const bStart = new Date(startB).getTime();
    const bEnd = new Date(endB).getTime();
    return aStart < bEnd && aEnd > bStart;
  }

  /**
   * Atomic Inventory-Lock: Claims deterministic per-room, per-night locks in a Firestore Transaction.
   * If any date cannot be claimed, transaction aborts and all locks fail together.
   */
  async createAtomicHold(params: {
    roomId: string;
    customerId: string;
    checkIn: string;
    checkOut: string;
    guestCount: number;
    idempotencyKey?: string;
  }): Promise<{ holdId: string; expiresAt: string; lockedNights: string[] }> {
    const { roomId, customerId, checkIn, checkOut, guestCount, idempotencyKey } = params;
    const nightlyDates = this.generateNightlyDates(checkIn, checkOut);
    const holdId = `hold_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 10 * 60 * 1000).toISOString(); // 10 minute atomic slot lock
    const nowStr = now.toISOString();

    const roomRef = this.db.collection('rooms').doc(roomId);
    const userRef = this.db.collection('users').doc(customerId);
    const holdRef = this.db.collection('booking_holds').doc(holdId);

    // Deterministic lock doc refs
    const lockRefs = nightlyDates.map(dateStr =>
      this.db.collection('room_date_locks').doc(`${roomId}_${dateStr}`)
    );

    await this.db.runTransaction(async transaction => {
      // 1. Verify Room exists and is published
      const roomSnap = await transaction.get(roomRef);
      if (!roomSnap.exists) throw new NotFoundError('Room not found.');
      const room = roomSnap.data() as RoomDocument;
      if (room.listingStatus !== 'published') {
        throw new AppError('Room is not currently active for bookings.', 400);
      }
      if (guestCount > room.maxGuests) {
        throw new AppError(`Guest count exceeds room capacity of ${room.maxGuests}.`, 400);
      }

      // 2. Verify Customer eligibility
      const userSnap = await transaction.get(userRef);
      if (userSnap.exists) {
        const user = userSnap.data() as UserProfileDocument;
        if (user.accountStatus === 'suspended') {
          throw new AppError('Suspended account cannot create booking holds.', 403);
        }
        if (user.ageEligibilityStatus === 'ineligible') {
          throw new AppError('User does not meet 18+ age eligibility requirements.', 403);
        }
      }

      // 3. Atomically evaluate and claim each nightly lock document
      const lockSnaps = await Promise.all(lockRefs.map(ref => transaction.get(ref)));
      for (let i = 0; i < lockSnaps.length; i++) {
        const snap = lockSnaps[i];
        const dateStr = nightlyDates[i];

        if (snap.exists) {
          const lockData = snap.data() as RoomDateLockDocument;
          // If lock is a hold, check if expired
          if (lockData.lockType === 'hold' && lockData.expiresAt) {
            const isExpired = new Date(lockData.expiresAt).getTime() <= now.getTime();
            if (!isExpired) {
              throw new ConflictError(`Night of ${dateStr} is currently held by another guest.`);
            }
            // Stale hold lock can be overwritten in transaction
          } else {
            // Confirmed booking or active owner block
            throw new ConflictError(`Night of ${dateStr} is occupied and unavailable.`);
          }
        }
      }

      // 4. All nights available: write the lock documents and hold record atomically
      nightlyDates.forEach((dateStr, idx) => {
        const lockDoc: RoomDateLockDocument = {
          lockId: `${roomId}_${dateStr}`,
          roomId,
          date: dateStr,
          lockType: 'hold',
          holderId: holdId,
          expiresAt,
          createdAt: nowStr,
        };
        transaction.set(lockRefs[idx], lockDoc);
      });

      const holdDoc: BookingHoldDocument = {
        holdId,
        roomId,
        customerId,
        checkIn,
        checkOut,
        status: 'active',
        expiresAt,
        idempotencyKey,
        createdAt: nowStr,
        updatedAt: nowStr,
      };
      transaction.set(holdRef, holdDoc);
    });

    await auditService.recordEvent({
      eventType: 'BOOKING_HOLD_CREATED',
      userId: customerId,
      resourceId: holdId,
      details: { roomId, checkIn, checkOut, nightsCount: nightlyDates.length },
    });

    return { holdId, expiresAt, lockedNights: nightlyDates };
  }

  /**
   * Converts a hold atomically into a confirmed booking.
   * Changes lockType from 'hold' to 'booking' and removes expiration date.
   */
  async convertHoldToBooking(holdId: string, bookingId: string): Promise<void> {
    const holdRef = this.db.collection('booking_holds').doc(holdId);

    await this.db.runTransaction(async transaction => {
      const holdSnap = await transaction.get(holdRef);
      if (!holdSnap.exists) throw new NotFoundError('Hold record not found.');
      const hold = holdSnap.data() as BookingHoldDocument;

      if (hold.status !== 'active') {
        throw new AppError(`Hold is in '${hold.status}' state and cannot be converted.`, 400);
      }
      if (new Date(hold.expiresAt).getTime() <= Date.now()) {
        throw new AppError('Hold has expired. Please reselect dates.', 400);
      }

      const nightlyDates = this.generateNightlyDates(hold.checkIn, hold.checkOut);
      const lockRefs = nightlyDates.map(d =>
        this.db.collection('room_date_locks').doc(`${hold.roomId}_${d}`)
      );

      // Upgrade each lock document to permanent 'booking'
      const nowStr = new Date().toISOString();
      lockRefs.forEach(ref => {
        transaction.update(ref, {
          lockType: 'booking',
          holderId: bookingId,
          expiresAt: admin.firestore.FieldValue.delete(),
        });
      });

      // Update hold status
      transaction.update(holdRef, {
        status: 'converted',
        updatedAt: nowStr,
      });

      // Update room's bookedDates
      const roomRef = this.db.collection('rooms').doc(hold.roomId);
      transaction.update(roomRef, {
        bookedDates: admin.firestore.FieldValue.arrayUnion(...nightlyDates),
        updatedAt: nowStr,
      });
    });
  }

  /**
   * Checks whether all nights in [checkIn, checkOut) are unlocked and free of active holds or bookings.
   */
  async checkNightlyAvailability(roomId: string, checkIn: string, checkOut: string): Promise<boolean> {
    const nightlyDates = this.generateNightlyDates(checkIn, checkOut);
    for (const d of nightlyDates) {
      const lockDoc = await this.db.collection('room_date_locks').doc(`${roomId}_${d}`).get();
      if (lockDoc.exists) {
        return false;
      }
    }
    return true;
  }

  /**
   * Owner block: Atomically reserves dates for maintenance or owner block
   */
  async createOwnerBlock(params: {
    roomId: string;
    startDate: string;
    endDate: string;
    reason: RoomBlockDocument['reason'];
    ownerUid: string;
  }): Promise<string> {
    const { roomId, startDate, endDate, reason, ownerUid } = params;
    const nightlyDates = this.generateNightlyDates(startDate, endDate);
    const blockId = `block_${Date.now()}`;
    const nowStr = new Date().toISOString();

    const blockRef = this.db.collection('room_blocks').doc(blockId);
    const lockRefs = nightlyDates.map(d =>
      this.db.collection('room_date_locks').doc(`${roomId}_${d}`)
    );

    await this.db.runTransaction(async transaction => {
      // Validate all nights are unlocked
      const snaps = await Promise.all(lockRefs.map(r => transaction.get(r)));
      snaps.forEach((snap, idx) => {
        if (snap.exists) {
          throw new ConflictError(`Cannot block date ${nightlyDates[idx]}: already reserved.`);
        }
      });

      // Commit locks
      nightlyDates.forEach((d, idx) => {
        const lockDoc: RoomDateLockDocument = {
          lockId: `${roomId}_${d}`,
          roomId,
          date: d,
          lockType: 'block',
          holderId: blockId,
          createdAt: nowStr,
        };
        transaction.set(lockRefs[idx], lockDoc);
      });

      const blockDoc: RoomBlockDocument = {
        blockId,
        roomId,
        startDate,
        endDate,
        reason,
        createdBy: ownerUid,
        status: 'active',
        createdAt: nowStr,
        updatedAt: nowStr,
      };
      transaction.set(blockRef, blockDoc);
    });

    return blockId;
  }
}

export const inventoryLockService = new InventoryLockService();

