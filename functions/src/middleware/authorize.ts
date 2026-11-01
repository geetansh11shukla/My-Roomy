import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './authenticate';

export function authorize(allowedRoles: Array<'customer' | 'owner' | 'admin'>) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthenticated user.' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        error: `Forbidden: role '${req.user.role}' is not authorized to access this resource.`,
      });
    }

    return next();
  };
}

