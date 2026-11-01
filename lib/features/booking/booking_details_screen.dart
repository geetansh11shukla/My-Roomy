import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../shared/widgets/app_components.dart';
import 'booking_ticket_screen.dart';
import 'cancellation_screen.dart';
import '../../services/whatsapp_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../stay_extension/extension_offer_card.dart';

class BookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;
  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late BookingModel _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
  }

  void _openDirections() async {
    final url = WhatsAppService.getNavigationMapUrl(26.8467, 80.9462, _currentBooking.roomTitle);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openCancellation() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CancellationScreen(booking: _currentBooking),
      ),
    );

    if (res == true && mounted) {
      setState(() {
        _currentBooking = BookingModel(
          bookingId: _currentBooking.bookingId,
          roomId: _currentBooking.roomId,
          roomTitle: _currentBooking.roomTitle,
          locality: _currentBooking.locality,
          city: _currentBooking.city,
          customerId: _currentBooking.customerId,
          customerName: _currentBooking.customerName,
          customerPhone: _currentBooking.customerPhone,
          customerAge: _currentBooking.customerAge,
          idProofType: _currentBooking.idProofType,
          idNumber: _currentBooking.idNumber,
          idVerified: _currentBooking.idVerified,
          checkIn: _currentBooking.checkIn,
          checkOut: _currentBooking.checkOut,
          nights: _currentBooking.nights,
          totalAmount: _currentBooking.totalAmount,
          status: BookingStatus.cancelled,
          accessPin: _currentBooking.accessPin,
          locationUrl: _currentBooking.locationUrl,
          priorityExtensionEligible: false,
          createdAt: _currentBooking.createdAt,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = _currentBooking.status == BookingStatus.cancelled;

    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: 'Booking Details',
        subtitle: '#${_currentBooking.bookingId}',
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Pill & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _currentBooking.roomTitle,
                      style: const TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? coral.withValues(alpha: 0.15)
                          : greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCancelled ? 'CANCELLED' : 'CONFIRMED',
                      style: TextStyle(
                        color: isCancelled ? coral : greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${_currentBooking.locality}, ${_currentBooking.city}', style: const TextStyle(color: muted, fontSize: 13)),
              const SizedBox(height: 18),

              // Digital Door PIN Access Box (If not cancelled)
              if (!isCancelled) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: lime.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DIGITAL ACCESS PIN', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_currentBooking.accessPin, style: const TextStyle(color: lime, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: surfaceLight, foregroundColor: lime),
                        onPressed: _openDirections,
                        icon: const Icon(Icons.navigation_outlined, size: 16),
                        label: const Text('Directions', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_currentBooking.priorityExtensionEligible) ...[
                  ExtensionOfferCard(booking: _currentBooking),
                  const SizedBox(height: 18),
                ],
              ],

              // Reservation Info Card
              const Text('Reservation Summary', style: TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildRow('Check-in', '${_currentBooking.checkIn} (12:00 PM)'),
                    const SizedBox(height: 10),
                    _buildRow('Check-out', '${_currentBooking.checkOut} (11:00 AM)'),
                    const SizedBox(height: 10),
                    _buildRow('Total Stay', '${_currentBooking.nights} Night(s)'),
                    const SizedBox(height: 10),
                    _buildRow('Guest Name', _currentBooking.customerName),
                    const SizedBox(height: 10),
                    _buildRow('WhatsApp', _currentBooking.customerPhone),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Payment Receipt Card
              const Text('Payment Receipt', style: TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildRow('Total Amount Paid', '₹${_currentBooking.totalAmount}'),
                    const SizedBox(height: 8),
                    _buildRow('Escrow Transaction', 'VERIFIED & LOCKED'),
                    const SizedBox(height: 8),
                    _buildRow('Payment Channel', 'Razorpay Gateway (UPI/Card)'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Digital Ticket Button
              AppButton(
                label: 'Open Digital Ticket Pass',
                icon: Icons.confirmation_number_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingTicketScreen(booking: _currentBooking),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Cancel Booking Button (if active)
              if (!isCancelled)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: coral),
                    foregroundColor: coral,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _openCancellation,
                  child: const Text('Cancel Booking & Get Full Refund', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: muted, fontSize: 13)),
        Text(value, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
