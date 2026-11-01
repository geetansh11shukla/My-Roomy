import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/extension_offer_model.dart';
import 'extension_date_selection_modal.dart';
import 'extension_checkout_screen.dart';

class ExtensionOfferCard extends StatefulWidget {
  final BookingModel booking;
  final int nightlyPrice;
  final VoidCallback? onOfferAccepted;

  const ExtensionOfferCard({
    super.key,
    required this.booking,
    this.nightlyPrice = 799,
    this.onOfferAccepted,
  });

  @override
  State<ExtensionOfferCard> createState() => _ExtensionOfferCardState();
}

class _ExtensionOfferCardState extends State<ExtensionOfferCard> {
  ExtensionOfferStatus _status = ExtensionOfferStatus.offered;

  void _acceptStandardOffer(int days) {
    final extraAmount = widget.nightlyPrice * days;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExtensionCheckoutScreen(
          booking: widget.booking,
          additionalDays: days,
          additionalAmount: extraAmount,
          proposedCheckOut: 'Extended (+${days}d)',
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        setState(() => _status = ExtensionOfferStatus.confirmed);
        if (widget.onOfferAccepted != null) widget.onOfferAccepted!();
      }
    });
  }

  void _openCustomDatePicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExtensionDateSelectionModal(
        booking: widget.booking,
        nightlyPrice: widget.nightlyPrice,
      ),
    );

    if (result != null && mounted) {
      final days = result['days'] as int;
      final amount = result['amount'] as int;
      final newDate = result['newCheckOut'] as String;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExtensionCheckoutScreen(
            booking: widget.booking,
            additionalDays: days,
            additionalAmount: amount,
            proposedCheckOut: newDate,
          ),
        ),
      ).then((confirmed) {
        if (confirmed == true && mounted) {
          setState(() => _status = ExtensionOfferStatus.confirmed);
          if (widget.onOfferAccepted != null) widget.onOfferAccepted!();
        }
      });
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text(
              'Extension Priority Terms',
              style: TextStyle(
                color: textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Current Guest VIP Priority',
              style: TextStyle(
                color: textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'As the active guest, you have the first right of refusal to extend your stay before dates are made available to other travelers.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            SizedBox(height: 12),
            Text(
              '2. Fixed Nightly Price Lock',
              style: TextStyle(
                color: textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Your extension is locked at the same negotiated nightly rate with zero surge pricing and zero broker commissions.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            SizedBox(height: 12),
            Text(
              '3. 24-Hour Expiration Window',
              style: TextStyle(
                color: textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Priority window closes 12 hours prior to scheduled checkout. Unaccepted holds are unlocked automatically by the backend.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: lime, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_status == ExtensionOfferStatus.declined) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: muted, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Stay extension priority declined. Room will be released at checkout.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () =>
                  setState(() => _status = ExtensionOfferStatus.offered),
              child: const Text(
                'Undo',
                style: TextStyle(color: lime, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_status == ExtensionOfferStatus.confirmed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: greenAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: greenAccent,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay Successfully Extended!',
                    style: TextStyle(
                      color: textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Updated WhatsApp pass & new checkout dates dispatched.',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lime.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: lime.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'VIP STAY EXTENSION PRIORITY',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: coral.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EXPIRES IN 11H:40M',
                    style: TextStyle(
                      color: coral,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.roomTitle,
                  style: const TextStyle(
                    color: textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current check-out: ${widget.booking.checkOut}. Would you like to extend your stay?',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 14),

                // Fast Extension Options Chips
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickOptionChip(
                        '+2 Days',
                        '₹${widget.nightlyPrice * 2}',
                        () => _acceptStandardOffer(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickOptionChip(
                        '+1 Week',
                        '₹${widget.nightlyPrice * 7}',
                        () => _acceptStandardOffer(7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          foregroundColor: textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _openCustomDatePicker,
                        child: const Text(
                          'Custom Dates',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Terms & Decline Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _showTermsDialog,
                      child: const Text(
                        'View Extension Terms',
                        style: TextStyle(
                          color: lime,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => setState(
                        () => _status = ExtensionOfferStatus.declined,
                      ),
                      child: const Text(
                        'Decline Offer',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOptionChip(String title, String price, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: surfaceLight,
        foregroundColor: textWhite,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white12),
        ),
      ),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: lime,
            ),
          ),
          const SizedBox(height: 2),
          Text(price, style: const TextStyle(fontSize: 11, color: muted)),
        ],
      ),
    );
  }
}
