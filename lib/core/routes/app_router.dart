import 'package:flutter/material.dart';

import '../../core/services/app_state.dart';

// Import All Screens for Routing
import '../../main.dart'
    hide navy, lime, surface, surfaceLight, muted, RoomDetailsScreen;
import '../../models/room_model.dart';
import '../../models/booking_model.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/auth/email_login_screen.dart';
import '../../features/profile/complete_profile_screen.dart';

import '../../features/search/location_selection_screen.dart';
import '../../features/search/search_results_screen.dart';
import '../../features/search/filter_bottom_sheet.dart';
import '../../features/room_details/room_details_screen.dart';
import '../../features/reviews/all_reviews_screen.dart';
import '../../features/favourites/favourites_screen.dart';

import '../../features/booking/date_selection_modal.dart';
import '../../features/booking/guest_selection_modal.dart';
import '../../features/identity_verification/verification_gate_screen.dart';
import '../../features/booking/booking_review_screen.dart';
import '../../features/booking/temporary_hold_screen.dart';
import '../../features/payments/payment_screen.dart';
import '../../features/booking/booking_confirmation_screen.dart';
import '../../features/booking/booking_details_screen.dart';
import '../../features/booking/booking_ticket_screen.dart';
import '../../features/booking/cancellation_screen.dart';
import '../../features/stay_extension/extension_checkout_screen.dart';

import '../../features/my_bookings/my_bookings_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/identity_status_screen.dart';
import '../../features/profile/settings_screen.dart';

import '../../features/owner/owner_onboarding_screen.dart';
import '../../features/owner/owner_app_shell.dart';
import '../../features/owner/add_room_wizard_screen.dart';
import '../../features/owner/owner_earnings_screen.dart';
import '../../features/owner/owner_reviews_screen.dart';

import '../../features/profile/help_support_screen.dart';
import '../../features/profile/legal_policy_screen.dart';
import '../../features/error/error_recovery_screen.dart';

class AppRouter {
  // Common fallback mock room
  static const RoomModel _mockRoom = RoomModel(
    roomId: 'room_1',
    ownerId: 'owner_1',
    title: 'Cozy City Room',
    description:
        'Comfortable air-conditioned private room with attached washroom.',
    city: 'Lucknow',
    locality: 'Gomti Nagar',
    pricePerNight: 799,
    rating: 4.8,
    reviewsCount: 34,
    imageUrl:
        'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
    photos: [
      'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
    ],
    tag: 'Popular',
    amenities: ['Fast Wi-Fi', 'AC', 'Attached Washroom', 'Smart Lock'],
    houseRules: ['18+ Govt ID mandatory', 'No loud noise after 10 PM'],
    latitude: 26.8522,
    longitude: 80.9995,
    ownerName: 'Shukla Stays',
    ownerPhone: '+919876543210',
    isVerified: true,
    digitalPin: 'PIN4821',
  );

  static final BookingModel _mockBooking = BookingModel(
    bookingId: 'RW-2026-8812',
    roomId: 'room_1',
    roomTitle: 'Cozy City Room',
    locality: 'Gomti Nagar',
    city: 'Lucknow',
    customerId: 'cust_rahul',
    customerName: 'Rahul Kumar',
    customerPhone: '+91 9876543210',
    customerAge: 24,
    idProofType: 'Aadhaar Card',
    idNumber: '8834 9102 3341',
    idVerified: true,
    checkIn: 'Tomorrow, 12:00 PM',
    checkOut: 'In 3 Days, 11:00 AM',
    nights: 2,
    totalAmount: 1598,
    status: BookingStatus.confirmed,
    accessPin: 'PIN4821',
    locationUrl: 'https://maps.google.com/?q=26.8522,80.9995',
    priorityExtensionEligible: true,
    createdAt: DateTime.now(),
  );

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;

    // Route Protection Checks
    final appState = AppState.instance;

    // Protected Owner Routes
    if (path.startsWith('/owner')) {
      if (!appState.isAuthenticated) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      }
      if (path == '/owner/onboarding') {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OwnerOnboardingScreen(),
        );
      }
      // If user is not yet marked as owner role, allow viewing dashboard shell or switch role
      appState.setRole(UserRole.owner);
    }

    // Dynamic Route Matchers
    // /room/:roomId
    if (path.startsWith('/room/')) {
      final segments = uri.pathSegments; // ['room', 'roomId', ...]
      if (segments.length >= 2) {
        if (segments.length == 3 && segments[2] == 'reviews') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const AllReviewsScreen(
              roomTitle: 'Cozy City Room',
              averageRating: 4.8,
              totalReviews: 34,
            ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RoomDetailsScreen(room: _mockRoom),
        );
      }
    }

    // /booking/hold/:holdId
    if (path.startsWith('/booking/hold/')) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => TemporaryHoldScreen(
          room: _mockRoom,
          checkInDate: 'Tomorrow, 12:00 PM',
          checkOutDate: 'In 3 Days, 11:00 AM',
          nights: 2,
          guests: 2,
          totalAmount: 1598,
          customerName: 'Rahul Kumar',
          customerPhone: '9876543210',
          customerAge: 24,
          idType: 'Aadhaar Card',
          idNumber: '8834 9102 3341',
        ),
      );
    }

    // /booking/payment/:bookingId
    if (path.startsWith('/booking/payment/')) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => PaymentScreen(
          room: _mockRoom,
          checkInDate: 'Tomorrow, 12:00 PM',
          checkOutDate: 'In 3 Days, 11:00 AM',
          totalAmount: 1598,
          nights: 2,
          guests: 2,
          customerName: 'Rahul Kumar',
          customerPhone: '9876543210',
          customerAge: 24,
          idType: 'Aadhaar Card',
          idNumber: '8834 9102 3341',
        ),
      );
    }

    // /booking/result/:bookingId
    if (path.startsWith('/booking/result/')) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) =>
            BookingConfirmationScreen(booking: _mockBooking, room: _mockRoom),
      );
    }

    // /bookings/:bookingId/*
    if (path.startsWith('/bookings/')) {
      final segments = uri.pathSegments;
      if (segments.length == 3) {
        final subAction = segments[2];
        if (subAction == 'ticket') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) =>
                BookingTicketScreen(booking: _mockBooking, room: _mockRoom),
          );
        }
        if (subAction == 'cancel') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => CancellationScreen(booking: _mockBooking),
          );
        }
        if (subAction == 'extension') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ExtensionCheckoutScreen(
              booking: _mockBooking,
              additionalDays: 1,
              additionalAmount: 799,
              proposedCheckOut: 'In 4 Days, 11:00 AM',
            ),
          );
        }
      }
      if (segments.length == 2 && segments[1] != 'ticket') {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BookingDetailsScreen(booking: _mockBooking),
        );
      }
    }

    // /owner/rooms/:roomId/*
    if (path.startsWith('/owner/rooms/')) {
      final segments = uri.pathSegments;
      if (segments.length == 4 &&
          (segments[3] == 'edit' || segments[3] == 'preview')) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AddRoomWizardScreen(),
        );
      }
    }

    // Exact Match Route Table
    switch (path) {
      case '/':
      case '/splash':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );

      case '/onboarding':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingScreen(),
        );

      case '/welcome':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const WelcomeScreen(),
        );

      case '/login':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case '/signup':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SignUpScreen(),
        );

      case '/otp':
      case '/forgot-password':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const EmailLoginScreen(),
        );

      case '/complete-profile':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CompleteProfileScreen(),
        );

      case '/home':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );

      case '/location':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LocationSelectionScreen(),
        );

      case '/search':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SearchResultsScreen(destination: 'Lucknow'),
        );

      case '/search/filters':
        return MaterialPageRoute(
          settings: settings,
          builder: (ctx) => Scaffold(
            backgroundColor: const Color(0xFF10141F),
            body: FilterBottomSheet(initialCriteria: FilterCriteria()),
          ),
        );

      case '/search/map':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SearchResultsScreen(destination: 'Lucknow'),
        );

      case '/favourites':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const FavouritesScreen(),
        );

      case '/booking/dates':
        return MaterialPageRoute(
          settings: settings,
          builder: (ctx) => Scaffold(
            backgroundColor: const Color(0xFF10141F),
            body: DateSelectionModal(
              room: _mockRoom,
              initialCheckIn: DateTime.now().add(const Duration(days: 1)),
              initialCheckOut: DateTime.now().add(const Duration(days: 3)),
            ),
          ),
        );

      case '/booking/guests':
        return MaterialPageRoute(
          settings: settings,
          builder: (ctx) => Scaffold(
            backgroundColor: const Color(0xFF10141F),
            body: GuestSelectionModal(room: _mockRoom),
          ),
        );

      case '/booking/eligibility':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VerificationGateScreen(),
        );

      case '/booking/review':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const BookingReviewScreen(
            room: _mockRoom,
            checkInDate: 'Tomorrow, 12:00 PM',
            checkOutDate: 'In 3 Days, 11:00 AM',
            nights: 2,
            guests: 2,
          ),
        );

      case '/bookings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MyBookingsScreen(),
        );

      case '/notifications':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const NotificationsScreen(),
        );

      case '/profile':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            backgroundColor: Color(0xFF10141F),
            body: SafeArea(child: ProfileScreen()),
          ),
        );

      case '/profile/edit':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const EditProfileScreen(),
        );

      case '/profile/verification':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const IdentityStatusScreen(),
        );

      case '/profile/settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );

      // Owner Routes
      case '/owner/dashboard':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OwnerAppShell(initialTab: 0),
        );

      case '/owner/rooms':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OwnerAppShell(initialTab: 1),
        );

      case '/owner/rooms/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AddRoomWizardScreen(),
        );

      case '/owner/availability':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OwnerAppShell(initialTab: 2),
        );

      case '/owner/bookings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OwnerAppShell(initialTab: 3),
        );

      case '/owner/earnings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OwnerEarningsScreen(),
        );

      case '/owner/payouts':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OwnerEarningsScreen(),
        );

      case '/owner/reviews':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OwnerReviewsScreen(),
        );

      // Support & Legal
      case '/support':
      case '/support/new':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HelpSupportScreen(),
        );

      case '/legal/terms':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LegalPolicyScreen(
            title: 'Terms & Conditions',
            contentKey: 'terms',
          ),
        );

      case '/legal/privacy':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LegalPolicyScreen(
            title: 'Privacy Policy',
            contentKey: 'privacy',
          ),
        );

      case '/legal/cancellation':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LegalPolicyScreen(
            title: 'Cancellation & Refund',
            contentKey: 'cancellation',
          ),
        );

      default:
        // Deep link or unexpected route recovery
        return MaterialPageRoute(
          settings: settings,
          builder: (ctx) => ErrorRecoveryScreen(
            errorType: ErrorRecoveryType.genericUnexpected,
            customMessage:
                'The requested route "${settings.name}" could not be found.',
            onPrimaryAction: () => Navigator.pushReplacementNamed(ctx, '/home'),
          ),
        );
    }
  }
}
