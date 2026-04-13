import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _pendingUsers = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get pendingUsers => _pendingUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPendingUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/auth/pending-users');
      if (response != null && response is List) {
        _pendingUsers = response;
      } else {
        _pendingUsers = [];
      }
    } catch (e) {
      _error = e.toString();
      _pendingUsers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> approveUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/approve/$userId', body: {});
      await fetchPendingUsers(); // Refresh list
      return {'success': true, 'message': response['message'] ?? 'Utilisateur approuvé'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur lors de l\'approbation: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> rejectUser(String userId, {String? reason}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/reject/$userId', body: {'reason': reason});
      await fetchPendingUsers(); // Refresh list
      return {'success': true, 'message': response['message'] ?? 'Utilisateur rejeté'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur lors du rejet: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
