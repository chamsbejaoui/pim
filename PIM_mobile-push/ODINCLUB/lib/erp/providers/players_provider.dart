import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/player.dart';

class PlayersProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Player> _players = [];
  Player? _selectedPlayer;
  List<PlayerHistory> _history = [];
  bool _isLoading = false;
  String? _error;
  int _totalCount = 0;

  List<Player> get players => _players;
  Player? get selectedPlayer => _selectedPlayer;
  List<PlayerHistory> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;

  void selectPlayer(Player? p) {
    _selectedPlayer = p;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }

  Future<void> fetchPlayers({String? status, String? position, bool? isProspect}) async {
    _setLoading(true);
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (position != null) queryParams['position'] = position;
      if (isProspect != null) queryParams['isProspect'] = isProspect.toString();

      final data = await _api.get('/players', queryParams: queryParams);

      if (data is Map && data['data'] != null) {
        final nestedData = data['data'];
        if (nestedData is Map && nestedData['players'] != null) {
          _players = (nestedData['players'] as List)
              .map((j) => Player.fromJson(j))
              .toList();
          _totalCount = nestedData['pagination']?['total'] ?? _players.length;
        } else if (nestedData is List) {
          _players = nestedData.map((j) => Player.fromJson(j)).toList();
          _totalCount = data['total'] ?? _players.length;
        }
      } else if (data is List) {
        _players = data.map((j) => Player.fromJson(j)).toList();
        _totalCount = _players.length;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur lors du chargement des joueurs';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPlayer(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/players/$id');
      if (data is Map && data['data'] != null) {
        _selectedPlayer = Player.fromJson(data['data']);
      } else {
        _selectedPlayer = Player.fromJson(data);
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur lors du chargement du joueur';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPlayer(Map<String, dynamic> playerData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/players', body: playerData);
      await fetchPlayers();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur inattendue: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePlayer(String id, Map<String, dynamic> playerData) async {
    try {
      await _api.put('/players/$id', body: playerData);
      await fetchPlayers();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePlayer(String id) async {
    try {
      await _api.delete('/players/$id');
      _players.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status, {String? description}) async {
    try {
      await _api.patch('/players/$id/status', body: {
        'status': status,
        if (description != null) 'description': description,
      });
      await fetchPlayer(id);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchHistory(String playerId) async {
    try {
      final data = await _api.get('/players/$playerId/history');
      if (data is List) {
        _history = data.map((h) => PlayerHistory.fromJson(h)).toList();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> assignTeam(String playerId, String teamId) async {
    try {
      await _api.post('/players/$playerId/assign-team', body: {
        'teamId': teamId,
      });
      await fetchPlayer(playerId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
