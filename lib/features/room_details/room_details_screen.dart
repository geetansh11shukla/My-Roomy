import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';
import '../booking/date_selection_modal.dart';
import '../booking/booking_review_screen.dart';
import 'image_gallery_screen.dart';
import '../reviews/all_reviews_screen.dart';

class RoomDetailsScreen extends StatefulWidget {
  final RoomModel room;
  const RoomDetailsScreen({super.key, required this.room});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Default 1-night stay starting tomorrow
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDateRange = DateTimeRange(
      start: tomorrow,
      end: tomorrow.add(const Duration(days: 1)),
    );
  }

  void _selectDates() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DateSelectionModal(
        room: widget.room,
        initialCheckIn:
            _selectedDateRange?.start ??
            DateTime.now().add(const Duration(days: 1)),
        initialCheckOut:
            _selectedDateRange?.end ??
            DateTime.now().add(const Duration(days: 2)),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(
          start: result['checkIn'] as DateTime,
          end: result['checkOut'] as DateTime,
        );
      });
    }
  }

  void _openBookingCheckout() {
    final checkIn =
        _selectedDateRange?.start ??
        DateTime.now().add(const Duration(days: 1));
    final checkOut =
        _selectedDateRange?.end ?? DateTime.now().add(const Duration(days: 2));
    final nights = checkOut.difference(checkIn).inDays;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingReviewScreen(
          room: widget.room,
          checkInDate:
              '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')}',
          checkOutDate:
              '${checkOut.year}-${checkOut.month.toString().padLeft(2, '0')}-${checkOut.day.toString().padLeft(2, '0')}',
          nights: nights > 0 ? nights : 1,
          guests: 1,
        ),
      ),
    );
  }

  void _reportListing() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Report Listing',
          style: TextStyle(
            color: textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Help us maintain 100% verified rooms. If you noticed inaccurate details, pricing discrepancy or misleading photos, let our inspection team know.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: coral,
              foregroundColor: textWhite,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Report submitted. Our inspection team will audit this room.',
                  ),
                ),
              );
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.room.photos.isNotEmpty
        ? widget.room.photos
        : ['https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900'];

    return Scaffold(
      backgroundColor: navy,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image Gallery App Bar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: navy,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isFavorite ? coral : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text(
                            _isFavorite
                                ? 'Saved to your Favourites!'
                                : 'Removed from Favourites',
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _reportListing,
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImageGalleryScreen(
                                images: images,
                                initialIndex: _currentImageIndex,
                                title: widget.room.title,
                              ),
                            ),
                          );
                        },
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (idx) =>
                              setState(() => _currentImageIndex = idx),
                          itemBuilder: (context, idx) {
                            return Image.network(
                              images[idx],
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: surface,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: muted,
                                    size: 48,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Image Counter Chip
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1} / ${images.length} Photos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Room Content Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verified Badge & Rating Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.room.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: lime.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: lime.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: lime,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '100% ROOMWALA VERIFIED',
                                    style: TextStyle(
                                      color: lime,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
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
                                '${widget.room.rating}',
                                style: const TextStyle(
                                  color: textWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '(34 reviews)',
                                style: TextStyle(color: muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Room Title
                      Text(
                        widget.room.title,
                        style: const TextStyle(
                          color: textWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Location & Proximity
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: lime,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.room.locality}, ${widget.room.city}',
                            style: const TextStyle(
                              color: muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),

                      // Key Specs Grid (Room Type, Capacity, Bed, Bath)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSpecItem(
                            Icons.hotel_rounded,
                            'Double Bed',
                            'Queen Size',
                          ),
                          _buildSpecItem(
                            Icons.group_rounded,
                            'Max Capacity',
                            '2 Guests',
                          ),
                          _buildSpecItem(
                            Icons.bathtub_rounded,
                            'Bathroom',
                            'Attached (Geyser)',
                          ),
                          _buildSpecItem(
                            Icons.meeting_room_rounded,
                            'Door Access',
                            'Digital PIN',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 18),

                      // Date Range Selector
                      const Text(
                        'Selected Dates',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDates,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: lime.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: lime,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedDateRange != null
                                            ? '${_selectedDateRange!.start.day} ${_getMonth(_selectedDateRange!.start.month)} - ${_selectedDateRange!.end.day} ${_getMonth(_selectedDateRange!.end.month)}'
                                            : 'Select check-in & check-out',
                                        style: const TextStyle(
                                          color: textWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedDateRange != null
                                            ? '${_selectedDateRange!.duration.inDays} night(s) stay • Instant lock'
                                            : 'Tap to pick stay calendar',
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.edit_calendar_rounded,
                                color: lime,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Description
                      const Text(
                        'About this Room',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.room.description.isNotEmpty
                            ? widget.room.description
                            : 'Comfortable, clean, and fully-equipped room located in a prime neighborhood. Features high-speed Wi-Fi, air conditioning, and convenient digital door lock for 24/7 self check-in.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Amenities Grid
                      const Text(
                        'Amenities & Inclusions',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            (widget.room.amenities.isNotEmpty
                                    ? widget.room.amenities
                                    : [
                                        'Fast Wi-Fi',
                                        'AC',
                                        'Attached Bath',
                                        'Power Backup',
                                        'Digital Lock',
                                      ])
                                .map(
                                  (amenity) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: lime,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          amenity,
                                          style: const TextStyle(
                                            color: textWhite,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 22),

                      // House Rules & Timings
                      const Text(
                        'House Rules & Policies',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Column(
                          children: [
                            _RuleRow(
                              icon: Icons.login_rounded,
                              title: 'Check-in Time',
                              value: '12:00 PM onwards (Digital PIN)',
                            ),
                            SizedBox(height: 10),
                            _RuleRow(
                              icon: Icons.logout_rounded,
                              title: 'Check-out Time',
                              value: '11:00 AM (Extension alerts 24h prior)',
                            ),
                            SizedBox(height: 10),
                            _RuleRow(
                              icon: Icons.verified_user_outlined,
                              title: 'ID Verification',
                              value: '18+ Government ID mandatory at check-in',
                            ),
                            SizedBox(height: 10),
                            _RuleRow(
                              icon: Icons.cancel_outlined,
                              title: 'Cancellation Policy',
                              value: '100% Free cancellation up to 24h before',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Approximate Map Location Preview
                      const Text(
                        'Location Preview',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Approximate neighborhood shown. Exact door PIN and navigation link are dispatched automatically to your WhatsApp upon booking confirmation.',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800',
                            ),
                            fit: BoxFit.cover,
                            opacity: 0.45,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: navy.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: lime),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pin_drop_rounded,
                                  color: lime,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${widget.room.locality}, ${widget.room.city}',
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
                      ),
                      const SizedBox(height: 24),

                      // Reviews Preview & View All Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Guest Reviews (34)',
                            style: TextStyle(
                              color: textWhite,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AllReviewsScreen(
                                    roomTitle: widget.room.title,
                                    averageRating: widget.room.rating,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'View All Reviews →',
                              style: TextStyle(
                                color: lime,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Bar with Price and Book Now
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: surface,
                border: const Border(top: BorderSide(color: Colors.white10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              '₹${widget.room.price}',
                              style: const TextStyle(
                                color: textWhite,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              ' / night',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
                        const Text(
                          'Zero brokerage fee',
                          style: TextStyle(
                            color: greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 170,
                      child: AppButton(
                        label: 'Book Now',
                        onPressed: _openBookingCheckout,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String title, String sub) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: lime, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: textWhite,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(sub, style: const TextStyle(color: muted, fontSize: 10)),
      ],
    );
  }

  String _getMonth(int month) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return m[month];
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _RuleRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: lime, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value, style: const TextStyle(color: muted, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

