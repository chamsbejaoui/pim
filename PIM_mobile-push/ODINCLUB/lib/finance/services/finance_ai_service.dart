import 'dart:math' as math;

import '../../services/api_service.dart';
import '../services/finance_store.dart';

class FinanceAiInsight {
  final String title;
  final String summary;
  final String details;
  final String source;

  const FinanceAiInsight({
    required this.title,
    required this.summary,
    required this.details,
    this.source = 'local',
  });
}

class FinanceAiBundle {
  final FinanceAiInsight forecast;
  final FinanceAiInsight cashflowRisk;
  final FinanceAiInsight sponsorTransferImpact;
  final String source;
  final int? generationTimeMs;
  final Map<String, dynamic>? forecastData;
  final Map<String, dynamic>? cashflowData;
  final Map<String, dynamic>? impactData;

  const FinanceAiBundle({
    required this.forecast,
    required this.cashflowRisk,
    required this.sponsorTransferImpact,
    this.source = 'local',
    this.generationTimeMs,
    this.forecastData,
    this.cashflowData,
    this.impactData,
  });
}

class FinanceAiService {
  FinanceAiService._();
  static final FinanceAiService instance = FinanceAiService._();
  final ApiService _apiService = ApiService();

  FinanceAiInsight buildBudgetForecast(FinanceStore store) {
    final revenueForecast = store.totalRevenueForecast;
    final revenueActual = store.totalRevenueActual;
    final expenses = store.totalExpenseAmount;
    final salaries = store.totalSalaryExpense;

    final forecastBase = revenueForecast > 0 ? revenueForecast : revenueActual;
    final safeBase = forecastBase <= 0 ? 1.0 : forecastBase;

    final actualVsForecastRatio = revenueForecast <= 0
        ? 1.0
        : (revenueActual / revenueForecast).clamp(0.0, 3.0);

    final net = revenueActual - expenses;
    final netPct = (net / safeBase) * 100.0;

    final salaryPct = (salaries / safeBase) * 100.0;
    final expensePct = (expenses / safeBase) * 100.0;

    final riskScore = _riskScore(
      netPct: netPct,
      actualVsForecastRatio: actualVsForecastRatio,
      salaryPct: salaryPct,
    );

    final riskLabel = switch (riskScore) {
      <= 34 => 'Faible',
      <= 67 => 'Moyen',
      _ => 'Élevé',
    };

    final summary = net < 0
        ? 'Risque de déficit détecté (risque $riskLabel).'
        : 'Trajectoire budgétaire correcte (risque $riskLabel).';

    final details = [
      'Prévision basée sur les données actuelles (revenus & dépenses).',
      '',
      'Indicateurs:',
      '- Revenus (réel): ${_fmtMoney(revenueActual)} DT',
      '- Revenus (prévu): ${_fmtMoney(revenueForecast)} DT',
      '- Dépenses (hors salaires): ${_fmtMoney(expenses - salaries)} DT',
      '- Salaires (net à payer): ${_fmtMoney(salaries)} DT',
      '',
      'Ratios:',
      '- Réel/Prévu revenus: ${(actualVsForecastRatio * 100).toStringAsFixed(0)}%',
      '- Dépenses / base: ${expensePct.toStringAsFixed(1)}%',
      '- Salaires / base: ${salaryPct.toStringAsFixed(1)}%',
      '- Résultat net: ${_fmtMoney(net)} DT (${netPct.toStringAsFixed(1)}%)',
      '',
      'Recommandation:',
      _forecastRecommendation(
        netPct: netPct,
        salaryPct: salaryPct,
        actualVsForecastRatio: actualVsForecastRatio,
      ),
    ].join('\n');

    return FinanceAiInsight(
      title: 'Prévision budget',
      summary: summary,
      details: details,
      source: 'local',
    );
  }

  FinanceAiInsight buildExpenseOptimization(FinanceStore store) {
    final byCategory = <String, double>{};
    for (final e in store.expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    if (byCategory.isEmpty) {
      return const FinanceAiInsight(
        title: 'Optimisation dépenses',
        summary: 'Pas assez de données pour optimiser.',
        details:
            'Ajoutez des dépenses catégorisées (avec montants) pour générer des recommandations.',
      );
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sorted.fold<double>(0.0, (s, e) => s + e.value);
    final top = sorted.take(math.min(5, sorted.length)).toList();

    final topShare = total <= 0 ? 0.0 : (top.first.value / total);
    final hasHeavyConcentration = topShare >= 0.45;

    final salaryLike = sorted.where((e) => e.key.contains('SALAIRES')).toList();
    final travelLike = sorted.where((e) => e.key.contains('TRANSPORT')).toList();
    final marketingLike =
        sorted.where((e) => e.key.contains('MARKETING')).toList();

    final summary = hasHeavyConcentration
        ? 'Dépenses très concentrées sur ${top.first.key}.'
        : 'Répartition des dépenses relativement équilibrée.';

    final details = [
      'Top catégories (montants):',
      for (final e in top)
        '- ${e.key}: ${_fmtMoney(e.value)} DT (${total <= 0 ? '—' : '${(e.value / total * 100).toStringAsFixed(0)}%'})',
      '',
      'Actions proposées (priorisées):',
      ..._optimizationActions(
        total: total,
        salaryLike: salaryLike,
        travelLike: travelLike,
        marketingLike: marketingLike,
        hasHeavyConcentration: hasHeavyConcentration,
        topCategory: top.first.key,
      ),
    ].join('\n');

    return FinanceAiInsight(
      title: 'Optimisation dépenses',
      summary: summary,
      details: details,
      source: 'local',
    );
  }

  Future<FinanceAiBundle> loadRemoteInsights(FinanceStore store) async {
    final response = await _apiService.getFinanceAiInsights(
      focusCategories: store.expenses.map((e) => e.category).toSet().toList(),
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Finance AI endpoint error');
    }

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final forecastData = data['forecast'] as Map<String, dynamic>? ?? {};
    final cashflowData = data['cashflowRisk'] as Map<String, dynamic>? ?? {};
    final impactData = data['sponsorTransferImpact'] as Map<String, dynamic>? ?? {};
    final source = (data['source']?.toString() ?? 'remote').toLowerCase();
    final generationTimeMs = data['generationTimeMs'] is int
        ? data['generationTimeMs'] as int
        : int.tryParse(data['generationTimeMs']?.toString() ?? '');

    final forecastInsight = _buildForecastInsight(forecastData, source);
    final cashflowInsight = _buildCashflowInsight(cashflowData, source);
    final impactInsight = _buildImpactInsight(impactData, source);

    return FinanceAiBundle(
      source: source,
      generationTimeMs: generationTimeMs,
      forecast: forecastInsight,
      cashflowRisk: cashflowInsight,
      sponsorTransferImpact: impactInsight,
      forecastData: forecastData,
      cashflowData: cashflowData,
      impactData: impactData,
    );
  }

  FinanceAiInsight _buildForecastInsight(
    Map<String, dynamic> data,
    String source,
  ) {
    final nextSeason = data['nextSeason'] as Map<String, dynamic>? ?? {};
    final confidence = data['confidence'];
    final season = nextSeason['season']?.toString() ?? 'N/A';
    final revenue = _fmtMoney((nextSeason['revenue'] ?? 0).toDouble());
    final expense = _fmtMoney((nextSeason['expense'] ?? 0).toDouble());
    final net = _fmtMoney((nextSeason['net'] ?? 0).toDouble());
    final confidenceLabel = confidence != null ? ' • Confiance ${confidence}%' : '';

    final bySeason = (data['bySeason'] as List? ?? [])
        .map((s) => s as Map<String, dynamic>)
        .map((seasonData) {
      final label = seasonData['season']?.toString() ?? '—';
      final rev = _fmtMoney((seasonData['revenue'] ?? 0).toDouble());
      final exp = _fmtMoney((seasonData['expense'] ?? 0).toDouble());
      final netVal = _fmtMoney((seasonData['net'] ?? 0).toDouble());
      return '- $label: +$rev / -$exp / net $netVal';
    }).toList();

    return FinanceAiInsight(
      title: 'Prévision saisonnière',
      summary: 'Prochaine saison $season: net $net$confidenceLabel',
      details: [
        'Prévision revenus/dépenses basée sur historique comptable.',
        'Prochaine saison: Revenus $revenue • Dépenses $expense • Net $net',
        if (bySeason.isNotEmpty) ...['', 'Historique:', ...bySeason]
      ].join('\n'),
      source: source,
    );
  }

  FinanceAiInsight _buildCashflowInsight(
    Map<String, dynamic> data,
    String source,
  ) {
    final level = data['level']?.toString() ?? 'N/A';
    final score = data['score']?.toString() ?? '—';
    final projected = _fmtMoney((data['projectedCash'] ?? 0).toDouble());
    final treasury = _fmtMoney((data['treasuryBalance'] ?? 0).toDouble());
    final outflows = _fmtMoney((data['upcomingOutflows'] ?? 0).toDouble());
    final inflows = _fmtMoney((data['upcomingInflows'] ?? 0).toDouble());
    final notes = (data['notes'] as List? ?? [])
        .map((n) => '- ${n.toString()}')
        .toList();

    return FinanceAiInsight(
      title: 'Risque de trésorerie',
      summary: 'Niveau $level (score $score) • Solde projeté $projected',
      details: [
        'Analyse cash-flow sur 90 jours.',
        'Trésorerie actuelle: $treasury',
        'Flux entrants à venir: $inflows',
        'Flux sortants à venir: $outflows',
        'Solde projeté: $projected',
        if (notes.isNotEmpty) ...['', 'Notes:', ...notes],
      ].join('\n'),
      source: source,
    );
  }

  FinanceAiInsight _buildImpactInsight(
    Map<String, dynamic> data,
    String source,
  ) {
    final sponsorBase = _fmtMoney((data['sponsorBase'] ?? 0).toDouble());
    final sponsorPlus = _fmtMoney((data['sponsorPlus10'] ?? 0).toDouble());
    final sponsorMinus = _fmtMoney((data['sponsorMinus10'] ?? 0).toDouble());
    final transferNet = _fmtMoney((data['transferNet'] ?? 0).toDouble());
    final scenario = data['scenario'] as Map<String, dynamic>? ?? {};
    final plusDelta =
        _fmtMoney((scenario['sponsorImpactPlus10'] ?? 0).toDouble());
    final minusDelta =
        _fmtMoney((scenario['sponsorImpactMinus10'] ?? 0).toDouble());

    return FinanceAiInsight(
      title: 'Impact sponsors & transferts',
      summary: 'Sponsors +10%: +$plusDelta • Net transferts: $transferNet',
      details: [
        'Base sponsors: $sponsorBase',
        'Scenario +10% sponsors: $sponsorPlus (impact +$plusDelta)',
        'Scenario -10% sponsors: $sponsorMinus (impact $minusDelta)',
        'Net transferts: $transferNet',
      ].join('\n'),
      source: source,
    );
  }

  int _riskScore({
    required double netPct,
    required double actualVsForecastRatio,
    required double salaryPct,
  }) {
    var score = 0.0;

    // Negative margin is a strong signal.
    if (netPct < 0) score += math.min(40, (-netPct) * 2.0);

    // Revenue underperforming forecast.
    if (actualVsForecastRatio < 0.9) {
      score += ((0.9 - actualVsForecastRatio) * 200).clamp(0, 30);
    }

    // Salary pressure.
    if (salaryPct > 55) score += ((salaryPct - 55) * 1.2).clamp(0, 30);

    return score.clamp(0, 100).round();
  }

  String _forecastRecommendation({
    required double netPct,
    required double salaryPct,
    required double actualVsForecastRatio,
  }) {
    if (netPct < -5) {
      return 'Déficit probable: geler les dépenses non essentielles, renforcer les validations, et viser une réduction 5–10% sur les postes variables (transport, équipement, marketing).';
    }
    if (actualVsForecastRatio < 0.9) {
      return 'Revenus en dessous du prévu: ajuster les plafonds par catégorie et déclencher un plan d’économies progressif tant que les encaissements ne rattrapent pas la prévision.';
    }
    if (salaryPct > 60) {
      return 'Pression salariale élevée: analyser la masse salariale (bonus/avantages), étaler certaines primes, et limiter les nouvelles charges fixes.';
    }
    if (netPct < 3) {
      return 'Marge faible: surveiller les achats récurrents, optimiser les contrats fournisseurs, et imposer un contrôle renforcé sur les dépenses > seuil.';
    }
    return 'Marge confortable: maintenir la discipline budgétaire, et réallouer une partie vers des postes à ROI (formation jeunes, médical préventif) si nécessaire.';
  }

  List<String> _optimizationActions({
    required double total,
    required List<MapEntry<String, double>> salaryLike,
    required List<MapEntry<String, double>> travelLike,
    required List<MapEntry<String, double>> marketingLike,
    required bool hasHeavyConcentration,
    required String topCategory,
  }) {
    final actions = <String>[];

    if (hasHeavyConcentration) {
      actions.add(
        '- Définir un plafond et un workflow de validation renforcé pour $topCategory (objectif: -5% sur 30 jours).',
      );
    } else {
      actions.add(
        '- Appliquer une politique “3 devis” sur les achats non récurrents et centraliser les fournisseurs pour réduire les coûts.',
      );
    }

    if (salaryLike.isNotEmpty) {
      actions.add(
        '- Masse salariale: auditer primes/avantages, limiter les bonus non liés à la performance, et renégocier certains contrats.',
      );
    }
    if (travelLike.isNotEmpty) {
      actions.add(
        '- Transport: regrouper les déplacements, négocier tarifs saisonniers, et standardiser les prestataires.',
      );
    }
    if (marketingLike.isNotEmpty) {
      actions.add(
        '- Marketing: basculer vers des campagnes mesurables (CPA/ROI), couper les canaux à faible conversion.',
      );
    }

    if (total > 0) {
      actions.add(
        '- Mettre des alertes automatiques à 80% et 95% d’utilisation des budgets par catégorie.',
      );
    }

    return actions;
  }

  String _fmtMoney(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (abs >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
