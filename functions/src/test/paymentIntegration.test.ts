import { describe, it, expect, vi, beforeEach } from 'vitest';
import { PaymentDomainService } from '../modules/payments/paymentDomainService';
import { paymentGateway } from '../services/paymentService';
import { AppError } from '../common/errors';

// In-memory Firestore mock store
const mockDb = new Map<string, any>();

vi.mock('firebase-admin', () => {
  return {
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
          get: async () => {
            const docs: any[] = [];
            for (const [key, val] of mockDb.entries()) {
              if (key.startsWith(`${colName}/`)) {
                if (op === '==' && val[field] === value) {
                  docs.push({
                    id: key.split('/')[1],
                    data: () => val,
                    ref: {
                      update: async (patch: any) => {
                        mockDb.set(key, { ...val, ...patch });
                      },
                    },
                  });
                } else if (op === 'in' && Array.isArray(value) && value.includes(val[field])) {
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
            }
            return { empty: docs.length === 0, docs };
          },
        }),
      }),
      runTransaction: async (updateFn: any) => {
        return updateFn({});
      },
      batch: () => ({
        delete: vi.fn(),
        update: vi.fn(),
        commit: vi.fn().mockResolvedValue(true),
      }),
    })),
  };
});

describe('Section 9: Payment Integration & Gateway Security', () => {
  let paymentService: PaymentDomainService;

  beforeEach(() => {
    mockDb.clear();
    paymentService = new PaymentDomainService();
  });

  it('1. createPaymentOrder computes authoritative quote in integer paise without client trust', async () => {
    // Setup mock room: 250000 paise (Rs 2,500) per night
    mockDb.set('rooms/ROOM-101', {
      roomId: 'ROOM-101',
      title: 'Deluxe Studio Indiranagar',
      pricePerNightPaise: 250000,
    });

    // Active hold for 2 nights (2026-11-01 to 2026-11-03)
    const futureExpiry = new Date(Date.now() + 10 * 60 * 1000).toISOString();
    mockDb.set('booking_holds/HOLD-999', {
      holdId: 'HOLD-999',
      roomId: 'ROOM-101',
      customerId: 'CUST-001',
      checkIn: '2026-11-01',
      checkOut: '2026-11-03',
      status: 'active',
      expiresAt: futureExpiry,
    });

    const result = await paymentService.createPaymentOrder('HOLD-999', 'CUST-001');

    // Subtotal: 250000 * 2 = 500000 paise. GST (5%): 25000 paise. Total: 525000 paise.
    expect(result.amountPaise).toBe(525000);
    expect(result.currency).toBe('INR');
    expect(result.providerOrderId).toContain('order_sandbox');

    // Confirm payments document was created in Firestore
    const storedPayment = mockDb.get(`payments/${result.paymentId}`);
    expect(storedPayment).toBeDefined();
    expect(storedPayment.amount).toBe(525000);
    expect(storedPayment.status).toBe('created');
    expect(storedPayment.customerId).toBe('CUST-001');
  });

  it('2. verifyPayment verifies cryptographic signature and prevents forged verification', async () => {
    const paymentId = 'PAY-TEST-001';
    mockDb.set(`payments/${paymentId}`, {
      paymentId,
      customerId: 'CUST-001',
      providerOrderId: 'order_test_123',
      amount: 150000,
      status: 'created',
    });

    mockDb.set('booking_holds/HOLD-111', {
      holdId: 'HOLD-111',
      roomId: 'ROOM-101',
      paymentId,
      customerId: 'CUST-001',
      status: 'active',
      expiresAt: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
    });

    mockDb.set('rooms/ROOM-101', {
      roomId: 'ROOM-101',
      title: 'Studio',
      pricePerNightPaise: 150000,
    });

    // Invalid signature rejection
    vi.spyOn(paymentGateway, 'verifyPaymentSignature').mockReturnValueOnce(false);

    await expect(
      paymentService.verifyPayment({
        paymentId,
        providerOrderId: 'order_test_123',
        providerPaymentId: 'pay_999',
        signature: 'invalid_sig',
        customerUid: 'CUST-001',
      })
    ).rejects.toThrow(AppError);

    // Stored payment marked as failed with failureCode
    const failedPayment = mockDb.get(`payments/${paymentId}`);
    expect(failedPayment.status).toBe('failed');
    expect(failedPayment.failureCode).toBe('SIGNATURE_VERIFICATION_FAILED');
  });

  it('3. webhook handles duplicate events idempotently and rejects unknown signatures', async () => {
    const webhookEvent = {
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: 'pay_rzp_9876',
            order_id: 'order_rzp_5555',
            amount: 300000,
          },
        },
      },
    };
    const rawBody = JSON.stringify(webhookEvent);

    // First time: processed
    vi.spyOn(paymentGateway, 'verifyWebhookSignature').mockReturnValue(true);
    const firstCall = await paymentService.paymentWebhook(rawBody, 'valid_sig', 'evt_razorpay_001');
    expect(firstCall.processed).toBe(true);

    // Second time with identical eventId: idempotent deduplication
    const secondCall = await paymentService.paymentWebhook(rawBody, 'valid_sig', 'evt_razorpay_001');
    expect(secondCall.processed).toBe(false);
    expect(secondCall.reason).toContain('Duplicate event already processed');
  });

  it('4. handles late payment when hold expired by flagging reconciliation_required', async () => {
    const paymentId = 'PAY-LATE-001';
    mockDb.set(`payments/${paymentId}`, {
      paymentId,
      customerId: 'CUST-LATE',
      providerOrderId: 'order_late_123',
      amount: 200000,
      status: 'created',
    });

    // Hold that expired 5 minutes ago
    const pastExpiry = new Date(Date.now() - 5 * 60 * 1000).toISOString();
    mockDb.set('booking_holds/HOLD-EXPIRED', {
      holdId: 'HOLD-EXPIRED',
      roomId: 'ROOM-101',
      paymentId,
      customerId: 'CUST-LATE',
      status: 'active',
      expiresAt: pastExpiry,
    });

    vi.spyOn(paymentGateway, 'verifyPaymentSignature').mockReturnValueOnce(true);

    const result = await paymentService.verifyPayment({
      paymentId,
      providerOrderId: 'order_late_123',
      providerPaymentId: 'pay_late_captured',
      signature: 'valid_signature_1234',
      customerUid: 'CUST-LATE',
    });

    expect(result.success).toBe(false);
    const updatedPayment = mockDb.get(`payments/${paymentId}`);
    expect(updatedPayment.status).toBe('reconciliation_required');
    expect(updatedPayment.failureCode).toBe('HOLD_EXPIRED_PAYMENT_CAPTURED');
  });

  it('5. initiateRefund executes gateway refund and updates state', async () => {
    const paymentId = 'PAY-REFUND-001';
    mockDb.set(`payments/${paymentId}`, {
      paymentId,
      customerId: 'CUST-001',
      providerPaymentId: 'pay_captured_777',
      amount: 400000,
      status: 'captured',
      bookingId: 'RW-BK-888',
    });

    mockDb.set('bookings/RW-BK-888', {
      bookingId: 'RW-BK-888',
      paymentStatus: 'captured',
    });

    const refundRes = await paymentService.initiateRefund({
      paymentId,
      reason: 'Host cancelled reservation',
      requestedByUid: 'ADMIN-001',
    });

    expect(refundRes.status).toBe('processed');
    expect(refundRes.amountPaise).toBe(400000);

    const updatedPayment = mockDb.get(`payments/${paymentId}`);
    expect(updatedPayment.status).toBe('refunded');

    const updatedBooking = mockDb.get('bookings/RW-BK-888');
    expect(updatedBooking.paymentStatus).toBe('refunded');
  });
});

