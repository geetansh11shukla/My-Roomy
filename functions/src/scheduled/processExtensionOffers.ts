import { logger } from '../common/logger';
import { extensionDomainService } from '../modules/extensions/extensionDomainService';

/**
 * 3. processExtensionOffers
 * - Background routine to mark expired extension offers
 * - Tracks expiration and prevents post-expiration acceptance
 */
export async function processExtensionOffers(): Promise<number> {
  logger.info('[Scheduled] Expiring past stay extension offers...');
  const count = await extensionDomainService.expireExtensionOffers();
  logger.info(`[Scheduled] Expired ${count} extension offers.`);
  return count;
}
