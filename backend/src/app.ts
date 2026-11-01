import express, { Request, Response } from 'express';
import cors from 'cors';
import { db } from './database';
import { RoomRecord, BookingRecord, HoldRecord, PaymentRecord, ExtensionOfferRecord } from './types';

export const app = express();
app.use(cors());
app.use(express.json());

// -----------------------------------------------------------------
// Health & Environment Diagnostic
// -----------------------------------------------------------------
app.get('/api/health', (req: Request, res: Response) => {
  res.json({
    status: 'online',
    service: 'RoomWala Production Backend Engine',
    timestamp: new Date().toISOString(),
    demoModeActive: true,
    supportedProviders: ['Razorpay Sandbox', 'PhonePe Sandbox', 'Direct NEFT Mock', 'Meta WhatsApp Cloud API Mock'],
  });
});

// -----------------------------------------------------------------
// 1. Authentication & Session Services
// -----------------------------------------------------------------
app.post('/api/auth/phone-login', (req: Request, res: Response) => {
  const { phone, otp } = req.body;
  if (!phone) {
    return res.status(400).json({ success: false, error: 'Phone number is required' });
  }

  // Deterministic OTP check
  if (otp !== '1234' && otp !== '0000') {
    return res.status(401).json({ success: false, error: 'Invalid verification OTP. Use 1234 in test environment.' });
  }

  const cleanPhone = phone.replace(/\D/g, '');
  let user = Array.from(db.users.values()).find(u => u.phoneNumber.includes(cleanPhone));
  if (!user) {
    const uid = `usr_${cleanPhone}`;
    user = {
      uid,
      fullName: 'Verified Guest',
      email: `${cleanPhone}@guest.roomwala.in`,
      phoneNumber: phone,
      role: 'customer',
      accountStatus: 'active',
      profilePhotoUrl: '',
      ageEligibilityStatus: 'eligible_18_plus',
      identityVerificationStatus: 'verified',
      preferredLanguage: 'en',
      notificationPreferences: { bookingUpdates: true, whatsappConsent: true },
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    db.users.set(uid, user);
  }

  return res.json({ success: true, token: `jwt_${user.uid}_mock_session`, user });
});

app.get('/api/auth/me', (req: Request, res: Response) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ success: false, error: 'Missing session authorization header.' });
  }
  const uid = authHeader.replace('Bearer ', '').split('_')[1];
  const user = db.users.get(uid) || db.users.get('usr_customer_101');
  return res.json({ success: true, user });
});

// -----------------------------------------------------------------
// 2. Room Discovery & Search Services
// -----------------------------------------------------------------
app.get('/api/rooms', (req: Request, res: Response) => {
  const { city, locality, maxPrice, roomType } = req.query;
  let rooms = Array.from(db.rooms.values()).filter(r => r.listingStatus === 'published');

  if (city && city !== 'All') {
    rooms = rooms.filter(r => r.city.toLowerCase() === (city as string).toLowerCase());
  }
  if (locality) {
    rooms = rooms.filter(r => r.locality.toLowerCase().includes((locality as string).toLowerCase()));
  }
  if (maxPrice) {
    rooms = rooms.filter(r => r.pricePerNight <= Number(maxPrice));
  }
  if (roomType && roomType !== 'All') {
    rooms = rooms.filter(r => r.roomType.toLowerCase() === (roomType as string).toLowerCase());
  }

  return res.json({ success: true, count: rooms.length, data: rooms });
});

app.get('/api/rooms/:roomId', (req: Request, res: Response) => {
  const room = db.rooms.get(req.params.roomId);
  if (!room) {
    return res.status(404).json({ success: false, error: 'Room listing not found.' });
  }
  return res.json({ success: true, data: room });
});

// -----------------------------------------------------------------
// 3. Availability & Slot Locking Engine
// -----------------------------------------------------------------
app.post('/api/availability/check', (req: Request, res: Response) => {
  const { roomId, checkIn, checkOut } = req.body;
  const room = db.rooms.get(roomId);
  if (!room) {
    return res.status(404).json({ success: false, error: 'Room not found' });
  }

  const dIn = new Date(checkIn);
  const dOut = new Date(checkOut);
  if (dOut <= dIn) {
    return res.status(400).json({ success: false, error: 'Check-out date must be after check-in date.' });
  }

  // Check against reserved dates
  const isConflict = room.bookedDates.some(bd => {
    const d = new Date(bd);
    return d >= dIn && d < dOut;
  });

  if (isConflict) {
    return res.json({ success: true, available: false, message: 'Dates are occupied by another guest.' });
  }

  return res.json({ success: true, available: true });
});

// -----------------------------------------------------------------
// 4. Booking Hold & Escrow Checkout Pipeline
// -----------------------------------------------------------------
app.post('/api/bookings/hold', (req: Request, res: Response) => {
  const { roomId, customerId, checkIn, checkOut, guestCount } = req.body;
  const room = db.rooms.get(roomId);
  if (!room) return res.status(404).json({ success: false, error: 'Room not found' });

  const dIn = new Date(checkIn);
  const dOut = new Date(checkOut);
  const nights = Math.max(1, Math.round((dOut.getTime() - dIn.getTime()) / (1000 * 3600 * 24)));
  const totalAmount = room.pricePerNight * nights;

  const holdId = `HOLD_${Date.now().toString().substring(5)}`;
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString(); // 10 minute slot lock

  const hold: HoldRecord = {
    holdId,
    roomId,
    customerId: customerId || 'usr_customer_101',
    checkIn,
    checkOut,
    guestCount: guestCount || 1,
    expiresAt,
    nightCount: nights,
    totalAmount,
  };

  db.holds.set(holdId, hold);
  return res.json({ success: true, holdId, expiresAt, totalAmount, nights });
});

app.post('/api/bookings/confirm', (req: Request, res: Response) => {
  const { holdId, paymentId } = req.body;
  const hold = db.holds.get(holdId);
  if (!hold) {
    return res.status(400).json({ success: false, error: 'Hold expired or invalid. Please reselect your dates.' });
  }

  const room = db.rooms.get(hold.roomId);
  if (!room) return res.status(404).json({ success: false, error: 'Room not found' });

  // Generate Digital Door Access PIN and Booking ID
  const bookingId = `RW-${Date.now().toString().substring(6)}`;
  const accessPin = `PIN-${1000 + (Date.now() % 8999)}`;
  const now = new Date().toISOString();

  const booking: BookingRecord = {
    bookingId,
    roomId: hold.roomId,
    customerId: hold.customerId,
    ownerId: room.ownerId,
    roomTitleSnapshot: room.title,
    checkIn: hold.checkIn,
    checkOut: hold.checkOut,
    guestCount: hold.guestCount,
    nightCount: hold.nightCount,
    pricePerNightSnapshot: room.pricePerNight,
    subtotal: hold.totalAmount,
    fees: 0,
    taxAmount: Math.round(hold.totalAmount * 0.05),
    discountAmount: 0,
    totalAmount: hold.totalAmount,
    currency: 'INR',
    bookingStatus: 'confirmed',
    paymentStatus: 'captured',
    cancellationReason: '',
    accessPin,
    locationUrl: `https://maps.google.com/?q=${room.latitude},${room.longitude}`,
    priorityExtensionEligible: true,
    createdAt: now,
    updatedAt: now,
  };

  db.bookings.set(bookingId, booking);
  db.holds.delete(holdId);

  // Send Simulated WhatsApp Confirmation Notice
  const customer = db.users.get(hold.customerId);
  if (customer && customer.notificationPreferences?.whatsappConsent) {
    // Record simulated delivery
    const notifs = db.notifications.get(customer.uid) || [];
    notifs.push({
      id: `ntf_${Date.now()}`,
      title: 'WhatsApp Booking Confirmation (Dispatched)',
      body: `Your booking for ${room.title} is confirmed. Digital PIN: ${accessPin}`,
      time: 'Just now',
    });
    db.notifications.set(customer.uid, notifs);
  }

  return res.json({ success: true, booking });
});

app.get('/api/bookings/my', (req: Request, res: Response) => {
  const customerId = (req.query.customerId as string) || 'usr_customer_101';
  const customerBookings = Array.from(db.bookings.values()).filter(b => b.customerId === customerId);
  return res.json({ success: true, count: customerBookings.length, data: customerBookings });
});

// -----------------------------------------------------------------
// 5. Payment Escrow Integration Gateway
// -----------------------------------------------------------------
app.post('/api/payments/create-order', (req: Request, res: Response) => {
  const { bookingId, amount, method } = req.body;
  const paymentId = `PAY_${Date.now().toString().substring(5)}`;
  const orderId = `order_${Date.now()}`;

  const payment: PaymentRecord = {
    paymentId,
    bookingId,
    provider: method || 'Razorpay UPI Sandbox',
    providerOrderId: orderId,
    providerPaymentId: `pay_mock_${Date.now()}`,
    amount,
    currency: 'INR',
    status: 'captured',
    paidAt: new Date().toISOString(),
    createdAt: new Date().toISOString(),
  };

  db.payments.set(paymentId, payment);
  return res.json({ success: true, paymentId, providerOrderId: orderId, status: 'captured' });
});

// -----------------------------------------------------------------
// 6. Stay Extension Priority Services
// -----------------------------------------------------------------
app.get('/api/extensions/offer/:bookingId', (req: Request, res: Response) => {
  const offer = Array.from(db.extensionOffers.values()).find(o => o.bookingId === req.params.bookingId);
  if (!offer) {
    return res.status(404).json({ success: false, error: 'No active extension priority offer found for this booking.' });
  }
  return res.json({ success: true, data: offer });
});

app.post('/api/extensions/accept', (req: Request, res: Response) => {
  const { offerId } = req.body;
  const offer = db.extensionOffers.get(offerId);
  if (!offer) {
    return res.status(404).json({ success: false, error: 'Offer not found or expired.' });
  }

  offer.status = 'confirmed';
  offer.updatedAt = new Date().toISOString();

  // Update original booking check-out
  const booking = db.bookings.get(offer.bookingId);
  if (booking) {
    booking.checkOut = offer.requestedCheckOut;
    booking.totalAmount += offer.quotedAmount;
    booking.bookingStatus = 'extended';
  }

  return res.json({ success: true, message: 'Stay extension confirmed.', data: offer });
});

// -----------------------------------------------------------------
// 7. Room Owner Management & Earnings API
// -----------------------------------------------------------------
app.get('/api/owner/listings', (req: Request, res: Response) => {
  const ownerId = (req.query.ownerId as string) || 'owner_101';
  const ownerRooms = Array.from(db.rooms.values()).filter(r => r.ownerId === ownerId);
  return res.json({ success: true, count: ownerRooms.length, data: ownerRooms });
});

app.post('/api/owner/listings', (req: Request, res: Response) => {
  const roomData = req.body as RoomRecord;
  const roomId = `room_${Date.now().toString().substring(7)}`;
  const now = new Date().toISOString();

  const newRoom: RoomRecord = {
    ...roomData,
    roomId,
    ownerId: roomData.ownerId || 'owner_101',
    listingStatus: 'published',
    ownerVerificationStatus: 'verified',
    averageRating: 5.0,
    reviewCount: 0,
    digitalPin: `PIN-${1000 + (Date.now() % 8999)}`,
    bookedDates: [],
    createdAt: now,
    updatedAt: now,
  };

  db.rooms.set(roomId, newRoom);
  return res.status(201).json({ success: true, data: newRoom });
});

app.get('/api/owner/earnings', (req: Request, res: Response) => {
  return res.json({
    success: true,
    data: {
      totalEarnings: 42800,
      monthEarnings: 15980,
      pendingPayouts: 4794,
      occupancyRate: 84.5,
      totalBookings: 28,
      payoutSchedule: 'Automated direct NEFT transfer every Monday',
    },
  });
});

// -----------------------------------------------------------------
// 8. Support & Audit Tickets
// -----------------------------------------------------------------
app.post('/api/support/tickets', (req: Request, res: Response) => {
  const { userId, category, subject, description, bookingId } = req.body;
  const ticketId = `SUP-${Date.now().toString().substring(6)}`;
  const now = new Date().toISOString();

  const ticket = {
    ticketId,
    userId: userId || 'usr_customer_101',
    category,
    subject,
    description,
    bookingId,
    status: 'open' as const,
    createdAt: now,
    updatedAt: now,
  };

  db.supportTickets.set(ticketId, ticket);
  return res.status(201).json({ success: true, ticketId, data: ticket });
});
