import 'package:flutter/material.dart';

import '../../models/booking_model.dart';
import '../../services/whatsapp_service.dart';
import '../../core/theme/app_theme.dart';

import 'package:url_launcher/url_launcher.dart';

class BookingPassDialog extends StatelessWidget {
  final BookingModel booking;

  const BookingPassDialog({super.key, required this.booking});

  Future<void> _openWhatsApp() async {
    final message =
        '''*🏠 ROOMWALA CONFIRMED BOOKING PASS*
---------------------------------------
Namaste *${booking.customerName}*, your stay reservation is confirmed!

🔖 *Pass ID:* ${booking.bookingId}
📍 *Room:* ${booking.roomTitle}
📌 *Locality:* ${booking.locality}, ${booking.city}
🗺️ *Live Google Maps:*
${booking.locationUrl}

🔑 *Digital Door PIN:* ${booking.accessPin}
📅 *Check-In:* ${booking.checkIn} (12:00 PM)
💳 *Amount Paid:* ₹${booking.totalAmount}
🛡️ *KYC Status:* Verified (${booking.idProofType}, 18+ Passed)

---------------------------------------
⭐ *STAY EXTENSION PRIORITY ACTIVE*
Check-out se 24 ghante pehle aapko extension reminder aayega. Current guest hone ke naate room extension par aapko first preference milegi!

*My Roomy Direct Dispatch — Zero Broker, Zero Owner Calling.*''';

    final url = WhatsAppService.getWhatsAppDeepLink(
      booking.customerPhone,
      message,
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMap() async {
    final uri = Uri.parse(booking.locationUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: greenAccent, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Booking Confirmed & Slot Locked!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Yeh room dates ab kisi doosre user ke liye book nahi ho sakti.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Pass Details Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PASS ID: ${booking.bookingId}',
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
                          color: greenAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CONFIRMED',
                          style: TextStyle(
                            color: greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    booking.roomTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Digital Door PIN',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.accessPin,
                    style: const TextStyle(
                      color: coral,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // WhatsApp Ticket Button
            ElevatedButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.send_to_mobile, color: Colors.white),
              label: const Text('Send Pass to WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Live GPS Map Button
            OutlinedButton.icon(
              onPressed: _openMap,
              icon: const Icon(Icons.navigation, color: lime, size: 18),
              label: const Text(
                'Open Live Google Map',
                style: TextStyle(color: textWhite),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: lime),
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Stay Extension Priority Notice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stay Extension Priority Active: Check-out se 24 ghante pehle aapko extension reminder aayega!',
                      style: TextStyle(color: Colors.amber, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done', style: TextStyle(color: muted)),
            ),
          ],
        ),
      ),
    );
  }
}
