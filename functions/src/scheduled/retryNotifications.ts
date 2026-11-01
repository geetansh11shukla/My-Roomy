import * as admin from 'firebase-admin';
import { logger } from '../common/logger';
import { notificationDomainService } from '../modules/notifications/notificationDomainService';
import { NotificationDocument } from '../modules/notifications/notificationTypes';

/**
 * 5. retryNotifications
 * - Finds failed notifications with retry eligibility
 * - Employs bounded retries with exponential backoff
 */
export async function retryNotifications(): Promise<number> {
  logger.info('[Scheduled] Retrying failed notifications...');
  const db = admin.firestore();

  const failedSnap = await db
    .collection('notifications')
    .where('deliveryStatus', '==', 'failed')
    .limit(20)
    .get();

  let retriedCount = 0;

  for (const doc of failedSnap.docs) {
    const notif = doc.data() as NotificationDocument;
    const delivered = await notificationDomainService.retryFailedNotification(notif.notificationId);
    if (delivered) retriedCount++;
  }

  logger.info(`[Scheduled] Retried ${retriedCount} notifications.`);
  return retriedCount;
}
