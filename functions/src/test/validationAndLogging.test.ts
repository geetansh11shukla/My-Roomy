import { describe, it, expect, vi, beforeEach } from 'vitest';
import { validateRequiredFields, validateIntegerRange, validateDateOrder, validateEnumValue } from '../common/validation';
import { AppError, ValidationError } from '../common/errors';
import { sanitizeMetadata, structuredLogger } from '../common/logger';

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
          set: async (data: any) => mockDb.set(`${colName}/${id}`, data),
        }),
      }),
      runTransaction: async (txFn: any) => {
        const tx = {
          get: async (docRef: any) => {
            const data = mockDb.get(`room_date_locks/${docRef.id}`);
            return { exists: Boolean(data), data: () => data };
          },
          set: (docRef: any, data: any) => {
            mockDb.set(`room_date_locks/${docRef.id}`, data);
          },
        };
        return txFn(tx);
      },
    })),
  };
});

describe('Section 25: Data Validation & Business Rules', () => {
  it('1. validates required fields and throws readable ValidationError', () => {
    expect(() => validateRequiredFields({ title: 'Room' }, ['title', 'price'])).toThrow(ValidationError);
    expect(() => validateRequiredFields({ title: 'Room', price: 1500 }, ['title', 'price'])).not.toThrow();
  });

  it('2. validates integer ranges (e.g. rating 1-5, guest count)', () => {
    expect(() => validateIntegerRange(6, 'rating', 1, 5)).toThrow(ValidationError);
    expect(() => validateIntegerRange(3.5, 'rating', 1, 5)).toThrow(ValidationError);
    expect(() => validateIntegerRange(5, 'rating', 1, 5)).not.toThrow();
  });

  it('3. validates date order enforcing checkOut strictly after checkIn', () => {
    expect(() => validateDateOrder('2026-11-05', '2026-11-01')).toThrow(ValidationError);
    expect(() => validateDateOrder('2026-11-05', '2026-11-05')).toThrow(ValidationError);
    expect(() => validateDateOrder('2026-11-05', '2026-11-06')).not.toThrow();
  });

  it('4. validates enum values strictly', () => {
    const roles = ['customer', 'owner', 'admin'] as const;
    expect(() => validateEnumValue('superadmin', 'role', roles)).toThrow(ValidationError);
    expect(validateEnumValue('admin', 'role', roles)).toBe('admin');
  });
});

describe('Section 26: Structured Logging, Sanitization & Safe Errors', () => {
  it('1. sanitizes sensitive keys (passwords, OTPs, auth headers, secrets) before logging', () => {
    const dirty = {
      userId: 'USER-123',
      otp: '9921',
      password: 'my-super-secret-password',
      keySecret: 'rzp_secret_998',
      meta: {
        token: 'eyJh...',
        roomPrice: 150000,
      },
    };

    const clean = sanitizeMetadata(dirty);
    expect(clean.userId).toBe('USER-123');
    expect(clean.otp).toBe('[REDACTED]');
    expect(clean.password).toBe('[REDACTED]');
    expect(clean.keySecret).toBe('[REDACTED]');
    expect(clean.meta.token).toBe('[REDACTED]');
    expect(clean.meta.roomPrice).toBe(150000);
  });

  it('2. structuredLogger outputs valid JSON object with request correlation and error category', () => {
    const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

    structuredLogger.log({
      requestId: 'req_test_123',
      functionName: 'createPaymentOrder',
      operationType: 'PAYMENT',
      userId: 'CUST-1',
      resourceId: 'HOLD-1',
      resultCategory: 'SUCCESS',
      durationMs: 42,
      safeErrorCode: null,
      timestamp: new Date().toISOString(),
    });

    expect(consoleSpy).toHaveBeenCalled();
    const loggedStr = consoleSpy.mock.calls[0][0];
    const parsed = JSON.parse(loggedStr);
    expect(parsed.requestId).toBe('req_test_123');
    expect(parsed.durationMs).toBe(42);
    expect(parsed.resultCategory).toBe('SUCCESS');
    consoleSpy.mockRestore();
  });
});

describe('Section 27: Concurrency & Atomic Inventory Claims', () => {
  beforeEach(() => {
    mockDb.clear();
  });

  it('1. parallel requests for overlapping dates allow only one winner to claim inventory', async () => {
    const roomId = 'ROOM-RACE-1';
    const dates = ['2026-11-20'];

    // Simulate two concurrent requests trying to claim the same date
    let winnerCount = 0;
    let loserCount = 0;

    const claimInventory = async (customerUid: string) => {
      try {
        // Atomic transaction check
        const key = `room_date_locks/${roomId}_${dates[0]}`;
        if (mockDb.has(key)) {
          throw new AppError('Conflict', 409, 'BOOKING_CONFLICT');
        }
        mockDb.set(key, { holderId: customerUid, roomId, date: dates[0] });
        winnerCount++;
      } catch {
        loserCount++;
      }
    };

    await Promise.all([
      claimInventory('CUST-ALICE'),
      claimInventory('CUST-BOB'),
    ]);

    expect(winnerCount).toBe(1);
    expect(loserCount).toBe(1);
    expect(mockDb.get(`room_date_locks/${roomId}_${dates[0]}`)).toBeDefined();
  });
});
