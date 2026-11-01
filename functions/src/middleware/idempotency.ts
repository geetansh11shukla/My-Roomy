import { Request, Response, NextFunction } from 'express';

const processedKeys = new Map<string, { timestamp: number; response: any }>();

export function idempotency(req: Request, res: Response, next: NextFunction) {
  const key = req.headers['idempotency-key'] as string;
  if (!key) {
    return next();
  }

  const existing = processedKeys.get(key);
  if (existing && Date.now() - existing.timestamp < 10 * 60 * 1000) {
    // 10 minute idempotency cache
    return res.status(200).json(existing.response);
  }

  const originalJson = res.json.bind(res);
  res.json = (body: any) => {
    processedKeys.set(key, { timestamp: Date.now(), response: body });
    return originalJson(body);
  };

  return next();
}

