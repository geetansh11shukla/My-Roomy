enum BookingStatus {
  pendingPayment,
  confirmed,
  cancelled,
  completed,
  extended,
}

enum PaymentStatus {
  pending,
  captured,
  failed,
  refunded,
}

/// Frontend Data Model for Bookings with Escrow Audit and Zero-Broker Lifecycle
class BookingModel {
  final String bookingId;
  final String roomId;
  final String customerId;
  final String ownerId;
  final String roomTitleSnapshot;
  final String checkIn; // Formatted date string or ISO
  final String checkOut; // Formatted date string or ISO
  final int guestCount;
  final int nightCount;
  final int pricePerNightSnapshot;
  final int subtotal;
  final int fees;
  final int taxAmount;
  final int discountAmount;
  final int totalAmount;
  final String currency;
  final BookingStatus bookingStatus;
  final PaymentStatus paymentStatus;
  final String cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Keyless / operational access details
  final String accessPin;
  final String locationUrl;
  final bool priorityExtensionEligible;
  final String locality;
  final String city;
  final String customerName;
  final String customerPhone;
  final int customerAge;
  final String idProofType;
  final String idNumber;
  final bool idVerified;

  // Backward-compatible accessors
  String get roomTitle => roomTitleSnapshot;
  int get nights => nightCount;
  BookingStatus get status => bookingStatus;
  int get totalPrice => totalAmount;
  String get digitalDoorPin => accessPin;

  const BookingModel({
    required this.bookingId,
    required this.roomId,
    this.customerId = 'cust_default',
    this.ownerId = 'host_default',
    String? roomTitleSnapshot,
    String? roomTitle,
    this.locality = 'Gomti Nagar',
    this.city = 'Lucknow',
    this.customerName = 'Rahul Kumar',
    this.customerPhone = '+91 9876543210',
    this.customerAge = 24,
    this.idProofType = 'Aadhaar Card',
    this.idNumber = '•••• •••• ••••',
    this.idVerified = true,
    required this.checkIn,
    required this.checkOut,
    this.guestCount = 1,
    int? nightCount,
    int? nights,
    this.pricePerNightSnapshot = 799,
    this.subtotal = 799,
    this.fees = 49,
    this.taxAmount = 40,
    this.discountAmount = 100,
    required this.totalAmount,
    this.currency = 'INR',
    BookingStatus? bookingStatus,
    BookingStatus? status,
    this.paymentStatus = PaymentStatus.captured,
    this.cancellationReason = '',
    this.accessPin = 'PIN1234',
    this.locationUrl = 'https://maps.google.com/?q=26.8467,80.9462',
    this.priorityExtensionEligible = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : roomTitleSnapshot = roomTitleSnapshot ?? roomTitle ?? 'Cozy City Room',
        nightCount = nightCount ?? nights ?? 1,
        bookingStatus = bookingStatus ?? status ?? BookingStatus.confirmed,
        createdAt = createdAt ?? const _DefaultDateTime(),
        updatedAt = updatedAt ?? createdAt ?? const _DefaultDateTime();

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      bookingId: id,
      roomId: map['roomId'] ?? '',
      customerId: map['customerId'] ?? '',
      ownerId: map['ownerId'] ?? 'host_default',
      roomTitleSnapshot: map['roomTitleSnapshot'] ?? map['roomTitle'] ?? '',
      locality: map['locality'] ?? 'Gomti Nagar',
      city: map['city'] ?? 'Lucknow',
      customerName: map['customerName'] ?? 'Rahul Kumar',
      customerPhone: map['customerPhone'] ?? '+91 9876543210',
      customerAge: (map['customerAge'] as num?)?.toInt() ?? 24,
      idProofType: map['idProofType'] ?? 'Aadhaar Card',
      idNumber: map['idNumber'] ?? '•••• •••• ••••',
      idVerified: map['idVerified'] ?? true,
      checkIn: map['checkIn'] ?? '',
      checkOut: map['checkOut'] ?? '',
      guestCount: (map['guestCount'] as num?)?.toInt() ?? (map['guests'] as num?)?.toInt() ?? 1,
      nightCount: (map['nightCount'] as num?)?.toInt() ?? (map['nights'] as num?)?.toInt() ?? 1,
      pricePerNightSnapshot: (map['pricePerNightSnapshot'] as num?)?.toInt() ?? 799,
      subtotal: (map['subtotal'] as num?)?.toInt() ?? (map['totalAmount'] as num?)?.toInt() ?? 799,
      fees: (map['fees'] as num?)?.toInt() ?? 49,
      taxAmount: (map['taxAmount'] as num?)?.toInt() ?? 40,
      discountAmount: (map['discountAmount'] as num?)?.toInt() ?? 100,
      totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 799,
      currency: map['currency'] ?? 'INR',
      bookingStatus: _parseStatus(map['bookingStatus'] ?? map['status']),
      paymentStatus: _parsePaymentStatus(map['paymentStatus']),
      cancellationReason: map['cancellationReason'] ?? '',
      accessPin: map['accessPin'] ?? map['digitalDoorPin'] ?? 'PIN1234',
      locationUrl: map['locationUrl'] ?? 'https://maps.google.com/?q=26.8467,80.9462',
      priorityExtensionEligible: map['priorityExtensionEligible'] ?? true,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'roomId': roomId,
      'customerId': customerId,
      'ownerId': ownerId,
      'roomTitleSnapshot': roomTitleSnapshot,
      'roomTitle': roomTitleSnapshot, // legacy compatibility
      'locality': locality,
      'city': city,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAge': customerAge,
      'idProofType': idProofType,
      'idNumber': idNumber,
      'idVerified': idVerified,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'guestCount': guestCount,
      'nightCount': nightCount,
      'nights': nightCount, // legacy compatibility
      'pricePerNightSnapshot': pricePerNightSnapshot,
      'subtotal': subtotal,
      'fees': fees,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'currency': currency,
      'bookingStatus': bookingStatus.name,
      'status': bookingStatus.name, // legacy compatibility
      'paymentStatus': paymentStatus.name,
      'cancellationReason': cancellationReason,
      'accessPin': accessPin,
      'locationUrl': locationUrl,
      'priorityExtensionEligible': priorityExtensionEligible,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? bookingId,
    String? roomId,
    String? customerId,
    String? ownerId,
    String? roomTitleSnapshot,
    String? checkIn,
    String? checkOut,
    int? guestCount,
    int? nightCount,
    int? pricePerNightSnapshot,
    int? subtotal,
    int? fees,
    int? taxAmount,
    int? discountAmount,
    int? totalAmount,
    String? currency,
    BookingStatus? bookingStatus,
    PaymentStatus? paymentStatus,
    String? cancellationReason,
    String? accessPin,
    String? locationUrl,
    bool? priorityExtensionEligible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      roomId: roomId ?? this.roomId,
      customerId: customerId ?? this.customerId,
      ownerId: ownerId ?? this.ownerId,
      roomTitleSnapshot: roomTitleSnapshot ?? this.roomTitleSnapshot,
      locality: locality,
      city: city,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAge: customerAge,
      idProofType: idProofType,
      idNumber: idNumber,
      idVerified: idVerified,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guestCount: guestCount ?? this.guestCount,
      nightCount: nightCount ?? this.nightCount,
      pricePerNightSnapshot: pricePerNightSnapshot ?? this.pricePerNightSnapshot,
      subtotal: subtotal ?? this.subtotal,
      fees: fees ?? this.fees,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      accessPin: accessPin ?? this.accessPin,
      locationUrl: locationUrl ?? this.locationUrl,
      priorityExtensionEligible: priorityExtensionEligible ?? this.priorityExtensionEligible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static BookingStatus _parseStatus(dynamic val) {
    if (val == null) return BookingStatus.confirmed;
    final str = val.toString().toLowerCase();
    for (final s in BookingStatus.values) {
      if (s.name.toLowerCase() == str) return s;
    }
    return BookingStatus.confirmed;
  }

  static PaymentStatus _parsePaymentStatus(dynamic val) {
    if (val == null) return PaymentStatus.captured;
    final str = val.toString().toLowerCase();
    for (final s in PaymentStatus.values) {
      if (s.name.toLowerCase() == str) return s;
    }
    return PaymentStatus.captured;
  }
}

class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  DateTime get _now => DateTime.now();

  @override bool isAfter(DateTime other) => _now.isAfter(other);
  @override bool isBefore(DateTime other) => _now.isBefore(other);
  @override bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override int compareTo(DateTime other) => _now.compareTo(other);
  @override int get year => _now.year;
  @override int get month => _now.month;
  @override int get day => _now.day;
  @override int get hour => _now.hour;
  @override int get minute => _now.minute;
  @override int get second => _now.second;
  @override int get millisecond => _now.millisecond;
  @override int get microsecond => _now.microsecond;
  @override int get weekday => _now.weekday;
  @override bool get isUtc => _now.isUtc;
  @override String toIso8601String() => _now.toIso8601String();
  @override DateTime toLocal() => _now.toLocal();
  @override DateTime toUtc() => _now.toUtc();
  @override String toString() => _now.toString();
  @override DateTime add(Duration duration) => _now.add(duration);
  @override DateTime subtract(Duration duration) => _now.subtract(duration);
  @override Duration difference(DateTime other) => _now.difference(other);
  @override int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;
  @override String get timeZoneName => _now.timeZoneName;
  @override Duration get timeZoneOffset => _now.timeZoneOffset;
  DateTime copyWith({int? year, int? month, int? day, int? hour, int? minute, int? second, int? millisecond, int? microsecond, bool? isUtc}) => _now;
}
