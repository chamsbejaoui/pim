import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../models/exercise.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/players_provider.dart';
import '../../models/player.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import 'stopwatch_performance_screen.dart';

class GeneratorForm extends ConsumerStatefulWidget {
  final String? initialPlayerId;
  final String? initialObjective;

  const GeneratorForm({
    Key? key,
    this.initialPlayerId,
    this.initialObjective,
  }) : super(key: key);

  @override
  ConsumerState<GeneratorForm> createState() => _GeneratorFormState();
}

class _GeneratorFormState extends ConsumerState<GeneratorForm> {
  PitchPosition _selectedPosition = PitchPosition.mid;
  String _selectedAge = 'Professional';
  double _duration = 10.0;
  String _objective = '';
  double _fatigueLevel = 30;
  String? _selectedPlayerId;

  final TextEditingController _objectiveController = TextEditingController();

  final Map<String, double> _durationOptions = {
    '5 min': 5.0,
    '10 min': 10.0,
    '15 min': 15.0,
    '20 min': 20.0,
    '30 min': 30.0,
  };

  @override
  void initState() {
    super.initState();
    _selectedPlayerId = widget.initialPlayerId;
    _objective = widget.initialObjective ?? '';
    _objectiveController.text = _objective;
    
    // Si un joueur est pré-sélectionné, on essaiera de mettre à jour son poste plus tard via le provider
  }

  @override
  void dispose() {
    _objectiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(aiDrillGenerationProvider);

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('AI DRILL GENERATOR'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.initialObjective != null) _buildPrescriptionBanner(),
            const SizedBox(height: 16),
            _buildSectionHeader('Poste Cible', Icons.person_pin_circle_outlined),
            const SizedBox(height: 16),
            _buildPositionSelector(),
            const SizedBox(height: 32),

            _buildSectionHeader('Joueur Concerné (Optionnel)', Icons.person_search_outlined),
            const SizedBox(height: 16),
            _buildPlayerSelector(),
            if (_selectedPlayerId != null) ...[
              const SizedBox(height: 16),
              _buildAiInsight(),
            ],
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Âge', Icons.calendar_month_outlined),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        value: _selectedAge,
                        items: ['Academy (U9-U12)', 'Youth (U13-U16)', 'Elite (U17-U23)', 'Professional'],
                        onChanged: (val) => setState(() => _selectedAge = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Durée', Icons.timer_outlined),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        value: _durationOptions.entries
                            .firstWhere((e) => e.value == _duration)
                            .key,
                        items: _durationOptions.keys.toList(),
                        onChanged: (val) => setState(() => _duration = _durationOptions[val]!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('Objectif Principal', Icons.bolt_outlined),
            const SizedBox(height: 12),
            TextField(
              controller: _objectiveController,
              onChanged: (val) => _objective = val,
              decoration: const InputDecoration(
                hintText: 'ex: Explosivité, Précision...',
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('Niveau de Fatigue', Icons.battery_charging_full_outlined),
            const SizedBox(height: 8),
            _buildFatigueSlider(),
            const SizedBox(height: 40),

            _buildGenerateButton(generationState.isLoading),

            const SizedBox(height: 32),
            if (generationState.hasValue && generationState.value != null)
              _buildResultArea(generationState.value!)
            else if (generationState.isLoading)
              _buildLoadingPlaceholder()
            else if (generationState.hasError)
              _buildErrorArea(generationState.error.toString())
            else
              _buildEmptyPlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: SPColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: SPTypography.label.copyWith(
            color: SPColors.textSecondary,
            letterSpacing: 1.0,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SPColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRESCRIPTION D\'ACTION IA',
                  style: SPTypography.overline.copyWith(
                    color: SPColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Basé sur les dernières analyses de scouting pour corriger : ${widget.initialObjective}',
                  style: SPTypography.bodySmall.copyWith(color: SPColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: PitchPosition.values.map((pos) {
        final isSelected = _selectedPosition == pos;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedPosition = pos),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? SPColors.primaryBlue.withOpacity(0.1) : SPColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? SPColors.primaryBlue : SPColors.borderPrimary,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: SPColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    pos.value,
                    style: TextStyle(
                      color: isSelected ? Colors.white : SPColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: SPColors.backgroundTertiary,
        ),
      ),
    );
  }

  Widget _buildFatigueSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getFatigueLabel(),
              style: TextStyle(
                color: _getFatigueColor(),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SPColors.badgeTechnical.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_fatigueLevel.toInt()}%',
                style: const TextStyle(
                  color: SPColors.badgeTechnical,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: SPColors.badgeTechnical,
            inactiveTrackColor: SPColors.backgroundTertiary,
            thumbColor: Colors.white,
            overlayColor: SPColors.badgeTechnical.withOpacity(0.2),
          ),
          child: Slider(
            value: _fatigueLevel,
            min: 1,
            max: 100,
            onChanged: (val) => setState(() => _fatigueLevel = val),
          ),
        ),
      ],
    );
  }

  String _getFatigueLabel() {
    if (_fatigueLevel < 30) return 'FRESH';
    if (_fatigueLevel < 70) return 'MODERATE';
    return 'EXHAUSTED';
  }

  Color _getFatigueColor() {
    if (_fatigueLevel < 30) return SPColors.success;
    if (_fatigueLevel < 70) return SPColors.warning;
    return SPColors.error;
  }

  Widget _buildGenerateButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : _generate,
        style: ElevatedButton.styleFrom(
          backgroundColor: SPColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          shadowColor: SPColors.primaryBlue.withOpacity(0.5),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.auto_awesome),
                  SizedBox(width: 12),
                  Text(
                    'GENERATE SMART DRILL',
                    style: TextStyle(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResultArea(Exercise exercise) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: SPColors.badgeTechnical, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: SPTypography.h3.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              // Hero GIF Section with Overlays
              if (exercise.imageUrl != null)
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SPColors.primaryBlue.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Image.network(
                          exercise.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.white.withOpacity(0.05),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Overlay Live View (Only for non-static images)
                    if (_isGif(exercise.imageUrl))
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LOOPING LIVE VIEW',
                              style: SPTypography.caption.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Tactical Diagram Badge
                    if (!_isGif(exercise.imageUrl))
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: SPColors.primaryBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'STRATÉGIE 2D/3D',
                            style: SPTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                    // Replay Indicator (Only for GIFs)
                    if (exercise.imageUrl!.contains('.gif'))
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 70),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SPColors.primaryBlue.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: SPColors.primaryBlue.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.replay_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              // Title and Metadata
              Text(
                exercise.name.toUpperCase(),
                style: SPTypography.h2.copyWith(color: Colors.white, fontSize: 20, letterSpacing: 1.1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSmallMetric(Icons.timer_outlined, '${exercise.duration.toInt()} Mins'),
                  const SizedBox(width: 16),
                  _buildSmallMetric(Icons.bolt, exercise.difficulty > 3 ? 'Pro Level' : 'Club Level'),
                  const SizedBox(width: 16),
                  _buildSmallMetric(Icons.straighten_rounded, '${exercise.technicalData?.equipment.length ?? 0} Items'),
                ],
              ),
              
              // Démarche Section (Cards)
              if (exercise.technicalData?.steps.isNotEmpty ?? false) ...[
                Text(
                  'DÉMARCHE DE L\'EXERCICE',
                  style: SPTypography.label.copyWith(
                    color: SPColors.primaryBlue,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: exercise.technicalData!.steps.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final isFirst = index == 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isFirst ? SPColors.primaryBlue.withOpacity(0.05) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFirst ? SPColors.primaryBlue.withOpacity(0.3) : SPColors.borderPrimary.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isFirst ? SPColors.primaryBlue : SPColors.backgroundTertiary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '$index',
                                  style: TextStyle(
                                    color: isFirst ? Colors.white : SPColors.textTertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: SPTypography.bodySmall.copyWith(
                                  color: isFirst ? Colors.white : SPColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              Row(
                children: [
                  _buildMetricCell('Séries', exercise.technicalData?.sets.toString() ?? '-'),
                  _buildMetricCell('Reps', exercise.technicalData?.reps.toString() ?? '-'),
                  _buildMetricCell('Difficulté', '${exercise.difficulty}/5'),
                ],
              ),
              const SizedBox(height: 24),
              // Equipment
              Text(
                'MATÉRIEL REQUIS',
                style: SPTypography.caption.copyWith(
                  color: SPColors.textTertiary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (exercise.technicalData?.equipment ?? []).map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: SPColors.backgroundTertiary,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: SPColors.borderPrimary),
                    ),
                    child: Text(
                      item.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // Start Button for Generator Result
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: SPColors.primaryBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: SPColors.primaryBlue.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StopwatchPerformanceScreen(exercise: exercise),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'DÉMARRER L\'EXERCICE',
                          style: SPTypography.label.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCell(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SPTypography.caption.copyWith(color: SPColors.textTertiary)),
          const SizedBox(height: 4),
          Text(value, style: SPTypography.h4.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPlayerSelector() {
    final playersAsync = ref.watch(playersProvider);

    return playersAsync.when(
      data: (players) => SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: players.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              final isSelected = _selectedPlayerId == null;
              return _buildPlayerCard(null, isSelected);
            }
            final player = players[index - 1];
            final isSelected = _selectedPlayerId == player.id;
            return _buildPlayerCard(player, isSelected);
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, r) => const Text('Erreur chargement joueurs'),
    );
  }

  Widget _buildPlayerCard(Player? player, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlayerId = player?.id;
          if (player != null) {
            // Auto-select position if player is chosen
            _selectedPosition = PitchPosition.fromString(player.position);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? SPColors.primaryBlue.withOpacity(0.1) : SPColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SPColors.primaryBlue : SPColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isSelected ? SPColors.primaryBlue : SPColors.backgroundTertiary,
              child: Text(
                player != null ? player.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player != null ? player.fullName : 'Générique',
                    style: TextStyle(
                      color: isSelected ? Colors.white : SPColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (player != null)
                    Text(
                      player.position,
                      style: TextStyle(color: SPColors.textTertiary, fontSize: 9),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SPColors.borderPrimary,
          style: BorderStyle.solid, // Should be dashed but tricky in Flutter without package
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined, size: 48, color: SPColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'Prêt pour la génération...',
            style: TextStyle(color: SPColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: SPColors.primaryBlue, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: SPTypography.caption.copyWith(color: SPColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildErrorArea(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SPColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: SPColors.error, size: 32),
          const SizedBox(height: 12),
          Text(
            'ERREUR IA',
            style: SPTypography.label.copyWith(color: SPColors.error, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'La génération a échoué. Veuillez vérifier votre connexion ou réessayer.\nDétails: $error',
            textAlign: TextAlign.center,
            style: SPTypography.bodySmall.copyWith(color: SPColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Center(
      child: Column(
        children: const [
          CircularProgressIndicator(color: SPColors.badgeTechnical),
          SizedBox(height: 16),
          Text(
            'L\'IA concocte votre exercice...',
            style: TextStyle(color: SPColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    final context = {
      'targetPosition': _selectedPosition.value,
      'ageGroup': _selectedAge,
      'durationMinutes': _duration,
      'primaryObjective': _objective,
      'currentFatigueLevel': _fatigueLevel.toInt(),
      'playerId': _selectedPlayerId,
    };

    await ref.read(aiDrillGenerationProvider.notifier).generateDrill(context);
  }

  Widget _buildAiInsight() {
    if (_selectedPlayerId == null) return const SizedBox.shrink();

    final insightsAsync = ref.watch(playerInsightsProvider(_selectedPlayerId!));

    return insightsAsync.when(
      data: (insights) {
        final weaknesses = insights['weaknesses'] as String;
        final matchLoad = insights['matchLoad'] as String;

        if (weaknesses.isEmpty && matchLoad.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SPColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SPColors.borderPrimary),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: SPColors.textTertiary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Profil prêt pour génération. (Aucune lacune spécifique détectée via le scouting)',
                    style: SPTypography.bodySmall.copyWith(color: SPColors.textTertiary, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SPColors.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SPColors.primaryBlue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_outlined, color: SPColors.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'DIAGNOSTIC SCOUTING ACTIVE',
                    style: SPTypography.overline.copyWith(
                      color: SPColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (weaknesses.isNotEmpty)
                _buildInsightItem(Icons.warning_amber_rounded, 'LACUNES', weaknesses, SPColors.warning),
              if (matchLoad.isNotEmpty)
                _buildInsightItem(Icons.fitness_center, 'CHARGE PHYSIQUE', matchLoad, SPColors.info),
            ],
          ),
        );
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(8.0),
        child: LinearProgressIndicator(minHeight: 2),
      )),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInsightItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: SPTypography.bodySmall.copyWith(fontSize: 11, color: SPColors.textSecondary),
                children: [
                  TextSpan(text: '$label : ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  bool _isGif(String? url) => url != null && (url.contains('giphy.com') || url.contains('.gif'));
}
