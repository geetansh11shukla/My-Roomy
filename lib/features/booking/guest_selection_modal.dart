import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';

class GuestSelectionModal extends StatefulWidget {
  final RoomModel room;
  final int initialAdults;
  final int initialChildren;

  const GuestSelectionModal({
    super.key,
    required this.room,
    this.initialAdults = 1,
    this.initialChildren = 0,
  });

  @override
  State<GuestSelectionModal> createState() => _GuestSelectionModalState();
}

class _GuestSelectionModalState extends State<GuestSelectionModal> {
  late int _adults;
  late int _children;

  // Derive maximum capacity from room model configuration
  int get _maxCapacity {
    if (widget.room.tag.toLowerCase().contains('studio')) return 2;
    if (widget.room.title.toLowerCase().contains('double')) return 3;
    if (widget.room.pricePerNight >= 1200) return 4;
    return 2;
  }

  @override
  void initState() {
    super.initState();
    _adults = widget.initialAdults;
    _children = widget.initialChildren;
  }

  int get _totalGuests => _adults + _children;
  bool get _canAddGuest => _totalGuests < _maxCapacity;

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
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Guests',
                  style: TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: lime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Max $_maxCapacity Guests',
                    style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Configured room limit based on fire & security guidelines for ${widget.room.title}.',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Adults Row
            _buildCounterRow(
              title: 'Adults',
              subtitle: 'Age 18+ (Govt ID required)',
              count: _adults,
              onDecrement: _adults > 1 ? () => setState(() => _adults--) : null,
              onIncrement: _canAddGuest ? () => setState(() => _adults++) : null,
            ),
            const Divider(color: Colors.white10, height: 24),

            // Children Row
            _buildCounterRow(
              title: 'Children',
              subtitle: 'Age 2 - 17 (Stay free with guardian)',
              count: _children,
              onDecrement: _children > 0 ? () => setState(() => _children--) : null,
              onIncrement: _canAddGuest ? () => setState(() => _children++) : null,
            ),

            if (_totalGuests >= _maxCapacity) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: lime, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Maximum capacity of $_maxCapacity guests reached for this room.',
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            AppButton(
              label: 'Confirm Guests ($_totalGuests)',
              onPressed: () {
                Navigator.pop(context, {
                  'adults': _adults,
                  'children': _children,
                  'total': _totalGuests,
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow({
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback? onDecrement,
    required VoidCallback? onIncrement,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: textWhite, fontSize: 15, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                color: onDecrement != null ? lime : Colors.white24,
                size: 26,
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: onIncrement != null ? lime : Colors.white24,
                size: 26,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
