import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'notification_settings_screen.dart';
import 'legal_policy_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English (India)';
  final String _selectedTheme = 'Dark Navy (Default)';
  bool _biometricsEnabled = true;
  bool _analyticsConsent = true;

  final List<String> _languages = [
    'English (India)',
    'हिन्दी (Hindi)',
    'Hinglish (Colloquial)',
    'मराठी (Marathi)',
    'తెలుగు (Telugu)',
    'বাংলা (Bengali)',
  ];

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: coral, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: coral, size: 28),
            SizedBox(width: 10),
            Text(
              'Delete Account?',
              style: TextStyle(
                color: textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Requesting account deletion will immediately terminate your session. In accordance with applicable Indian digital retention guidelines and escrow tenancy policies:',
              style: TextStyle(color: textWhite, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Active bookings will be cancelled per policy.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Door access digital codes will be revoked.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Your PII will be queued for anonymization within 30 days.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textWhite)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: coral,
              foregroundColor: textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deletion request submitted. An SMS confirmation will be sent.',
                  ),
                  backgroundColor: coral,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Confirm Deletion',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to sign out from My Roomy on this device?',
          style: TextStyle(color: muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textWhite)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(
            color: textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Appearance & Language
            _buildSectionHeader('Preferences'),
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.translate, color: lime),
                    title: const Text(
                      'Language',
                      style: TextStyle(
                        color: textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _selectedLanguage,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      underline: const SizedBox(),
                      dropdownColor: surfaceLight,
                      icon: const Icon(Icons.keyboard_arrow_down, color: lime),
                      items: _languages
                          .map(
                            (l) => DropdownMenuItem(
                              value: l,
                              child: Text(
                                l,
                                style: const TextStyle(
                                  color: textWhite,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLanguage = val);
                        }
                      },
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined, color: lime),
                    title: const Text(
                      'App Theme',
                      style: TextStyle(
                        color: textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _selectedTheme,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    trailing: const Chip(
                      label: Text(
                        'OLED Dark',
                        style: TextStyle(
                          color: navy,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: lime,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  SwitchListTile(
                    activeThumbColor: lime,
                    secondary: const Icon(Icons.fingerprint, color: lime),
                    title: const Text(
                      'Biometric Authentication',
                      style: TextStyle(
                        color: textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Require Face/Fingerprint for smart lock PIN viewing',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    value: _biometricsEnabled,
                    onChanged: (val) =>
                        setState(() => _biometricsEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notifications & Communications
            _buildSectionHeader('Notifications & Privacy'),
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_active_outlined,
                      color: lime,
                    ),
                    title: const Text(
                      'Notification Preferences',
                      style: TextStyle(
                        color: textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'WhatsApp, Stay extension alerts, Reminders',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: muted,
                      size: 14,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  SwitchListTile(
                    activeThumbColor: lime,
                    secondary: const Icon(
                      Icons.analytics_outlined,
                      color: lime,
                    ),
                    title: const Text(
                      'Performance & Crash Telemetry',
                      style: TextStyle(
                        color: textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Share anonymous telemetry to optimize room search speed',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    value: _analyticsConsent,
                    onChanged: (val) => setState(() => _analyticsConsent = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Legal & Compliance
            _buildSectionHeader('Legal & Compliance Policies'),
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                      color: lime,
                    ),
                    title: const Text(
                      'Terms & Conditions',
                      style: TextStyle(color: textWhite, fontSize: 14),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: muted,
                      size: 14,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalPolicyScreen(
                          title: 'Terms & Conditions',
                          contentKey: 'terms',
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                      color: lime,
                    ),
                    title: const Text(
                      'Privacy & Data Retention Policy',
                      style: TextStyle(color: textWhite, fontSize: 14),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: muted,
                      size: 14,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalPolicyScreen(
                          title: 'Privacy Policy',
                          contentKey: 'privacy',
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(Icons.cancel_outlined, color: lime),
                    title: const Text(
                      'Cancellation & Refund Policy',
                      style: TextStyle(color: textWhite, fontSize: 14),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: muted,
                      size: 14,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalPolicyScreen(
                          title: 'Cancellation & Refund',
                          contentKey: 'cancellation',
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.verified_user_outlined,
                      color: lime,
                    ),
                    title: const Text(
                      'Guest & Owner House Rules',
                      style: TextStyle(color: textWhite, fontSize: 14),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: muted,
                      size: 14,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalPolicyScreen(
                          title: 'Rules & Conduct',
                          contentKey: 'rules',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Danger Zone
            _buildSectionHeader('Account Actions'),
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.orangeAccent,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Sign out from this device',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: muted,
                      size: 14,
                    ),
                    onTap: _showLogoutDialog,
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: coral),
                    title: const Text(
                      'Request Account Deletion',
                      style: TextStyle(
                        color: coral,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Permanently erase account and active profiles',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: muted,
                      size: 14,
                    ),
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
            Center(
              child: Column(
                children: [
                  Text(
                    'My Roomy 2.0 • Zero Brokerage Mobile System',
                    style: TextStyle(
                      color: muted.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 2.4.0 (Build 2026.10)',
                    style: TextStyle(
                      color: muted.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: lime,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
