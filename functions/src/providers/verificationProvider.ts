export interface VerificationAuditResult {
  isVerified: boolean;
  age: number;
  isAdultEligible: boolean;
  maskedId: string;
  provider: 'aadhaar_offline_xml' | 'manual_review' | 'sandbox';
}

export interface IIdentityVerificationProvider {
  verifyDocument(documentType: string, rawNumber: string, dob: string): Promise<VerificationAuditResult>;
}

export class IdentityVerificationProvider implements IIdentityVerificationProvider {
  async verifyDocument(documentType: string, rawNumber: string, dob: string): Promise<VerificationAuditResult> {
    const birthYear = new Date(dob).getFullYear();
    const currentYear = new Date().getFullYear();
    const age = currentYear - birthYear;
    const isAdultEligible = age >= 18;

    const cleanNum = rawNumber.replace(/\s+/g, '');
    const maskedId = cleanNum.length >= 4 ? `•••• •••• ${cleanNum.slice(-4)}` : '••••';

    return {
      isVerified: isAdultEligible,
      age,
      isAdultEligible,
      maskedId,
      provider: 'sandbox',
    };
  }
}

export const verificationProvider = new IdentityVerificationProvider();

