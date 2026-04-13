import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/tactics.dart';
import '../services/tactics_service.dart';
import '../../theme/app_theme.dart';
import '../../ui/navigation/menu_config.dart';
import '../../ui/shell/app_shell.dart';

class TacticsBoardScreen extends StatefulWidget {
  const TacticsBoardScreen({super.key});

  @override
  State<TacticsBoardScreen> createState() => _TacticsBoardScreenState();
}

class _TacticsBoardScreenState extends State<TacticsBoardScreen> {
  String _selectedStyle = 'POSSESSION';
  bool _isLoading = false;
  TacticalPlan? _plan;
  bool _showAdvancedInputs = false;
  final List<_OpponentPlayerDraft> _retiredOpponentDrafts = [];

  final TextEditingController _opponentTeamController = TextEditingController();
  final TextEditingController _preferredFormationController = TextEditingController();
  final TextEditingController _detailedOpponentStyleController = TextEditingController();
  final TextEditingController _strengthsController = TextEditingController();
  final TextEditingController _weaknessesController = TextEditingController();
  final List<_OpponentPlayerDraft> _opponentPlayerDrafts = [
    _OpponentPlayerDraft(),
    _OpponentPlayerDraft(),
  ];

  final List<Map<String, String>> _oppStyles = [
    {'value': 'POSSESSION', 'label': 'Jeu de Possession (ex: Man City)'},
    {'value': 'COUNTER_ATTACK', 'label': 'Gros pressing & Contre (ex: Liverpool)'},
    {'value': 'HIGH_PRESS', 'label': 'Pressing très haut (ex: Bayern)'},
    {'value': 'PARK_THE_BUS', 'label': 'Bloc très bas / Défensif'},
  ];

  Color get _surface => AppTheme.surface;
  Color get _surfaceAlt => AppTheme.surfaceAlt;
  Color get _border => AppTheme.cardBorder;
  Color get _primary => AppTheme.blueFonce;
  Color get _accent => AppTheme.blueCiel;
  Color get _textPrimary => AppTheme.textPrimary;
  Color get _textSecondary => AppTheme.textSecondary;
  Color get _textMuted => AppTheme.textMuted;
  Color get _success => AppTheme.success;
  Color get _warning => AppTheme.warning;
  Color get _danger => AppTheme.danger;

  BoxDecoration _panelDecoration({
    Color? color,
    double radius = 16,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color ?? _surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : const [],
    );
  }

  @override
  void dispose() {
    _opponentTeamController.dispose();
    _preferredFormationController.dispose();
    _detailedOpponentStyleController.dispose();
    _strengthsController.dispose();
    _weaknessesController.dispose();
    for (final draft in _opponentPlayerDrafts) {
      draft.dispose();
    }
    for (final draft in _retiredOpponentDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _generateTactics() async {
    setState(() => _isLoading = true);
    try {
      final opponentTeamName = _cleanText(_opponentTeamController.text);
      final preferredFormation = _cleanText(_preferredFormationController.text);
      final detailedOpponentStyle = _cleanText(_detailedOpponentStyleController.text);
      final strengths = _splitTags(_strengthsController.text);
      final weaknesses = _splitTags(_weaknessesController.text);
      final opponentSquad = _opponentPlayerDrafts
          .map((draft) => draft.toRequestModel())
          .whereType<OpponentSquadPlayerInput>()
          .toList();

      // In detailed mode (JSON/manual), rely only on detailed report data.
      final useDetailedReportData = _showAdvancedInputs && _hasDetailedReportInput();

      final plan = await TacticsService.suggestFormation(
        opponentStyle: useDetailedReportData ? detailedOpponentStyle : _selectedStyle,
        opponentTeamName: opponentTeamName,
        preferredFormation: preferredFormation,
        strengths: strengths,
        weaknesses: weaknesses,
        opponentSquad: opponentSquad,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _plan = plan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _danger),
        );
      }
    }
  }

  String? _cleanText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  List<String>? _splitTags(String value) {
    final tags = value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    if (tags.isEmpty) {
      return null;
    }
    return tags;
  }

  bool _hasDetailedReportInput() {
    final hasTextualInput =
        _cleanText(_detailedOpponentStyleController.text) != null ||
        _cleanText(_opponentTeamController.text) != null ||
        _cleanText(_preferredFormationController.text) != null ||
        (_splitTags(_strengthsController.text)?.isNotEmpty ?? false) ||
        (_splitTags(_weaknessesController.text)?.isNotEmpty ?? false);

    if (hasTextualInput) {
      return true;
    }

    return _opponentPlayerDrafts.any((draft) => draft.toRequestModel() != null);
  }

  Future<void> _openJsonImportDialog() async {
    final controller = TextEditingController();
    final payload = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importer un rapport JSON'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collez un payload brut (opponentStyle, opponentTeamName, strengths, weaknesses, opponentSquad...).',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    minLines: 8,
                    maxLines: 14,
                    decoration: const InputDecoration(
                      hintText: '{\n  "opponentStyle": "HIGH_PRESS",\n  "opponentSquad": [...]\n}',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Importer'),
            ),
          ],
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    try {
      final root = _decodeImportedPayload(payload);
      if (root == null) {
        throw const FormatException(
          'JSON invalide. Verifiez les accolades/crochets ou retirez les caracteres en trop a la fin.',
        );
      }

      final imported = _parseImportedReport(root);

      if (!mounted) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _showAdvancedInputs = true;
          _detailedOpponentStyleController.text = imported.opponentStyle ?? '';
          _opponentTeamController.text = imported.opponentTeamName ?? '';
          _preferredFormationController.text = imported.preferredFormation ?? '';
          _strengthsController.text = imported.strengths.join(', ');
          _weaknessesController.text = imported.weaknesses.join(', ');
          _replaceOpponentDrafts(imported.players);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _success,
            content: Text(
              'Rapport importe: ${imported.players.length} joueur(s) detecte(s).',
            ),
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _danger,
            content: Text('Import JSON invalide: $e'),
          ),
        );
      }
    }
  }

  Map<String, dynamic>? _decodeImportedPayload(String rawPayload) {
    final cleaned = _stripCodeFences(rawPayload).trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final direct = _tryParseJsonMap(cleaned);
    if (direct != null) {
      return direct;
    }

    final extracted = _extractFirstJsonObject(cleaned);
    if (extracted != null) {
      return _tryParseJsonMap(extracted);
    }

    return null;
  }

  String _stripCodeFences(String input) {
    var output = input.trim();
    if (output.startsWith('```')) {
      final firstLineEnd = output.indexOf('\n');
      if (firstLineEnd >= 0) {
        output = output.substring(firstLineEnd + 1);
      }
      if (output.endsWith('```')) {
        output = output.substring(0, output.length - 3);
      }
    }
    return output.trim();
  }

  Map<String, dynamic>? _tryParseJsonMap(String source) {
    try {
      final decoded = jsonDecode(source);
      return _asMap(decoded);
    } catch (_) {
      return null;
    }
  }

  String? _extractFirstJsonObject(String source) {
    final start = source.indexOf('{');
    if (start < 0) {
      return null;
    }

    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = start; i < source.length; i += 1) {
      final char = source[i];

      if (inString) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (char == '\\') {
          escaped = true;
          continue;
        }
        if (char == '"') {
          inString = false;
        }
        continue;
      }

      if (char == '"') {
        inString = true;
        continue;
      }

      if (char == '{') {
        depth += 1;
        continue;
      }

      if (char == '}') {
        depth -= 1;
        if (depth == 0) {
          return source.substring(start, i + 1);
        }
        if (depth < 0) {
          return null;
        }
      }
    }

    return null;
  }

  void _replaceOpponentDrafts(List<OpponentSquadPlayerInput> players) {
    final oldDrafts = List<_OpponentPlayerDraft>.from(_opponentPlayerDrafts);
    _retiredOpponentDrafts.addAll(oldDrafts);
    _opponentPlayerDrafts.clear();

    if (players.isEmpty) {
      _opponentPlayerDrafts.add(_OpponentPlayerDraft());
    } else {
      for (final player in players.take(24)) {
        final draft = _OpponentPlayerDraft()..applyFromInput(player);
        _opponentPlayerDrafts.add(draft);
      }
    }

  }

  _ImportedOpponentReport _parseImportedReport(Map<String, dynamic> root) {
    final opponent = _asMap(root['opponent']);
    final opponentReport = _asMap(root['opponent_report']);

    final style = _pickString([
      root['opponentStyle'],
      root['opponent_style'],
      root['style'],
      opponent?['style'],
      opponent?['opponentStyle'],
    ]);

    final teamName = _pickString([
      root['opponentTeamName'],
      root['opponent_team_name'],
      root['teamName'],
      opponent?['teamName'],
      opponent?['team_name'],
      opponentReport?['team_name'],
    ]);

    final preferredFormation = _pickString([
      root['preferredFormation'],
      root['preferred_formation'],
      root['formation'],
      opponent?['preferredFormation'],
      opponent?['preferred_formation'],
      opponentReport?['preferred_formation'],
    ]);

    final strengths = _pickTags([
      root['strengths'],
      opponent?['strengths'],
      opponentReport?['strengths'],
    ]);

    final weaknesses = _pickTags([
      root['weaknesses'],
      opponent?['weaknesses'],
      opponentReport?['weaknesses'],
    ]);

    final players = _pickPlayers([
      root['opponentSquad'],
      root['opponent_squad'],
      opponent?['squad'],
      opponentReport?['squad'],
      root['squad'],
      root['players'],
      opponent?['players'],
    ]);

    return _ImportedOpponentReport(
      opponentStyle: style,
      opponentTeamName: teamName,
      preferredFormation: preferredFormation,
      strengths: strengths,
      weaknesses: weaknesses,
      players: players,
    );
  }

  String? _pickString(List<dynamic> candidates) {
    for (final value in candidates) {
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  List<String> _pickTags(List<dynamic> candidates) {
    for (final value in candidates) {
      final tags = _tagsFromDynamic(value);
      if (tags.isNotEmpty) {
        return tags;
      }
    }
    return const [];
  }

  List<String> _tagsFromDynamic(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'[,;\n]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }
    return const [];
  }

  List<OpponentSquadPlayerInput> _pickPlayers(List<dynamic> candidates) {
    for (final value in candidates) {
      final players = _playersFromDynamic(value);
      if (players.isNotEmpty) {
        return players;
      }
    }
    return const [];
  }

  List<OpponentSquadPlayerInput> _playersFromDynamic(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final players = <OpponentSquadPlayerInput>[];
    for (final item in value) {
      final row = _asMap(item);
      if (row == null) {
        continue;
      }

      final stats = _asMap(row['stats']) ??
          _asMap(row['statistics']) ??
          _asMap(row['player_stats']);

      final name = _pickString([
        row['name'],
        row['player_name'],
        row['playerName'],
        row['full_name'],
      ]);
      final position = _pickString([
        row['position'],
        row['role'],
        row['poste'],
      ]);

      if (name == null || position == null) {
        continue;
      }

      final rating = _toDouble(row['rating']) ?? _toDouble(stats?['rating']) ?? _toDouble(row['note']);
      final goals = _toInt(row['goals']) ?? _toInt(stats?['goals']);
      final assists = _toInt(row['assists']) ?? _toInt(stats?['assists']);
      final shots = _toInt(row['shots']) ?? _toInt(stats?['shots']);
      final passes = _toInt(row['passes']) ?? _toInt(stats?['passes']);
      final tackles = _toInt(row['tackles']) ?? _toInt(stats?['tackles']);
      final minutes = _toInt(row['minutes']) ?? _toInt(stats?['minutes']);

      final statsInput = OpponentPlayerStatsInput(
        rating: rating,
        goals: goals,
        assists: assists,
        shots: shots,
        passes: passes,
        tackles: tackles,
        minutes: minutes,
      );

      players.add(
        OpponentSquadPlayerInput(
          name: name,
          position: position.toUpperCase(),
          status: _pickString([row['status'], row['lineupStatus']]),
          rating: rating,
          stats: statsInput.toJson().isNotEmpty ? statsInput : null,
        ),
      );
    }

    return players;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.of(context);
    final canGoBack = Navigator.of(context).canPop() || shell != null;
    final detailedModeActive = _showAdvancedInputs && _hasDetailedReportInput();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('IA Tactique'),
        centerTitle: false,
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: canGoBack
            ? IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).maybePop();
                    return;
                  }

                  if (shell != null) {
                    final fallbackRoute = MenuConfig.defaultRouteForRole(shell.session.role);
                    shell.navigate(fallbackRoute);
                  }
                },
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulaire
            Text(
              'Profil rapide de l\'adversaire',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _primary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: _panelDecoration(radius: 12, elevated: false),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedStyle,
                  items: _oppStyles.map((s) {
                    return DropdownMenuItem<String>(
                      value: s['value'],
                      child: Text(s['label']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStyle = val);
                  },
                ),
              ),
            ),
            if (detailedModeActive) ...[
              const SizedBox(height: 8),
              Text(
                'Mode rapport detaille actif: cette selection de style est ignoree pour l\'analyse.',
                style: TextStyle(fontSize: 12, color: _warning, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _showAdvancedInputs,
              onChanged: (value) => setState(() => _showAdvancedInputs = value),
              title: Text(
                'Rapport adverse detaille',
                style: TextStyle(fontWeight: FontWeight.w700, color: _primary),
              ),
              subtitle: const Text(
                'Ajouter equipe reelle, style, formation, forces, faiblesses et joueurs cles.',
              ),
            ),
            if (_showAdvancedInputs) ...[
              const SizedBox(height: 8),
              _buildAdvancedOpponentForm(),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateTactics,
                icon: _isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.psychology, color: Colors.white),
                label: const Text('Générer le 11 de départ via IA', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Plan de jeu
            if (_plan != null) ...[
              // Cartouche Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _panelDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield, color: _primary),
                        const SizedBox(width: 8),
                        Text(
                          'Formation : ${_plan!.formation}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
                        ),
                      ],
                    ),
                    Text(
                      _plan!.instructions,
                      style: TextStyle(fontSize: 15, color: _textSecondary, height: 1.4),
                    ),
                    if (_plan!.strengths.isNotEmpty || _plan!.weaknesses.isNotEmpty) ...[
                      const Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Icon(Icons.add_circle, color: _success, size: 16), const SizedBox(width: 6), Text('Forces', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _success))]),
                                const SizedBox(height: 6),
                                ..._plan!.strengths.map((s) => Text('• $s', style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [Icon(Icons.remove_circle, color: _danger, size: 16), const SizedBox(width: 6), Text('Faiblesses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _danger))]),
                                const SizedBox(height: 6),
                                ..._plan!.weaknesses.map((w) => Text('• $w', style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_plan!.opponent != null ||
                  _plan!.summaryByPosition.isNotEmpty ||
                  _plan!.keyPlayers.isNotEmpty ||
                  _plan!.tacticalFocus.isNotEmpty ||
                  _plan!.realism != null) ...[
                _buildOpponentInsights(_plan!),
                const SizedBox(height: 24),
              ],

              if (_plan!.dangerPrincipal != null) ...[
                _buildDangerPrincipal(_plan!.dangerPrincipal!),
                const SizedBox(height: 24),
              ],
              
              if (_plan!.consignesCollectives != null) ...[
                _buildConsignesCollectives(_plan!.consignesCollectives!),
                const SizedBox(height: 24),
              ],

              // Terrain de football
              Text(
                'Composition suggérée',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _primary),
              ),
              const SizedBox(height: 12),
              _buildFootballPitch(),
              const SizedBox(height: 24),

              if (_plan!.phasesArretees != null) ...[
                _buildPhasesArretees(_plan!.phasesArretees!),
                const SizedBox(height: 24),
              ],

              if (_plan!.variantesSelonScore != null) ...[
                _buildVariantesScore(_plan!.variantesSelonScore!),
                const SizedBox(height: 24),
              ],

              if (_plan!.messageVestiaire != null) ...[
                _buildMessageVestiaire(_plan!.messageVestiaire!),
                const SizedBox(height: 24),
              ],
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOpponentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(radius: 12, elevated: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Rapport adverse',
                style: TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 16),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _openJsonImportDialog,
                icon: const Icon(Icons.file_upload_outlined, size: 16),
                label: const Text('Importer JSON'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Collez un payload brut et le formulaire sera rempli automatiquement.',
            style: TextStyle(fontSize: 12, color: _textMuted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _opponentTeamController,
            decoration: const InputDecoration(
              labelText: 'Equipe adverse',
              hintText: 'Ex: Wydad AC',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _preferredFormationController,
            decoration: const InputDecoration(
              labelText: 'Formation adverse',
              hintText: 'Ex: 4-3-3',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _detailedOpponentStyleController,
            decoration: const InputDecoration(
              labelText: 'Style adverse (optionnel)',
              hintText: 'Ex: pressing haut, transitions rapides',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _strengthsController,
            decoration: const InputDecoration(
              labelText: 'Points forts (separes par virgule)',
              hintText: 'Transitions rapides, Pressing',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _weaknessesController,
            decoration: const InputDecoration(
              labelText: 'Points faibles (separes par virgule)',
              hintText: 'CPA defensifs, couloirs',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.groups_2, color: _primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Joueurs adverses (optionnel)',
                style: TextStyle(fontWeight: FontWeight.w700, color: _primary),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _opponentPlayerDrafts.length >= 8
                    ? null
                    : () => setState(() => _opponentPlayerDrafts.add(_OpponentPlayerDraft())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(_opponentPlayerDrafts.length, (index) {
            return _buildOpponentPlayerDraftCard(index, _opponentPlayerDrafts[index]);
          }),
        ],
      ),
    );
  }

  Widget _buildOpponentPlayerDraftCard(int index, _OpponentPlayerDraft draft) {
    return KeyedSubtree(
      key: ValueKey(draft.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: _panelDecoration(
          color: _surfaceAlt,
          radius: 10,
          elevated: false,
        ),
        child: Column(
          children: [
          Row(
            children: [
              Text(
                'Joueur ${index + 1}',
                style: TextStyle(fontWeight: FontWeight.bold, color: _primary),
              ),
              const Spacer(),
              if (_opponentPlayerDrafts.length > 1)
                IconButton(
                  tooltip: 'Retirer',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    late _OpponentPlayerDraft removed;
                    setState(() {
                      removed = _opponentPlayerDrafts.removeAt(index);
                      _retiredOpponentDrafts.add(removed);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: draft.positionController,
                  decoration: const InputDecoration(
                    labelText: 'Poste',
                    hintText: 'RW, CM, CB',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.ratingController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: '7.4',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: draft.goalsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Buts',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: draft.assistsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Passes D',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.shotsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tirs',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: draft.passesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Passes',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: draft.tacklesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tacles',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: draft.minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minutes',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpponentInsights(TacticalPlan plan) {
    final orderedKeys = ['GK', 'DEF', 'MID', 'ATT', 'OTHER'];
    final displayedSummaryKeys = orderedKeys
        .where((key) => plan.summaryByPosition.containsKey(key))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: _primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Analyse adverse enrichie',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _primary),
                ),
              ),
              if (plan.aiSource != null && plan.aiSource!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    plan.aiSource!,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primary),
                  ),
                ),
            ],
          ),
          if (plan.opponent != null) ...[
            const SizedBox(height: 10),
            Text(
              '${plan.opponent!.teamName.isEmpty ? 'Adversaire' : plan.opponent!.teamName} • ${plan.opponent!.style.isEmpty ? (_cleanText(_detailedOpponentStyleController.text) ?? 'Style auto-deduit') : plan.opponent!.style}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (plan.opponent!.preferredFormation != null &&
                plan.opponent!.preferredFormation!.isNotEmpty)
              Text(
                'Formation adverse: ${plan.opponent!.preferredFormation}',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
          ],
          if (plan.realism != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRealismChip('Squad reel', plan.realism!.hasRealOpponentSquad),
                _buildRealismChip('Stats joueurs', plan.realism!.hasIndividualPlayerStats),
                _buildRealismChip('Forces renseignees', plan.realism!.hasDeclaredStrengths),
                _buildRealismChip('Faiblesses renseignees', plan.realism!.hasDeclaredWeaknesses),
              ],
            ),
          ],
          if (plan.tacticalFocus.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Focus tactique recommande', style: TextStyle(fontWeight: FontWeight.bold, color: _primary)),
            const SizedBox(height: 6),
            ...plan.tacticalFocus.take(4).map((focus) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $focus', style: const TextStyle(fontSize: 13)),
                )),
          ],
          if (plan.keyPlayers.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Joueurs adverses a surveiller', style: TextStyle(fontWeight: FontWeight.bold, color: _primary)),
            const SizedBox(height: 6),
            ...plan.keyPlayers.take(4).map((player) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${player.name} (${player.position})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        'Threat ${player.threatScore.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 12, color: _warning, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
          ],
          if (displayedSummaryKeys.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Resume par ligne', style: TextStyle(fontWeight: FontWeight.bold, color: _primary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayedSummaryKeys.map((key) {
                final summary = plan.summaryByPosition[key]!;
                return Container(
                  width: 150,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(key, style: TextStyle(fontWeight: FontWeight.bold, color: _primary)),
                      const SizedBox(height: 4),
                      Text('Joueurs: ${summary.count}', style: const TextStyle(fontSize: 12)),
                      Text('Note moy: ${summary.averageRating.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                      Text('Buts: ${summary.totalGoals}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRealismChip(String label, bool enabled) {
    final color = enabled ? _success : _warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(enabled ? Icons.check_circle : Icons.info_outline, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFootballPitch() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = width * 1.5; // Aspect ratio classique d'un terrain

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.green.shade800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.white, width: 3),
          ),
          child: Stack(
            children: [
              // Lignes du terrain 
              Center(
                child: Container(
                  height: 2,
                  color: AppTheme.white.withValues(alpha: 0.5),
                ),
              ),
              Center(
                child: Container(
                  width: width * 0.3,
                  height: width * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.white.withValues(alpha: 0.5), width: 2),
                  ),
                ),
              ),
              // Surface de réparation haute
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: width * 0.5,
                  height: height * 0.15,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.white.withValues(alpha: 0.5), width: 2),
                      left: BorderSide(color: AppTheme.white.withValues(alpha: 0.5), width: 2),
                      right: BorderSide(color: AppTheme.white.withValues(alpha: 0.5), width: 2),
                    ),
                  ),
                ),
              ),
              // Surface de réparation basse
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: width * 0.5,
                  height: height * 0.15,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.white.withValues(alpha: 0.5), width: 2),
                      left: BorderSide(color: AppTheme.white.withValues(alpha: 0.5), width: 2),
                      right: BorderSide(color: AppTheme.white.withValues(alpha: 0.5), width: 2),
                    ),
                  ),
                ),
              ),

              // Joueurs positionnés (le python renvoie y entre 0 et 1 (0 = attaque, 1 = gardien en bas))
              ..._plan!.startingXi.map((p) {
                return Positioned(
                  left: (p.x * width) - 30, // Centrage x
                  top: (p.y * height) - 30, // Centrage y
                  child: GestureDetector(
                    onTap: () => _showPlayerInstruction(context, p),
                    child: SizedBox(
                      width: 60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _primary, width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                            ),
                            child: Center(
                              child: Text(
                                p.role,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.playerName.split(' ').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showPlayerInstruction(BuildContext context, TacticalPlayer p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.82),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: _border),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _primary.withValues(alpha: 0.1),
                            child: Text(p.role, style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.playerName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
                                Text(p.roleLabel.isNotEmpty ? p.roleLabel : 'Rôle: ${p.role}', style: TextStyle(fontSize: 13, color: _textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Consigne Spécifique', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: _accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accent.withValues(alpha: 0.3))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb, color: _accent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(p.instruction ?? 'Aucune consigne spécifique.', style: const TextStyle(fontSize: 14, height: 1.4))),
                          ],
                        ),
                      ),
                      if (p.actionsCles.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('Actions Clés', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        ...p.actionsCles.map((action) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle, color: _success, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(action, style: TextStyle(fontSize: 13, color: _textPrimary))),
                                ],
                              ),
                            )),
                      ],
                      if (p.joueurAdverseASurveiller != null) ...[
                        const SizedBox(height: 20),
                        Text('Attention Marquage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _warning)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _warning.withValues(alpha: 0.3))),
                          child: Row(
                            children: [
                              Icon(Icons.visibility, color: _warning, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(p.joueurAdverseASurveiller!, style: TextStyle(fontSize: 13, color: _textPrimary))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDangerPrincipal(String danger) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: _warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Danger Principal Adversaire', style: TextStyle(fontWeight: FontWeight.bold, color: _warning, fontSize: 15)),
                const SizedBox(height: 6),
                Text(danger, style: TextStyle(color: _textPrimary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsignesCollectives(ConsignesCollectives consignes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: _primary),
              const SizedBox(width: 8),
              Text('Consignes Collectives', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
            ],
          ),
          const SizedBox(height: 16),
          _buildPhaseList('Phase Défensive', consignes.phasesDefensives, Icons.shield),
          const Divider(),
          _buildPhaseList('Phase Offensive', consignes.phasesOffensives, Icons.sports_soccer),
          const Divider(),
          _buildPhaseList('Transitions', [...consignes.transitionsOffensives, ...consignes.transitionsDefensives], Icons.swap_horiz),
        ],
      ),
    );
  }

  Widget _buildPhaseList(String title, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _textSecondary),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPhasesArretees(PhasesArretees phases) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phases Arrêtées', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoRow('Corners Pour', phases.cornersPour),
          _buildInfoRow('Corners Contre', phases.cornersContre),
          _buildInfoRow('CF Pour', phases.coupsFrancsPour),
          _buildInfoRow('CF Contre', phases.coupsFrancsContre),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildVariantesScore(VariantesSelonScore variantes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(color: _surfaceAlt),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.score, color: _primary),
              const SizedBox(width: 8),
              Text('Variantes selon Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildScoreRow('Si on mène', variantes.siOnMene, _success),
          _buildScoreRow('Si égalité', variantes.siEgalite, _textSecondary),
          _buildScoreRow('Si on perd', variantes.siOnPerd, _danger),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String state, String instruction, Color color) {
    if (instruction.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(state, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          const SizedBox(height: 2),
          Text(instruction, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMessageVestiaire(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(color: _surfaceAlt),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.record_voice_over, color: _primary, size: 20),
              const SizedBox(width: 8),
              Text('Message Vestiaire (Coach)', style: TextStyle(fontWeight: FontWeight.bold, color: _primary, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$message"',
            style: TextStyle(color: _textPrimary, fontStyle: FontStyle.italic, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ImportedOpponentReport {
  final String? opponentStyle;
  final String? opponentTeamName;
  final String? preferredFormation;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<OpponentSquadPlayerInput> players;

  const _ImportedOpponentReport({
    this.opponentStyle,
    this.opponentTeamName,
    this.preferredFormation,
    this.strengths = const [],
    this.weaknesses = const [],
    this.players = const [],
  });
}

class _OpponentPlayerDraft {
  bool _disposed = false;
  final String id = UniqueKey().toString();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();
  final TextEditingController goalsController = TextEditingController();
  final TextEditingController assistsController = TextEditingController();
  final TextEditingController shotsController = TextEditingController();
  final TextEditingController passesController = TextEditingController();
  final TextEditingController tacklesController = TextEditingController();
  final TextEditingController minutesController = TextEditingController();

  void applyFromInput(OpponentSquadPlayerInput player) {
    nameController.text = player.name;
    positionController.text = player.position;
    ratingController.text = player.rating?.toString() ?? player.stats?.rating?.toString() ?? '';
    goalsController.text = player.stats?.goals?.toString() ?? '';
    assistsController.text = player.stats?.assists?.toString() ?? '';
    shotsController.text = player.stats?.shots?.toString() ?? '';
    passesController.text = player.stats?.passes?.toString() ?? '';
    tacklesController.text = player.stats?.tackles?.toString() ?? '';
    minutesController.text = player.stats?.minutes?.toString() ?? '';
  }

  OpponentSquadPlayerInput? toRequestModel() {
    final name = nameController.text.trim();
    final position = positionController.text.trim().toUpperCase();
    if (name.isEmpty || position.isEmpty) {
      return null;
    }

    final rating = _parseDouble(ratingController.text);
    final goals = _parseInt(goalsController.text);
    final assists = _parseInt(assistsController.text);
    final shots = _parseInt(shotsController.text);
    final passes = _parseInt(passesController.text);
    final tackles = _parseInt(tacklesController.text);
    final minutes = _parseInt(minutesController.text);

    final stats = OpponentPlayerStatsInput(
      rating: rating,
      goals: goals,
      assists: assists,
      shots: shots,
      passes: passes,
      tackles: tackles,
      minutes: minutes,
    );

    final hasStats = stats.toJson().isNotEmpty;

    return OpponentSquadPlayerInput(
      name: name,
      position: position,
      status: 'starter',
      rating: rating,
      stats: hasStats ? stats : null,
    );
  }

  int? _parseInt(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return null;
    }
    return int.tryParse(cleaned);
  }

  double? _parseDouble(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return null;
    }
    return double.tryParse(cleaned);
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    nameController.dispose();
    positionController.dispose();
    ratingController.dispose();
    goalsController.dispose();
    assistsController.dispose();
    shotsController.dispose();
    passesController.dispose();
    tacklesController.dispose();
    minutesController.dispose();
  }
}
