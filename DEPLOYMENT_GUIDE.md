# RoomWala 2.0: Beginner-Friendly Deployment and Setup Guide
*Operating System Target: Windows (PowerShell) | Node.js v20+ | Firebase CLI v13+ | Flutter SDK 3.x+*

---

## 1. Prerequisites and Version Requirements
Before starting, ensure the following software versions are installed on your machine:
- **Node.js**: `v20.x LTS` (Check with `node -v`)
- **npm**: `v10.x+` (Check with `npm -v`)
- **Firebase CLI**: `v13.x+` (Install globally: `npm install -g firebase-tools`, check with `firebase --version`)
- **Flutter SDK**: `3.x+` (Check with `flutter --version`)
- **Google Cloud SDK / gcloud CLI** (Optional, for advanced Secret Manager operations)

---

## 2. Firebase Project & Platform Setup

### Step 2.1: Log in to Firebase CLI
In Windows PowerShell:
```powershell
firebase login
```

### Step 2.2: Create a Firebase Project
1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and name it (e.g., `roomwala-prod` or `roomwala-dev`).
3. Enable or disable Google Analytics based on your preference and click **Create Project**.
4. **Billing Plan**: Upgrade your project to the **Blaze (Pay as you go)** plan.
   > *Note:* Cloud Functions (Node.js runtime) and outbound networking to Razorpay and WhatsApp Cloud API require the Blaze plan.

### Step 2.3: Register Apps & Configure FlutterFire
From the root repository directory (`E:\Room Wala 2.0`):
```powershell
# Activate flutterfire_cli
dart pub global activate flutterfire_cli

# Configure Firebase options for Android, iOS, and Web
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID>
```
This automatically updates `lib/firebase_options.dart` and links Android `google-services.json` and iOS `GoogleService-Info.plist`.

---

## 3. Firebase Services Provisioning

### Step 3.1: Enable Authentication Providers
In Firebase Console > **Authentication** > **Sign-in method**:
1. Enable **Phone**: Required for customer OTP login.
2. Enable **Email/Password**: For email credentials.

### Step 3.2: Provision Cloud Firestore
In Firebase Console > **Firestore Database**:
1. Click **Create database**.
2. Location: Select **`asia-south1` (Mumbai)** for lowest latency in India.
3. Start in **Production mode** (Security rules will be deployed from the repo).

### Step 3.3: Provision Firebase Storage
In Firebase Console > **Storage**:
1. Click **Get Started**.
2. Location: Select **`asia-south1` (Mumbai)**.

---

## 4. Environment Configuration & Google Secret Manager

### Step 4.1: Local Environment File
In the project root, copy `.env.example`:
```powershell
Copy-Item .env.example .env
```
Fill in sandbox/development values for Razorpay and WhatsApp credentials.

### Step 4.2: Production Secrets (Zero Credentials in Terminal History)
For production Cloud Functions, use Firebase Secret Manager so secrets are never saved in source code:
```powershell
# Set secrets interactively without exposing them in shell history
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET
firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
firebase functions:secrets:set WHATSAPP_CLOUD_API_TOKEN
firebase functions:secrets:set WHATSAPP_PHONE_NUMBER_ID
```

---

## 5. Local Development & Firebase Emulator Suite

### Step 5.1: Install Functions Dependencies
```powershell
cd functions
npm install
cd ..
```

### Step 5.2: Start Local Emulators
Run Firestore, Auth, Storage, and Functions locally:
```powershell
firebase emulators:start --only auth,firestore,storage,functions
```
- Emulator UI: `http://localhost:4000`
- Functions HTTP: `http://localhost:5001/<project-id>/asia-south1/app`

---

## 6. Running Automated Tests

### Step 6.1: Run Backend Vitest Test Suite (58 Tests Across 14 Domains)
In Windows PowerShell:
```powershell
cd functions
npm test
cd ..
```
*Expected Result: 14 test files passed, 58/58 tests passing.*

### Step 6.2: Run Frontend Flutter Test Suite (15 Tests)
```powershell
flutter test
```
*Expected Result: 15/15 tests passing (Unit, Widget, and Service Integration).*

---

## 7. Deployment Procedures

### Step 7.1: Deploy Firestore Security Rules & Indexes
Deploy strict security rules (`firestore.rules`) and compound indexes (`firestore.indexes.json`):
```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

### Step 7.2: Deploy Storage Security Rules
Deploy restrictive storage rules (`storage.rules`):
```powershell
firebase deploy --only storage
```

### Step 7.3: Deploy Cloud Functions
Build and deploy TypeScript backend services:
```powershell
cd functions
npm run build
cd ..
firebase deploy --only functions
```

---

## 8. External Provider Webhook Configurations

### Step 8.1: Razorpay Webhook Configuration
1. Open the [Razorpay Dashboard](https://dashboard.razorpay.com/) > **Settings** > **Webhooks**.
2. Click **Add New Webhook**.
3. **Webhook URL**:
   `https://<REGION>-<PROJECT_ID>.cloudfunctions.net/app/payments/webhook`
4. **Secret**: Enter the exact string stored in `RAZORPAY_WEBHOOK_SECRET`.
5. **Active Events**:
   - `payment.captured`
   - `payment.failed`
   - `refund.processed`
   - `refund.failed`

### Step 8.2: WhatsApp Business Cloud API Configuration
1. Open the [Meta for Developers App Dashboard](https://developers.facebook.com/).
2. Under **WhatsApp** > **Configuration**:
   - **Callback URL**: `https://<REGION>-<PROJECT_ID>.cloudfunctions.net/app/notifications/whatsapp/webhook`
   - **Verify Token**: Configured `WHATSAPP_WEBHOOK_VERIFY_TOKEN`.
   - **Webhook Fields**: Subscribe to `messages`.
3. Create and submit the required Message Templates:
   - `booking_confirmation_ticket`
   - `owner_booking_alert`
   - `authorized_room_location`
   - `checkout_reminder_and_extension`

---

## 9. Rollback & Staging Procedures

### Staging Validation Checklist
1. Create a test room listing as Owner $\rightarrow$ verify status is `pending_review`.
2. Approve listing as Admin $\rightarrow$ verify listing is `published` in public search.
3. Reserve dates as Customer $\rightarrow$ verify atomic date lock creation in `room_date_locks`.
4. Trigger sandbox payment $\rightarrow$ verify digital door PIN and WhatsApp ticket delivery.
5. Cancel booking $\rightarrow$ verify automatic refund calculation and inventory release.

### Production Rollback Procedure
If an issue is detected post-deployment:
1. **Rollback Cloud Functions**:
   ```powershell
   # Deploy previously tagged git commit
   git checkout <PREVIOUS_RELEASE_TAG>
   cd functions; npm run build; cd ..
   firebase deploy --only functions
   ```
2. **Emergency Maintenance Mode**:
   Admin can toggle maintenance mode via Admin API or console:
   ```powershell
   Invoke-RestMethod -Uri "https://<PROJECT_URL>/admin/config" -Method Put -Headers @{ "Authorization" = "Bearer <ADMIN_TOKEN>" } -Body '{"maintenanceMode": true}' -ContentType "application/json"
   ```

