import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ReviewDomainService } from '../modules/reviews/reviewDomainService';
import { SupportDomainService } from '../modules/support/supportDomainService';
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
          collection: (subCol: string) => ({
            doc: (subId: string) => ({
              set: async (data: any) => {
                mockDb.set(`${colName}/${id}/${subCol}/${subId}`, data);
              },
            }),
            orderBy: () => ({
              get: async () => {
                const docs: any[] = [];
                for (const [key, val] of mockDb.entries()) {
                  if (key.startsWith(`${colName}/${id}/${subCol}/`)) {
                    docs.push({ id: key.split('/').pop(), data: () => val });
                  }
                }
                return { docs, empty: docs.length === 0 };
              },
            }),
          }),
        }),
        where: (field: string, op: string, value: any) => ({
          where: (f2: string, op2: string, v2: any) => ({
            orderBy: () => ({
              get: async () => {
                const docs: any[] = [];
                for (const [key, val] of mockDb.entries()) {
                  if (key.startsWith(`${colName}/`) && val[field] === value && val[f2] === v2) {
                    docs.push({ id: key.split('/')[1], data: () => val });
                  }
                }
                return { docs, empty: docs.length === 0 };
              },
            }),
          }),
          limit: () => ({
            get: async () => {
              const docs: any[] = [];
              for (const [key, val] of mockDb.entries()) {
                if (key.startsWith(`${colName}/`) && val[field] === value) {
                  docs.push({ id: key.split('/')[1], data: () => val });
                }
              }
              return { empty: docs.length === 0, docs };
            },
          }),
          orderBy: () => ({
            get: async () => {
              const docs: any[] = [];
              for (const [key, val] of mockDb.entries()) {
                if (key.startsWith(`${colName}/`) && val[field] === value) {
                  docs.push({ id: key.split('/')[1], data: () => val });
                }
              }
              return { docs, empty: docs.length === 0 };
            },
          }),
        }),
      }),
      runTransaction: async (txFn: any) => {
        const tx = {
          get: async (docRef: any) => {
            const data = mockDb.get(docRef.id ? `rooms/${docRef.id}` : 'rooms/RM-TEST');
            return {
              exists: Boolean(data),
              data: () => data,
            };
          },
          set: (docRef: any, data: any) => {
            mockDb.set(`reviews/${data.reviewId}`, data);
          },
          update: (docRef: any, data: any) => {
            const prev = mockDb.get('rooms/RM-TEST') || {};
            mockDb.set('rooms/RM-TEST', { ...prev, ...data });
          },
        };
        return txFn(tx);
      },
    })),
  };
});

describe('Section 15: Reviews & Ratings', () => {
  let reviewService: ReviewDomainService;

  beforeEach(() => {
    mockDb.clear();
    reviewService = new ReviewDomainService();
  });

  it('1. permits review only for completed stays and updates room aggregate rating', async () => {
    mockDb.set('bookings/BK-COMPLETED', {
      bookingId: 'BK-COMPLETED',
      roomId: 'RM-TEST',
      customerId: 'CUST-10',
      ownerId: 'OWNER-20',
      bookingStatus: 'completed',
    });

    mockDb.set('rooms/RM-TEST', {
      roomId: 'RM-TEST',
      reviewCount: 1,
      averageRating: 4.0,
    });

    const review = await reviewService.createReview({
      bookingId: 'BK-COMPLETED',
      customerId: 'CUST-10',
      rating: 5,
      comment: 'Exceptional stay, spotless room and frictionless digital key checkin!',
    });

    expect(review.reviewId).toBeDefined();
    expect(review.rating).toBe(5);

    // Stored review doc exists
    const stored = mockDb.get(`reviews/${review.reviewId}`);
    expect(stored).toBeDefined();

    // Verify atomic aggregate calculation: (4.0 * 1 + 5) / 2 = 4.5
    const updatedRoom = mockDb.get('rooms/RM-TEST');
    expect(updatedRoom.reviewCount).toBe(2);
    expect(updatedRoom.averageRating).toBe(4.5);
  });

  it('2. rejects review if booking is not completed or rating is out of bounds', async () => {
    mockDb.set('bookings/BK-PENDING', {
      bookingId: 'BK-PENDING',
      customerId: 'CUST-10',
      bookingStatus: 'confirmed', // not completed
    });

    await expect(
      reviewService.createReview({
        bookingId: 'BK-PENDING',
        customerId: 'CUST-10',
        rating: 5,
        comment: 'Great place!',
      })
    ).rejects.toThrow('Only completed stays are eligible for customer reviews.');

    await expect(
      reviewService.createReview({
        bookingId: 'BK-PENDING',
        customerId: 'CUST-10',
        rating: 6, // invalid rating
        comment: 'Great place!',
      })
    ).rejects.toThrow(AppError);
  });

  it('3. allows room owner to post an official reply', async () => {
    const reviewId = 'REV-100';
    mockDb.set(`reviews/${reviewId}`, {
      reviewId,
      ownerId: 'OWNER-99',
      rating: 5,
      comment: 'Loved the room!',
    });

    const res = await reviewService.replyToReview({
      reviewId,
      ownerId: 'OWNER-99',
      reply: 'Thank you for staying with us! Hope to host you again.',
    });

    expect(res.ownerReply).toContain('Thank you for staying with us!');
    const updatedReview = mockDb.get(`reviews/${reviewId}`);
    expect(updatedReview.ownerReply).toContain('Thank you for staying with us!');
  });
});

describe('Section 16: Support & Reporting', () => {
  let supportService: SupportDomainService;

  beforeEach(() => {
    mockDb.clear();
    supportService = new SupportDomainService();
  });

  it('1. creates support ticket and appends threaded replies', async () => {
    const ticket = await supportService.createSupportTicket({
      userId: 'USER-ISSUE',
      bookingId: 'BK-777',
      category: 'payment',
      subject: 'Double payment confirmation inquiry',
      description: 'I noticed a slight delay during payment capture and want to confirm receipt.',
    });

    expect(ticket.ticketId).toBeDefined();
    expect(ticket.status).toBe('open');

    // Customer or Admin adds reply
    const reply = await supportService.addSupportReply({
      ticketId: ticket.ticketId,
      senderId: 'ADMIN-1',
      senderRole: 'admin',
      message: 'We verified with Razorpay and your payment is fully captured. Booking is confirmed.',
    });

    expect(reply.replyId).toBeDefined();
    expect(reply.senderRole).toBe('admin');
  });

  it('2. creates trust and safety report for fraud or damage', async () => {
    const report = await supportService.createReport({
      reporterId: 'USER-REPORTER',
      targetType: 'room',
      targetId: 'RM-MISLEADING',
      reportCategory: 'misleading_listing',
      description: 'Room amenities do not match photos and WiFi was missing.',
    });

    expect(report.reportId).toBeDefined();
    expect(report.reviewStatus).toBe('pending');

    const storedReport = mockDb.get(`reports/${report.reportId}`);
    expect(storedReport).toBeDefined();
    expect(storedReport.reportCategory).toBe('misleading_listing');
  });
});

