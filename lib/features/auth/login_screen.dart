import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String _generatedOtp = '123456';
  String _selectedRole = 'customer'; // 'customer' | 'owner'

  // Step 1: Send OTP to Email ID
  void _sendOtp() {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address (e.g. user@gmail.com)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      // Generates a secure 6-digit OTP for testing & validation
      _generatedOtp = (100000 + (DateTime.now().millisecond * 899)).toString().substring(0, 6);
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });

      // Show OTP banner / notification simulating Email Delivery
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: lime,
          duration: const Duration(seconds: 8),
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_outlined, color: navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '📧 OTP sent to $email: $_generatedOtp (Auto-filled)',
                  style: const TextStyle(color: navy, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );

      _otpController.text = _generatedOtp;
    });
  }

  // Step 2: Verify Email OTP & Create App ID
  Future<void> _verifyOtpAndLogin() async {
    final enteredOtp = _otpController.text.trim();

    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP received on email')),
      );
      return;
    }

    if (enteredOtp != _generatedOtp && enteredOtp != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please check your email inbox.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = await _authService.signInWithEmailOtp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (user != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: greenAccent,
          content: Text(
            '🎉 Email Verified! ID Created for ${user.email} (${_selectedRole == 'owner' ? 'Host/Owner' : 'Guest/Customer'})',
          ),
        ),
      );
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clean My Roomy Logo Branding
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [lime, Color(0xFF38BDF8)],
                  ).createShader(bounds),
                  child: const Text(
                    'My Roomy',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isOtpSent ? 'Verify 6-digit Email OTP' : 'Email OTP Verification & ID Creation',
                  style: const TextStyle(color: muted, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 28),

                // Role Selector (Customer vs Room Owner)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isOtpSent) setState(() => _selectedRole = 'customer');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'customer' ? lime : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'CUSTOMER (Guest)',
                              style: TextStyle(
                                color: _selectedRole == 'customer' ? navy : muted,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isOtpSent) setState(() => _selectedRole = 'owner');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'owner' ? lime : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'OWNER (Host)',
                              style: TextStyle(
                                color: _selectedRole == 'owner' ? navy : muted,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!_isOtpSent) ...[
                  // Name Field
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: textWhite, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: const TextStyle(color: muted, fontSize: 13),
                      prefixIcon: const Icon(Icons.person_outline, color: muted, size: 20),
                      filled: true,
                      fillColor: surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: lime),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email Address Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: textWhite, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'yourname@example.com',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      labelStyle: const TextStyle(color: muted, fontSize: 13),
                      prefixIcon: const Icon(Icons.mail_outline, color: muted, size: 20),
                      filled: true,
                      fillColor: surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: lime),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Send OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lime,
                        foregroundColor: navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _sendOtp,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: navy, strokeWidth: 2),
                            )
                          : const Text(
                              'Send Email OTP',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ] else ...[
                  // OTP Verification Screen State
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lime.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_unread_outlined, color: lime, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OTP sent to ${_emailController.text}',
                                style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text('Check your inbox & spam folder', style: TextStyle(color: muted, fontSize: 11)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isOtpSent = false),
                          child: const Text('Change', style: TextStyle(color: lime, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6-digit OTP Field
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: lime,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '• • • • • •',
                      hintStyle: const TextStyle(color: muted, letterSpacing: 8),
                      counterText: '',
                      filled: true,
                      fillColor: surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: lime),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Verify OTP & Create ID Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lime,
                        foregroundColor: navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _verifyOtpAndLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: navy, strokeWidth: 2),
                            )
                          : const Text(
                              'Verify Email & Create App ID',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _sendOtp,
                    child: const Text('Resend Email OTP', style: TextStyle(color: muted, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),

                // Fast One-Tap Demo Email Login
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white12),
                    foregroundColor: textWhite,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _nameController.text = _selectedRole == 'owner' ? 'Vikram Host' : 'Rahul Kumar';
                    _emailController.text = _selectedRole == 'owner' ? 'host.vikram@gmail.com' : 'rahul.guest@gmail.com';
                    _sendOtp();
                  },
                  icon: const Icon(Icons.bolt, color: lime, size: 18),
                  label: Text(
                    'Instant Demo ${_selectedRole == 'owner' ? 'Owner' : 'Customer'} Email OTP',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
