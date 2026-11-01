import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../shared/widgets/app_components.dart';
import '../../services/booking_engine.dart';

class ExtensionCheckoutScreen extends StatefulWidget {
  final BookingModel booking;
  final int additionalDays;
  final int additionalAmount;
  final String proposedCheckOut;

  const ExtensionCheckoutScreen({
    super.key,
    required this.booking,
    required this.additionalDays,
    required this.additionalAmount,
    required this.proposedCheckOut,
  });

  @override
  State<ExtensionCheckoutScreen> createState() => _ExtensionCheckoutScreenState();
}

class _ExtensionCheckoutScreenState extends State<ExtensionCheckoutScreen> {
  final BookingEngine _bookingEngine = BookingEngine();
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'UPI (Instant)';
  bool _isSuccess = false;

  void _confirmAndPay() async {
    setState(() => _isProcessing = true);

    // Call backend stay extension transaction
    final success = await _bookingEngine.requestStayExtension(
      bookingId: widget.booking.bookingId,
      additionalDays: widget.additionalDays,
      additionalAmount: widget.additionalAmount,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isSuccess = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: const AppHeader(title: 'Stay Extension Checkout', showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isSuccess ? _buildSuccessView() : _buildCheckoutView(),
        ),
      ),
    );
  }

  Widget _buildCheckoutView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lime.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ORIGINAL PASS: #${widget.booking.bookingId}', style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: greenAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('PRIORITY LOCKED', style: TextStyle(color: greenAccent, fontWeight: FontWeight.bold, fontSize: 9)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text(widget.booking.roomTitle, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${widget.booking.locality}, ${widget.booking.city}', style: const TextStyle(color: muted, fontSize: 12)),
              const Divider(color: Colors.white10, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Additional Stay', style: TextStyle(color: muted, fontSize: 13)),
                  Text('+${widget.additionalDays} Night(s)', style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Checkout Timeline', style: TextStyle(color: muted, fontSize: 13)),
                  Text(widget.proposedCheckOut, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Extension Amount Due', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('₹${widget.additionalAmount}', style: const TextStyle(color: lime, fontWeight: FontWeight.w900, fontSize: 22)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text('Select Payment Method', style: TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ...['UPI (Instant)', 'Net Banking (Escrow)', 'Gateway Saved Card'].map((method) {
          final isSel = _selectedPaymentMethod == method;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSel ? lime : Colors.white10),
            ),
            child: ListTile(
              leading: Icon(
                method.contains('UPI') ? Icons.account_balance_wallet_outlined : Icons.account_balance_outlined,
                color: isSel ? lime : textWhite,
              ),
              title: Text(method, style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
              trailing: Radio<String>(
                value: method,
                groupValue: _selectedPaymentMethod,
                activeColor: lime,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPaymentMethod = val);
                },
              ),
              onTap: () => setState(() => _selectedPaymentMethod = method),
            ),
          );
        }),

        const Spacer(),

        AppButton(
          label: 'Pay ₹${widget.additionalAmount} & Confirm Extension',
          icon: Icons.lock_outline_rounded,
          isLoading: _isProcessing,
          onPressed: _confirmAndPay,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(color: Color(0xFF0F3E2E), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: greenAccent, size: 54),
          ),
          const SizedBox(height: 20),
          const Text('Stay Extension Confirmed!', style: TextStyle(color: textWhite, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Your reservation for ${widget.booking.roomTitle} has been extended by ${widget.additionalDays} night(s).\nUpdated digital pass sent to WhatsApp (${widget.booking.customerPhone}).',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'View Updated Passes',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}
