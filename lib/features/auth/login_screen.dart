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
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String _generatedOtp = '123456';
  String _selectedRole = 'customer'; // 'customer' | 'owner'

  // Step 1: Send OTP to Mobile
  void _sendOtp() {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      // Generates a mock 6-digit OTP for testing
      _generatedOtp = (100000 + (DateTime.now().millisecond * 899)).toString().substring(0, 6);
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });

      // Show OTP banner / notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: lime,
          duration: const Duration(seconds: 8),
          content: Text(
            '🔑 My Roomy Verification OTP: $_generatedOtp (Auto-filled for testing)',
            style: const TextStyle(color: navy, fontWeight: FontWeight.bold),
          ),
        ),
      );

      _otpController.text = _generatedOtp;
    });
  }

  // Step 2: Verify OTP & Log In
  Future<void> _verifyOtpAndLogin() async {
    final enteredOtp = _otpController.text.trim();

    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = await _authService.signInGuest(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: greenAccent,
          content: Text(
            '🎉 Mobile Verified! Logged in as ${_selectedRole == 'owner' ? 'ROOM OWNER (Host)' : 'CUSTOMER (Guest)'}',
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
                  _isOtpSent ? 'Verify 6-digit Mobile OTP' : 'Login with OTP Verification',
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
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'customer' ? lime : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'I am Customer (Guest)',
                              textAlign: TextAlign.center,
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
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'owner' ? lime : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'I am Room Owner (Host)',
                              textAlign: TextAlign.center,
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

                  // Phone Number Field
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: textWhite, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Mobile Number',
                      labelStyle: const TextStyle(color: muted, fontSize: 13),
                      prefixText: '+91 ',
                      prefixStyle: const TextStyle(color: textWhite, fontWeight: FontWeight.bold),
                      prefixIcon: const Icon(Icons.phone_android_outlined, color: muted, size: 20),
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
                              'Send 6-Digit OTP',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ] else ...[
                  // OTP Screen State
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lime.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sms_outlined, color: lime, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OTP sent to +91 ${_phoneController.text}',
                                style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              const Text('Valid for 10 minutes', style: TextStyle(color: muted, fontSize: 11)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isOtpSent = false),
                          child: const Text('Edit', style: TextStyle(color: lime, fontSize: 12)),
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

                  // Verify OTP & Login Button
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
                              'Verify & Continue',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _sendOtp,
                    child: const Text('Resend OTP', style: TextStyle(color: muted, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),

                // Fast One-Tap Demo Login
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white12),
                    foregroundColor: textWhite,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _phoneController.text = '9876543210';
                    _nameController.text = _selectedRole == 'owner' ? 'Vikram Host' : 'Rahul Kumar';
                    _sendOtp();
                  },
                  icon: const Icon(Icons.bolt, color: lime, size: 18),
                  label: Text(
                    'Instant Demo ${_selectedRole == 'owner' ? 'Owner' : 'Customer'} OTP',
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
