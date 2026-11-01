import * as admin from 'firebase-admin';
import {
  VerificationCaseDocument,
  StartVerificationInput,
  StartVerificationResult,
  AdminReviewInput,
} from './verificationTypes';
import { NotFoundError, UnauthorizedError } from '../../common/errors';
import { auditService } from '../../audit/auditService';

export class IdentityVerificationService {
  private get db() {
    return admin.firestore();
  }

  /**
   * Helper to compute age from Date of Birth
   */
  calculateAge(dobString: string, referenceDate: Date = new Date()): number {
    const birthDate = new Date(dobString);
    let age = referenceDate.getFullYear() - birthDate.getFullYear();
    const m = referenceDate.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && referenceDate.getDate() < birthDate.getDate())) {
      age--;
    }
    return age;
  }

  /**
   * 1. startVerification
   * Initializes identity verification case with configurable minimum age requirement.
   * Keeps raw identity files and raw numbers out of ordinary user profiles.
   */
  async startVerification(input: StartVerificationInput): Promise<StartVerificationResult> {
    const { userId, verificationType, consentVersion, dateOfBirth, minimumAgePolicy = 18 } = input;

    // Verify user profile exists
    const userRef = this.db.collection('users').doc(userId);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      throw new NotFoundError('User profile not found.');
    }

    const verificationId = `VERIF-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const now = new Date();
    const nowStr = now.toISOString();

    // Data retention until 1 year from submission per approved privacy guidelines
    const retentionDate = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);

    let isAgeEligible = false;
    let status: VerificationCaseDocument['status'] = 'pending';

    if (dateOfBirth) {
      const calculatedAge = this.calculateAge(dateOfBirth, now);
      if (calculatedAge >= minimumAgePolicy) {
        isAgeEligible = true;
      } else {
        // Under configured age threshold
        status = 'rejected';
      }
    }

    // Default simulation for mock/sandbox provider
    const isMock = process.env.NODE_ENV !== 'production' || !process.env.HYPERVERGE_APP_ID;
    let providerRef = `ref_mock_${Date.now()}`;
    let providerSessionUrl = `https://verify.roomwala.in/session/${verificationId}`;

    if (isMock) {
      // Auto-verify if age is eligible, else manual_review
      if (isAgeEligible) {
        status = 'verified';
      } else if (status !== 'rejected') {
        status = 'manual_review';
      }
    }

    const verificationCase: VerificationCaseDocument = {
      verificationId,
      userId,
      verificationType,
      provider: isMock ? 'mock' : 'hyperverge',
      providerReference: providerRef,
      status,
      submittedAt: nowStr,
      reviewedAt: status === 'verified' ? nowStr : null,
      reviewedBy: status === 'verified' ? 'system_provider' : null,
      rejectionReasonCode: status === 'rejected' ? 'UNDER_AGE_LIMIT' : null,
      expiresAt: new Date(now.getTime() + 730 * 24 * 60 * 60 * 1000).toISOString(), // 2 year validity
      retentionUntil: retentionDate.toISOString(),
      consentVersion,
      minimumAgeRequired: minimumAgePolicy,
      ageVerified: isAgeEligible,
      createdAt: nowStr,
      updatedAt: nowStr,
    };

    // Store in restricted collection `verification_cases`
    await this.db.collection('verification_cases').doc(verificationId).set(verificationCase);

    // Update minimal, non-sensitive summary on user profile
    await userRef.update({
      identityVerificationStatus: status,
      ageEligibilityStatus: isAgeEligible ? 'eligible' : status === 'rejected' ? 'ineligible' : 'pending',
      updatedAt: nowStr,
    });

    await auditService.recordEvent({
      eventType: status === 'verified' ? 'ID_VERIFIED' : 'ID_VERIFICATION_SUBMITTED',
      userId,
      resourceId: verificationId,
      details: { verificationType, status, ageEligible: isAgeEligible },
    });

    return {
      verificationId,
      status,
      providerSessionUrl,
      ageEligible: isAgeEligible,
      requiresManualReview: status === 'manual_review',
    };
  }

  /**
   * 2. getVerificationStatus
   * Restricted: User can view only their own case; Admins can view any.
   */
  async getVerificationStatus(verificationId: string, viewerUid: string, userRole: string = 'customer'): Promise<VerificationCaseDocument> {
    const snap = await this.db.collection('verification_cases').doc(verificationId).get();
    if (!snap.exists) {
      throw new NotFoundError('Verification case not found.');
    }
    const verif = snap.data() as VerificationCaseDocument;

    if (verif.userId !== viewerUid && userRole !== 'admin') {
      throw new UnauthorizedError('Restricted document access.');
    }

    return verif;
  }

  /**
   * 3. handleVerificationProviderWebhook
   * Trusted backend / provider webhook to set verified or rejected state.
   */
  async handleVerificationProviderWebhook(
    providerReference: string,
    resultStatus: 'verified' | 'rejected' | 'manual_review',
    rejectionReasonCode?: string
  ): Promise<void> {
    const snap = await this.db
      .collection('verification_cases')
      .where('providerReference', '==', providerReference)
      .limit(1)
      .get();

    if (snap.empty) return;

    const caseDoc = snap.docs[0];
    const caseData = caseDoc.data() as VerificationCaseDocument;
    const nowStr = new Date().toISOString();

    await caseDoc.ref.update({
      status: resultStatus,
      reviewedAt: nowStr,
      reviewedBy: 'provider_webhook',
      rejectionReasonCode: rejectionReasonCode || null,
      updatedAt: nowStr,
    });

    // Mirror status on user document
    await this.db.collection('users').doc(caseData.userId).update({
      identityVerificationStatus: resultStatus,
      updatedAt: nowStr,
    });

    if (resultStatus === 'verified') {
      await auditService.recordEvent({
        eventType: 'ID_VERIFIED',
        userId: caseData.userId,
        resourceId: caseData.verificationId,
        details: { providerReference },
      });
    }
  }

  /**
   * 4. adminReviewVerification
   * Manual review fallback conducted by authorized admin.
   */
  async adminReviewVerification(input: AdminReviewInput): Promise<void> {
    const { verificationId, adminUid, decision, rejectionReasonCode } = input;

    const caseRef = this.db.collection('verification_cases').doc(verificationId);
    const snap = await caseRef.get();
    if (!snap.exists) throw new NotFoundError('Verification case not found.');
    const caseData = snap.data() as VerificationCaseDocument;

    const newStatus = decision === 'approve' ? 'verified' : 'rejected';
    const nowStr = new Date().toISOString();

    await caseRef.update({
      status: newStatus,
      reviewedAt: nowStr,
      reviewedBy: adminUid,
      rejectionReasonCode: decision === 'reject' ? (rejectionReasonCode || 'ADMIN_REJECTED') : null,
      updatedAt: nowStr,
    });

    await this.db.collection('users').doc(caseData.userId).update({
      identityVerificationStatus: newStatus,
      updatedAt: nowStr,
    });

    await auditService.recordEvent({
      eventType: newStatus === 'verified' ? 'ID_VERIFIED' : 'ID_VERIFICATION_SUBMITTED',
      userId: caseData.userId,
      resourceId: verificationId,
      details: { decision, reviewedBy: adminUid },
    });
  }

  /**
   * 5. requestVerificationRetry
   */
  async requestVerificationRetry(userId: string): Promise<void> {
    const userRef = this.db.collection('users').doc(userId);
    const snap = await userRef.get();
    if (!snap.exists) throw new NotFoundError('User not found.');

    const nowStr = new Date().toISOString();
    await userRef.update({
      identityVerificationStatus: 'pending',
      updatedAt: nowStr,
    });
  }
}

export const identityVerificationService = new IdentityVerificationService();
