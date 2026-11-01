import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../shared/widgets/app_components.dart';

class CancellationScreen extends StatefulWidget {
  final BookingModel booking;
  const CancellationScreen({super.key, required this.booking});

  @override
  State<CancellationScreen> createState() => _CancellationScreenState();
}

class _CancellationScreenState extends State<CancellationScreen> {
  bool _isProcessing = false;
  bool _isCancelled = false;
  String _selectedReason = 'Change of travel plans';

  final List<String> _reasons = [
    'Change of travel plans',
    'Found another stay',
    'Booking made by mistake',
    'Emergency / Personal reasons',
  ];

  // Calculated server refund
  int get _refundableAmount => widget.booking.totalAmount; // 100% free cancellation eligible

  void _confirmCancellation() async {
    setState(() => _isProcessing = true);

    // Simulate backend cancellation and instant escrow refund trigger
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isCancelled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: const AppHeader(title: 'Cancel Booking', showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isCancelled ? _buildCancelledSuccessView() : _buildConfirmView(),
        ),
      ),
    );
  }

  Widget _buildConfirmView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cancellation Notice Card
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
              Text(widget.booking.roomTitle, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Booking ID #${widget.booking.bookingId}', style: const TextStyle(color: muted, fontSize: 12)),
              const Divider(color: Colors.white10, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Original Amount Paid', style: TextStyle(color: muted, fontSize: 13)),
                  Text('₹${widget.booking.totalAmount}', style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cancellation Penalty', style: TextStyle(color: greenAccent, fontSize: 13)),
                  Text('₹0 (100% Free)', style: TextStyle(color: greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Refund', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('₹$_refundableAmount', style: const TextStyle(color: lime, fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('Reason for Cancellation', style: TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ..._reasons.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _selectedReason == r ? lime : Colors.white10),
              ),
              child: RadioListTile<String>(
                value: r,
                groupValue: _selectedReason,
                title: Text(r, style: const TextStyle(color: textWhite, fontSize: 13)),
                activeColor: lime,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedReason = val);
                },
              ),
            )),

        const Spacer(),

        AppButton(
          label: 'Confirm Cancellation & Refund',
          isLoading: _isProcessing,
          onPressed: _confirmCancellation,
        ),
      ],
    );
  }

  Widget _buildCancelledSuccessView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: coral.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded, color: coral, size: 54),
          ),
          const SizedBox(height: 20),
          const Text('Booking Successfully Cancelled', style: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Refund of ₹$_refundableAmount has been initiated to your original payment method via escrow gateway (typically reflects within 24-48 hours).',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Back to My Bookings',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}
