import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';
import 'temporary_hold_screen.dart';
import '../identity_verification/verification_gate_screen.dart';

class BookingReviewScreen extends StatefulWidget {
  final RoomModel room;
  final String checkInDate;
  final String checkOutDate;
  final int nights;
  final int guests;

  const BookingReviewScreen({
    super.key,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.guests,
  });

  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  final _nameController = TextEditingController(text: 'Rahul Kumar');
  final _phoneController = TextEditingController(text: '9876543210');
  final _ageController = TextEditingController(text: '24');
  final _idNumberController = TextEditingController(text: '8834 9102 3341');

  final String _idType = 'Aadhaar Card';
  bool _termsAccepted = true;

  // Server-validated pricing structure
  int get _subtotal => widget.room.pricePerNight * widget.nights;
  int get _taxes => (_subtotal * 0.05).round(); // 5% GST
  int get _platformFee => 49; // Nominal verified stay pass fee
  int get _discount => 100; // My Roomy direct booking savings
  int get _grandTotal => _subtotal + _taxes + _platformFee - _discount;

  void _proceedToHold() {
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    if (age < 18) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VerificationGateScreen()),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid guest contact details.'),
        ),
      );
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemporaryHoldScreen(
          room: widget.room,
          checkInDate: widget.checkInDate,
          checkOutDate: widget.checkOutDate,
          nights: widget.nights,
          guests: widget.guests,
          totalAmount: _grandTotal,
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          customerAge: age,
          idType: _idType,
          idNumber: _idNumberController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: const AppHeader(title: 'Review Booking', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Overview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.room.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.room.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 80,
                                height: 80,
                                color: surfaceLight,
                                child: const Icon(
                                  Icons.hotel_rounded,
                                  color: lime,
                                ),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: surfaceLight,
                              child: const Icon(
                                Icons.hotel_rounded,
                                color: lime,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.room.isVerified)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: lime.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ROOMWALA VERIFIED',
                                style: TextStyle(
                                  color: lime,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Text(
                            widget.room.title,
                            style: const TextStyle(
                              color: textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.room.locality}, ${widget.room.city}',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${widget.room.pricePerNight} / night',
                            style: const TextStyle(
                              color: lime,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stay Schedule & Guests
              const Text(
                'Stay Details',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildRow('Check-in', '${widget.checkInDate} (12:00 PM)'),
                    const SizedBox(height: 10),
                    _buildRow('Check-out', '${widget.checkOutDate} (11:00 AM)'),
                    const SizedBox(height: 10),
                    _buildRow('Total Stay', '${widget.nights} Night(s)'),
                    const SizedBox(height: 10),
                    _buildRow('Total Guests', '${widget.guests} Guest(s)'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Price Breakdown (Validated from Service)
              const Text(
                'Price Breakdown',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildPriceRow(
                      'Base Room Rate (₹${widget.room.pricePerNight} × ${widget.nights})',
                      '₹$_subtotal',
                    ),
                    const SizedBox(height: 8),
                    _buildPriceRow('Taxes & GST (5%)', '₹$_taxes'),
                    const SizedBox(height: 8),
                    _buildPriceRow(
                      'Direct Stay Verification Pass',
                      '₹$_platformFee',
                    ),
                    const SizedBox(height: 8),
                    _buildPriceRow(
                      'My Roomy Member Discount',
                      '-₹$_discount',
                      isHighlight: true,
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Final Total',
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '₹$_grandTotal',
                          style: const TextStyle(
                            color: lime,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Primary Guest Details
              const Text(
                'Guest Identification',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: textWhite, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Lead Guest Legal Name',
                        labelStyle: TextStyle(color: muted, fontSize: 12),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: textWhite, fontSize: 14),
                      decoration: const InputDecoration(
                        prefixText: '+91 ',
                        prefixStyle: TextStyle(
                          color: textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                        labelText:
                            'WhatsApp Mobile Number (For Digital PIN Pass)',
                        labelStyle: TextStyle(color: muted, fontSize: 12),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: textWhite,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Age (18+)',
                              labelStyle: TextStyle(color: muted, fontSize: 12),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _idNumberController,
                            style: const TextStyle(
                              color: textWhite,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Aadhaar / Gov ID No.',
                              labelStyle: TextStyle(color: muted, fontSize: 12),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Cancellation Policy
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: greenAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% Free Cancellation Policy',
                            style: TextStyle(
                              color: textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Full refund if cancelled up to 24 hours prior to 12:00 PM check-in date. Zero cancellation penalty.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Terms Acceptance
              Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    activeColor: lime,
                    checkColor: navy,
                    onChanged: (val) =>
                        setState(() => _termsAccepted = val ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I accept My Roomy Guest Rules, 18+ verification terms and room policies.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              AppButton(
                label: 'Hold Dates & Continue',
                icon: Icons.lock_clock_rounded,
                onPressed: _proceedToHold,
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
        Text(
          value,
          style: const TextStyle(
            color: textWhite,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String title,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isHighlight ? greenAccent : muted,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? greenAccent : textWhite,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

