import { Router } from 'express';
import { identityVerificationService } from './identityVerificationService';
import { authenticate } from '../../middleware/authenticate';
import { authorize } from '../../middleware/authorize';

export const verificationRouter = Router();

/**
 * 1. POST /verification/start
 * Customer starts identity verification.
 */
verificationRouter.post('/start', authenticate, async (req, res) => {
  try {
    const userId = (req as any).user.uid;
    const { verificationType, consentVersion, documentNumberMasked, dateOfBirth, minimumAgePolicy } = req.body;

    if (!verificationType || !consentVersion) {
      return res.status(400).json({ success: false, message: 'verificationType and consentVersion are required.' });
    }

    const result = await identityVerificationService.startVerification({
      userId,
      verificationType,
      consentVersion,
      documentNumberMasked: documentNumberMasked || 'XXXX-XXXX-XXXX',
      dateOfBirth,
      minimumAgePolicy,
    });

    return res.status(201).json({ success: true, result });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 2. GET /verification/:verificationId
 * Restricted access to verification case status.
 */
verificationRouter.get('/:verificationId', authenticate, async (req, res) => {
  try {
    const { verificationId } = req.params;
    const viewerUid = (req as any).user.uid;
    const userRole = (req as any).user.role || 'customer';

    const caseDoc = await identityVerificationService.getVerificationStatus(verificationId, viewerUid, userRole);
    return res.json({ success: true, verificationCase: caseDoc });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 3. POST /verification/webhook
 * Provider webhook callback.
 */
verificationRouter.post('/webhook', async (req, res) => {
  try {
    const { providerReference, status, rejectionReasonCode } = req.body;
    if (!providerReference || !status) {
      return res.status(400).json({ success: false, message: 'providerReference and status are required.' });
    }

    await identityVerificationService.handleVerificationProviderWebhook(
      providerReference,
      status,
      rejectionReasonCode
    );

    return res.json({ success: true });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 4. POST /verification/admin/review
 * Admin manual review.
 */
verificationRouter.post('/admin/review', authenticate, authorize(['admin']), async (req, res) => {
  try {
    const { verificationId, decision, rejectionReasonCode } = req.body;
    const adminUid = (req as any).user.uid;

    if (!verificationId || !decision) {
      return res.status(400).json({ success: false, message: 'verificationId and decision are required.' });
    }

    await identityVerificationService.adminReviewVerification({
      verificationId,
      adminUid,
      decision,
      rejectionReasonCode,
    });

    return res.json({ success: true, message: `Verification case ${decision}ed successfully.` });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

/**
 * 5. POST /verification/retry
 */
verificationRouter.post('/retry', authenticate, async (req, res) => {
  try {
    const userId = (req as any).user.uid;
    await identityVerificationService.requestVerificationRetry(userId);
    return res.json({ success: true, message: 'Verification status reset for retry.' });
  } catch (err: any) {
    return res.status(err.statusCode || 500).json({ success: false, message: err.message });
  }
});

