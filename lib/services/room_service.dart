import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _roomsRef => _firestore.collection('rooms');
  CollectionReference get _bookingsRef => _firestore.collection('bookings');

  /// Stream of all active room listings in real-time
  Stream<List<RoomModel>> streamActiveRooms({String? city}) {
    Query query = _roomsRef.where('instantBookingEnabled', isEqualTo: true);
    if (city != null && city.isNotEmpty && city != 'All') {
      query = query.where('city', isEqualTo: city);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RoomModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Single room details fetch
  Future<RoomModel?> getRoomById(String roomId) async {
    final doc = await _roomsRef.doc(roomId).get();
    if (!doc.exists) return null;
    return RoomModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Atomic Booking & Slot Locking:
  /// Uses a Firestore Transaction so two users can NEVER book the same room for the same date!
  Future<bool> createBookingTransaction({
    required BookingModel booking,
    required RoomModel room,
  }) async {
    try {
      final roomDocRef = _roomsRef.doc(room.roomId);
      final bookingDocRef = _bookingsRef.doc(booking.bookingId);

      await _firestore.runTransaction((transaction) async {
        final roomSnapshot = await transaction.get(roomDocRef);

        if (!roomSnapshot.exists) {
          throw Exception("Room does not exist.");
        }

        final roomData = roomSnapshot.data() as Map<String, dynamic>;
        final List<String> existingBookedDates = List<String>.from(roomData['bookedDates'] ?? []);

        // Check if requested checkIn date is already booked
        if (existingBookedDates.contains(booking.checkIn)) {
          throw Exception("Selected date is already booked by another customer!");
        }

        // 1. Save confirmed booking
        transaction.set(bookingDocRef, booking.toMap());

        // 2. Lock date in room record immediately
        existingBookedDates.add(booking.checkIn);
        transaction.update(roomDocRef, {
          'bookedDates': existingBookedDates,
          'instantBookingEnabled': true, // Keep active for other dates
        });
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Seed initial demo rooms if Firestore is empty
  Future<void> seedInitialRoomsIfEmpty(List<RoomModel> seedRooms) async {
    final snapshot = await _roomsRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final batch = _firestore.batch();
      for (final r in seedRooms) {
        final doc = _roomsRef.doc(r.roomId);
        batch.set(doc, r.toMap());
      }
      await batch.commit();
    }
  }
}
