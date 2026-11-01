import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Configurable preferences
  bool _promotionalOffers = false;
  bool _extensionReminders = true;
  bool _pushNotifications = true;
  bool _whatsAppConsent = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: const AppHeader(
        title: 'Notification Settings',
        subtitle: 'Alerts, WhatsApp pass and consent rules',
        showBack: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Mandatory Transactional Notices Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: lime.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: lime, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mandatory Service Notices',
                          style: TextStyle(
                            color: textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'In compliance with regulatory standards, core booking confirmation, door access PINs, and escrow payment receipts cannot be disabled.',
                          style: TextStyle(
                            color: muted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'COMMUNICATION CHANNELS',
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            _buildSwitchTile(
              title: 'WhatsApp Automation Dispatch',
              subtitle: 'Receive digital door PIN pass and live Google Maps directions on WhatsApp',
              value: _whatsAppConsent,
              onChanged: (val) => setState(() => _whatsAppConsent = val),
            ),
            const SizedBox(height: 10),

            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Instant alerts on booking updates, check-in readiness and host status',
              value: _pushNotifications,
              onChanged: (val) => setState(() => _pushNotifications = val),
            ),
            const SizedBox(height: 24),

            const Text(
              'OPTIONAL ALERTS & PREFERENCES',
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            _buildSwitchTile(
              title: '24-Hour Stay Extension Reminders',
              subtitle: 'Priority notification 24 hours prior to checkout offering first preference extension lock',
              value: _extensionReminders,
              onChanged: (val) => setState(() => _extensionReminders = val),
            ),
            const SizedBox(height: 10),

            _buildSwitchTile(
              title: 'Promotional Offers & Discounts',
              subtitle: 'Special direct-booking member rates and seasonal offers across cities',
              value: _promotionalOffers,
              onChanged: (val) => setState(() => _promotionalOffers = val),
            ),
            const SizedBox(height: 32),

            AppButton(
              label: 'Save Notification Preferences',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: greenAccent,
                    content: Text('Preferences updated successfully!'),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SwitchListTile(
        activeThumbColor: lime,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            color: textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: muted, fontSize: 11),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
