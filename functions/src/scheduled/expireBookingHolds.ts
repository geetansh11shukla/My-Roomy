import * as admin from 'firebase-admin';
import { logger } from '../common/logger';
import { BookingHoldDocument } from '../modules/availability/availabilityTypes';

/**
 * 1. expireBookingHolds
 * - Finds holds where expiresAt <= now and status == 'active'
 * - Rechecks current hold state to prevent touching converted holds or confirmed bookings
 * - Releases ONLY the inventory (room_date_locks) owned by that hold
 * - Transitions hold status to 'expired'
 * - Idempotent
 */
export async function expireBookingHolds(): Promise<number> {
  logger.info('[Scheduled] Expiring past booking holds...');
  const db = admin.firestore();
  const now = new Date();
  const nowStr = now.toISOString();

  const expiredSnapshot = await db
    .collection('booking_holds')
    .where('status', '==', 'active')
    .where('expiresAt', '<=', nowStr)
    .get();

  let count = 0;

  for (const doc of expiredSnapshot.docs) {
    const hold = doc.data() as BookingHoldDocument;

    // Double-check state before write
    if (hold.status !== 'active') continue;

    await db.runTransaction(async tx => {
      const freshDoc = await tx.get(doc.ref);
      if (!freshDoc.exists) return;
      const freshHold = freshDoc.data() as BookingHoldDocument;
      if (freshHold.status !== 'active') return;

      // Expand nights
      const current = new Date(freshHold.checkIn);
      const end = new Date(freshHold.checkOut);
      while (current < end) {
        const yyyy = current.getFullYear();
        const mm = String(current.getMonth() + 1).padStart(2, '0');
        const dd = String(current.getDate()).padStart(2, '0');
        const dStr = `${yyyy}-${mm}-${dd}`;
        const lockRef = db.collection('room_date_locks').doc(`${freshHold.roomId}_${dStr}`);

        // Read lock to ensure it belongs to THIS hold before deleting
        const lockSnap = await tx.get(lockRef);
        if (lockSnap.exists && lockSnap.data()?.holderId === freshHold.holdId) {
          tx.delete(lockRef);
        }
        current.setDate(current.getDate() + 1);
      }

      // Mark hold expired
      tx.update(doc.ref, {
        status: 'expired',
        updatedAt: nowStr,
      });
      count++;
    });
  }

  logger.info(`[Scheduled] Expired ${count} stale booking holds and released inventory.`);
  return count;
}
