import 'package:flutter/material.dart';
import '../models/season_plan.dart';
import '../services/season_plan_service.dart';
import '../../theme/app_theme.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';

class SeasonDashboardScreen extends StatefulWidget {
  final SeasonPlan plan;

  const SeasonDashboardScreen({super.key, required this.plan});

  @override
  State<SeasonDashboardScreen> createState() => _SeasonDashboardScreenState();
}

class _SeasonDashboardScreenState extends State<SeasonDashboardScreen> {
  late SeasonPlan _plan;
  SeasonPlanDashboard? _dashboard;
  bool _isGenerating = false;
  bool _isLoadingDashboard = false;
  bool _isSavingCheckin = false;
  bool _isSavingPreparation = false;

  Color get _surface => AppTheme.surface;
  Color get _surfaceAlt => AppTheme.surfaceAlt;
  Color get _border => AppTheme.cardBorder;
  Color get _primary => AppTheme.blueFonce;
  Color get _accent => AppTheme.blueCiel;
  Color get _textPrimary => AppTheme.textPrimary;
  Color get _textSecondary => AppTheme.textSecondary;
  Color get _success => AppTheme.success;
  Color get _warning => AppTheme.warning;
  Color get _danger => AppTheme.danger;

  void _disposeControllersSafely(List<TextEditingController> controllers) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _loadDashboard();
  }

  void _goBackToSeasons() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final shell = AppShellScope.of(context);
    if (shell != null) {
      shell.navigate(AppRoutes.seasonPlanning);
    }
  }

  Future<void> _loadDashboard() async {
    if (_plan.id == null) return;
    if (!mounted) return;

    setState(() => _isLoadingDashboard = true);
    try {
      final dashboard = await SeasonPlanService.getDashboard(_plan.id!);
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _isLoadingDashboard = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDashboard = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de charger le dashboard: $e'),
          backgroundColor: _danger,
        ),
      );
    }
  }

  Future<void> _generateForMacro(String macroId) async {
    if (_plan.id == null || macroId.isEmpty) return;
    setState(() => _isGenerating = true);
    try {
      final updated = await SeasonPlanService.generateWithAi(
        planId: _plan.id!,
        macroId: macroId,
        weeksCount: 8,
      );

      if (!mounted) return;
      setState(() {
        _plan = updated;
        _isGenerating = false;
      });

      await _loadDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bloc de saison genere avec succes.'),
          backgroundColor: _success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur generation IA: $e'), backgroundColor: _danger),
      );
    }
  }

  Future<void> _showWeeklyCheckinDialog() async {
    if (_plan.id == null || _isSavingCheckin) return;

    final latest = _dashboard?.latestCheckin;
    final weekController = TextEditingController(
      text: ((latest?.weekNumber ?? 0) + 1).toString(),
    );
    final injuriesController = TextEditingController(
      text: (latest?.injuries ?? 0).toString(),
    );
    final notesController = TextEditingController(text: latest?.coachNotes ?? '');
    final actionsController = TextEditingController(
      text: latest?.actionItems.join(', ') ?? '',
    );
    final dialogControllers = <TextEditingController>[
      weekController,
      injuriesController,
      notesController,
      actionsController,
    ];

    double physicalLoad = latest?.physicalLoad ?? 6;
    double tacticalAssimilation = latest?.tacticalAssimilation ?? 6;
    double teamCohesion = latest?.teamCohesion ?? 6;
    double morale = latest?.morale ?? 6;
    double fatigue = latest?.fatigue ?? 4;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Bilan rapide de la semaine', style: TextStyle(color: _primary)),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: weekController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Semaine',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SliderField(
                        label: 'Charge physique',
                        value: physicalLoad,
                        onChanged: (value) => setDialogState(() => physicalLoad = value),
                      ),
                      _SliderField(
                        label: 'Comprehension du plan',
                        value: tacticalAssimilation,
                        onChanged: (value) => setDialogState(() => tacticalAssimilation = value),
                      ),
                      _SliderField(
                        label: 'Cohesion equipe',
                        value: teamCohesion,
                        onChanged: (value) => setDialogState(() => teamCohesion = value),
                      ),
                      _SliderField(
                        label: 'Moral collectif',
                        value: morale,
                        onChanged: (value) => setDialogState(() => morale = value),
                      ),
                      _SliderField(
                        label: 'Fatigue globale',
                        value: fatigue,
                        onChanged: (value) => setDialogState(() => fatigue = value),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: injuriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de blessures',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Notes coach',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: actionsController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Actions prioritaires (separees par virgule)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) {
      _disposeControllersSafely(dialogControllers);
      return;
    }

    if (shouldSubmit != true) {
      _disposeControllersSafely(dialogControllers);
      return;
    }

    setState(() => _isSavingCheckin = true);
    try {
      final weekNumber = int.tryParse(weekController.text.trim()) ?? 1;
      final injuries = int.tryParse(injuriesController.text.trim()) ?? 0;
      final actionItems = actionsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      final updated = await SeasonPlanService.addWeeklyCheckin(
        planId: _plan.id!,
        checkin: WeeklyCollectiveCheckin(
          weekNumber: weekNumber,
          date: DateTime.now(),
          physicalLoad: physicalLoad,
          tacticalAssimilation: tacticalAssimilation,
          teamCohesion: teamCohesion,
          morale: morale,
          injuries: injuries,
          fatigue: fatigue,
          coachNotes: notesController.text.trim(),
          actionItems: actionItems,
        ),
      );

      if (!mounted) return;
      setState(() {
        _plan = updated;
        _isSavingCheckin = false;
      });
      await _loadDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bilan hebdomadaire enregistre.'),
          backgroundColor: _success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingCheckin = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur bilan hebdo: $e'), backgroundColor: _danger),
      );
    } finally {
      _disposeControllersSafely(dialogControllers);
    }
  }

  Future<void> _showPreparationDialog() async {
    if (_plan.id == null || _isSavingPreparation) return;

    final prep = _dashboard?.collectivePreparation ?? _plan.collectivePreparation;

    final competitionController = TextEditingController(text: prep.competitionName);
    final gameModelController = TextEditingController(text: prep.gameModel);
    final objectiveController = TextEditingController(text: prep.primaryObjective);
    final secondaryController = TextEditingController(text: prep.secondaryObjectives.join(', '));
    final tacticalController = TextEditingController(text: prep.tacticalPrinciples.join(', '));
    final cultureController = TextEditingController(text: prep.culturalPrinciples.join(', '));
    final dialogControllers = <TextEditingController>[
      competitionController,
      gameModelController,
      objectiveController,
      secondaryController,
      tacticalController,
      cultureController,
    ];

    double availabilityTarget = prep.targetAvailabilityPct;
    double cohesionTarget = prep.targetCohesionScore;
    double assimilationTarget = prep.targetTacticalAssimilation;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Objectifs et style de jeu', style: TextStyle(color: _primary)),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: competitionController,
                        decoration: const InputDecoration(
                          labelText: 'Competition cible',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: gameModelController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Modele de jeu',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: objectiveController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Objectif principal',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: secondaryController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Objectifs secondaires (virgule)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tacticalController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Principes tactiques (virgule)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cultureController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Principes culturels (virgule)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SliderField(
                        label: 'Disponibilite cible (%)',
                        value: availabilityTarget,
                        min: 50,
                        max: 100,
                        onChanged: (value) => setDialogState(() => availabilityTarget = value),
                      ),
                      _SliderField(
                        label: 'Cohesion cible (/10)',
                        value: cohesionTarget,
                        onChanged: (value) => setDialogState(() => cohesionTarget = value),
                      ),
                      _SliderField(
                        label: 'Comprehension cible (/10)',
                        value: assimilationTarget,
                        onChanged: (value) => setDialogState(() => assimilationTarget = value),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Mettre a jour'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) {
      _disposeControllersSafely(dialogControllers);
      return;
    }

    if (shouldSubmit != true) {
      _disposeControllersSafely(dialogControllers);
      return;
    }

    setState(() => _isSavingPreparation = true);
    try {
      List<String> parseCsv(String raw) {
        return raw
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
      }

      final updated = await SeasonPlanService.updateCollectivePreparation(
        planId: _plan.id!,
        preparation: CollectivePreparation(
          competitionName: competitionController.text.trim(),
          gameModel: gameModelController.text.trim(),
          primaryObjective: objectiveController.text.trim(),
          secondaryObjectives: parseCsv(secondaryController.text),
          tacticalPrinciples: parseCsv(tacticalController.text),
          culturalPrinciples: parseCsv(cultureController.text),
          targetAvailabilityPct: availabilityTarget,
          targetCohesionScore: cohesionTarget,
          targetTacticalAssimilation: assimilationTarget,
        ),
      );

      if (!mounted) return;
      setState(() {
        _plan = updated;
        _isSavingPreparation = false;
      });
      await _loadDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Strategie collective mise a jour.'),
          backgroundColor: _success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingPreparation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur mise a jour strategie: $e'), backgroundColor: _danger),
      );
    } finally {
      _disposeControllersSafely(dialogControllers);
    }
  }

  void _generateNextMacroBlock() {
    if (_isGenerating || _plan.id == null || _plan.macroCycles.isEmpty) {
      return;
    }

    final withId = _plan.macroCycles.where((macro) => (macro.id ?? '').isNotEmpty);
    if (withId.isEmpty) {
      return;
    }

    _generateForMacro(withId.first.id!);
  }

  Widget _buildSimpleUsageCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _primary),
              const SizedBox(width: 8),
              Text(
                'Comment suivre cette saison',
                style: TextStyle(fontWeight: FontWeight.w700, color: _primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1) Definissez les objectifs et le style de jeu.\n'
            '2) Ajoutez un bilan chaque semaine.\n'
            '3) Suivez les recommandations et le planning des blocs.',
            style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: TextStyle(fontWeight: FontWeight.w700, color: _primary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _plan.id == null || _isSavingPreparation ? null : _showPreparationDialog,
              icon: const Icon(Icons.flag_circle_outlined),
              label: const Text('Configurer les objectifs de saison'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _plan.id == null || _isSavingCheckin ? null : _showWeeklyCheckinDialog,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Ajouter un bilan de la semaine'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateNextMacroBlock,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.psychology, color: Colors.white),
              label: const Text(
                'Generer automatiquement le prochain bloc',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kpis = _dashboard?.kpis;
    final prep = _dashboard?.collectivePreparation ?? _plan.collectivePreparation;
    final readiness = _dashboard?.readinessIndex ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour aux saisons',
          onPressed: _goBackToSeasons,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('${_plan.title} - ${_plan.year}'),
        centerTitle: false,
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
        actions: [
          IconButton(
            tooltip: 'Configurer les objectifs',
            onPressed: _plan.id == null || _isSavingPreparation ? null : _showPreparationDialog,
            icon: _isSavingPreparation
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                  )
                : const Icon(Icons.flag_circle_outlined),
          ),
          IconButton(
            tooltip: 'Ajouter bilan semaine',
            onPressed: _plan.id == null || _isSavingCheckin ? null : _showWeeklyCheckinDialog,
            icon: _isSavingCheckin
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                  )
                : const Icon(Icons.fact_check_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _isLoadingDashboard && _dashboard == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SeasonHeaderCard(
                    title: _plan.title,
                    year: _plan.year,
                    readinessIndex: readiness,
                    macroCount: kpis?.totalMacroCycles ?? _plan.macroCycles.length,
                    microCount: kpis?.totalMicroCycles ?? 0,
                    primaryColor: _primary,
                    accentColor: _accent,
                  ),
                  const SizedBox(height: 16),
                  _buildSimpleUsageCard(),
                  const SizedBox(height: 12),
                  _buildQuickActionsCard(),
                  const SizedBox(height: 16),
                  if (kpis != null) _buildKpiGrid(kpis),
                  const SizedBox(height: 16),
                  _buildCollectivePreparationCard(prep),
                  const SizedBox(height: 16),
                  if (_dashboard != null) _buildRecommendationsCard(_dashboard!),
                  const SizedBox(height: 16),
                  if (_dashboard != null && _dashboard!.macroTimeline.isNotEmpty)
                    _buildMacroTimelineCard(_dashboard!.macroTimeline),
                  if (_dashboard != null && _dashboard!.macroTimeline.isNotEmpty)
                    const SizedBox(height: 16),
                  if (_dashboard != null && _dashboard!.focusDistribution.isNotEmpty)
                    _buildFocusDistributionCard(_dashboard!.focusDistribution),
                  if (_dashboard != null && _dashboard!.focusDistribution.isNotEmpty)
                    const SizedBox(height: 16),
                  if (_dashboard != null) _buildWeeklyTrendCard(_dashboard!),
                  const SizedBox(height: 20),
                  Text(
                    'Planning detaille de la saison',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_plan.macroCycles.isEmpty)
                    _EmptyPanel(
                      title: 'Aucun bloc de saison',
                      message: 'Ajoutez des blocs pour construire votre saison.',
                      surface: _surface,
                      border: _border,
                      text: _textSecondary,
                    )
                  else
                    ..._plan.macroCycles.asMap().entries.map(
                          (entry) => _MacroCycleCard(
                            macro: entry.value,
                            primaryColor: _primary,
                            accentColor: _accent,
                            surface: _surface,
                            border: _border,
                            textSecondary: _textSecondary,
                            isGenerating: _isGenerating,
                            onGenerateAi: _plan.id != null
                                ? () => _generateForMacro(entry.value.id ?? '')
                                : null,
                          ),
                        ),
                  const SizedBox(height: 8),
                  if (_plan.macroCycles.isNotEmpty && _plan.id != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating
                            ? null
                            : () {
                                final first = _plan.macroCycles.first;
                                if ((first.id ?? '').isNotEmpty) {
                                  _generateForMacro(first.id!);
                                }
                              },
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.psychology, color: Colors.white),
                        label: const Text(
                          'Generer un planning automatique pour le prochain bloc',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildKpiGrid(SeasonDashboardKpis kpis) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indicateurs rapides de la saison',
            style: TextStyle(fontWeight: FontWeight.w700, color: _primary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(label: 'Blocs', value: '${kpis.totalMacroCycles}', color: _primary),
              _MetricTile(label: 'Sous-blocs', value: '${kpis.totalMesoCycles}', color: _primary),
              _MetricTile(label: 'Semaines', value: '${kpis.totalMicroCycles}', color: _primary),
              _MetricTile(label: 'Effort moyen', value: kpis.averageRpe.toStringAsFixed(1), color: _warning),
              _MetricTile(label: 'Semaines intenses', value: '${kpis.highIntensityWeeks}', color: _danger),
              _MetricTile(label: 'Semaines recup', value: '${kpis.recoveryWeeks}', color: _success),
              _MetricTile(label: 'Seances video', value: '${kpis.videoSessions}', color: _accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectivePreparationCard(CollectivePreparation prep) {
    final hasStrategy =
        prep.primaryObjective.isNotEmpty || prep.gameModel.isNotEmpty || prep.tacticalPrinciples.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: _primary),
              const SizedBox(width: 8),
              Text(
                'Objectifs et style de jeu',
                style: TextStyle(fontWeight: FontWeight.w700, color: _primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasStrategy)
            Text(
              'Aucune information pour le moment. Utilisez "Configurer les objectifs de saison" pour commencer.',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            )
          else ...[
            if (prep.competitionName.isNotEmpty)
              _InfoLine(label: 'Competition', value: prep.competitionName, muted: _textSecondary),
            if (prep.primaryObjective.isNotEmpty)
              _InfoLine(label: 'Objectif principal', value: prep.primaryObjective, muted: _textSecondary),
            if (prep.gameModel.isNotEmpty)
              _InfoLine(label: 'Modele de jeu', value: prep.gameModel, muted: _textSecondary),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TargetChip(
                  label: 'Disponibilite cible ${prep.targetAvailabilityPct.toStringAsFixed(0)}%',
                  color: _success,
                ),
                _TargetChip(
                  label: 'Cohesion cible ${prep.targetCohesionScore.toStringAsFixed(1)}/10',
                  color: _accent,
                ),
                _TargetChip(
                  label: 'Comprehension cible ${prep.targetTacticalAssimilation.toStringAsFixed(1)}/10',
                  color: _primary,
                ),
              ],
            ),
            if (prep.tacticalPrinciples.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Principes tactiques', style: TextStyle(fontWeight: FontWeight.w600, color: _primary)),
              const SizedBox(height: 4),
              ...prep.tacticalPrinciples.map((item) => Text('- $item', style: TextStyle(fontSize: 13, color: _textSecondary))),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(SeasonPlanDashboard dashboard) {
    final readiness = dashboard.readinessIndex;
    final color = readiness >= 75
        ? _success
        : readiness >= 55
            ? _warning
            : _danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: color),
              const SizedBox(width: 8),
              Text(
                'Etat global de l\'equipe',
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
              const Spacer(),
              Text(
                '${dashboard.readinessIndex}/100',
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: dashboard.readinessIndex / 100,
              minHeight: 9,
              color: color,
              backgroundColor: _surfaceAlt,
            ),
          ),
          if (dashboard.latestCheckin != null) ...[
            const SizedBox(height: 10),
            Text(
              'Dernier bilan: S${dashboard.latestCheckin!.weekNumber} - charge ${dashboard.latestCheckin!.physicalLoad.toStringAsFixed(1)} / cohesion ${dashboard.latestCheckin!.teamCohesion.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Text('Recommandations pratiques', style: TextStyle(fontWeight: FontWeight.w600, color: _primary)),
          const SizedBox(height: 6),
          ...dashboard.recommendations.take(4).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('- $item', style: TextStyle(fontSize: 13, color: _textSecondary)),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMacroTimelineCard(List<MacroTimelineItem> timeline) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calendrier des blocs de saison', style: TextStyle(fontWeight: FontWeight.w700, color: _primary)),
          const SizedBox(height: 10),
          ...timeline.map(
            (item) {
              final progress = ((item.progressPct ?? 0).clamp(0, 100)) / 100.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.name} (${item.type})',
                            style: TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
                          ),
                        ),
                        Text(
                          '${item.progressPct ?? 0}%',
                          style: TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(item.startDate)} - ${_formatDate(item.endDate)}',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        color: _accent,
                        backgroundColor: _surfaceAlt,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFocusDistributionCard(List<FocusDistributionItem> distribution) {
    Color focusColor(String focus) {
      switch (focus) {
        case 'HIGH_INTENSITY':
          return _danger;
        case 'RECOVERY':
          return _success;
        case 'MAINTENANCE':
          return _warning;
        default:
          return _textSecondary;
      }
    }

    String focusLabel(String focus) {
      switch (focus) {
        case 'HIGH_INTENSITY':
          return 'Haute intensite';
        case 'RECOVERY':
          return 'Recuperation';
        case 'MAINTENANCE':
          return 'Stabilisation';
        default:
          return focus;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Repartition simple de la charge', style: TextStyle(fontWeight: FontWeight.w700, color: _primary)),
          const SizedBox(height: 10),
          ...distribution.map(
            (item) {
              final color = focusColor(item.focus);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(focusLabel(item.focus), style: TextStyle(fontSize: 12, color: _textSecondary)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: item.ratio,
                          minHeight: 8,
                          color: color,
                          backgroundColor: _surfaceAlt,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${item.count}', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendCard(SeasonPlanDashboard dashboard) {
    final list = dashboard.weeklyCheckins.reversed.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bilans des 5 dernieres semaines', style: TextStyle(fontWeight: FontWeight.w700, color: _primary)),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Text(
              'Aucun bilan enregistre pour le moment.',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            )
          else
            ...list.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'S${item.weekNumber}',
                        style: TextStyle(fontWeight: FontWeight.w700, color: _primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Charge ${item.physicalLoad.toStringAsFixed(1)} • Cohesion ${item.teamCohesion.toStringAsFixed(1)} • Fatigue ${item.fatigue.toStringAsFixed(1)} • Blessures ${item.injuries}',
                        style: TextStyle(fontSize: 12, color: _textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value.toStringAsFixed(1), style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        Slider(
          min: min,
          max: max,
          value: value.clamp(min, max),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SeasonHeaderCard extends StatelessWidget {
  final String title;
  final String year;
  final int readinessIndex;
  final int macroCount;
  final int microCount;
  final Color primaryColor;
  final Color accentColor;

  const _SeasonHeaderCard({
    required this.title,
    required this.year,
    required this.readinessIndex,
    required this.macroCount,
    required this.microCount,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final readinessColor = readinessIndex >= 75
        ? AppTheme.success
        : readinessIndex >= 55
            ? AppTheme.warning
            : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  year,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.layers_outlined, color: Colors.white, size: 15),
              const SizedBox(width: 4),
              Text('$macroCount blocs', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 12),
              const Icon(Icons.calendar_view_week_outlined, color: Colors.white, size: 15),
              const SizedBox(width: 4),
              Text('$microCount semaines', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_outlined, color: readinessColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Etat global de l\'equipe',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                Text(
                  '$readinessIndex/100',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: readinessColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final Color muted;

  const _InfoLine({
    required this.label,
    required this.value,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: muted),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TargetChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String title;
  final String message;
  final Color surface;
  final Color border;
  final Color text;

  const _EmptyPanel({
    required this.title,
    required this.message,
    required this.surface,
    required this.border,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(color: text, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MacroCycleCard extends StatelessWidget {
  final MacroCycle macro;
  final VoidCallback? onGenerateAi;
  final bool isGenerating;
  final Color primaryColor;
  final Color accentColor;
  final Color surface;
  final Color border;
  final Color textSecondary;

  const _MacroCycleCard({
    required this.macro,
    required this.primaryColor,
    required this.accentColor,
    required this.surface,
    required this.border,
    required this.textSecondary,
    this.onGenerateAi,
    this.isGenerating = false,
  });

  Color get _typeColor {
    switch (macro.type) {
      case 'PRE_SEASON':
        return AppTheme.warning;
      case 'COMPETITION':
        return AppTheme.success;
      case 'REST':
        return AppTheme.blueCiel;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData get _typeIcon {
    switch (macro.type) {
      case 'PRE_SEASON':
        return Icons.fitness_center;
      case 'COMPETITION':
        return Icons.emoji_events;
      case 'REST':
        return Icons.self_improvement;
      default:
        return Icons.calendar_month;
    }
  }

  String get _typeLabel {
    switch (macro.type) {
      case 'PRE_SEASON':
        return 'Pre-saison';
      case 'COMPETITION':
        return 'Competition';
      case 'REST':
        return 'Recuperation';
      default:
        return macro.type;
    }
  }

  String _simplifyWords(String value) {
    var output = value;
    const accentMap = <String, String>{
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'À': 'A',
      'Â': 'A',
      'Ä': 'A',
      'Á': 'A',
      'Ã': 'A',
      'Å': 'A',
      'Ç': 'C',
      'É': 'E',
      'È': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Í': 'I',
      'Ì': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ñ': 'N',
      'Ó': 'O',
      'Ò': 'O',
      'Ô': 'O',
      'Ö': 'O',
      'Õ': 'O',
      'Ú': 'U',
      'Ù': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ý': 'Y',
    };

    accentMap.forEach((from, to) {
      output = output.replaceAll(from, to);
    });

    final replacements = <MapEntry<RegExp, String>>[
      MapEntry(RegExp(r'\bchoc physiologique\b', caseSensitive: false), 'remise en forme'),
      MapEntry(RegExp(r'\bconsolidation aerobie\b', caseSensitive: false), 'progression endurance'),
      MapEntry(RegExp(r'\bdecharge\b', caseSensitive: false), 'semaine legere'),
      MapEntry(RegExp(r'\bsuper-?compensation\b', caseSensitive: false), 'recuperation complete'),
      MapEntry(RegExp(r'\bsurcompensation\b', caseSensitive: false), 'recuperation complete'),
      MapEntry(RegExp(r'\baerobie\b', caseSensitive: false), 'endurance'),
      MapEntry(RegExp(r'\banaerobie\b', caseSensitive: false), 'effort court intense'),
      MapEntry(RegExp(r'\bVMA\b', caseSensitive: false), 'vitesse repere'),
      MapEntry(RegExp(r'\bRPE\b', caseSensitive: false), 'effort ressenti'),
      MapEntry(RegExp(r'\bfoncier\b', caseSensitive: false), 'endurance de base'),
      MapEntry(RegExp(r'\bintervalle[s]?\b', caseSensitive: false), 'alternance de rythme'),
      MapEntry(RegExp(r'\bregeneration\b', caseSensitive: false), 'recuperation'),
      MapEntry(RegExp(r'\boff-?season\b', caseSensitive: false), 'intersaison'),
      MapEntry(RegExp(r'\s+&\s+', caseSensitive: false), ' et '),
    ];

    for (final entry in replacements) {
      output = output.replaceAll(entry.key, entry.value);
    }

    return output.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  String _simpleWeekTitle(String? raw, String fallback) {
    final base = (raw != null && raw.trim().isNotEmpty) ? raw.trim() : fallback;
    return _simplifyWords(base);
  }

  String _simpleObjective(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Objectif non renseigne';
    }
    return _simplifyWords(raw);
  }

  String _simpleTag(String label, String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '$label: -';
    }
    return '$label: ${_simplifyWords(raw.trim())}';
  }

  @override
  Widget build(BuildContext context) {
    final microCycles = macro.mesoCycles.expand((meso) => meso.microCycles).toList();

    String fmtDate(DateTime? value) {
      if (value == null) return '-';
      final d = value.day.toString().padLeft(2, '0');
      final m = value.month.toString().padLeft(2, '0');
      return '$d/$m/${value.year}';
    }

    String focusLabel(String focus) {
      switch (focus) {
        case 'HIGH_INTENSITY':
          return 'Haute intensite';
        case 'RECOVERY':
          return 'Recuperation';
        case 'MAINTENANCE':
          return 'Stabilisation';
        default:
          return focus;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: _typeColor.withValues(alpha: 0.14),
          child: Icon(_typeIcon, color: _typeColor),
        ),
        title: Text(
          _simplifyWords(macro.name),
          style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _typeLabel,
                  style: TextStyle(fontSize: 10, color: _typeColor, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${fmtDate(macro.startDate)} - ${fmtDate(macro.endDate)}',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
        ),
        trailing: onGenerateAi == null
            ? null
            : IconButton(
                tooltip: 'Generer bloc IA',
                onPressed: isGenerating ? null : onGenerateAi,
                icon: isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.psychology, color: accentColor),
              ),
        children: [
          if (microCycles.isEmpty)
            Row(
              children: [
                Icon(Icons.info_outline, size: 15, color: textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aucune semaine detaillee pour ce bloc.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ),
              ],
            )
          else
            ...microCycles.map(
              (week) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${week.weekNumber}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: _typeColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _simpleWeekTitle(week.label, focusLabel(week.focus)),
                            style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _simpleObjective(week.objective),
                            style: TextStyle(fontSize: 12, color: textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _MiniTag(text: _simpleTag('Temps', week.trainingVolume), color: AppTheme.warning),
                              _MiniTag(text: _simpleTag('Rythme', week.intensityLevel), color: AppTheme.danger),
                              if (week.chargeRpe != null)
                                _MiniTag(text: 'Effort ressenti ${week.chargeRpe}/10', color: AppTheme.blueCiel),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
