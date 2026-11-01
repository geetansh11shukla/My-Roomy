import { Request, Response, NextFunction } from 'express';
import * as admin from 'firebase-admin';

export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    role: 'customer' | 'owner' | 'admin';
    email?: string;
  };
}

export async function authenticate(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header.' });
  }

  const token = authHeader.split('Bearer ')[1];

  // Sandbox / Mock token bypass for rapid development
  if (token.startsWith('jwt_') || token.startsWith('mock_')) {
    const uid = token.split('_')[1] || 'usr_customer_101';
    req.user = {
      uid,
      role: token.includes('owner') ? 'owner' : (token.includes('admin') ? 'admin' : 'customer'),
      email: `${uid}@roomwala.in`,
    };
    return next();
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = {
      uid: decoded.uid,
      role: (decoded.role as any) || 'customer',
      email: decoded.email,
    };
    return next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired Firebase ID token.' });
  }
}

