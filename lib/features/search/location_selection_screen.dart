import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class LocationSelectionScreen extends StatefulWidget {
  final String? initialCity;
  const LocationSelectionScreen({super.key, this.initialCity});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _popularLocalities = [
    'Gomti Nagar, Lucknow',
    'Hazratganj, Lucknow',
    'Indira Nagar, Lucknow',
    'Aliganj, Lucknow',
    'Connaught Place, New Delhi',
    'Sector 62, Noida',
    'Cyber City, Gurugram',
    'Koramangala, Bengaluru',
    'Bandra West, Mumbai',
  ];

  final List<String> _recentSearches = [
    'Gomti Nagar, Lucknow',
    'Hazratganj, Lucknow',
    'Delhi Airport Terminal 3',
  ];

  void _useCurrentLocation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.my_location_rounded, color: lime, size: 22),
            SizedBox(width: 8),
            Text('Location Permission', style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'My Roomy uses your location to discover verified rooms nearby and provide instant walking navigation.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Now', style: TextStyle(color: muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lime, foregroundColor: navy),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, 'Hazratganj, Lucknow (GPS)');
            },
            child: const Text('Allow', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLocalities = _searchQuery.isEmpty
        ? _popularLocalities
        : _popularLocalities
            .where((loc) => loc.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: 'Select Destination',
        subtitle: 'Search cities, localities or landmarks',
        showBack: true,
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: muted, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: textWhite, fontSize: 14),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search city, locality or landmark...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: lime, size: 22),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: lime)),
                ),
              ),
            ),

            // Use Current Location CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                onTap: _useCurrentLocation,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lime.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.gps_fixed_rounded, color: lime, size: 20),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Use Current Location', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Discover rooms within walking distance', style: TextStyle(color: muted, fontSize: 11)),
                        ],
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, color: muted, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Search Content / Suggestions
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_searchQuery.isEmpty && _recentSearches.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('RECENT SEARCHES', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                    ..._recentSearches.map((rec) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history_rounded, color: muted, size: 20),
                          title: Text(rec, style: const TextStyle(color: textWhite, fontSize: 14)),
                          trailing: const Icon(Icons.north_west_rounded, color: Colors.white24, size: 16),
                          onTap: () => Navigator.pop(context, rec),
                        )),
                    const Divider(color: Colors.white10, height: 24),
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _searchQuery.isEmpty ? 'POPULAR LOCALITIES' : 'MATCHING DESTINATIONS (${filteredLocalities.length})',
                      style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                    ),
                  ),

                  if (filteredLocalities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text('No localities match your search. Try another city.', style: TextStyle(color: muted, fontSize: 13)),
                      ),
                    )
                  else
                    ...filteredLocalities.map((loc) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.location_on_outlined, color: lime, size: 18),
                          ),
                          title: Text(loc, style: const TextStyle(color: textWhite, fontSize: 14, fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: muted, size: 20),
                          onTap: () => Navigator.pop(context, loc),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
