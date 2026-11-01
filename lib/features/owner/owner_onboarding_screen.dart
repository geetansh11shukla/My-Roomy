import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';
import 'owner_dashboard_screen.dart';

enum OnboardingStep { details, identity, payout, pendingReview, approved, rejected }

class OwnerOnboardingScreen extends StatefulWidget {
  const OwnerOnboardingScreen({super.key});

  @override
  State<OwnerOnboardingScreen> createState() => _OwnerOnboardingScreenState();
}

class _OwnerOnboardingScreenState extends State<OwnerOnboardingScreen> {
  OnboardingStep _currentStep = OnboardingStep.details;

  // Form Fields
  final _businessNameController = TextEditingController(text: 'Shukla Stays & Co.');
  final _contactPersonController = TextEditingController(text: 'Geetansh Shukla');
  final _phoneController = TextEditingController(text: '9876543210');
  final _emailController = TextEditingController(text: 'geetansh.stays@roomwala.in');
  final _cityController = TextEditingController(text: 'Lucknow');

  // Verification
  String _govIdType = 'PAN Card';
  final _govIdNumberController = TextEditingController(text: 'ABCPS1234F');
  final _propertyOwnershipDocController = TextEditingController(text: 'Electricity Bill / Property Tax Deed #LKO-2026-991');

  // Payout Account Details (Bank Transfer via Escrow)
  final _bankAccountController = TextEditingController(text: '918239019283');
  final _ifscController = TextEditingController(text: 'HDFC0001234');
  final _beneficiaryNameController = TextEditingController(text: 'Geetansh Shukla');
  final _upiIdController = TextEditingController(text: 'geetansh@hdfcbank');

  bool _acceptedTerms = true;
  bool _isSubmitting = false;

  void _submitApplication() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Host Partner Agreement.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate server side verification & approval workflow
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _currentStep = OnboardingStep.approved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: 'Host Partner Onboarding',
        subtitle: _getSubtitle(),
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildCurrentStepContent(),
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (_currentStep) {
      case OnboardingStep.details:
        return 'Step 1 of 3: Host Account Details';
      case OnboardingStep.identity:
        return 'Step 2 of 3: Legal & Property Verification';
      case OnboardingStep.payout:
        return 'Step 3 of 3: Bank Account for Escrow Payouts';
      case OnboardingStep.pendingReview:
        return 'Application Under Review';
      case OnboardingStep.approved:
        return 'Host Partner Verified';
      case OnboardingStep.rejected:
        return 'Application Status';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case OnboardingStep.details:
        return _buildDetailsStep();
      case OnboardingStep.identity:
        return _buildIdentityStep();
      case OnboardingStep.payout:
        return _buildPayoutStep();
      case OnboardingStep.pendingReview:
        return _buildPendingReview();
      case OnboardingStep.approved:
        return _buildApprovedView();
      case OnboardingStep.rejected:
        return _buildRejectedView();
    }
  }

  // STEP 1: Details
  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(
          icon: Icons.storefront_rounded,
          title: 'Zero Brokerage Host Network',
          subtitle: 'List rooms directly to verified customers with instant digital door PIN delivery and 100% upfront escrow payments.',
        ),
        const SizedBox(height: 24),

        _buildTextField('Business or Property Trade Name', _businessNameController, Icons.business_rounded),
        const SizedBox(height: 14),
        _buildTextField('Primary Contact Person Name', _contactPersonController, Icons.person_outline_rounded),
        const SizedBox(height: 14),
        _buildTextField('Host Contact Mobile (WhatsApp)', _phoneController, Icons.phone_android_rounded, prefix: '+91 '),
        const SizedBox(height: 14),
        _buildTextField('Business Email Address', _emailController, Icons.mail_outline_rounded),
        const SizedBox(height: 14),
        _buildTextField('Primary Operating City', _cityController, Icons.location_city_rounded),
        const SizedBox(height: 28),

        AppButton(
          label: 'Continue to Property Verification →',
          onPressed: () {
            if (_businessNameController.text.trim().isEmpty || _phoneController.text.trim().length < 10) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all business details.')),
              );
              return;
            }
            setState(() => _currentStep = OnboardingStep.identity);
          },
        ),
      ],
    );
  }

  // STEP 2: Identity & Property Proof
  Widget _buildIdentityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(
          icon: Icons.verified_user_rounded,
          title: 'KYC & Ownership Verification',
          subtitle: 'Required to ensure high safety standards for travelers and zero fraudulent listings.',
        ),
        const SizedBox(height: 24),

        const Text('Government Tax / Identity ID', style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _govIdType,
              dropdownColor: surface,
              isExpanded: true,
              style: const TextStyle(color: textWhite, fontSize: 14),
              items: ['PAN Card', 'GSTIN', 'Aadhaar Card (UIDAI Offline XML)']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _govIdType = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField('$_govIdType Number', _govIdNumberController, Icons.badge_outlined),
        const SizedBox(height: 14),
        _buildTextField('Property Deed / Electricity Bill Reference', _propertyOwnershipDocController, Icons.receipt_long_rounded),
        const SizedBox(height: 28),

        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Back',
                isSecondary: true,
                onPressed: () => setState(() => _currentStep = OnboardingStep.details),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'Continue to Payouts →',
                onPressed: () {
                  if (_govIdNumberController.text.trim().length < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid tax/identity number.')),
                    );
                    return;
                  }
                  setState(() => _currentStep = OnboardingStep.payout);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: Payouts & Terms
  Widget _buildPayoutStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Escrow Payout Settlement',
          subtitle: 'Guest booking payments are disbursed automatically to this bank account within 24 hours of guest check-in.',
        ),
        const SizedBox(height: 24),

        _buildTextField('Beneficiary Account Holder Name', _beneficiaryNameController, Icons.person_rounded),
        const SizedBox(height: 14),
        _buildTextField('Bank Account Number', _bankAccountController, Icons.account_balance_rounded),
        const SizedBox(height: 14),
        _buildTextField('Bank IFSC Code', _ifscController, Icons.numbers_rounded),
        const SizedBox(height: 14),
        _buildTextField('Business UPI ID (Optional Fast Payout)', _upiIdController, Icons.qr_code_rounded),
        const SizedBox(height: 20),

        Row(
          children: [
            Checkbox(
              value: _acceptedTerms,
              activeColor: lime,
              checkColor: navy,
              onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
            ),
            const Expanded(
              child: Text(
                'I agree to the My Roomy Host Terms, Zero Brokerage Code and verified door PIN access rules.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        AppButton(
          label: 'Submit Host Application',
          icon: Icons.send_rounded,
          isLoading: _isSubmitting,
          onPressed: _submitApplication,
        ),
      ],
    );
  }

  // Pending Status
  Widget _buildPendingReview() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(color: lime, strokeWidth: 3)),
          const SizedBox(height: 24),
          const Text('Application Under Audit', style: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Our verification team is auditing your property documents and bank credentials.\nApprovals typically complete within 2 to 4 business hours.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Check Status Refresh',
            onPressed: () => setState(() => _currentStep = OnboardingStep.approved),
          ),
        ],
      ),
    );
  }

  // Approved Status
  Widget _buildApprovedView() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(color: Color(0xFF0F3E2E), shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded, color: greenAccent, size: 54),
          ),
          const SizedBox(height: 20),
          const Text('Host Partner Approved!', style: TextStyle(color: textWhite, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Welcome to My Roomy Host Network. You can now publish room listings, set availability calendars and track earnings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 28),

          AppButton(
            label: 'Go to Owner Dashboard →',
            icon: Icons.dashboard_rounded,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Rejected Status
  Widget _buildRejectedView() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: coral.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, color: coral, size: 54),
          ),
          const SizedBox(height: 20),
          const Text('Application Action Required', style: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'The uploaded property proof or bank details could not be validated against land records. Please re-check your submissions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Edit & Resubmit Application',
            onPressed: () => setState(() => _currentStep = OnboardingStep.details),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {String? prefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: textWhite, fontSize: 14),
          decoration: InputDecoration(
            prefixText: prefix,
            prefixStyle: const TextStyle(color: textWhite, fontWeight: FontWeight.bold),
            prefixIcon: Icon(icon, color: lime, size: 20),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lime.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: lime, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: muted, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
