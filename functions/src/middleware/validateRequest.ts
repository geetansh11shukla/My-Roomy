import { Request, Response, NextFunction } from 'express';

export function validateRequest(requiredFields: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const missing = requiredFields.filter(f => req.body[f] === undefined || req.body[f] === null || req.body[f] === '');
    if (missing.length > 0) {
      return res.status(400).json({
        error: `Missing required body fields: ${missing.join(', ')}`,
      });
    }
    return next();
  };
}

