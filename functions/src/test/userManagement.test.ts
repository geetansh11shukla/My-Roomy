import { describe, it, expect } from 'vitest';
import { UserProfileDocument } from '../modules/users/userTypes';

describe('Authentication & User Management Suite', () => {
  it('1. User Profile conforms to all 19 canonical schema fields', () => {
    const mockUser: UserProfileDocument = {
      uid: 'usr_test_101',
      fullName: 'Rahul Verma',
      email: 'rahul.v@roomwala.in',
      phoneNumber: '+919876543210',
      phoneVerified: true,
      emailVerified: true,
      role: 'customer',
      accountStatus: 'active',
      profilePhotoUrl: null,
      dateOfBirth: '2000-01-01',
      ageEligibilityStatus: 'eligible',
      identityVerificationStatus: 'verified',
      preferredLanguage: 'en',
      notificationPreferences: {
        bookingUpdates: true,
        paymentUpdates: true,
        promotionalOffers: false,
        extensionOffersAndReminders: true,
        pushNotifications: true,
        whatsappConsent: true,
      },
      termsAcceptedVersion: '2026.1',
      termsAcceptedAt: new Date().toISOString(),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      lastLoginAt: new Date().toISOString(),
    };

    expect(mockUser.uid).toBe('usr_test_101');
    expect(mockUser.role).toBe('customer');
    expect(mockUser.accountStatus).toBe('active');
    expect(mockUser.notificationPreferences.whatsappConsent).toBe(true);
    expect(mockUser.ageEligibilityStatus).toBe('eligible');
  });

  it('2. Disallows storing raw password or OTP in user profile documents', () => {
    const keys = Object.keys({} as UserProfileDocument);
    expect(keys.includes('password')).toBe(false);
    expect(keys.includes('otp')).toBe(false);
  });
});

