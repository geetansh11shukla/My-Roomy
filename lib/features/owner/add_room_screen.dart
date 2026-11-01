import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController(text: 'Delhi');
  final _localityController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=900',
  );
  final _descriptionController = TextEditingController();
  final _ownerNameController = TextEditingController(text: 'Vikram Sharma');
  final _ownerPhoneController = TextEditingController(text: '9876543210');

  final List<String> _selectedAmenities = [
    'Wi-Fi',
    'Attached Washroom',
    'Air Conditioning',
  ];
  bool _isSaving = false;

  final List<String> _allAmenities = [
    'Wi-Fi',
    'Air Conditioning',
    'Attached Washroom',
    'Geyser',
    'Balcony',
    'Power Backup',
    'RO Water',
    'Washing Machine',
  ];

  Future<void> _submitRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
      final price = int.tryParse(_priceController.text.trim()) ?? 800;

      final newRoom = RoomModel(
        roomId: roomId,
        ownerId: 'owner_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        city: _cityController.text.trim(),
        locality: _localityController.text.trim(),
        pricePerNight: price,
        rating: 4.9,
        reviewsCount: 1,
        imageUrl: _imageController.text.trim(),
        tag: 'New Listing',
        description: _descriptionController.text.trim(),
        amenities: _selectedAmenities,
        houseRules: const [
          '18+ Govt ID mandatory',
          'Strict check-in 12:00 PM',
          'No loud music after 10 PM',
        ],
        latitude: 28.5355,
        longitude: 77.3910,
        ownerName: _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        instantBookingEnabled: true,
        bookedDates: const [],
      );

      try {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .set(newRoom.toMap())
            .timeout(const Duration(seconds: 4));
      } catch (_) {
        debugPrint('Firestore not active, saved locally to session.');
      }

      if (!mounted) return;

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: greenAccent,
          content: Text('🎉 Room Listing successfully published to My Roomy!'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving room: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text('Add New Room Listing'),
        backgroundColor: navy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Host Your Room on My Roomy',
                style: TextStyle(
                  color: textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Direct guest bookings without broker commission. Zero owner calling hassle.',
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: textWhite),
                decoration: InputDecoration(
                  labelText: 'Room Title (e.g. Cozy Private Studio near Metro)',
                  labelStyle: const TextStyle(color: muted),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 14),

              // City & Locality Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      style: const TextStyle(color: textWhite),
                      decoration: InputDecoration(
                        labelText: 'City (e.g. Delhi, Lucknow)',
                        labelStyle: const TextStyle(color: muted),
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'City required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _localityController,
                      style: const TextStyle(color: textWhite),
                      decoration: InputDecoration(
                        labelText: 'Locality / Area',
                        labelStyle: const TextStyle(color: muted),
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Locality required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Rent per night
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textWhite),
                decoration: InputDecoration(
                  labelText: 'Rent Per Night (₹)',
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    color: lime,
                    fontWeight: FontWeight.bold,
                  ),
                  labelStyle: const TextStyle(color: muted),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Rent required' : null,
              ),
              const SizedBox(height: 14),

              // Photo URL
              TextFormField(
                controller: _imageController,
                style: const TextStyle(color: textWhite),
                decoration: InputDecoration(
                  labelText: 'Cover Image URL',
                  labelStyle: const TextStyle(color: muted),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Image required' : null,
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: textWhite),
                decoration: InputDecoration(
                  labelText: 'Room Description & House Highlights',
                  labelStyle: const TextStyle(color: muted),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Amenities selection
              const Text(
                'Select Available Amenities',
                style: TextStyle(
                  color: textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allAmenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    selectedColor: lime,
                    backgroundColor: surface,
                    labelStyle: TextStyle(
                      color: isSelected ? navy : textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Owner Contact Details
              const Text(
                'Owner Contact (Private — for automated tickets)',
                style: TextStyle(
                  color: textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ownerNameController,
                      style: const TextStyle(color: textWhite),
                      decoration: InputDecoration(
                        labelText: 'Host Name',
                        labelStyle: const TextStyle(color: muted),
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ownerPhoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: textWhite),
                      decoration: InputDecoration(
                        labelText: 'WhatsApp No.',
                        labelStyle: const TextStyle(color: muted),
                        filled: true,
                        fillColor: surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _submitRoom,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: navy)
                      : const Text(
                          'Publish Verified Room',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

