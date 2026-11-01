import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'models/room_model.dart';
import 'features/booking/booking_checkout_modal.dart';
import 'features/my_bookings/my_bookings_screen.dart';
import 'features/profile/profile_screen.dart';

import 'features/notifications/notifications_screen.dart';
import 'features/search/location_selection_screen.dart';
import 'features/search/search_results_screen.dart';
import 'features/owner/owner_dashboard_screen.dart';
import 'features/favourites/favourites_screen.dart';

import 'core/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init: $e');
  }
  runApp(const MyRoomyApp());
}

const Color navy = Color(0xFF171329);
const Color lime = Color(0xFFB8A1FF);
const Color surface = Color(0xFF27213D);
const Color surfaceLight = Color(0xFF322A4E);
const Color muted = Color(0xFFC4BDD6);

class MyRoomyApp extends StatelessWidget {
  const MyRoomyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Roomy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: lime,
          brightness: Brightness.dark,
        ),
      ),
      initialRoute: '/splash',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

class RoomData {
  final String name;
  final String location;
  final int price;
  final String rating;
  final String image;
  final String tag;
  final String description;

  const RoomData({
    required this.name,
    required this.location,
    required this.price,
    required this.rating,
    required this.image,
    required this.tag,
    required this.description,
  });

  String get formattedPrice =>
      '₹${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';
}

const List<RoomData> demoRooms = [
  RoomData(
    name: 'Cozy City Room',
    location: 'Gomti Nagar, Lucknow',
    price: 799,
    rating: '4.8',
    tag: 'Popular',
    image: 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
    description:
        'A welcoming room for a comfortable stay, with a relaxing '
        'interior and convenient city access.',
  ),
  RoomData(
    name: 'Modern Comfort Stay',
    location: 'Hazratganj, Lucknow',
    price: 999,
    rating: '4.9',
    tag: 'Top rated',
    image: 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=900',
    description:
        'A modern room with a calm atmosphere, ideal for a short '
        'city visit or a comfortable break.',
  ),
  RoomData(
    name: 'Minimal Studio Room',
    location: 'Indira Nagar, Lucknow',
    price: 599,
    rating: '4.7',
    tag: 'Budget pick',
    image: 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=900',
    description:
        'A simple, budget-friendly room for guests who value comfort '
        'and practical essentials.',
  ),
  RoomData(
    name: 'Premium Relax Room',
    location: 'Aliganj, Lucknow',
    price: 1299,
    rating: '4.9',
    tag: 'Premium',
    image: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=900',
    description:
        'Enjoy a stylish room with a spacious feel and a thoughtfully '
        'designed interior.',
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();

  int selectedCategory = 0;
  int selectedTab = 0;

  final List<String> categories = ['All rooms', 'Private', 'Budget', 'Premium'];

  final Set<String> savedRooms = {};

  List<RoomData> get filteredRooms {
    final query = searchController.text.trim().toLowerCase();

    return demoRooms.where((room) {
      final matchesLocation =
          room.location.toLowerCase().contains(query) ||
          room.name.toLowerCase().contains(query);

      final matchesCategory = switch (selectedCategory) {
        1 => room.price >= 700 && room.price < 1200,
        2 => room.price < 800,
        3 => room.price >= 1000,
        _ => true,
      };

      final matchesTab = selectedTab != 1 || savedRooms.contains(room.name);

      return matchesLocation && matchesCategory && matchesTab;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openRoom(RoomData room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomDetailsScreen(
          room: room,
          isSaved: savedRooms.contains(room.name),
          onSave: () => toggleSaved(room),
        ),
      ),
    );
  }

  void toggleSaved(RoomData room) {
    setState(() {
      if (savedRooms.contains(room.name)) {
        savedRooms.remove(room.name);
      } else {
        savedRooms.add(room.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (selectedTab) {
      case 1:
        currentBody = const SearchResultsScreen(destination: 'Lucknow');
        break;
      case 2:
        currentBody = FavouritesScreen(
          onExplore: () => setState(() => selectedTab = 0),
        );
        break;
      case 3:
        currentBody = const MyBookingsScreen();
        break;
      case 4:
        currentBody = const ProfileScreen();
        break;
      case 0:
      default:
        currentBody = CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _welcome()),
            SliverToBoxAdapter(child: _searchBox()),
            SliverToBoxAdapter(child: _categories()),
            SliverToBoxAdapter(child: _sectionHeading()),
            if (filteredRooms.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No rooms found',
                  message: 'Try a different location or category.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final room = filteredRooms[index];
                    return RoomCard(
                      room: room,
                      isSaved: savedRooms.contains(room.name),
                      onTap: () => openRoom(room),
                      onSave: () => toggleSaved(room),
                    );
                  }, childCount: filteredRooms.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 18,
                    mainAxisExtent: 270,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: _ownerBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 25)),
          ],
        );
        break;
    }

    return Scaffold(
      body: SafeArea(child: currentBody),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF171C29),
        indicatorColor: lime.withValues(alpha: 0.16),
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: lime),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: lime),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: lime),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_num_outlined),
            selectedIcon: Icon(Icons.confirmation_num, color: lime),
            label: 'My Bookings',
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

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: lime,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.home_rounded, color: navy, size: 27),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Roomy',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              Text(
                'YOUR STAY, YOUR WAY',
                style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: lime),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: surfaceLight,
              foregroundColor: lime,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
              );
            },
            icon: const Icon(Icons.add_home_work_outlined, size: 16),
            label: const Text(
              'Switch to Host',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcome() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E2638), Color(0xFF151926)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: lime.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: lime.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: lime.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 14, color: lime),
                      SizedBox(width: 4),
                      Text(
                        'ZERO BROKERAGE · DIRECT STAY',
                        style: TextStyle(
                          color: lime,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFFB8A1FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Find your dream stay.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Handpicked premium rooms, instant slot locking & automated WhatsApp dispatch.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final selectedLoc = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LocationSelectionScreen(),
                ),
              );
              if (selectedLoc != null) {
                searchController.text = selectedLoc;
                setState(() {});
              }
            },
            borderRadius: BorderRadius.circular(13),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: lime, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      searchController.text.isEmpty
                          ? 'Select city, locality or landmark...'
                          : searchController.text,
                      style: TextStyle(
                        color: searchController.text.isEmpty
                            ? muted
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: searchController.text.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: muted,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SearchResultsScreen(destination: searchController.text),
                  ),
                );
              },
              icon: const Icon(Icons.search_rounded),
              label: const Text(
                'Search Verified Rooms',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categories() {
    return SizedBox(
      height: 66,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final selected = selectedCategory == index;

          return ChoiceChip(
            label: Text(categories[index]),
            selected: selected,
            onSelected: (_) {
              setState(() => selectedCategory = index);
            },
            selectedColor: lime,
            backgroundColor: surface,
            labelStyle: TextStyle(
              color: selected ? navy : Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            side: BorderSide(color: selected ? lime : Colors.white12),
          );
        },
      ),
    );
  }

  Widget _sectionHeading() {
    final title = selectedTab == 1 ? 'Your saved rooms' : 'Rooms for you';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '${filteredRooms.length} stays',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _ownerBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lime,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Have a room to rent?',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'List your space on My Roomy.',
                  style: TextStyle(color: navy, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: navy, size: 28),
        ],
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final RoomData room;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const RoomCard({
    super.key,
    required this.room,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  room.image,
                  height: 132,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 132,
                    color: const Color(0xFF303849),
                    child: const Center(
                      child: Icon(Icons.bed, size: 38, color: lime),
                    ),
                  ),
                ),
                Positioned(
                  top: 9,
                  left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: lime,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      room.tag,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: navy.withValues(alpha: 0.85),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 17,
                      onPressed: onSave,
                      icon: Icon(
                        isSaved ? Icons.favorite : Icons.favorite_border,
                        color: isSaved ? lime : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: muted,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          room.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: lime, size: 14),
                      const SizedBox(width: 3),
                      Text(room.rating, style: const TextStyle(fontSize: 11)),
                      const Spacer(),
                      Text(
                        room.formattedPrice,
                        style: const TextStyle(
                          color: lime,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '/ night',
                      style: TextStyle(fontSize: 9, color: muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomDetailsScreen extends StatelessWidget {
  final RoomData room;
  final bool isSaved;
  final VoidCallback onSave;

  const RoomDetailsScreen({
    super.key,
    required this.room,
    required this.isSaved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: navy,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: onSave,
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved ? lime : Colors.white,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                room.image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Center(child: Icon(Icons.bed, size: 70, color: lime)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: lime,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      room.tag,
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    room.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: lime),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          room.location,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      const Icon(Icons.star, color: lime),
                      Text(
                        room.rating,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'About this room',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    room.description,
                    style: const TextStyle(
                      color: Colors.white60,
                      height: 1.6,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Room facilities',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FacilityChip(icon: Icons.wifi, label: 'Wi-Fi'),
                      FacilityChip(
                        icon: Icons.bed_outlined,
                        label: 'Comfortable bed',
                      ),
                      FacilityChip(
                        icon: Icons.shower_outlined,
                        label: 'Bathroom',
                      ),
                      FacilityChip(
                        icon: Icons.ac_unit,
                        label: 'Air conditioning',
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: lime),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            room.location,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(22, 15, 22, 22),
        decoration: const BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.formattedPrice,
                      style: const TextStyle(
                        color: lime,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'per night · demo price',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: lime,
                  foregroundColor: navy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 17,
                  ),
                ),
                onPressed: () {
                  final roomModel = RoomModel(
                    roomId: room.name.toLowerCase().replaceAll(' ', '_'),
                    ownerId: 'owner_default',
                    title: room.name,
                    city: 'Lucknow',
                    locality: room.location,
                    pricePerNight: room.price,
                    rating: double.tryParse(room.rating) ?? 4.8,
                    reviewsCount: 38,
                    imageUrl: room.image,
                    tag: room.tag,
                    description: room.description,
                    amenities: const [
                      'Wi-Fi',
                      'Air Conditioning',
                      'Attached Bath',
                      'Power Backup',
                    ],
                    houseRules: const [
                      '18+ Govt ID mandatory',
                      'No loud noise after 10 PM',
                    ],
                    latitude: 26.8467,
                    longitude: 80.9462,
                    ownerName: 'Verified Host',
                    ownerPhone: '+919876543210',
                  );

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BookingCheckoutModal(room: roomModel),
                  );
                },
                child: const Text(
                  'Book Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FacilityChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const FacilityChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: lime, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 55, color: lime),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: surface,
              child: Icon(Icons.person_outline, size: 42, color: lime),
            ),
            SizedBox(height: 18),
            Text(
              'Welcome to My Roomy',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your profile and sign-in options will be added next.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

