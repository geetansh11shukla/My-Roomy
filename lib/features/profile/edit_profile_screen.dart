import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_components.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhone;

  const EditProfileScreen({
    super.key,
    this.currentName = 'Rahul Kumar',
    this.currentEmail = 'rahul.kumar@example.com',
    this.currentPhone = '9876543210',
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);

    _nameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final changed = _nameController.text != widget.currentName ||
        _emailController.text != widget.currentEmail ||
        _phoneController.text != widget.currentPhone;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Unsaved Changes?', style: TextStyle(color: textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'You have made modifications to your profile. Leaving now will discard these updates.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing', style: TextStyle(color: muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: coral, foregroundColor: textWhite),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard Changes'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email address')));
      return;
    }
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit WhatsApp number')));
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _hasChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: greenAccent, content: Text('🎉 Profile changes saved successfully!')),
    );
    Navigator.pop(context, {
      'name': name,
      'email': email,
      'phone': phone,
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: navy,
        appBar: AppHeader(
          title: 'Edit Profile',
          subtitle: 'Update verified account details',
          showBack: true,
          onBack: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Avatar with Camera Overlay
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 46,
                      backgroundColor: surfaceLight,
                      child: Icon(Icons.person_rounded, size: 52, color: lime),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: lime, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: navy, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Tap to change profile picture', style: TextStyle(color: muted, fontSize: 11)),
                const SizedBox(height: 28),

                _buildInputField('Full Legal Name', _nameController, Icons.badge_outlined),
                const SizedBox(height: 16),
                _buildInputField('Email Address', _emailController, Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildInputField('WhatsApp Mobile Number', _phoneController, Icons.phone_android_rounded, prefix: '+91 ', keyboardType: TextInputType.phone),
                const SizedBox(height: 28),

                AppButton(
                  label: 'Save Changes',
                  isLoading: _isSaving,
                  onPressed: _hasChanges ? _saveProfile : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {String? prefix, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: textWhite, fontSize: 14),
          decoration: InputDecoration(
            prefixText: prefix,
            prefixStyle: const TextStyle(color: textWhite, fontWeight: FontWeight.bold),
            prefixIcon: Icon(icon, color: lime, size: 20),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
          ),
        ),
      ],
    );
  }
}
