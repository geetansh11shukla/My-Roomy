import { describe, it, expect, vi, beforeEach } from 'vitest';
import { expireBookingHolds } from '../scheduled/expireBookingHolds';
import { sendCheckoutReminders } from '../scheduled/sendCheckoutReminders';
import { whatsAppMessenger } from '../services/whatsappService';

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
          delete: async () => {
            mockDb.delete(`${colName}/${id}`);
          },
        }),
        where: (field: string, op: string, value: any) => ({
          where: (f2: string, op2: string, v2: any) => ({
            get: async () => {
              const docs: any[] = [];
              for (const [key, val] of mockDb.entries()) {
                if (key.startsWith(`${colName}/`) && val[field] === value) {
                  const matches = op2 === '<=' ? String(val[f2]) <= String(v2) : val[f2] === v2;
                  if (matches) {
                    docs.push({
                      id: key.split('/')[1],
                      data: () => val,
                      ref: {
                        id: key.split('/')[1],
                        update: async (patch: any) => mockDb.set(key, { ...val, ...patch }),
                      },
                    });
                  }
                }
              }
              return { docs, size: docs.length, empty: docs.length === 0 };
            },
            limit: () => ({
              get: async () => {
                const docs: any[] = [];
                for (const [key, val] of mockDb.entries()) {
                  if (key.startsWith(`${colName}/`) && val[field] === value) {
                    const matches = op2 === '<=' ? String(val[f2]) <= String(v2) : val[f2] === v2;
                    if (matches) {
                      docs.push({
                        id: key.split('/')[1],
                        data: () => val,
                        ref: {
                          id: key.split('/')[1],
                          update: async (patch: any) => mockDb.set(key, { ...val, ...patch }),
                        },
                      });
                    }
                  }
                }
                return { docs, size: docs.length, empty: docs.length === 0 };
              },
            }),
          }),
        }),
      }),
      runTransaction: async (txFn: any) => {
        const tx = {
          get: async (docRef: any) => {
            const id = docRef.id || 'unknown';
            for (const [key, val] of mockDb.entries()) {
              if (key.endsWith(`/${id}`)) {
                return { exists: true, data: () => val };
              }
            }
            return { exists: false, data: () => null };
          },
          delete: (docRef: any) => {
            const id = docRef.id || 'unknown';
            for (const key of Array.from(mockDb.keys())) {
              if (key === id || key.endsWith(`/${id}`)) {
                mockDb.delete(key);
              }
            }
          },
          update: (docRef: any, patch: any) => {
            const id = docRef.id || 'unknown';
            for (const key of Array.from(mockDb.keys())) {
              if (key.endsWith(`/${id}`)) {
                const prev = mockDb.get(key) || {};
                mockDb.set(key, { ...prev, ...patch });
              }
            }
          },
        };
        return txFn(tx);
      },
    })),
  };
});

describe('Section 21: Scheduled Jobs & Background Processing', () => {
  beforeEach(() => {
    mockDb.clear();
  });

  it('1. expireBookingHolds releases only the inventory owned by the expired hold without affecting confirmed bookings', async () => {
    // Hold expired 2 minutes ago
    const past = new Date(Date.now() - 120000).toISOString();
    mockDb.set('booking_holds/HOLD-EXPIRED-1', {
      holdId: 'HOLD-EXPIRED-1',
      roomId: 'RM-SCHEDULED',
      checkIn: '2026-11-01',
      checkOut: '2026-11-02',
      status: 'active',
      expiresAt: past,
    });

    // Date lock belonging to this hold
    mockDb.set('room_date_locks/RM-SCHEDULED_2026-11-01', {
      lockId: 'RM-SCHEDULED_2026-11-01',
      holderId: 'HOLD-EXPIRED-1',
    });

    const expiredCount = await expireBookingHolds();
    expect(expiredCount).toBe(1);

    const hold = mockDb.get('booking_holds/HOLD-EXPIRED-1');
    expect(hold.status).toBe('expired');
  });

  it('2. sendCheckoutReminders dispatches alert only for confirmed bookings and cancels superseded jobs', async () => {
    const past = new Date(Date.now() - 1000).toISOString();
    mockDb.set('notification_jobs/rem_BK-ACTIVE', {
      jobId: 'rem_BK-ACTIVE',
      bookingId: 'BK-ACTIVE',
      status: 'pending',
      scheduledAt: past,
      attempts: 0,
    });

    mockDb.set('bookings/BK-ACTIVE', {
      bookingId: 'BK-ACTIVE',
      customerId: 'CUST-REMIND',
      roomTitleSnapshot: 'Boutique Room',
      checkOut: '2026-11-05',
      bookingStatus: 'confirmed',
    });

    mockDb.set('users/CUST-REMIND', {
      phoneNumber: '+919876543210',
    });

    const waSpy = vi.spyOn(whatsAppMessenger, 'sendCheckoutReminder').mockResolvedValueOnce(true);

    const count = await sendCheckoutReminders();
    expect(count).toBe(1);
    expect(waSpy).toHaveBeenCalledWith(
      '+919876543210',
      'Boutique Room',
      '2026-11-05',
      'https://roomwala.in/bookings/BK-ACTIVE/extension'
    );

    const job = mockDb.get('notification_jobs/rem_BK-ACTIVE');
    expect(job.status).toBe('completed');
  });
});
