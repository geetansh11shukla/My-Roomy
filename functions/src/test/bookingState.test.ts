import { describe, it, expect } from 'vitest';
import { BookingStateMachine } from '../modules/bookings/bookingStateMachine';

describe('Booking State Machine & Hold Pipeline Suite', () => {
  it('1. Permits legal forward transitions', () => {
    expect(() => BookingStateMachine.assertTransition('pending_payment', 'confirmed')).not.toThrow();
    expect(() => BookingStateMachine.assertTransition('confirmed', 'cancelled')).not.toThrow();
    expect(() => BookingStateMachine.assertTransition('confirmed', 'completed')).not.toThrow();
    expect(() => BookingStateMachine.assertTransition('cancelled', 'refund_pending')).not.toThrow();
  });

  it('2. Strictly rejects illegal transitions', () => {
    // A cancelled booking cannot jump back to confirmed directly
    expect(() => BookingStateMachine.assertTransition('cancelled', 'confirmed')).toThrow();

    // A completed booking is in terminal state
    expect(() => BookingStateMachine.assertTransition('completed', 'confirmed')).toThrow();
    expect(() => BookingStateMachine.assertTransition('completed', 'pending_payment')).toThrow();
  });
});

