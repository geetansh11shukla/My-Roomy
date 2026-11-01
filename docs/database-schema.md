# RoomWala Database Schema (Cloud Firestore)

## Collections

### 1. `users/{userId}`
- `uid`: string (Primary Key)
- `fullName`: string
- `phoneNumber`: string
- `email`: string
- `role`: 'customer' | 'owner' | 'admin'
- `identityVerificationStatus`: 'not_started' | 'pending' | 'verified' | 'rejected'
- `ageEligibilityStatus`: 'eligible_18_plus' | 'underage' | 'unverified'
- `notificationPreferences`: map

### 2. `rooms/{roomId}`
- `roomId`: string
- `ownerId`: string
- `title`: string
- `locality`: string
- `city`: string
- `pricePerNight`: number
- `bookedDates`: string[] (e.g. `['2026-11-15', '2026-11-16']`)
- `listingStatus`: 'draft' | 'pending' | 'published' | 'rejected' | 'suspended'

### 3. `bookings/{bookingId}`
- `bookingId`: string
- `roomId`: string
- `customerId`: string
- `ownerId`: string
- `checkIn`: string
- `checkOut`: string
- `nightCount`: number
- `totalAmount`: number
- `bookingStatus`: 'confirmed' | 'cancelled' | 'extended'
- `accessPin`: string (e.g. `PIN-8812`)
- `locationUrl`: string

