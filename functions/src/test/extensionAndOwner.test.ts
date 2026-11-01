import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ExtensionDomainService } from '../modules/extensions/extensionDomainService';
import { OwnerDomainService } from '../modules/owner/ownerDomainService';
import { inventoryLockService } from '../modules/availability/inventoryLockService';
import { AppError } from '../common/errors';

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
        }),
        where: (field: string, op: string, value: any) => ({
          where: (f2: string, _op2: string, v2: any) => ({
            get: async () => {
              const docs: any[] = [];
              for (const [key, val] of mockDb.entries()) {
                if (key.startsWith(`${colName}/`) && val[field] === value) {
                  if (Array.isArray(v2) ? v2.includes(val[f2]) : val[f2] === v2) {
                    docs.push({
                      id: key.split('/')[1],
                      data: () => val,
                      ref: {
                        update: async (patch: any) => mockDb.set(key, { ...val, ...patch }),
                      },
                    });
                  }
                }
              }
              return { empty: docs.length === 0, docs, size: docs.length };
            },
          }),
          get: async () => {
            const docs: any[] = [];
            for (const [key, val] of mockDb.entries()) {
              if (key.startsWith(`${colName}/`)) {
                if (op === '==' && val[field] === value) {
                  docs.push({
                    id: key.split('/')[1],
                    data: () => val,
                    ref: { update: async (patch: any) => mockDb.set(key, { ...val, ...patch }) },
                  });
                } else if (op === 'in' && Array.isArray(value) && value.includes(val[field])) {
                  docs.push({
                    id: key.split('/')[1],
                    data: () => val,
                    ref: { update: async (patch: any) => mockDb.set(key, { ...val, ...patch }) },
                  });
                }
              }
            }
            return { empty: docs.length === 0, docs, size: docs.length };
          },
          orderBy: () => ({
            get: async () => {
              const docs: any[] = [];
              for (const [key, val] of mockDb.entries()) {
                if (key.startsWith(`${colName}/`) && val[field] === value) {
                  docs.push({ id: key.split('/')[1], data: () => val });
                }
              }
              return { empty: docs.length === 0, docs, size: docs.length };
            },
          }),
        }),
      }),
      runTransaction: async (txFn: any) => {
        const tx = {
          get: async (docRef: any) => {
            const path = docRef.id ? docRef.id : 'unknown';
            return {
              exists: Array.from(mockDb.keys()).some(k => k.endsWith(path)),
              data: () => null,
            };
          },
          set: (docRef: any, data: any) => {
            mockDb.set(`trans_${Date.now()}`, data);
          },
          update: (docRef: any, data: any) => {
            // Transaction mock update
          },
        };
        return txFn(tx);
      },
      batch: () => ({
        update: vi.fn(),
        delete: vi.fn(),
        commit: vi.fn().mockResolvedValue(true),
      }),
    })),
  };
});

describe('Section 13: Stay Extension Priority', () => {
  let extService: ExtensionDomainService;

  beforeEach(() => {
    mockDb.clear();
    extService = new ExtensionDomainService();
  });

  it('1. createExtensionOffer creates a time-limited offer with 15% discount when dates are available', async () => {
    mockDb.set('bookings/BK-CONF', {
      bookingId: 'BK-CONF',
      roomId: 'ROOM-55',
      customerId: 'CUST-EXT',
      ownerId: 'OWNER-7',
      bookingStatus: 'confirmed',
      checkOut: '2026-11-10',
      totalAmountPaise: 400000,
    });

    mockDb.set('rooms/ROOM-55', {
      roomId: 'ROOM-55',
      pricePerNightPaise: 200000, // Rs 2,000 / night
    });

    vi.spyOn(inventoryLockService, 'checkNightlyAvailability').mockResolvedValueOnce(true);

    const offer = await extService.createExtensionOffer({
      bookingId: 'BK-CONF',
      extensionNights: 1,
      discountPercentage: 15,
    });

    expect(offer.offerId).toBeDefined();
    expect(offer.status).toBe('offered');
    expect(offer.requestedCheckIn).toBe('2026-11-10');
    expect(offer.requestedCheckOut).toBe('2026-11-11');
    // Rs 2,000 * 0.85 = Rs 1,700 (170000 paise) + 5% tax (8500 paise) = 178500 paise
    expect(offer.quotedAmount).toBe(178500);

    const storedOffer = mockDb.get(`extension_offers/${offer.offerId}`);
    expect(storedOffer).toBeDefined();
    expect(storedOffer.customerId).toBe('CUST-EXT');
  });

  it('2. reject extension creation if dates conflict with another reservation', async () => {
    mockDb.set('bookings/BK-BUSY', {
      bookingId: 'BK-BUSY',
      roomId: 'ROOM-BUSY',
      customerId: 'CUST-1',
      bookingStatus: 'confirmed',
      checkOut: '2026-11-10',
    });

    vi.spyOn(inventoryLockService, 'checkNightlyAvailability').mockResolvedValueOnce(false);

    await expect(
      extService.createExtensionOffer({
        bookingId: 'BK-BUSY',
      })
    ).rejects.toThrow(AppError);
  });

  it('3. acceptExtensionOffer validates offer status and backend expiration', async () => {
    const offerId = 'EXT-EXPIRED-TEST';
    mockDb.set(`extension_offers/${offerId}`, {
      offerId,
      customerId: 'CUST-A',
      roomId: 'ROOM-1',
      status: 'offered',
      expiresAt: new Date(Date.now() - 60000).toISOString(), // Expired
    });

    await expect(
      extService.acceptExtensionOffer(offerId, 'CUST-A')
    ).rejects.toThrow('Extension offer has expired.');
  });
});

describe('Section 14: Owner Services & Dashboard Metrics', () => {
  let ownerService: OwnerDomainService;

  beforeEach(() => {
    mockDb.clear();
    ownerService = new OwnerDomainService();
  });

  it('1. getOwnerDashboard computes metrics strictly from authoritative records', async () => {
    const ownerId = 'OWNER-TOP';

    // 2 listings: 1 published, 1 pending_review
    mockDb.set('rooms/RM-1', { roomId: 'RM-1', ownerId, listingStatus: 'published' });
    mockDb.set('rooms/RM-2', { roomId: 'RM-2', ownerId, listingStatus: 'pending_review' });

    // 2 bookings: 1 confirmed (Rs 3,000), 1 completed (Rs 5,000)
    mockDb.set('bookings/BK-1', {
      bookingId: 'BK-1',
      ownerId,
      bookingStatus: 'confirmed',
      totalAmountPaise: 300000,
      feesPaise: 0,
    });
    mockDb.set('bookings/BK-2', {
      bookingId: 'BK-2',
      ownerId,
      bookingStatus: 'completed',
      totalAmountPaise: 500000,
      feesPaise: 0,
    });

    // 1 completed payout (Rs 4,000)
    mockDb.set('owner_payouts/PAYOUT-1', {
      payoutId: 'PAYOUT-1',
      ownerId,
      status: 'completed',
      netAmount: 400000,
    });

    const metrics = await ownerService.getOwnerDashboard(ownerId);

    expect(metrics.totalListings).toBe(2);
    expect(metrics.publishedListings).toBe(1);
    expect(metrics.pendingListings).toBe(1);
    expect(metrics.upcomingBookings).toBe(1);
    expect(metrics.completedBookings).toBe(1);
    expect(metrics.grossBookingValuePaise).toBe(800000); // Rs 8,000
    expect(metrics.netEarningsPaise).toBe(800000);
    expect(metrics.completedPayoutsPaise).toBe(400000); // Rs 4,000
  });

  it('2. createRoomBlock prevents blocking dates that conflict with confirmed bookings', async () => {
    mockDb.set('rooms/RM-10', {
      roomId: 'RM-10',
      ownerId: 'OWNER-BLOCK',
    });

    vi.spyOn(inventoryLockService, 'checkNightlyAvailability').mockResolvedValueOnce(false);

    await expect(
      ownerService.createRoomBlock({
        roomId: 'RM-10',
        ownerId: 'OWNER-BLOCK',
        startDate: '2026-11-01',
        endDate: '2026-11-03',
        reason: 'maintenance',
      })
    ).rejects.toThrow('Cannot block dates: dates conflict with an existing reservation or hold.');
  });
});
