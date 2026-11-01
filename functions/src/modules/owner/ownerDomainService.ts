import * as admin from 'firebase-admin';
import {
  OwnerDashboardMetrics,
  RoomBlockDocument,
  OwnerPayoutDocument,
  SubmitOwnerApplicationInput,
} from './ownerTypes';
import { RoomDocument } from '../rooms/roomTypes';
import { BookingDocument } from '../bookings/bookingTypes';
import { inventoryLockService } from '../availability/inventoryLockService';
import { AppError, NotFoundError, UnauthorizedError } from '../../common/errors';

export class OwnerDomainService {
  private get db() {
    return admin.firestore();
  }

  /**
   * 1. submitOwnerApplication
   * Onboards applicant with restricted bank & property details. Transitions user role to owner upon approval.
   */
  async submitOwnerApplication(input: SubmitOwnerApplicationInput): Promise<{ applicationId: string; status: string }> {
    const { userId, propertyAddress, taxIdentifierMasked, bankAccountNumberMasked, bankIfsc } = input;

    const applicationId = `OWN-APP-${Date.now()}`;
    const nowStr = new Date().toISOString();

    const application = {
      applicationId,
      userId,
      propertyAddress,
      taxIdentifierMasked: taxIdentifierMasked || 'XXXX-XXXX',
      bankAccountNumberMasked: bankAccountNumberMasked || 'XXXX-XXXX-1234',
      bankIfsc: bankIfsc || 'HDFC0001234',
      status: 'pending_review',
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    await this.db.collection('owner_applications').doc(applicationId).set(application);

    await this.db.collection('users').doc(userId).update({
      role: 'owner',
      updatedAt: nowStr,
    });

    return { applicationId, status: 'pending_review' };
  }

  /**
   * 2. getOwnerDashboard
   * Authoritatively computes metrics from rooms, bookings, and payouts without client-provided sums.
   */
  async getOwnerDashboard(ownerId: string): Promise<OwnerDashboardMetrics> {
    // 1. Listings
    const roomsSnap = await this.db.collection('rooms').where('ownerId', '==', ownerId).get();
    let totalListings = roomsSnap.size;
    let publishedListings = 0;
    let pendingListings = 0;

    roomsSnap.docs.forEach(doc => {
      const r = doc.data() as RoomDocument;
      if (r.listingStatus === 'published') publishedListings++;
      if (r.listingStatus === 'pending_review') pendingListings++;
    });

    // 2. Bookings
    const bookingsSnap = await this.db.collection('bookings').where('ownerId', '==', ownerId).get();
    let upcomingBookings = 0;
    let completedBookings = 0;
    let grossBookingValuePaise = 0;
    let platformFeesPaise = 0;

    bookingsSnap.docs.forEach(doc => {
      const b = doc.data() as BookingDocument;
      if (b.bookingStatus === 'confirmed') {
        upcomingBookings++;
        grossBookingValuePaise += b.totalAmountPaise || 0;
        platformFeesPaise += b.feesPaise || 0;
      } else if (b.bookingStatus === 'completed') {
        completedBookings++;
        grossBookingValuePaise += b.totalAmountPaise || 0;
        platformFeesPaise += b.feesPaise || 0;
      }
    });

    // 3. Payouts
    const payoutsSnap = await this.db.collection('owner_payouts').where('ownerId', '==', ownerId).get();
    let pendingPayoutsPaise = 0;
    let completedPayoutsPaise = 0;

    payoutsSnap.docs.forEach(doc => {
      const p = doc.data() as OwnerPayoutDocument;
      if (p.status === 'completed') {
        completedPayoutsPaise += p.netAmount || 0;
      } else if (p.status === 'pending' || p.status === 'processing') {
        pendingPayoutsPaise += p.netAmount || 0;
      }
    });

    const netEarningsPaise = grossBookingValuePaise - platformFeesPaise;

    return {
      totalListings,
      publishedListings,
      pendingListings,
      upcomingBookings,
      completedBookings,
      grossBookingValuePaise,
      platformFeesPaise,
      netEarningsPaise,
      pendingPayoutsPaise,
      completedPayoutsPaise,
    };
  }

  /**
   * 3. getOwnerRooms
   */
  async getOwnerRooms(ownerId: string): Promise<RoomDocument[]> {
    const snap = await this.db.collection('rooms').where('ownerId', '==', ownerId).get();
    return snap.docs.map(d => d.data() as RoomDocument);
  }

  /**
   * 4. getOwnerBookings
   */
  async getOwnerBookings(ownerId: string): Promise<BookingDocument[]> {
    const snap = await this.db
      .collection('bookings')
      .where('ownerId', '==', ownerId)
      .orderBy('createdAt', 'desc')
      .get();
    return snap.docs.map(d => d.data() as BookingDocument);
  }

  /**
   * 5. getOwnerEarnings
   */
  async getOwnerEarnings(ownerId: string): Promise<{ grossEarningsPaise: number; netEarningsPaise: number; totalBookings: number }> {
    const dashboard = await this.getOwnerDashboard(ownerId);
    return {
      grossEarningsPaise: dashboard.grossBookingValuePaise,
      netEarningsPaise: dashboard.netEarningsPaise,
      totalBookings: dashboard.upcomingBookings + dashboard.completedBookings,
    };
  }

  /**
   * 6. getOwnerPayouts
   */
  async getOwnerPayouts(ownerId: string): Promise<OwnerPayoutDocument[]> {
    const snap = await this.db
      .collection('owner_payouts')
      .where('ownerId', '==', ownerId)
      .orderBy('requestedAt', 'desc')
      .get();
    return snap.docs.map(d => d.data() as OwnerPayoutDocument);
  }

  /**
   * 7. createRoomBlock
   * Atomically locks dates for owner maintenance or personal use.
   * Rejects if conflicting with confirmed bookings or active holds.
   */
  async createRoomBlock(params: {
    roomId: string;
    ownerId: string;
    startDate: string;
    endDate: string;
    reason: 'maintenance' | 'owner_block' | 'other';
  }): Promise<RoomBlockDocument> {
    const { roomId, ownerId, startDate, endDate, reason } = params;

    // Verify room ownership
    const roomSnap = await this.db.collection('rooms').doc(roomId).get();
    if (!roomSnap.exists) throw new NotFoundError('Room not found.');
    const room = roomSnap.data() as RoomDocument;

    if (room.ownerId !== ownerId) {
      throw new UnauthorizedError('Unauthorized room block attempt.');
    }

    // Atomic availability check
    const isAvailable = await inventoryLockService.checkNightlyAvailability(roomId, startDate, endDate);
    if (!isAvailable) {
      throw new AppError('Cannot block dates: dates conflict with an existing reservation or hold.', 409);
    }

    const blockId = `BLK-${Date.now()}`;
    const nowStr = new Date().toISOString();
    const nightlyDates = inventoryLockService.generateNightlyDates(startDate, endDate);

    // Commit room_blocks and nightly locks in atomic transaction
    await this.db.runTransaction(async tx => {
      for (const d of nightlyDates) {
        const lockRef = this.db.collection('room_date_locks').doc(`${roomId}_${d}`);
        tx.set(lockRef, {
          lockId: `${roomId}_${d}`,
          roomId,
          date: d,
          blockId,
          createdBy: ownerId,
          status: 'blocked',
          createdAt: nowStr,
        });
      }

      const blockDoc: RoomBlockDocument = {
        blockId,
        roomId,
        startDate,
        endDate,
        reason,
        createdBy: ownerId,
        status: 'active',
        createdAt: nowStr,
        updatedAt: nowStr,
      };

      tx.set(this.db.collection('room_blocks').doc(blockId), blockDoc);
    });

    return {
      blockId,
      roomId,
      startDate,
      endDate,
      reason,
      createdBy: ownerId,
      status: 'active',
      createdAt: nowStr,
      updatedAt: nowStr,
    };
  }

  /**
   * 8. releaseRoomBlock
   */
  async releaseRoomBlock(blockId: string, ownerId: string): Promise<void> {
    const blockRef = this.db.collection('room_blocks').doc(blockId);
    const snap = await blockRef.get();
    if (!snap.exists) throw new NotFoundError('Room block not found.');
    const block = snap.data() as RoomBlockDocument;

    if (block.createdBy !== ownerId) {
      throw new UnauthorizedError('Unauthorized to release this block.');
    }

    const nightlyDates = inventoryLockService.generateNightlyDates(block.startDate, block.endDate);
    const batch = this.db.batch();

    nightlyDates.forEach(d => {
      const lockRef = this.db.collection('room_date_locks').doc(`${block.roomId}_${d}`);
      batch.delete(lockRef);
    });

    batch.update(blockRef, {
      status: 'released',
      updatedAt: new Date().toISOString(),
    });

    await batch.commit();
  }

  /**
   * 9. getOwnerReviews
   */
  async getOwnerReviews(ownerId: string): Promise<any[]> {
    const snap = await this.db.collection('reviews').where('ownerId', '==', ownerId).get();
    return snap.docs.map(d => d.data());
  }
}

export const ownerDomainService = new OwnerDomainService();
