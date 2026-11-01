import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';
import 'booking_ticket_screen.dart';
import '../../main.dart' hide navy, lime, surface, surfaceLight, muted;

class BookingConfirmationScreen extends StatelessWidget {
  final BookingModel booking;
  final RoomModel room;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Glow Success Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: greenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: greenAccent.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: navy, size: 52),
              ),
              const SizedBox(height: 24),

              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reference #${booking.bookingId}',
                style: const TextStyle(
                  color: lime,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            room.imageUrl.isNotEmpty
                                ? room.imageUrl
                                : 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking.roomTitle, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('${booking.locality}, ${booking.city}', style: const TextStyle(color: muted, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('₹${booking.totalAmount} Paid via Escrow', style: const TextStyle(color: greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),

                    // WhatsApp Status Notice
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: greenAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: greenAccent, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Door Access PIN & Google Maps navigation link sent to your registered WhatsApp.',
                              style: TextStyle(color: greenAccent, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // View Ticket Action
              AppButton(
                label: 'View Digital Stay Ticket',
                icon: Icons.confirmation_number_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingTicketScreen(booking: booking, room: room),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Return Home Action
              AppButton(
                label: 'Return to Home',
                isSecondary: true,
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
