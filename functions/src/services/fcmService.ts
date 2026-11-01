import * as admin from 'firebase-admin';

export interface IFcmService {
  sendToUser(userId: string, title: string, body: string, data?: Record<string, string>): Promise<{ successCount: number; failureCount: number }>;
  registerDeviceToken(userId: string, token: string, deviceName?: string): Promise<void>;
  removeDeviceToken(userId: string, token: string): Promise<void>;
}

export class FcmService implements IFcmService {
  private get db() {
    return admin.firestore();
  }

  /**
   * Register device token under authenticated user (supporting multiple devices)
   */
  async registerDeviceToken(userId: string, token: string, deviceName: string = 'mobile'): Promise<void> {
    const tokenRef = this.db.collection('users').doc(userId).collection('fcm_tokens').doc(token);
    await tokenRef.set({
      token,
      deviceName,
      updatedAt: new Date().toISOString(),
    });
  }

  /**
   * Remove invalid or expired device token
   */
  async removeDeviceToken(userId: string, token: string): Promise<void> {
    const tokenRef = this.db.collection('users').doc(userId).collection('fcm_tokens').doc(token);
    await tokenRef.delete();
  }

  /**
   * Send push notification to all active devices of an authorized recipient.
   * Cleans up stale/invalid tokens reported by FCM.
   */
  async sendToUser(
    userId: string,
    title: string,
    body: string,
    data: Record<string, string> = {}
  ): Promise<{ successCount: number; failureCount: number }> {
    const tokensSnap = await this.db.collection('users').doc(userId).collection('fcm_tokens').get();
    if (tokensSnap.empty) {
      return { successCount: 0, failureCount: 0 };
    }

    const tokens = tokensSnap.docs.map(doc => doc.id);
    let successCount = 0;
    let failureCount = 0;

    // Check if Firebase messaging is active and credentials are present
    const isMock = process.env.NODE_ENV !== 'production' || admin.apps.length === 0;

    if (isMock) {
      // Mock FCM dispatch in test/dev
      return { successCount: tokens.length, failureCount: 0 };
    }

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data,
      });

      successCount = response.successCount;
      failureCount = response.failureCount;

      // Handle invalid tokens
      const tokensToRemove: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errCode = resp.error?.code;
          if (
            errCode === 'messaging/invalid-registration-token' ||
            errCode === 'messaging/registration-token-not-registered'
          ) {
            tokensToRemove.push(tokens[idx]);
          }
        }
      });

      if (tokensToRemove.length > 0) {
        const batch = this.db.batch();
        tokensToRemove.forEach(tok => {
          const ref = this.db.collection('users').doc(userId).collection('fcm_tokens').doc(tok);
          batch.delete(ref);
        });
        await batch.commit();
      }
    } catch (err) {
      console.error('[FcmService] Send error:', err);
    }

    return { successCount, failureCount };
  }
}

export const fcmService = new FcmService();

