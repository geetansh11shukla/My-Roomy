import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../shared/widgets/app_components.dart';

class ExtensionDateSelectionModal extends StatefulWidget {
  final BookingModel booking;
  final int nightlyPrice;

  const ExtensionDateSelectionModal({
    super.key,
    required this.booking,
    required this.nightlyPrice,
  });

  @override
  State<ExtensionDateSelectionModal> createState() =>
      _ExtensionDateSelectionModalState();
}

class _ExtensionDateSelectionModalState
    extends State<ExtensionDateSelectionModal> {
  int _additionalDays = 3;
  bool _isCheckingAvailability = false;

  int get _extensionTotal => widget.nightlyPrice * _additionalDays;

  void _verifyAndConfirm() async {
    setState(() {
      _isCheckingAvailability = true;
    });

    // Backend availability validation simulation
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _isCheckingAvailability = false;
    });

    Navigator.pop(context, {
      'days': _additionalDays,
      'amount': _extensionTotal,
      'newCheckOut': 'Auto-extended (+${_additionalDays}d)',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
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
                  'Select Extension Days',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRIORITY LOCK',
                    style: TextStyle(
                      color: lime,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Extending reservation for ${widget.booking.roomTitle}.',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Number of Days Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Stay',
                      style: TextStyle(
                        color: textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '₹${widget.nightlyPrice} per additional night',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        color: muted,
                        size: 28,
                      ),
                      onPressed: _additionalDays > 1
                          ? () => setState(() => _additionalDays--)
                          : null,
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$_additionalDays',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: textWhite,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: lime,
                        size: 28,
                      ),
                      onPressed: _additionalDays < 30
                          ? () => setState(() => _additionalDays++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // Price Calculation Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_additionalDays Night(s) × ₹${widget.nightlyPrice}',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      const Text(
                        'Zero brokerage · Direct host extension',
                        style: TextStyle(
                          color: greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹$_extensionTotal',
                    style: const TextStyle(
                      color: lime,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              label: 'Check Availability & Lock (₹$_extensionTotal)',
              icon: Icons.lock_clock_rounded,
              isLoading: _isCheckingAvailability,
              onPressed: _verifyAndConfirm,
            ),
          ],
        ),
      ),
    );
  }
}
