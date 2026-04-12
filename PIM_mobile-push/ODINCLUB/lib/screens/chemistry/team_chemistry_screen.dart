import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/theme/app_spacing.dart';

class TeamChemistryScreen extends StatefulWidget {
  const TeamChemistryScreen({super.key});

  @override
  State<TeamChemistryScreen> createState() => _TeamChemistryScreenState();
}

class _TeamChemistryScreenState extends State<TeamChemistryScreen> {
  static const List<MapEntry<String, String>> _styleMetrics = [
    MapEntry('possessionPlay', 'Possession Play'),
    MapEntry('selfishness', 'Selfishness'),
    MapEntry('oneTouchPreference', 'One-touch Preference'),
    MapEntry('directPlay', 'Direct Play'),
    MapEntry('riskTaking', 'Risk Taking'),
    MapEntry('pressingIntensity', 'Pressing Intensity'),
    MapEntry('offBallMovement', 'Off-ball Movement'),
    MapEntry('communication', 'Communication'),
    MapEntry('defensiveDiscipline', 'Defensive Discipline'),
    MapEntry('creativity', 'Creativity'),
  ];

  final ApiService _apiService = ApiService();

  final TextEditingController _seasonController = TextEditingController(
    text: '2026-2027',
  );
  final TextEditingController _lineupFormationController =
      TextEditingController(text: '4-3-3');
  final TextEditingController _observedByController = TextEditingController();
  final TextEditingController _tacticalZoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _manualScoreByController =
      TextEditingController();
  final TextEditingController _manualScoreReasonController =
      TextEditingController();
  final TextEditingController _profileNotesController = TextEditingController();
  final TextEditingController _profileStylesController =
      TextEditingController();

  List<Map<String, dynamic>> _players = [];
  String? _playerAId;
  String? _playerBId;
  String? _networkPlayerId;
  String? _profilePlayerId;
  double _pairRating = 7.0;
  double _manualOverrideScore = 7.0;
  Map<String, double> _editingStyle = _defaultStyleValues();
  Map<String, Map<String, dynamic>> _profilesByPlayerId = {};

  bool _includeAiInsights = true;
  bool _isLoadingPlayers = false;
  bool _isLoadingProfiles = false;
  bool _isLoadingMatrix = false;
  bool _isLoadingGraph = false;
  bool _isLoadingPairs = false;
  bool _isSubmittingPair = false;
  bool _isAnalyzingPairProfile = false;
  bool _isSavingManualOverride = false;
  bool _isSavingProfile = false;
  bool _isScoringLineup = false;
  bool _isGeneratingLineup = false;
  bool _isLoadingNetwork = false;
  bool _isAnalyzingSquad = false;

  final Set<String> _selectedLineupIds = {};

  Map<String, dynamic>? _matrixData;
  Map<String, dynamic>? _graphData;
  Map<String, dynamic>? _bestPairsData;
  Map<String, dynamic>? _conflictsData;
  Map<String, dynamic>? _lineupScoreData;
  Map<String, dynamic>? _generatedLineupData;
  Map<String, dynamic>? _networkData;
  Map<String, dynamic>? _pairProfileAnalysis;
  Map<String, dynamic>? _squadAnalysisData;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _loadProfiles();
    _loadPairs();
  }

  @override
  void dispose() {
    _seasonController.dispose();
    _lineupFormationController.dispose();
    _observedByController.dispose();
    _tacticalZoneController.dispose();
    _notesController.dispose();
    _manualScoreByController.dispose();
    _manualScoreReasonController.dispose();
    _profileNotesController.dispose();
    _profileStylesController.dispose();
    super.dispose();
  }

  static Map<String, double> _defaultStyleValues() {
    return {for (final metric in _styleMetrics) metric.key: 5};
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry('$key', item));
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value;
    }
    return const [];
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    final root = _asMap(payload);
    if (root['data'] is List) {
      return root['data'] as List<dynamic>;
    }

    final nested = root['data'];
    if (nested is Map) {
      if (nested['data'] is List) {
        return nested['data'] as List<dynamic>;
      }
      if (nested['items'] is List) {
        return nested['items'] as List<dynamic>;
      }
    }

    if (root['items'] is List) {
      return root['items'] as List<dynamic>;
    }

    return const [];
  }

  String _playerId(Map<String, dynamic> player) {
    return (player['_id'] ?? player['id'] ?? '').toString();
  }

  String _playerName(Map<String, dynamic> player) {
    final named = (player['name'] ?? '').toString().trim();
    if (named.isNotEmpty) {
      return named;
    }

    final firstName = (player['firstName'] ?? '').toString().trim();
    final lastName = (player['lastName'] ?? '').toString().trim();
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return _playerId(player);
  }

  String _shortName(String value, int max) {
    if (value.length <= max) {
      return value;
    }
    return '${value.substring(0, max - 1)}…';
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? fallback;
  }

  Color _ratingColor(double rating, BuildContext context) {
    if (rating >= 8.5) {
      return Colors.green.shade700;
    }
    if (rating <= 4.5) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  List<Map<String, dynamic>> _extractSquadPlayers(Map<String, dynamic> payload) {
    final directPlayers = _asList(payload['players']).map(_asMap).toList();
    if (directPlayers.isNotEmpty) {
      return directPlayers.where((player) => _playerId(player).isNotEmpty).toList();
    }

    final playerIds = _asList(payload['playerIds']).map(_asMap).toList();
    return playerIds.where((player) => _playerId(player).isNotEmpty).toList();
  }

  Future<void> _loadPlayers() async {
    final season = _seasonController.text.trim();
    setState(() {
      _isLoadingPlayers = true;
    });

    final result = season.isNotEmpty
        ? await _apiService.getSeasonSquad(season)
        : await _apiService.getPlayers(page: 1, limit: 200);
    final loadedPlayers = <Map<String, dynamic>>[];
    final starterIds = <String>[];

    if (result['success'] == true) {
      final root = _asMap(result['data']);
      final rows = season.isNotEmpty
          ? _extractSquadPlayers(root)
          : _extractList(result['data']).map(_asMap).toList();
      if (season.isNotEmpty) {
        starterIds.addAll(
          _asList(root['starterIds']).map((item) => item.toString()).where((id) => id.isNotEmpty),
        );
      }
      for (final row in rows) {
        final player = _asMap(row);
        if (_playerId(player).isNotEmpty) {
          loadedPlayers.add(player);
        }
      }

      loadedPlayers.sort(
        (a, b) => _playerName(
          a,
        ).toLowerCase().compareTo(_playerName(b).toLowerCase()),
      );

      if (mounted) {
        setState(() {
          _players = loadedPlayers;
          _selectedLineupIds
            ..clear()
            ..addAll(starterIds.where((id) => _players.any((player) => _playerId(player) == id)).take(11));
          _playerAId = _players.isNotEmpty ? _playerId(_players.first) : null;
          _playerBId = _players.length > 1
              ? _playerId(_players[1])
              : _playerAId;
          _networkPlayerId = _players.isNotEmpty
              ? _playerId(_players.first)
              : null;
          _profilePlayerId = _players.isNotEmpty
              ? _playerId(_players.first)
              : null;
        });
        _hydrateProfileEditor();
      }
    } else {
      _showMessage(result['message'] ?? 'Failed to load squad players');
    }

    if (mounted) {
      setState(() {
        _isLoadingPlayers = false;
      });
    }
  }

  Future<void> _loadProfiles() async {
    final season = _seasonController.text.trim();
    if (season.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingProfiles = true;
    });

    final result = await _apiService.listPlayerStyleProfiles(
      season: season,
      limit: 300,
    );
    if (result['success'] == true) {
      final data = _asMap(result['data']);
      final rows = _asList(data['items']).map(_asMap).toList();
      final map = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final playerId = (row['playerId'] ?? '').toString();
        if (playerId.isNotEmpty) {
          map[playerId] = row;
        }
      }

      if (mounted) {
        setState(() {
          _profilesByPlayerId = map;
        });
        _hydrateProfileEditor();
      }
    } else {
      _showMessage(result['message'] ?? 'Failed to load player style profiles');
    }

    if (mounted) {
      setState(() {
        _isLoadingProfiles = false;
      });
    }
  }

  void _hydrateProfileEditor() {
    final playerId = _profilePlayerId;
    if (playerId == null || playerId.isEmpty) {
      return;
    }

    final profile = _profilesByPlayerId[playerId];
    final style = _asMap(profile?['style']);

    setState(() {
      _editingStyle = _defaultStyleValues();
      for (final metric in _styleMetrics) {
        _editingStyle[metric.key] = _toDouble(
          style[metric.key],
          fallback: 5,
        ).clamp(0, 10).toDouble();
      }
      _profileNotesController.text = (profile?['notes'] ?? '').toString();
      final preferred = _asList(profile?['preferredStyles'])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      _profileStylesController.text = preferred.join(', ');
    });
  }

  Future<void> _saveProfile() async {
    final season = _seasonController.text.trim();
    if (season.isEmpty) {
      _showMessage('Season is required');
      return;
    }
    if (_profilePlayerId == null || _profilePlayerId!.isEmpty) {
      _showMessage('Select a player profile first');
      return;
    }

    setState(() {
      _isSavingProfile = true;
    });

    final preferredStyles = _profileStylesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final stylePayload = <String, dynamic>{
      for (final metric in _styleMetrics)
        metric.key: (_editingStyle[metric.key] ?? 5).clamp(0, 10),
    };

    final result = await _apiService.upsertPlayerStyleProfile(
      playerId: _profilePlayerId!,
      season: season,
      style: stylePayload,
      preferredStyles: preferredStyles,
      notes: _profileNotesController.text.trim(),
      updatedBy: _observedByController.text.trim(),
    );

    if (result['success'] == true) {
      _showMessage('Player style profile saved');
      await _loadProfiles();
    } else {
      _showMessage(result['message'] ?? 'Failed to save player style profile');
    }

    if (mounted) {
      setState(() {
        _isSavingProfile = false;
      });
    }
  }

  Future<void> _analyzePairProfile() async {
    final season = _seasonController.text.trim();
    if (season.isEmpty) {
      _showMessage('Season is required');
      return;
    }
    if (_playerAId == null || _playerBId == null) {
      _showMessage('Select both players');
      return;
    }
    if (_playerAId == _playerBId) {
      _showMessage('Player pair must be different');
      return;
    }

    setState(() {
      _isAnalyzingPairProfile = true;
    });

    final result = await _apiService.analyzeChemistryPairProfile(
      season: season,
      playerAId: _playerAId!,
      playerBId: _playerBId!,
      includeAiInsights: _includeAiInsights,
    );

    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _pairProfileAnalysis = _asMap(result['data']);
          _manualOverrideScore = _toDouble(
            result['data']?['aiScore'],
            fallback: _manualOverrideScore,
          ).clamp(0, 10).toDouble();
        });
      }
      _showMessage('AI pair profile analysis completed');
      await _loadPairs();
      if (_matrixData != null) {
        await _loadMatrix();
      }
    } else {
      _showMessage(
        result['message'] ?? 'Failed to analyze pair profile chemistry',
      );
    }

    if (mounted) {
      setState(() {
        _isAnalyzingPairProfile = false;
      });
    }
  }

  Future<void> _saveManualOverride() async {
    final season = _seasonController.text.trim();
    if (season.isEmpty) {
      _showMessage('Season is required');
      return;
    }
    if (_playerAId == null || _playerBId == null) {
      _showMessage('Select both players');
      return;
    }

    setState(() {
      _isSavingManualOverride = true;
    });

    final result = await _apiService.setChemistryManualScore(
      season: season,
      playerAId: _playerAId!,
      playerBId: _playerBId!,
      manualScore: _manualOverrideScore,
      manualScoreBy: _manualScoreByController.text.trim(),
      manualScoreReason: _manualScoreReasonController.text.trim(),
    );

    if (result['success'] == true) {
      _showMessage('Manual override saved. Manual score is now primary.');
      await _loadPairs();
      if (_matrixData != null) {
        await _loadMatrix();
      }
    } else {
      _showMessage(result['message'] ?? 'Failed to save manual override');
    }

    if (mounted) {
      setState(() {
        _isSavingManualOverride = false;
      });
    }
  }

  Future<void> _loadMatrix() async {
    final season = _seasonController.text.trim();
    if (season.isEmpty) {
      _showMessage('Season is required');
      return;
    }

    setState(() {
      _isLoadingMatrix = true;
    });

    final result = await _apiService.getChemistryMatrix(season);

    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _matrixData = _asMap(result['data']);
        });
      }
    } else {
      _showMessage(result['message'] ?? 'Failed to load chemistry matrix');
    }

    if (mounted) {
      setState(() {
        _isLoadingMatrix = false;
      });
    }
  }

  Future<void> _loadGraph() async {
    final season = _seasonController.text.trim();
    if (season.isEmpty) {
      _showMessage('Season is required');
      return;
    }

    setState(() {
      _isLoadingGraph = true;
    });

    final result = await _apiService.getChemistryGraph(season);

    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _graphData = _asMap(result['data']);
        });
      }
    } else {
      _showMessage(result['message'] ?? 'Failed to load chemistry graph');
    }

    if (mounted) {
      setState(() {
        _isLoadingGraph = false;
      });
    }
  }

  Future<void> _loadPairs() async {
    final season = _seasonController.text.trim();

    setState(() {
      _isLoadingPairs = true;
    });

    final bestResult = await _apiService.getChemistryBestPairs(
      season: season,
      limit: 12,
      threshold: 8,
      includeAiInsights: _includeAiInsights,
    );
    final conflictsResult = await _apiService.getChemistryConflicts(
      season: season,
      limit: 12,
      threshold: 4.5,
      includeAiInsights: _includeAiInsights,
    );

    if (mounted) {
      setState(() {
        if (bestResult['success'] == true) {
          _bestPairsData = _asMap(bestResult['data']);
        }
        if (conflictsResult['success'] == true) {
          _conflictsData = _asMap(conflictsResult['data']);
        }
      });
    }

    if (bestResult['success'] != true) {
      _showMessage(bestResult['message'] ?? 'Failed to load best pairs');
    }
    if (conflictsResult['success'] != true) {
      _showMessage(conflictsResult['message'] ?? 'Failed to load conflicts');
    }

    if (mounted) {
      setState(() {
        _isLoadingPairs = false;
      });
    }
  }

  Future<void> _submitPairRating() async {
    final season = _seasonController.text.trim();
    if (season.isEmpty) {
      _showMessage('Season is required');
      return;
    }
    if (_playerAId == null || _playerBId == null) {
      _showMessage('Select both players');
      return;
    }
    if (_playerAId == _playerBId) {
      _showMessage('Player pair must be different');
      return;
    }

    setState(() {
      _isSubmittingPair = true;
    });

    final result = await _apiService.rateChemistryPair(
      season: season,
      playerAId: _playerAId!,
      playerBId: _playerBId!,
      rating: _pairRating,
      observedBy: _observedByController.text.trim(),
      tacticalZone: _tacticalZoneController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (result['success'] == true) {
      _showMessage('Pair rating saved');
      await _loadPairs();
      if (_matrixData != null) {
        await _loadMatrix();
      }
    } else {
      _showMessage(result['message'] ?? 'Failed to rate pair');
    }

    if (mounted) {
      setState(() {
        _isSubmittingPair = false;
      });
    }
  }

  Future<void> _scoreLineup() async {
    final season = _seasonController.text.trim();
    if (_selectedLineupIds.length < 3) {
      _showMessage('Select at least 3 players for lineup chemistry scoring');
      return;
    }

    setState(() {
      _isScoringLineup = true;
    });

    final result = await _apiService.scoreChemistryLineup(
      playerIds: _selectedLineupIds.toList(),
      season: season,
      includeAiInsights: _includeAiInsights,
    );

    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _lineupScoreData = _asMap(result['data']);
        });
      }
    } else {
      _showMessage(result['message'] ?? 'Failed to score lineup chemistry');
    }

    if (mounted) {
      setState(() {
        _isScoringLineup = false;
      });
    }
  }

  Future<void> _generateStartingXiByChemistry() async {
    final season = _seasonController.text.trim();
    final formation = _lineupFormationController.text.trim().isEmpty
        ? '4-3-3'
        : _lineupFormationController.text.trim();

    setState(() {
      _isGeneratingLineup = true;
    });

    final result = await _apiService.generateChemistryStartingXi(
      season: season.isEmpty ? null : season,
      formation: formation,
      includeAiInsights: _includeAiInsights,
    );

    if (result['success'] == true) {
      final data = _asMap(result['data']);
      final directRows = _asList(data['startingXi']);
      final rows = directRows.isNotEmpty
          ? directRows
          : _asList(data['starting_xi']);

      final ids = <String>[];
      for (final row in rows) {
        final item = _asMap(row);
        final id = (item['playerId'] ?? item['player_id'] ?? '').toString();
        if (id.isNotEmpty) {
          ids.add(id);
        }
      }

      final evaluation = _asMap(data['chemistryEvaluation']);
      final summary = _asMap(evaluation['summary']);
      final chemistryScore = _toDouble(summary['chemistryScore']);

      if (mounted) {
        setState(() {
          _generatedLineupData = data;
          if (ids.isNotEmpty) {
            _selectedLineupIds
              ..clear()
              ..addAll(ids.take(11));
          }
          if (evaluation.isNotEmpty) {
            _lineupScoreData = evaluation;
          }
        });
      }

      _showMessage(
        'Chemistry XI generated (${chemistryScore.toStringAsFixed(2)}/10)',
      );
    } else {
      _showMessage(result['message'] ?? 'Failed to generate chemistry starting XI');
    }

    if (mounted) {
      setState(() {
        _isGeneratingLineup = false;
      });
    }
  }

  Future<void> _analyzeSquad() async {
    final season = _seasonController.text.trim();
    if (season.isEmpty) {
      _showMessage('Season is required');
      return;
    }

    setState(() {
      _isAnalyzingSquad = true;
    });

    final result = await _apiService.analyzeSquadChemistryProfile(
      season: season,
      includeAiInsights: _includeAiInsights,
    );

    if (result['success'] == true) {
      final data = _asMap(result['data']);
      final bestFormation = _asMap(data['bestFormation']);
      final currentLineup = _asMap(data['currentLineup']);
      final bestPairs = _asMap(data['bestPairs']);
      final conflicts = _asMap(data['conflicts']);
      final rows = (_asList(bestFormation['startingXi']).isNotEmpty
              ? _asList(bestFormation['startingXi'])
              : _asList(bestFormation['starting_xi']))
          .map(_asMap)
          .toList();

      final ids = <String>[];
      for (final row in rows) {
        final id = (row['playerId'] ?? row['player_id'] ?? '').toString();
        if (id.isNotEmpty) {
          ids.add(id);
        }
      }

      if (mounted) {
        setState(() {
          _squadAnalysisData = data;
          _generatedLineupData = bestFormation.isNotEmpty ? bestFormation : null;
          _lineupScoreData = bestFormation.isNotEmpty
              ? _asMap(bestFormation['chemistryEvaluation'])
              : currentLineup;
          _bestPairsData = bestPairs;
          _conflictsData = conflicts;
          if (ids.isNotEmpty) {
            _selectedLineupIds
              ..clear()
              ..addAll(ids.take(11));
          }

          final chosenFormation = (bestFormation['formation'] ?? '').toString();
          if (chosenFormation.isNotEmpty) {
            _lineupFormationController.text = chosenFormation;
          }
        });
      }

      final chemistrySummary = _asMap(data['chemistrySummary']);
      _showMessage(
        'Analyse terminee: note groupe ${_toDouble(chemistrySummary['squadScore']).toStringAsFixed(2)}/10',
      );
    } else {
      _showMessage(result['message'] ?? 'Failed to analyze squad chemistry');
    }

    if (mounted) {
      setState(() {
        _isAnalyzingSquad = false;
      });
    }
  }

  Future<void> _loadPlayerNetwork() async {
    final season = _seasonController.text.trim();
    if (_networkPlayerId == null || _networkPlayerId!.isEmpty) {
      _showMessage('Select a player');
      return;
    }

    setState(() {
      _isLoadingNetwork = true;
    });

    final result = await _apiService.getChemistryPlayerNetwork(
      _networkPlayerId!,
      season: season,
      includeAiInsights: _includeAiInsights,
    );

    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _networkData = _asMap(result['data']);
        });
      }
    } else {
      _showMessage(
        result['message'] ?? 'Failed to load player chemistry network',
      );
    }

    if (mounted) {
      setState(() {
        _isLoadingNetwork = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadPlayers();
    await _loadProfiles();
    await _loadPairs();
    await _loadMatrix();
    await _loadGraph();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Chemistry',
            subtitle:
                'Analyse simple du squad: profils, note du groupe, meilleure formation et XI recommande.',
            action: const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.s16),
          _buildTopControls(context),
          const SizedBox(height: AppSpacing.s16),
          const TabBar(
            tabs: [
              Tab(text: 'Essentiel'),
              Tab(text: 'XI'),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Expanded(
            child: TabBarView(
              children: [
                _buildOverviewTab(context),
                _buildLineupTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _seasonController,
                  decoration: const InputDecoration(
                    labelText: 'Season',
                    hintText: '2026-2027',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aide IA'),
                  value: _includeAiInsights,
                  onChanged: (value) {
                    setState(() {
                      _includeAiInsights = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzingSquad ? null : _analyzeSquad,
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                _isAnalyzingSquad ? 'Analyse...' : 'Analyser le squad',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lecture rapide',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                '1. Choisis la saison.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '2. Lance une seule analyse du squad.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '3. Ouvre l’onglet XI pour generer une composition recommandee.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'Joueurs charges: ${_players.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (_isAnalyzingSquad) ...[
                const SizedBox(height: AppSpacing.s12),
                const LinearProgressIndicator(minHeight: 3),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        _buildSquadSummaryCard(context),
        const SizedBox(height: AppSpacing.s12),
        _buildPairsListCard(context),
      ],
    );
  }

  Widget _buildSquadSummaryCard(BuildContext context) {
    final data = _squadAnalysisData;
    if (data == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultat du squad',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s8),
            const Text(
              'Aucune analyse encore. Utilise "Analyser le squad" pour verifier les profils joueurs et calculer la chemistry du groupe.',
            ),
          ],
        ),
      );
    }

    final chemistrySummary = _asMap(data['chemistrySummary']);
    final profiles = _asMap(data['profiles']);
    final groupProfile = _asMap(data['groupProfile']);
    final style = _asMap(groupProfile['style']);
    final formationComparisons =
        _asList(data['formationComparisons']).map(_asMap).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultat du squad',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Note du groupe: ${_toDouble(chemistrySummary['squadScore']).toStringAsFixed(2)} / 10',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text('Niveau: ${(chemistrySummary['squadLabel'] ?? '-').toString()}'),
          Text(
            'Meilleure formation: ${(chemistrySummary['bestFormation'] ?? '-').toString()}',
          ),
          Text(
            'Score du meilleur XI: ${_toDouble(chemistrySummary['bestFormationScore']).toStringAsFixed(2)} / 10',
          ),
          if (chemistrySummary['currentStarterScore'] != null)
            Text(
              'Score des titulaires actuels: ${_toDouble(chemistrySummary['currentStarterScore']).toStringAsFixed(2)} / 10',
            ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Profils joueurs',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text('Complets: ${profiles['complete'] == true ? 'oui' : 'non'}'),
          Text(
            'Profils crees automatiquement: ${profiles['createdProfiles'] ?? 0}',
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Identite du groupe',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text((groupProfile['identity'] ?? '-').toString()),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Possession ${_toDouble(style['possessionPlay']).toStringAsFixed(1)} • Pressing ${_toDouble(style['pressingIntensity']).toStringAsFixed(1)} • Creativite ${_toDouble(style['creativity']).toStringAsFixed(1)}',
          ),
          if (formationComparisons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Comparaison formations',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.s4),
            ...formationComparisons.map(
              (item) => Text(
                '${(item['formation'] ?? '-').toString()} : ${_toDouble(item['chemistryScore']).toStringAsFixed(2)} / 10',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerProfilesTab(BuildContext context) {
    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Player Style Profile',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _isLoadingProfiles ? null : _loadProfiles,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload Profiles'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Define player behavior traits (possession, one-touch, selfishness, etc.). Chemistry AI uses these profiles to generate pair scores.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.s12),
              DropdownButtonFormField<String>(
                initialValue: _profilePlayerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Player Profile',
                  border: OutlineInputBorder(),
                ),
                items: _players
                    .map(
                      (player) => DropdownMenuItem<String>(
                        value: _playerId(player),
                        child: Text(
                          _playerName(player),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _profilePlayerId = value;
                  });
                  _hydrateProfileEditor();
                },
              ),
              const SizedBox(height: AppSpacing.s12),
              for (final metric in _styleMetrics) ...[
                Row(
                  children: [
                    Expanded(child: Text(metric.value)),
                    Text((_editingStyle[metric.key] ?? 5).toStringAsFixed(1)),
                  ],
                ),
                Slider(
                  value: _editingStyle[metric.key] ?? 5,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  label: (_editingStyle[metric.key] ?? 5).toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _editingStyle[metric.key] = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.s8),
              TextField(
                controller: _profileStylesController,
                decoration: const InputDecoration(
                  labelText: 'Preferred styles (comma separated)',
                  hintText: 'possession, short-passes, one-touch',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              TextField(
                controller: _profileNotesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Profile notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingProfile ? null : _saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    _isSavingProfile
                        ? 'Saving profile...'
                        : 'Save Player Profile',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatrixAndGraphTab(BuildContext context) {
    return ListView(
      children: [
        if (_isLoadingMatrix || _isLoadingGraph) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s12),
            child: LinearProgressIndicator(minHeight: 3),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        _buildMatrixCard(context),
        const SizedBox(height: AppSpacing.s12),
        _buildGraphCard(context),
      ],
    );
  }

  Widget _buildMatrixCard(BuildContext context) {
    final data = _matrixData;
    if (data == null) {
      return const AppCard(
        child: Text('Matrix not loaded yet. Use "Load Matrix".'),
      );
    }

    final players = _asList(data['players']).map(_asMap).toList();
    final rows = _asList(data['matrix']).map(_asMap).toList();

    if (players.isEmpty || rows.isEmpty) {
      return const AppCard(
        child: Text('No matrix data found for this season.'),
      );
    }

    final columns = <DataColumn>[
      const DataColumn(label: Text('Player')),
      ...players.map(
        (player) => DataColumn(
          label: SizedBox(
            width: 92,
            child: Text(_shortName(_playerName(player), 10)),
          ),
        ),
      ),
    ];

    final tableRows = rows.map((row) {
      final relationEntries = _asList(row['relations']).map(_asMap).toList();
      final relationByPlayerId = <String, Map<String, dynamic>>{};
      for (final relation in relationEntries) {
        relationByPlayerId[(relation['playerId'] ?? '').toString()] = relation;
      }

      final cells = <DataCell>[
        DataCell(
          SizedBox(
            width: 120,
            child: Text(_shortName((row['playerName'] ?? '').toString(), 14)),
          ),
        ),
      ];

      for (final player in players) {
        final peerId = _playerId(player);
        final relation = relationByPlayerId[peerId];
        final status = (relation?['status'] ?? '').toString();
        final rating = relation?['rating'];
        final label = rating is num
            ? rating.toStringAsFixed(1)
            : (status == 'self' ? '-' : 'n/a');

        cells.add(
          DataCell(
            Text(
              label,
              style: rating is num
                  ? TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _ratingColor(rating.toDouble(), context),
                    )
                  : null,
            ),
          ),
        );
      }

      return DataRow(cells: cells);
    }).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Affinity Matrix',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Rows: ${rows.length} | Players: ${players.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(columns: columns, rows: tableRows),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphCard(BuildContext context) {
    final data = _graphData;
    if (data == null) {
      return const AppCard(
        child: Text('Graph not loaded yet. Use "Load Graph".'),
      );
    }

    final nodes = _asList(data['nodes']).map(_asMap).toList();
    final edges = _asList(data['edges']).map(_asMap).toList();

    final sortedEdges = [...edges];
    sortedEdges.sort((a, b) {
      final left = _toDouble(a['weight']);
      final right = _toDouble(b['weight']);
      return right.compareTo(left);
    });

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chemistry Graph',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Nodes: ${nodes.length} | Edges: ${edges.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s12),
          if (sortedEdges.isEmpty)
            const Text('No graph links for this season yet.')
          else
            ...sortedEdges.take(12).map((edge) {
              final weight = _toDouble(edge['weight']);
              final source = (edge['source'] ?? '').toString();
              final target = (edge['target'] ?? '').toString();
              final warning = edge['warning'] == true;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  warning ? Icons.warning_amber_rounded : Icons.star_rounded,
                  color: warning
                      ? Theme.of(context).colorScheme.error
                      : Colors.amber.shade700,
                ),
                title: Text('$source ↔ $target'),
                subtitle: Text('Score: ${weight.toStringAsFixed(1)}/10'),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPairsTab(BuildContext context) {
    return ListView(
      children: [
        _buildRatePairCard(context),
        const SizedBox(height: AppSpacing.s12),
        _buildPairsListCard(context),
      ],
    );
  }

  Widget _buildRatePairCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate a Pair', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s12),
          if (_isLoadingPlayers)
            const LinearProgressIndicator(minHeight: 3)
          else ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _playerAId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Player A',
                      border: OutlineInputBorder(),
                    ),
                    items: _players
                        .map(
                          (player) => DropdownMenuItem<String>(
                            value: _playerId(player),
                            child: Text(
                              _playerName(player),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _playerAId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _playerBId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Player B',
                      border: OutlineInputBorder(),
                    ),
                    items: _players
                        .map(
                          (player) => DropdownMenuItem<String>(
                            value: _playerId(player),
                            child: Text(
                              _playerName(player),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _playerBId = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text('Rating: ${_pairRating.toStringAsFixed(1)} / 10'),
            Slider(
              value: _pairRating,
              min: 0,
              max: 10,
              divisions: 20,
              label: _pairRating.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _pairRating = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.s8),
            TextField(
              controller: _observedByController,
              decoration: const InputDecoration(
                labelText: 'Observed by',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextField(
              controller: _tacticalZoneController,
              decoration: const InputDecoration(
                labelText: 'Tactical zone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzingPairProfile
                        ? null
                        : _analyzePairProfile,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      _isAnalyzingPairProfile
                          ? 'Analyzing...'
                          : 'AI Analyze from Profiles',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Manual override score (primary)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Manual score: ${_manualOverrideScore.toStringAsFixed(1)} / 10',
            ),
            Slider(
              value: _manualOverrideScore,
              min: 0,
              max: 10,
              divisions: 20,
              label: _manualOverrideScore.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _manualOverrideScore = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.s8),
            TextField(
              controller: _manualScoreByController,
              decoration: const InputDecoration(
                labelText: 'Manual score by',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextField(
              controller: _manualScoreReasonController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Manual override reason',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSavingManualOverride ? null : _saveManualOverride,
                icon: const Icon(Icons.tune),
                label: Text(
                  _isSavingManualOverride
                      ? 'Saving manual override...'
                      : 'Save Manual Override (Primary Score)',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            if (_pairProfileAnalysis != null)
              _buildPairProfileAnalysisCard(context),
            const SizedBox(height: AppSpacing.s12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmittingPair ? null : _submitPairRating,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _isSubmittingPair ? 'Saving...' : 'Save Pair Rating',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPairProfileAnalysisCard(BuildContext context) {
    final data = _pairProfileAnalysis;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final aiScore = _toDouble(data['aiScore']);
    final baseline = _toDouble(data['baselineProfileScore']);
    final source = (data['aiInsightsSource'] ?? '').toString();
    final insights = _asList(data['aiInsights']);
    final pair = _asMap(data['pair']);
    final effective = _toDouble(pair['effectiveRating'], fallback: aiScore);
    final effectiveSource = (pair['scoreSource'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Profile Analysis',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text('Baseline profile score: ${baseline.toStringAsFixed(2)} / 10'),
          Text('AI analyzed score: ${aiScore.toStringAsFixed(2)} / 10'),
          Text(
            'Effective score now: ${effective.toStringAsFixed(2)} / 10 (${effectiveSource.isEmpty ? 'n/a' : effectiveSource})',
          ),
          if (source.isNotEmpty)
            Text(
              'Insights source: ${source == 'ai-service' ? 'AI service' : 'Rule-based fallback'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            ...insights.map((item) => Text('• ${item.toString()}')),
          ],
        ],
      ),
    );
  }

  Widget _buildPairsListCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Smart Pairing Alerts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _isLoadingPairs ? null : _loadPairs,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
              ),
            ],
          ),
          if (_isLoadingPairs) ...[
            const SizedBox(height: AppSpacing.s8),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: AppSpacing.s12),
          _buildPairListBlock(context, 'Top Compatible Pairs', _bestPairsData),
          const SizedBox(height: AppSpacing.s12),
          _buildPairListBlock(context, 'Conflict Pairs', _conflictsData),
        ],
      ),
    );
  }

  Widget _buildPairListBlock(
    BuildContext context,
    String title,
    Map<String, dynamic>? source,
  ) {
    final pairs = _asList(source?['pairs']).map(_asMap).toList();
    final aiInsights = _asList(source?['aiInsights']);
    final aiInsightsSource = (source?['aiInsightsSource'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.s8),
        if (pairs.isEmpty)
          Text('No data yet.', style: Theme.of(context).textTheme.bodySmall)
        else
          ...pairs.map((pair) {
            final rating = _toDouble(
              pair['effectiveRating'],
              fallback: _toDouble(pair['averageRating']),
            );
            final a = (pair['playerAName'] ?? '').toString();
            final b = (pair['playerBName'] ?? '').toString();
            final observations = (pair['observationCount'] ?? 0).toString();
            final scoreSource = (pair['scoreSource'] ?? '').toString();
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                rating <= 4.5 ? Icons.warning_amber_rounded : Icons.link,
                color: _ratingColor(rating, context),
              ),
              title: Text('$a + $b'),
              subtitle: Text(
                'Effective ${rating.toStringAsFixed(1)} / 10 • source ${scoreSource.isEmpty ? 'n/a' : scoreSource} • $observations observations',
              ),
            );
          }),
        if (aiInsights.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          Text('AI Insights', style: Theme.of(context).textTheme.labelLarge),
          if (aiInsightsSource.isNotEmpty)
            Text(
              'Source: ${aiInsightsSource == 'ai-service' ? 'AI service' : 'Rule-based fallback'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: AppSpacing.s4),
          ...aiInsights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              child: Text('• ${item.toString()}'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLineupTab(BuildContext context) {
    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meilleure Formation Et XI',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Le resultat ci-dessous montre directement la meilleure formation et la meilleure selection proposees.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'Formation choisie: ${_lineupFormationController.text.isEmpty ? '-' : _lineupFormationController.text}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Utilise seulement "Analyser le squad" dans l onglet principal. Cet onglet sert ensuite a lire le XI recommande.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        _buildLineupResultCard(context),
      ],
    );
  }

  Widget _buildLineupResultCard(BuildContext context) {
    final data = _lineupScoreData;
    if (data == null) {
      return const AppCard(child: Text('No lineup score yet.'));
    }

    final summary = _asMap(data['summary']);
    final impact = _asMap(data['impact']);
    final centralTriangle = _asMap(impact['centralTriangle']);
    final defensiveCore = _asMap(impact['defensiveCore']);
    final weakLink = _asMap(impact['leftFlankWeakLink']);
    final smartAlerts = _asList(data['smartPairingAlerts']);
    final aiInsights = _asList(data['aiInsights']);
    final aiInsightsSource = (data['aiInsightsSource'] ?? '').toString();
    final generatedData = _asMap(_generatedLineupData);
    final generatedFormation = (generatedData['formation'] ?? '').toString();
    final generatedRowsRaw = _asList(generatedData['startingXi']);
    final generatedRows = (generatedRowsRaw.isNotEmpty
        ? generatedRowsRaw
        : _asList(generatedData['starting_xi']))
      .map(_asMap)
      .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'XI Proposed Chemistry Score',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            '${_toDouble(summary['chemistryScore']).toStringAsFixed(2)} / 10',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text('Known pairs: ${summary['knownPairCount'] ?? 0}'),
          Text('Unknown pairs: ${summary['unknownPairCount'] ?? 0}'),
          Text(
            'Coverage: ${_toDouble(summary['coverage']).toStringAsFixed(1)}%',
          ),
          if (generatedRows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              generatedFormation.isEmpty
                  ? 'Generated XI (chemistry)'
                  : 'Generated XI (formation $generatedFormation)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.s4),
            ...generatedRows.map((row) {
              final name = (row['playerName'] ?? row['player_name'] ?? '-')
                  .toString();
              final role =
                  (row['roleLabel'] ?? row['role_label'] ?? row['role'] ?? '')
                      .toString();
              return Text('• $name${role.isEmpty ? '' : ' - $role'}');
            }),
          ],
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Central triangle: ${centralTriangle['label'] ?? 'Unknown'} (${centralTriangle['score'] ?? 'n/a'})',
          ),
          Text(
            'Defensive core: ${defensiveCore['label'] ?? 'Unknown'} (${defensiveCore['score'] ?? 'n/a'})',
          ),
          if (weakLink.isNotEmpty)
            Text(
              'Weak link: ${weakLink['playerAName'] ?? '-'} + ${weakLink['playerBName'] ?? '-'} (${weakLink['rating'] ?? 'n/a'})',
            ),
          if (smartAlerts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Text('Smart alerts', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.s4),
            ...smartAlerts.map((alert) => Text('• ${alert.toString()}')),
          ],
          if (aiInsights.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Text('AI insights', style: Theme.of(context).textTheme.titleSmall),
            if (aiInsightsSource.isNotEmpty)
              Text(
                'Source: ${aiInsightsSource == 'ai-service' ? 'AI service' : 'Rule-based fallback'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: AppSpacing.s4),
            ...aiInsights.map((item) => Text('• ${item.toString()}')),
          ],
        ],
      ),
    );
  }

  Widget _buildNetworkTab(BuildContext context) {
    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Player Affinity Network',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s12),
              DropdownButtonFormField<String>(
                initialValue: _networkPlayerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Player',
                  border: OutlineInputBorder(),
                ),
                items: _players
                    .map(
                      (player) => DropdownMenuItem<String>(
                        value: _playerId(player),
                        child: Text(
                          _playerName(player),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _networkPlayerId = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.s12),
              ElevatedButton.icon(
                onPressed: _isLoadingNetwork ? null : _loadPlayerNetwork,
                icon: const Icon(Icons.hub_outlined),
                label: Text(_isLoadingNetwork ? 'Loading...' : 'Load Network'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        _buildNetworkResultCard(context),
      ],
    );
  }

  Widget _buildNetworkResultCard(BuildContext context) {
    final data = _networkData;
    if (data == null) {
      return const AppCard(child: Text('No player network loaded yet.'));
    }

    final player = _asMap(data['player']);
    final summary = _asMap(data['summary']);
    final connections = _asList(data['connections']).map(_asMap).toList();
    final aiInsights = _asList(data['aiInsights']);
    final aiInsightsSource = (data['aiInsightsSource'] ?? '').toString();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network for ${player['playerName'] ?? '-'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text('Connections: ${summary['connectionCount'] ?? 0}'),
          Text('Average rating: ${summary['averageRating'] ?? 'n/a'}'),
          const SizedBox(height: AppSpacing.s12),
          if (connections.isEmpty)
            const Text('No chemistry records for this player yet.')
          else
            ...connections.map((connection) {
              final rating = _toDouble(connection['rating']);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.person_outline,
                  color: _ratingColor(rating, context),
                ),
                title: Text((connection['teammateName'] ?? '-').toString()),
                subtitle: Text(
                  'Rating ${rating.toStringAsFixed(1)} / 10 • ${connection['observationCount'] ?? 0} observations',
                ),
              );
            }),
          if (aiInsights.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Text('AI insights', style: Theme.of(context).textTheme.titleSmall),
            if (aiInsightsSource.isNotEmpty)
              Text(
                'Source: ${aiInsightsSource == 'ai-service' ? 'AI service' : 'Rule-based fallback'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: AppSpacing.s4),
            ...aiInsights.map((item) => Text('• ${item.toString()}')),
          ],
        ],
      ),
    );
  }
}
