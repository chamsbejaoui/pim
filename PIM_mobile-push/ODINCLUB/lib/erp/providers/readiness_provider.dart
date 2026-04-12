import 'package:flutter/foundation.dart';
import '../core/api_service.dart';
import '../models/player_metrics.dart';
import '../models/readiness_result.dart';

class ReadinessProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<ReadinessResult> _results = [];
  bool _isAnalyzing = false;
  int _analyzedCount = 0;
  int _totalToAnalyze = 0;
  String? _error;
  String? _currentPlayerName;

  List<ReadinessResult> get results => _results;
  bool get isAnalyzing => _isAnalyzing;
  int get analyzedCount => _analyzedCount;
  int get totalToAnalyze => _totalToAnalyze;
  String? get error => _error;
  String? get currentPlayerName => _currentPlayerName;

  double get progress =>
      _totalToAnalyze == 0 ? 0 : _analyzedCount / _totalToAnalyze;

  // Average team score
  int get teamScore {
    if (_results.isEmpty) return 0;
    final sum = _results.fold<int>(0, (acc, r) => acc + r.score);
    return (sum / _results.length).round();
  }

  int get optimalCount => _results.where((r) => r.score >= 85).length;
  int get attentionCount =>
      _results.where((r) => r.score >= 60 && r.score < 85).length;
  int get riskCount => _results.where((r) => r.score < 60).length;

  // ─── Load cached results for a match date ─────────────────────────
  Future<void> loadCached(String matchDate) async {
    _isAnalyzing = false;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/ai/readiness/$matchDate');
      if (data is List) {
        _results = data.map((e) => ReadinessResult.fromJson(e)).toList();
        _results.sort((a, b) => b.score.compareTo(a.score));
      }
    } catch (e) {
      _error = 'Impossible de charger les données';
      debugPrint('ReadinessProvider.loadCached error: $e');
    }
    notifyListeners();
  }

  // ─── Analyze squad player by player ───────────────────────────────
  Future<void> analyzeSquad(List<PlayerMetrics> squad, String matchDate) async {
    _isAnalyzing = true;
    _analyzedCount = 0;
    _totalToAnalyze = squad.length;
    _results = [];
    _error = null;
    notifyListeners();

    for (final metrics in squad) {
      _currentPlayerName = metrics.playerName;
      notifyListeners();

      try {
        final payload = metrics.toJson();
        payload['matchDate'] = matchDate;

        final data = await _api.post('/ai/readiness', body: payload);
        if (data != null) {
          final result = ReadinessResult.fromJson(data as Map<String, dynamic>);
          _results.add(result);
          _results.sort((a, b) => b.score.compareTo(a.score));
        }
      } catch (e) {
        debugPrint('Failed to analyze ${metrics.playerName}: $e');
      }

      _analyzedCount++;
      notifyListeners();
    }

    _isAnalyzing = false;
    _currentPlayerName = null;
    notifyListeners();
  }

  // ─── Clear and re-analyze ─────────────────────────────────────────
  Future<void> clearResults(String matchDate) async {
    try {
      await _api.delete('/ai/readiness/$matchDate');
      _results = [];
      notifyListeners();
    } catch (_) {}
  }

  void reset() {
    _results = [];
    _isAnalyzing = false;
    _analyzedCount = 0;
    _totalToAnalyze = 0;
    _error = null;
    _currentPlayerName = null;
    notifyListeners();
  }
}
