import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';
import 'add_room_wizard_screen.dart';
import 'owner_listings_screen.dart';
import 'owner_bookings_screen.dart';
import 'owner_earnings_screen.dart';
import 'owner_reviews_screen.dart';
import 'owner_availability_calendar_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  // Operational Metrics
  final int _totalListings = 3;
  final int _publishedListings = 2;
  final int _pendingApprovals = 1;
  final int _upcomingBookings = 2;
  final int _occupancyRate = 85; // 85%
  final int _totalEarnings = 4994;
  final int _pendingPayouts = 1598;

  final RoomModel _primaryRoom = const RoomModel(
    roomId: 'room_1',
    ownerId: 'host_current',
    title: 'Cozy City Room',
    description: 'Comfortable air-conditioned private room with attached washroom and high speed Wi-Fi.',
    city: 'Lucknow',
    locality: 'Gomti Nagar',
    pricePerNight: 799,
    rating: 4.8,
    reviewsCount: 34,
    imageUrl: 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
    photos: ['https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900'],
    tag: 'Popular',
    amenities: ['Fast Wi-Fi', 'AC', 'Attached Bathroom', '24x7 Power Backup'],
    houseRules: ['18+ Govt ID mandatory', 'No smoking inside'],
    latitude: 26.8522,
    longitude: 80.9995,
    ownerName: 'Shukla Stays',
    ownerPhone: '+919876543210',
    isVerified: true,
    digitalPin: 'PIN4821',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: 'Host Control Center',
        subtitle: 'Shukla Stays & Co. (Verified Host)',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home_work_rounded, color: lime),
            tooltip: 'Add Room',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddRoomWizardScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Revenue Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: lime.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(color: lime.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL EARNINGS (ESCROW)', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: greenAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('0% FEE · NET 100%', style: TextStyle(color: greenAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹$_totalEarnings',
                    style: const TextStyle(color: textWhite, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      _buildMetricMini('Pending Settlement', '₹$_pendingPayouts'),
                      const SizedBox(width: 12),
                      _buildMetricMini('Occupancy Rate', '$_occupancyRate%'),
                      const SizedBox(width: 12),
                      _buildMetricMini('Active Guests', '$_upcomingBookings'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions Grid
            const Text('HOST ACTIONS', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.add_business_rounded,
                    title: 'Add Room',
                    subtitle: '7-step wizard',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddRoomWizardScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.meeting_room_rounded,
                    title: 'My Listings ($_totalListings)',
                    subtitle: '$_publishedListings Live · $_pendingApprovals Audit',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OwnerListingsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.calendar_month_rounded,
                    title: 'Calendar & Slots',
                    subtitle: 'Block/unblock dates',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OwnerAvailabilityCalendarScreen(room: _primaryRoom),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Bookings ($_upcomingBookings)',
                    subtitle: 'PINs & guest passes',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OwnerBookingsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payouts',
                    subtitle: 'Bank settlement history',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OwnerEarningsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.star_border_rounded,
                    title: 'Guest Reviews',
                    subtitle: '4.8★ rating · Replies',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OwnerReviewsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Live Booking Activity Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_rounded, color: lime, size: 18),
                      SizedBox(width: 8),
                      Text('Recent Reservation Activity', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActivityRow('Aarav Patel', 'Cozy City Room', 'Check-in Tomorrow', '₹1,598 Paid (PIN4821)'),
                  const Divider(color: Colors.white10, height: 16),
                  _buildActivityRow('Priya Sharma', 'Modern Comfort Stay', 'Check-in Today', '₹999 Paid (PIN9321)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricMini(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: surfaceLight, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: muted, fontSize: 9)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: surfaceLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: lime, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(String guest, String room, String timing, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(guest, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
            Text('$room • $timing', style: const TextStyle(color: muted, fontSize: 11)),
          ],
        ),
        Text(price, style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
