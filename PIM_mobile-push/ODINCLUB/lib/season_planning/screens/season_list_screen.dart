import 'package:flutter/material.dart';
import '../models/season_plan.dart';
import '../services/season_plan_service.dart';
import '../../theme/app_theme.dart';
import '../../ui/navigation/menu_config.dart';
import '../../ui/shell/app_shell.dart';
import 'season_dashboard_screen.dart';

class SeasonListScreen extends StatefulWidget {
  const SeasonListScreen({super.key});

  @override
  State<SeasonListScreen> createState() => _SeasonListScreenState();
}

class _SeasonListScreenState extends State<SeasonListScreen> {
  List<SeasonPlan> _plans = [];
  bool _isLoading = true;

  Color get _surface => AppTheme.surface;
  Color get _border => AppTheme.cardBorder;
  Color get _primary => AppTheme.blueFonce;
  Color get _accent => AppTheme.blueCiel;
  Color get _textPrimary => AppTheme.textPrimary;
  Color get _textSecondary => AppTheme.textSecondary;
  Color get _success => AppTheme.success;
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
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final plans = await SeasonPlanService.getPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement: $e'), backgroundColor: _danger),
      );
    }
  }

  DateTime _safeSeasonStart(String year) {
    final parts = year.split('-');
    final firstYear = int.tryParse(parts.first.trim());
    if (firstYear != null) {
      return DateTime(firstYear, 7, 1);
    }
    final now = DateTime.now();
    return DateTime(now.year, 7, 1);
  }

  DateTime _safeSeasonEnd(String year) {
    final parts = year.split('-');
    final secondYear = parts.length > 1 ? int.tryParse(parts[1].trim()) : null;
    if (secondYear != null) {
      return DateTime(secondYear, 6, 30);
    }
    final start = _safeSeasonStart(year);
    return DateTime(start.year + 1, 6, 30);
  }

  DateTime _addWeeks(DateTime base, int weeks) {
    return base.add(Duration(days: weeks * 7));
  }

  List<MacroCycle> _defaultMacroCycles(DateTime start, DateTime end) {
    final preSeasonEnd = _addWeeks(start, 6);
    final compPhase1End = _addWeeks(preSeasonEnd, 16);
    final compPhase2End = _addWeeks(compPhase1End, 16);
    final runInEnd = _addWeeks(compPhase2End, 8);

    return [
      MacroCycle(
        name: 'Pre-saison collective',
        type: 'PRE_SEASON',
        startDate: start,
        endDate: preSeasonEnd,
      ),
      MacroCycle(
        name: 'Competition - Bloc 1',
        type: 'COMPETITION',
        startDate: preSeasonEnd,
        endDate: compPhase1End,
      ),
      MacroCycle(
        name: 'Competition - Bloc 2',
        type: 'COMPETITION',
        startDate: compPhase1End,
        endDate: compPhase2End,
      ),
      MacroCycle(
        name: 'Run-in et playoffs',
        type: 'COMPETITION',
        startDate: compPhase2End,
        endDate: runInEnd.isAfter(end) ? end : runInEnd,
      ),
      MacroCycle(
        name: 'Transition et regeneration',
        type: 'REST',
        startDate: runInEnd.isAfter(end) ? end : runInEnd,
        endDate: end,
      ),
    ];
  }

  Future<void> _showCreateDialog() async {
    final now = DateTime.now();
    final titleController = TextEditingController();
    final yearController = TextEditingController(text: '${now.year}-${now.year + 1}');
    final competitionController = TextEditingController();
    final objectiveController = TextEditingController();
    final gameModelController = TextEditingController();
    final dialogControllers = <TextEditingController>[
      titleController,
      yearController,
      competitionController,
      objectiveController,
      gameModelController,
    ];

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nouvelle planification saison', style: TextStyle(color: _primary)),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Equipe / groupe',
                      hintText: 'Ex: Equipe A Senior',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: yearController,
                    decoration: const InputDecoration(
                      labelText: 'Saison',
                      hintText: 'Ex: 2026-2027',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: competitionController,
                    decoration: const InputDecoration(
                      labelText: 'Competition cible',
                      hintText: 'Ex: Botola Pro',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: objectiveController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Objectif principal collectif',
                      hintText: 'Ex: Top 3 + identite de jeu haute intensite',
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
                      hintText: 'Ex: pressing coordonne + transitions rapides',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Creer la saison'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      _disposeControllersSafely(dialogControllers);
      return;
    }

    if (shouldCreate != true) {
      _disposeControllersSafely(dialogControllers);
      return;
    }

    if (titleController.text.trim().isEmpty || yearController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Le titre et la saison sont obligatoires.'),
            backgroundColor: _danger,
          ),
        );
      }
      _disposeControllersSafely(dialogControllers);
      return;
    }

    final year = yearController.text.trim();
    final startDate = _safeSeasonStart(year);
    final endDate = _safeSeasonEnd(year);

    final newPlan = SeasonPlan(
      title: titleController.text.trim(),
      year: year,
      startDate: startDate,
      endDate: endDate,
      collectivePreparation: CollectivePreparation(
        competitionName: competitionController.text.trim(),
        primaryObjective: objectiveController.text.trim(),
        gameModel: gameModelController.text.trim(),
        targetAvailabilityPct: 85,
        targetCohesionScore: 7,
        targetTacticalAssimilation: 7,
      ),
      macroCycles: _defaultMacroCycles(startDate, endDate),
    );

    _disposeControllersSafely(dialogControllers);

    try {
      await SeasonPlanService.createPlan(newPlan);
      await _loadPlans();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saison creee avec succes.'),
          backgroundColor: _success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur creation saison: $e'),
          backgroundColor: _danger,
        ),
      );
    }
  }

  Future<void> _openSeason(SeasonPlan plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeasonDashboardScreen(plan: plan)),
    );
    if (mounted) {
      _loadPlans();
    }
  }

  void _goBackToDashboard() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.maybePop();
      return;
    }

    final shell = AppShellScope.of(context);
    if (shell != null) {
      final homeRoute = MenuConfig.defaultRouteForRole(shell.session.role);
      shell.navigate(homeRoute);
    }
  }

  Widget _buildSimpleGuideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.lightbulb_outline, color: _primary),
              const SizedBox(width: 8),
              Text(
                'Comment utiliser ce module',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '1) Creez une saison.\n'
            '2) Definissez vos objectifs et votre style de jeu.\n'
            '3) Faites un bilan chaque semaine pour garder la saison sur les rails.',
            style: TextStyle(color: _textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour au dashboard',
          onPressed: _goBackToDashboard,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Planification de saison'),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle saison', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPlans,
              child: _plans.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildSimpleGuideCard(),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_month, color: _primary, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Aucune saison planifiee',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Commencez simplement: creez votre premiere saison, ajoutez vos objectifs, puis faites un petit suivi chaque semaine.',
                                style: TextStyle(color: _textSecondary, height: 1.4),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _showCreateDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Creer ma premiere saison'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      children: [
                        _buildSimpleGuideCard(),
                        const SizedBox(height: 12),
                        ..._plans.map((plan) {
                          final objective = plan.collectivePreparation.primaryObjective;
                          final readinessHint = plan.weeklyCheckins.isNotEmpty
                              ? 'Bilans semaine: ${plan.weeklyCheckins.length}'
                              : 'Bilans semaine: 0';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openSeason(plan),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _accent.withValues(alpha: 0.14),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.track_changes, color: _primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: _primary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            plan.year,
                                            style: TextStyle(fontSize: 12, color: _textSecondary),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _Tag(
                                                text: '${plan.macroCycles.length} blocs',
                                                color: _accent,
                                              ),
                                              _Tag(
                                                text: readinessHint,
                                                color: _success,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Etapes de cette saison: 1) Objectifs  2) Bilan semaine  3) Planning des blocs',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            objective.isNotEmpty
                                                ? 'Objectif: $objective'
                                                : 'Objectif: a definir',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _textSecondary,
                                              height: 1.35,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 10),
                                          OutlinedButton.icon(
                                            onPressed: () => _openSeason(plan),
                                            icon: const Icon(Icons.open_in_new, size: 16),
                                            label: const Text('Ouvrir cette saison'),
                                          ),
                                        ],
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
            ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
