import express from 'express';
import cors from 'cors';
import { authRouter } from './modules/auth';
import { usersRouter } from './modules/users';
import { roomsRouter } from './modules/rooms';
import { availabilityRouter } from './modules/availability';
import { bookingsRouter } from './modules/bookings';
import { paymentsRouter } from './modules/payments';
import { extensionsRouter } from './modules/extensions';
import { refundsRouter } from './modules/refunds';
import { verificationRouter } from './modules/verification';
import { notificationsRouter } from './modules/notifications';
import { ownerRouter } from './modules/owner';
import { reviewsRouter } from './modules/reviews';
import { supportRouter } from './modules/support';
import { adminRouter } from './modules/admin';
import { responseFormatter } from './middleware/responseFormatter';

export const app = express();
app.use(cors({ origin: true }));
app.use(express.json());
app.use(responseFormatter);

app.get('/health', (req, res) => {
  res.apiSuccess({
    status: 'online',
    runtime: 'Firebase Functions (TypeScript Strict Mode, Modular Architecture)',
    timestamp: new Date().toISOString(),
  });
});

app.use('/auth', authRouter);
app.use('/users', usersRouter);
app.use('/rooms', roomsRouter);
app.use('/availability', availabilityRouter);
app.use('/bookings', bookingsRouter);
app.use('/payments', paymentsRouter);
app.use('/extensions', extensionsRouter);
app.use('/refunds', refundsRouter);
app.use('/verification', verificationRouter);
app.use('/notifications', notificationsRouter);
app.use('/owner', ownerRouter);
app.use('/reviews', reviewsRouter);
app.use('/support', supportRouter);
app.use('/admin', adminRouter);

