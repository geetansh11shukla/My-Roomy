import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../models/booking_model.dart';
import '../../shared/widgets/app_components.dart';
import '../../services/booking_engine.dart';
import '../booking/booking_confirmation_screen.dart';

enum PaymentState {
  selectMethod,
  processing,
  success,
  failed,
  pendingReconciliation,
}

class PaymentScreen extends StatefulWidget {
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

  const PaymentScreen({
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
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentState _state = PaymentState.selectMethod;
  String _selectedMethod = 'UPI (GPay / PhonePe / Paytm)';
  final BookingEngine _bookingEngine = BookingEngine();
  String? _errorMessage;

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'upi',
      'title': 'UPI (GPay / PhonePe / Paytm)',
      'subtitle': 'Instant 0% transaction fee via Virtual Payment Address',
      'icon': Icons.account_balance_wallet_outlined,
    },
    {
      'id': 'netbanking',
      'title': 'Net Banking',
      'subtitle': 'HDFC, ICICI, SBI, Axis & top Indian banks',
      'icon': Icons.account_balance_outlined,
    },
    {
      'id': 'card',
      'title': 'Debit / Credit Card (Gateway Hosted)',
      'subtitle':
          'Visa, Mastercard, RuPay processed securely via Razorpay gateway',
      'icon': Icons.credit_card_outlined,
    },
  ];

  void _triggerPayment() async {
    setState(() {
      _state = PaymentState.processing;
      _errorMessage = null;
    });

    // Gateway processing simulation (never stores CVV locally)
    await Future.delayed(const Duration(milliseconds: 1800));

    // Execute atomic booking transaction with slot locking
    final res = await _bookingEngine.executeInstantBooking(
      room: widget.room,
      customerName: widget.customerName,
      customerPhone: widget.customerPhone,
      customerAge: widget.customerAge,
      idProofType: widget.idType,
      idNumber: widget.idNumber,
      checkInDate: widget.checkInDate,
      stayDays: widget.nights,
      totalAmount: widget.totalAmount,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final booking = res['booking'] as BookingModel;
      setState(() {
        _state = PaymentState.success;
      });

      // Navigate to dedicated Booking Confirmation Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BookingConfirmationScreen(booking: booking, room: widget.room),
        ),
      );
    } else {
      setState(() {
        _errorMessage =
            res['error'] ?? 'Payment gateway could not verify transaction.';
        _state = PaymentState.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: 'Payment Gateway',
        subtitle: 'Secured 256-Bit Escrow Checkout',
        showBack: _state == PaymentState.selectMethod,
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(20), child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case PaymentState.processing:
        return _buildProcessingView();
      case PaymentState.failed:
        return _buildFailedView();
      case PaymentState.pendingReconciliation:
        return _buildPendingReconciliationView();
      case PaymentState.selectMethod:
      default:
        return _buildSelectMethodView();
    }
  }

  Widget _buildSelectMethodView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Payable Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lime.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL PAYABLE (INR)',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${widget.totalAmount}',
                    style: const TextStyle(
                      color: textWhite,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_rounded, color: greenAccent, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '100% Escrow Safe',
                      style: TextStyle(
                        color: greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Select Gateway Payment Method',
          style: TextStyle(
            color: textWhite,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'My Roomy does not collect or store card numbers or CVVs. All transactions are securely routed through PCI-DSS compliant partner gateways.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 16),

        ..._methods.map((m) {
          final isSel = _selectedMethod == m['title'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSel ? lime : Colors.white10),
            ),
            child: ListTile(
              onTap: () =>
                  setState(() => _selectedMethod = m['title'] as String),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSel ? lime.withValues(alpha: 0.2) : surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  m['icon'] as IconData,
                  color: isSel ? lime : textWhite,
                  size: 20,
                ),
              ),
              title: Text(
                m['title'] as String,
                style: const TextStyle(
                  color: textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                m['subtitle'] as String,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
              trailing: Radio<String>(
                value: m['title'] as String,
                groupValue: _selectedMethod,
                activeColor: lime,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMethod = val);
                },
              ),
            ),
          );
        }),

        const Spacer(),

        AppButton(
          label: 'Pay ₹${widget.totalAmount} Now',
          icon: Icons.payment_rounded,
          onPressed: _triggerPayment,
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(color: lime, strokeWidth: 3.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Connecting to Bank Gateway...',
            style: TextStyle(
              color: textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Authorizing transaction & locking room slot. Please do not refresh or close this window.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: coral.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: coral,
              size: 54,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment Failed or Declined',
            style: TextStyle(
              color: textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Your bank declined the transaction. The room slot hold remains active for a few minutes.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Retry Payment',
            onPressed: () => setState(() => _state = PaymentState.selectMethod),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReconciliationView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF3B2D05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Colors.amber,
              size: 54,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment Pending Bank Webhook',
            style: TextStyle(
              color: textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We received authorization but the bank is still settling. We will update your status as soon as the gateway confirms.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Check My Bookings',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
