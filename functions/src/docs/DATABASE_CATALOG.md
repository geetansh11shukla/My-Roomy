# Database Collection Catalog: RoomWala Production Backend
*Architecture Standard: Google Cloud Firestore (Document Store), Strict Access Control, Half-Open Date Locks, Integer Minor Units (Paise)*

---

### Catalog Summary Index
1. `users`
2. `rooms`
3. `bookings`
4. `room_blocks`
5. `booking_holds`
6. `room_date_locks`
7. `payments`
8. `refunds`
9. `verification_cases`
10. `reviews`
11. `notifications`
12. `notification_jobs`
13. `whatsapp_messages`
14. `extension_offers`
15. `owner_payouts`
16. `support_tickets`
17. `reports`
18. `outbox_events`
19. `payment_webhook_events` (processed_webhook_events)
20. `idempotency_records`
21. `audit_logs`
22. `app_config`

---

### Detailed Collection Specifications

#### 1. `users`
- **Document ID Strategy**: Matches Firebase Authentication `uid` (`auth.uid`).
- **Fields & Types**:
  - `uid`: string (Required)
  - `fullName`: string (Required)
  - `email`: string | null (Optional)
  - `phoneNumber`: string (Required)
  - `phoneVerified`: boolean (Required)
  - `emailVerified`: boolean (Required)
  - `role`: enum ('customer' | 'owner' | 'admin') (Required)
  - `accountStatus`: enum ('active' | 'suspended' | 'pending_deletion' | 'deleted') (Required)
  - `profilePhotoUrl`: string | null (Optional)
  - `dateOfBirth`: timestamp | null (Optional, restricted)
  - `ageEligibilityStatus`: enum ('not_checked' | 'pending' | 'eligible' | 'ineligible' | 'manual_review') (Required)
  - `identityVerificationStatus`: enum ('not_started' | 'pending' | 'verified' | 'rejected' | 'expired' | 'manual_review') (Required)
  - `preferredLanguage`: string (Required, default 'en')
  - `notificationPreferences`: map (Required)
  - `termsAcceptedVersion`: string | null (Optional)
  - `termsAcceptedAt`: timestamp | null (Optional)
  - `createdAt`: ISO 8601 string / timestamp (Required)
  - `updatedAt`: ISO 8601 string / timestamp (Required)
  - `lastLoginAt`: timestamp | null (Optional)
- **Permissions**:
  - Read: Authenticated user (own record) or Admin.
  - Create: Server / Auth Trigger upon phone/email verification.
  - Update: User (restricted to non-sensitive profile fields; cannot update `role`, `accountStatus`, or verification statuses); Admin (full).
  - Delete: Admin or compliant deletion workflow.
- **Transactions Required**: Role elevation, account suspension.
- **Indexes**: `(role ASC, accountStatus ASC, createdAt DESC)`.
- **Retention**: Active accounts retained indefinitely; deleted accounts purged/anonymized after 30 days per privacy policy.
- **Sensitive Data**: Yes (phone, email, DOB, verification summaries).

---

#### 2. `rooms`
- **Document ID Strategy**: `ROOM-<timestamp>-<random>` or UUID.
- **Fields & Types**:
  - `roomId`: string (Required)
  - `ownerId`: string (Required)
  - `title`: string (Required)
  - `description`: string (Required)
  - `roomType`: enum ('single' | 'double' | 'shared' | 'flat' | 'studio') (Required)
  - `pricePerNightPaise`: integer minor units (Required)
  - `securityDepositPaise`: integer minor units (Required)
  - `currency`: string ('INR') (Required)
  - `capacity`: integer >= 1 (Required)
  - `amenities`: array of strings (Required)
  - `photos`: array of strings (>= 3 URLs required) (Required)
  - `coverPhotoUrl`: string (Required)
  - `address`: map with `street`, `landmark`, `city`, `state`, `postalCode` (Restricted until stay confirmed) (Required)
  - `latitude`: number (Required)
  - `longitude`: number (Required)
  - `checkInTime`: string (e.g. '12:00 PM') (Required)
  - `checkOutTime`: string (e.g. '11:00 AM') (Required)
  - `cancellationPolicyId`: string (Required)
  - `listingStatus`: enum ('draft' | 'pending_review' | 'published' | 'rejected' | 'suspended') (Required)
  - `averageRating`: number (0.0 to 5.0) (Required)
  - `reviewCount`: integer (Required)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Public can read published listings (with street address redacted); Owner can read own; Admin can read all.
  - Create: Authenticated room owner.
  - Update: Owner (own listings, restricted from publishing directly); Admin (approvals/rejections); Server (rating aggregates).
  - Delete: Owner (drafts only); Admin (suspended).
- **Transactions Required**: Rating aggregate updates (`averageRating`, `reviewCount`).
- **Indexes**: `(listingStatus ASC, city ASC, pricePerNightPaise ASC)`, `(ownerId ASC, createdAt DESC)`.
- **Retention**: Indefinite while active.
- **Sensitive Data**: Exact physical address is confidential until booking confirmation.

---

#### 3. `bookings`
- **Document ID Strategy**: Canonical booking reference `RW-<timestamp>`.
- **Fields & Types**:
  - `bookingId`: string (Required)
  - `roomId`: string (Required)
  - `customerId`: string (Required)
  - `ownerId`: string (Required)
  - `roomTitleSnapshot`: string (Required)
  - `roomPhotoSnapshot`: string (Required)
  - `checkIn`: string YYYY-MM-DD (Required)
  - `checkOut`: string YYYY-MM-DD (Required)
  - `guestCount`: integer >= 1 (Required)
  - `nightCount`: integer >= 1 (Required)
  - `pricePerNightSnapshotPaise`: integer (Required)
  - `subtotalPaise`: integer (Required)
  - `feesPaise`: integer (Paise, 0 for 0% brokerage) (Required)
  - `taxAmountPaise`: integer (5% GST) (Required)
  - `discountAmountPaise`: integer (Required)
  - `totalAmountPaise`: integer (Required)
  - `currency`: string ('INR') (Required)
  - `bookingStatus`: enum ('pending_payment' | 'confirmed' | 'cancelled' | 'completed' | 'expired') (Required)
  - `paymentStatus`: enum ('created' | 'captured' | 'failed' | 'refund_initiated' | 'refunded') (Required)
  - `holdId`: string (Required)
  - `paymentId`: string (Required)
  - `cancellationPolicySnapshot`: string (Required)
  - `cancellationReason`: string | null (Optional)
  - `cancelledBy`: string | null (Optional)
  - `cancelledAt`: string | null (Optional)
  - `confirmedAt`: string | null (Optional)
  - `completedAt`: string | null (Optional)
  - `accessPin`: string (Digital door PIN) (Required)
  - `locationUrl`: string (Required)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Customer (own bookings), Owner (own listed bookings), Admin (all).
  - Create: Server transaction only (converting hold).
  - Update: Server domain service only (status transitions, cancellation, extensions).
  - Delete: None (immutable audit integrity).
- **Transactions Required**: Converting `booking_holds` to confirmed `bookings` and locking `room_date_locks`.
- **Indexes**: `(customerId ASC, createdAt DESC)`, `(ownerId ASC, createdAt DESC)`, `(bookingStatus ASC, checkOut ASC)`.
- **Retention**: 7 years for financial and tax compliance.
- **Sensitive Data**: Yes (access door PIN, customer IDs, financial totals).

---

#### 4. `room_blocks`
- **Document ID Strategy**: `BLK-<timestamp>`.
- **Fields & Types**:
  - `blockId`: string (Required)
  - `roomId`: string (Required)
  - `startDate`: string YYYY-MM-DD (Required)
  - `endDate`: string YYYY-MM-DD (Required)
  - `reason`: enum ('maintenance' | 'owner_block' | 'other') (Required)
  - `createdBy`: string (Required)
  - `status`: enum ('active' | 'released') (Required)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Room owner (own blocks), Admin.
  - Create: Room owner (atomically verified against bookings).
  - Update: Room owner (release block).
  - Delete: Admin.
- **Transactions Required**: Atomic date claiming in `room_date_locks`.
- **Indexes**: `(roomId ASC, startDate ASC, endDate ASC)`.
- **Retention**: 1 year post-endDate.

---

#### 5. `booking_holds`
- **Document ID Strategy**: `HOLD-<timestamp>-<random>`.
- **Fields & Types**:
  - `holdId`: string (Required)
  - `roomId`: string (Required)
  - `customerId`: string (Required)
  - `checkIn`: string YYYY-MM-DD (Required)
  - `checkOut`: string YYYY-MM-DD (Required)
  - `guestCount`: integer (Required)
  - `status`: enum ('active' | 'converted' | 'expired' | 'released') (Required)
  - `expiresAt`: ISO 8601 string (10 minutes from creation) (Required)
  - `paymentId`: string | null (Optional)
  - `idempotencyKey`: string | null (Optional)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Customer (own active holds), Server, Admin.
  - Create: Server transaction via `inventoryLockService.createAtomicHold`.
  - Update: Server domain service only.
  - Delete: Automatic expiration cleanup.
- **Transactions Required**: Atomic inventory lock creation.
- **Indexes**: `(customerId ASC, status ASC, expiresAt ASC)`.
- **Retention**: Expired holds purged after 7 days.

---

#### 6. `room_date_locks`
- **Document ID Strategy**: Deterministic compound key `${roomId}_${YYYY-MM-DD}`.
- **Fields & Types**:
  - `lockId`: string `${roomId}_${date}` (Required)
  - `roomId`: string (Required)
  - `date`: string YYYY-MM-DD (Required)
  - `lockType`: enum ('hold' | 'booking' | 'block') (Required)
  - `holderId`: string (`holdId`, `bookingId`, or `blockId`) (Required)
  - `status`: enum ('active' | 'confirmed' | 'blocked') (Required)
  - `createdAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Internal service layer only.
  - Create / Delete: Strictly inside Firestore Transactions (`runTransaction`).
- **Transactions Required**: All read-checks and writes MUST occur inside transaction blocks.
- **Indexes**: Primary key lookup only.
- **Retention**: Deleted automatically upon hold expiration, cancellation, or block release.

---

#### 7. `payments`
- **Document ID Strategy**: `PAY-<timestamp>-<random>`.
- **Fields & Types**:
  - `paymentId`: string (Required)
  - `bookingId`: string (Required)
  - `customerId`: string (Required)
  - `provider`: enum ('razorpay' | 'mock') (Required)
  - `providerOrderId`: string (Required)
  - `providerPaymentId`: string | null (Optional)
  - `amount`: integer minor units (paise) (Required)
  - `currency`: string ('INR') (Required)
  - `status`: enum ('created' | 'authorized' | 'captured' | 'failed' | 'refund_pending' | 'refunded' | 'reconciliation_required') (Required)
  - `signatureVerified`: boolean (Required)
  - `webhookEventId`: string | null (Optional)
  - `failureCode`: string | null (Optional)
  - `failureMessage`: string | null (Optional)
  - `paidAt`: string | null (Optional)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Authenticated customer (own payment), Admin.
  - Create: Backend order generator (`createPaymentOrder`).
  - Update: Backend verification handler or webhook dispatcher.
  - Delete: Forbidden.
- **Transactions Required**: Capturing payment and confirming hold to booking.
- **Indexes**: `(providerOrderId ASC)`, `(customerId ASC, createdAt DESC)`, `(status ASC)`.
- **Retention**: 7 years for financial records.
- **Sensitive Data**: Yes (transaction IDs, amounts).

---

#### 8. `refunds`
- **Document ID Strategy**: `RFND-<timestamp>-<random>`.
- **Fields & Types**:
  - `refundId`: string (Required)
  - `bookingId`: string (Required)
  - `paymentId`: string (Required)
  - `amount`: integer minor units (paise) (Required)
  - `currency`: string ('INR') (Required)
  - `reason`: string (Required)
  - `providerRefundId`: string | null (Optional)
  - `status`: enum ('pending' | 'processing' | 'succeeded' | 'failed' | 'manual_review') (Required)
  - `requestedBy`: string (User or Admin UID) (Required)
  - `requestedAt`: ISO 8601 string (Required)
  - `processedAt`: string | null (Optional)
  - `failureReason`: string | null (Optional)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Customer (own refunds), Admin.
  - Create: Server cancellation/refund domain service.
  - Update: Gateway webhook processor or Admin manual review.
  - Delete: Forbidden.
- **Transactions Required**: Cancellation inventory release and refund registration.
- **Indexes**: `(bookingId ASC)`, `(providerRefundId ASC)`.
- **Retention**: 7 years.
- **Sensitive Data**: Financial refund amounts.

---

#### 9. `verification_cases`
- **Document ID Strategy**: `VERIF-<timestamp>-<random>`.
- **Fields & Types**:
  - `verificationId`: string (Required)
  - `userId`: string (Required)
  - `verificationType`: enum ('aadhaar' | 'driving_license' | 'passport' | 'voter_id') (Required)
  - `provider`: enum ('digilocker' | 'hyperverge' | 'mock') (Required)
  - `providerReference`: string (Required)
  - `status`: enum ('not_started' | 'pending' | 'verified' | 'rejected' | 'expired' | 'manual_review') (Required)
  - `submittedAt`: ISO 8601 string (Required)
  - `reviewedAt`: string | null (Optional)
  - `reviewedBy`: string | null (Optional)
  - `rejectionReasonCode`: string | null (Optional)
  - `expiresAt`: string | null (Optional)
  - `retentionUntil`: ISO 8601 string (Required)
  - `consentVersion`: string (Required)
  - `minimumAgeRequired`: number (Required, e.g. 18)
  - `ageVerified`: boolean (Required)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Applicant user (own case), Admin.
  - Create: Applicant user via server initiation endpoint.
  - Update: Provider webhook or Admin reviewer.
  - Delete: Automated compliance worker when `retentionUntil <= now()`.
- **Transactions Required**: Admin approval and user status mirror.
- **Indexes**: `(userId ASC, submittedAt DESC)`, `(status ASC)`.
- **Retention**: 1 year from submission (`retentionUntil`).
- **Sensitive Data**: High (identity documents, verification results). Masked before storage.

---

#### 10. `reviews`
- **Document ID Strategy**: `REV-<timestamp>-<random>`.
- **Fields & Types**:
  - `reviewId`: string (Required)
  - `bookingId`: string (Required, unique)
  - `roomId`: string (Required)
  - `customerId`: string (Required)
  - `ownerId`: string (Required)
  - `rating`: integer (1 to 5) (Required)
  - `comment`: string (5 to 1000 chars) (Required)
  - `photoUrls`: array of strings (Optional)
  - `moderationStatus`: enum ('pending' | 'published' | 'flagged' | 'rejected') (Required)
  - `ownerReply`: string | null (Optional)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Public (if published), Admin (all).
  - Create: Customer with completed booking.
  - Update: Room owner (ownerReply only); Admin (moderationStatus).
  - Delete: Admin only.
- **Transactions Required**: Recalculating `averageRating` and `reviewCount` on `rooms`.
- **Indexes**: `(roomId ASC, moderationStatus ASC, createdAt DESC)`.
- **Retention**: Indefinite while room exists.

---

#### 11. `notifications`
- **Document ID Strategy**: `NOTIF-<timestamp>-<random>`.
- **Fields & Types**:
  - `notificationId`: string (Required)
  - `recipientUserId`: string (Required)
  - `bookingId`: string | null (Optional)
  - `type`: enum ('booking_confirmed' | 'booking_cancelled' | 'checkout_reminder' | 'location_shared' | 'stay_extension_offer' | 'owner_booking_alert' | 'identity_verification_update' | 'payout_processed') (Required)
  - `title`: string (Required)
  - `message`: string (Required)
  - `channel`: enum ('in_app' | 'fcm' | 'whatsapp') (Required)
  - `deliveryStatus`: enum ('pending' | 'queued' | 'sent' | 'delivered' | 'read' | 'failed') (Required)
  - `providerMessageId`: string | null (Optional)
  - `scheduledAt`: string | null (Optional)
  - `sentAt`: string | null (Optional)
  - `failureReason`: string | null (Optional)
  - `read`: boolean (Required, default false)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Recipient user, Admin.
  - Create: Server domain events.
  - Update: Recipient user (mark read).
  - Delete: Recipient user.
- **Transactions Required**: None.
- **Indexes**: `(recipientUserId ASC, createdAt DESC)`, `(recipientUserId ASC, read ASC)`.
- **Retention**: 90 days.

---

#### 12. `notification_jobs`
- **Document ID Strategy**: `rem_<bookingId>` or UUID.
- **Fields & Types**:
  - `jobId`: string (Required)
  - `notificationId` / `bookingId`: string (Required)
  - `channel`: enum ('whatsapp' | 'fcm') (Required)
  - `attempts`: integer (Required)
  - `maxAttempts`: integer (Required)
  - `status`: enum ('pending' | 'processing' | 'completed' | 'failed') (Required)
  - `scheduledAt`: ISO 8601 string (Required)
  - `lastError`: string | null (Optional)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**: Internal server workers only.
- **Transactions Required**: Worker claiming job.
- **Indexes**: `(status ASC, scheduledAt ASC)`.
- **Retention**: 14 days after completion.

---

#### 13. `whatsapp_messages`
- **Document ID Strategy**: `WA-<type>-<timestamp>`.
- **Fields & Types**:
  - `messageId`: string (Required)
  - `recipientUserId`: string (Required)
  - `recipientPhone`: string (Required)
  - `bookingId`: string | null (Optional)
  - `templateName`: string (Required)
  - `templateVersion`: string (Required)
  - `parameters`: map (Required)
  - `providerMessageId`: string | null (Optional)
  - `status`: enum ('queued' | 'sent' | 'delivered' | 'read' | 'failed') (Required)
  - `failureReason`: string | null (Optional)
  - `consentVerified`: boolean (Required)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**: Internal server only.
- **Transactions Required**: None.
- **Indexes**: `(providerMessageId ASC)`.
- **Retention**: 1 year.
- **Sensitive Data**: Recipient phone number and parameters.

---

#### 14. `extension_offers`
- **Document ID Strategy**: `EXT-<timestamp>-<random>`.
- **Fields & Types**:
  - `offerId`: string (Required)
  - `bookingId`: string (Required)
  - `roomId`: string (Required)
  - `customerId`: string (Required)
  - `ownerId`: string (Required)
  - `offeredAt`: ISO 8601 string (Required)
  - `expiresAt`: ISO 8601 string (Required)
  - `requestedCheckIn`: string YYYY-MM-DD (Required)
  - `requestedCheckOut`: string YYYY-MM-DD (Required)
  - `quotedAmount`: integer minor units (paise) (Required)
  - `currency`: string ('INR') (Required)
  - `paymentId`: string | null (Optional)
  - `status`: enum ('offered' | 'accepted' | 'declined' | 'expired' | 'payment_pending' | 'confirmed') (Required)
  - `reminderScheduledAt`: string | null (Optional)
  - `reminderSentAt`: string | null (Optional)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Customer, Owner, Admin.
  - Create: Backend trigger after booking confirmation.
  - Update: Customer (accept/decline/dates); Server (payment & confirmation).
  - Delete: Forbidden.
- **Transactions Required**: Confirming extension and claiming extra nights in `room_date_locks`.
- **Indexes**: `(customerId ASC, status ASC, expiresAt ASC)`.
- **Retention**: 1 year.

---

#### 15. `owner_payouts`
- **Document ID Strategy**: `PAYOUT-<timestamp>`.
- **Fields & Types**:
  - `payoutId`: string (Required)
  - `ownerId`: string (Required)
  - `bookingId`: string (Required)
  - `grossAmount`: integer (paise) (Required)
  - `platformFee`: integer (paise) (Required)
  - `netAmount`: integer (paise) (Required)
  - `currency`: string ('INR') (Required)
  - `providerPayoutId`: string | null (Optional)
  - `status`: enum ('pending' | 'processing' | 'completed' | 'failed') (Required)
  - `requestedAt`: ISO 8601 string (Required)
  - `processedAt`: string | null (Optional)
  - `failureReason`: string | null (Optional)
- **Permissions**:
  - Read: Room owner (own payouts), Admin.
  - Create: Server payout automation.
  - Update: Admin or payout provider webhook.
  - Delete: Forbidden.
- **Transactions Required**: Payout settlement reconciliation.
- **Indexes**: `(ownerId ASC, requestedAt DESC)`.
- **Retention**: 7 years for tax accounting.
- **Sensitive Data**: Yes (bank payouts, net earnings).

---

#### 16. `support_tickets`
- **Document ID Strategy**: `TCK-<timestamp>-<random>`.
- **Fields & Types**:
  - `ticketId`: string (Required)
  - `userId`: string (Required)
  - `bookingId`: string | null (Optional)
  - `category`: enum ('booking' | 'payment' | 'host' | 'cancellation' | 'app_bug' | 'general') (Required)
  - `subject`: string (Required)
  - `description`: string (Required)
  - `attachmentUrls`: array of strings (Optional)
  - `priority`: enum ('low' | 'medium' | 'high' | 'urgent') (Required)
  - `status`: enum ('open' | 'in_progress' | 'waiting_user' | 'resolved' | 'closed') (Required)
  - `assignedAdminId`: string | null (Optional)
  - `resolution`: string | null (Optional)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
  - `resolvedAt`: string | null (Optional)
- **Permissions**:
  - Read: Ticket author (userId), Admin.
  - Create: Authenticated user.
  - Update: Author (replies); Admin (assignment, status, resolution).
  - Delete: Admin only.
- **Sub-collections**: `replies` (threaded chat history).
- **Indexes**: `(userId ASC, createdAt DESC)`, `(status ASC, priority ASC, createdAt ASC)`.
- **Retention**: 3 years.

---

#### 17. `reports`
- **Document ID Strategy**: `RPT-<timestamp>-<random>`.
- **Fields & Types**:
  - `reportId`: string (Required)
  - `reporterId`: string (Required)
  - `targetType`: enum ('room' | 'user') (Required)
  - `targetId`: string (Required)
  - `reportCategory`: enum ('misleading_listing' | 'fraud' | 'harassment' | 'property_damage' | 'other') (Required)
  - `description`: string (Required)
  - `evidenceReferences`: array of strings (Optional)
  - `reviewStatus`: enum ('pending' | 'under_review' | 'action_taken' | 'dismissed') (Required)
  - `assignedReviewer`: string | null (Optional)
  - `resolution`: string | null (Optional)
  - `createdAt`: ISO 8601 string (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Admin only.
  - Create: Any authenticated user.
  - Update: Admin only.
  - Delete: Admin only.
- **Indexes**: `(reviewStatus ASC, createdAt ASC)`.
- **Retention**: 5 years.
- **Sensitive Data**: Confidential whistleblower reports.

---

#### 18. `outbox_events`
- **Document ID Strategy**: Deterministic event ID `evt_<name>_<aggregateId>_<timestamp>`.
- **Fields & Types**:
  - `eventId`: string (Required)
  - `eventType`: string (Required)
  - `aggregateId`: string (Required)
  - `payload`: map (Required)
  - `processed`: boolean (Required)
  - `processedAt`: string | null (Optional)
  - `createdAt`: ISO 8601 string (Required)
- **Permissions**: Internal server only.
- **Transactions Required**: Committed in the same atomic transaction as the source event.
- **Indexes**: `(processed ASC, createdAt ASC)`.
- **Retention**: 30 days after processing.

---

#### 19. `payment_webhook_events` (processed_webhook_events)
- **Document ID Strategy**: Provider-supplied event ID (e.g. `evt_...`).
- **Fields & Types**:
  - `eventId`: string (Required)
  - `eventType`: string (Required)
  - `receivedAt`: ISO 8601 string (Required)
- **Permissions**: Server webhook handler only.
- **Indexes**: Document ID lookup.
- **Retention**: 90 days.

---

#### 20. `idempotency_records`
- **Document ID Strategy**: Client-provided or generated `idempotencyKey`.
- **Fields & Types**:
  - `idempotencyKey`: string (Required)
  - `userId`: string (Required)
  - `resourceId`: string (Required)
  - `responsePayload`: map (Required)
  - `createdAt`: ISO 8601 string (Required)
- **Permissions**: Internal server middleware only.
- **Retention**: 24 hours.

---

#### 21. `audit_logs`
- **Document ID Strategy**: `audit_<timestamp>_<random>`.
- **Fields & Types**:
  - `eventId`: string (Required)
  - `eventType`: enum ('USER_SIGNUP' | 'ID_VERIFICATION_SUBMITTED' | 'ID_VERIFIED' | 'ROOM_CREATED' | 'BOOKING_HOLD_CREATED' | 'BOOKING_CONFIRMED' | 'PAYMENT_ORDER_CREATED' | 'PAYMENT_CAPTURED' | 'PAYMENT_VERIFIED' | 'PAYMENT_FAILED' | 'REFUND_ISSUED' | 'REFUND_PROCESSED' | 'STAY_EXTENDED' | 'BOOKING_CANCELLED') (Required)
  - `userId`: string | null (Optional)
  - `resourceId`: string | null (Optional)
  - `details`: map (Non-sensitive sanitized parameters) (Optional)
  - `ipAddress`: string | null (Optional)
  - `timestamp`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Admin only.
  - Create: Server audit logger.
  - Update / Delete: Strictly prohibited (immutable write-once audit trail).
- **Indexes**: `(timestamp DESC)`, `(eventType ASC, timestamp DESC)`.
- **Retention**: 7 years.

---

#### 22. `app_config`
- **Document ID Strategy**: Singleton document ID `global`.
- **Fields & Types**:
  - `configId`: string ('global') (Required)
  - `platformFeePercentage`: number (0% Brokerage Guarantee) (Required)
  - `defaultGstPercentage`: number (5%) (Required)
  - `minBookingAdvanceHours`: number (Required)
  - `defaultCancellationPolicyId`: string (Required)
  - `extensionOfferDiscountPercent`: number (15%) (Required)
  - `maintenanceMode`: boolean (Required)
  - `updatedBy`: string (Admin UID) (Required)
  - `updatedAt`: ISO 8601 string (Required)
- **Permissions**:
  - Read: Public / Authenticated.
  - Create / Update: Authorized Admin only (`adminDomainService.updateApprovedAppConfiguration`).
  - Delete: Forbidden.
- **Retention**: Indefinite.

