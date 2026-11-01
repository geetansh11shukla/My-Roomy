import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';

export const authRouter = Router();

authRouter.post('/login', (req, res) => {
  const { phone, otp } = req.body;
  if (!phone) return res.status(400).json({ error: 'Phone is required' });
  if (otp !== '1234' && otp !== '0000') {
    return res.status(401).json({ error: 'Invalid OTP. Use 1234 in demo.' });
  }

  const uid = `usr_${phone.replace(/\D/g, '')}`;
  return res.json({
    success: true,
    token: `jwt_${uid}_session`,
    user: {
      uid,
      fullName: 'Verified Guest',
      phoneNumber: phone,
      role: 'customer',
      identityVerificationStatus: 'verified',
    },
  });
});

authRouter.get('/me', authenticate, (req: any, res) => {
  return res.json({ success: true, user: req.user });
});

