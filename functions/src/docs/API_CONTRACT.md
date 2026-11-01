# RoomWala 2.0: Complete API Contract Specification
*Production Backend Standard: Authenticated Callable Endpoints & Dedicated HTTPS Webhooks*

All client responses adhere to the standard JSON envelopes:

### Standard Success Response Format
```json
{
  "success": true,
  "data": { ... },
  "requestId": "req_1730300000_a1b2c3d4"
}
```

### Standard Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "BOOKING_CONFLICT",
    "message": "The selected dates are no longer available."
  },
  "requestId": "req_1730300000_a1b2c3d4"
}
```

---

## 1. Authentication & User Services (`/auth`, `/users`)
| Endpoint / Function | Method | Auth | Role | Input Payload | Success Data | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `getMyProfile` | `GET /users/me` | Yes | Any | None | `UserProfileDocument` | `NOT_FOUND`, `UNAUTHORIZED` |
| `updateMyProfile` | `PUT /users/me` | Yes | Any | `{ fullName?: string, preferredLanguage?: string, notificationPreferences?: object }` | `{ user: UserProfileDocument }` | `INVALID_INPUT`, `UNAUTHORIZED` |
| `requestAccountDeletion` | `POST /users/me/delete` | Yes | Any | `{ reason?: string }` | `{ status: "pending_deletion" }` | `ACTIVE_BOOKINGS_EXIST` |

---

## 2. Room & Listing Services (`/rooms`)
| Endpoint / Function | Method | Auth | Role | Input Payload | Success Data | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `createRoom` | `POST /rooms` | Yes | Owner/Admin | `CreateRoomInput` (title, pricePaise, photos >= 3, capacity, lat, lng) | `{ roomId: string, status: "draft" }` | `INVALID_PRICE`, `INSUFFICIENT_PHOTOS` |
| `updateRoom` | `PUT /rooms/:roomId` | Yes | Owner/Admin | Partial room fields | `{ room: RoomDocument }` | `NOT_FOUND`, `FORBIDDEN` |
| `getRoom` | `GET /rooms/:roomId` | No | Public | Query: `?viewerUid=...` | `RoomDocument` (exact address redacted if not booked) | `ROOM_NOT_FOUND` |
| `searchRooms` | `GET /rooms/search` | No | Public | Query: `city`, `checkIn`, `checkOut`, `minPrice`, `maxPrice`, `roomType` | `{ rooms: RoomDocument[], total: number }` | `INVALID_DATES` |
| `getOwnerRooms` | `GET /owner/rooms` | Yes | Owner/Admin | None | `{ rooms: RoomDocument[] }` | `UNAUTHORIZED` |
| `submitRoomForReview`| `POST /rooms/:roomId/submit` | Yes | Owner/Admin | None | `{ status: "pending_review" }` | `ROOM_INCOMPLETE` |

---

## 3. Availability & Inventory Locking (`/availability`)
| Endpoint / Function | Method | Auth | Role | Input Payload | Success Data | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `getRoomAvailability` | `GET /availability/:roomId` | No | Public | Query: `month=YYYY-MM` | `{ lockedDates: string[] }` | `ROOM_NOT_FOUND` |
| `createBookingHold` | `POST /availability/holds` | Yes | Customer | `{ roomId, checkIn, checkOut, guestCount, idempotencyKey }` | `BookingHoldQuoteResult` (holdId, expiresAt, quote) | `INVENTORY_CONFLICT`, `HOLD_EXPIRED` |
| `releaseBookingHold` | `POST /availability/holds/:id/release` | Yes | Customer | None | `{ released: true }` | `NOT_FOUND` |
| `setRoomAvailability` | `POST /owner/blocks` | Yes | Owner/Admin | `{ roomId, startDate, endDate, reason }` | `RoomBlockDocument` | `INVENTORY_CONFLICT` |
| `createRoomBlock` | `POST /owner/blocks` | Yes | Owner/Admin | `{ roomId, startDate, endDate, reason }` | `RoomBlockDocument` | `INVENTORY_CONFLICT` |

---

## 4. Booking Lifecycle (`/bookings`)
| Endpoint / Function | Method | Auth | Role | Input Payload | Success Data | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `createBookingFromHold`| `POST /bookings/confirm` | Yes | Customer | `{ holdId, paymentId }` | `BookingDocument` (accessPin, mapsUrl) | `HOLD_EXPIRED`, `PAYMENT_UNVERIFIED` |
| `getMyBookings` | `GET /bookings/me` | Yes | Customer | None | `BookingDocument[]` | `UNAUTHORIZED` |
| `getBookingDetails` | `GET /bookings/:id` | Yes | Customer/Host/Admin | None | `BookingDocument` | `FORBIDDEN`, `NOT_FOUND` |
| `getBookingTicket` | `GET /bookings/:id/ticket` | Yes | Customer | None | `{ accessPin, locationUrl, checkIn }` | `BOOKING_NOT_CONFIRMED` |
| `getOwnerBookings` | `GET /owner/bookings` | Yes | Owner/Admin | None | `BookingDocument[]` | `UNAUTHORIZED` |
| `cancelBooking` | `POST /refunds/cancel-booking`| Yes | Customer/Host/Admin | `{ bookingId, reason }` | `{ bookingStatus: "cancelled", refundStatus, refundAmountPaise }` | `NON_CANCELLABLE_STATE` |

---

## 5. Payments & Refunds (`/payments`, `/refunds`)
| Endpoint / Function | Method | Auth | Role | Input Payload | Success Data | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `createPaymentOrder` | `POST /payments/order` | Yes | Customer | `{ holdId }` | `{ paymentId, providerOrderId, amountPaise, keyId }` | `HOLD_EXPIRED` |
| `verifyPayment` | `POST /payments/verify` | Yes | Customer | `{ paymentId, providerOrderId, providerPaymentId, signature }` | `{ success: true, bookingId: string }` | `SIGNATURE_VERIFICATION_FAILED` |
| `getPaymentStatus` | `GET /payments/:id` | Yes | Customer/Admin | None | `PaymentDocument` | `NOT_FOUND` |
| `paymentWebhook` | `POST /payments/webhook` | No (HMAC) | Razorpay Webhook | Razorpay Webhook Payload (`x-razorpay-signature`) | `{ received: true, processed: true }` | `INVALID_WEBHOOK_SIGNATURE` |
| `initiateRefund` | `POST /payments/:id/refund`| Yes | Customer/Admin | `{ reason, amountPaise? }` | `RefundResult` | `NON_REFUNDABLE` |
| `getRefundStatus` | `GET /payments/refunds/:id`| Yes | Customer/Admin | None | `RefundDocument` | `NOT_FOUND` |

---

## 6. Verification (`/verification`)
| Endpoint / Function | Method | Auth | Role | Input Payload | Success Data | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `startVerification` | `POST /verification/start` | Yes | Customer/Owner | `{ verificationType, consentVersion, documentNumberMasked, dateOfBirth }` | `{ verificationId, status, ageEligible }` | `UNDER_AGE_LIMIT` |
| `getVerificationStatus`| `GET /verification/:id` | Yes | Applicant/Admin| None | `VerificationCaseDocument` | `NOT_FOUND`, `FORBIDDEN` |
| `verificationProviderWebhook` | `POST /verification/webhook` | No (Signed) | Provider | `{ providerReference, status, rejectionReasonCode }` | `{ success: true }` | `INVALID_PROVIDER_SIGNATURE` |

---

## 7. Notifications & WhatsApp (`/notifications`)
| Endpoint / Function | Method | Auth | Role | Input Payload | Success Data | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `getMyNotifications` | `GET /notifications` | Yes | Any | None | `NotificationDocument[]` | `UNAUTHORIZED` |
| `markNotificationRead`| `POST /notifications/:id/read` | Yes | Recipient | None | `{ success: true }` | `NOT_FOUND` |
| `markAllNotificationsRead` | `POST /notifications/read-all` | Yes | Recipient | None | `{ markedCount: number }` | `UNAUTHORIZED` |

---

## 8. Stay Extension Priority (`/extensions`)
| Endpoint / Function | Method | Auth | Role | Input Payload | Success Data | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `getEligibleExtensionOffers` | `GET /extensions` | Yes | Customer | None | `ExtensionOfferDocument[]` | `UNAUTHORIZED` |
| `createExtensionOffer`| `POST /extensions/create` | Yes | System/Admin | `{ bookingId, extensionNights, discountPercentage }` | `ExtensionOfferDocument` | `EXTENSION_CONFLICT` |
| `acceptExtensionOffer` | `POST /extensions/:id/accept` | Yes | Customer | None | `ExtensionOfferDocument` | `OFFER_EXPIRED` |
| `declineExtensionOffer`| `POST /extensions/:id/decline`| Yes | Customer | None | `{ success: true }` | `NOT_FOUND` |
| `requestExtensionDates`| `POST /extensions/:id/dates` | Yes | Customer | `{ newRequestedCheckOut }` | `ExtensionOfferDocument` | `DATES_CONFLICT` |
| `confirmExtension` | `POST /extensions/:id/confirm`| Yes | Customer | `{ paymentId }` | `BookingDocument` | `INVENTORY_CONFLICT` |

---

## 9. Reviews & Support (`/reviews`, `/support`)
| Endpoint / Function | Method | Auth | Role | Input Payload | Success Data | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `createReview` | `POST /reviews` | Yes | Customer | `{ bookingId, rating, comment, photoUrls }` | `ReviewDocument` | `BOOKING_NOT_COMPLETED`, `DUPLICATE_REVIEW` |
| `getRoomReviews` | `GET /reviews/room/:roomId`| No | Public | None | `ReviewDocument[]` | `ROOM_NOT_FOUND` |
| `createSupportTicket` | `POST /support/tickets` | Yes | Any | `{ category, subject, description, attachmentUrls, priority }` | `SupportTicketDocument` | `INVALID_INPUT` |
| `getMySupportTickets` | `GET /support/tickets` | Yes | Author | None | `SupportTicketDocument[]` | `UNAUTHORIZED` |
| `reportRoom` | `POST /support/reports` | Yes | Any | `{ targetType: "room", targetId, reportCategory, description }` | `ReportDocument` | `INVALID_INPUT` |

---

## 10. Owner & Admin Operations (`/owner`, `/admin`)
| Endpoint / Function | Method | Auth | Role | Input Payload | Success Data | Error Codes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `getOwnerDashboard` | `GET /owner/dashboard` | Yes | Owner/Admin | None | `OwnerDashboardMetrics` | `FORBIDDEN` |
| `getOwnerEarnings` | `GET /owner/earnings` | Yes | Owner/Admin | None | `{ grossEarningsPaise, netEarningsPaise, totalBookings }` | `FORBIDDEN` |
| `getOwnerPayouts` | `GET /owner/payouts` | Yes | Owner/Admin | None | `OwnerPayoutDocument[]` | `FORBIDDEN` |
| `getAdminDashboard` | `GET /admin/dashboard` | Yes | Admin | None | `AdminDashboardMetrics` | `FORBIDDEN` |
| `suspendUser` | `POST /admin/users/:id/suspend` | Yes | Admin | `{ reason }` | `{ success: true }` | `USER_NOT_FOUND` |
| `reviewRoomApproval`| `POST /admin/rooms/:id/review` | Yes | Admin | `{ action: "approve" \| "reject", rejectionReason }` | `{ success: true }` | `ROOM_NOT_FOUND` |
| `reviewRefund` | `POST /admin/refunds/:id/review`| Yes | Admin | `{ action: "approve" \| "reject", notes }` | `{ success: true }` | `REFUND_NOT_FOUND` |

