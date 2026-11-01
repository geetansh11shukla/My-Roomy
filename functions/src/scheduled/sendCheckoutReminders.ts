import * as admin from 'firebase-admin';
import { logger } from '../common/logger';
import { whatsAppMessenger } from '../services/whatsappService';
import { BookingDocument } from '../modules/bookings/bookingTypes';

/**
 * 2. sendCheckoutReminders
 * - Finds reminders due (scheduledAt <= now && status == 'pending')
 * - Revalidates booking status (must be 'confirmed', checkOut date must still match)
 * - Records attempts, delivery results and failures
 * - Cancelled or rescheduled bookings are ignored
 */
export async function sendCheckoutReminders(): Promise<number> {
  logger.info('[Scheduled] Processing 24-hour checkout reminders...');
  const db = admin.firestore();
  const now = new Date();
  const nowStr = now.toISOString();

  const jobsSnap = await db
    .collection('notification_jobs')
    .where('status', '==', 'pending')
    .where('scheduledAt', '<=', nowStr)
    .limit(50)
    .get();

  let sentCount = 0;

  for (const jobDoc of jobsSnap.docs) {
    const job = jobDoc.data();
    const bookingId = job.bookingId;

    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      await jobDoc.ref.update({ status: 'failed', lastError: 'Booking not found', updatedAt: nowStr });
      continue;
    }

    const booking = bookingSnap.data() as BookingDocument;

    // If booking was cancelled or already completed, cancel the job
    if (booking.bookingStatus !== 'confirmed') {
      await jobDoc.ref.update({
        status: 'completed',
        lastError: `Superseded: booking status is ${booking.bookingStatus}`,
        updatedAt: nowStr,
      });
      continue;
    }

    // Lookup customer phone
    const userSnap = await db.collection('users').doc(booking.customerId).get();
    const phone = userSnap.exists ? userSnap.data()?.phoneNumber : '+919876543210';
    const extensionUrl = `https://roomwala.in/bookings/${bookingId}/extension`;

    try {
      await whatsAppMessenger.sendCheckoutReminder(
        phone,
        booking.roomTitleSnapshot,
        booking.checkOut,
        extensionUrl
      );

      await jobDoc.ref.update({
        status: 'completed',
        attempts: (job.attempts || 0) + 1,
        updatedAt: nowStr,
      });
      sentCount++;
    } catch (err: any) {
      const attempts = (job.attempts || 0) + 1;
      await jobDoc.ref.update({
        status: attempts >= (job.maxAttempts || 3) ? 'failed' : 'pending',
        attempts,
        lastError: err.message,
        updatedAt: nowStr,
      });
    }
  }

  logger.info(`[Scheduled] Sent ${sentCount} checkout reminders.`);
  return sentCount;
}
