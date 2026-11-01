import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // New Ticket Form
  String _selectedCategory = 'Booking & Door PIN Problem';
  final _bookingRefController = TextEditingController(text: 'RW8291024');
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Booking & Door PIN Problem',
    'Payment & Escrow Question',
    'Refund Processing Delay',
    'Identity Verification (KYC)',
    'Report Listing / Discrepancy',
    'Other Inquiries',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I access my room without an owner meeting?',
      'a': 'My Roomy stays feature 100% digital check-in. Once your booking and 18+ ID are verified, your unique 4-digit Door Access PIN and Google Maps navigation link are dispatched directly to your WhatsApp.',
    },
    {
      'q': 'What is the Stay Extension Priority?',
      'a': 'As the active guest, you receive first right of refusal to extend your stay before dates open to others. 24 hours prior to checkout, an extension card appears in your booking pass.',
    },
    {
      'q': 'When are cancellation refunds processed?',
      'a': 'Cancellations made 24 hours prior to check-in are eligible for a 100% full refund with zero cancellation penalty. Refunds are initiated instantly through the escrow gateway and settle within 24-48 hours.',
    },
    {
      'q': 'Why is Government ID verification mandatory?',
      'a': 'Hospitality regulations mandate guest verification to eliminate illegal subletting and ensure guest security. We only verify via DigiLocker / UIDAI offline tokens and never store unmasked scans.',
    },
  ];

  final List<Map<String, dynamic>> _ticketHistory = [
    {
      'id': 'TKT_1092',
      'subject': 'Extension priority date hold confirmation',
      'category': 'Booking & Door PIN Problem',
      'status': 'RESOLVED',
      'date': '24 Oct 2026',
      'response': 'Your stay dates have been updated in the system and your new checkout timeline has been synced.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bookingRefController.dispose();
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitTicket() async {
    if (_subjectController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject and problem description.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _ticketHistory.insert(0, {
        'id': 'TKT_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'subject': _subjectController.text.trim(),
        'category': _selectedCategory,
        'status': 'OPEN',
        'date': 'Today',
        'response': 'Support desk assigned. An operations officer will respond via WhatsApp within 30 minutes.',
      });
      _subjectController.clear();
      _descController.clear();
      _tabController.animateTo(2); // Switch to ticket history
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: greenAccent, content: Text('Support ticket submitted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text('Help & Support Desk', style: TextStyle(color: textWhite, fontWeight: FontWeight.bold)),
        backgroundColor: navy,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: lime,
          labelColor: lime,
          unselectedLabelColor: muted,
          tabs: const [
            Tab(text: 'FAQs'),
            Tab(text: 'Submit Ticket'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqView(),
          _buildSubmitTicketView(),
          _buildHistoryView(),
        ],
      ),
    );
  }

  Widget _buildFaqView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _faqs.length,
      itemBuilder: (context, i) {
        final faq = _faqs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: ExpansionTile(
            title: Text(faq['q']!, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
            iconColor: lime,
            collapsedIconColor: muted,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(faq['a']!, style: const TextStyle(color: muted, fontSize: 13, height: 1.4)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitTicketView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category', style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                dropdownColor: surface,
                isExpanded: true,
                style: const TextStyle(color: textWhite, fontSize: 13),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          _buildField('Related Booking Reference (Optional)', _bookingRefController, 'e.g. RW8291024'),
          const SizedBox(height: 14),
          _buildField('Subject', _subjectController, 'Brief description of issue'),
          const SizedBox(height: 14),
          _buildField('Detailed Description', _descController, 'Explain in detail what happened...', maxLines: 4),
          const SizedBox(height: 24),

          AppButton(
            label: 'Submit Support Ticket',
            isLoading: _isSubmitting,
            onPressed: _submitTicket,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_ticketHistory.isEmpty) {
      return const Center(child: Text('No support tickets submitted yet.', style: TextStyle(color: muted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _ticketHistory.length,
      itemBuilder: (context, i) {
        final t = _ticketHistory[i];
        final isResolved = t['status'] == 'RESOLVED';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t['id'] as String, style: const TextStyle(color: lime, fontWeight: FontWeight.bold, fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isResolved ? greenAccent.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t['status'] as String,
                      style: TextStyle(color: isResolved ? greenAccent : Colors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(t['subject'] as String, style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text('${t['category']} • ${t['date']}', style: const TextStyle(color: muted, fontSize: 11)),
              const Divider(color: Colors.white10, height: 20),

              Text('Support Desk Response:', style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(t['response'] as String, style: const TextStyle(color: muted, fontSize: 12, height: 1.3)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: textWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
