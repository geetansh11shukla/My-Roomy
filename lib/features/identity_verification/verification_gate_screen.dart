import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

enum KycStatus { unverified, pending, verified, rejected }

class VerificationGateScreen extends StatefulWidget {
  final VoidCallback? onVerifiedSuccess;
  const VerificationGateScreen({super.key, this.onVerifiedSuccess});

  @override
  State<VerificationGateScreen> createState() => _VerificationGateScreenState();
}

class _VerificationGateScreenState extends State<VerificationGateScreen> {
  KycStatus _status = KycStatus.unverified;
  String _selectedDocType = 'Aadhaar Card (Offline e-KYC XML)';
  final _docNumberController = TextEditingController(text: '8834 9102 3341');
  bool _consentGiven = false;
  bool _isSubmitting = false;

  final List<String> _docTypes = [
    'Aadhaar Card (Offline e-KYC XML)',
    'Driving License (DigiLocker)',
    'Voter ID Card',
    'Passport',
  ];

  void _submitVerification() async {
    if (_docNumberController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid document identifier.')),
      );
      return;
    }
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide consent for identity verification.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _status = KycStatus.pending;
    });

    // Simulated trusted backend automated identity verification gateway call
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _status = KycStatus.verified;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: const AppHeader(title: 'Identity & Age Gate', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildStatusContent(),
        ),
      ),
    );
  }

  Widget _buildStatusContent() {
    switch (_status) {
      case KycStatus.pending:
        return _buildPendingView();
      case KycStatus.verified:
        return _buildVerifiedView();
      case KycStatus.rejected:
        return _buildRejectedView();
      case KycStatus.unverified:
        return _buildFormView();
    }
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trust Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lime.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.security_rounded, color: lime, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('18+ Mandatory Guest Gate', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 4),
                    Text(
                      'Indian hospitality laws mandate valid Government ID check before digital door PIN issuance.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('Government Document Type', style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDocType,
              isExpanded: true,
              dropdownColor: surface,
              style: const TextStyle(color: textWhite, fontSize: 14),
              items: _docTypes.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDocType = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 18),

        const Text('Document Reference / UID', style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _docNumberController,
          style: const TextStyle(color: textWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter document number',
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: const Icon(Icons.badge_outlined, color: lime, size: 20),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
          ),
        ),
        const SizedBox(height: 18),

        // Privacy explanation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, color: greenAccent, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'End-to-end encrypted: We never store raw Aadhaar scans or unmasked biometric details. Verified automatically via official DigiLocker / UIDAI offline sandbox.',
                  style: TextStyle(color: muted, fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Consent Checkbox
        Row(
          children: [
            Checkbox(
              value: _consentGiven,
              activeColor: lime,
              checkColor: navy,
              onChanged: (val) => setState(() => _consentGiven = val ?? false),
            ),
            const Expanded(
              child: Text(
                'I confirm I am 18+ years of age and consent to trusted identity verification.',
                style: TextStyle(color: textWhite, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        AppButton(
          label: 'Verify Identity & Unlock Stays',
          isLoading: _isSubmitting,
          onPressed: _consentGiven ? _submitVerification : null,
        ),
      ],
    );
  }

  Widget _buildPendingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(color: lime, strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            const Text('Verifying Government Credentials...', style: TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Connecting with approved DigiLocker gateway. This usually takes 5-10 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFF0F3E2E), shape: BoxShape.circle),
              child: const Icon(Icons.verified_user_rounded, color: greenAccent, size: 54),
            ),
            const SizedBox(height: 20),
            const Text('Identity Verified (18+ Eligible)', style: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Your identification credentials have been approved by the trusted verification service.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Proceed with Booking',
              onPressed: () {
                if (widget.onVerifiedSuccess != null) {
                  widget.onVerifiedSuccess!();
                } else {
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: coral.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.cancel_rounded, color: coral, size: 54),
            ),
            const SizedBox(height: 20),
            const Text('Verification Failed or Expired', style: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'We were unable to validate your document against official records. Please retry with a valid document or contact 24x7 My Roomy Support.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Retry Verification',
              onPressed: () => setState(() => _status = KycStatus.unverified),
            ),
          ],
        ),
      ),
    );
  }
}
