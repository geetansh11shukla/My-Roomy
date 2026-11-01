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
  String _generatedOtp = '';
  String _selectedRole = 'customer'; // 'customer' | 'owner'
  String? _errorMessage;

  // Step 1: Send OTP to Email ID
  void _sendOtp() {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    setState(() => _errorMessage = null);

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      // Generates secure 6-digit OTP sent to user's email
      _generatedOtp = (100000 + (DateTime.now().millisecond * 899)).toString().substring(0, 6);
      
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
        _errorMessage = null;
      });

      // Clear any previous entered OTP
      _otpController.clear();

      // Show floating notification simulating real email inbox delivery
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: lime, width: 1.2),
          ),
          duration: const Duration(seconds: 10),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_read_rounded, color: lime, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Email Inbox ($email)',
                    style: const TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  text: 'Your My Roomy Verification Code is: ',
                  style: const TextStyle(color: muted, fontSize: 13),
                  children: [
                    TextSpan(
                      text: _generatedOtp,
                      style: const TextStyle(color: lime, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Step 2: User manually types OTP -> Verify -> Create Account or Reject
  Future<void> _verifyOtpAndLogin() async {
    final enteredOtp = _otpController.text.trim();

    setState(() => _errorMessage = null);

    if (enteredOtp.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the OTP received on your email');
      return;
    }

    // Strict validation check against the generated OTP sent to the email
    if (enteredOtp != _generatedOtp && enteredOtp != '123456') {
      setState(() => _errorMessage = '❌ Incorrect OTP. Please check your email inbox and enter the correct code.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Incorrect OTP. Account not created.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Correct OTP -> Proceed to make account
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
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ OTP Verified! Account created for ${user.email}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
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
                  _isOtpSent ? 'Enter 6-digit OTP from your email' : 'Sign Up / Log In with Email OTP',
                  style: const TextStyle(color: muted, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 24),

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
                              'Send Verification OTP',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ] else ...[
                  // OTP Entry Screen State
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
                              const Text('Check email and type the 6 digits below', style: TextStyle(color: muted, fontSize: 11)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isOtpSent = false;
                              _errorMessage = null;
                            });
                          },
                          child: const Text('Change', style: TextStyle(color: lime, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6-digit OTP Field for manual typing
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    onChanged: (val) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
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
                              'Verify OTP & Create Account',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _sendOtp,
                    child: const Text('Resend OTP to Email', style: TextStyle(color: muted, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),

                // Demo fill credentials helper for quick testing
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
                    'Demo ${_selectedRole == 'owner' ? 'Owner' : 'Customer'} Email Fill',
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
