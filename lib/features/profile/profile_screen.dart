import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'identity_status_screen.dart';
import 'help_support_screen.dart';
import 'settings_screen.dart';
import '../my_bookings/my_bookings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../owner/add_room_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Profile Photo & Avatar
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: lime, width: 2.5),
                ),
                child: const CircleAvatar(
                  radius: 46,
                  backgroundColor: surfaceLight,
                  child: Icon(Icons.person, size: 52, color: lime),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: lime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, size: 18, color: navy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name
          const Text(
            'Rahul Kumar',
            style: TextStyle(
              color: textWhite,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Verification Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVerificationBadge(
                icon: Icons.phone_android,
                label: '+91 9876543210',
                isVerified: true,
              ),
              const SizedBox(width: 8),
              _buildVerificationBadge(
                icon: Icons.mail_outline,
                label: 'rahul.k@roomwala.in',
                isVerified: true,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 18+ Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: greenAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: greenAccent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, color: greenAccent, size: 14),
                SizedBox(width: 6),
                Text(
                  '18+ KYC Eligible & Verified',
                  style: TextStyle(
                    color: greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Edit Profile Action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: lime),
                foregroundColor: lime,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Edit Customer Profile',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Host / Room Owner Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  lime.withValues(alpha: 0.15),
                  const Color(0xFF3B82F6).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: lime.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.real_estate_agent, color: lime, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Are you a Room Owner?',
                      style: TextStyle(
                        color: textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'List your room for short/long stay without broker calls. Digital passes dispatch to guests directly.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddRoomScreen()),
                    );
                  },
                  icon: const Icon(Icons.add_home_work, size: 18),
                  label: const Text(
                    'Add Room Listing (Host Mode)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Navigation Menu Items
          _buildActionTile(
            icon: Icons.calendar_month_outlined,
            title: 'My Bookings',
            subtitle: 'Active stays, digital door PINs & check-in passes',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
              );
            },
          ),
          _buildActionTile(
            icon: Icons.favorite_border,
            title: 'Favourites & Saved Rooms',
            subtitle: 'Shortlisted zero-brokerage stays',
            trailingBadge: '4 Saved',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved rooms loaded in discovery view'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildActionTile(
            icon: Icons.verified_user_outlined,
            title: 'Identity Verification Status',
            subtitle: 'Aadhaar 18+ eligibility & provider review status',
            trailingBadge: 'Approved',
            badgeColor: greenAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IdentityStatusScreen()),
              );
            },
          ),
          _buildActionTile(
            icon: Icons.notifications_none,
            title: 'Notifications & Alerts',
            subtitle: 'Automated door codes, extension offers & updates',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          _buildActionTile(
            icon: Icons.support_agent_outlined,
            title: 'Help & Support Desk',
            subtitle: 'FAQs, ticket history & 24/7 dispute resolution',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              );
            },
          ),
          _buildActionTile(
            icon: Icons.settings_outlined,
            title: 'App Settings & Policies',
            subtitle: 'Language, themes, legal notices & account deletion',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          const SizedBox(height: 12),

          // Logout Button
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.white12),
            ),
            tileColor: surface,
            leading: const Icon(Icons.logout, color: coral),
            title: const Text(
              'Log Out',
              style: TextStyle(
                color: coral,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: const Text(
              'Safely end session on this device',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: muted,
              size: 14,
            ),
            onTap: () => _showLogoutDialog(context),
          ),

          const SizedBox(height: 30),
          Text(
            'My Roomy 2.0 • Version 2.4.0 (Production Build)',
            style: TextStyle(color: muted.withValues(alpha: 0.6), fontSize: 11),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge({
    required IconData icon,
    required String label,
    required bool isVerified,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: muted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: muted, fontSize: 11)),
          const SizedBox(width: 4),
          Icon(
            isVerified ? Icons.check_circle : Icons.error_outline,
            size: 13,
            color: isVerified ? greenAccent : Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingBadge,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: lime.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: lime, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: muted, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? lime).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trailingBadge,
                  style: TextStyle(
                    color: badgeColor ?? lime,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.arrow_forward_ios, color: muted, size: 14),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
