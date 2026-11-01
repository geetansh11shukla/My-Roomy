import { Router } from 'express';
import { notificationDomainService } from './notificationDomainService';
import { fcmService } from '../../services/fcmService';
import { authenticate } from '../../middleware/authenticate';

export const notificationsRouter = Router();

/**
 * 1. GET /notifications
 * Get authenticated user notifications.
 */
notificationsRouter.get('/', authenticate, async (req, res) => {
  try {
    const userId = (req as any).user.uid;
    const notifications = await notificationDomainService.getMyNotifications(userId);
    return res.json({ success: true, notifications });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 2. POST /notifications/:id/read
 * Mark single notification as read.
 */
notificationsRouter.post('/:id/read', authenticate, async (req, res) => {
  try {
    const userId = (req as any).user.uid;
    const { id } = req.params;
    await notificationDomainService.markNotificationRead(id, userId);
    return res.json({ success: true, message: 'Notification marked read.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 3. POST /notifications/read-all
 * Mark all notifications as read.
 */
notificationsRouter.post('/read-all', authenticate, async (req, res) => {
  try {
    const userId = (req as any).user.uid;
    const count = await notificationDomainService.markAllNotificationsRead(userId);
    return res.json({ success: true, markedCount: count });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 4. POST /notifications/fcm/token
 * Register device FCM token.
 */
notificationsRouter.post('/fcm/token', authenticate, async (req, res) => {
  try {
    const userId = (req as any).user.uid;
    const { token, deviceName } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: 'FCM token is required.' });
    }
    await fcmService.registerDeviceToken(userId, token, deviceName);
    return res.json({ success: true, message: 'Device token registered.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 5. POST /notifications/retry/:id
 * Retry a failed notification.
 */
notificationsRouter.post('/retry/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const delivered = await notificationDomainService.retryFailedNotification(id);
    return res.json({ success: true, delivered });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 6. POST /notifications/whatsapp/webhook
 * WhatsApp Business Platform webhook callback for status updates (sent, delivered, read).
 */
notificationsRouter.post('/whatsapp/webhook', async (req, res) => {
  try {
    const { entry } = req.body;
    if (entry && Array.isArray(entry)) {
      for (const e of entry) {
        for (const change of e.changes || []) {
          for (const statusObj of change.value?.statuses || []) {
            const providerMessageId = statusObj.id;
            const status = statusObj.status; // 'delivered' | 'read' | 'failed'
            if (providerMessageId && status) {
              await notificationDomainService.handleWhatsAppWebhook(providerMessageId, status);
            }
          }
        }
      }
    }
    return res.json({ status: 'ok' });
  } catch (err: any) {
    return res.status(500).json({ success: false, message: err.message });
  }
});

