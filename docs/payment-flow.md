# RoomWala Escrow Payment Flow

## 1. Flow Overview
1. Customer initiates checkout on Flutter client.
2. Cloud Function calls Razorpay API to generate an authenticated order.
3. Razorpay SDK opens on mobile/web client.
4. Signature verification executes on backend via SHA-256 HMAC.
5. Escrow hold is established until check-in.

