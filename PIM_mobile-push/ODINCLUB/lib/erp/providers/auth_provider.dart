import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  /// Try to restore session from stored token
  Future<bool> tryAutoLogin() async {
    final hasToken = await _api.hasToken();
    if (!hasToken) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        _user = User.fromJson(jsonDecode(userData));
        notifyListeners();
        return true;
      }

      // Try to fetch profile if we have token but no cached user
      final data = await _api.get('/auth/me');
      _user = User.fromJson(data);
      await _cacheUser();
      notifyListeners();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.post('/auth/login', body: {
        'email': email,
        'password': password,
      }, auth: false);

      await _api.saveTokens(data['accessToken']);

      _user = User.fromJson(data['user']);
      await _cacheUser();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Impossible de se connecter au serveur';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
    required String role,
    required String clubId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.post('/auth/register', body: {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'role': role,
        'clubId': clubId,
      }, auth: false);

      _isLoading = false;
      notifyListeners();
      return {'success': true, 'message': data['message'] ?? 'Inscription effectuée'};
    } on ApiException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return {'success': false, 'message': e.message};
    } catch (e) {
      _isLoading = false;
      _error = 'Impossible de se connecter au serveur';
      notifyListeners();
      return {'success': false, 'message': _error!};
    }
  }

  Future<void> logout() async {
    _user = null;
    await _api.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }

  Future<void> _cacheUser() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    }
  }
}
