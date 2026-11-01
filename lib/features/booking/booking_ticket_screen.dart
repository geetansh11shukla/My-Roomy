import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';

class BookingTicketScreen extends StatelessWidget {
  final BookingModel booking;
  final RoomModel? room;

  const BookingTicketScreen({
    super.key,
    required this.booking,
    this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: 'Stay Ticket Pass',
        subtitle: 'Reference #${booking.bookingId}',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: textWhite, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stay Ticket link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Digital Pass Ticket Container
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: lime.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    // Ticket Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceLight,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.home_rounded, color: navy, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text('My Roomy Verified Pass', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: greenAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('CONFIRMED', style: TextStyle(color: greenAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),

                    // Ticket Body
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.roomTitle, style: const TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${booking.locality}, ${booking.city}', style: const TextStyle(color: muted, fontSize: 12)),
                          const SizedBox(height: 16),

                          // Digital Door Access PIN
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: navy,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: lime.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                const Text('DIGITAL DOOR LOCK PIN', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                const SizedBox(height: 6),
                                Text(
                                  booking.accessPin,
                                  style: const TextStyle(color: lime, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3),
                                ),
                                const SizedBox(height: 4),
                                const Text('Valid for self check-in from 12:00 PM', style: TextStyle(color: Colors.white38, fontSize: 10)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Ticket details grid
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CHECK-IN', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(booking.checkIn, style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const Text('12:00 PM', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CHECK-OUT', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(booking.checkOut, style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const Text('11:00 AM', style: TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PRIMARY GUEST', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(booking.customerName, style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('AMOUNT PAID', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('₹${booking.totalAmount}', style: const TextStyle(color: lime, fontSize: 15, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Mock QR Code Representation
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.black),
                                  Text(
                                    'SCAN AT PROPERTY: ${booking.bookingId}',
                                    style: const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // WhatsApp Delivery notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: greenAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'WhatsApp Pass Dispatched: Live Google Maps link & digital PIN sent.',
                        style: TextStyle(color: greenAccent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
