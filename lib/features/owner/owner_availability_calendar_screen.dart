import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';

class OwnerAvailabilityCalendarScreen extends StatefulWidget {
  final RoomModel room;
  const OwnerAvailabilityCalendarScreen({super.key, required this.room});

  @override
  State<OwnerAvailabilityCalendarScreen> createState() => _OwnerAvailabilityCalendarScreenState();
}

class _OwnerAvailabilityCalendarScreenState extends State<OwnerAvailabilityCalendarScreen> {
  late Set<String> _blockedDates;
  late Set<String> _confirmedBookings;
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _confirmedBookings = Set.from(widget.room.bookedDates);
    // Add demo confirmed booking dates
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dayAfter = DateTime.now().add(const Duration(days: 2));
    _confirmedBookings.add('${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}');
    _confirmedBookings.add('${dayAfter.year}-${dayAfter.month.toString().padLeft(2, '0')}-${dayAfter.day.toString().padLeft(2, '0')}');

    _blockedDates = {};
    // Demo maintenance block
    final nextWeek = DateTime.now().add(const Duration(days: 7));
    _blockedDates.add('${nextWeek.year}-${nextWeek.month.toString().padLeft(2, '0')}-${nextWeek.day.toString().padLeft(2, '0')}');
  }

  void _toggleDateBlock(DateTime day) {
    final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    // The frontend must NEVER let an owner override an existing confirmed booking!
    if (_confirmedBookings.contains(dateStr)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.amber, size: 22),
              SizedBox(width: 8),
              Text('Confirmed Stay Protected', style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Date $dateStr is locked by a confirmed guest reservation with escrow deposit.\n\nMy Roomy terms prevent modifying or canceling active guest dates directly from the calendar.',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood', style: TextStyle(color: lime))),
          ],
        ),
      );
      return;
    }

    setState(() {
      if (_blockedDates.contains(dateStr)) {
        _blockedDates.remove(dateStr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Date $dateStr unblocked. Now open for bookings!')),
        );
      } else {
        _blockedDates.add(dateStr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Date $dateStr blocked for maintenance/personal use.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: 'Availability Calendar',
        subtitle: widget.room.title,
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legend Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(lime, 'Available'),
                    _buildLegendItem(coral, 'Confirmed (Locked)'),
                    _buildLegendItem(Colors.grey, 'Owner Blocked'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Month Navigator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                    style: const TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: textWhite),
                        onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: textWhite),
                        onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Weekdays Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map((d) => SizedBox(
                          width: 36,
                          child: Text(d, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Calendar Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, i) {
                  final dayOffset = i - (firstDayWeekday - 1);
                  if (dayOffset < 0 || dayOffset >= daysInMonth) {
                    return const SizedBox();
                  }

                  final dayNum = dayOffset + 1;
                  final dayDate = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
                  final dateStr = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

                  final isConfirmed = _confirmedBookings.contains(dateStr);
                  final isBlocked = _blockedDates.contains(dateStr);

                  Color bgColor = surface;
                  Color borderColor = Colors.white12;
                  Color textColor = textWhite;

                  if (isConfirmed) {
                    bgColor = coral.withValues(alpha: 0.2);
                    borderColor = coral;
                    textColor = coral;
                  } else if (isBlocked) {
                    bgColor = Colors.white10;
                    borderColor = Colors.white24;
                    textColor = muted;
                  }

                  return InkWell(
                    onTap: () => _toggleDateBlock(dayDate),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$dayNum', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          if (isConfirmed)
                            const Text('LOCKED', style: TextStyle(color: coral, fontSize: 7, fontWeight: FontWeight.bold))
                          else if (isBlocked)
                            const Text('BLOCK', style: TextStyle(color: muted, fontSize: 7, fontWeight: FontWeight.bold))
                          else
                            Text('₹${widget.room.pricePerNight}', style: const TextStyle(color: lime, fontSize: 8, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Policy Info Note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: surfaceLight, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: lime, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap any open date to block/unblock. Confirmed booking dates cannot be overridden to protect guest reservations.',
                        style: TextStyle(color: muted, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: textWhite, fontSize: 11)),
      ],
    );
  }

  String _getMonthName(int m) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[m];
  }
}
