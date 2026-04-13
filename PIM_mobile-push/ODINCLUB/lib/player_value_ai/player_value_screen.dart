import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../services/api_service.dart';
import '../ui/components/app_card.dart';
import '../ui/theme/app_spacing.dart';
import '../finance/theme/finance_theme.dart';
import 'player_value_api.dart';
import 'player_value_models.dart';

class PlayerValueScreen extends StatefulWidget {
  const PlayerValueScreen({super.key});

  @override
  State<PlayerValueScreen> createState() => _PlayerValueScreenState();
}

class _PlayerValueScreenState extends State<PlayerValueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = PlayerValueApi();
  final _backend = ApiService();

  final _ageController = TextEditingController(text: '24');
  final _minutesController = TextEditingController(text: '2850');
  final _goalsController = TextEditingController(text: '12');
  final _assistsController = TextEditingController(text: '8');
  final _valueController = TextEditingController(text: '45000000');
  int _injuries = 0;

  bool _loading = false;
  String? _error;
  PlayerValueResponse? _result;

  bool _loadingPlayers = false;
  bool _loadingAnalyses = false;
  List<PlayerModel> _players = [];
  PlayerModel? _selectedPlayer;
  List<Map<String, dynamic>> _analyses = [];

  int _viewIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _minutesController.dispose();
    _goalsController.dispose();
    _assistsController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _loadingPlayers = true;
    });
    try {
      final response = await _backend.getPlayers(page: 1, limit: 200);
      if (response['success'] == true) {
        final data = response['data'];
        final list = data is List
            ? data
            : (data is Map && data['data'] is List ? data['data'] as List : []);
        final players = list
            .map((item) =>
                PlayerModel.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _players = players;
          if (_selectedPlayer == null && players.isNotEmpty) {
            _selectedPlayer = players.first;
            _loadAnalyses(players.first.id);
          }
        });
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _loadingPlayers = false);
      }
    }
  }

  Future<void> _loadAnalyses(String playerId) async {
    setState(() {
      _loadingAnalyses = true;
      _analyses = [];
    });
    try {
      final response = await _backend.getPlayerAnalyses(playerId);
      if (response['success'] == true) {
        final data = response['data'];
        final list = data is List
            ? data
            : (data is Map && data['data'] is List ? data['data'] as List : []);
        setState(() {
          _analyses = list
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _loadingAnalyses = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final request = PlayerValueRequest(
        age: int.parse(_ageController.text),
        minutesPlayed: int.parse(_minutesController.text),
        goals: int.parse(_goalsController.text),
        assists: int.parse(_assistsController.text),
        injuriesLastSeason: _injuries,
        currentMarketValue: double.parse(_valueController.text),
      );

      final response = await _api.predict(request);
      setState(() {
        _result = response;
        _viewIndex = 1;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    FinancePalette.setDarkMode(Theme.of(context).brightness == Brightness.dark);
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _viewIndex == 0
                ? _buildValuationView(context)
                : _buildForecastView(context),
          ),
        ),
        _buildBottomNav(context),
      ],
    );
  }

  Widget _buildValuationView(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('valuation'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(context, showBack: false),
          const SizedBox(height: 12),
          Text(
            'Market Valuation',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Enter performance metrics to calculate projected player worth via Value AI.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: FinancePalette.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metricField('AGE', _ageController),
                  _metricField('MINUTES PLAYED', _minutesController),
                  _metricField('GOALS', _goalsController),
                  _metricField('ASSISTS', _assistsController),
                  _injuryDropdown(),
                  _metricField('CURRENT MARKET VALUE', _valueController,
                      prefixText: '€ '),
                  const SizedBox(height: AppSpacing.s16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: FinancePalette.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _loading ? 'Predicting...' : 'Predict Value',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'POWERED BY PROPRIETARY NEURAL SCOUT ENGINE',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FinancePalette.muted,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(
            icon: Icons.trending_up_rounded,
            title: 'Predictive Accuracy',
            body:
                'Our AI models maintain a 94.2% correlation with actual transfer fees across European Top 5 leagues.',
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.verified_user_rounded,
            title: 'Verified Data',
            body:
                'Sourced from real-time performance telemetry and historical valuation benchmarks.',
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorCard(context, _error!),
          ],
        ],
      ),
    );
  }

  Widget _buildForecastView(BuildContext context) {
    final latest = _analyses.isNotEmpty ? _analyses.first : null;
    return SingleChildScrollView(
      key: const ValueKey('forecast'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(context, showBack: true),
          const SizedBox(height: 12),
          Text(
            'Market Selector',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: FinancePalette.cyan,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                if (_loadingPlayers)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    value: _selectedPlayer?.id,
                    items: _players
                        .map(
                          (player) => DropdownMenuItem<String>(
                            value: player.id,
                            child: Text(player.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null || _players.isEmpty) return;
                      final selected = _players.firstWhere(
                        (p) => p.id == value,
                        orElse: () => _players.first,
                      );
                      setState(() {
                        _selectedPlayer = selected;
                      });
                      _loadAnalyses(selected.id);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Player',
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _submit,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: FinancePalette.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Run New Prediction'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingAnalyses)
            const LinearProgressIndicator()
          else if (latest == null)
            _emptyState('No analyses found for this player.')
          else ...[
            _analysisForecastCard(context, latest),
            const SizedBox(height: 16),
            _vitalsCard(context, latest),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _marketValuationCard(context),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorCard(context, _error!),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: FinancePalette.card,
        border: Border(top: BorderSide(color: FinancePalette.soft)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.sports_soccer_rounded, 'Pitch', false),
          _navItem(Icons.search_rounded, 'Scout', false),
          _navCenterItem(),
          _navItem(Icons.groups_rounded, 'Squad', false),
          _navItem(Icons.cases_rounded, 'Office', false),
        ],
      ),
    );
  }

  Widget _headerRow(BuildContext context, {required bool showBack}) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: () => setState(() => _viewIndex = 0),
            icon: const Icon(Icons.arrow_back),
          )
        else
          CircleAvatar(
            radius: 18,
            backgroundColor: FinancePalette.soft,
            child: Icon(Icons.person, color: FinancePalette.cyan),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'PLAYER VALUE AI',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              letterSpacing: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    final color = active ? FinancePalette.blue : FinancePalette.muted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _navCenterItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: FinancePalette.blue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FinancePalette.blue.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            'VALUE AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricField(String label, TextEditingController controller,
      {String? prefixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: FinancePalette.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            validator: _requiredNumber,
            decoration: InputDecoration(
              prefixText: prefixText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _injuryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INJURIES LAST SEASON',
            style: TextStyle(
              color: FinancePalette.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _injuries,
            items: List.generate(
              6,
              (i) => DropdownMenuItem<int>(
                value: i,
                child: Text(i == 0 ? 'None' : i.toString()),
              ),
            ),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _injuries = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String body}) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FinancePalette.soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: FinancePalette.cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FinancePalette.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return AppCard(
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: FinancePalette.muted,
        ),
      ),
    );
  }

  Widget _analysisForecastCard(BuildContext context, Map<String, dynamic> analysis) {
    final ai = analysis['aiAnalysis'] as Map<String, dynamic>? ?? {};
    final confidence = ai['confidence'];
    final cluster = ai['cluster'];
    final potential = ai['potentialScore'];
    final analyzedAt = ai['analyzedAt'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FinancePalette.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_graph_rounded, color: FinancePalette.cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Performance Forecast',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Last analysis computed on ${analyzedAt ?? '-'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FinancePalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FinancePalette.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LIVE ENGINE ACTIVE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FinancePalette.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Prediction Confidence',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: confidence is num ? confidence.toDouble() : 0.0,
            color: FinancePalette.blue,
            backgroundColor: FinancePalette.soft,
          ),
          const SizedBox(height: 12),
          Text('Tactical Cluster: ${cluster ?? '-'}'),
          Text('Potential Ceiling: ${potential ?? '-'} / 100'),
        ],
      ),
    );
  }

  Widget _vitalsCard(BuildContext context, Map<String, dynamic> analysis) {
    final ai = analysis['aiAnalysis'] as Map<String, dynamic>? ?? {};
    final metrics = ai['metrics'] as Map<String, dynamic>? ?? {};
    final items = {
      'Speed': metrics['speed'],
      'Endurance': metrics['endurance'],
      'Distance': metrics['distance'],
      'Dribbles': metrics['dribbles'],
      'Shots': metrics['shots'],
      'Injuries': metrics['injuries'],
      'Heart Rate': metrics['heart_rate'],
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vitals & Output',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.entries
                .map(
                  (entry) => Container(
                    width: 130,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FinancePalette.soft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: FinancePalette.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.value?.toString() ?? '-',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _marketValuationCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Market Valuation',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _result!.predictedValue.toStringAsFixed(2),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: FinancePalette.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text('Growth: ${_result!.growthPercent.toStringAsFixed(2)}%'),
          Text('Trend: ${_result!.trend}'),
          Text('Confidence: ${(_result!.confidence * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _errorCard(BuildContext context, String message) {
    return AppCard(
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return int.tryParse(value.trim()) == null ? 'Number required' : null;
  }
}
