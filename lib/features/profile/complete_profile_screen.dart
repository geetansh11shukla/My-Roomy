import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController(text: 'Rahul Sharma');
  final _emailController = TextEditingController(text: 'rahul.sharma@example.com');
  final _phoneController = TextEditingController(text: '9876543210');
  DateTime? _selectedDob = DateTime(1998, 5, 14);
  String _selectedLanguage = 'English';
  bool _isLoading = false;

  final List<String> _languages = [
    'English',
    'Hindi (हिंदी)',
    'Hinglish',
    'Punjabi (ਪੰਜਾਬੀ)',
    'Bengali (বাংলা)',
  ];

  void _saveProfile() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: greenAccent,
          content: Text('Profile updated successfully!'),
        ),
      );
      Navigator.pop(context);
    });
  }

  void _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18+ requirement
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: lime,
              onPrimary: navy,
              surface: surface,
              onSurface: textWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: const AppHeader(title: 'Complete Profile', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Photo with Camera Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: surfaceLight,
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: lime,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: navy, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Upload Government ID Verified Photo',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 28),

              // Full Name
              Align(
                alignment: Alignment.centerLeft,
                child: const Text('Full Legal Name', style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: textWhite, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.badge_outlined, color: muted, size: 20),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Details (Email)
              Align(
                alignment: Alignment.centerLeft,
                child: const Text('Email Address', style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: textWhite, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: muted, size: 20),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Details (Phone)
              Align(
                alignment: Alignment.centerLeft,
                child: const Text('WhatsApp Phone Number', style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                style: const TextStyle(color: textWhite, fontSize: 14),
                decoration: InputDecoration(
                  prefixText: '+91 ',
                  prefixStyle: const TextStyle(color: textWhite, fontWeight: FontWeight.bold),
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: muted, size: 20),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Date of Birth (18+ eligibility requirement)
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Date of Birth', style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: lime.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text('18+ Required', style: TextStyle(color: lime, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDob,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: muted, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDob != null
                            ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                            : 'Select Date of Birth',
                        style: const TextStyle(color: textWhite, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_rounded, color: lime, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preferred Language
              Align(
                alignment: Alignment.centerLeft,
                child: const Text('Preferred Language', style: TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    dropdownColor: surface,
                    style: const TextStyle(color: textWhite, fontSize: 14),
                    items: _languages.map((l) {
                      return DropdownMenuItem<String>(
                        value: l,
                        child: Text(l),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLanguage = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              AppButton(
                label: 'Save Profile Details',
                isLoading: _isLoading,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
