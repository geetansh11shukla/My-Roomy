export type UserRole = 'customer' | 'owner' | 'admin';
export type AccountStatus = 'active' | 'suspended' | 'pending_deletion' | 'deleted';
export type AgeEligibilityStatus = 'not_checked' | 'pending' | 'eligible' | 'ineligible' | 'manual_review';
export type IdentityVerificationStatus = 'not_started' | 'pending' | 'verified' | 'rejected' | 'expired' | 'manual_review';

export interface UserProfileDocument {
  uid: string;
  fullName: string;
  email: string | null;
  phoneNumber: string;
  phoneVerified: boolean;
  emailVerified: boolean;
  role: UserRole;
  accountStatus: AccountStatus;
  profilePhotoUrl: string | null;
  dateOfBirth: string | null; // ISO timestamp or null
  ageEligibilityStatus: AgeEligibilityStatus;
  identityVerificationStatus: IdentityVerificationStatus;
  preferredLanguage: string;
  notificationPreferences: {
    bookingUpdates: boolean;
    paymentUpdates: boolean;
    promotionalOffers: boolean;
    extensionOffersAndReminders: boolean;
    pushNotifications: boolean;
    whatsappConsent: boolean;
  };
  termsAcceptedVersion: string | null;
  termsAcceptedAt: string | null;
  createdAt: string;
  updatedAt: string;
  lastLoginAt: string | null;
}

export type EditableUserFields = Partial<Pick<UserProfileDocument, 'fullName' | 'profilePhotoUrl' | 'preferredLanguage' | 'notificationPreferences'>>;

