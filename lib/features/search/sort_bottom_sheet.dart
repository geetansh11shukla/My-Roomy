import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SortBottomSheet extends StatelessWidget {
  final String currentSort;
  const SortBottomSheet({super.key, required this.currentSort});

  static const List<Map<String, dynamic>> sortOptions = [
    {'title': 'Recommended', 'subtitle': 'Best combination of ratings and proximity', 'icon': Icons.thumb_up_alt_outlined},
    {'title': 'Price: Low to High', 'subtitle': 'Budget friendly rooms first', 'icon': Icons.arrow_downward_rounded},
    {'title': 'Price: High to Low', 'subtitle': 'Luxury & premium stays first', 'icon': Icons.arrow_upward_rounded},
    {'title': 'Highest Rated', 'subtitle': 'Top rated 4.8+ rooms by verified guests', 'icon': Icons.star_outline_rounded},
    {'title': 'Recently Added', 'subtitle': 'Newly listed rooms with instant booking', 'icon': Icons.access_time_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Sort Rooms By', style: TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          ...sortOptions.map((opt) {
            final isSelected = opt['title'] == currentSort;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? lime : surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(opt['icon'] as IconData, color: isSelected ? navy : textWhite, size: 20),
              ),
              title: Text(
                opt['title'] as String,
                style: TextStyle(
                  color: isSelected ? lime : textWhite,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(opt['subtitle'] as String, style: const TextStyle(color: muted, fontSize: 11)),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: lime, size: 20) : null,
              onTap: () => Navigator.pop(context, opt['title']),
            );
          }),
        ],
      ),
    );
  }
}
