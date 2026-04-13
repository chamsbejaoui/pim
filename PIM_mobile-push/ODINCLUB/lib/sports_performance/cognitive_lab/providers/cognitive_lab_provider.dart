import 'package:flutter/material.dart';
import '../models/cognitive_session.dart';
import '../services/cognitive_lab_service.dart';
import '../../services/api_client.dart';

class CognitiveLabProvider with ChangeNotifier {
  final CognitiveLabService _service = CognitiveLabService(ApiClient());

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CognitiveSession? _latestSession;
  CognitiveSession? get latestSession => _latestSession;

  Map<String, dynamic>? _baseline;
  Map<String, dynamic>? get baseline => _baseline;

  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> get history => _history;

  Map<String, dynamic> _squadSummary = {};
  Map<String, dynamic> get squadSummary => _squadSummary;

  List<dynamic> _atRiskPlayers = [];
  List<dynamic> get atRiskPlayers => _atRiskPlayers;

  List<dynamic> _allSessions = [];
  List<dynamic> get allSessions => _allSessions;

  Future<void> fetchDashboard(String playerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _service.getDashboard(playerId);

      if (data['latestSession'] != null) {
        final sessionMap = Map<String, dynamic>.from(data['latestSession']);
        sessionMap['playerInfo'] = data['playerInfo']; // Inject identities
        _latestSession = CognitiveSession.fromJson(sessionMap);
      } else if (data['playerInfo'] != null) {
        // Skeleton session for new players
        _latestSession = CognitiveSession.fromJson({
          'playerId': playerId,
          'playerInfo': data['playerInfo'],
        });
      } else {
        _latestSession = null;
      }

      _baseline = data['baseline'];
      if (data['history'] != null) {
        _history = List<Map<String, dynamic>>.from(data['history']);
      }
    } catch (e) {
      print('Error fetching dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSquadOverview() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _service.getSquadOverview();
      _squadSummary = data['summary'] ?? {};
      _atRiskPlayers = data['atRiskPlayers'] ?? [];
      _allSessions = data['allSessions'] ?? [];
    } catch (e) {
      print('Error fetching squad overview: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CognitiveSession?> submitSession(Map<String, dynamic> sessionData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = await _service.createSession(sessionData);

      // Update local state immediately with the result
      _latestSession = session;

      // Also trigger a full refresh to get baseline and history updated
      await fetchDashboard(sessionData['playerId']);

      return session;
    } catch (e) {
      print('Error submitting session: $e');
      rethrow; // Rethrow to let UI handle the error message
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
