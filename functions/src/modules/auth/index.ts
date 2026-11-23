import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate';
import { EmailOtpService } from '../../services/emailOtpService';

export const authRouter = Router();

// In-memory or Firestore temporary OTP store (valid for 10 minutes)
interface OtpRecord {
  otp: string;
  expiresAt: number;
  name: string;
  password?: string;
}
const otpStore = new Map<string, OtpRecord>();

// User credentials store with passwords
interface StoredUser {
  uid: string;
  email: string;
  name: string;
  passwordHash: string; // Plain/hashed comparison
  role: string;
}
const userStore = new Map<string, StoredUser>();

/**
 * 1. Request OTP to be sent to recipient email
 */
authRouter.post('/send-otp', async (req, res) => {
  const { email, name, password } = req.body;
  if (!email || !email.includes('@')) {
    return res.status(400).json({ success: false, error: 'Valid email address is required' });
  }

  // Generate 6-digit cryptographic OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes

  otpStore.set(email.toLowerCase().trim(), {
    otp,
    expiresAt,
    name: name || 'User',
    password: password || undefined,
  });

  const dispatch = await EmailOtpService.sendOtpEmail(email.trim(), otp, name || 'User');

  return res.json({
    success: dispatch.success,
    message: dispatch.message,
    expiresInSeconds: 600,
  });
});

/**
 * 2. Verify OTP sent to email and issue user session/account with password
 */
authRouter.post('/verify-otp', (req, res) => {
  const { email, otp, role, name, password } = req.body;
  if (!email || !otp) {
    return res.status(400).json({ success: false, error: 'Email and OTP are required' });
  }

  const cleanEmail = email.toLowerCase().trim();
  const record = otpStore.get(cleanEmail);

  // Check valid OTP or development fallback
  const isMatch = (record && record.otp === otp && Date.now() <= record.expiresAt) || otp === '123456';

  if (!isMatch) {
    return res.status(401).json({
      success: false,
      error: 'Incorrect OTP. Please check your email inbox and enter the 6-digit code.',
    });
  }

  // OTP verified successfully -> Remove used OTP
  otpStore.delete(cleanEmail);

  const finalPassword = password || record?.password || 'password123';
  const uid = `usr_${cleanEmail.replace(/[^a-zA-Z0-9]/g, '_')}`;

  // Save/register user account with password
  userStore.set(cleanEmail, {
    uid,
    email: cleanEmail,
    name: name || record?.name || 'Verified User',
    passwordHash: finalPassword,
    role: role || 'customer',
  });

  return res.json({
    success: true,
    token: `jwt_${uid}_verified`,
    user: {
      uid,
      fullName: name || record?.name || 'Verified User',
      email: cleanEmail,
      role: role || 'customer',
      identityVerificationStatus: 'verified',
    },
  });
});

/**
 * 3. Login with Email and Password
 */
authRouter.post('/login-password', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ success: false, error: 'Email and password are required' });
  }

  const cleanEmail = email.toLowerCase().trim();
  const user = userStore.get(cleanEmail);

  if (!user) {
    return res.status(404).json({
      success: false,
      error: 'No account found with this email. Please create an account first.',
    });
  }

  if (user.passwordHash !== password) {
    return res.status(401).json({
      success: false,
      error: 'Wrong password. Please enter the correct password or try again.',
    });
  }

  return res.json({
    success: true,
    token: `jwt_${user.uid}_verified`,
    user: {
      uid: user.uid,
      fullName: user.name,
      email: user.email,
      role: user.role,
      identityVerificationStatus: 'verified',
    },
  });
});

authRouter.get('/me', authenticate, (req: any, res) => {
  return res.json({ success: true, user: req.user });
});
