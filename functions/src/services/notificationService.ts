import * as admin from 'firebase-admin';

export class NotificationService {
  async sendPushNotification(fcmTokens: string[], title: string, body: string, data?: Record<string, string>): Promise<number> {
    if (!fcmTokens || fcmTokens.length === 0) return 0;

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: fcmTokens,
        notification: { title, body },
        data: data || {},
      });
      return response.successCount;
    } catch (err) {
      console.warn('[FCM Notification Error] (Safe fallback):', err);
      return 0;
    }
  }

  async sendExtensionOfferAlert(fcmTokens: string[], roomTitle: string, hoursRemaining: number): Promise<number> {
    return this.sendPushNotification(
      fcmTokens,
      'Stay Extension Priority Open',
      `You have ${hoursRemaining}h to extend your stay at ${roomTitle} before dates open to public.`,
      { type: 'extension_priority' }
    );
  }
}

export const notificationService = new NotificationService();

