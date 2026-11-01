import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { app } from './app';
import { expireBookingHolds } from './scheduled/expireBookingHolds';
import { sendCheckoutReminders } from './scheduled/sendCheckoutReminders';
import { processExtensionOffers } from './scheduled/processExtensionOffers';

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Modular Express HTTP API
 */
export const api = functions.https.onRequest(app);

/**
 * Scheduled Jobs
 */
export const expireHoldsJob = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    await expireBookingHolds();
  });

export const checkoutRemindersJob = functions.pubsub
  .schedule('every 1 hours')
  .timeZone('Asia/Kolkata')
  .onRun(async () => {
    await sendCheckoutReminders();
    await processExtensionOffers();
  });
