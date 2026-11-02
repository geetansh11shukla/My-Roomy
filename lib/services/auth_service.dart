import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Points to local running backend on clean port 5050
  static const String _backendBaseUrl = 'http://localhost:5050';

  User? get currentUser => _auth.currentUser;

  /// 1. Send Real OTP to user's Email via Gmail SMTP
  Future<Map<String, dynamic>> requestEmailOtp({required String email, required String name}) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'name': name}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'OTP sent to your email'};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Could not send verification code.'};
      }
    } catch (e) {
      debugPrint('[AuthService] Backend requestEmailOtp error: $e');
      return {'success': false, 'error': 'Could not connect to authentication server. Check connection.'};
    }
  }

  /// 2. Verify OTP with Server & Activate App Account
  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
    required String name,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'name': name,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        String uid = 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        try {
          UserCredential userCredential = await _auth.signInAnonymously();
          if (userCredential.user?.uid != null) {
            uid = userCredential.user!.uid;
          }
        } catch (authErr) {
          debugPrint('[AuthService] FirebaseAuth anonymous signin fallback: $authErr');
        }

        final userModel = UserModel(
          uid: uid,
          fullName: name,
          email: email,
          phoneNumber: '+91 9876543210',
          role: role,
          identityVerificationStatus: 'verified',
          createdAt: DateTime.now(),
        );

        try {
          await _firestore.collection('users').doc(uid).set(userModel.toMap(), SetOptions(merge: true));
        } catch (_) {}

        return {'success': true, 'user': userModel};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Incorrect OTP. Please check your email inbox and enter the 6-digit code.',
        };
      }
    } catch (e) {
      debugPrint('[AuthService] Backend verifyEmailOtp error: $e');
      return {'success': false, 'error': 'Could not verify code with server: $e'};
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
