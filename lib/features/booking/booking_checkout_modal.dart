import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../services/booking_engine.dart';
import 'booking_pass_dialog.dart';

class BookingCheckoutModal extends StatefulWidget {
  final RoomModel room;

  const BookingCheckoutModal({super.key, required this.room});

  @override
  State<BookingCheckoutModal> createState() => _BookingCheckoutModalState();
}

class _BookingCheckoutModalState extends State<BookingCheckoutModal> {
  final BookingEngine _bookingEngine = BookingEngine();
  final _nameController = TextEditingController(text: 'Rahul Kumar');
  final _phoneController = TextEditingController(text: '9876543210');
  final _ageController = TextEditingController(text: '24');
  final _idNumberController = TextEditingController(text: '8834 9102 3341');

  String _idType = 'Aadhaar Card';
  int _stayDays = 2;
  bool _isProcessing = false;
  final String _checkInDate = DateTime.now().toString().split(' ')[0];

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.room.pricePerNight * _stayDays;
    final taxes = (subtotal * 0.05).round();
    final grandTotal = subtotal + taxes;

    return Container(
      decoration: const BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Instant Booking & KYC',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Room mini summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.room.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.bed, color: lime),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.room.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.room.locality,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        Text(
                          '₹${widget.room.pricePerNight} / night',
                          style: const TextStyle(
                            color: lime,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            const Text(
              '1. Stay Duration',
              style: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 2, 5, 10, 30].map((days) {
                final isSelected = _stayDays == days;
                return ChoiceChip(
                  label: Text(days == 30 ? '1 Month (25% OFF)' : '$days Days'),
                  selected: isSelected,
                  selectedColor: lime,
                  backgroundColor: surface,
                  labelStyle: TextStyle(
                    color: isSelected ? navy : textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _stayDays = days),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),
            const Text(
              '2. Guest Identity & 18+ Age Check',
              style: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Age and Phone Row
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: textWhite),
                    decoration: InputDecoration(
                      labelText: 'Age (18+)',
                      labelStyle: const TextStyle(color: muted),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: textWhite),
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Mobile',
                      labelStyle: const TextStyle(color: muted),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Name Field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: textWhite),
              decoration: InputDecoration(
                labelText: 'Full Name (As per Govt ID)',
                labelStyle: const TextStyle(color: muted),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ID Type Selector
            Wrap(
              spacing: 8,
              children:
                  [
                    'Aadhaar Card',
                    'Driving License',
                    'Voter ID',
                    'Passport',
                  ].map((t) {
                    final isSelected = _idType == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: isSelected,
                      selectedColor: const Color(0xFF3B82F6),
                      backgroundColor: surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : muted,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setState(() => _idType = t),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 8),

            // ID Number Field
            TextField(
              controller: _idNumberController,
              style: const TextStyle(color: textWhite),
              decoration: InputDecoration(
                labelText: '$_idType Number',
                labelStyle: const TextStyle(color: muted),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 18),
            const Text(
              '3. Payment Method',
              style: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: lime),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: lime,
                          size: 20,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'UPI / QR',
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.credit_card, color: muted, size: 20),
                        SizedBox(height: 4),
                        Text(
                          'Card',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.account_balance, color: muted, size: 20),
                        SizedBox(height: 4),
                        Text(
                          'NetBanking',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Text(
              '4. Payment Summary',
              style: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Room Rent ($_stayDays Days)',
                        style: const TextStyle(color: muted),
                      ),
                      Text(
                        '₹$subtotal',
                        style: const TextStyle(color: textWhite),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Taxes & Escrow (5%)',
                        style: TextStyle(color: muted),
                      ),
                      Text('₹$taxes', style: const TextStyle(color: textWhite)),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(
                          color: textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹$grandTotal',
                        style: const TextStyle(
                          color: lime,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pay & Lock Slot Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: lime,
                  foregroundColor: navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        final age =
                            int.tryParse(_ageController.text.trim()) ?? 0;
                        if (age < 18) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Guest must be at least 18 years old!',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() => _isProcessing = true);

                        final result = await _bookingEngine
                            .executeInstantBooking(
                              room: widget.room,
                              customerName: _nameController.text.trim(),
                              customerPhone: _phoneController.text.trim(),
                              customerAge: age,
                              idProofType: _idType,
                              idNumber: _idNumberController.text.trim(),
                              checkInDate: _checkInDate,
                              stayDays: _stayDays,
                              totalAmount: grandTotal,
                            );

                        setState(() => _isProcessing = false);

                        if (!mounted) return;

                        final scaffold = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        if (result['success'] == true) {
                          navigator.pop();
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) =>
                                BookingPassDialog(booking: result['booking']),
                          );
                        } else {
                          scaffold.showSnackBar(
                            SnackBar(
                              content: Text(
                                result['error'] ?? 'Booking failed',
                              ),
                            ),
                          );
                        }
                      },
                child: _isProcessing
                    ? const CircularProgressIndicator(color: navy)
                    : const Text(
                        'Pay & Confirm Instant Booking',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
