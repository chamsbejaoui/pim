import 'package:flutter/material.dart';
import '../models/ai_player.dart';
import '../services/ai_api_service.dart';
import '../services/ai_scouting_bridge.dart';
import '../sports_performance/models/event_player.dart';

/// Central state management for the AI scouting campaign.
/// Manages players, AI enrichment, selection, training, and archiving.
class CampaignProvider extends ChangeNotifier {
  // ─── State ─────────────────────────────────────────────────
  List<AiPlayer> _players = [];
  List<AiPlayer> _archivedPlayers = [];
  final Set<String> _selectedPlayerIds = {};
  bool _isLoading = false;
  String? _error;
  int _activeTabIndex = 0;
  bool _aiOnline = false;
  Map<String, dynamic> _aiMetrics = {};
  Map<String, dynamic> _aiStatus = {};
  /// True when players were pre-loaded from an event (skip API fetch in initialize())
  bool _preLoaded = false;

  // ─── Getters ───────────────────────────────────────────────
  List<AiPlayer> get players => _players;
  List<AiPlayer> get archivedPlayers => _archivedPlayers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null && _error!.isNotEmpty;
  int get activeTabIndex => _activeTabIndex;
  bool get aiOnline => _aiOnline;
  Map<String, dynamic> get aiMetrics => _aiMetrics;
  Map<String, dynamic> get aiStatus => _aiStatus;

  int get selectedCount => _selectedPlayerIds.length;
  bool isSelected(AiPlayer player) =>
      _selectedPlayerIds.contains(player.id ?? player.name);

  List<AiPlayer> get selectedPlayers => _players
      .where((p) => _selectedPlayerIds.contains(p.id ?? p.name))
      .toList();

  AiPlayer? get topAiSuggestion {
    if (_players.isEmpty) return null;
    final withScore =
        _players.where((p) => (p.matchPercentage ?? 0) > 0).toList();
    if (withScore.isEmpty) return null;
    withScore.sort(
        (a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));
    return withScore.first;
  }

  // ─── Actions ───────────────────────────────────────────────

  Future<void> initialize() async {
    // Skip loadPlayers() if we were already pre-loaded from an event
    if (!_preLoaded) {
      await loadPlayers();
    }
    await loadArchivedPlayers();
    await _checkAiHealth();
    await loadAiMetrics();
  }

  Future<void> _checkAiHealth() async {
    _aiOnline = await AiApiService.healthCheck();
    notifyListeners();
  }

  Future<void> loadPlayers() async {
    // If pre-loaded from event, re-enrich existing players instead of wiping them
    if (_preLoaded) {
      await _enrichPlayersWithAi(_players);
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiPlayers = await AiApiService.fetchPlayers();

      if (apiPlayers.isEmpty) {
        _players = [];
      } else {
        _players = apiPlayers;
        await _enrichPlayersWithAi(_players);
      }
    } catch (e) {
      _error = 'Failed to load players: $e';
      _players = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadArchivedPlayers() async {
    try {
      _archivedPlayers = await AiApiService.fetchArchivedPlayers();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load archived players: $e');
    }
  }

  Future<void> _enrichPlayersWithAi(List<AiPlayer> playersList) async {
    final futures = playersList.map((p) async {
      try {
        final prediction = await AiApiService.predictPlayer(p);
        return p.copyWith(
          matchPercentage: prediction.confidence,
          shapExplanation: prediction.shapExplanation,
          clusterProfile: prediction.clusterProfile,
          aiRecommendation: prediction.decision,
        );
      } catch (e) {
        debugPrint('Failed to predict for ${p.name}: $e');
        return p;
      }
    });

    final enriched = await Future.wait(futures);
    _players = enriched;

    _players.sort((a, b) {
      final scoreA = a.matchPercentage ?? 0;
      final scoreB = b.matchPercentage ?? 0;
      return scoreB.compareTo(scoreA);
    });

    notifyListeners();
  }

  void togglePlayerSelection(AiPlayer player) {
    final key = player.id ?? player.name;
    if (_selectedPlayerIds.contains(key)) {
      _selectedPlayerIds.remove(key);
    } else {
      _selectedPlayerIds.add(key);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedPlayerIds.clear();
    notifyListeners();
  }

  void setActiveTab(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadAiMetrics() async {
    try {
      _aiMetrics = await AiApiService.getAiMetrics();
      _aiStatus = await AiApiService.getAiStatus();
      _aiOnline = await AiApiService.healthCheck();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> sendConvocation() async {
    final names = selectedPlayers.map((p) => p.name).join(', ');
    debugPrint('📩 Sending convocation to: $names');
  }

  Future<void> addPlayer(AiPlayer player) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await AiApiService.createPlayer(player);
      await loadPlayers();
    } catch (e) {
      _error = 'Error creating player: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlayers(List<AiPlayer> players) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      for (final player in players) {
        await AiApiService.createPlayer(player);
      }
      await loadPlayers();
    } catch (e) {
      _error = 'Error importing players: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlayer(AiPlayer player) async {
    final playerId = player.id;
    if (playerId == null) return;

    final index = _players.indexWhere((p) => p.id == playerId);
    AiPlayer? removedPlayer;
    if (index != -1) {
      removedPlayer = _players[index];
      _players.removeAt(index);
      _selectedPlayerIds.remove(playerId);
      notifyListeners();
    }

    try {
      await AiApiService.deletePlayer(playerId);
    } catch (e) {
      if (removedPlayer != null && index != -1) {
        _players.insert(index, removedPlayer);
        notifyListeners();
      }
      _error = 'Error deleting player: $e';
      notifyListeners();
    }
  }

  Future<void> recruitPlayer(AiPlayer player) async {
    try {
      final updatedPlayer = player.copyWith(label: 1);

      final index = _players
          .indexWhere((p) => p.id == player.id || p.name == player.name);
      if (index != -1) {
        _players[index] = updatedPlayer;
        notifyListeners();
      }

      if (player.id != null) {
        await AiApiService.updatePlayer(updatedPlayer);
      }

      await _autoRetrain();
    } catch (e) {
      debugPrint('Error recruiting player: $e');
    }
  }

  Future<void> skipPlayer(AiPlayer player) async {
    try {
      final updatedPlayer = player.copyWith(label: 0);

      final index = _players
          .indexWhere((p) => p.id == player.id || p.name == player.name);
      if (index != -1) {
        _players[index] = updatedPlayer;
        notifyListeners();
      }

      if (player.id != null) {
        await AiApiService.updatePlayer(updatedPlayer);
      }

      await _autoRetrain();
    } catch (e) {
      debugPrint('Error skipping player: $e');
    }
  }

  Future<void> _autoRetrain() async {
    try {
      final labeledPlayers = _players.where((p) => p.label != null).toList();
      if (labeledPlayers.isEmpty) return;

      debugPrint(
          '🔄 Auto-retraining model with ${labeledPlayers.length} labeled players...');
      await AiApiService.trainModel(labeledPlayers);
      debugPrint('✅ Model retrained successfully');

      await loadAiMetrics();
      await _enrichPlayersWithAi(_players);
    } catch (e) {
      debugPrint('⚠️ Auto-retrain failed: $e');
    }
  }

  Future<void> trainModel() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final labeledPlayers = _players.where((p) => p.label != null).toList();

      if (labeledPlayers.isEmpty) {
        throw Exception('Need at least 1 labeled player to train');
      }

      await AiApiService.trainModel(labeledPlayers);
      await loadAiMetrics();
      await loadPlayers();
    } catch (e) {
      _error = 'Training failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pre-populate the campaign with players from a closed SP event.
  /// Registers each player in the Python AI database so all AI insights work.
  Future<void> loadFromEventPlayers(List<EventPlayer> eventPlayers) async {
    _isLoading = true;
    _error = null;
    _preLoaded = true; // Prevent initialize() from overwriting these players
    notifyListeners();

    try {
      final List<AiPlayer> registered = [];

      for (final ep in eventPlayers) {
        try {
          // Convert to AiPlayer using bridge
          final local = AiScoutingBridge.fromEventPlayer(ep);

          // Register in Python AI database to get a real ID
          final created = await AiApiService.createPlayer(local);
          registered.add(created);
        } catch (_) {
          // If creation fails (e.g. duplicate), still add local version
          registered.add(AiScoutingBridge.fromEventPlayer(ep));
        }
      }

      // Enrich with AI prediction scores (also sets _players + notifyListeners)
      await _enrichPlayersWithAi(registered);

    } catch (e) {
      _error = 'Error loading event players: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Session Management ────────────────────────────────────

  Future<void> endSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final toArchive = _players.where((p) => p.label != 1).toList();
      final toArchiveIds =
          toArchive.where((p) => p.id != null).map((p) => p.id!).toList();

      if (toArchiveIds.isNotEmpty) {
        await AiApiService.archivePlayers(toArchiveIds);
      }

      // 1. Prepare data for Retraining
      // All players in this session are sent: '1' for recruited, '0' for non-recruited.
      if (_players.isNotEmpty) {
        final trainingData = _players.map((p) {
          return p.copyWith(label: p.label == 1 ? 1 : 0);
        }).toList();

        // 2. Retrain the AI Model
        await AiApiService.trainModel(trainingData);
        
        // 3. Refresh AI Metrics after training
        await loadAiMetrics();
      }

      _archivedPlayers
          .addAll(toArchive.map((p) => p.copyWith(status: 'archived')));
      _players.removeWhere((p) => p.label != 1);
      _selectedPlayerIds.clear();

      notifyListeners();
    } catch (e) {
      _error = 'Error ending session: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get recruitedCount => _players.where((p) => p.label == 1).length;
  int get toArchiveCount => _players.where((p) => p.label != 1).length;
}
