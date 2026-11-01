import { Request, Response, NextFunction } from 'express';
import * as crypto from 'crypto';

export interface StandardSuccessResponse<T = any> {
  success: true;
  data: T;
  requestId: string;
}

export interface StandardErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
  };
  requestId: string;
}

declare global {
  namespace Express {
    interface Request {
      requestId: string;
    }
    interface Response {
      apiSuccess<T>(data: T, statusCode?: number): void;
      apiError(code: string, message: string, statusCode?: number): void;
    }
  }
}

/**
 * Middleware attaches unique requestId to incoming requests and defines standard helper responders.
 */
export const responseFormatter = (req: Request, res: Response, next: NextFunction) => {
  const reqId = (req.headers['x-request-id'] as string) || `req_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
  req.requestId = reqId;
  res.setHeader('X-Request-Id', reqId);

  res.apiSuccess = function <T>(data: T, statusCode: number = 200) {
    const responsePayload: StandardSuccessResponse<T> = {
      success: true,
      data,
      requestId: reqId,
    };
    return res.status(statusCode).json(responsePayload);
  };

  res.apiError = function (code: string, message: string, statusCode: number = 400) {
    const errorPayload: StandardErrorResponse = {
      success: false,
      error: {
        code,
        message,
      },
      requestId: reqId,
    };
    return res.status(statusCode).json(errorPayload);
  };

  next();
};
