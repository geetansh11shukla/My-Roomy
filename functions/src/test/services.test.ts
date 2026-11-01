import { describe, it, expect } from 'vitest';
import { paymentGateway } from '../services/paymentService';
import { whatsAppMessenger } from '../services/whatsappService';

describe('Firebase Backend Architecture Automated Suite', () => {
  it('1. Payment Gateway abstraction creates order in sandbox or production', async () => {
    const order = await paymentGateway.createOrder('RW-TEST-100', 1598);
    expect(order.bookingId).toBe('RW-TEST-100');
    expect(order.amount).toBe(1598);
    expect(order.currency).toBe('INR');
  });

  it('2. Payment Signature Verification authenticates securely', () => {
    const valid = paymentGateway.verifyPaymentSignature('order_test', 'pay_test', 'mock_valid_signature');
    expect(valid).toBe(true);
  });

  it('3. WhatsApp Messenger dispatches booking ticket and PIN', async () => {
    const result = await whatsAppMessenger.sendBookingTicket(
      '+91 9876543210',
      'Premium AC Suite Gomti Nagar',
      'Tomorrow 12:00 PM',
      'PIN-8812',
      'https://maps.google.com/?q=26.8522,80.9995'
    );
    expect(result).toBe(true);
  });

  it('4. WhatsApp Messenger dispatches 24h checkout reminder and extension invitation', async () => {
    const result = await whatsAppMessenger.sendCheckoutReminder(
      '+91 9876543210',
      'Premium AC Suite Gomti Nagar',
      'In 24 Hours, 11:00 AM',
      'https://roomwala.in/bookings/RW-TEST/extension'
    );
    expect(result).toBe(true);
  });
});

