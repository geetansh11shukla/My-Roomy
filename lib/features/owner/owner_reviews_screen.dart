import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class OwnerReviewsScreen extends StatefulWidget {
  const OwnerReviewsScreen({super.key});

  @override
  State<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends State<OwnerReviewsScreen> {
  final List<Map<String, dynamic>> _reviews = [
    {
      'id': 'rev_1',
      'author': 'Aarav Patel',
      'stay': 'Cozy City Room (Oct 2026)',
      'rating': 5.0,
      'comment': 'Check-in with WhatsApp door PIN was smooth and instant. The AC was chilling and high-speed Wi-Fi worked great for work.',
      'ownerReply': 'Thank you Aarav! Looking forward to welcoming you back to Shukla Stays.',
    },
    {
      'id': 'rev_2',
      'author': 'Priya Sharma',
      'stay': 'Modern Comfort Stay (Sep 2026)',
      'rating': 4.8,
      'comment': 'Clean room, quiet street, and zero broker interference. Loved the direct digital pass.',
      'ownerReply': null,
    },
    {
      'id': 'rev_3',
      'author': 'Vikram Verma',
      'stay': 'Cozy City Room (Aug 2026)',
      'rating': 4.5,
      'comment': 'Geyser took about 10 minutes to heat up, but otherwise great stay and peaceful area.',
      'ownerReply': 'Thanks Vikram! We serviced the water heater immediately after your feedback.',
    },
  ];

  void _openReplyDialog(int index) {
    final controller = TextEditingController(text: _reviews[index]['ownerReply']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reply as Host', style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Responding to ${_reviews[index]['author']}', style: const TextStyle(color: muted, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: textWhite, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Write a polite, professional reply...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lime, foregroundColor: navy),
            onPressed: () {
              setState(() {
                _reviews[index]['ownerReply'] = controller.text.trim();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reply published on room listing!')),
              );
            },
            child: const Text('Post Public Reply'),
          ),
        ],
      ),
    );
  }

  void _reportReview(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Report Review for Audit', style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'My Roomy audits reported reviews for spam, profanity, or policy violations. If verified false or malicious, the review will be removed.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: coral, foregroundColor: textWhite),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted. Operations desk will audit within 24 hours.')),
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
    return Scaffold(
      backgroundColor: navy,
      appBar: const AppHeader(
        title: 'Guest Reviews & Ratings',
        subtitle: 'Average 4.8★ across all properties',
        showBack: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _reviews.length,
          itemBuilder: (context, i) {
            final r = _reviews[i];
            final hasReply = r['ownerReply'] != null && (r['ownerReply'] as String).isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['author'] as String, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(r['stay'] as String, style: const TextStyle(color: muted, fontSize: 11)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: lime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: lime, size: 14),
                            const SizedBox(width: 4),
                            Text('${r['rating']}', style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(r['comment'] as String, style: const TextStyle(color: textWhite, fontSize: 13, height: 1.4)),

                  if (hasReply) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: lime.withValues(alpha: 0.2))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.reply_rounded, color: lime, size: 14),
                              SizedBox(width: 6),
                              Text('Host Response', style: TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(r['ownerReply'] as String, style: const TextStyle(color: textWhite, fontSize: 12, height: 1.3)),
                        ],
                      ),
                    ),
                  ],

                  const Divider(color: Colors.white10, height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: muted),
                        onPressed: () => _reportReview(i),
                        icon: const Icon(Icons.flag_outlined, size: 14),
                        label: const Text('Report', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: surfaceLight, foregroundColor: lime),
                        onPressed: () => _openReplyDialog(i),
                        icon: const Icon(Icons.reply_rounded, size: 14),
                        label: Text(hasReply ? 'Edit Reply' : 'Reply', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
