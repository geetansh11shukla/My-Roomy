import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<BookingModel> _demoBookings = [
    BookingModel(
      bookingId: 'RW8291024',
      roomId: 'room_1',
      roomTitle: 'Cozy City Room',
      locality: 'Gomti Nagar',
      city: 'Lucknow',
      customerId: 'cust_1',
      customerName: 'Aarav Patel',
      customerPhone: '+919876543210',
      customerAge: 25,
      idProofType: 'Aadhaar Card',
      idNumber: '8834 9102 3341',
      idVerified: true,
      checkIn: 'Tomorrow',
      checkOut: 'In 3 days',
      nights: 2,
      totalAmount: 1598,
      status: BookingStatus.confirmed,
      accessPin: 'PIN4821',
      locationUrl: 'https://maps.google.com',
      priorityExtensionEligible: true,
      createdAt: DateTime.now(),
    ),
    BookingModel(
      bookingId: 'RW7319021',
      roomId: 'room_2',
      roomTitle: 'Modern Comfort Stay',
      locality: 'Hazratganj',
      city: 'Lucknow',
      customerId: 'cust_2',
      customerName: 'Priya Sharma',
      customerPhone: '+919876543211',
      customerAge: 28,
      idProofType: 'Driving License',
      idNumber: 'UP32 20190019283',
      idVerified: true,
      checkIn: 'Today',
      checkOut: 'Tomorrow',
      nights: 1,
      totalAmount: 999,
      status: BookingStatus.confirmed,
      accessPin: 'PIN9321',
      locationUrl: 'https://maps.google.com',
      priorityExtensionEligible: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    BookingModel(
      bookingId: 'RW6190281',
      roomId: 'room_1',
      roomTitle: 'Cozy City Room',
      locality: 'Gomti Nagar',
      city: 'Lucknow',
      customerId: 'cust_3',
      customerName: 'Vikram Verma',
      customerPhone: '+919876543212',
      customerAge: 31,
      idProofType: 'Passport',
      idNumber: 'Z8910293',
      idVerified: true,
      checkIn: 'Last Week',
      checkOut: 'Completed',
      nights: 3,
      totalAmount: 2397,
      status: BookingStatus.completed,
      accessPin: 'PIN1084',
      locationUrl: 'https://maps.google.com',
      priorityExtensionEligible: false,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _contactSupport(BookingModel b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'My Roomy Host Support',
          style: TextStyle(
            color: textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Under My Roomy Zero-Chat policy, direct unrecorded owner-guest chat is prohibited to eliminate harassment.\n\nContact My Roomy 24/7 Operations Desk for Booking #${b.bookingId} regarding guest arrival, maintenance or early extensions.',
          style: const TextStyle(color: muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: navy,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Support ticket opened for booking. Desk agent will call host.',
                  ),
                ),
              );
            },
            child: const Text('Call Support Desk'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _demoBookings
        .where((b) => b.status == BookingStatus.confirmed)
        .toList();
    final completed = _demoBookings
        .where((b) => b.status == BookingStatus.completed)
        .toList();
    final cancelled = _demoBookings
        .where((b) => b.status == BookingStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text(
          'Reservations Management',
          style: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
        ),
        backgroundColor: navy,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: lime,
          labelColor: lime,
          unselectedLabelColor: muted,
          tabs: [
            Tab(text: 'Active / Upcoming (${upcoming.length})'),
            Tab(text: 'Completed (${completed.length})'),
            Tab(text: 'Cancelled (${cancelled.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(upcoming, 'No active guest reservations'),
          _buildList(completed, 'No completed stays yet'),
          _buildList(cancelled, 'No cancelled reservations'),
        ],
      ),
    );
  }

  Widget _buildList(List<BookingModel> list, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: muted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final b = list[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RESERVATION #${b.bookingId}',
                    style: const TextStyle(
                      color: lime,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      b.status == BookingStatus.confirmed
                          ? 'PAID & ESCROW LOCKED'
                          : 'COMPLETED',
                      style: const TextStyle(
                        color: greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                b.roomTitle,
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Guest: ${b.customerName} • Verified ID (${b.idProofType})',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${b.checkIn} → ${b.checkOut} (${b.nights}n)',
                    style: const TextStyle(color: textWhite, fontSize: 13),
                  ),
                  Text(
                    'Payout: ₹${b.totalAmount}',
                    style: const TextStyle(
                      color: lime,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Door PIN: ${b.accessPin}',
                    style: const TextStyle(
                      color: textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: lime,
                      side: const BorderSide(color: lime),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () => _contactSupport(b),
                    icon: const Icon(Icons.support_agent_rounded, size: 16),
                    label: const Text(
                      'Contact Desk',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
