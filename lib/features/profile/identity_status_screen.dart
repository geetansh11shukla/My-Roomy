import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class IdentityStatusScreen extends StatelessWidget {
  const IdentityStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: const AppHeader(
        title: 'Identity Verification Status',
        subtitle: '18+ Regulatory Compliance',
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Status Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3E2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: greenAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: greenAccent, size: 40),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('18+ KYC VERIFIED', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 2),
                          Text('Authorized for instant booking & digital door PIN access.', style: TextStyle(color: muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Verification Lifecycle Steps
              const Text('VERIFICATION STEPS', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              _buildStepCard(
                icon: Icons.badge_outlined,
                title: 'Government ID Submission',
                subtitle: 'Aadhaar Offline e-KYC (UIDAI XML)',
                date: 'Submitted 14 Oct 2026',
                isCompleted: true,
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                icon: Icons.security_rounded,
                title: 'Age Eligibility Check',
                subtitle: 'Calculated DOB matches 18+ hospitality legal standard',
                date: 'Approved automatically',
                isCompleted: true,
              ),
              const SizedBox(height: 10),
              _buildStepCard(
                icon: Icons.phone_android_rounded,
                title: 'Mobile OTP Authentication',
                subtitle: 'WhatsApp number bound to verified pass issuance',
                date: 'Verified (+91 9876543210)',
                isCompleted: true,
              ),
              const SizedBox(height: 24),

              // Privacy & Data Retention Policy
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: lime, size: 18),
                        SizedBox(width: 8),
                        Text('Privacy & Data Retention Notice', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• We never capture, download or store raw unmasked Aadhaar scans or biometric records.\n• Identity verification tokens are encrypted with AES-256 and used solely to prevent room subletting fraud.\n• Admin-only operational logs and internal reviewer notes are strictly confidential and protected by role-based access.',
                      style: TextStyle(color: muted, fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Help link
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: lime),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification Help: Contact support desk for document assistance.')),
                    );
                  },
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: const Text('Need help with identity verification?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: lime, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: muted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isCompleted ? greenAccent : muted,
            size: 18,
          ),
        ],
      ),
    );
  }
}
