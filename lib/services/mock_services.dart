import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';
import '../models/payment_model.dart';
import '../models/extension_offer_model.dart';
import 'contracts.dart';

/// Helper to simulate real network round-trip in UI without blocking the thread
Future<void> _simulateDelay() async {
  if (ServiceConfig.simulateLatency) {
    await Future.delayed(Duration(milliseconds: ServiceConfig.defaultLatencyMs));
  }
}

/// -------------------------------------------------------------
/// MockAuthService
/// -------------------------------------------------------------
class MockAuthService implements IAuthService {
  final ValueNotifier<UserModel?> _userNotifier = ValueNotifier<UserModel?>(
    const UserModel(
      uid: 'usr_mock_101',
      fullName: 'Rahul Verma',
      phoneNumber: '+91 9876543210',
      email: 'rahul.demo@roomwala.in',
      role: 'customer',
      accountStatus: 'active',
      profilePhotoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
      ageEligibilityStatus: 'eligible_18_plus',
      identityVerificationStatus: 'verified',
    ),
  );

  @override
  ValueListenable<UserModel?> get currentUserNotifier => _userNotifier;

  @override
  UserModel? get currentUser => _userNotifier.value;

  @override
  Future<ServiceResult<UserModel>> loginWithPhone({required String phone, required String otp}) async {
    await _simulateDelay();
    if (ServiceConfig.forceFailure) {
      return const ServiceResult.failure('Simulated network error. Please try again.');
    }
    if (otp == '1234' || otp == '0000') {
      final user = UserModel(
        uid: 'usr_${phone.replaceAll(RegExp(r'\D'), '')}',
        fullName: 'Rahul Verma',
        phoneNumber: phone,
        email: 'guest@roomwala.in',
        role: 'customer',
        accountStatus: 'active',
        ageEligibilityStatus: 'eligible_18_plus',
        identityVerificationStatus: 'verified',
      );
      _userNotifier.value = user;
      return ServiceResult.success(user);
    }
    return const ServiceResult.failure('Invalid OTP. In demo mode, use 1234 or 0000.');
  }

  @override
  Future<ServiceResult<UserModel>> loginWithEmail({required String email, required String password}) async {
    await _simulateDelay();
    if (password.length < 6) {
      return const ServiceResult.failure('Password must be at least 6 characters.');
    }
    final user = UserModel(
      uid: 'usr_email_${email.hashCode.abs()}',
      fullName: email.split('@').first,
      email: email,
      phoneNumber: '+91 9876543210',
      role: email.contains('owner') ? 'owner' : 'customer',
    );
    _userNotifier.value = user;
    return ServiceResult.success(user);
  }

  @override
  Future<ServiceResult<UserModel>> signup({
    required String fullName,
    required String phone,
    required String email,
    required String role,
  }) async {
    await _simulateDelay();
    final user = UserModel(
      uid: 'usr_new_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      phoneNumber: phone,
      email: email,
      role: role,
      identityVerificationStatus: 'not_started',
    );
    _userNotifier.value = user;
    return ServiceResult.success(user);
  }

  @override
  Future<ServiceResult<void>> logout() async {
    await _simulateDelay();
    _userNotifier.value = null;
    return const ServiceResult.success(null);
  }

  @override
  Future<ServiceResult<UserModel>> updateProfile(UserModel updatedUser) async {
    await _simulateDelay();
    _userNotifier.value = updatedUser;
    return ServiceResult.success(updatedUser);
  }
}

/// -------------------------------------------------------------
/// MockRoomService
/// -------------------------------------------------------------
class MockRoomService implements IRoomService {
  final List<RoomModel> _rooms = [
    const RoomModel(
      roomId: 'room_mock_1',
      ownerId: 'owner_101',
      title: 'Premium AC Suite near Gomti Nagar',
      description: 'Spacious private studio with attached bath, fast Wi-Fi and keyless digital door entry. No brokerage, direct verified owner stay.',
      roomType: 'Private Room',
      city: 'Lucknow',
      locality: 'Gomti Nagar',
      latitude: 26.8522,
      longitude: 80.9995,
      pricePerNight: 799,
      coverPhotoUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=900',
      photoUrls: [
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=900',
        'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
      ],
      amenities: ['Fast Wi-Fi', 'AC', 'Attached Washroom', 'Smart Lock', 'Power Backup'],
      houseRules: ['18+ Govt ID mandatory', 'No loud music after 10 PM', 'Couples allowed'],
      ownerVerificationStatus: 'verified',
      averageRating: 4.9,
      reviewCount: 48,
      digitalPin: 'PIN-8812',
    ),
    const RoomModel(
      roomId: 'room_mock_2',
      ownerId: 'owner_102',
      title: 'Hazratganj Heritage City Studio',
      description: 'Charming modern studio room in central Lucknow. Close to metro, cafes and historic shopping lanes.',
      roomType: 'Entire Apartment',
      city: 'Lucknow',
      locality: 'Hazratganj',
      latitude: 26.8467,
      longitude: 80.9462,
      pricePerNight: 1199,
      coverPhotoUrl: 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=900',
      photoUrls: [
        'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=900',
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=900',
      ],
      amenities: ['AC', 'Attached Washroom', 'Work Desk', 'Geyser', 'CCTV Outside'],
      houseRules: ['18+ Govt ID mandatory', 'Smoking inside room prohibited'],
      ownerVerificationStatus: 'verified',
      averageRating: 4.8,
      reviewCount: 32,
      digitalPin: 'PIN-3142',
    ),
    const RoomModel(
      roomId: 'room_mock_3',
      ownerId: 'owner_103',
      title: 'Indira Nagar Clean Budget Room',
      description: 'Budget-friendly, super clean air-conditioned bedroom with queen bed and verified host.',
      roomType: 'Private Room',
      city: 'Lucknow',
      locality: 'Indira Nagar',
      latitude: 26.8841,
      longitude: 80.9854,
      pricePerNight: 599,
      coverPhotoUrl: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=900',
      photoUrls: [
        'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=900',
      ],
      amenities: ['Fast Wi-Fi', 'Cooler/AC', 'Attached Washroom', 'RO Water'],
      houseRules: ['18+ Govt ID mandatory', 'Quiet hours 11 PM to 7 AM'],
      ownerVerificationStatus: 'verified',
      averageRating: 4.7,
      reviewCount: 19,
      digitalPin: 'PIN-9921',
    ),
  ];

  final Set<String> _favouriteIds = {'room_mock_1'};

  @override
  Future<ServiceResult<List<RoomModel>>> searchRooms({
    String? city,
    String? locality,
    int? minPrice,
    int? maxPrice,
    String? roomType,
    List<String>? amenities,
    DateTime? checkIn,
    DateTime? checkOut,
  }) async {
    await _simulateDelay();
    if (ServiceConfig.forceFailure) {
      return const ServiceResult.failure('Unable to load rooms from network. Retry?');
    }
    var list = _rooms.where((r) {
      if (city != null && city.isNotEmpty && city.toLowerCase() != 'all' && !r.city.toLowerCase().contains(city.toLowerCase())) {
        return false;
      }
      if (locality != null && locality.isNotEmpty && !r.locality.toLowerCase().contains(locality.toLowerCase())) {
        return false;
      }
      if (minPrice != null && r.pricePerNight < minPrice) return false;
      if (maxPrice != null && r.pricePerNight > maxPrice) return false;
      if (roomType != null && roomType.isNotEmpty && roomType.toLowerCase() != 'all' && r.roomType.toLowerCase() != roomType.toLowerCase()) {
        return false;
      }
      if (amenities != null && amenities.isNotEmpty) {
        for (var a in amenities) {
          if (!r.amenities.contains(a)) return false;
        }
      }
      return true;
    }).toList();

    return ServiceResult.success(list);
  }

  @override
  Future<ServiceResult<RoomModel>> getRoomById(String roomId) async {
    await _simulateDelay();
    try {
      final room = _rooms.firstWhere((r) => r.roomId == roomId);
      return ServiceResult.success(room);
    } catch (_) {
      return const ServiceResult.failure('Room not found or no longer available.');
    }
  }

  @override
  Future<ServiceResult<List<RoomModel>>> getFavourites() async {
    await _simulateDelay();
    final favs = _rooms.where((r) => _favouriteIds.contains(r.roomId)).toList();
    return ServiceResult.success(favs);
  }

  @override
  Future<ServiceResult<bool>> toggleFavourite(String roomId) async {
    await _simulateDelay();
    if (_favouriteIds.contains(roomId)) {
      _favouriteIds.remove(roomId);
      return const ServiceResult.success(false);
    } else {
      _favouriteIds.add(roomId);
      return const ServiceResult.success(true);
    }
  }
}

/// -------------------------------------------------------------
/// MockAvailabilityService
/// -------------------------------------------------------------
class MockAvailabilityService implements IAvailabilityService {
  @override
  Future<ServiceResult<bool>> checkDateAvailability({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    await _simulateDelay();
    if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
      return const ServiceResult.failure('Check-out date must be after check-in date.');
    }
    // Deterministic unavailable window: 15th to 17th of current month
    if ((checkIn.day >= 15 && checkIn.day <= 17) || (checkOut.day >= 15 && checkOut.day <= 17)) {
      return const ServiceResult.failure('Selected dates are already reserved by another guest.');
    }
    return const ServiceResult.success(true);
  }

  @override
  Future<ServiceResult<List<DateTime>>> getUnavailableDates(String roomId) async {
    await _simulateDelay();
    final now = DateTime.now();
    return ServiceResult.success([
      DateTime(now.year, now.month, 15),
      DateTime(now.year, now.month, 16),
      DateTime(now.year, now.month, 17),
    ]);
  }
}

/// -------------------------------------------------------------
/// MockBookingService
/// -------------------------------------------------------------
class MockBookingService implements IBookingService {
  final Map<String, BookingModel> _bookings = {};

  MockBookingService() {
    final now = DateTime.now();
    final initialBooking = BookingModel(
      bookingId: 'RW-MOCK-2026',
      roomId: 'room_mock_1',
      roomTitleSnapshot: 'Premium AC Suite near Gomti Nagar',
      checkIn: '${now.day} Nov 2026, 12:00 PM',
      checkOut: '${now.day + 2} Nov 2026, 11:00 AM',
      nightCount: 2,
      guestCount: 1,
      totalAmount: 1598,
      bookingStatus: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
      accessPin: 'PIN-8812',
      customerName: 'Rahul Verma',
      customerPhone: '+91 9876543210',
      priorityExtensionEligible: true,
      createdAt: now.subtract(const Duration(hours: 6)),
    );
    _bookings[initialBooking.bookingId] = initialBooking;
  }

  @override
  Future<ServiceResult<String>> createHold({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guestCount,
  }) async {
    await _simulateDelay();
    final holdId = 'HOLD_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    return ServiceResult.success(holdId);
  }

  @override
  Future<ServiceResult<BookingModel>> reviewBooking(String holdId) async {
    await _simulateDelay();
    final booking = BookingModel(
      bookingId: 'BK_$holdId',
      roomId: 'room_mock_1',
      roomTitleSnapshot: 'Premium AC Suite near Gomti Nagar',
      checkIn: '12 Nov 2026, 12:00 PM',
      checkOut: '14 Nov 2026, 11:00 AM',
      nightCount: 2,
      totalAmount: 1598,
      bookingStatus: BookingStatus.pendingPayment,
      createdAt: DateTime.now(),
    );
    return ServiceResult.success(booking);
  }

  @override
  Future<ServiceResult<BookingModel>> confirmBooking({
    required String holdId,
    required String paymentId,
  }) async {
    await _simulateDelay();
    final bookingId = 'RW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final confirmed = BookingModel(
      bookingId: bookingId,
      roomId: 'room_mock_1',
      roomTitleSnapshot: 'Premium AC Suite near Gomti Nagar',
      checkIn: 'Tomorrow, 12:00 PM',
      checkOut: 'In 2 Days, 11:00 AM',
      nightCount: 2,
      totalAmount: 1598,
      bookingStatus: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
      accessPin: 'PIN-${1000 + (DateTime.now().microsecond % 8999)}',
      createdAt: DateTime.now(),
    );
    _bookings[bookingId] = confirmed;
    return ServiceResult.success(confirmed);
  }

  @override
  Future<ServiceResult<BookingModel>> getBookingById(String bookingId) async {
    await _simulateDelay();
    final b = _bookings[bookingId];
    if (b != null) return ServiceResult.success(b);
    return const ServiceResult.failure('Booking reference not found.');
  }

  @override
  Future<ServiceResult<List<BookingModel>>> getCustomerBookings(String customerId) async {
    await _simulateDelay();
    return ServiceResult.success(_bookings.values.toList());
  }

  @override
  Future<ServiceResult<bool>> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    await _simulateDelay();
    final b = _bookings[bookingId];
    if (b != null) {
      _bookings[bookingId] = b.copyWith(
        bookingStatus: BookingStatus.cancelled,
        cancellationReason: reason,
      );
      return const ServiceResult.success(true);
    }
    return const ServiceResult.failure('Booking not found.');
  }
}

/// -------------------------------------------------------------
/// MockPaymentService
/// -------------------------------------------------------------
class MockPaymentService implements IPaymentService {
  @override
  Future<ServiceResult<PaymentModel>> initiatePayment({
    required String bookingId,
    required int amount,
    required String method,
  }) async {
    await _simulateDelay();
    if (ServiceConfig.forceFailure) {
      return const ServiceResult.failure('Payment authorization declined by test gateway.');
    }
    final payment = PaymentModel(
      paymentId: 'PAY_MOCK_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      bookingId: bookingId,
      provider: 'Mock UPI / Razorpay Test Sandbox',
      providerOrderId: 'order_test_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      providerPaymentId: 'pay_test_${DateTime.now().microsecond}',
      amount: amount,
      currency: 'INR',
      status: 'captured',
      paidAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    return ServiceResult.success(payment);
  }

  @override
  Future<ServiceResult<PaymentModel>> verifyPaymentStatus(String paymentId) async {
    await _simulateDelay();
    return ServiceResult.success(
      PaymentModel(
        paymentId: paymentId,
        bookingId: 'RW-MOCK-2026',
        provider: 'Mock Razorpay Sandbox',
        providerOrderId: 'order_test_verified',
        providerPaymentId: 'pay_test_verified',
        amount: 1598,
        currency: 'INR',
        status: 'captured',
        paidAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// -------------------------------------------------------------
/// MockVerificationService
/// -------------------------------------------------------------
class MockVerificationService implements IVerificationService {
  String _status = 'verified';

  @override
  Future<ServiceResult<String>> submitIdentityVerification({
    required String idType,
    required String maskedIdNumber,
    required DateTime dob,
  }) async {
    await _simulateDelay();
    _status = 'pending';
    return const ServiceResult.success('Verification submitted for secure automated audit.');
  }

  @override
  Future<ServiceResult<String>> getVerificationStatus(String userId) async {
    await _simulateDelay();
    return ServiceResult.success(_status);
  }
}

/// -------------------------------------------------------------
/// MockNotificationService
/// -------------------------------------------------------------
class MockNotificationService implements INotificationService {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'notif_1',
      'title': 'Stay Extension Priority',
      'body': 'Your stay at Premium AC Suite has 24h extension window open.',
      'type': 'extension',
      'read': false,
      'time': '10 mins ago',
    },
    {
      'id': 'notif_2',
      'title': 'Booking Confirmed (Demo)',
      'body': 'Digital door PIN generated for your check-in.',
      'type': 'booking',
      'read': true,
      'time': '2 hours ago',
    },
  ];

  @override
  Future<ServiceResult<List<Map<String, dynamic>>>> getNotifications(String userId) async {
    await _simulateDelay();
    return ServiceResult.success(List.from(_notifications));
  }

  @override
  Future<ServiceResult<void>> markAsRead(String notificationId) async {
    await _simulateDelay();
    for (var n in _notifications) {
      if (n['id'] == notificationId) n['read'] = true;
    }
    return const ServiceResult.success(null);
  }
}

/// -------------------------------------------------------------
/// MockExtensionService
/// -------------------------------------------------------------
class MockExtensionService implements IExtensionService {
  final List<ExtensionOfferModel> _offers = [];

  MockExtensionService() {
    final now = DateTime.now();
    _offers.add(
      ExtensionOfferModel(
        offerId: 'EXT-OFFER-101',
        bookingId: 'RW-MOCK-2026',
        roomId: 'room_mock_1',
        customerId: 'usr_mock_101',
        ownerId: 'owner_101',
        offeredAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 22)),
        requestedCheckIn: now.add(const Duration(days: 2)),
        requestedCheckOut: now.add(const Duration(days: 3)),
        quotedAmount: 799,
        status: ExtensionOfferStatus.offered,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now,
      ),
    );
  }

  @override
  Future<ServiceResult<List<ExtensionOfferModel>>> listOffers(String bookingId) async {
    await _simulateDelay();
    return ServiceResult.success(_offers.where((o) => o.bookingId == bookingId).toList());
  }

  @override
  Future<ServiceResult<ExtensionOfferModel>> acceptOffer(String offerId) async {
    await _simulateDelay();
    final idx = _offers.indexWhere((o) => o.offerId == offerId);
    if (idx != -1) {
      final updated = _offers[idx].copyWith(status: ExtensionOfferStatus.confirmed);
      _offers[idx] = updated;
      return ServiceResult.success(updated);
    }
    return const ServiceResult.failure('Offer expired or not found.');
  }

  @override
  Future<ServiceResult<void>> declineOffer(String offerId) async {
    await _simulateDelay();
    final idx = _offers.indexWhere((o) => o.offerId == offerId);
    if (idx != -1) {
      _offers[idx] = _offers[idx].copyWith(status: ExtensionOfferStatus.declined);
    }
    return const ServiceResult.success(null);
  }

  @override
  Future<ServiceResult<ExtensionOfferModel>> requestCustomExtension({
    required String bookingId,
    required DateTime newCheckOut,
  }) async {
    await _simulateDelay();
    final now = DateTime.now();
    final customOffer = ExtensionOfferModel(
      offerId: 'EXT-CUSTOM-${now.millisecondsSinceEpoch.toString().substring(7)}',
      bookingId: bookingId,
      roomId: 'room_mock_1',
      customerId: 'usr_mock_101',
      ownerId: 'owner_101',
      offeredAt: now,
      expiresAt: now.add(const Duration(hours: 12)),
      requestedCheckIn: now.add(const Duration(days: 2)),
      requestedCheckOut: newCheckOut,
      quotedAmount: 799.0 * newCheckOut.difference(now.add(const Duration(days: 2))).inDays.clamp(1, 14),
      status: ExtensionOfferStatus.offered,
      createdAt: now,
      updatedAt: now,
    );
    _offers.add(customOffer);
    return ServiceResult.success(customOffer);
  }
}

/// -------------------------------------------------------------
/// MockOwnerService
/// -------------------------------------------------------------
class MockOwnerService implements IOwnerService {
  final List<RoomModel> _ownerRooms = [];

  MockOwnerService() {
    _ownerRooms.add(
      const RoomModel(
        roomId: 'room_owner_1',
        ownerId: 'owner_101',
        title: 'Gomti Nagar Clean Private Suite',
        description: 'Verified My Roomy listing with direct zero-broker guest bookings.',
        city: 'Lucknow',
        locality: 'Gomti Nagar',
        latitude: 26.8522,
        longitude: 80.9995,
        pricePerNight: 799,
        amenities: ['Fast Wi-Fi', 'AC', 'Attached Washroom', 'Smart Lock'],
        houseRules: ['18+ Govt ID mandatory'],
        listingStatus: 'published',
        ownerVerificationStatus: 'verified',
        averageRating: 4.9,
        reviewCount: 38,
      ),
    );
  }

  @override
  Future<ServiceResult<List<RoomModel>>> getOwnerListings(String ownerId) async {
    await _simulateDelay();
    return ServiceResult.success(List.from(_ownerRooms));
  }

  @override
  Future<ServiceResult<RoomModel>> createListing(RoomModel room) async {
    await _simulateDelay();
    _ownerRooms.add(room);
    return ServiceResult.success(room);
  }

  @override
  Future<ServiceResult<RoomModel>> updateListing(RoomModel room) async {
    await _simulateDelay();
    final idx = _ownerRooms.indexWhere((r) => r.roomId == room.roomId);
    if (idx != -1) {
      _ownerRooms[idx] = room;
    }
    return ServiceResult.success(room);
  }

  @override
  Future<ServiceResult<void>> setAvailability({
    required String roomId,
    required List<DateTime> blockedDates,
  }) async {
    await _simulateDelay();
    return const ServiceResult.success(null);
  }

  @override
  Future<ServiceResult<Map<String, dynamic>>> getEarningsSummary(String ownerId) async {
    await _simulateDelay();
    return const ServiceResult.success({
      'totalEarnings': 42800,
      'monthEarnings': 15980,
      'pendingPayouts': 4794,
      'occupancyRate': 84.5,
      'totalBookings': 28,
      'payoutSchedule': 'Next automated direct NEFT payout on Monday',
    });
  }
}

/// -------------------------------------------------------------
/// MockSupportService
/// -------------------------------------------------------------
class MockSupportService implements ISupportService {
  final List<Map<String, dynamic>> _tickets = [];

  @override
  Future<ServiceResult<String>> submitTicket({
    required String category,
    required String subject,
    required String description,
    String? bookingId,
  }) async {
    await _simulateDelay();
    final ticketId = 'SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _tickets.add({
      'ticketId': ticketId,
      'category': category,
      'subject': subject,
      'description': description,
      'bookingId': bookingId,
      'status': 'open',
      'createdAt': DateTime.now().toIso8601String(),
    });
    return ServiceResult.success(ticketId);
  }

  @override
  Future<ServiceResult<List<Map<String, dynamic>>>> getTickets(String userId) async {
    await _simulateDelay();
    return ServiceResult.success(List.from(_tickets));
  }
}

/// -------------------------------------------------------------
/// Service Registry / Dependency Injection locator
/// -------------------------------------------------------------
class ServiceRegistry {
  static IAuthService auth = MockAuthService();
  static IRoomService room = MockRoomService();
  static IAvailabilityService availability = MockAvailabilityService();
  static IBookingService booking = MockBookingService();
  static IPaymentService payment = MockPaymentService();
  static IVerificationService verification = MockVerificationService();
  static INotificationService notification = MockNotificationService();
  static IExtensionService extension = MockExtensionService();
  static IOwnerService owner = MockOwnerService();
  static ISupportService support = MockSupportService();

  /// Easily switch from Mock to Production Backend Services without touching any screen UI
  static void configureServices({
    IAuthService? authService,
    IRoomService? roomService,
    IAvailabilityService? availabilityService,
    IBookingService? bookingService,
    IPaymentService? paymentService,
    IVerificationService? verificationService,
    INotificationService? notificationService,
    IExtensionService? extensionService,
    IOwnerService? ownerService,
    ISupportService? supportService,
  }) {
    if (authService != null) auth = authService;
    if (roomService != null) room = roomService;
    if (availabilityService != null) availability = availabilityService;
    if (bookingService != null) booking = bookingService;
    if (paymentService != null) payment = paymentService;
    if (verificationService != null) verification = verificationService;
    if (notificationService != null) notification = notificationService;
    if (extensionService != null) extension = extensionService;
    if (ownerService != null) owner = ownerService;
    if (supportService != null) support = supportService;
  }
}

