import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import 'extension_offer_card.dart';
import '../booking/booking_details_screen.dart';

class CheckoutReminderBanner extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onRefresh;

  const CheckoutReminderBanner({
    super.key,
    required this.booking,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // Banner Top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B2D05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.notification_important_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'CHECK-OUT REMINDER (24 HOURS PRIOR)',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onRefresh,
                  child: const Row(
                    children: [
                      Icon(Icons.refresh_rounded, color: muted, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Sync',
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scheduled Check-Out',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${booking.checkOut} at 11:00 AM',
                          style: const TextStyle(
                            color: textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surfaceLight,
                        foregroundColor: textWhite,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingDetailsScreen(booking: booking),
                          ),
                        );
                      },
                      child: const Text(
                        'View Booking',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Extension Offer Card Integrated
                if (booking.priorityExtensionEligible)
                  ExtensionOfferCard(booking: booking),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
