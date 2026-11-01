import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class LegalPolicyScreen extends StatelessWidget {
  final String title;
  final String contentKey;

  const LegalPolicyScreen({
    super.key,
    required this.title,
    required this.contentKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(title: title, showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              _getContent(),
              style: const TextStyle(color: textWhite, fontSize: 13, height: 1.6),
            ),
          ),
        ),
      ),
    );
  }

  String _getContent() {
    switch (contentKey) {
      case 'terms':
        return '''ROOMWALA 2.0 TERMS AND CONDITIONS OF SERVICE
Last Updated: October 2026

1. SCOPE OF SERVICES
My Roomy is a direct room discovery, digital verification, and automated door access facilitation platform operating under Indian hospitality guidelines. My Roomy eliminates middleman brokerage fees by enabling direct host-guest interactions governed by automated smart rules.

2. ZERO CHAT & HARASSMENT PREVENTION POLICY
To eliminate harassment, unauthorized bargaining, and unrecorded disputes, direct unstructured chat between host and guest is prohibited. All essential access credentials, digital door lock PINs, and verified Google Maps locations are dispatched automatically via WhatsApp through verified My Roomy webhooks.

3. AGE & IDENTITY VERIFICATION MANDATE
All primary guests checking into any room must be at least 18 years of age and hold a valid Government-issued identity document (Aadhaar, Driving License, Voter ID, or Passport). Falsification of identification results in immediate booking revocation without refund eligibility.

4. ESCROW TRANSACTION PROTECTION
All payments are collected through PCI-DSS certified gateway escrow accounts. Funds are held in security escrow until verified guest check-in, safeguarding both guest and property owner against fraud.

5. JURISDICTION
These terms are governed by the laws of India. Any legal disputes arising hereunder shall be subject to the exclusive jurisdiction of the competent courts in Lucknow, Uttar Pradesh.''';

      case 'privacy':
        return '''ROOMWALA PRIVACY POLICY & DATA RETENTION
Last Updated: October 2026

1. DATA COLLECTION PRINCIPLES
We collect only the minimum required information necessary to facilitate room access:
- Full legal name and contact details (email and WhatsApp phone number).
- Date of birth for 18+ eligibility verification.
- Offline KYC verification tokens through approved DigiLocker / UIDAI verification APIs.

2. IDENTITY ENCRYPTION GUARANTEE
My Roomy NEVER stores raw, unmasked biometric data, full physical Aadhaar copies, or payment card CVV numbers on its database servers. All verification credentials are processed via short-lived cryptographic tokens.

3. AUTOMATED WHATSAPP COMMUNICATION CONSENT
By making a reservation on My Roomy, you consent to receive transactional booking passes, digital door PIN codes, directions, and 24-hour checkout reminders on your registered WhatsApp number.

4. USER RIGHTS & DATA DELETION
Users maintain the right to review their profile data and request account deletion directly from the Settings menu. Upon account deletion request, personal records are permanently anonymized within 30 days, subject to mandatory tax retention regulations.''';

      case 'cancellation':
        return '''CANCELLATION AND REFUND POLICY
Last Updated: October 2026

1. 100% FREE CANCELLATION WINDOW
Guests may cancel any confirmed booking up to 24 hours prior to the scheduled 12:00 PM check-in date without incurring any cancellation penalty. A 100% full refund of the room subtotal and platform fee is credited back to the original payment source.

2. CANCELLATION WITHIN 24 HOURS
Cancellations requested within 24 hours of scheduled check-in are subject to a one-night fee deduction to compensate the room host for holding the exclusive reservation slot. The remaining balance is refunded.

3. ESCROW REFUND TIMELINES
All refunds are processed through automated gateway webhooks. Refunds typically reflect on original payment sources (UPI, NetBanking, Debit/Credit Cards) within 24 to 48 banking hours.

4. EXTENSION REFUNDABILITY
Confirmed stay extensions are subject to the same standard 24-hour cancellation rules from the newly calculated extension checkout timestamp.''';

      case 'rules':
        return '''ROOMWALA GUEST & OWNER HOUSE RULES
Last Updated: October 2026

GUEST CODE OF CONDUCT:
- 18+ Government ID must be presented upon check-in or verified digitally.
- Self check-in via Digital PIN starts at 12:00 PM. Check-out is strictly 11:00 AM.
- No loud noise, parties, or disturbances after 10:00 PM out of respect for neighbors.
- Commercial or illegal activities inside the room are strictly prohibited.

HOST & OWNER OBLIGATIONS:
- Room owners must maintain 100% photo and amenity accuracy.
- Confirmed booking dates cannot be cancelled or blocked by owners without verified emergency justification.
- Payouts are settled automatically to the owner's bank account within 24 hours of guest check-in.''';

      default:
        return 'Policy content is verified and up-to-date.';
    }
  }
}
