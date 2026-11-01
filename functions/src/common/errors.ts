export type ErrorCode =
  | 'UNAUTHENTICATED'
  | 'PERMISSION_DENIED'
  | 'VALIDATION_FAILED'
  | 'ROOM_NOT_FOUND'
  | 'ROOM_NOT_PUBLISHED'
  | 'BOOKING_CONFLICT'
  | 'HOLD_EXPIRED'
  | 'PAYMENT_PENDING'
  | 'PAYMENT_FAILED'
  | 'VERIFICATION_REQUIRED'
  | 'VERIFICATION_PENDING'
  | 'OFFER_EXPIRED'
  | 'RATE_LIMITED'
  | 'INTERNAL_ERROR'
  | 'ILLEGAL_STATUS_TRANSITION'
  | 'ACCOUNT_SUSPENDED'
  | 'NOT_FOUND'
  | 'UNAUTHORIZED'
  | 'CONFLICT';

export class AppError extends Error {
  constructor(
    public override message: string,
    public statusCode: number = 400,
    public code: ErrorCode = 'VALIDATION_FAILED'
  ) {
    super(message);
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export class NotFoundError extends AppError {
  constructor(message: string = 'Requested resource not found', code: ErrorCode = 'ROOM_NOT_FOUND') {
    super(message, 404, code);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message: string = 'Authentication required', code: ErrorCode = 'UNAUTHENTICATED') {
    super(message, 401, code);
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Access denied', code: ErrorCode = 'PERMISSION_DENIED') {
    super(message, 403, code);
  }
}

export class ConflictError extends AppError {
  constructor(message: string = 'Inventory conflict: dates already reserved', code: ErrorCode = 'BOOKING_CONFLICT') {
    super(message, 409, code);
  }
}

export class ValidationError extends AppError {
  constructor(message: string) {
    super(message, 400, 'VALIDATION_FAILED');
    Object.setPrototypeOf(this, ValidationError.prototype);
  }
}
