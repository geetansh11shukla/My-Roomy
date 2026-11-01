import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

enum UserRole {
  customer,
  owner,
  admin,
}

enum VerificationState {
  notStarted,
  pending,
  verified,
  rejected,
}

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  factory AppState() => instance;
  AppState._internal();

  UserModel? _currentUser = const UserModel(
    uid: 'usr_rahul_1',
    name: 'Rahul Kumar',
    phone: '+91 9876543210',
    email: 'rahul.k@roomwala.in',
    role: 'customer',
    verificationStatus: 'verified',
    age: 24,
    idType: 'Aadhaar Card',
    idNumber: '8834 9102 3341',
    createdAt: null,
  );

  bool _isAuthenticated = true;
  UserRole _currentRole = UserRole.customer;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  UserRole get currentRole => _currentRole;
  bool get isOwner => _currentRole == UserRole.owner;
  bool get isCustomer => _currentRole == UserRole.customer;
  bool get isVerified => _currentUser?.verificationStatus == 'verified';

  void setRole(UserRole role) {
    if (_currentRole != role) {
      _currentRole = role;
      notifyListeners();
    }
  }

  void toggleRole() {
    _currentRole = (_currentRole == UserRole.customer) ? UserRole.owner : UserRole.customer;
    notifyListeners();
  }

  void login({required UserModel user, required UserRole role}) {
    _currentUser = user;
    _isAuthenticated = true;
    _currentRole = role;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    _currentRole = UserRole.customer;
    notifyListeners();
  }

  void updateVerificationStatus(String status) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        email: _currentUser!.email,
        role: _currentUser!.role,
        verificationStatus: status,
        age: _currentUser!.age,
        idType: _currentUser!.idType,
        idNumber: _currentUser!.idNumber,
        createdAt: _currentUser!.createdAt,
      );
      notifyListeners();
    }
  }
}
