import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';
import '../room_details/room_details_screen.dart';
import '../booking/booking_checkout_modal.dart';

class FavouritesScreen extends StatefulWidget {
  final VoidCallback? onExplore;
  const FavouritesScreen({super.key, this.onExplore});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  // Pre-populated saved rooms for demo
  final List<RoomModel> _savedRooms = [
    const RoomModel(
      roomId: 'room_1',
      ownerId: 'owner_1',
      title: 'Cozy City Room',
      description: 'Comfortable air-conditioned private room with attached washroom and high speed Wi-Fi.',
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
    ),
    const RoomModel(
      roomId: 'room_2',
      ownerId: 'owner_2',
      title: 'Modern Comfort Stay',
      description: 'Newly renovated studio room close to metro station and city shopping centers.',
      city: 'Lucknow',
      locality: 'Hazratganj',
      pricePerNight: 999,
      rating: 4.9,
      reviewsCount: 48,
      imageUrl:
          'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=900',
      photos: [
        'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=900',
      ],
      tag: 'Verified Host',
      amenities: ['Wi-Fi', 'AC', 'Geyser', 'Keyless PIN Access'],
      houseRules: ['18+ mandatory', 'Couples allowed'],
      latitude: 26.8467,
      longitude: 80.9462,
      ownerName: 'Awasthi Properties',
      ownerPhone: '+919876543211',
      isVerified: true,
      digitalPin: 'PIN9102',
    ),
  ];

  void _removeRoom(String id) {
    setState(() {
      _savedRooms.removeWhere((r) => r.roomId == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room removed from Favourites'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _bookNow(RoomModel room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingCheckoutModal(room: room),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: 'Saved Favourites',
        subtitle: '${_savedRooms.length} Shortlisted Stays',
        showBack: false,
        actions: [
          if (_savedRooms.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _savedRooms.clear()),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: coral,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _savedRooms.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 54,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No saved rooms yet',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the heart icon on any room in Explore to save it here for fast booking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lime,
                        foregroundColor: navy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          widget.onExplore ?? () => Navigator.pop(context),
                      icon: const Icon(Icons.explore, size: 18),
                      label: const Text(
                        'Explore Nearby Rooms',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _savedRooms.length,
              itemBuilder: (context, index) {
                final room = _savedRooms[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      // Image with Quick Actions
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              room.imageUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 160,
                                color: surfaceLight,
                                child: const Center(
                                  child: Icon(
                                    Icons.hotel,
                                    color: muted,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.6,
                              ),
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.favorite,
                                  color: coral,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () => _removeRoom(room.roomId),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: lime,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                room.tag,
                                style: const TextStyle(
                                  color: navy,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Details & Price
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    room.title,
                                    style: const TextStyle(
                                      color: textWhite,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${room.rating}',
                                      style: const TextStyle(
                                        color: textWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${room.locality}, ${room.city}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PER NIGHT (ZERO BROKERAGE)',
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹${room.pricePerNight}',
                                      style: const TextStyle(
                                        color: lime,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.white24,
                                        ),
                                        foregroundColor: textWhite,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                RoomDetailsScreen(room: room),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'View',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: lime,
                                        foregroundColor: navy,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => _bookNow(room),
                                      child: const Text(
                                        'Book Now',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
