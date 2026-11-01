export const featureFlags = {
  enableInstantBooking: true,
  enablePriorityExtension: true,
  enableWhatsAppNotifications: true,
  enableRazorpayEscrow: true,
  enableMockFallback: process.env.NODE_ENV !== 'production',
  enableSelfVerificationUpload: true,
};

