import 'package:flutter/foundation.dart';

enum ExtensionOfferStatus {
  offered,
  accepted,
  pendingPayment,
  confirmed,
  declined,
  expired,
}

@immutable
class ExtensionOfferModel {
  final String offerId;
  final String bookingId;
  final String roomId;
  final String customerId;
  final String ownerId;
  final DateTime offeredAt;
  final DateTime expiresAt;
  final DateTime requestedCheckIn;
  final DateTime requestedCheckOut;
  final double quotedAmount;
  final ExtensionOfferStatus status;
  final DateTime? reminderScheduledAt;
  final DateTime? reminderSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExtensionOfferModel({
    required this.offerId,
    required this.bookingId,
    required this.roomId,
    required this.customerId,
    required this.ownerId,
    required this.offeredAt,
    required this.expiresAt,
    required this.requestedCheckIn,
    required this.requestedCheckOut,
    required this.quotedAmount,
    this.status = ExtensionOfferStatus.offered,
    this.reminderScheduledAt,
    this.reminderSentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check whether offer has passed expiration
  bool get isExpired => DateTime.now().isAfter(expiresAt) || status == ExtensionOfferStatus.expired;

  /// Check whether offer is currently actionable
  bool get canAccept => status == ExtensionOfferStatus.offered && !isExpired;

  /// Number of extra nights requested
  int get additionalNights {
    final diff = requestedCheckOut.difference(requestedCheckIn).inDays;
    return diff > 0 ? diff : 1;
  }

  ExtensionOfferModel copyWith({
    String? offerId,
    String? bookingId,
    String? roomId,
    String? customerId,
    String? ownerId,
    DateTime? offeredAt,
    DateTime? expiresAt,
    DateTime? requestedCheckIn,
    DateTime? requestedCheckOut,
    double? quotedAmount,
    ExtensionOfferStatus? status,
    DateTime? reminderScheduledAt,
    DateTime? reminderSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExtensionOfferModel(
      offerId: offerId ?? this.offerId,
      bookingId: bookingId ?? this.bookingId,
      roomId: roomId ?? this.roomId,
      customerId: customerId ?? this.customerId,
      ownerId: ownerId ?? this.ownerId,
      offeredAt: offeredAt ?? this.offeredAt,
      expiresAt: expiresAt ?? this.expiresAt,
      requestedCheckIn: requestedCheckIn ?? this.requestedCheckIn,
      requestedCheckOut: requestedCheckOut ?? this.requestedCheckOut,
      quotedAmount: quotedAmount ?? this.quotedAmount,
      status: status ?? this.status,
      reminderScheduledAt: reminderScheduledAt ?? this.reminderScheduledAt,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'offerId': offerId,
      'bookingId': bookingId,
      'roomId': roomId,
      'customerId': customerId,
      'ownerId': ownerId,
      'offeredAt': offeredAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'requestedCheckIn': requestedCheckIn.toIso8601String(),
      'requestedCheckOut': requestedCheckOut.toIso8601String(),
      'quotedAmount': quotedAmount,
      'status': status.name,
      'reminderScheduledAt': reminderScheduledAt?.toIso8601String(),
      'reminderSentAt': reminderSentAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ExtensionOfferModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is String) {
        return DateTime.tryParse(val) ?? fallback ?? DateTime.now();
      }
      return fallback ?? DateTime.now();
    }

    ExtensionOfferStatus parseStatus(dynamic val) {
      if (val == null) return ExtensionOfferStatus.offered;
      return ExtensionOfferStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == val.toString().toLowerCase(),
        orElse: () => ExtensionOfferStatus.offered,
      );
    }

    return ExtensionOfferModel(
      offerId: map['offerId']?.toString() ?? '',
      bookingId: map['bookingId']?.toString() ?? '',
      roomId: map['roomId']?.toString() ?? '',
      customerId: map['customerId']?.toString() ?? '',
      ownerId: map['ownerId']?.toString() ?? '',
      offeredAt: parseDate(map['offeredAt']),
      expiresAt: parseDate(map['expiresAt'], DateTime.now().add(const Duration(hours: 24))),
      requestedCheckIn: parseDate(map['requestedCheckIn']),
      requestedCheckOut: parseDate(map['requestedCheckOut'], DateTime.now().add(const Duration(days: 1))),
      quotedAmount: (map['quotedAmount'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(map['status']),
      reminderScheduledAt: map['reminderScheduledAt'] != null ? parseDate(map['reminderScheduledAt']) : null,
      reminderSentAt: map['reminderSentAt'] != null ? parseDate(map['reminderSentAt']) : null,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
