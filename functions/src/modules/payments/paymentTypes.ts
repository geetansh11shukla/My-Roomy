export type PaymentStatus =
  | 'created'
  | 'authorized'
  | 'captured'
  | 'failed'
  | 'refund_pending'
  | 'refunded'
  | 'reconciliation_required';

export type PaymentProvider = 'razorpay' | 'mock';

export interface PaymentDocument {
  paymentId: string;
  bookingId: string;
  customerId: string;
  provider: PaymentProvider;
  providerOrderId: string;
  providerPaymentId: string | null;
  amount: number; // Integer minor units (paise)
  currency: string; // 'INR'
  status: PaymentStatus;
  signatureVerified: boolean;
  webhookEventId: string | null;
  failureCode: string | null;
  failureMessage: string | null;
  paidAt: string | null; // ISO 8601 string or timestamp
  createdAt: string;
  updatedAt: string;
}

export interface CreatePaymentOrderInput {
  holdId: string;
  customerUid: string;
}

export interface CreatePaymentOrderResult {
  paymentId: string;
  providerOrderId: string;
  amountPaise: number;
  currency: string;
  keyId: string;
  bookingHoldId: string;
}

export interface VerifyPaymentInput {
  paymentId: string;
  providerOrderId: string;
  providerPaymentId: string;
  signature: string;
  customerUid: string;
}

export interface PaymentWebhookPayload {
  entity: string;
  account_id: string;
  event: string;
  contains: string[];
  payload: {
    payment?: {
      entity: {
        id: string;
        order_id: string;
        amount: number;
        currency: string;
        status: string;
        error_code?: string | null;
        error_description?: string | null;
      };
    };
    order?: {
      entity: {
        id: string;
        amount: number;
        status: string;
      };
    };
  };
  created_at: number;
}

export interface InitiateRefundInput {
  paymentId: string;
  reason: string;
  requestedByUid: string;
  amountPaise?: number; // Optional partial or full amount (defaults to full)
}

export interface RefundResult {
  refundId: string;
  paymentId: string;
  amountPaise: number;
  status: 'processed' | 'pending' | 'failed';
  createdAt: string;
}

