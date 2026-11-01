import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class ReviewItem {
  final String author;
  final String date;
  final double rating;
  final String comment;
  final bool verifiedStay;

  const ReviewItem({
    required this.author,
    required this.date,
    required this.rating,
    required this.comment,
    this.verifiedStay = true,
  });
}

class AllReviewsScreen extends StatelessWidget {
  final String roomTitle;
  final double averageRating;
  final int totalReviews;

  const AllReviewsScreen({
    super.key,
    required this.roomTitle,
    this.averageRating = 4.8,
    this.totalReviews = 34,
  });

  static const List<ReviewItem> demoReviews = [
    ReviewItem(
      author: 'Aarav Patel',
      date: '14 Oct 2026',
      rating: 5.0,
      comment: 'Super fast check-in with the WhatsApp PIN. The room was spotless and matched the photos 100%. Highly recommended for short stays!',
      verifiedStay: true,
    ),
    ReviewItem(
      author: 'Priya Sharma',
      date: '02 Oct 2026',
      rating: 5.0,
      comment: 'Quiet neighborhood, high speed Wi-Fi for remote work, and instant extension approval. Best experience without broker hassle.',
      verifiedStay: true,
    ),
    ReviewItem(
      author: 'Vikram Verma',
      date: '28 Sep 2026',
      rating: 4.5,
      comment: 'Great value for money. AC was chilled and power backup kicked in immediately during power cuts. Owner was very polite.',
      verifiedStay: true,
    ),
    ReviewItem(
      author: 'Neha Gupta',
      date: '19 Sep 2026',
      rating: 4.8,
      comment: 'Loved the direct digital pass on WhatsApp. No awkward waiting for keys. Very safe for solo female travelers.',
      verifiedStay: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppHeader(
        title: 'Guest Reviews',
        subtitle: roomTitle,
        showBack: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Rating Summary Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(color: textWhite, fontSize: 34, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                        ],
                      ),
                      Text(
                        'Based on $totalReviews verified stays',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Rating Breakdown Mini Bars
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildRatingBar('5 ★', 0.85),
                      _buildRatingBar('4 ★', 0.12),
                      _buildRatingBar('3 ★', 0.03),
                      _buildRatingBar('2 ★', 0.00),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'REVIEWS FROM VERIFIED GUESTS',
              style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(height: 12),

            ...demoReviews.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: surfaceLight,
                                child: Text(r.author[0], style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.author, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(r.date, style: const TextStyle(color: muted, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: lime.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: lime, size: 13),
                                const SizedBox(width: 4),
                                Text(r.rating.toString(), style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(r.comment, style: const TextStyle(color: textWhite, fontSize: 13, height: 1.4)),
                      if (r.verifiedStay) ...[
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: greenAccent, size: 13),
                            SizedBox(width: 4),
                            Text('Verified My Roomy Stay', style: TextStyle(color: greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(String label, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 10)),
          const SizedBox(width: 6),
          Container(
            width: 70,
            height: 5,
            decoration: BoxDecoration(color: surfaceLight, borderRadius: BorderRadius.circular(3)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(3))),
            ),
          ),
        ],
      ),
    );
  }
}
