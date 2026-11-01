export interface StructuredLog {
  requestId: string;
  functionName: string;
  operationType: 'READ' | 'WRITE' | 'TRANSACTION' | 'PAYMENT' | 'WEBHOOK' | 'SCHEDULED';
  userId?: string | null;
  resourceId?: string | null;
  resultCategory: 'SUCCESS' | 'CLIENT_ERROR' | 'SYSTEM_ERROR' | 'SECURITY_ALERT';
  durationMs: number;
  safeErrorCode?: string | null;
  message?: string;
  timestamp: string;
}

// Sensitive sanitization filter
const SENSITIVE_KEYS = [
  'password',
  'token',
  'otp',
  'secret',
  'keySecret',
  'aadhaar',
  'cardNumber',
  'cvv',
  'pan',
  'authHeader',
];

export function sanitizeMetadata(data: any): any {
  if (!data || typeof data !== 'object') return data;
  if (Array.isArray(data)) return data.map(sanitizeMetadata);

  const clean: Record<string, any> = {};
  for (const [k, v] of Object.entries(data)) {
    const isSensitive = SENSITIVE_KEYS.some(sk => k.toLowerCase().includes(sk.toLowerCase()));
    if (isSensitive) {
      clean[k] = '[REDACTED]';
    } else if (typeof v === 'object') {
      clean[k] = sanitizeMetadata(v);
    } else {
      clean[k] = v;
    }
  }
  return clean;
}

export const structuredLogger = {
  log: (log: StructuredLog) => {
    const output = {
      ...log,
      timestamp: log.timestamp || new Date().toISOString(),
    };
    if (log.resultCategory === 'SYSTEM_ERROR' || log.resultCategory === 'SECURITY_ALERT') {
      console.error(JSON.stringify(output));
    } else if (log.resultCategory === 'CLIENT_ERROR') {
      console.warn(JSON.stringify(output));
    } else {
      console.log(JSON.stringify(output));
    }
  },
};

export const logger = {
  info: (msg: string, meta?: any) => {
    console.log(`[INFO] ${new Date().toISOString()} - ${msg}`, meta ? JSON.stringify(sanitizeMetadata(meta)) : '');
  },
  warn: (msg: string, meta?: any) => {
    console.warn(`[WARN] ${new Date().toISOString()} - ${msg}`, meta ? JSON.stringify(sanitizeMetadata(meta)) : '');
  },
  error: (msg: string, error?: any) => {
    console.error(`[ERROR] ${new Date().toISOString()} - ${msg}`, error || '');
  },
};
