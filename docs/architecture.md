# RoomWala Production Architecture Documentation

## 1. High-Level System Overview
RoomWala is a zero-brokerage room rental marketplace connecting verified room owners directly with verified guests.

```mermaid
flowchart TD
    Client["Flutter Mobile & Web Client"] --> CF["Firebase Cloud Functions (Node.js 20 / TypeScript)"]
    Client --> Auth["Firebase Authentication"]
    Client --> Firestore["Cloud Firestore"]
    Client --> Storage["Firebase Storage"]
    CF --> Razorpay["Razorpay Escrow Gateway"]
    CF --> WhatsApp["Meta WhatsApp Business Cloud API"]
    CF --> FCM["Firebase Cloud Messaging"]
    Scheduler["Cloud Scheduler"] --> CF
```

## 2. Core Service Boundaries
1. **Auth & Identity Verification**: Secure metadata verification with protected raw ID storage in Firebase Storage.
2. **Atomic Booking Pipeline**: Firestore transactions guarantee zero double-bookings with slot locking.
3. **Escrow Payments**: Razorpay signature verification and automated payout scheduling.
4. **Stay Extension Priority**: 24-hour departure trigger reserving extension window exclusively for active guests.

