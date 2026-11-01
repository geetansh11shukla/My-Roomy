# RoomWala Local Developer Setup Guide

## Prerequisites
1. Node.js 20+ & npm
2. Flutter SDK 3.x
3. Firebase CLI (`npm install -g firebase-tools`)

## Quickstart
1. Install functions dependencies:
   ```bash
   cd functions && npm install
   ```
2. Build and verify:
   ```bash
   npm run build
   npm test
   ```
3. Run Firebase Emulators:
   ```bash
   firebase emulators:start
   ```
4. Run Flutter client:
   ```bash
   flutter run -d chrome
   ```

