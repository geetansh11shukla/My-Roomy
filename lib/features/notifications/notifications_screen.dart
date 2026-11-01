import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'notif_1',
      'title': 'Stay Extension Priority Active',
      'body': 'Your check-out is in 24 hours. Extend your room stay with 1-click priority lock before it unlocks for others.',
      'time': '10 mins ago',
      'type': 'extension',
      'isRead': false,
    },
    {
      'id': 'notif_2',
      'title': 'WhatsApp Pass Dispatched',
      'body': 'Digital Door Access PIN & live Google Maps navigation link sent to your registered WhatsApp.',
      'time': '2 hours ago',
      'type': 'booking',
      'isRead': false,
    },
    {
      'id': 'notif_3',
      'title': 'Payment & Escrow Verified',
      'body': '₹1,678 payment received. Slot locked safely with 100% money-back escrow protection.',
      'time': 'Yesterday',
      'type': 'payment',
      'isRead': true,
    },
    {
      'id': 'notif_4',
      'title': '18+ Government ID Verified',
      'body': 'Your submitted Aadhaar identification proof has been verified successfully.',
      'time': '2 days ago',
      'type': 'kyc',
      'isRead': true,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text('Notifications Inbox'),
        backgroundColor: navy,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: lime, fontSize: 13),
            ),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    color: muted,
                    size: 54,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No new notifications',
                    style: TextStyle(
                      color: textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Booking, KYC and WhatsApp updates will show here.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _notifications[index];
                final isRead = item['isRead'] as bool;
                final type = item['type'] as String;

                IconData icon;
                Color color;
                switch (type) {
                  case 'extension':
                    icon = Icons.stars;
                    color = Colors.amber;
                    break;
                  case 'payment':
                    icon = Icons.check_circle;
                    color = greenAccent;
                    break;
                  case 'kyc':
                    icon = Icons.verified_user;
                    color = const Color(0xFF38BDF8);
                    break;
                  default:
                    icon = Icons.airplane_ticket;
                    color = lime;
                }

                return InkWell(
                  onTap: () {
                    setState(() => item['isRead'] = true);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isRead
                          ? surface
                          : surfaceLight.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isRead
                            ? Colors.white10
                            : lime.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: TextStyle(
                                      color: textWhite,
                                      fontWeight: isRead
                                          ? FontWeight.w600
                                          : FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    item['time'] as String,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['body'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
