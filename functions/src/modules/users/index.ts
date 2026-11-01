import { Router, Response } from 'express';
import { userService } from './userService';
import { authenticate, AuthenticatedRequest } from '../../middleware/authenticate';
import { validateRequest } from '../../middleware/validateRequest';

export const usersRouter = Router();

/**
 * GET /users/me
 * Retrieves current authenticated user's profile
 */
usersRouter.get('/me', authenticate, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const user = await userService.syncUserProfileOnLogin(req.user!.uid, undefined, req.user!.email);
    return res.json({ success: true, user });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

/**
 * PATCH /users/me
 * Updates editable profile fields
 */
usersRouter.patch('/me', authenticate, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const updated = await userService.updateProfile(req.user!.uid, req.body);
    return res.json({ success: true, user: updated });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ error: err.message });
  }
});

/**
 * POST /users/sync-login
 * Called after successful OTP or Password login on Flutter client
 */
usersRouter.post(
  '/sync-login',
  authenticate,
  validateRequest(['phoneNumber']),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const { phoneNumber, email, fullName } = req.body;
      const user = await userService.syncUserProfileOnLogin(
        req.user!.uid,
        phoneNumber,
        email,
        fullName
      );
      return res.json({ success: true, user });
    } catch (err: any) {
      return res.status(err.statusCode || 500).json({ error: err.message });
    }
  }
);

