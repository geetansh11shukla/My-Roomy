import { Booking, Room } from '../types';

/**
 * Generates direct Google Maps Navigation URL from latitude & longitude
 */
export function getLiveLocationUrl(latitude: number, longitude: number, placeName: string): string {
  const query = encodeURIComponent(`${placeName}`);
  return `https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}&query_place_id=${query}`;
}

/**
 * Generates automated WhatsApp Booking Ticket Message
 * Sent immediately after payment to both Customer and Room Owner
 */
export function generateWhatsAppReceiptPayload(booking: Booking, room: Room) {
  const messageCustomer = `*🏠 ROOMWALA CONFIRMED BOOKING PASS*
---------------------------------------
Hi *${booking.customerName}*, your room booking is confirmed!

🔖 *Booking ID:* ${booking.bookingId}
📍 *Room:* ${booking.roomTitle}
📌 *Exact Address:* ${booking.roomAddress}
🗺️ *Live Google Maps Link:*
${booking.roomLocationUrl}

🔑 *Digital Check-in PIN:* \`${booking.accessCode}\`
📅 *Check-In:* ${booking.checkInDate} (12:00 PM)
📅 *Check-Out:* ${booking.checkOutDate} (11:00 AM)
💳 *Amount Paid:* ₹${booking.amountPaid} (${booking.paymentMethod})
🛡️ *KYC Status:* Verified (${booking.idProofType} checked, 18+ eligible)

---------------------------------------
⭐ *STAY EXTENSION PRIORITY ACTIVE*
Aapko checkout se 24 ghante pehle extension reminder milega. Current guest hone ke kaaran room extension par aapko first preference milegi!

*RoomWala automated dispatch - No broker, No direct owner hassle.*`;

  const messageOwner = `*🔔 NEW ROOMWALA RESERVATION ALERT*
---------------------------------------
Namaste *${room.ownerName}*, aapke room me ek nayi booking aayi hai!

🏷️ *Room:* ${room.title}
👤 *Guest Name:* ${booking.customerName} (Age: ${booking.customerAge})
🆔 *ID Proof:* ${booking.idProofType} (Auto-Verified)
📅 *Dates:* ${booking.checkInDate} to ${booking.checkOutDate} (${booking.totalDays} Days)
💰 *Payment Received:* ₹${booking.amountPaid} via RoomWala Escrow

Guest ko live location aur access PIN bhej diya gaya hai. Room slot lock ho chuka hai.`;

  return {
    customerWhatsAppLink: `https://wa.me/91${booking.customerPhone.replace(/[^0-9]/g, '')}?text=${encodeURIComponent(messageCustomer)}`,
    ownerWhatsAppLink: `https://wa.me/${room.ownerWhatsApp.replace(/[^0-9]/g, '')}?text=${encodeURIComponent(messageOwner)}`,
    messageCustomer,
    messageOwner,
  };
}

/**
 * Validates Government ID format & Age rule (18+)
 */
export function validateGuestIdentity(age: number, idType: string, idNumber: string): { valid: boolean; error?: string } {
  if (isNaN(age) || age < 18) {
    return { valid: false, error: 'Strict Age Restriction: Guest must be at least 18 years old.' };
  }
  if (!idNumber || idNumber.trim().length < 6) {
    return { valid: false, error: 'Please enter a valid Government Document Number.' };
  }
  if (idType === 'Aadhaar Card' && idNumber.replace(/\s/g, '').length !== 12) {
    return { valid: false, error: 'Aadhaar card number must be exactly 12 digits.' };
  }
  return { valid: true };
}
