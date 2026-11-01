import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';
import '../models/payment_model.dart';
import '../models/extension_offer_model.dart';

/// -------------------------------------------------------------
/// Configuration & Mock Mode Switch
/// -------------------------------------------------------------
class ServiceConfig {
  static bool isMockMode = true;
  static bool simulateLatency = true;
  static int defaultLatencyMs = 300;
  static bool forceFailure = false;

  /// Guaranteed safety switches: Never simulate real transactions in mock mode
  static const bool isDemoBannerVisible = true;
  static const String demoDisclaimer =
      'DEMO / MOCK MODE ACTIVE: Zero real money is charged. WhatsApp messages and booking pins are simulated test fixtures.';
}

/// Base Service Response wrapper with loading, error, and recovery data
class ServiceResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;
  final String? errorCode;
  final bool isRecoverable;

  const ServiceResult.success(this.data)
      : isSuccess = true,
        errorMessage = null,
        errorCode = null,
        isRecoverable = false;

  const ServiceResult.failure(this.errorMessage, {this.errorCode, this.isRecoverable = true})
      : isSuccess = false,
        data = null;
}

/// -------------------------------------------------------------
/// 1. AuthService Interface & Mock Implementation
/// -------------------------------------------------------------
abstract class IAuthService {
  ValueListenable<UserModel?> get currentUserNotifier;
  UserModel? get currentUser;
  Future<ServiceResult<UserModel>> loginWithPhone({required String phone, required String otp});
  Future<ServiceResult<UserModel>> loginWithEmail({required String email, required String password});
  Future<ServiceResult<UserModel>> signup({required String fullName, required String phone, required String email, required String role});
  Future<ServiceResult<void>> logout();
  Future<ServiceResult<UserModel>> updateProfile(UserModel updatedUser);
}

/// -------------------------------------------------------------
/// 2. RoomService Interface & Mock Implementation
/// -------------------------------------------------------------
abstract class IRoomService {
  Future<ServiceResult<List<RoomModel>>> searchRooms({
    String? city,
    String? locality,
    int? minPrice,
    int? maxPrice,
    String? roomType,
    List<String>? amenities,
    DateTime? checkIn,
    DateTime? checkOut,
  });
  Future<ServiceResult<RoomModel>> getRoomById(String roomId);
  Future<ServiceResult<List<RoomModel>>> getFavourites();
  Future<ServiceResult<bool>> toggleFavourite(String roomId);
}

/// -------------------------------------------------------------
/// 3. AvailabilityService Interface & Mock Implementation
/// -------------------------------------------------------------
abstract class IAvailabilityService {
  Future<ServiceResult<bool>> checkDateAvailability({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  });
  Future<ServiceResult<List<DateTime>>> getUnavailableDates(String roomId);
}

/// -------------------------------------------------------------
/// 4. BookingService Interface & Mock Implementation
/// -------------------------------------------------------------
abstract class IBookingService {
  Future<ServiceResult<String>> createHold({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guestCount,
  });
  Future<ServiceResult<BookingModel>> reviewBooking(String holdId);
  Future<ServiceResult<BookingModel>> confirmBooking({
    required String holdId,
    required String paymentId,
  });
  Future<ServiceResult<BookingModel>> getBookingById(String bookingId);
  Future<ServiceResult<List<BookingModel>>> getCustomerBookings(String customerId);
  Future<ServiceResult<bool>> cancelBooking({
    required String bookingId,
    required String reason,
  });
}

/// -------------------------------------------------------------
/// 5. PaymentService Interface & Mock Implementation
/// -------------------------------------------------------------
abstract class IPaymentService {
  Future<ServiceResult<PaymentModel>> initiatePayment({
    required String bookingId,
    required int amount,
    required String method,
  });
  Future<ServiceResult<PaymentModel>> verifyPaymentStatus(String paymentId);
}

/// -------------------------------------------------------------
/// 6. VerificationService Interface & Mock Implementation
/// -------------------------------------------------------------
abstract class IVerificationService {
  Future<ServiceResult<String>> submitIdentityVerification({
    required String idType,
    required String maskedIdNumber,
    required DateTime dob,
  });
  Future<ServiceResult<String>> getVerificationStatus(String userId);
}

/// -------------------------------------------------------------
/// 7. NotificationService Interface & Mock Implementation
/// -------------------------------------------------------------
abstract class INotificationService {
  Future<ServiceResult<List<Map<String, dynamic>>>> getNotifications(String userId);
  Future<ServiceResult<void>> markAsRead(String notificationId);
}

/// -------------------------------------------------------------
/// 8. ExtensionService Interface & Mock Implementation
/// -------------------------------------------------------------
abstract class IExtensionService {
  Future<ServiceResult<List<ExtensionOfferModel>>> listOffers(String bookingId);
  Future<ServiceResult<ExtensionOfferModel>> acceptOffer(String offerId);
  Future<ServiceResult<void>> declineOffer(String offerId);
  Future<ServiceResult<ExtensionOfferModel>> requestCustomExtension({
    required String bookingId,
    required DateTime newCheckOut,
  });
}

/// -------------------------------------------------------------
/// 9. OwnerService Interface & Mock Implementation
/// -------------------------------------------------------------
abstract class IOwnerService {
  Future<ServiceResult<List<RoomModel>>> getOwnerListings(String ownerId);
  Future<ServiceResult<RoomModel>> createListing(RoomModel room);
  Future<ServiceResult<RoomModel>> updateListing(RoomModel room);
  Future<ServiceResult<void>> setAvailability({
    required String roomId,
    required List<DateTime> blockedDates,
  });
  Future<ServiceResult<Map<String, dynamic>>> getEarningsSummary(String ownerId);
}

/// -------------------------------------------------------------
/// 10. SupportService Interface & Mock Implementation
/// -------------------------------------------------------------
abstract class ISupportService {
  Future<ServiceResult<String>> submitTicket({
    required String category,
    required String subject,
    required String description,
    String? bookingId,
  });
  Future<ServiceResult<List<Map<String, dynamic>>>> getTickets(String userId);
}
