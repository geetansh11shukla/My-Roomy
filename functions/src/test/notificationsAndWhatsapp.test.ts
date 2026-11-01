import { describe, it, expect, vi, beforeEach } from 'vitest';
import { NotificationDomainService } from '../modules/notifications/notificationDomainService';
import { whatsAppMessenger } from '../services/whatsappService';
import { fcmService } from '../services/fcmService';

const mockDb = new Map<string, any>();

vi.mock('firebase-admin', () => {
  return {
    apps: ['[DEFAULT]'],
    firestore: vi.fn(() => ({
      collection: (colName: string) => ({
        doc: (id: string) => ({
          get: async () => ({
            exists: mockDb.has(`${colName}/${id}`),
            data: () => mockDb.get(`${colName}/${id}`),
            id,
          }),
          set: async (data: any) => {
            mockDb.set(`${colName}/${id}`, data);
          },
          update: async (data: any) => {
            const prev = mockDb.get(`${colName}/${id}`) || {};
            mockDb.set(`${colName}/${id}`, { ...prev, ...data });
          },
          collection: (subCol: string) => ({
            doc: (subId: string) => ({
              set: async (data: any) => {
                mockDb.set(`${colName}/${id}/${subCol}/${subId}`, data);
              },
              delete: async () => {
                mockDb.delete(`${colName}/${id}/${subCol}/${subId}`);
              },
            }),
            get: async () => {
              const docs: any[] = [];
              for (const [key, val] of mockDb.entries()) {
                if (key.startsWith(`${colName}/${id}/${subCol}/`)) {
                  docs.push({
                    id: key.split('/').pop(),
                    data: () => val,
                  });
                }
              }
              return { empty: docs.length === 0, docs };
            },
          }),
        }),
        where: (field: string, op: string, value: any) => ({
          where: (f2: string, _op2: string, v2: any) => ({
            where: (f3: string, _op3: string, v3: any) => ({
              limit: () => ({
                get: async () => {
                  const docs: any[] = [];
                  for (const [key, val] of mockDb.entries()) {
                    if (key.startsWith(`${colName}/`) && val[field] === value && val[f2] === v2 && val[f3] === v3) {
                      docs.push({
                        id: key.split('/')[1],
                        data: () => val,
                      });
                    }
                  }
                  return { empty: docs.length === 0, docs };
                },
              }),
            }),
            get: async () => {
              const docs: any[] = [];
              for (const [key, val] of mockDb.entries()) {
                if (key.startsWith(`${colName}/`) && val[field] === value && val[f2] === v2) {
                  docs.push({
                    id: key.split('/')[1],
                    data: () => val,
                    ref: {
                      update: async (patch: any) => {
                        mockDb.set(key, { ...val, ...patch });
                      },
                    },
                  });
                }
              }
              return { empty: docs.length === 0, docs, size: docs.length };
            },
          }),
          orderBy: () => ({
            limit: () => ({
              get: async () => {
                const docs: any[] = [];
                for (const [key, val] of mockDb.entries()) {
                  if (key.startsWith(`${colName}/`) && val[field] === value) {
                    docs.push({
                      id: key.split('/')[1],
                      data: () => val,
                    });
                  }
                }
                return { empty: docs.length === 0, docs };
              },
            }),
          }),
          limit: () => ({
            get: async () => {
              const docs: any[] = [];
              for (const [key, val] of mockDb.entries()) {
                if (key.startsWith(`${colName}/`) && val[field] === value) {
                  docs.push({
                    id: key.split('/')[1],
                    data: () => val,
                    ref: {
                      update: async (patch: any) => {
                        mockDb.set(key, { ...val, ...patch });
                      },
                    },
                  });
                }
              }
              return { empty: docs.length === 0, docs };
            },
          }),
        }),
      }),
      batch: () => {
        const operations: any[] = [];
        return {
          set: (docRef: any, data: any) => operations.push({ type: 'set', docRef, data }),
          update: (docRef: any, data: any) => operations.push({ type: 'update', docRef, data }),
          delete: (docRef: any) => operations.push({ type: 'delete', docRef }),
          commit: async () => {
            for (const op of operations) {
              if (op.type === 'set') {
                await op.docRef.set(op.data);
              } else if (op.type === 'update') {
                await op.docRef.update(op.data);
              }
            }
          },
        };
      },
    })),
  };
});

describe('Section 12: Notifications and WhatsApp Integration', () => {
  let notifService: NotificationDomainService;

  beforeEach(() => {
    mockDb.clear();
    notifService = new NotificationDomainService();
  });

  it('1. createNotification persists document and avoids duplicates with durableEventId', async () => {
    const input = {
      recipientUserId: 'USER-101',
      bookingId: 'BK-555',
      type: 'booking_confirmed' as const,
      title: 'Booking Confirmed!',
      message: 'Your stay at Gomti Nagar is set.',
      durableEventId: 'evt_durable_booking_confirmed_101_555',
    };

    const first = await notifService.createNotification(input);
    expect(first.notificationId).toBeDefined();
    expect(first.deliveryStatus).toBe('sent');

    // Attempt duplicate call with same durable event id
    const second = await notifService.createNotification(input);
    expect(second.notificationId).toBe(first.notificationId);

    // Verify outbox_events document exists
    const outboxDoc = mockDb.get('outbox_events/evt_durable_booking_confirmed_101_555');
    expect(outboxDoc).toBeDefined();
    expect(outboxDoc.processed).toBe(true);
  });

  it('2. sendBookingTicket dispatches WhatsApp template with digital PIN and records message document', async () => {
    const waSpy = vi.spyOn(whatsAppMessenger, 'sendBookingTicket').mockResolvedValueOnce(true);

    const waDoc = await notifService.sendBookingTicket({
      recipientUserId: 'CUST-100',
      recipientPhone: '+919876543210',
      bookingId: 'BK-TICKET-77',
      roomTitle: 'Studio Suite',
      checkIn: '2026-11-05 12:00 PM',
      accessPin: 'PIN-9921',
      locationUrl: 'https://maps.google.com/?q=26.85,80.99',
    });

    expect(waSpy).toHaveBeenCalledWith(
      '+919876543210',
      'Studio Suite',
      '2026-11-05 12:00 PM',
      'PIN-9921',
      'https://maps.google.com/?q=26.85,80.99'
    );

    expect(waDoc.status).toBe('sent');
    expect(waDoc.templateName).toBe('booking_confirmation_ticket');
    expect(waDoc.parameters.accessPin).toBe('PIN-9921');

    const storedMsg = mockDb.get(`whatsapp_messages/${waDoc.messageId}`);
    expect(storedMsg).toBeDefined();
    expect(storedMsg.status).toBe('sent');
  });

  it('3. sendOwnerBookingConfirmation alerts host with transparent booking details', async () => {
    const waDoc = await notifService.sendOwnerBookingConfirmation({
      ownerUserId: 'OWNER-200',
      ownerPhone: '+919988776655',
      bookingId: 'BK-OWN-88',
      roomTitle: 'Executive AC Room',
      customerName: 'Aarav Sharma',
      checkIn: '2026-11-06',
      checkOut: '2026-11-08',
      totalPayoutPaise: 380000, // Rs 3,800
    });

    expect(waDoc.templateName).toBe('owner_booking_alert');
    expect(waDoc.parameters.payoutAmount).toBe('Rs. 3800');
    expect(waDoc.status).toBe('sent');
  });

  it('4. sendAuthorizedRoomLocation enforces confirmed stay policy before revealing directions', async () => {
    mockDb.set('bookings/BK-PENDING', {
      bookingId: 'BK-PENDING',
      bookingStatus: 'pending_payment',
    });

    // Should reject unauthorized access to room location for unconfirmed booking
    await expect(
      notifService.sendAuthorizedRoomLocation({
        recipientUserId: 'CUST-1',
        recipientPhone: '+919876543210',
        bookingId: 'BK-PENDING',
        roomTitle: 'Private Flat',
        locationUrl: 'https://maps.google.com',
        addressText: '123 Secret Lane',
      })
    ).rejects.toThrow('Room location is only shared for confirmed stays.');

    // Now test with confirmed booking
    mockDb.set('bookings/BK-CONFIRMED', {
      bookingId: 'BK-CONFIRMED',
      bookingStatus: 'confirmed',
    });

    const waDoc = await notifService.sendAuthorizedRoomLocation({
      recipientUserId: 'CUST-1',
      recipientPhone: '+919876543210',
      bookingId: 'BK-CONFIRMED',
      roomTitle: 'Private Flat',
      locationUrl: 'https://maps.google.com',
      addressText: '123 Secret Lane',
    });

    expect(waDoc.status).toBe('sent');
    expect(waDoc.templateName).toBe('authorized_room_location');
  });

  it('5. FCM registration and dispatch supports multi-device and removes invalid tokens', async () => {
    await fcmService.registerDeviceToken('USER-MULTI', 'fcm_tok_phone_1', 'Pixel 8');
    await fcmService.registerDeviceToken('USER-MULTI', 'fcm_tok_tablet_2', 'iPad Pro');

    const tok1 = mockDb.get('users/USER-MULTI/fcm_tokens/fcm_tok_phone_1');
    const tok2 = mockDb.get('users/USER-MULTI/fcm_tokens/fcm_tok_tablet_2');
    expect(tok1).toBeDefined();
    expect(tok2).toBeDefined();

    // Send push notification
    const res = await fcmService.sendToUser('USER-MULTI', 'Special Offer', 'Stay extended with 20% discount');
    expect(res.successCount).toBe(2);

    // Remove single token
    await fcmService.removeDeviceToken('USER-MULTI', 'fcm_tok_tablet_2');
    const tokRemoved = mockDb.get('users/USER-MULTI/fcm_tokens/fcm_tok_tablet_2');
    expect(tokRemoved).toBeUndefined();
  });

  it('6. markNotificationRead and markAllNotificationsRead updates status cleanly', async () => {
    mockDb.set('notifications/NOTIF-1', {
      notificationId: 'NOTIF-1',
      recipientUserId: 'USER-READ-TEST',
      read: false,
    });
    mockDb.set('notifications/NOTIF-2', {
      notificationId: 'NOTIF-2',
      recipientUserId: 'USER-READ-TEST',
      read: false,
    });

    await notifService.markNotificationRead('NOTIF-1', 'USER-READ-TEST');
    const doc1 = mockDb.get('notifications/NOTIF-1');
    expect(doc1.read).toBe(true);

    const markedCount = await notifService.markAllNotificationsRead('USER-READ-TEST');
    expect(markedCount).toBe(1); // Only NOTIF-2 remained unread

    const doc2 = mockDb.get('notifications/NOTIF-2');
    expect(doc2.read).toBe(true);
  });
});

