# RoomWala Production Deployment Guide

## Deploying Firebase Services
```bash
firebase deploy --only firestore:rules,storage:rules
firebase deploy --only functions
```

## Environment Secrets Setup
```bash
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET
firebase functions:secrets:set WHATSAPP_CLOUD_API_TOKEN
```

