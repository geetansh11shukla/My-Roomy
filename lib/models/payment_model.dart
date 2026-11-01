/// Frontend Data Model for Escrow Payments
/// Note: Never store secrets, CVV, or raw card pins in frontend models.
class PaymentModel {
  final String paymentId;
  final String bookingId;
  final String provider; // 'razorpay' | 'phonepe' | 'paytm' | 'upi_intent'
  final String providerOrderId;
  final String providerPaymentId;
  final int amount;
  final String currency;
  final String status; // 'pending' | 'captured' | 'failed' | 'refunded'
  final DateTime? paidAt;
  final DateTime createdAt;

  // Backward compatibility aliases
  String get gatewayOrderId => providerOrderId;
  String get gatewayPaymentId => providerPaymentId;
  String get method => provider;

  const PaymentModel({
    required this.paymentId,
    required this.bookingId,
    this.provider = 'razorpay',
    required this.providerOrderId,
    required this.providerPaymentId,
    required this.amount,
    this.currency = 'INR',
    this.status = 'pending',
    this.paidAt,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      paymentId: id,
      bookingId: map['bookingId'] ?? '',
      provider: map['provider'] ?? map['method'] ?? 'razorpay',
      providerOrderId: map['providerOrderId'] ?? map['gatewayOrderId'] ?? '',
      providerPaymentId: map['providerPaymentId'] ?? map['gatewayPaymentId'] ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      currency: map['currency'] ?? 'INR',
      status: map['status'] ?? 'pending',
      paidAt: map['paidAt'] != null ? DateTime.tryParse(map['paidAt'].toString()) : null,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'bookingId': bookingId,
      'provider': provider,
      'providerOrderId': providerOrderId,
      'gatewayOrderId': providerOrderId, // legacy compatibility
      'providerPaymentId': providerPaymentId,
      'gatewayPaymentId': providerPaymentId, // legacy compatibility
      'amount': amount,
      'currency': currency,
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
