import * as admin from 'firebase-admin';
import { logger } from '../common/logger';

export interface AuditEvent {
  eventId?: string;
  eventType:
    | 'USER_SIGNUP'
    | 'ID_VERIFICATION_SUBMITTED'
    | 'ID_VERIFIED'
    | 'ROOM_CREATED'
    | 'BOOKING_HOLD_CREATED'
    | 'BOOKING_CONFIRMED'
    | 'PAYMENT_ORDER_CREATED'
    | 'PAYMENT_CAPTURED'
    | 'PAYMENT_VERIFIED'
    | 'PAYMENT_FAILED'
    | 'REFUND_ISSUED'
    | 'REFUND_PROCESSED'
    | 'STAY_EXTENDED'
    | 'BOOKING_CANCELLED';
  userId?: string;
  resourceId?: string;
  details?: Record<string, any>;
  ipAddress?: string;
  timestamp: string;
}

export interface IAuditService {
  recordEvent(event: Omit<AuditEvent, 'timestamp'>): Promise<void>;
  logDiagnostic(message: string, context?: Record<string, any>): void;
}

export class FirestoreAuditService implements IAuditService {
  private get db(): admin.firestore.Firestore {
    return admin.firestore();
  }

  async recordEvent(event: Omit<AuditEvent, 'timestamp'>): Promise<void> {
    const fullEvent: AuditEvent = {
      ...event,
      timestamp: new Date().toISOString(),
    };

    // Sanitize any sensitive details before storing
    if (fullEvent.details) {
      delete fullEvent.details.password;
      delete fullEvent.details.rawIdNumber;
      delete fullEvent.details.cvv;
      delete fullEvent.details.secret;
    }

    try {
      if (admin.apps.length > 0) {
        await this.db.collection('audit_logs').add(fullEvent);
      }
      logger.info(`[Audit] ${fullEvent.eventType} on ${fullEvent.resourceId || 'N/A'}`);
    } catch (err: any) {
      logger.warn(`[Audit Failure] (Non-blocking): ${err.message}`);
    }
  }

  logDiagnostic(message: string, context?: Record<string, any>): void {
    logger.info(`[Diagnostic] ${message}`, context);
  }
}

export const auditService = new FirestoreAuditService();

