import { ValidationError } from './errors';

export function validateRequiredFields(obj: Record<string, any>, requiredFields: string[]): void {
  for (const field of requiredFields) {
    if (obj[field] === undefined || obj[field] === null || obj[field] === '') {
      throw new ValidationError(`Field '${field}' is required and cannot be empty.`);
    }
  }
}

export function validateStringLength(value: string, fieldName: string, min: number, max: number): void {
  if (typeof value !== 'string') {
    throw new ValidationError(`Field '${fieldName}' must be a string.`);
  }
  const len = value.trim().length;
  if (len < min || len > max) {
    throw new ValidationError(`Field '${fieldName}' length must be between ${min} and ${max} characters.`);
  }
}

export function validateIntegerRange(value: number, fieldName: string, min: number, max: number): void {
  if (!Number.isInteger(value)) {
    throw new ValidationError(`Field '${fieldName}' must be an integer.`);
  }
  if (value < min || value > max) {
    throw new ValidationError(`Field '${fieldName}' must be between ${min} and ${max}.`);
  }
}

export function validateEnumValue<T extends string>(value: any, fieldName: string, allowedValues: readonly T[]): T {
  if (!allowedValues.includes(value)) {
    throw new ValidationError(`Field '${fieldName}' has invalid value '${value}'. Allowed: ${allowedValues.join(', ')}.`);
  }
  return value as T;
}

export function validateDateFormat(dateStr: string, fieldName: string): void {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
    throw new ValidationError(`Field '${fieldName}' must match YYYY-MM-DD format.`);
  }
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) {
    throw new ValidationError(`Field '${fieldName}' is not a valid calendar date.`);
  }
}

export function validateDateOrder(checkIn: string, checkOut: string): void {
  validateDateFormat(checkIn, 'checkIn');
  validateDateFormat(checkOut, 'checkOut');
  const inTime = new Date(checkIn).getTime();
  const outTime = new Date(checkOut).getTime();
  if (outTime <= inTime) {
    throw new ValidationError('checkOut date must be strictly after checkIn date.');
  }
}

export function isValidIndianPhone(phone: string): boolean {
  const clean = phone.replace(/\D/g, '');
  return clean.length === 10 || (clean.length === 12 && clean.startsWith('91'));
}

export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
