import { describe, it, expect, vi, beforeEach } from 'vitest';
import { CancellationRefundService } from '../modules/refunds/cancellationRefundService';
import { IdentityVerificationService } from '../modules/verification/identityVerificationService';
import { paymentGateway } from '../services/paymentService';

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
        where: (field: string, _op: string, value: any) => ({
          limit: (_limitNum: number) => ({
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
      batch: () => ({
        delete: (docRef: any) => {
          mockDb.delete(docRef.path || 'deleted');
        },
        update: vi.fn(),
        commit: vi.fn().mockResolvedValue(true),
      }),
    })),
  };
});

describe('Section 10: Cancellation & Refunds', () => {
  let refundService: CancellationRefundService;

  beforeEach(() => {
    mockDb.clear();
    refundService = new CancellationRefundService();
  });

  it('1. calculates refund eligibility using saved policy snapshot (> 24h = 100% refund)', () => {
    const booking: any = {
      bookingId: 'RW-TEST-CANCEL',
      checkIn: '2026-11-10T12:00:00Z',
      totalAmountPaise: 300000, // Rs 3,000
    };

    const policy: any = {
      policyId: 'flexible',
      rules: [
        { hoursBeforeCheckIn: 24, refundPercentage: 100 },
        { hoursBeforeCheckIn: 12, refundPercentage: 50 },
        { hoursBeforeCheckIn: 0, refundPercentage: 0 },
      ],
    };

    // Cancellation 48 hours prior to check-in
    const cancellationTime = new Date('2026-11-08T12:00:00Z');
    const result = refundService.calculateRefundEligibility(booking, policy, cancellationTime);

    expect(result.refundPercentage).toBe(100);
    expect(result.refundAmountPaise).toBe(300000);
  });

  it('2. calculates partial refund (< 24h but > 12h = 50% refund)', () => {
    const booking: any = {
      bookingId: 'RW-TEST-CANCEL-2',
      checkIn: '2026-11-10T12:00:00Z',
      totalAmountPaise: 400000, // Rs 4,000
    };

    const policy: any = {
      policyId: 'flexible',
      rules: [
        { hoursBeforeCheckIn: 24, refundPercentage: 100 },
        { hoursBeforeCheckIn: 12, refundPercentage: 50 },
        { hoursBeforeCheckIn: 0, refundPercentage: 0 },
      ],
    };

    // Cancellation 18 hours prior to check-in
    const cancellationTime = new Date('2026-11-09T18:00:00Z');
    const result = refundService.calculateRefundEligibility(booking, policy, cancellationTime);

    expect(result.refundPercentage).toBe(50);
    expect(result.refundAmountPaise).toBe(200000);
  });

  it('3. cancelBooking transitions status, creates refund document and releases inventory', async () => {
    const bookingId = 'RW-CANCEL-999';
    mockDb.set(`bookings/${bookingId}`, {
      bookingId,
      customerId: 'CUST-001',
      ownerId: 'OWNER-001',
      roomId: 'ROOM-101',
      roomTitleSnapshot: 'Deluxe Studio',
      checkIn: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
      checkOut: new Date(Date.now() + 72 * 60 * 60 * 1000).toISOString(),
      bookingStatus: 'confirmed',
      paymentStatus: 'captured',
      paymentId: 'PAY-111',
      totalAmountPaise: 500000,
      cancellationPolicySnapshot: 'flexible',
    });

    mockDb.set('payments/PAY-111', {
      paymentId: 'PAY-111',
      providerPaymentId: 'pay_rzp_mock_live',
      amount: 500000,
      status: 'captured',
    });

    vi.spyOn(paymentGateway, 'initiateRefund').mockResolvedValueOnce({
      id: 'rfnd_rzp_123',
      amount: 500000,
      currency: 'INR',
      payment_id: 'pay_rzp_mock_live',
      status: 'processed',
    });

    const res = await refundService.cancelBooking({
      bookingId,
      requestedByUid: 'CUST-001',
      reason: 'Travel plans shifted',
    });

    expect(res.bookingStatus).toBe('cancelled');
    expect(res.refundStatus).toBe('succeeded');
    expect(res.refundAmountPaise).toBe(500000);
    expect(res.inventoryReleased).toBe(true);

    // Stored booking status updated
    const updatedBooking = mockDb.get(`bookings/${bookingId}`);
    expect(updatedBooking.bookingStatus).toBe('cancelled');
    expect(updatedBooking.paymentStatus).toBe('refunded');
  });
});

describe('Section 11: Age & Identity Verification', () => {
  let verifService: IdentityVerificationService;

  beforeEach(() => {
    mockDb.clear();
    verifService = new IdentityVerificationService();
  });

  it('1. calculates age accurately and sets status according to configured policy threshold', async () => {
    mockDb.set('users/USER-ADULT', {
      uid: 'USER-ADULT',
      fullName: 'Vikram Mehta',
      identityVerificationStatus: 'not_started',
    });

    // 25 years old
    const result = await verifService.startVerification({
      userId: 'USER-ADULT',
      verificationType: 'aadhaar',
      consentVersion: 'v1.0',
      documentNumberMasked: 'XXXX-XXXX-9912',
      dateOfBirth: '2001-05-15',
      minimumAgePolicy: 18,
    });

    expect(result.ageEligible).toBe(true);
    expect(result.status).toBe('verified');

    // Case document is saved in `verification_cases` collection
    const storedCase = mockDb.get(`verification_cases/${result.verificationId}`);
    expect(storedCase).toBeDefined();
    expect(storedCase.ageVerified).toBe(true);
    expect(storedCase.minimumAgeRequired).toBe(18);
    expect(storedCase.retentionUntil).toBeDefined();
  });

  it('2. rejects verification if applicant is below the configured minimum age policy', async () => {
    mockDb.set('users/USER-MINOR', {
      uid: 'USER-MINOR',
      fullName: 'Rahul Junior',
      identityVerificationStatus: 'not_started',
    });

    // 16 years old
    const result = await verifService.startVerification({
      userId: 'USER-MINOR',
      verificationType: 'driving_license',
      consentVersion: 'v1.0',
      documentNumberMasked: 'UP32-XXXX-1122',
      dateOfBirth: '2010-01-01',
      minimumAgePolicy: 18,
    });

    expect(result.ageEligible).toBe(false);
    expect(result.status).toBe('rejected');

    const updatedUser = mockDb.get('users/USER-MINOR');
    expect(updatedUser.ageEligibilityStatus).toBe('ineligible');
  });

  it('3. supports admin manual review fallback', async () => {
    const verificationId = 'VERIF-MANUAL-001';
    mockDb.set(`verification_cases/${verificationId}`, {
      verificationId,
      userId: 'USER-NEEDS-REVIEW',
      status: 'manual_review',
    });

    mockDb.set('users/USER-NEEDS-REVIEW', {
      uid: 'USER-NEEDS-REVIEW',
      identityVerificationStatus: 'manual_review',
    });

    await verifService.adminReviewVerification({
      verificationId,
      adminUid: 'ADMIN-SUPER',
      decision: 'approve',
    });

    const updatedCase = mockDb.get(`verification_cases/${verificationId}`);
    expect(updatedCase.status).toBe('verified');
    expect(updatedCase.reviewedBy).toBe('ADMIN-SUPER');

    const updatedUser = mockDb.get('users/USER-NEEDS-REVIEW');
    expect(updatedUser.identityVerificationStatus).toBe('verified');
  });
});
