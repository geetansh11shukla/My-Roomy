# RoomWala REST & Functions API Reference

## Base URL
- Local Emulator: `http://localhost:5001/roomwala-production/us-central1/api`
- Production: `https://us-central1-roomwala-production.cloudfunctions.net/api`

## Endpoints

### 1. Health
- `GET /health`: System diagnostic & status.

### 2. Payments
- `POST /payments/order`: Creates Razorpay escrow order.
- `POST /payments/verify`: Validates HMAC-SHA256 signature.

### 3. Extensions
- `GET /extensions/:bookingId`: Retrieves active Stay Extension Priority offers.
- `POST /extensions/accept`: Confirms stay extension and updates checkout date.

