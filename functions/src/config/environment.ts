export const environment = {
  isProduction: process.env.NODE_ENV === 'production',
  nodeEnv: process.env.NODE_ENV || 'development',
  projectId: process.env.GCLOUD_PROJECT || 'roomwala-prod',
  razorpay: {
    keyId: process.env.RAZORPAY_KEY_ID || '',
    keySecret: process.env.RAZORPAY_KEY_SECRET || '',
  },
  whatsapp: {
    cloudApiToken: process.env.WHATSAPP_CLOUD_API_TOKEN || '',
    phoneNumberId: process.env.WHATSAPP_PHONE_NUMBER_ID || '',
  },
  smtp: {
    user: process.env.SMTP_EMAIL || '',
    pass: process.env.SMTP_APP_PASSWORD || '',
  },
  corsOrigin: process.env.CORS_ORIGIN || '*',
};

