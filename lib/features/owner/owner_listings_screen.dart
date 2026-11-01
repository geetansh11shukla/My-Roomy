import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';
import 'add_room_wizard_screen.dart';
import 'owner_availability_calendar_screen.dart';
import '../room_details/room_details_screen.dart';

enum ListingStatus { published, pendingApproval, draft, paused }

class OwnerListingsScreen extends StatefulWidget {
  const OwnerListingsScreen({super.key});

  @override
  State<OwnerListingsScreen> createState() => _OwnerListingsScreenState();
}

class _OwnerListingsScreenState extends State<OwnerListingsScreen> {
  final List<Map<String, dynamic>> _myListings = [
    {
      'room': const RoomModel(
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
        amenities: ['Fast Wi-Fi', 'AC', 'Attached Bathroom', '24x7 Power Backup'],
        houseRules: ['18+ Govt ID mandatory', 'No smoking inside'],
        latitude: 26.8522,
        longitude: 80.9995,
        ownerName: 'Shukla Stays',
        ownerPhone: '+919876543210',
        isVerified: true,
        digitalPin: 'PIN4821',
      ),
      'status': ListingStatus.published,
    },
    {
      'room': const RoomModel(
        roomId: 'room_2',
        ownerId: 'host_current',
        title: 'Modern Comfort Stay',
        description: 'Upscale room in the heart of Hazratganj with premium queen mattress and balcony view.',
        city: 'Lucknow',
        locality: 'Hazratganj',
        pricePerNight: 999,
        rating: 4.9,
        reviewsCount: 42,
        imageUrl: 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=900',
        photos: ['https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=900'],
        tag: 'Top rated',
        amenities: ['Fast Wi-Fi', 'AC', 'Kitchen Access', 'Attached Bathroom', 'Balcony'],
        houseRules: ['18+ Govt ID mandatory', 'No parties'],
        latitude: 26.8467,
        longitude: 80.9462,
        ownerName: 'Shukla Stays',
        ownerPhone: '+919876543210',
        isVerified: true,
        digitalPin: 'PIN9321',
      ),
      'status': ListingStatus.published,
    },
    {
      'room': const RoomModel(
        roomId: 'room_new',
        ownerId: 'host_current',
        title: 'Sunlit Studio Suite',
        description: 'New property near metro station pending initial quality inspection audit.',
        city: 'Lucknow',
        locality: 'Indira Nagar',
        pricePerNight: 650,
        rating: 5.0,
        reviewsCount: 0,
        imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=900',
        photos: ['https://images.unsplash.com/photo-1590490360182-c33d57733427?w=900'],
        tag: 'New',
        amenities: ['Fast Wi-Fi', 'Attached Bathroom'],
        houseRules: ['18+ Govt ID mandatory'],
        latitude: 26.8833,
        longitude: 80.9833,
        ownerName: 'Shukla Stays',
        ownerPhone: '+919876543210',
        isVerified: false,
        digitalPin: 'PIN5501',
      ),
      'status': ListingStatus.pendingApproval,
    },
  ];

  void _addNewRoom() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddRoomWizardScreen()),
    );
    if (res == true) {
      setState(() {});
    }
  }

  void _togglePause(int index) {
    setState(() {
      final current = _myListings[index]['status'] as ListingStatus;
      if (current == ListingStatus.published) {
        _myListings[index]['status'] = ListingStatus.paused;
      } else if (current == ListingStatus.paused) {
        _myListings[index]['status'] = ListingStatus.published;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: 'My Room Listings',
        subtitle: '${_myListings.length} total properties',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: lime, size: 24),
            onPressed: _addNewRoom,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _myListings.length,
          itemBuilder: (context, i) {
            final item = _myListings[i];
            final RoomModel room = item['room'];
            final ListingStatus status = item['status'];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  // Photo & Status Row
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          room.imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _buildStatusPill(status),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: navy.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            '₹${room.pricePerNight}/night',
                            style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Room Details Body
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.title, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('${room.locality}, ${room.city}', style: const TextStyle(color: muted, fontSize: 12)),
                        const Divider(color: Colors.white10, height: 20),

                        // Action Buttons Bar
                        Row(
                          children: [
                            // Calendar action
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white24),
                                  foregroundColor: textWhite,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OwnerAvailabilityCalendarScreen(room: room),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.calendar_month_rounded, size: 16, color: lime),
                                label: const Text('Calendar', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Preview action
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white24),
                                  foregroundColor: textWhite,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => RoomDetailsScreen(room: room)),
                                  );
                                },
                                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                label: const Text('Preview', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Edit / Pause
                            IconButton(
                              icon: Icon(
                                status == ListingStatus.published ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                                color: status == ListingStatus.published ? Colors.amber : greenAccent,
                              ),
                              tooltip: status == ListingStatus.published ? 'Pause Listing' : 'Publish Listing',
                              onPressed: () => _togglePause(i),
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
      ),
    );
  }

  Widget _buildStatusPill(ListingStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ListingStatus.published:
        bg = greenAccent.withValues(alpha: 0.2);
        fg = greenAccent;
        label = 'LIVE & PUBLISHED';
        break;
      case ListingStatus.pendingApproval:
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amber;
        label = 'AUDIT PENDING';
        break;
      case ListingStatus.paused:
        bg = Colors.orange.withValues(alpha: 0.2);
        fg = Colors.orange;
        label = 'PAUSED';
        break;
      case ListingStatus.draft:
        bg = Colors.white10;
        fg = muted;
        label = 'DRAFT';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: fg)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 9)),
    );
  }
}

