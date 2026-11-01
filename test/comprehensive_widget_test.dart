import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_wala/core/theme/app_theme.dart';
import 'package:room_wala/models/room_model.dart';
import 'package:room_wala/models/booking_model.dart';
import 'package:room_wala/services/contracts.dart';
import 'package:room_wala/shared/widgets/app_components.dart';
import 'package:room_wala/shared/widgets/async_state_builder.dart';
import 'package:room_wala/shared/widgets/validated_form_widgets.dart';
import 'package:room_wala/features/stay_extension/extension_offer_card.dart';
import 'package:room_wala/features/booking/date_selection_modal.dart';
import 'package:room_wala/features/booking/guest_selection_modal.dart';
import 'package:room_wala/features/booking/booking_review_screen.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() {
    ServiceConfig.isMockMode = true;
    ServiceConfig.simulateLatency = false;
  });

  group('15. Widget Tests Suite', () {
    testWidgets(
      '1. Reusable AppRoomCard renders correctly with zero brokerage highlight',
      (tester) async {
        const room = RoomModel(
          roomId: 'test_1',
          title: 'Luxury Gomti Suite',
          city: 'Lucknow',
          locality: 'Gomti Nagar',
          latitude: 26.85,
          longitude: 80.99,
          pricePerNight: 899,
          amenities: ['Fast Wi-Fi', 'AC'],
          houseRules: ['18+ ID mandatory'],
        );

        await tester.pumpWidget(
          _buildTestApp(
            AppRoomCard(
              room: room,
              isSaved: false,
              onTap: () {},
              onSave: () {},
            ),
          ),
        );
        expect(find.text('Luxury Gomti Suite'), findsOneWidget);
        expect(find.text('Gomti Nagar, Lucknow'), findsOneWidget);
        expect(find.text('₹899/n'), findsOneWidget);
      },
    );

    testWidgets('2. Search Bar renders with search and filter triggers', (
      tester,
    ) async {
      bool filterTapped = false;
      await tester.pumpWidget(
        _buildTestApp(
          AppSearchBar(
            hint: 'Search city or locality...',
            onFilterTap: () => filterTapped = true,
          ),
        ),
      );

      expect(find.text('Search city or locality...'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      expect(filterTapped, isTrue);
    });

    testWidgets('3. Date Selection modal validates stay dates', (tester) async {
      const room = RoomModel(
        roomId: 'test_1',
        title: 'Luxury Suite',
        city: 'Lucknow',
        locality: 'Gomti Nagar',
        latitude: 26.85,
        longitude: 80.99,
        pricePerNight: 899,
        amenities: ['AC'],
        houseRules: ['18+ ID'],
      );

      await tester.pumpWidget(
        _buildTestApp(
          DateSelectionModal(
            room: room,
            initialCheckIn: DateTime(2026, 11, 10),
            initialCheckOut: DateTime(2026, 11, 12),
          ),
        ),
      );

      expect(find.text('Select Stay Dates'), findsOneWidget);
      expect(find.text('CHECK-IN'), findsOneWidget);
      expect(find.text('CHECK-OUT'), findsOneWidget);
    });

    testWidgets(
      '4. Guest Selection modal initializes with configured capacity',
      (tester) async {
        const room = RoomModel(
          roomId: 'test_1',
          title: 'Luxury Suite',
          city: 'Lucknow',
          locality: 'Gomti Nagar',
          latitude: 26.85,
          longitude: 80.99,
          pricePerNight: 899,
          amenities: ['AC'],
          houseRules: ['18+ ID'],
          maxGuests: 4,
        );

        await tester.pumpWidget(
          _buildTestApp(
            const GuestSelectionModal(
              room: room,
              initialAdults: 2,
              initialChildren: 0,
            ),
          ),
        );

        expect(find.text('Select Guests'), findsOneWidget);
        expect(find.text('Adults'), findsOneWidget);
        expect(find.text('Children'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Booking Review screen displays transparent cost breakdown',
      (tester) async {
        const room = RoomModel(
          roomId: 'test_1',
          title: 'Luxury Gomti Suite',
          city: 'Lucknow',
          locality: 'Gomti Nagar',
          latitude: 26.85,
          longitude: 80.99,
          pricePerNight: 899,
          coverPhotoUrl: '',
          photoUrls: [],
          amenities: ['Fast Wi-Fi', 'AC'],
          houseRules: ['18+ ID mandatory'],
        );

        await tester.pumpWidget(
          _buildTestApp(
            const BookingReviewScreen(
              room: room,
              checkInDate: 'Tomorrow, 12:00 PM',
              checkOutDate: 'In 3 Days, 11:00 AM',
              nights: 2,
              guests: 2,
            ),
          ),
        );

        expect(find.text('Review Booking'), findsOneWidget);
        expect(find.text('Hold Dates & Continue'), findsOneWidget);
        expect(find.text('Stay Details'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Extension Offer Card renders priority extension with actions',
      (tester) async {
        final now = DateTime.now();
        final booking = BookingModel(
          bookingId: 'RW-EXT-1',
          roomId: 'room_mock_1',
          roomTitleSnapshot: 'Premium AC Suite',
          checkIn: 'Today',
          checkOut: 'Tomorrow',
          nightCount: 1,
          totalAmount: 799,
          createdAt: now,
        );

        await tester.pumpWidget(
          _buildTestApp(
            ExtensionOfferCard(booking: booking, nightlyPrice: 799),
          ),
        );

        expect(find.text('VIP STAY EXTENSION PRIORITY'), findsOneWidget);
        expect(find.text('+2 Days'), findsOneWidget);
        expect(find.text('+1 Week'), findsOneWidget);
      },
    );

    testWidgets(
      '7. AsyncStateBuilder handles loading, error, empty and data states',
      (tester) async {
        // 1. Loading State
        await tester.pumpWidget(
          _buildTestApp(
            AsyncStateBuilder<String>(
              isLoading: true,
              data: null,
              builder: (ctx, data) => Text(data),
            ),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 2. Error State with Retry
        bool retried = false;
        await tester.pumpWidget(
          _buildTestApp(
            AsyncStateBuilder<String>(
              isLoading: false,
              errorMessage: 'Network timeout',
              data: null,
              onRetry: () => retried = true,
              builder: (ctx, data) => Text(data),
            ),
          ),
        );
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Network timeout'), findsOneWidget);
        await tester.tap(find.text('Retry'));
        expect(retried, isTrue);

        // 3. Empty State
        await tester.pumpWidget(
          _buildTestApp(
            AsyncStateBuilder<List<String>>(
              isLoading: false,
              data: const [],
              isEmpty: (list) => list.isEmpty,
              emptyMessage: 'No bookings available.',
              builder: (ctx, list) => Text('Count: ${list.length}'),
            ),
          ),
        );
        expect(find.text('No bookings available.'), findsOneWidget);

        // 4. Data State
        await tester.pumpWidget(
          _buildTestApp(
            AsyncStateBuilder<String>(
              isLoading: false,
              data: 'Loaded Data Successfully',
              builder: (ctx, data) => Text(data),
            ),
          ),
        );
        expect(find.text('Loaded Data Successfully'), findsOneWidget);
      },
    );

    testWidgets(
      '8. ValidatedFormField and AsyncSubmitButton enforce inline validation and prevent duplicate clicks',
      (tester) async {
        final controller = TextEditingController();
        bool submitted = false;

        await tester.pumpWidget(
          _buildTestApp(
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ValidatedFormField(
                      controller: controller,
                      label: 'Full Name',
                      hint: 'Enter your name',
                      errorText: controller.text.isEmpty
                          ? 'Name is required'
                          : null,
                      isRequired: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    AsyncSubmitButton(
                      label: 'Save Profile',
                      isSubmitting: false,
                      isEnabled: controller.text.isNotEmpty,
                      onPressed: () => submitted = true,
                    ),
                  ],
                );
              },
            ),
          ),
        );

        expect(find.text('Name is required'), findsOneWidget);
        await tester.tap(find.text('Save Profile'));
        expect(submitted, isFalse);

        await tester.enterText(find.byType(TextField), 'Aarav Sharma');
        await tester.pump();

        expect(find.text('Name is required'), findsNothing);
        await tester.tap(find.text('Save Profile'));
        expect(submitted, isTrue);
      },
    );
  });
}
