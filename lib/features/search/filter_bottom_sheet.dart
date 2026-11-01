import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class FilterCriteria {
  double minPrice;
  double maxPrice;
  String roomType;
  int guests;
  List<String> amenities;
  double minRating;
  bool verifiedOnly;
  String sortBy;

  FilterCriteria({
    this.minPrice = 400,
    this.maxPrice = 3000,
    this.roomType = 'All',
    this.guests = 1,
    this.amenities = const [],
    this.minRating = 0.0,
    this.verifiedOnly = false,
    this.sortBy = 'Recommended',
  });

  FilterCriteria copyWith({
    double? minPrice,
    double? maxPrice,
    String? roomType,
    int? guests,
    List<String>? amenities,
    double? minRating,
    bool? verifiedOnly,
    String? sortBy,
  }) {
    return FilterCriteria(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      roomType: roomType ?? this.roomType,
      guests: guests ?? this.guests,
      amenities: amenities ?? List.from(this.amenities),
      minRating: minRating ?? this.minRating,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  int get activeFilterCount {
    int count = 0;
    if (minPrice > 400 || maxPrice < 3000) count++;
    if (roomType != 'All') count++;
    if (guests > 1) count++;
    if (amenities.isNotEmpty) count += amenities.length;
    if (minRating > 0) count++;
    if (verifiedOnly) count++;
    return count;
  }
}

class FilterBottomSheet extends StatefulWidget {
  final FilterCriteria initialCriteria;
  const FilterBottomSheet({super.key, required this.initialCriteria});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterCriteria _criteria;

  final List<String> _roomTypes = [
    'All',
    'Single Room',
    'Double Room',
    'Studio',
    '1 BHK Flat',
  ];
  final List<String> _availableAmenities = [
    'Fast Wi-Fi',
    'AC',
    'Attached Bathroom',
    '24x7 Power Backup',
    'Kitchen Access',
    'Geyser',
    'Balcony',
    'RO Water Purifier',
  ];

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria.copyWith(
      amenities: List.from(widget.initialCriteria.amenities),
    );
  }

  void _clearAll() {
    setState(() {
      _criteria = FilterCriteria();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Filter Rooms',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_criteria.activeFilterCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: lime,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_criteria.activeFilterCount}',
                          style: const TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: _clearAll,
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
          ),
          const Divider(color: Colors.white10),

          // Scrollable Filter Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Price Range Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Price per night',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${_criteria.minPrice.toInt()} - ₹${_criteria.maxPrice.toInt()}',
                      style: const TextStyle(
                        color: lime,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(_criteria.minPrice, _criteria.maxPrice),
                  min: 400,
                  max: 4000,
                  divisions: 36,
                  activeColor: lime,
                  inactiveColor: surfaceLight,
                  onChanged: (vals) {
                    setState(() {
                      _criteria.minPrice = vals.start;
                      _criteria.maxPrice = vals.end;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Room Type Selector
                const Text(
                  'Room Type',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _roomTypes.map((type) {
                    final isSelected = _criteria.roomType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      selectedColor: lime,
                      backgroundColor: surfaceLight,
                      labelStyle: TextStyle(
                        color: isSelected ? navy : textWhite,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _criteria.roomType = type);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Number of Guests
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Number of Guests',
                      style: TextStyle(
                        color: textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: muted,
                          ),
                          onPressed: _criteria.guests > 1
                              ? () => setState(() => _criteria.guests--)
                              : null,
                        ),
                        Text(
                          '${_criteria.guests}',
                          style: const TextStyle(
                            color: textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: lime,
                          ),
                          onPressed: () => setState(() => _criteria.guests++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amenities Multi-Select
                const Text(
                  'Amenities',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableAmenities.map((amenity) {
                    final isChecked = _criteria.amenities.contains(amenity);
                    return FilterChip(
                      label: Text(amenity),
                      selected: isChecked,
                      selectedColor: lime,
                      backgroundColor: surfaceLight,
                      labelStyle: TextStyle(
                        color: isChecked ? navy : textWhite,
                        fontWeight: isChecked
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _criteria.amenities.add(amenity);
                          } else {
                            _criteria.amenities.remove(amenity);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Minimum Rating
                const Text(
                  'Minimum Rating',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [0.0, 4.0, 4.5, 4.8].map((rating) {
                    final isSel = _criteria.minRating == rating;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: rating > 0
                            ? const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              )
                            : null,
                        label: Text(rating == 0.0 ? 'Any' : '$rating+'),
                        selected: isSel,
                        selectedColor: lime,
                        backgroundColor: surfaceLight,
                        labelStyle: TextStyle(
                          color: isSel ? navy : textWhite,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _criteria.minRating = rating);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Verified Listings Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: lime,
                  title: const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: lime, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'My Roomy Verified Only',
                        style: TextStyle(
                          color: textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Show stays with 100% physically inspected rooms & digital door PINs',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                  value: _criteria.verifiedOnly,
                  onChanged: (val) =>
                      setState(() => _criteria.verifiedOnly = val),
                ),
              ],
            ),
          ),

          // Bottom Apply Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: navy,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: AppButton(
              label: 'Apply Filters (${_criteria.activeFilterCount})',
              onPressed: () => Navigator.pop(context, _criteria),
            ),
          ),
        ],
      ),
    );
  }
}
