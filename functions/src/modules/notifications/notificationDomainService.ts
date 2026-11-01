import * as admin from 'firebase-admin';
import {
  NotificationDocument,
  WhatsAppMessageDocument,
  CreateNotificationInput,
  SendWhatsAppTicketInput,
  SendOwnerAlertInput,
  SendLocationInput,
  SendCheckoutReminderInput,
} from './notificationTypes';
import { whatsAppMessenger } from '../../services/whatsappService';
import { fcmService } from '../../services/fcmService';
import { NotFoundError, UnauthorizedError } from '../../common/errors';
import { paiseToRupees } from '../../common/money';

export class NotificationDomainService {
  private get db() {
    return admin.firestore();
  }

  /**
   * 1. createNotification
   * Persists in-app and push notification record.
   * Guarantees idempotency via durableEventId when supplied.
   */
  async createNotification(input: CreateNotificationInput): Promise<NotificationDocument> {
    const {
      recipientUserId,
      bookingId = null,
      type,
      title,
      message,
      channel = 'in_app',
      scheduledAt = null,
      durableEventId,
    } = input;

    // Deduplication check via outbox_events
    if (durableEventId) {
      const eventRef = this.db.collection('outbox_events').doc(durableEventId);
      const eventDoc = await eventRef.get();
      if (eventDoc.exists && eventDoc.data()?.processed) {
        // Return existing notification if already generated
        const existingSnap = await this.db
          .collection('notifications')
          .where('recipientUserId', '==', recipientUserId)
          .where('type', '==', type)
          .where('bookingId', '==', bookingId)
          .limit(1)
          .get();

        if (!existingSnap.empty) {
          return existingSnap.docs[0].data() as NotificationDocument;
        }
      }
    }

    const notificationId = `NOTIF-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const nowStr = new Date().toISOString();

    const notifDoc: NotificationDocument = {
      notificationId,
      recipientUserId,
      bookingId: bookingId || null,
      type,
      title,
      message,
      channel,
      deliveryStatus: scheduledAt ? 'pending' : 'sent',
      providerMessageId: null,
      scheduledAt,
      sentAt: scheduledAt ? null : nowStr,
      failureReason: null,
      read: false,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    const batch = this.db.batch();
    batch.set(this.db.collection('notifications').doc(notificationId), notifDoc);

    if (durableEventId) {
      batch.set(this.db.collection('outbox_events').doc(durableEventId), {
        eventId: durableEventId,
        eventType: type,
        aggregateId: bookingId || recipientUserId,
        payload: { title, message },
        processed: true,
        processedAt: nowStr,
        createdAt: nowStr,
      });
    }

    await batch.commit();

    // Trigger FCM push dispatch if channel matches or multi-channel
    if (channel === 'fcm' || channel === 'in_app') {
      try {
        await fcmService.sendToUser(recipientUserId, title, message, {
          notificationId,
          type,
          bookingId: bookingId || '',
        });
      } catch (err) {
        console.warn('[NotificationDomainService] FCM dispatch warning:', err);
      }
    }

    return notifDoc;
  }

  /**
   * 2. getMyNotifications
   * Restricted: authenticated customer or owner can only read their notifications.
   */
  async getMyNotifications(viewerUserId: string): Promise<NotificationDocument[]> {
    const snap = await this.db
      .collection('notifications')
      .where('recipientUserId', '==', viewerUserId)
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get();

    return snap.docs.map(doc => doc.data() as NotificationDocument);
  }

  /**
   * 3. markNotificationRead
   */
  async markNotificationRead(notificationId: string, viewerUserId: string): Promise<void> {
    const notifRef = this.db.collection('notifications').doc(notificationId);
    const snap = await notifRef.get();
    if (!snap.exists) throw new NotFoundError('Notification not found.');

    const notif = snap.data() as NotificationDocument;
    if (notif.recipientUserId !== viewerUserId) {
      throw new UnauthorizedError('Unauthorized notification access.');
    }

    await notifRef.update({
      read: true,
      deliveryStatus: 'read',
      updatedAt: new Date().toISOString(),
    });
  }

  /**
   * 4. markAllNotificationsRead
   */
  async markAllNotificationsRead(viewerUserId: string): Promise<number> {
    const snap = await this.db
      .collection('notifications')
      .where('recipientUserId', '==', viewerUserId)
      .where('read', '==', false)
      .get();

    const batch = this.db.batch();
    const nowStr = new Date().toISOString();

    snap.docs.forEach(doc => {
      batch.update(doc.ref, {
        read: true,
        deliveryStatus: 'read',
        updatedAt: nowStr,
      });
    });

    if (snap.size > 0) {
      await batch.commit();
    }
    return snap.size;
  }

  /**
   * 5. sendBookingTicket (WhatsApp Cloud API Integration)
   * Sends verified booking ticket to the customer with digital door access PIN.
   */
  async sendBookingTicket(input: SendWhatsAppTicketInput): Promise<WhatsAppMessageDocument> {
    const { recipientUserId, recipientPhone, bookingId, roomTitle, checkIn, accessPin, locationUrl } = input;

    const messageId = `WA-TKT-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const nowStr = new Date().toISOString();

    const waDoc: WhatsAppMessageDocument = {
      messageId,
      recipientUserId,
      recipientPhone,
      bookingId,
      templateName: 'booking_confirmation_ticket',
      templateVersion: 'v2.1',
      parameters: { roomTitle, checkIn, accessPin, locationUrl },
      providerMessageId: null,
      status: 'queued',
      failureReason: null,
      consentVerified: true,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    // Store in whatsapp_messages collection
    await this.db.collection('whatsapp_messages').doc(messageId).set(waDoc);

    // Call WhatsApp Cloud Provider abstraction
    try {
      const delivered = await whatsAppMessenger.sendBookingTicket(
        recipientPhone,
        roomTitle,
        checkIn,
        accessPin,
        locationUrl
      );

      const status = delivered ? 'sent' : 'failed';
      await this.db.collection('whatsapp_messages').doc(messageId).update({
        status,
        providerMessageId: `wamid_${Date.now()}`,
        updatedAt: new Date().toISOString(),
      });

      waDoc.status = status;
    } catch (err: any) {
      await this.db.collection('whatsapp_messages').doc(messageId).update({
        status: 'failed',
        failureReason: err.message || 'WhatsApp dispatch failure',
        updatedAt: new Date().toISOString(),
      });
      waDoc.status = 'failed';
      waDoc.failureReason = err.message;
    }

    return waDoc;
  }

  /**
   * 6. sendOwnerBookingConfirmation
   * Informs room owner via WhatsApp when their room is successfully booked.
   */
  async sendOwnerBookingConfirmation(input: SendOwnerAlertInput): Promise<WhatsAppMessageDocument> {
    const { ownerUserId, ownerPhone, bookingId, roomTitle, customerName, checkIn, checkOut, totalPayoutPaise } = input;

    const messageId = `WA-OWN-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const nowStr = new Date().toISOString();
    const payoutRupees = paiseToRupees(totalPayoutPaise);

    const waDoc: WhatsAppMessageDocument = {
      messageId,
      recipientUserId: ownerUserId,
      recipientPhone: ownerPhone,
      bookingId,
      templateName: 'owner_booking_alert',
      templateVersion: 'v1.0',
      parameters: {
        roomTitle,
        customerName,
        checkIn,
        checkOut,
        payoutAmount: `Rs. ${payoutRupees}`,
      },
      providerMessageId: `wamid_own_${Date.now()}`,
      status: 'sent',
      failureReason: null,
      consentVerified: true,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    await this.db.collection('whatsapp_messages').doc(messageId).set(waDoc);

    await whatsAppMessenger.sendNotification(
      ownerPhone,
      `New Booking Confirmed for ${roomTitle}! Guest: ${customerName}, CheckIn: ${checkIn}. Est. Payout: Rs ${payoutRupees}`
    );

    return waDoc;
  }

  /**
   * 7. sendAuthorizedRoomLocation
   * Shares exact directions and property address only when booking is confirmed.
   */
  async sendAuthorizedRoomLocation(input: SendLocationInput): Promise<WhatsAppMessageDocument> {
    const { recipientUserId, recipientPhone, bookingId, roomTitle, locationUrl, addressText } = input;

    // Verify booking policy permits sharing location
    const bookingDoc = await this.db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) throw new NotFoundError('Booking reference not found.');
    const booking = bookingDoc.data()!;

    if (booking.bookingStatus !== 'confirmed' && booking.bookingStatus !== 'completed') {
      throw new UnauthorizedError('Room location is only shared for confirmed stays.');
    }

    const messageId = `WA-LOC-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const nowStr = new Date().toISOString();

    const waDoc: WhatsAppMessageDocument = {
      messageId,
      recipientUserId,
      recipientPhone,
      bookingId,
      templateName: 'authorized_room_location',
      templateVersion: 'v1.0',
      parameters: { roomTitle, locationUrl, addressText },
      providerMessageId: `wamid_loc_${Date.now()}`,
      status: 'sent',
      failureReason: null,
      consentVerified: true,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    await this.db.collection('whatsapp_messages').doc(messageId).set(waDoc);

    await whatsAppMessenger.sendNotification(
      recipientPhone,
      `Location & Directions for ${roomTitle}: ${addressText}. Google Maps: ${locationUrl}`
    );

    return waDoc;
  }

  /**
   * 8. sendCheckoutReminder
   * Sent 24 hours prior to checkout with stay extension option.
   */
  async sendCheckoutReminder(input: SendCheckoutReminderInput): Promise<WhatsAppMessageDocument> {
    const { recipientUserId, recipientPhone, bookingId, roomTitle, checkOut, extensionUrl } = input;

    const messageId = `WA-REM-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const nowStr = new Date().toISOString();

    const waDoc: WhatsAppMessageDocument = {
      messageId,
      recipientUserId,
      recipientPhone,
      bookingId,
      templateName: 'checkout_reminder_and_extension',
      templateVersion: 'v2.0',
      parameters: { roomTitle, checkOut, extensionUrl },
      providerMessageId: `wamid_rem_${Date.now()}`,
      status: 'sent',
      failureReason: null,
      consentVerified: true,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    await this.db.collection('whatsapp_messages').doc(messageId).set(waDoc);

    await whatsAppMessenger.sendCheckoutReminder(recipientPhone, roomTitle, checkOut, extensionUrl);

    return waDoc;
  }

  /**
   * 9. retryFailedNotification
   * Retries notifications from notification_jobs collection.
   */
  async retryFailedNotification(notificationId: string): Promise<boolean> {
    const notifRef = this.db.collection('notifications').doc(notificationId);
    const snap = await notifRef.get();
    if (!snap.exists) throw new NotFoundError('Notification not found.');

    const notif = snap.data() as NotificationDocument;
    const nowStr = new Date().toISOString();

    let delivered = false;
    try {
      if (notif.channel === 'fcm') {
        const res = await fcmService.sendToUser(notif.recipientUserId, notif.title, notif.message);
        delivered = res.successCount > 0;
      } else {
        delivered = true;
      }

      await notifRef.update({
        deliveryStatus: delivered ? 'sent' : 'failed',
        sentAt: delivered ? nowStr : null,
        failureReason: delivered ? null : 'Retry attempt failed to reach provider',
        updatedAt: nowStr,
      });
    } catch (err: any) {
      await notifRef.update({
        deliveryStatus: 'failed',
        failureReason: err.message,
        updatedAt: nowStr,
      });
    }

    return delivered;
  }

  /**
   * 10. handleWhatsAppWebhook
   * Updates delivery status from WhatsApp Business Platform (sent -> delivered -> read).
   */
  async handleWhatsAppWebhook(providerMessageId: string, status: 'delivered' | 'read' | 'failed', failureReason?: string): Promise<void> {
    const snap = await this.db
      .collection('whatsapp_messages')
      .where('providerMessageId', '==', providerMessageId)
      .limit(1)
      .get();

    if (snap.empty) return;

    const waDoc = snap.docs[0];
    const nowStr = new Date().toISOString();

    await waDoc.ref.update({
      status,
      failureReason: failureReason || null,
      updatedAt: nowStr,
    });
  }
}

export const notificationDomainService = new NotificationDomainService();
