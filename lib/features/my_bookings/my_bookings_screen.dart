import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../services/booking_engine.dart';
import '../booking/booking_details_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  final String customerPhone;

  const MyBookingsScreen({super.key, this.customerPhone = '9876543210'});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingEngine _bookingEngine = BookingEngine();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold)),
        backgroundColor: navy,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: lime,
          labelColor: lime,
          unselectedLabelColor: muted,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _bookingEngine.streamCustomerBookings(widget.customerPhone),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasError) {
            return const Center(child: CircularProgressIndicator(color: lime));
          }

          final allBookings = (snapshot.hasData && snapshot.data!.isNotEmpty)
              ? snapshot.data!
              : _bookingEngine.getLocalBookings();

          // Split by tabs
          final upcoming = allBookings.where((b) => b.status == BookingStatus.confirmed).toList();
          final cancelled = allBookings.where((b) => b.status == BookingStatus.cancelled).toList();
          final past = allBookings.where((b) => b.status == BookingStatus.completed).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(upcoming, 'No upcoming room bookings', 'Explore rooms to make an instant reservation.'),
              _buildBookingList(past, 'No past room stays', 'Completed stays will appear here for review and invoices.'),
              _buildBookingList(cancelled, 'No cancelled bookings', 'Cancelled bookings and refund records will show here.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings, String emptyTitle, String emptySubtitle) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: surface, shape: BoxShape.circle),
                child: const Icon(Icons.confirmation_number_outlined, size: 48, color: muted),
              ),
              const SizedBox(height: 16),
              Text(emptyTitle, style: const TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(emptySubtitle, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        final isCancelled = b.status == BookingStatus.cancelled;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: b)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('BOOKING ID: ${b.bookingId}', style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCancelled ? coral.withValues(alpha: 0.15) : greenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCancelled ? 'CANCELLED' : 'CONFIRMED',
                          style: TextStyle(
                            color: isCancelled ? coral : greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(b.roomTitle, style: const TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${b.locality}, ${b.city}', style: const TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: muted),
                      const SizedBox(width: 6),
                      Text('${b.checkIn} (${b.nights} night${b.nights == 1 ? '' : 's'})', style: const TextStyle(color: textWhite, fontSize: 12)),
                      const Spacer(),
                      Text('₹${b.totalAmount}', style: const TextStyle(color: lime, fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isCancelled)
                        Text('PIN: ${b.accessPin}', style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 13))
                      else
                        const Text('Refund processed', style: TextStyle(color: coral, fontSize: 12, fontWeight: FontWeight.w500)),
                      const Row(
                        children: [
                          Text('View Details', style: TextStyle(color: textWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, color: textWhite, size: 12),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
