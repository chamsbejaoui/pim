import 'package:flutter/foundation.dart';

class AdminUser {
  AdminUser({required this.name, required this.email, required this.password});

  String name;
  String email;
  String password;
}

class AdminAuthService extends ChangeNotifier {
  AdminAuthService._();
  static final AdminAuthService instance = AdminAuthService._();

  final List<AdminUser> _users = [
    AdminUser(
      name: 'Global Admin',
      email: 'admin@odin.local',
      password: 'ChangeMe123!',
    ),
  ];

  AdminUser? _currentUser;
  String? _error;

  AdminUser? get currentUser => _currentUser;
  String? get error => _error;

  bool login(String email, String password) {
    AdminUser? user;
    for (final candidate in _users) {
      if (candidate.email.toLowerCase() == email.toLowerCase()) {
        user = candidate;
        break;
      }
    }
    if (user == null || user.password != password) {
      _error = 'Invalid admin credentials';
      notifyListeners();
      return false;
    }
    _error = null;
    _currentUser = user;
    notifyListeners();
    return true;
  }

  bool register(String name, String email, String password) {
    final exists = _users.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (exists) {
      _error = 'Admin email already exists';
      notifyListeners();
      return false;
    }

    _users.add(
      AdminUser(name: name, email: email.toLowerCase(), password: password),
    );
    _error = null;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
