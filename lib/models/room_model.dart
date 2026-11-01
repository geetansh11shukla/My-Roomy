/// Frontend Data Model for Rooms with Complete Listing Life-Cycle
class RoomModel {
  // Core Section 11 Specification Fields
  final String roomId;
  final String ownerId;
  final String title;
  final String description;
  final String roomType;
  final String country;
  final String state;
  final String city;
  final String locality;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> photoUrls;
  final String coverPhotoUrl;
  final List<String> amenities;
  final int maxGuests;
  final int bedCount;
  final int bathroomCount;
  final int pricePerNight;
  final String currency;
  final int cleaningFee;
  final int securityDeposit;
  final String checkInTime;
  final String checkOutTime;
  final List<String> houseRules;
  final String cancellationPolicyId;
  final String listingStatus; // 'draft' | 'pending' | 'published' | 'rejected' | 'suspended'
  final String ownerVerificationStatus; // 'unverified' | 'pending' | 'verified'
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional operational metadata for fast offline UX
  final String ownerName;
  final String ownerPhone;
  final bool instantBookingEnabled;
  final String digitalPin;
  final List<String> bookedDates; // YYYY-MM-DD strings

  // Backward-compatible aliases
  String get id => roomId;
  int get price => pricePerNight;
  double get rating => averageRating;
  int get reviewsCount => reviewCount;
  String get imageUrl => coverPhotoUrl.isNotEmpty ? coverPhotoUrl : (photoUrls.isNotEmpty ? photoUrls.first : '');
  List<String> get photos => photoUrls;
  List<String> get allPhotos => photoUrls.isNotEmpty ? photoUrls : (coverPhotoUrl.isNotEmpty ? [coverPhotoUrl] : []);
  String get tag => averageRating >= 4.8 ? 'Popular' : 'Verified Host';
  double get lat => latitude;
  double get lng => longitude;
  bool get isVerified => ownerVerificationStatus == 'verified';

  const RoomModel({
    required this.roomId,
    this.ownerId = 'host_default',
    required this.title,
    this.description = '',
    this.roomType = 'Private Room',
    this.country = 'India',
    this.state = 'Uttar Pradesh',
    required this.city,
    required this.locality,
    this.address = '',
    required this.latitude,
    required this.longitude,
    List<String>? photoUrls,
    List<String>? photos,
    String? coverPhotoUrl,
    String? imageUrl,
    String? tag,
    required this.amenities,
    this.maxGuests = 2,
    this.bedCount = 1,
    this.bathroomCount = 1,
    int? pricePerNight,
    int? price,
    this.currency = 'INR',
    this.cleaningFee = 0,
    this.securityDeposit = 0,
    this.checkInTime = '12:00 PM',
    this.checkOutTime = '11:00 AM',
    this.houseRules = const ['18+ Govt ID mandatory', 'No loud noise after 10 PM'],
    this.cancellationPolicyId = 'flexible_24h',
    this.listingStatus = 'published',
    String? ownerVerificationStatus,
    bool? isVerified,
    double? averageRating,
    double? rating,
    int? reviewCount,
    int? reviewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.ownerName = 'Verified Host',
    this.ownerPhone = '+91 9876543210',
    this.instantBookingEnabled = true,
    this.digitalPin = 'PIN1234',
    this.bookedDates = const [],
  })  : photoUrls = photoUrls ?? photos ?? const [],
        coverPhotoUrl = coverPhotoUrl ?? imageUrl ?? '',
        pricePerNight = pricePerNight ?? price ?? 799,
        ownerVerificationStatus = ownerVerificationStatus ?? (isVerified == true ? 'verified' : 'unverified'),
        averageRating = averageRating ?? rating ?? 4.8,
        reviewCount = reviewCount ?? reviewsCount ?? 34,
        createdAt = createdAt ?? const _DefaultDateTime(),
        updatedAt = updatedAt ?? const _DefaultDateTime();

  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    final photoList = List<String>.from(map['photoUrls'] ?? map['photos'] ?? []);
    final cover = map['coverPhotoUrl'] ?? map['imageUrl'] ?? (photoList.isNotEmpty ? photoList.first : '');

    return RoomModel(
      roomId: id,
      ownerId: map['ownerId'] ?? 'host_default',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      roomType: map['roomType'] ?? 'Private Room',
      country: map['country'] ?? 'India',
      state: map['state'] ?? 'Uttar Pradesh',
      city: map['city'] ?? 'Lucknow',
      locality: map['locality'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? map['lat'] as num?)?.toDouble() ?? 26.8467,
      longitude: (map['longitude'] ?? map['lng'] as num?)?.toDouble() ?? 80.9462,
      photoUrls: photoList,
      coverPhotoUrl: cover,
      amenities: List<String>.from(map['amenities'] ?? []),
      maxGuests: (map['maxGuests'] as num?)?.toInt() ?? 2,
      bedCount: (map['bedCount'] as num?)?.toInt() ?? 1,
      bathroomCount: (map['bathroomCount'] as num?)?.toInt() ?? 1,
      pricePerNight: (map['pricePerNight'] ?? map['price'] as num?)?.toInt() ?? 799,
      currency: map['currency'] ?? 'INR',
      cleaningFee: (map['cleaningFee'] as num?)?.toInt() ?? 0,
      securityDeposit: (map['securityDeposit'] as num?)?.toInt() ?? 0,
      checkInTime: map['checkInTime'] ?? '12:00 PM',
      checkOutTime: map['checkOutTime'] ?? '11:00 AM',
      houseRules: List<String>.from(map['houseRules'] ?? []),
      cancellationPolicyId: map['cancellationPolicyId'] ?? 'flexible_24h',
      listingStatus: map['listingStatus'] ?? 'published',
      ownerVerificationStatus: map['ownerVerificationStatus'] ?? (map['isVerified'] == true ? 'verified' : 'unverified'),
      averageRating: (map['averageRating'] ?? map['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (map['reviewCount'] ?? map['reviewsCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null,
      ownerName: map['ownerName'] ?? 'Verified Host',
      ownerPhone: map['ownerPhone'] ?? '+91 9876543210',
      instantBookingEnabled: map['instantBookingEnabled'] ?? true,
      digitalPin: map['digitalPin'] ?? 'PIN1234',
      bookedDates: List<String>.from(map['bookedDates'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'roomType': roomType,
      'country': country,
      'state': state,
      'city': city,
      'locality': locality,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrls': photoUrls,
      'coverPhotoUrl': coverPhotoUrl,
      'imageUrl': imageUrl, // backward compatibility
      'amenities': amenities,
      'maxGuests': maxGuests,
      'bedCount': bedCount,
      'bathroomCount': bathroomCount,
      'pricePerNight': pricePerNight,
      'price': pricePerNight, // backward compatibility
      'currency': currency,
      'cleaningFee': cleaningFee,
      'securityDeposit': securityDeposit,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'houseRules': houseRules,
      'cancellationPolicyId': cancellationPolicyId,
      'listingStatus': listingStatus,
      'ownerVerificationStatus': ownerVerificationStatus,
      'isVerified': isVerified, // backward compatibility
      'averageRating': averageRating,
      'rating': averageRating, // backward compatibility
      'reviewCount': reviewCount,
      'reviewsCount': reviewCount, // backward compatibility
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'instantBookingEnabled': instantBookingEnabled,
      'digitalPin': digitalPin,
      'bookedDates': bookedDates,
    };
  }

  RoomModel copyWith({
    String? roomId,
    String? ownerId,
    String? title,
    String? description,
    String? roomType,
    String? country,
    String? state,
    String? city,
    String? locality,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? photoUrls,
    String? coverPhotoUrl,
    List<String>? amenities,
    int? maxGuests,
    int? bedCount,
    int? bathroomCount,
    int? pricePerNight,
    String? currency,
    int? cleaningFee,
    int? securityDeposit,
    String? checkInTime,
    String? checkOutTime,
    List<String>? houseRules,
    String? cancellationPolicyId,
    String? listingStatus,
    String? ownerVerificationStatus,
    double? averageRating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerName,
    String? ownerPhone,
    bool? instantBookingEnabled,
    String? digitalPin,
    List<String>? bookedDates,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      roomType: roomType ?? this.roomType,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrls: photoUrls ?? this.photoUrls,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      amenities: amenities ?? this.amenities,
      maxGuests: maxGuests ?? this.maxGuests,
      bedCount: bedCount ?? this.bedCount,
      bathroomCount: bathroomCount ?? this.bathroomCount,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      currency: currency ?? this.currency,
      cleaningFee: cleaningFee ?? this.cleaningFee,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      houseRules: houseRules ?? this.houseRules,
      cancellationPolicyId: cancellationPolicyId ?? this.cancellationPolicyId,
      listingStatus: listingStatus ?? this.listingStatus,
      ownerVerificationStatus: ownerVerificationStatus ?? this.ownerVerificationStatus,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      instantBookingEnabled: instantBookingEnabled ?? this.instantBookingEnabled,
      digitalPin: digitalPin ?? this.digitalPin,
      bookedDates: bookedDates ?? this.bookedDates,
    );
  }

  bool isDateAvailable(DateTime date) {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return !bookedDates.contains(dateStr);
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
