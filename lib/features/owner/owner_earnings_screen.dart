import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class OwnerEarningsScreen extends StatelessWidget {
  const OwnerEarningsScreen({super.key});

  final List<Map<String, dynamic>> _payoutHistory = const [
    {
      'id': 'PO_98210923',
      'date': '24 Oct 2026',
      'guest': 'Aarav Patel (Booking #RW8291024)',
      'gross': 1598,
      'fee': 0, // Zero brokerage
      'net': 1598,
      'status': 'SETTLED',
      'bank': 'HDFC Bank •••• 9283',
    },
    {
      'id': 'PO_87192019',
      'date': '18 Oct 2026',
      'guest': 'Priya Sharma (Booking #RW7319021)',
      'gross': 999,
      'fee': 0,
      'net': 999,
      'status': 'SETTLED',
      'bank': 'HDFC Bank •••• 9283',
    },
    {
      'id': 'PO_76120912',
      'date': '12 Oct 2026',
      'guest': 'Vikram Verma (Booking #RW6190281)',
      'gross': 2397,
      'fee': 0,
      'net': 2397,
      'status': 'SETTLED',
      'bank': 'HDFC Bank •••• 9283',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const totalEarnings = 4994;
    const pendingEscrow = 1598;

    return Scaffold(
      backgroundColor: navy,
      appBar: const AppHeader(
        title: 'Earnings & Escrow Payouts',
        subtitle: 'Direct bank settlement within 24h of check-in',
        showBack: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Revenue Snapshot Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: lime.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL LIFETIME EARNINGS', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  const Text(
                    '₹$totalEarnings',
                    style: TextStyle(color: textWhite, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: surfaceLight, borderRadius: BorderRadius.circular(10)),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pending Escrow', style: TextStyle(color: muted, fontSize: 11)),
                              SizedBox(height: 4),
                              Text('₹$pendingEscrow', style: TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: surfaceLight, borderRadius: BorderRadius.circular(10)),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Platform Brokerage', style: TextStyle(color: muted, fontSize: 11)),
                              SizedBox(height: 4),
                              Text('₹0 (0% Fee)', style: TextStyle(color: greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payout Destination Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_rounded, color: lime, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verified Payout Account', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('HDFC Bank (A/C ending in •••• 9283)', style: TextStyle(color: muted, fontSize: 11)),
                        Text('Auto-settlement active via IMPS / NEFT', style: TextStyle(color: greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('SETTLED ESCROW PAYOUTS', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            ..._payoutHistory.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                          Text(p['id'] as String, style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: greenAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text(p['status'] as String, style: const TextStyle(color: greenAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(p['guest'] as String, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Processed on ${p['date']} to ${p['bank']}', style: const TextStyle(color: muted, fontSize: 11)),
                      const Divider(color: Colors.white10, height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Net Payout (0% Commission)', style: TextStyle(color: muted, fontSize: 12)),
                          Text('₹${p['net']}', style: const TextStyle(color: textWhite, fontWeight: FontWeight.w900, fontSize: 15)),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
