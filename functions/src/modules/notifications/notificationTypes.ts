export type NotificationChannel = 'in_app' | 'fcm' | 'whatsapp';

export type NotificationDeliveryStatus = 'pending' | 'queued' | 'sent' | 'delivered' | 'read' | 'failed';

export type NotificationType =
  | 'booking_confirmed'
  | 'booking_cancelled'
  | 'checkout_reminder'
  | 'location_shared'
  | 'stay_extension_offer'
  | 'owner_booking_alert'
  | 'identity_verification_update'
  | 'payout_processed';

export interface NotificationDocument {
  notificationId: string;
  recipientUserId: string;
  bookingId: string | null;
  type: NotificationType;
  title: string;
  message: string;
  channel: NotificationChannel;
  deliveryStatus: NotificationDeliveryStatus;
  providerMessageId: string | null;
  scheduledAt: string | null;
  sentAt: string | null;
  failureReason: string | null;
  read: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface WhatsAppMessageDocument {
  messageId: string;
  recipientUserId: string;
  recipientPhone: string;
  bookingId: string | null;
  templateName: string;
  templateVersion: string;
  parameters: Record<string, string>;
  providerMessageId: string | null;
  status: 'queued' | 'sent' | 'delivered' | 'read' | 'failed';
  failureReason: string | null;
  consentVerified: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface NotificationJobDocument {
  jobId: string;
  notificationId: string;
  channel: NotificationChannel;
  attempts: number;
  maxAttempts: number;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  nextAttemptAt: string;
  lastError: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface OutboxEventDocument {
  eventId: string; // Durable event ID for idempotency & deduplication
  eventType: string;
  aggregateId: string;
  payload: Record<string, any>;
  processed: boolean;
  processedAt: string | null;
  createdAt: string;
}

export interface CreateNotificationInput {
  recipientUserId: string;
  bookingId?: string | null;
  type: NotificationType;
  title: string;
  message: string;
  channel?: NotificationChannel;
  scheduledAt?: string | null;
  durableEventId?: string; // Idempotency check against duplicate event firing
}

export interface SendWhatsAppTicketInput {
  recipientUserId: string;
  recipientPhone: string;
  bookingId: string;
  roomTitle: string;
  checkIn: string;
  accessPin: string;
  locationUrl: string;
}

export interface SendOwnerAlertInput {
  ownerUserId: string;
  ownerPhone: string;
  bookingId: string;
  roomTitle: string;
  customerName: string;
  checkIn: string;
  checkOut: string;
  totalPayoutPaise: number;
}

export interface SendLocationInput {
  recipientUserId: string;
  recipientPhone: string;
  bookingId: string;
  roomTitle: string;
  locationUrl: string;
  addressText: string;
}

export interface SendCheckoutReminderInput {
  recipientUserId: string;
  recipientPhone: string;
  bookingId: string;
  roomTitle: string;
  checkOut: string;
  extensionUrl: string;
}

