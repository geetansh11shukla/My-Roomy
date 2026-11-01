import * as crypto from 'crypto';

export interface RazorpayOrderResponse {
  id: string;
  orderId?: string;
  bookingId?: string;
  amount: number;
  currency: string;
  receipt?: string;
  status: string;
  provider?: string;
}

export interface RazorpayRefundResponse {
  id: string;
  amount: number;
  currency: string;
  payment_id: string;
  status: string;
}

export interface IPaymentGateway {
  createOrder(
    amountPaiseOrBookingId: number | string,
    receiptOrAmount: string | number,
    notes?: Record<string, string>
  ): Promise<RazorpayOrderResponse>;
  verifyPaymentSignature(orderId: string, paymentId: string, signature: string): boolean;
  verifyWebhookSignature(rawBody: string, signature: string): boolean;
  initiateRefund(paymentId: string, amountPaise: number, notes?: Record<string, string>): Promise<RazorpayRefundResponse>;
  getKeyId(): string;
}

export class RazorpayPaymentGateway implements IPaymentGateway {
  private keyId: string;
  private keySecret: string;
  private webhookSecret: string;
  private isConfigured: boolean;

  constructor() {
    this.keyId = process.env.RAZORPAY_KEY_ID || '';
    this.keySecret = process.env.RAZORPAY_KEY_SECRET || '';
    this.webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || this.keySecret;
    this.isConfigured = Boolean(this.keyId && this.keySecret);
  }

  getKeyId(): string {
    return this.keyId || 'rzp_test_roomwala_mock';
  }

  /**
   * Overloaded createOrder supporting:
   * (amountPaise: number, receipt: string, notes?: Record<string, string>)
   * or legacy (bookingId: string, amountInRupees: number)
   */
  async createOrder(
    param1: number | string,
    param2: string | number,
    notes?: Record<string, string>
  ): Promise<RazorpayOrderResponse> {
    let amountPaise: number;
    let receipt: string;
    let bookingId: string | undefined;

    if (typeof param1 === 'string') {
      // Legacy call: createOrder(bookingId, amountInRupees)
      bookingId = param1;
      const amountInRupees = typeof param2 === 'number' ? param2 : parseFloat(param2);
      amountPaise = Math.round(amountInRupees * 100);
      receipt = `rcpt_${param1.substring(0, 30)}`;
    } else {
      // Direct call: createOrder(amountPaise, receipt, notes)
      amountPaise = Math.round(param1);
      receipt = typeof param2 === 'string' ? param2 : `rcpt_${Date.now()}`;
      if (notes && notes.bookingId) {
        bookingId = notes.bookingId;
      }
    }

    if (!this.isConfigured) {
      const orderId = `order_sandbox_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
      return {
        id: orderId,
        orderId,
        bookingId: bookingId || 'RW-SANDBOX',
        amount: typeof param1 === 'string' ? (param2 as number) : amountPaise,
        currency: 'INR',
        receipt,
        status: 'created',
        provider: 'mock',
      };
    }

    try {
      const Razorpay = require('razorpay');
      const instance = new Razorpay({
        key_id: this.keyId,
        key_secret: this.keySecret,
      });

      const options = {
        amount: Math.round(amountPaise), // Razorpay strictly takes integer minor units (paise)
        currency: 'INR',
        receipt: receipt.substring(0, 40),
        notes: notes || (bookingId ? { bookingId } : {}),
      };

      const order = await instance.orders.create(options);
      return {
        id: order.id,
        orderId: order.id,
        bookingId,
        amount: typeof param1 === 'string' ? (param2 as number) : order.amount,
        currency: order.currency,
        receipt: order.receipt,
        status: order.status,
        provider: 'razorpay',
      };
    } catch (err) {
      console.error('[RazorpayGateway] Order creation error:', err);
      throw new Error('Payment gateway error. Unable to create order.');
    }
  }

  verifyPaymentSignature(orderId: string, paymentId: string, signature: string): boolean {
    if (!this.isConfigured) {
      return signature === 'mock_valid_signature' || signature.length >= 8;
    }
    const expectedSignature = crypto
      .createHmac('sha256', this.keySecret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');
    return expectedSignature === signature;
  }

  verifyWebhookSignature(rawBody: string, signature: string): boolean {
    if (!this.isConfigured) {
      return Boolean(signature && signature.length >= 6);
    }
    const expectedSignature = crypto
      .createHmac('sha256', this.webhookSecret)
      .update(rawBody)
      .digest('hex');
    return expectedSignature === signature;
  }

  async initiateRefund(paymentId: string, amountPaise: number, notes?: Record<string, string>): Promise<RazorpayRefundResponse> {
    if (!this.isConfigured) {
      return {
        id: `rfnd_mock_${Date.now()}`,
        amount: Math.round(amountPaise),
        currency: 'INR',
        payment_id: paymentId,
        status: 'processed',
      };
    }

    try {
      const Razorpay = require('razorpay');
      const instance = new Razorpay({
        key_id: this.keyId,
        key_secret: this.keySecret,
      });

      const refund = await instance.payments.refund(paymentId, {
        amount: Math.round(amountPaise),
        notes: notes || {},
      });

      return {
        id: refund.id,
        amount: refund.amount,
        currency: refund.currency,
        payment_id: refund.payment_id,
        status: refund.status || 'processed',
      };
    } catch (err) {
      console.error('[RazorpayGateway] Refund initiation error:', err);
      throw new Error('Payment gateway refund failure.');
    }
  }
}

export const paymentGateway = new RazorpayPaymentGateway();
