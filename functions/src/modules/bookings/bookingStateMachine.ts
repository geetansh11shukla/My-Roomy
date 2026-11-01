import { BookingStatus } from './bookingTypes';
import { AppError } from '../../common/errors';

export class BookingStateMachine {
  private static readonly ALLOWED_TRANSITIONS: Record<BookingStatus, BookingStatus[]> = {
    pending_payment: ['confirmed', 'expired', 'payment_failed', 'cancelled'],
    confirmed: ['cancelled', 'completed', 'refund_pending'],
    cancelled: ['refund_pending', 'refunded'],
    completed: [], // Terminal state
    expired: [], // Terminal state
    payment_failed: ['pending_payment', 'cancelled'],
    refund_pending: ['refunded', 'cancelled'],
    refunded: [], // Terminal state
  };

  /**
   * Asserts whether a booking status transition is legal.
   */
  static assertTransition(current: BookingStatus, next: BookingStatus): void {
    const allowed = this.ALLOWED_TRANSITIONS[current] || [];
    if (!allowed.includes(next)) {
      throw new AppError(
        `Illegal booking status transition from '${current}' to '${next}'.`,
        400,
        'ILLEGAL_STATUS_TRANSITION'
      );
    }
  }

  static canCancel(status: BookingStatus): boolean {
    return status === 'pending_payment' || status === 'confirmed';
  }

  static canComplete(status: BookingStatus, checkOutDate: string): boolean {
    if (status !== 'confirmed') return false;
    const checkoutTime = new Date(checkOutDate).getTime();
    return Date.now() >= checkoutTime;
  }
}
