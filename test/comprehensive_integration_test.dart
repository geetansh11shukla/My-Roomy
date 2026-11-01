import 'package:flutter_test/flutter_test.dart';
import 'package:room_wala/models/room_model.dart';
import 'package:room_wala/services/contracts.dart';
import 'package:room_wala/services/mock_services.dart';

void main() {
  setUp(() {
    ServiceConfig.isMockMode = true;
    ServiceConfig.simulateLatency = false;
  });

  group('15. Integration Tests: End-to-End Service Flow', () {
    test('1. Auth to Session: login with phone & OTP session lifecycle', () async {
      final auth = MockAuthService();
      expect(auth.currentUser, isNotNull);

      // Successful OTP
      final loginRes = await auth.loginWithPhone(phone: '+91 9876543210', otp: '1234');
      expect(loginRes.isSuccess, isTrue);
      expect(loginRes.data!.phoneNumber, '+91 9876543210');

      // Invalid OTP
      final badRes = await auth.loginWithPhone(phone: '+91 9876543210', otp: '9999');
      expect(badRes.isSuccess, isFalse);
      expect(badRes.errorMessage, contains('Invalid OTP'));

      // Logout
      final logoutRes = await auth.logout();
      expect(logoutRes.isSuccess, isTrue);
      expect(auth.currentUser, isNull);
    });

    test('2. Room Search to Filters & Availability check', () async {
      final roomService = MockRoomService();
      final availService = MockAvailabilityService();

      // Search Gomti Nagar
      final searchRes = await roomService.searchRooms(city: 'Lucknow', locality: 'Gomti Nagar');
      expect(searchRes.isSuccess, isTrue);
      expect(searchRes.data!.length, greaterThanOrEqualTo(1));
      expect(searchRes.data!.first.locality, 'Gomti Nagar');

      // Filter by max price 600
      final budgetRes = await roomService.searchRooms(maxPrice: 600);
      expect(budgetRes.isSuccess, isTrue);
      expect(budgetRes.data!.every((r) => r.pricePerNight <= 600), isTrue);

      // Check Available dates
      final checkIn = DateTime(2026, 11, 20);
      final checkOut = DateTime(2026, 11, 22);
      final avail = await availService.checkDateAvailability(
        roomId: searchRes.data!.first.roomId,
        checkIn: checkIn,
        checkOut: checkOut,
      );
      expect(avail.isSuccess, isTrue);
      expect(avail.data, isTrue);

      // Check conflict dates (15th reserved in mock)
      final conflict = await availService.checkDateAvailability(
        roomId: searchRes.data!.first.roomId,
        checkIn: DateTime(DateTime.now().year, DateTime.now().month, 15),
        checkOut: DateTime(DateTime.now().year, DateTime.now().month, 17),
      );
      expect(conflict.isSuccess, isFalse);
    });

    test('3. Hold creation -> Payment simulation -> Confirmation with Keyless Door PIN', () async {
      final bookingService = MockBookingService();
      final paymentService = MockPaymentService();

      // 1. Hold
      final holdRes = await bookingService.createHold(
        roomId: 'room_mock_1',
        checkIn: DateTime.now().add(const Duration(days: 1)),
        checkOut: DateTime.now().add(const Duration(days: 3)),
        guestCount: 2,
      );
      expect(holdRes.isSuccess, isTrue);
      final holdId = holdRes.data!;

      // 2. Review
      final reviewRes = await bookingService.reviewBooking(holdId);
      expect(reviewRes.isSuccess, isTrue);
      expect(reviewRes.data!.totalAmount, 1598);

      // 3. Payment
      final payRes = await paymentService.initiatePayment(
        bookingId: reviewRes.data!.bookingId,
        amount: 1598,
        method: 'UPI',
      );
      expect(payRes.isSuccess, isTrue);
      expect(payRes.data!.status, 'captured');

      // 4. Confirm booking
      final confirmRes = await bookingService.confirmBooking(
        holdId: holdId,
        paymentId: payRes.data!.paymentId,
      );
      expect(confirmRes.isSuccess, isTrue);
      expect(confirmRes.data!.accessPin, startsWith('PIN-'));
      expect(confirmRes.data!.bookingStatus.name, 'confirmed');
    });

    test('4. Stay Extension flow: list offer -> accept extension -> update status', () async {
      final extService = MockExtensionService();

      final offers = await extService.listOffers('RW-MOCK-2026');
      expect(offers.isSuccess, isTrue);
      expect(offers.data!.isNotEmpty, isTrue);

      final targetOffer = offers.data!.first;
      expect(targetOffer.canAccept, isTrue);

      final accepted = await extService.acceptOffer(targetOffer.offerId);
      expect(accepted.isSuccess, isTrue);
      expect(accepted.data!.status.name, 'confirmed');
    });

    test('5. Owner flow: create listing, manage availability and view transparent earnings', () async {
      final ownerService = MockOwnerService();

      // Get listings
      final listings = await ownerService.getOwnerListings('owner_101');
      expect(listings.isSuccess, isTrue);

      // Create new room
      const newRoom = RoomModel(
        roomId: 'room_owner_new',
        ownerId: 'owner_101',
        title: 'Hazratganj Luxury Studio',
        city: 'Lucknow',
        locality: 'Hazratganj',
        latitude: 26.84,
        longitude: 80.94,
        pricePerNight: 999,
        amenities: ['AC', 'Wi-Fi'],
        houseRules: ['18+ ID mandatory'],
      );

      final created = await ownerService.createListing(newRoom);
      expect(created.isSuccess, isTrue);
      expect(created.data!.title, 'Hazratganj Luxury Studio');

      // Earnings
      final earnings = await ownerService.getEarningsSummary('owner_101');
      expect(earnings.isSuccess, isTrue);
      expect(earnings.data!['totalEarnings'], 42800);
      expect(earnings.data!['occupancyRate'], 84.5);
    });

    test('6. Support & Feedback: submit ticket and retrieve ticket history', () async {
      final supportService = MockSupportService();

      final ticketRes = await supportService.submitTicket(
        category: 'Identity Verification',
        subject: 'Aadhaar verification help',
        description: 'Need help updating verified phone number.',
      );

      expect(ticketRes.isSuccess, isTrue);
      expect(ticketRes.data!, startsWith('SUP-'));

      final tickets = await supportService.getTickets('usr_mock_101');
      expect(tickets.isSuccess, isTrue);
      expect(tickets.data!.any((t) => t['ticketId'] == ticketRes.data), isTrue);
    });
  });
}
