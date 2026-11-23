import 'package:flutter/material.dart';

import 'package:room_wala/core/theme/app_theme.dart';
import 'package:room_wala/core/services/app_state.dart';
import 'package:room_wala/main.dart' hide navy, lime, surface, surfaceLight, muted;
import 'package:room_wala/models/user_model.dart';
import 'package:room_wala/services/auth_service.dart';
import 'package:room_wala/features/owner/owner_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isSignUpMode = false; // false = Login with Password, true = Register (OTP + Password)
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'customer'; // 'customer' | 'owner'
  String? _errorMessage;

  // Login using Email and Password
  Future<void> _loginWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _errorMessage = null);

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    final res = await _authService.loginWithPassword(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final user = res['user'] as UserModel?;
      if (user != null) {
        final role = user.role == 'owner' ? UserRole.owner : UserRole.customer;
        AppState.instance.login(user: user, role: role);
      }

      // Navigate to destination
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => _selectedRole == 'owner'
              ? const OwnerDashboardScreen()
              : const HomeScreen(),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = res['error'] ?? 'Login failed. Please check your details.';
      });
    }
  }

  // Step 1 of Sign Up: Send Real OTP to Email via Backend Gmail SMTP
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;

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

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    final res = await _authService.requestEmailOtp(
      email: email,
      name: name,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _isOtpSent = true;
        _errorMessage = null;
      });
      _otpController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: lime, width: 1.2),
          ),
          duration: const Duration(seconds: 8),
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: lime, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verification code sent to $email. Please check your Gmail app.',
                  style: const TextStyle(
                    color: textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = res['error'] ?? 'Could not send verification email.';
      });
    }
  }

  // Step 2 of Sign Up: Verify OTP -> Save Account & Password
  Future<void> _verifyOtpAndLogin() async {
    final enteredOtp = _otpController.text.trim();

    setState(() => _errorMessage = null);

    if (enteredOtp.length != 6) {
      setState(
        () => _errorMessage =
            'Please enter all 6 digits of the OTP received on your email',
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await _authService.verifyEmailOtp(
      email: _emailController.text.trim(),
      otp: enteredOtp,
      name: _nameController.text.trim(),
      role: _selectedRole,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      // 1. Update global AppState with created/verified account
      final user = res['user'] as UserModel?;
      if (user != null) {
        final role = _selectedRole == 'owner'
            ? UserRole.owner
            : UserRole.customer;
        AppState.instance.login(user: user, role: role);
      }

      // 2. Show big success confirmation dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: lime, width: 1.5),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: lime, size: 28),
              SizedBox(width: 10),
              Text(
                'Account Created!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${_nameController.text.trim()}!',
                style: const TextStyle(
                  color: lime,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your email (${_emailController.text.trim()}) was successfully verified via OTP.',
                style: const TextStyle(color: muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: lime, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Account Type: ${_selectedRole.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                // Navigate into the main app experience
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _selectedRole == 'owner'
                        ? const OwnerDashboardScreen()
                        : const HomeScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Continue to App ➔',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      // Server returned incorrect OTP
      final err =
          res['error'] ??
          '❌ Incorrect OTP. Please check your email inbox and enter the correct code.';
      setState(() => _errorMessage = err);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  err,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
                  shaderCallback: (bounds) =>
                      const LinearGradient(colors: [lime, Color(0xFF38BDF8)])
                          .createShader(bounds),
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
                  _isOtpSent
                      ? 'Enter 6-digit OTP from your email'
                      : (_isSignUpMode
                          ? 'Create Account with Password & Email OTP'
                          : 'Sign In to Your Account with Password'),
                  style: const TextStyle(
                    color: muted,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Switcher: Login vs Sign Up
                if (!_isOtpSent) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSignUpMode = false;
                                _errorMessage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isSignUpMode ? lime : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Log In',
                                style: TextStyle(
                                  color: !_isSignUpMode ? navy : muted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSignUpMode = true;
                                _errorMessage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isSignUpMode ? lime : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Create New ID',
                                style: TextStyle(
                                  color: _isSignUpMode ? navy : muted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
                            if (!_isOtpSent)
                              setState(() => _selectedRole = 'customer');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'customer'
                                  ? lime
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'CUSTOMER (Guest)',
                              style: TextStyle(
                                color: _selectedRole == 'customer'
                                    ? navy
                                    : muted,
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
                            if (!_isOtpSent)
                              setState(() => _selectedRole = 'owner');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'owner'
                                  ? lime
                                  : Colors.transparent,
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
                  // Name Field (Only in Sign Up mode)
                  if (_isSignUpMode) ...[
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: textWhite, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: const TextStyle(color: muted, fontSize: 13),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: muted,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                  ],

                  // Email Address Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: textWhite, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'yourname@example.com',
                      hintStyle: const TextStyle(
                        color: Colors.white24,
                        fontSize: 13,
                      ),
                      labelStyle: const TextStyle(color: muted, fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        color: muted,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: textWhite, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: _isSignUpMode ? 'Set New Password' : 'Password',
                      hintText: _isSignUpMode ? 'Min 6 characters' : 'Enter your password',
                      hintStyle: const TextStyle(
                        color: Colors.white24,
                        fontSize: 13,
                      ),
                      labelStyle: const TextStyle(color: muted, fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: muted,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: muted,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      filled: true,
                      fillColor: surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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

                  // Submit Button (Login with Password OR Send OTP to Create ID)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lime,
                        foregroundColor: navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading
                          ? null
                          : (_isSignUpMode ? _sendOtp : _loginWithPassword),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: navy,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isSignUpMode
                                  ? 'Verify Email & Create Account'
                                  : 'Log In with Password',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
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
                        const Icon(
                          Icons.mark_email_unread_outlined,
                          color: lime,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OTP sent to ${_emailController.text}',
                                style: const TextStyle(
                                  color: textWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Check email and type the 6 digits below',
                                style: TextStyle(color: muted, fontSize: 11),
                              ),
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
                          child: const Text(
                            'Change',
                            style: TextStyle(color: lime, fontSize: 12),
                          ),
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
                      hintStyle: const TextStyle(
                        color: muted,
                        letterSpacing: 8,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _verifyOtpAndLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: navy,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Verify OTP & Create Account',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _sendOtp,
                    child: const Text(
                      'Resend OTP to Email',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Demo fill credentials helper for quick testing
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white12),
                    foregroundColor: textWhite,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _nameController.text = _selectedRole == 'owner'
                        ? 'Vikram Host'
                        : 'Rahul Kumar';
                    _emailController.text = 'geetanshshukla11@gmail.com';
                    _sendOtp();
                  },
                  icon: const Icon(Icons.bolt, color: lime, size: 18),
                  label: Text(
                    'Quick Fill My Email (${_selectedRole == 'owner' ? 'Host' : 'Guest'})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
