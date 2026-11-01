import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/room_model.dart';
import '../../shared/widgets/app_components.dart';

class AddRoomWizardScreen extends StatefulWidget {
  final RoomModel? existingRoom; // When editing
  const AddRoomWizardScreen({super.key, this.existingRoom});

  @override
  State<AddRoomWizardScreen> createState() => _AddRoomWizardScreenState();
}

class _AddRoomWizardScreenState extends State<AddRoomWizardScreen> {
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1: Basic Information
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _roomType = 'Private Room';
  int _maxGuests = 2;
  int _bedCount = 1;
  int _bathCount = 1;

  // Step 2: Location
  final _cityController = TextEditingController(text: 'Lucknow');
  final _localityController = TextEditingController(text: 'Gomti Nagar');
  final _addressController = TextEditingController(
    text: 'Plot 42, Patrakarpuram Road',
  );
  final _landmarkController = TextEditingController(
    text: 'Near Mithai Chauraha',
  );

  // Step 3: Photos
  List<String> _photos = [];
  int _coverImageIndex = 0;

  // Step 4: Amenities
  final Set<String> _selectedAmenities = {
    'Fast Wi-Fi',
    'AC',
    'Attached Bathroom',
    '24x7 Power Backup',
  };
  final List<String> _allAmenities = [
    'Fast Wi-Fi',
    'AC',
    'Attached Bathroom',
    '24x7 Power Backup',
    'Geyser / Hot Water',
    'Kitchen Access',
    'Dedicated Workstation',
    'Balcony View',
    'RO Water Purifier',
    'Washing Machine',
    'Car Parking',
    'Elevator / Lift',
  ];

  // Step 5: Pricing
  final _pricePerNightController = TextEditingController(text: '899');
  final _cleaningFeeController = TextEditingController(text: '0');
  final _securityDepositController = TextEditingController(text: '0');

  // Step 6: Rules & Policies
  final _checkInTime = '12:00 PM';
  final _checkOutTime = '11:00 AM';
  bool _requiresGovId = true;
  bool _noSmoking = true;
  bool _noParties = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingRoom != null) {
      final r = widget.existingRoom!;
      _titleController.text = r.title;
      _descriptionController.text = r.description;
      _cityController.text = r.city;
      _localityController.text = r.locality;
      _pricePerNightController.text = r.pricePerNight.toString();
      _photos = List.from(r.allPhotos);
      _selectedAmenities.addAll(r.amenities);
    } else {
      _titleController.text = 'Cozy Executive Stay';
      _descriptionController.text = 'Modern, peaceful room with attached bath, high-speed Wi-Fi and 24/7 digital door lock.';
      _photos = [
        'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=900',
        'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=900',
      ];
    }
  }

  void _nextStep() {
    if (_currentStep < 6) {
      setState(() => _currentStep++);
    } else {
      _submitListing();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _submitListing() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: greenAccent,
        content: Text(
          '🎉 Listing submitted for My Roomy Inspection! Published live upon audit.',
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: widget.existingRoom != null
            ? 'Edit Listing'
            : 'Add New Room Listing',
        subtitle: 'Step ${_currentStep + 1} of 7: ${_getStepTitle()}',
        showBack: true,
        onBack: _prevStep,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / 7,
              backgroundColor: surface,
              color: lime,
              minHeight: 3,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStep(),
              ),
            ),

            // Sticky Bottom Nav Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: AppButton(
                        label: 'Previous',
                        isSecondary: true,
                        onPressed: _prevStep,
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _currentStep == 6
                          ? 'Submit for Audit'
                          : 'Continue →',
                      isLoading: _isSaving,
                      onPressed: _nextStep,
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

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Basic Information';
      case 1:
        return 'Location & Map Details';
      case 2:
        return 'Room Photography';
      case 3:
        return 'Amenities & Utilities';
      case 4:
        return 'Pricing & Deposits';
      case 5:
        return 'House Rules & Policies';
      case 6:
        return 'Preview & Submit';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Basic();
      case 1:
        return _buildStep2Location();
      case 2:
        return _buildStep3Photos();
      case 3:
        return _buildStep4Amenities();
      case 4:
        return _buildStep5Pricing();
      case 5:
        return _buildStep6Rules();
      case 6:
        return _buildStep7Preview();
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Basic
  Widget _buildStep1Basic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'Room Title',
          _titleController,
          'e.g. Modern Executive Studio',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Description',
          _descriptionController,
          'Describe interiors, environment, and conveniences...',
          maxLines: 4,
        ),
        const SizedBox(height: 16),

        const Text(
          'Room Type',
          style: TextStyle(
            color: textWhite,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              [
                'Private Room',
                'Shared Room',
                'Entire Studio',
                '1 BHK Apartment',
              ].map((t) {
                final isSel = _roomType == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: isSel,
                  selectedColor: lime,
                  backgroundColor: surfaceLight,
                  labelStyle: TextStyle(
                    color: isSel ? navy : textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _roomType = t);
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 20),

        _buildCounter(
          'Maximum Guest Capacity',
          _maxGuests,
          (v) => setState(() => _maxGuests = v),
        ),
        const Divider(color: Colors.white10, height: 24),
        _buildCounter(
          'Bed Count',
          _bedCount,
          (v) => setState(() => _bedCount = v),
        ),
        const Divider(color: Colors.white10, height: 24),
        _buildCounter(
          'Bathroom Count',
          _bathCount,
          (v) => setState(() => _bathCount = v),
        ),
      ],
    );
  }

  // STEP 2: Location
  Widget _buildStep2Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('City', _cityController, 'e.g. Lucknow'),
        const SizedBox(height: 14),
        _buildTextField(
          'Locality / Sector',
          _localityController,
          'e.g. Gomti Nagar',
        ),
        const SizedBox(height: 14),
        _buildTextField(
          'Complete Street Address',
          _addressController,
          'Building No., Street, Area',
        ),
        const SizedBox(height: 14),
        _buildTextField(
          'Notable Landmark',
          _landmarkController,
          'e.g. Behind Metro Station',
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lime.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.pin_drop_rounded, color: lime, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Pin Coordinates Active',
                      style: TextStyle(
                        color: textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Exact Google Maps deep link is automatically generated for guests.',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 3: Photos
  Widget _buildStep3Photos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upload Photos (Min 3 required)',
              style: TextStyle(
                color: textWhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_photos.length} uploaded',
              style: const TextStyle(
                color: lime,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'High-resolution photos increase booking conversions by 4x.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _photos.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, i) {
            if (i == _photos.length) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _photos.add(
                      'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=900',
                    );
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white24,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: lime, size: 28),
                      SizedBox(height: 6),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isCover = _coverImageIndex == i;
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_photos[i], fit: BoxFit.cover),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _coverImageIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCover ? lime : Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCover ? 'COVER PHOTO' : 'Set as cover',
                        style: TextStyle(
                          color: isCover ? navy : textWhite,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      if (_photos.length > 1) {
                        setState(() => _photos.removeAt(i));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // STEP 4: Amenities
  Widget _buildStep4Amenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Inclusions & Amenities',
          style: TextStyle(
            color: textWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Check all features provided without extra charge.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allAmenities.map((am) {
            final isChecked = _selectedAmenities.contains(am);
            return FilterChip(
              label: Text(am),
              selected: isChecked,
              selectedColor: lime,
              backgroundColor: surfaceLight,
              labelStyle: TextStyle(
                color: isChecked ? navy : textWhite,
                fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(am);
                  } else {
                    _selectedAmenities.remove(am);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 5: Pricing
  Widget _buildStep5Pricing() {
    final nightlyPrice = int.tryParse(_pricePerNightController.text) ?? 0;
    final weeklyDiscounted = (nightlyPrice * 7 * 0.9).round();
    final monthlyDiscounted = (nightlyPrice * 30 * 0.8).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'Nightly Price (INR ₹)',
          _pricePerNightController,
          'e.g. 799',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          'One-time Cleaning Fee (INR ₹)',
          _cleaningFeeController,
          '0 if included',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          'Refundable Security Deposit (INR ₹)',
          _securityDepositController,
          '0 if none',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calculated Long-Stay Discounts',
                style: TextStyle(
                  color: textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              _buildPriceRow(
                'Weekly Stay (7 nights, 10% off)',
                '₹$weeklyDiscounted',
              ),
              const SizedBox(height: 6),
              _buildPriceRow(
                'Monthly Stay (30 nights, 20% off)',
                '₹$monthlyDiscounted',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 6: Rules
  Widget _buildStep6Rules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timings & Access',
          style: TextStyle(
            color: textWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTimingCard('CHECK-IN TIME', _checkInTime)),
            const SizedBox(width: 12),
            Expanded(child: _buildTimingCard('CHECK-OUT TIME', _checkOutTime)),
          ],
        ),
        const SizedBox(height: 20),

        const Text(
          'Mandatory House Rules',
          style: TextStyle(
            color: textWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: lime,
          title: const Text(
            '18+ Government ID Mandatory',
            style: TextStyle(color: textWhite, fontSize: 13),
          ),
          subtitle: const Text(
            'Guests must verify ID before digital PIN is dispatched',
            style: TextStyle(color: muted, fontSize: 11),
          ),
          value: _requiresGovId,
          onChanged: (v) => setState(() => _requiresGovId = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: lime,
          title: const Text(
            'Strictly No Smoking inside room',
            style: TextStyle(color: textWhite, fontSize: 13),
          ),
          value: _noSmoking,
          onChanged: (v) => setState(() => _noSmoking = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: lime,
          title: const Text(
            'No Late Night Loud Music / Parties',
            style: TextStyle(color: textWhite, fontSize: 13),
          ),
          value: _noParties,
          onChanged: (v) => setState(() => _noParties = v),
        ),
      ],
    );
  }

  // STEP 7: Preview
  Widget _buildStep7Preview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lime.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _photos.isNotEmpty ? _photos[_coverImageIndex] : 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _titleController.text,
                      style: const TextStyle(
                        color: textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '₹${_pricePerNightController.text}/night',
                    style: const TextStyle(
                      color: lime,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_localityController.text}, ${_cityController.text}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const Divider(color: Colors.white10, height: 20),

              Text(
                '$_roomType • Max $_maxGuests Guests • $_bedCount Bed • $_bathCount Bath',
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedAmenities
                    .take(4)
                    .map(
                      (a) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a,
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textWhite,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: textWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int val, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: muted),
              onPressed: val > 1 ? () => onChanged(val - 1) : null,
            ),
            Text(
              '$val',
              style: const TextStyle(
                color: textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: lime),
              onPressed: () => onChanged(val + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimingCard(String title, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 12)),
        Text(
          price,
          style: const TextStyle(
            color: greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

