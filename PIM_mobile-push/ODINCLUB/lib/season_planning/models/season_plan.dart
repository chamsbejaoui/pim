// ─── EXERCISE MODEL ──────────────────────────────────────────────────────────
class Exercise {
  final int ordre;
  final String nom;
  final String objectif;
  final String repetitions;
  final String intensite;
  final String materiel;

  Exercise({
    required this.ordre,
    required this.nom,
    required this.objectif,
    required this.repetitions,
    required this.intensite,
    required this.materiel,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      ordre: json['ordre'] ?? 0,
      nom: json['nom'] ?? '',
      objectif: json['objectif'] ?? '',
      repetitions: json['repetitions'] ?? '',
      intensite: json['intensite'] ?? '',
      materiel: json['materiel'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'ordre': ordre,
    'nom': nom,
    'objectif': objectif,
    'repetitions': repetitions,
    'intensite': intensite,
    'materiel': materiel,
  };
}

// ─── MICROCYCLE MODEL ─────────────────────────────────────────────────────────
class MicroCycle {
  final int weekNumber;
  final String focus;
  final String? label;
  final String? objective;
  final String? trainingVolume;
  final String? intensityLevel;
  final int? chargeRpe;
  final String? ratioTravailRepos;
  final List<Exercise> keyExercises;
  final String? medicalAdvice;
  final List<String> indicateursProgression;
  final String? nutritionRecommandee;
  final bool sessionVideoTactique;
  final DateTime? startDate;
  final DateTime? endDate;

  MicroCycle({
    required this.weekNumber,
    required this.focus,
    this.label,
    this.objective,
    this.trainingVolume,
    this.intensityLevel,
    this.chargeRpe,
    this.ratioTravailRepos,
    this.keyExercises = const [],
    this.medicalAdvice,
    this.indicateursProgression = const [],
    this.nutritionRecommandee,
    this.sessionVideoTactique = false,
    this.startDate,
    this.endDate,
  });

  factory MicroCycle.fromJson(Map<String, dynamic> json) {
    return MicroCycle(
      weekNumber: json['weekNumber'] ?? 0,
      focus: json['focus'] ?? 'MAINTENANCE',
      label: json['label'],
      objective: json['objective'],
      trainingVolume: json['trainingVolume'],
      intensityLevel: json['intensityLevel'],
      chargeRpe: json['chargeRpe'],
      ratioTravailRepos: json['ratioTravailRepos'],
      keyExercises: (json['keyExercises'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) return Exercise.fromJson(e);
                return Exercise(ordre: 0, nom: e.toString(), objectif: '', repetitions: '', intensite: '', materiel: '');
              })
              .toList() ??
          [],
      medicalAdvice: json['medicalAdvice'],
      indicateursProgression: (json['indicateursProgression'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      nutritionRecommandee: json['nutritionRecommandee'],
      sessionVideoTactique: json['sessionVideoTactique'] ?? false,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'weekNumber': weekNumber,
    'focus': focus,
    if (label != null) 'label': label,
    if (objective != null) 'objective': objective,
    if (trainingVolume != null) 'trainingVolume': trainingVolume,
    if (intensityLevel != null) 'intensityLevel': intensityLevel,
    if (chargeRpe != null) 'chargeRpe': chargeRpe,
    if (ratioTravailRepos != null) 'ratioTravailRepos': ratioTravailRepos,
    'keyExercises': keyExercises.map((e) => e.toJson()).toList(),
    if (medicalAdvice != null) 'medicalAdvice': medicalAdvice,
    'indicateursProgression': indicateursProgression,
    if (nutritionRecommandee != null) 'nutritionRecommandee': nutritionRecommandee,
    'sessionVideoTactique': sessionVideoTactique,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
  };
}

// ─── MESOCYCLE MODEL ──────────────────────────────────────────────────────────
class MesoCycle {
  final String name;
  final String? objective;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<MicroCycle> microCycles;

  MesoCycle({
    required this.name,
    this.objective,
    this.startDate,
    this.endDate,
    this.microCycles = const [],
  });

  factory MesoCycle.fromJson(Map<String, dynamic> json) {
    return MesoCycle(
      name: json['name'] ?? '',
      objective: json['objective'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      microCycles: (json['microCycles'] as List<dynamic>?)
              ?.map((e) => MicroCycle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (objective != null) 'objective': objective,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        'microCycles': microCycles.map((e) => e.toJson()).toList(),
      };
}

// ─── MACROCYCLE MODEL ─────────────────────────────────────────────────────────
class MacroCycle {
  final String? id;
  final String name;
  final String type;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<MesoCycle> mesoCycles;

  MacroCycle({
    this.id,
    required this.name,
    required this.type,
    this.startDate,
    this.endDate,
    this.mesoCycles = const [],
  });

  factory MacroCycle.fromJson(Map<String, dynamic> json) {
    return MacroCycle(
      id: json['_id'],
      name: json['name'] ?? '',
      type: json['type'] ?? 'REST',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      mesoCycles: (json['mesoCycles'] as List<dynamic>?)
              ?.map((e) => MesoCycle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        'mesoCycles': mesoCycles.map((e) => e.toJson()).toList(),
      };
}

class CollectivePreparation {
  final String competitionName;
  final String gameModel;
  final String primaryObjective;
  final List<String> secondaryObjectives;
  final List<String> tacticalPrinciples;
  final List<String> culturalPrinciples;
  final double targetAvailabilityPct;
  final double targetCohesionScore;
  final double targetTacticalAssimilation;

  const CollectivePreparation({
    this.competitionName = '',
    this.gameModel = '',
    this.primaryObjective = '',
    this.secondaryObjectives = const [],
    this.tacticalPrinciples = const [],
    this.culturalPrinciples = const [],
    this.targetAvailabilityPct = 85,
    this.targetCohesionScore = 7,
    this.targetTacticalAssimilation = 7,
  });

  factory CollectivePreparation.fromJson(Map<String, dynamic> json) {
    return CollectivePreparation(
      competitionName: (json['competitionName'] ?? '').toString(),
      gameModel: (json['gameModel'] ?? '').toString(),
      primaryObjective: (json['primaryObjective'] ?? '').toString(),
      secondaryObjectives: (json['secondaryObjectives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tacticalPrinciples: (json['tacticalPrinciples'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      culturalPrinciples: (json['culturalPrinciples'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      targetAvailabilityPct: _readDouble(
        json['targetAvailabilityPct'],
        fallback: 85,
      ),
      targetCohesionScore: _readDouble(
        json['targetCohesionScore'],
        fallback: 7,
      ),
      targetTacticalAssimilation: _readDouble(
        json['targetTacticalAssimilation'],
        fallback: 7,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        if (competitionName.trim().isNotEmpty) 'competitionName': competitionName.trim(),
        if (gameModel.trim().isNotEmpty) 'gameModel': gameModel.trim(),
        if (primaryObjective.trim().isNotEmpty) 'primaryObjective': primaryObjective.trim(),
        'secondaryObjectives': secondaryObjectives,
        'tacticalPrinciples': tacticalPrinciples,
        'culturalPrinciples': culturalPrinciples,
        'targetAvailabilityPct': targetAvailabilityPct,
        'targetCohesionScore': targetCohesionScore,
        'targetTacticalAssimilation': targetTacticalAssimilation,
      };
}

class WeeklyCollectiveCheckin {
  final int weekNumber;
  final DateTime? date;
  final double physicalLoad;
  final double tacticalAssimilation;
  final double teamCohesion;
  final double morale;
  final int injuries;
  final double fatigue;
  final String coachNotes;
  final List<String> actionItems;

  const WeeklyCollectiveCheckin({
    required this.weekNumber,
    this.date,
    this.physicalLoad = 0,
    this.tacticalAssimilation = 0,
    this.teamCohesion = 0,
    this.morale = 0,
    this.injuries = 0,
    this.fatigue = 0,
    this.coachNotes = '',
    this.actionItems = const [],
  });

  factory WeeklyCollectiveCheckin.fromJson(Map<String, dynamic> json) {
    return WeeklyCollectiveCheckin(
      weekNumber: _readInt(json['weekNumber'], fallback: 1),
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      physicalLoad: _readDouble(json['physicalLoad']),
      tacticalAssimilation: _readDouble(json['tacticalAssimilation']),
      teamCohesion: _readDouble(json['teamCohesion']),
      morale: _readDouble(json['morale']),
      injuries: _readInt(json['injuries']),
      fatigue: _readDouble(json['fatigue']),
      coachNotes: (json['coachNotes'] ?? '').toString(),
      actionItems: (json['actionItems'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'weekNumber': weekNumber,
        if (date != null) 'date': date!.toIso8601String(),
        'physicalLoad': physicalLoad,
        'tacticalAssimilation': tacticalAssimilation,
        'teamCohesion': teamCohesion,
        'morale': morale,
        'injuries': injuries,
        'fatigue': fatigue,
        if (coachNotes.trim().isNotEmpty) 'coachNotes': coachNotes.trim(),
        'actionItems': actionItems,
      };
}

class SeasonDashboardKpis {
  final int totalMacroCycles;
  final int totalMesoCycles;
  final int totalMicroCycles;
  final double averageRpe;
  final int highIntensityWeeks;
  final int recoveryWeeks;
  final int videoSessions;

  const SeasonDashboardKpis({
    this.totalMacroCycles = 0,
    this.totalMesoCycles = 0,
    this.totalMicroCycles = 0,
    this.averageRpe = 0,
    this.highIntensityWeeks = 0,
    this.recoveryWeeks = 0,
    this.videoSessions = 0,
  });

  factory SeasonDashboardKpis.fromJson(Map<String, dynamic> json) {
    return SeasonDashboardKpis(
      totalMacroCycles: _readInt(json['totalMacroCycles']),
      totalMesoCycles: _readInt(json['totalMesoCycles']),
      totalMicroCycles: _readInt(json['totalMicroCycles']),
      averageRpe: _readDouble(json['averageRpe']),
      highIntensityWeeks: _readInt(json['highIntensityWeeks']),
      recoveryWeeks: _readInt(json['recoveryWeeks']),
      videoSessions: _readInt(json['videoSessions']),
    );
  }
}

class FocusDistributionItem {
  final String focus;
  final int count;
  final double ratio;

  const FocusDistributionItem({
    required this.focus,
    this.count = 0,
    this.ratio = 0,
  });

  factory FocusDistributionItem.fromJson(Map<String, dynamic> json) {
    return FocusDistributionItem(
      focus: (json['focus'] ?? '').toString(),
      count: _readInt(json['count']),
      ratio: _readDouble(json['ratio']),
    );
  }
}

class MacroTimelineItem {
  final String id;
  final String name;
  final String type;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? progressPct;

  const MacroTimelineItem({
    this.id = '',
    this.name = '',
    this.type = 'REST',
    this.startDate,
    this.endDate,
    this.progressPct,
  });

  factory MacroTimelineItem.fromJson(Map<String, dynamic> json) {
    return MacroTimelineItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'REST').toString(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      progressPct: json['progressPct'] == null
          ? null
          : _readInt(json['progressPct']),
    );
  }
}

class SeasonPlanDashboard {
  final String planId;
  final String title;
  final String year;
  final CollectivePreparation collectivePreparation;
  final WeeklyCollectiveCheckin? latestCheckin;
  final List<WeeklyCollectiveCheckin> weeklyCheckins;
  final int readinessIndex;
  final SeasonDashboardKpis kpis;
  final List<FocusDistributionItem> focusDistribution;
  final List<MacroTimelineItem> macroTimeline;
  final List<String> recommendations;

  const SeasonPlanDashboard({
    this.planId = '',
    this.title = '',
    this.year = '',
    this.collectivePreparation = const CollectivePreparation(),
    this.latestCheckin,
    this.weeklyCheckins = const [],
    this.readinessIndex = 0,
    this.kpis = const SeasonDashboardKpis(),
    this.focusDistribution = const [],
    this.macroTimeline = const [],
    this.recommendations = const [],
  });

  factory SeasonPlanDashboard.fromJson(Map<String, dynamic> json) {
    return SeasonPlanDashboard(
      planId: (json['planId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      year: (json['year'] ?? '').toString(),
      collectivePreparation: json['collectivePreparation'] is Map<String, dynamic>
          ? CollectivePreparation.fromJson(
              json['collectivePreparation'] as Map<String, dynamic>,
            )
          : const CollectivePreparation(),
      latestCheckin: json['latestCheckin'] is Map<String, dynamic>
          ? WeeklyCollectiveCheckin.fromJson(
              json['latestCheckin'] as Map<String, dynamic>,
            )
          : null,
      weeklyCheckins: (json['weeklyCheckins'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(WeeklyCollectiveCheckin.fromJson)
              .toList() ??
          const [],
      readinessIndex: _readInt(json['readinessIndex']),
      kpis: json['kpis'] is Map<String, dynamic>
          ? SeasonDashboardKpis.fromJson(json['kpis'] as Map<String, dynamic>)
          : const SeasonDashboardKpis(),
      focusDistribution: (json['focusDistribution'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(FocusDistributionItem.fromJson)
              .toList() ??
          const [],
      macroTimeline: (json['macroTimeline'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(MacroTimelineItem.fromJson)
              .toList() ??
          const [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

// ─── SEASON PLAN MODEL ────────────────────────────────────────────────────────
class SeasonPlan {
  final String? id;
  final String title;
  final String year;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? teamId;
  final CollectivePreparation collectivePreparation;
  final List<WeeklyCollectiveCheckin> weeklyCheckins;
  final List<MacroCycle> macroCycles;

  SeasonPlan({
    this.id,
    required this.title,
    required this.year,
    this.startDate,
    this.endDate,
    this.teamId,
    this.collectivePreparation = const CollectivePreparation(),
    this.weeklyCheckins = const [],
    this.macroCycles = const [],
  });

  factory SeasonPlan.fromJson(Map<String, dynamic> json) {
    return SeasonPlan(
      id: json['_id'],
      title: json['title'] ?? '',
      year: json['year'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      teamId: json['teamId'],
        collectivePreparation: json['collectivePreparation'] is Map<String, dynamic>
          ? CollectivePreparation.fromJson(
            json['collectivePreparation'] as Map<String, dynamic>,
          )
          : const CollectivePreparation(),
        weeklyCheckins: (json['weeklyCheckins'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(WeeklyCollectiveCheckin.fromJson)
            .toList() ??
          const [],
      macroCycles: (json['macroCycles'] as List<dynamic>?)
              ?.map((e) => MacroCycle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'year': year,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        if (teamId != null) 'teamId': teamId,
        'collectivePreparation': collectivePreparation.toJson(),
        'weeklyCheckins': weeklyCheckins.map((e) => e.toJson()).toList(),
        'macroCycles': macroCycles.map((e) => e.toJson()).toList(),
      };
}

double _readDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
