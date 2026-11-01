import * as admin from 'firebase-admin';
import { UserProfileDocument, EditableUserFields, UserRole } from './userTypes';
import { AppError, UnauthorizedError, NotFoundError } from '../../common/errors';
import { auditService } from '../../audit/auditService';

export class UserService {
  private get collection() {
    return admin.firestore().collection('users');
  }

  /**
   * Initializes or fetches a user profile upon Firebase Authentication login
   */
  async syncUserProfileOnLogin(
    uid: string,
    phoneNumber?: string,
    email?: string,
    fullName?: string
  ): Promise<UserProfileDocument> {
    const docRef = this.collection.doc(uid);
    const doc = await docRef.get();
    const now = new Date().toISOString();

    if (!doc.exists) {
      const newUser: UserProfileDocument = {
        uid,
        fullName: fullName || 'New Guest',
        email: email || null,
        phoneNumber: phoneNumber || '',
        phoneVerified: Boolean(phoneNumber),
        emailVerified: Boolean(email),
        role: 'customer', // Default role
        accountStatus: 'active',
        profilePhotoUrl: null,
        dateOfBirth: null,
        ageEligibilityStatus: 'not_checked',
        identityVerificationStatus: 'not_started',
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
        termsAcceptedAt: now,
        createdAt: now,
        updatedAt: now,
        lastLoginAt: now,
      };

      await docRef.set(newUser);
      await auditService.recordEvent({
        eventType: 'USER_SIGNUP',
        userId: uid,
        details: { role: 'customer', phoneVerified: newUser.phoneVerified },
      });
      return newUser;
    }

    // Existing user: update last login timestamp
    const existing = doc.data() as UserProfileDocument;
    if (existing.accountStatus === 'suspended') {
      throw new AppError('This account is suspended. Please contact support.', 403, 'ACCOUNT_SUSPENDED');
    }

    await docRef.update({
      lastLoginAt: now,
      updatedAt: now,
    });

    return { ...existing, lastLoginAt: now, updatedAt: now };
  }

  /**
   * Safely updates allowed user profile fields.
   * Disallows self-promotion of role or verification self-approval.
   */
  async updateProfile(uid: string, fields: EditableUserFields): Promise<UserProfileDocument> {
    const docRef = this.collection.doc(uid);
    const doc = await docRef.get();
    if (!doc.exists) {
      throw new NotFoundError('User profile not found.');
    }

    const current = doc.data() as UserProfileDocument;
    if (current.accountStatus === 'suspended') {
      throw new AppError('Suspended accounts cannot modify profile.', 403, 'ACCOUNT_SUSPENDED');
    }

    // Explicitly filter to allowed fields only
    const safeUpdates: Partial<UserProfileDocument> = {
      updatedAt: new Date().toISOString(),
    };

    if (fields.fullName !== undefined) safeUpdates.fullName = fields.fullName.trim();
    if (fields.profilePhotoUrl !== undefined) safeUpdates.profilePhotoUrl = fields.profilePhotoUrl;
    if (fields.preferredLanguage !== undefined) safeUpdates.preferredLanguage = fields.preferredLanguage;
    if (fields.notificationPreferences !== undefined) {
      safeUpdates.notificationPreferences = {
        ...current.notificationPreferences,
        ...fields.notificationPreferences,
      };
    }

    await docRef.update(safeUpdates);
    return { ...current, ...safeUpdates } as UserProfileDocument;
  }

  /**
   * Administrative role assignment (Must be performed by admin or trusted server provisioning)
   */
  async setRoleByAdmin(targetUid: string, newRole: UserRole, adminUid: string): Promise<void> {
    const adminDoc = await this.collection.doc(adminUid).get();
    if (!adminDoc.exists || (adminDoc.data() as UserProfileDocument).role !== 'admin') {
      throw new UnauthorizedError('Only administrators can assign user roles.');
    }

    await this.collection.doc(targetUid).update({
      role: newRole,
      updatedAt: new Date().toISOString(),
    });

    // Also update custom user claims in Firebase Auth for secure rule evaluation
    try {
      await admin.auth().setCustomUserClaims(targetUid, { role: newRole });
    } catch (e) {
      // Safe fallback in emulator / mock environment
    }
  }

  /**
   * Verifies identity & age through trusted verification workflow
   */
  async applyVerificationResult(
    uid: string,
    isAdultEligible: boolean,
    dob: string,
    isVerified: boolean
  ): Promise<void> {
    await this.collection.doc(uid).update({
      dateOfBirth: dob,
      ageEligibilityStatus: isAdultEligible ? 'eligible' : 'ineligible',
      identityVerificationStatus: isVerified ? 'verified' : 'rejected',
      updatedAt: new Date().toISOString(),
    });

    await auditService.recordEvent({
      eventType: isVerified ? 'ID_VERIFIED' : 'ID_VERIFICATION_SUBMITTED',
      userId: uid,
      details: { isAdultEligible, isVerified },
    });
  }
}

export const userService = new UserService();

