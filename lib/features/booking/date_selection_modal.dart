import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';

class DateSelectionModal extends StatefulWidget {
  final RoomModel room;
  final DateTime initialCheckIn;
  final DateTime initialCheckOut;

  const DateSelectionModal({
    super.key,
    required this.room,
    required this.initialCheckIn,
    required this.initialCheckOut,
  });

  @override
  State<DateSelectionModal> createState() => _DateSelectionModalState();
}

class _DateSelectionModalState extends State<DateSelectionModal> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  bool _isCheckingAvailability = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.initialCheckIn;
    _checkOut = widget.initialCheckOut.isAfter(_checkIn)
        ? widget.initialCheckOut
        : _checkIn.add(const Duration(days: 1));
  }

  int get _nights => _checkOut.difference(_checkIn).inDays;

  bool _isDateDisabled(DateTime day) {
    final today = DateTime.now();
    final dateOnlyToday = DateTime(today.year, today.month, today.day);
    if (day.isBefore(dateOnlyToday)) return true;

    final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return widget.room.bookedDates.contains(dateStr);
  }

  void _pickCheckInDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkIn.isBefore(now) ? now : _checkIn,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      selectableDayPredicate: (day) => !_isDateDisabled(day),
      builder: (context, child) => _buildDatePickerTheme(child!),
    );

    if (picked != null) {
      setState(() {
        _checkIn = picked;
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
        _validateDates();
      });
    }
  }

  void _pickCheckOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOut.isAfter(_checkIn) ? _checkOut : _checkIn.add(const Duration(days: 1)),
      firstDate: _checkIn.add(const Duration(days: 1)),
      lastDate: _checkIn.add(const Duration(days: 180)),
      selectableDayPredicate: (day) => !_isDateDisabled(day),
      builder: (context, child) => _buildDatePickerTheme(child!),
    );

    if (picked != null) {
      setState(() {
        _checkOut = picked;
        _validateDates();
      });
    }
  }

  void _validateDates() {
    if (!_checkOut.isAfter(_checkIn)) {
      _validationError = 'Check-out date must be after check-in date.';
      return;
    }

    // Check if any intermediate day in the stay is already booked
    DateTime curr = _checkIn;
    while (curr.isBefore(_checkOut)) {
      final dateStr = '${curr.year}-${curr.month.toString().padLeft(2, '0')}-${curr.day.toString().padLeft(2, '0')}';
      if (widget.room.bookedDates.contains(dateStr)) {
        _validationError = '$dateStr is unavailable. Please pick another stay window.';
        return;
      }
      curr = curr.add(const Duration(days: 1));
    }

    _validationError = null;
  }

  void _confirmDates() async {
    _validateDates();
    if (_validationError != null) return;

    setState(() => _isCheckingAvailability = true);

    // Simulated trusted backend revalidation call
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    setState(() => _isCheckingAvailability = false);

    Navigator.pop(context, {
      'checkIn': _checkIn,
      'checkOut': _checkOut,
      'nights': _nights,
    });
  }

  Widget _buildDatePickerTheme(Widget child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: lime,
          onPrimary: navy,
          surface: surface,
          onSurface: textWhite,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.room.pricePerNight * _nights;

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
                  'Select Stay Dates',
                  style: TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: lime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_nights night${_nights == 1 ? '' : 's'}',
                    style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Past dates & conflicting reserved dates are automatically disabled.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Date Pickers Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickCheckInDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.login_rounded, color: lime, size: 14),
                              SizedBox(width: 6),
                              Text('CHECK-IN', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_checkIn.day} ${_getMonth(_checkIn.month)} ${_checkIn.year}',
                            style: const TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Text('12:00 PM onwards', style: TextStyle(color: muted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickCheckOutDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.logout_rounded, color: lime, size: 14),
                              SizedBox(width: 6),
                              Text('CHECK-OUT', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_checkOut.day} ${_getMonth(_checkOut.month)} ${_checkOut.year}',
                            style: const TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Text('11:00 AM', style: TextStyle(color: muted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: coral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: coral.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: coral, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_validationError!, style: const TextStyle(color: coral, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Pricing summary
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
                        '₹${widget.room.pricePerNight} × $_nights night${_nights == 1 ? '' : 's'}',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                      const Text(
                        'Informational preview. Server confirms lock.',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                  Text(
                    '₹$subtotal',
                    style: const TextStyle(color: lime, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            AppButton(
              label: 'Confirm Dates',
              isLoading: _isCheckingAvailability,
              onPressed: _validationError == null ? _confirmDates : null,
            ),
          ],
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[month];
  }
}
