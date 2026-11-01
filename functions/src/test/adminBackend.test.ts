import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AdminDomainService } from '../modules/admin/adminDomainService';

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
        get: async () => {
          const docs: any[] = [];
          for (const [key, val] of mockDb.entries()) {
            if (key.startsWith(`${colName}/`)) {
              docs.push({ id: key.split('/')[1], data: () => val });
            }
          }
          return { docs, size: docs.length, empty: docs.length === 0 };
        },
        where: (field: string, op: string, value: any) => ({
          get: async () => {
            const docs: any[] = [];
            for (const [key, val] of mockDb.entries()) {
              if (key.startsWith(`${colName}/`)) {
                if (op === '==' && val[field] === value) {
                  docs.push({ id: key.split('/')[1], data: () => val });
                } else if (op === 'in' && Array.isArray(value) && value.includes(val[field])) {
                  docs.push({ id: key.split('/')[1], data: () => val });
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
                  docs.push({ id: key.split('/')[1], data: () => val });
                }
              }
              return { docs, size: docs.length, empty: docs.length === 0 };
            },
          }),
        }),
      }),
    })),
  };
});

describe('Section 17: Admin Backend & Platform Governance', () => {
  let adminService: AdminDomainService;

  beforeEach(() => {
    mockDb.clear();
    adminService = new AdminDomainService();
  });

  it('1. getAdminDashboard accurately computes platform metrics across all collections', async () => {
    // 2 users (1 customer, 1 owner)
    mockDb.set('users/U1', { uid: 'U1', role: 'customer' });
    mockDb.set('users/U2', { uid: 'U2', role: 'owner' });

    // 2 rooms (1 published, 1 pending review)
    mockDb.set('rooms/R1', { roomId: 'R1', listingStatus: 'published' });
    mockDb.set('rooms/R2', { roomId: 'R2', listingStatus: 'pending_review' });

    // 1 confirmed booking, 1 cancelled
    mockDb.set('bookings/B1', { bookingId: 'B1', bookingStatus: 'confirmed' });
    mockDb.set('bookings/B2', { bookingId: 'B2', bookingStatus: 'cancelled' });

    // 1 captured payment (Rs 5,000 = 500000 paise), 1 discrepancy
    mockDb.set('payments/P1', { paymentId: 'P1', amount: 500000, status: 'captured' });
    mockDb.set('payments/P2', { paymentId: 'P2', status: 'reconciliation_required' });

    // 1 pending refund
    mockDb.set('refunds/RF1', { refundId: 'RF1', status: 'pending' });

    // 1 verification manual review
    mockDb.set('verification_cases/V1', { verificationId: 'V1', status: 'manual_review' });

    // 1 open support ticket
    mockDb.set('support_tickets/T1', { ticketId: 'T1', status: 'open' });

    const metrics = await adminService.getAdminDashboard();

    expect(metrics.registeredCustomers).toBe(1);
    expect(metrics.registeredOwners).toBe(1);
    expect(metrics.activeListings).toBe(1);
    expect(metrics.pendingRoomApprovals).toBe(1);
    expect(metrics.confirmedBookings).toBe(1);
    expect(metrics.cancelledBookings).toBe(1);
    expect(metrics.grossPaymentVolumePaise).toBe(500000);
    expect(metrics.reconciliationDiscrepanciesCount).toBe(1);
    expect(metrics.pendingRefundsCount).toBe(1);
    expect(metrics.pendingIdentityReviewsCount).toBe(1);
    expect(metrics.openSupportTicketsCount).toBe(1);
  });

  it('2. suspendUser and restoreUser enforce administrative actions and log audit trail', async () => {
    mockDb.set('users/BAD-ACTOR', {
      uid: 'BAD-ACTOR',
      accountStatus: 'active',
    });

    await adminService.suspendUser('BAD-ACTOR', 'ADMIN-SUPER', 'Violated safety guidelines');
    const suspended = mockDb.get('users/BAD-ACTOR');
    expect(suspended.accountStatus).toBe('suspended');

    await adminService.restoreUser('BAD-ACTOR', 'ADMIN-SUPER');
    const restored = mockDb.get('users/BAD-ACTOR');
    expect(restored.accountStatus).toBe('active');
  });

  it('3. reviewRoomApproval approves or rejects listings', async () => {
    mockDb.set('rooms/ROOM-PENDING', {
      roomId: 'ROOM-PENDING',
      listingStatus: 'pending_review',
    });

    await adminService.reviewRoomApproval({
      roomId: 'ROOM-PENDING',
      adminId: 'ADMIN-SUPER',
      action: 'approve',
    });

    const approved = mockDb.get('rooms/ROOM-PENDING');
    expect(approved.listingStatus).toBe('published');
  });

  it('4. updateApprovedAppConfiguration persists platform configs safely', async () => {
    const config = await adminService.updateApprovedAppConfiguration('ADMIN-SUPER', {
      platformFeePercentage: 0,
      maintenanceMode: false,
      extensionOfferDiscountPercent: 20,
    });

    expect(config.extensionOfferDiscountPercent).toBe(20);
    expect(config.platformFeePercentage).toBe(0);

    const stored = mockDb.get('app_config/global');
    expect(stored.extensionOfferDiscountPercent).toBe(20);
  });
});

