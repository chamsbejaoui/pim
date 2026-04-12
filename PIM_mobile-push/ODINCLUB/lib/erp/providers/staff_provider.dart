import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/staff_member.dart';

class StaffProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<StaffMember> _staffList = [];
  StaffMember? _selectedStaff;
  bool _isLoading = false;
  String? _error;

  List<StaffMember> get staffList => _staffList;
  StaffMember? get selectedStaff => _selectedStaff;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void selectStaff(StaffMember? s) {
    _selectedStaff = s;
    notifyListeners();
  }

  Future<void> fetchStaff({String? role, String? teamId, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (role != null) params['role'] = role;
      if (teamId != null) params['teamId'] = teamId;
      if (status != null) params['status'] = status;

      final data = await _api.get('/staff', queryParams: params.isNotEmpty ? params : null);
      if (data is Map && data['data'] != null && data['data']['staff'] != null) {
        _staffList = (data['data']['staff'] as List).map((s) => StaffMember.fromJson(s)).toList();
      } else if (data is List) {
        _staffList = data.map((s) => StaffMember.fromJson(s)).toList();
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur lors du chargement du staff';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStaffMember(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/staff/$id');
      if (data is Map && data['data'] != null) {
        _selectedStaff = StaffMember.fromJson(data['data']);
      } else {
        _selectedStaff = StaffMember.fromJson(data);
      }
    } catch (e) {
      _error = 'Erreur lors du chargement';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStaff(Map<String, dynamic> staffData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/staff', body: staffData);
      await fetchStaff();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStaff(String id, Map<String, dynamic> staffData) async {
    try {
      await _api.put('/staff/$id', body: staffData);
      await fetchStaff();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStaff(String id) async {
    try {
      await _api.delete('/staff/$id');
      _staffList.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
