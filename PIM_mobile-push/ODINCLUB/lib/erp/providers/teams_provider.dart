import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/team.dart';

class TeamsProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Team> _teams = [];
  bool _isLoading = false;
  String? _error;

  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTeams() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/teams');
      if (data is List) {
        _teams = data.map((t) => Team.fromJson(t)).toList();
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur lors du chargement des équipes';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTeam(String name, {String? categoryId}) async {
    try {
      await _api.post('/teams', body: {
        'name': name,
        if (categoryId != null) 'categoryId': categoryId,
      });
      await fetchTeams();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTeam(String id) async {
    try {
      await _api.delete('/teams/$id');
      _teams.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
