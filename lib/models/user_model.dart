/// Frontend Data Model for User Profile, Identity and Eligibility
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role; // 'customer' | 'owner' | 'admin'
  final String accountStatus; // 'active' | 'suspended' | 'pending_review'
  final String profilePhotoUrl;
  final DateTime? dateOfBirth;
  final String ageEligibilityStatus; // 'eligible_18_plus' | 'underage' | 'unverified'
  final String identityVerificationStatus; // 'not_started' | 'pending' | 'verified' | 'rejected'
  final String preferredLanguage; // 'en' | 'hi' | 'hinglish' | 'mr' | 'te' | 'bn'
  final Map<String, bool> notificationPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Backward-compatible getters
  String get name => fullName;
  String get phone => phoneNumber;
  String get verificationStatus => identityVerificationStatus;
  int get age {
    if (dateOfBirth == null) return 18;
    final now = DateTime.now();
    int calculated = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      calculated--;
    }
    return calculated >= 0 ? calculated : 18;
  }
  String get idType => 'Aadhaar Card';
  String get idNumber => '•••• •••• ••••';

  const UserModel({
    required this.uid,
    String? fullName,
    String? name,
    this.email = '',
    String? phoneNumber,
    String? phone,
    this.role = 'customer',
    this.accountStatus = 'active',
    this.profilePhotoUrl = '',
    this.dateOfBirth,
    int? age,
    String? idType,
    String? idNumber,
    this.ageEligibilityStatus = 'eligible_18_plus',
    String? identityVerificationStatus,
    String? verificationStatus,
    this.preferredLanguage = 'en',
    this.notificationPreferences = const {
      'bookingUpdates': true,
      'paymentUpdates': true,
      'extensionOffers': true,
      'whatsappConsent': true,
      'promotions': false,
    },
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : fullName = fullName ?? name ?? 'Guest User',
        phoneNumber = phoneNumber ?? phone ?? '',
        identityVerificationStatus = identityVerificationStatus ?? verificationStatus ?? 'not_started',
        createdAt = createdAt ?? const _DefaultDateTime(),
        updatedAt = updatedAt ?? createdAt ?? const _DefaultDateTime();

  /// Factory with flexible null-safety and legacy field mapping
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      fullName: map['fullName'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['phone'] ?? '',
      role: map['role'] ?? 'customer',
      accountStatus: map['accountStatus'] ?? 'active',
      profilePhotoUrl: map['profilePhotoUrl'] ?? map['photoUrl'] ?? '',
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.tryParse(map['dateOfBirth'].toString()) : null,
      ageEligibilityStatus: map['ageEligibilityStatus'] ?? 'eligible_18_plus',
      identityVerificationStatus: map['identityVerificationStatus'] ?? map['verificationStatus'] ?? 'not_started',
      preferredLanguage: map['preferredLanguage'] ?? 'en',
      notificationPreferences: Map<String, bool>.from(map['notificationPreferences'] ?? {
        'bookingUpdates': true,
        'paymentUpdates': true,
        'extensionOffers': true,
        'whatsappConsent': true,
        'promotions': false,
      }),
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  /// Serialization to map (Strictly never storing private keys or documents)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'name': fullName, // legacy compatibility
      'email': email,
      'phoneNumber': phoneNumber,
      'phone': phoneNumber, // legacy compatibility
      'role': role,
      'accountStatus': accountStatus,
      'profilePhotoUrl': profilePhotoUrl,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'ageEligibilityStatus': ageEligibilityStatus,
      'identityVerificationStatus': identityVerificationStatus,
      'verificationStatus': identityVerificationStatus, // legacy compatibility
      'preferredLanguage': preferredLanguage,
      'notificationPreferences': notificationPreferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Immutable state copier
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    String? accountStatus,
    String? profilePhotoUrl,
    DateTime? dateOfBirth,
    String? ageEligibilityStatus,
    String? identityVerificationStatus,
    String? preferredLanguage,
    Map<String, bool>? notificationPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      ageEligibilityStatus: ageEligibilityStatus ?? this.ageEligibilityStatus,
      identityVerificationStatus: identityVerificationStatus ?? this.identityVerificationStatus,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Domain Validations
  bool get isValidPhone => RegExp(r'^\+?[0-9]{10,13}$').hasMatch(phoneNumber.replaceAll(' ', ''));
  bool get isAdultEligible => ageEligibilityStatus == 'eligible_18_plus' && age >= 18;
  bool get isIdentityVerified => identityVerificationStatus == 'verified';
  bool get isOwnerRole => role == 'owner';
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
