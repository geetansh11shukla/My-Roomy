import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';
import '../payments/payment_screen.dart';

class TemporaryHoldScreen extends StatefulWidget {
  final RoomModel room;
  final String checkInDate;
  final String checkOutDate;
  final int nights;
  final int guests;
  final int totalAmount;
  final String customerName;
  final String customerPhone;
  final int customerAge;
  final String idType;
  final String idNumber;
  final int holdDurationSeconds; // Received from backend hold response

  const TemporaryHoldScreen({
    super.key,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.guests,
    required this.totalAmount,
    required this.customerName,
    required this.customerPhone,
    required this.customerAge,
    required this.idType,
    required this.idNumber,
    this.holdDurationSeconds = 600, // 10 minutes backend hold
  });

  @override
  State<TemporaryHoldScreen> createState() => _TemporaryHoldScreenState();
}

class _TemporaryHoldScreenState extends State<TemporaryHoldScreen> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.holdDurationSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        setState(() => _isExpired = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _proceedToPayment() {
    if (_isExpired) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          room: widget.room,
          checkInDate: widget.checkInDate,
          checkOutDate: widget.checkOutDate,
          nights: widget.nights,
          guests: widget.guests,
          totalAmount: widget.totalAmount,
          customerName: widget.customerName,
          customerPhone: widget.customerPhone,
          customerAge: widget.customerAge,
          idType: widget.idType,
          idNumber: widget.idNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: const AppHeader(title: 'Room Lock Hold', showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isExpired ? _buildExpiredView() : _buildActiveHoldView(),
        ),
      ),
    );
  }

  Widget _buildActiveHoldView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),

        // Live Countdown Clock
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: lime.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: lime.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              const Text('TEMPORARY HOLD EXPIRATION', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: lime, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    _formattedTime,
                    style: const TextStyle(color: lime, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'This room is reserved exclusively for you. Other guests cannot book these dates while the timer is running.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textWhite, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Room & Booking Snapshot Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.room.imageUrl.isNotEmpty
                      ? widget.room.imageUrl
                      : 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.room.title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('${widget.room.locality}, ${widget.room.city}', style: const TextStyle(color: muted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.checkInDate} • ${widget.nights} night(s) • ${widget.guests} guest(s)',
                      style: const TextStyle(color: lime, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Amount & Continue button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount Due', style: TextStyle(color: muted, fontSize: 13)),
              Text('₹${widget.totalAmount}', style: const TextStyle(color: textWhite, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        AppButton(
          label: 'Continue to Secure Payment',
          icon: Icons.lock_outline_rounded,
          onPressed: _proceedToPayment,
        ),
      ],
    );
  }

  Widget _buildExpiredView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: coral.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.alarm_off_rounded, color: coral, size: 54),
          ),
          const SizedBox(height: 20),
          const Text('Temporary Hold Expired', style: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'The dates have been unlocked for other travelers. Please re-check room availability to re-hold your slot.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Check Availability Again',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
