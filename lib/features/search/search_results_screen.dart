import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';
import 'filter_bottom_sheet.dart';
import 'sort_bottom_sheet.dart';
import '../room_details/room_details_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String destination;
  final String? initialDateLabel;
  final int guests;

  const SearchResultsScreen({
    super.key,
    required this.destination,
    this.initialDateLabel,
    this.guests = 1,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  FilterCriteria _filters = FilterCriteria();
  bool _isMapView = false;
  final bool _isLoading = false;
  int? _selectedMarkerIndex;

  // Real room mock listings for search
  final List<RoomModel> _allRooms = const [
    RoomModel(
      roomId: 'room_1',
      ownerId: 'owner_1',
      title: 'Cozy City Room',
      description: 'Comfortable, quiet and air-conditioned room with high-speed Wi-Fi and attached washroom.',
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
      amenities: ['Fast Wi-Fi', 'AC', 'Attached Bathroom', '24x7 Power Backup'],
      houseRules: ['18+ Govt ID mandatory', 'No smoking inside'],
      latitude: 26.8522,
      longitude: 80.9995,
      ownerName: 'Sunita Verma',
      ownerPhone: '+919876543210',
      isVerified: true,
      digitalPin: 'PIN4821',
    ),
    RoomModel(
      roomId: 'room_2',
      ownerId: 'owner_2',
      title: 'Modern Comfort Stay',
      description: 'Upscale room in the heart of Hazratganj with premium queen mattress and balcony view.',
      city: 'Lucknow',
      locality: 'Hazratganj',
      pricePerNight: 999,
      rating: 4.9,
      reviewsCount: 42,
      imageUrl:
          'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=900',
      photos: [
        'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=900',
      ],
      tag: 'Top rated',
      amenities: [
        'Fast Wi-Fi',
        'AC',
        'Kitchen Access',
        'Attached Bathroom',
        'Balcony',
      ],
      houseRules: ['18+ Govt ID mandatory', 'No parties'],
      latitude: 26.8467,
      longitude: 80.9462,
      ownerName: 'Amit Tiwari',
      ownerPhone: '+919876543211',
      isVerified: true,
      digitalPin: 'PIN9321',
    ),
    RoomModel(
      roomId: 'room_3',
      ownerId: 'owner_3',
      title: 'Minimal Studio Room',
      description:
          'Budget-friendly studio with workstation and clean private bath.',
      city: 'Lucknow',
      locality: 'Indira Nagar',
      pricePerNight: 599,
      rating: 4.7,
      reviewsCount: 19,
      imageUrl:
          'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=900',
      photos: [
        'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=900',
      ],
      tag: 'Budget pick',
      amenities: ['Fast Wi-Fi', 'Attached Bathroom', 'RO Water Purifier'],
      houseRules: ['18+ Govt ID mandatory'],
      latitude: 26.8833,
      longitude: 80.9833,
      ownerName: 'Rajesh Mishra',
      ownerPhone: '+919876543212',
      isVerified: false,
      digitalPin: 'PIN1084',
    ),
    RoomModel(
      roomId: 'room_4',
      ownerId: 'owner_4',
      title: 'Premium Relax Room',
      description: 'Spacious executive room with dedicated work desk and high-end interiors.',
      city: 'Lucknow',
      locality: 'Aliganj',
      pricePerNight: 1299,
      rating: 4.9,
      reviewsCount: 56,
      imageUrl:
          'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=900',
      photos: [
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=900',
      ],
      tag: 'Premium',
      amenities: [
        'Fast Wi-Fi',
        'AC',
        'Attached Bathroom',
        '24x7 Power Backup',
        'Geyser',
        'Balcony',
      ],
      houseRules: ['18+ Govt ID mandatory', 'Quiet hours after 10 PM'],
      latitude: 26.8920,
      longitude: 80.9410,
      ownerName: 'Vikas Saxena',
      ownerPhone: '+919876543213',
      isVerified: true,
      digitalPin: 'PIN7712',
    ),
  ];

  List<RoomModel> get _filteredRooms {
    return _allRooms.where((room) {
      if (widget.destination.isNotEmpty &&
          !widget.destination.contains('All')) {
        final query = widget.destination.toLowerCase();
        final matchesLoc =
            room.locality.toLowerCase().contains(query) ||
            room.city.toLowerCase().contains(query) ||
            query.contains(room.locality.toLowerCase()) ||
            query.contains(room.city.toLowerCase());
        if (!matchesLoc) return false;
      }
      if (room.price < _filters.minPrice || room.price > _filters.maxPrice) {
        return false;
      }
      if (_filters.minRating > 0 && room.rating < _filters.minRating) {
        return false;
      }
      if (_filters.verifiedOnly && !room.isVerified) {
        return false;
      }
      if (_filters.amenities.isNotEmpty) {
        for (final am in _filters.amenities) {
          if (!room.amenities.contains(am)) return false;
        }
      }
      return true;
    }).toList()..sort((a, b) {
      switch (_filters.sortBy) {
        case 'Price: Low to High':
          return a.price.compareTo(b.price);
        case 'Price: High to Low':
          return b.price.compareTo(a.price);
        case 'Highest Rated':
          return b.rating.compareTo(a.rating);
        default:
          return 0;
      }
    });
  }

  void _openFilters() async {
    final result = await showModalBottomSheet<FilterCriteria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(initialCriteria: _filters),
    );
    if (result != null) {
      setState(() => _filters = result);
    }
  }

  void _openSorting() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SortBottomSheet(currentSort: _filters.sortBy),
    );
    if (result != null) {
      setState(() => _filters.sortBy = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredRooms;

    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: widget.destination.isEmpty ? 'All Rooms' : widget.destination,
        subtitle:
            '${widget.initialDateLabel ?? "Today - Tomorrow"} • ${widget.guests} Guest(s)',
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(
              _isMapView
                  ? Icons.format_list_bulleted_rounded
                  : Icons.map_rounded,
              color: lime,
            ),
            tooltip: _isMapView ? 'Switch to List' : 'Switch to Map',
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter & Sort Sticky Chips Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: surface,
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _openFilters,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _filters.activeFilterCount > 0
                            ? lime.withValues(alpha: 0.15)
                            : surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _filters.activeFilterCount > 0
                              ? lime
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: _filters.activeFilterCount > 0
                                ? lime
                                : textWhite,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _filters.activeFilterCount > 0
                                ? 'Filters (${_filters.activeFilterCount})'
                                : 'Filter',
                            style: TextStyle(
                              color: _filters.activeFilterCount > 0
                                  ? lime
                                  : textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  InkWell(
                    onTap: _openSorting,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sort_rounded,
                            size: 16,
                            color: textWhite,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _filters.sortBy,
                            style: const TextStyle(
                              color: textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),
                  Text(
                    '${results.length} available',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 4,
                      itemBuilder: (_, _) => const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: AppSkeleton(width: double.infinity, height: 220),
                      ),
                    )
                  : _isMapView
                  ? _buildMapResultsView(results)
                  : _buildListResultsView(results),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListResultsView(List<RoomModel> results) {
    if (results.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No rooms match your filters',
        message: 'Try expanding your price range, clearing some amenities, or searching another neighborhood.',
        actionLabel: 'Reset Filters',
        onAction: () {
          setState(() => _filters = FilterCriteria());
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, idx) {
        final room = results[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoomDetailsScreen(room: room),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        room.allPhotos.first,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 180,
                          color: surfaceLight,
                          child: const Center(
                            child: Icon(
                              Icons.hotel_rounded,
                              color: muted,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (room.isVerified)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: navy.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: lime),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: lime,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'VERIFIED',
                                style: TextStyle(
                                  color: lime,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: navy.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${room.price}/night',
                          style: const TextStyle(
                            color: textWhite,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(14),
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
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                                size: 16,
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
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Available Now',
                              style: TextStyle(
                                color: greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Digital PIN Dispatch',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: lime,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapResultsView(List<RoomModel> results) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF141923),
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=1200',
              ),
              fit: BoxFit.cover,
              opacity: 0.35,
            ),
          ),
          child: Stack(
            children: List.generate(results.length, (i) {
              final r = results[i];
              final topOffset = 80.0 + (i * 90.0) % 360.0;
              final leftOffset = 40.0 + (i * 110.0) % 280.0;
              final isSel = _selectedMarkerIndex == i;

              return Positioned(
                top: topOffset,
                left: leftOffset,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMarkerIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSel ? lime : navy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lime, width: isSel ? 2 : 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bed_rounded,
                          size: 14,
                          color: isSel ? navy : lime,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${r.price}',
                          style: TextStyle(
                            color: isSel ? navy : textWhite,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        if (_selectedMarkerIndex != null &&
            _selectedMarkerIndex! < results.length)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lime.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      results[_selectedMarkerIndex!].allPhotos.first,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          results[_selectedMarkerIndex!].title,
                          style: const TextStyle(
                            color: textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${results[_selectedMarkerIndex!].locality}, ${results[_selectedMarkerIndex!].city}',
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${results[_selectedMarkerIndex!].price} / night',
                          style: const TextStyle(
                            color: lime,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lime,
                      foregroundColor: navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoomDetailsScreen(
                            room: results[_selectedMarkerIndex!],
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
