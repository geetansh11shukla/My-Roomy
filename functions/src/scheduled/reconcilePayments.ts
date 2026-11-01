import { logger } from '../common/logger';
import { paymentDomainService } from '../modules/payments/paymentDomainService';

/**
 * 4. reconcilePayments
 * - Identifies stale pending payments and flags discrepancies
 */
export async function reconcilePayments(): Promise<{ reconciledCount: number }> {
  logger.info('[Scheduled] Running payment reconciliation worker...');
  const result = await paymentDomainService.reconcilePendingPayments();
  logger.info(`[Scheduled] Reconciled ${result.reconciledCount} payments.`);
  return result;
}
