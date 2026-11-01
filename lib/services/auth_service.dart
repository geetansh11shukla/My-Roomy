import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Sign in anonymously or with phone/credentials
  Future<UserModel?> signInGuest({required String name, required String phone}) async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      final uid = userCredential.user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

      final userModel = UserModel(
        uid: uid,
        name: name,
        phone: phone,
        role: 'customer',
        verificationStatus: 'verified',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap(), SetOptions(merge: true));
      return userModel;
    } catch (e) {
      debugPrint('Auth Error: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
