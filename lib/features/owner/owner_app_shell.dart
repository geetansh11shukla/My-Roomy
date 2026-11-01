import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../owner/owner_dashboard_screen.dart';
import '../owner/owner_listings_screen.dart';
import '../owner/owner_availability_calendar_screen.dart';
import '../owner/owner_bookings_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../core/services/app_state.dart';
import '../../models/room_model.dart';

class OwnerAppShell extends StatefulWidget {
  final int initialTab;
  const OwnerAppShell({super.key, this.initialTab = 0});

  @override
  State<OwnerAppShell> createState() => _OwnerAppShellState();
}

class _OwnerAppShellState extends State<OwnerAppShell> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  static const RoomModel _defaultRoom = RoomModel(
    roomId: 'room_1',
    ownerId: 'host_current',
    title: 'Cozy City Room',
    description: 'Comfortable air-conditioned private room with attached washroom and high speed Wi-Fi.',
    city: 'Lucknow',
    locality: 'Gomti Nagar',
    pricePerNight: 799,
    rating: 4.8,
    reviewsCount: 34,
    imageUrl: 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
    photos: ['https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900'],
    tag: 'Popular',
    amenities: ['Fast Wi-Fi', 'AC', 'Attached Bathroom'],
    houseRules: ['18+ Govt ID mandatory'],
    latitude: 26.8522,
    longitude: 80.9995,
    ownerName: 'Shukla Stays',
    ownerPhone: '+919876543210',
    isVerified: true,
    digitalPin: 'PIN4821',
  );

  final List<Widget> _screens = const [
    OwnerDashboardScreen(),
    OwnerListingsScreen(),
    OwnerAvailabilityCalendarScreen(room: _defaultRoom),
    OwnerBookingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: lime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: lime.withValues(alpha: 0.3)),
              ),
              child: const Text('HOST MODE', style: TextStyle(color: lime, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
            const SizedBox(width: 10),
            const Text('My Roomy Owner', style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: lime),
            tooltip: 'Switch to Guest Mode',
            onPressed: () {
              AppState.instance.setRole(UserRole.customer);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: textWhite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF141A29),
        indicatorColor: lime.withValues(alpha: 0.18),
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: lime),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.hotel_outlined),
            selectedIcon: Icon(Icons.hotel, color: lime),
            label: 'My Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: lime),
            label: 'Availability',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_num_outlined),
            selectedIcon: Icon(Icons.confirmation_num, color: lime),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: lime),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
