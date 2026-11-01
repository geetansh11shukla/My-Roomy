import '../models/booking_model.dart';
import '../models/room_model.dart';

class WhatsAppService {
  /// Generates the verified WhatsApp ticket template
  static String buildCustomerPassMessage({
    required BookingModel booking,
    required RoomModel room,
  }) {
    return '''*🏠 ROOMWALA CONFIRMED BOOKING PASS*
---------------------------------------
Namaste *${booking.customerName}*, your stay reservation is confirmed!

🔖 *Pass ID:* ${booking.bookingId}
📍 *Room:* ${room.title}
📌 *Exact Locality:* ${room.locality}, ${room.city}
🗺️ *Live Google Maps Navigation:*
${booking.locationUrl}

🔑 *Digital Door PIN:* ${booking.accessPin}
📅 *Check-In:* ${booking.checkIn} (12:00 PM)
📅 *Check-Out:* ${booking.checkOut} (11:00 AM)
💳 *Amount Paid:* ₹${booking.totalAmount}
🛡️ *KYC Status:* Verified (${booking.idProofType}, 18+ Passed)

---------------------------------------
⭐ *STAY EXTENSION PRIORITY ACTIVE*
Check-out se 24 ghante pehle aapko extension reminder aayega. Current guest hone ke naate room extension par aapko first preference milegi!

*My Roomy Direct Dispatch — No Broker, No Owner Calling Hassle.*''';
  }

  /// WhatsApp Web / Mobile deep link generator
  static String getWhatsAppDeepLink(String phone, String message) {
    final sanitizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMsg = Uri.encodeComponent(message);
    return 'https://wa.me/91$sanitizedPhone?text=$encodedMsg';
  }

  /// Google maps navigation link generator
  static String getNavigationMapUrl(double lat, double lng, String placeName) {
    final encodedQuery = Uri.encodeComponent(placeName);
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$encodedQuery';
  }
}
