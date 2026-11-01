# Privacy & Security Guidelines

1. **Zero Raw ID Exposure**: Aadhaar / Passport scans stored strictly under `/identity_verifications/{userId}` with public read disabled.
2. **Zero Payment Secrets in Frontend**: Razorpay secrets never bundled in Flutter client.
3. **Role Enforcement**: Customer, Owner and Admin routes protected by Firebase Auth custom claims and middleware.

