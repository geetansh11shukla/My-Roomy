import express, { Request, Response } from 'express';
import cors from 'cors';
import { paymentGateway } from '../services/paymentService';
import { whatsAppMessenger } from '../services/whatsappService';
import { BookingEngine } from '../services/bookingEngine';

export const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

const bookingEngine = new BookingEngine();

app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'online',
    runtime: 'Firebase Cloud Functions (Node.js 20, TypeScript Strict)',
    architecture: {
      auth: 'Firebase Authentication',
      database: 'Cloud Firestore',
      storage: 'Firebase Storage',
      notifications: 'Firebase Cloud Messaging (FCM)',
      payment: 'Razorpay / Abstract Gateway',
      messaging: 'Meta WhatsApp Cloud API',
    },
    timestamp: new Date().toISOString(),
  });
});

/**
 * 1. Razorpay Escrow Order Creation
 */
app.post('/payments/create-order', async (req: Request, res: Response) => {
  try {
    const { bookingId, amount } = req.body;
    if (!bookingId || !amount) {
      return res.status(400).json({ error: 'bookingId and amount are required' });
    }
    const order = await paymentGateway.createOrder(bookingId, Number(amount));
    return res.json({ success: true, order });
  } catch (err: any) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * 2. Razorpay Payment Verification & Booking Finalization
 */
app.post('/payments/verify', async (req: Request, res: Response) => {
  try {
    const { orderId, paymentId, signature } = req.body;
    const isValid = paymentGateway.verifyPaymentSignature(orderId, paymentId, signature);
    if (!isValid) {
      return res.status(400).json({ success: false, error: 'Invalid payment signature' });
    }
    return res.json({ success: true, message: 'Payment authorized and verified.' });
  } catch (err: any) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * 3. WhatsApp Direct Pass Dispatch
 */
app.post('/whatsapp/send-ticket', async (req: Request, res: Response) => {
  try {
    const { toPhone, roomTitle, checkIn, digitalPin, mapUrl } = req.body;
    const success = await whatsAppMessenger.sendBookingTicket(
      toPhone,
      roomTitle,
      checkIn,
      digitalPin,
      mapUrl
    );
    return res.json({ success });
  } catch (err: any) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * 4. Run Scheduled Reminders Trigger
 */
app.post('/cron/check-reminders', async (req: Request, res: Response) => {
  try {
    const count = await bookingEngine.processScheduledExtensionReminders();
    return res.json({ success: true, remindersProcessed: count });
  } catch (err: any) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

