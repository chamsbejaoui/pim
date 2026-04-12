// ─── CONSIGNES COLLECTIVES ───────────────────────────────────────────────────
class ConsignesCollectives {
  final List<String> phasesDefensives;
  final List<String> phasesOffensives;
  final List<String> transitionsOffensives;
  final List<String> transitionsDefensives;

  ConsignesCollectives({
    this.phasesDefensives = const [],
    this.phasesOffensives = const [],
    this.transitionsOffensives = const [],
    this.transitionsDefensives = const [],
  });

  factory ConsignesCollectives.fromJson(Map<String, dynamic> json) {
    return ConsignesCollectives(
      phasesDefensives: (json['phases_defensives'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      phasesOffensives: (json['phases_offensives'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      transitionsOffensives: (json['transitions_offensives'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      transitionsDefensives: (json['transitions_defensives'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

// ─── PHASES ARRETEES ─────────────────────────────────────────────────────────
class PhasesArretees {
  final String cornersPour;
  final String cornersContre;
  final String coupsFrancsPour;
  final String coupsFrancsContre;

  PhasesArretees({
    this.cornersPour = '',
    this.cornersContre = '',
    this.coupsFrancsPour = '',
    this.coupsFrancsContre = '',
  });

  factory PhasesArretees.fromJson(Map<String, dynamic> json) {
    return PhasesArretees(
      cornersPour: json['corners_pour'] ?? '',
      cornersContre: json['corners_contre'] ?? '',
      coupsFrancsPour: json['coups_francs_pour'] ?? '',
      coupsFrancsContre: json['coups_francs_contre'] ?? '',
    );
  }
}

// ─── TACTICAL PLAYER ─────────────────────────────────────────────────────────
class TacticalPlayer {
  final String? playerId;
  final String playerName;
  final String role;
  final String roleLabel;
  final double x;
  final double y;
  final String? instruction;
  final List<String> actionsCles;
  final String? joueurAdverseASurveiller;

  TacticalPlayer({
    this.playerId,
    required this.playerName,
    required this.role,
    this.roleLabel = '',
    required this.x,
    required this.y,
    this.instruction,
    this.actionsCles = const [],
    this.joueurAdverseASurveiller,
  });

  factory TacticalPlayer.fromJson(Map<String, dynamic> json) {
    return TacticalPlayer(
      playerId: json['player_id'],
      playerName: json['player_name'] ?? 'Inconnu',
      role: json['role'] ?? 'UKN',
      roleLabel: json['role_label'] ?? '',
      x: (json['x'] ?? 0.5).toDouble(),
      y: (json['y'] ?? 0.5).toDouble(),
      instruction: json['instruction'],
      actionsCles: (json['actions_cles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      joueurAdverseASurveiller: json['joueur_adverse_a_surveiller'],
    );
  }
}

// ─── VARIANTES SELON SCORE ───────────────────────────────────────────────────
class VariantesSelonScore {
  final String siOnMene;
  final String siEgalite;
  final String siOnPerd;

  VariantesSelonScore({
    this.siOnMene = '',
    this.siEgalite = '',
    this.siOnPerd = '',
  });

  factory VariantesSelonScore.fromJson(Map<String, dynamic> json) {
    return VariantesSelonScore(
      siOnMene: json['si_on_mene'] ?? '',
      siEgalite: json['si_egalite'] ?? '',
      siOnPerd: json['si_on_perd'] ?? '',
    );
  }
}

class OpponentPlayerStatsInput {
  final double? rating;
  final int? goals;
  final int? assists;
  final int? shots;
  final int? passes;
  final int? tackles;
  final int? minutes;

  const OpponentPlayerStatsInput({
    this.rating,
    this.goals,
    this.assists,
    this.shots,
    this.passes,
    this.tackles,
    this.minutes,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (rating != null) map['rating'] = rating;
    if (goals != null) map['goals'] = goals;
    if (assists != null) map['assists'] = assists;
    if (shots != null) map['shots'] = shots;
    if (passes != null) map['passes'] = passes;
    if (tackles != null) map['tackles'] = tackles;
    if (minutes != null) map['minutes'] = minutes;
    return map;
  }
}

class OpponentSquadPlayerInput {
  final String name;
  final String position;
  final String? status;
  final double? rating;
  final OpponentPlayerStatsInput? stats;

  const OpponentSquadPlayerInput({
    required this.name,
    required this.position,
    this.status,
    this.rating,
    this.stats,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'position': position,
    };
    if (status != null && status!.trim().isNotEmpty) map['status'] = status;
    if (rating != null) map['rating'] = rating;
    if (stats != null) {
      final statsJson = stats!.toJson();
      if (statsJson.isNotEmpty) map['stats'] = statsJson;
    }
    return map;
  }
}

class OpponentAnalysisRequest {
  final String? opponentStyle;
  final String? opponentTeamName;
  final String? preferredFormation;
  final List<String>? strengths;
  final List<String>? weaknesses;
  final List<OpponentSquadPlayerInput>? opponentSquad;

  const OpponentAnalysisRequest({
    this.opponentStyle,
    this.opponentTeamName,
    this.preferredFormation,
    this.strengths,
    this.weaknesses,
    this.opponentSquad,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (opponentStyle != null && opponentStyle!.trim().isNotEmpty) {
      map['opponentStyle'] = opponentStyle;
    }
    if (opponentTeamName != null && opponentTeamName!.trim().isNotEmpty) {
      map['opponentTeamName'] = opponentTeamName;
    }
    if (preferredFormation != null && preferredFormation!.trim().isNotEmpty) {
      map['preferredFormation'] = preferredFormation;
    }
    if (strengths != null && strengths!.isNotEmpty) {
      map['strengths'] = strengths;
    }
    if (weaknesses != null && weaknesses!.isNotEmpty) {
      map['weaknesses'] = weaknesses;
    }
    if (opponentSquad != null && opponentSquad!.isNotEmpty) {
      map['opponentSquad'] = opponentSquad!.map((player) => player.toJson()).toList();
    }
    return map;
  }
}

class OpponentOverview {
  final String teamName;
  final String style;
  final String? preferredFormation;
  final List<String> strengths;
  final List<String> weaknesses;
  final int squadSize;

  const OpponentOverview({
    required this.teamName,
    required this.style,
    this.preferredFormation,
    this.strengths = const [],
    this.weaknesses = const [],
    this.squadSize = 0,
  });

  factory OpponentOverview.fromJson(Map<String, dynamic> json) {
    return OpponentOverview(
      teamName: (json['teamName'] ?? json['team_name'] ?? '').toString(),
      style: (json['style'] ?? '').toString(),
      preferredFormation: json['preferredFormation']?.toString() ?? json['preferred_formation']?.toString(),
      strengths: _stringListFrom(json['strengths']),
      weaknesses: _stringListFrom(json['weaknesses']),
      squadSize: _intFrom(json['squadSize'] ?? json['squad_size']),
    );
  }
}

class PositionSummary {
  final int count;
  final double averageRating;
  final int totalGoals;
  final int totalAssists;
  final int totalShots;
  final int totalPasses;
  final int totalTackles;

  const PositionSummary({
    this.count = 0,
    this.averageRating = 0,
    this.totalGoals = 0,
    this.totalAssists = 0,
    this.totalShots = 0,
    this.totalPasses = 0,
    this.totalTackles = 0,
  });

  factory PositionSummary.fromJson(Map<String, dynamic> json) {
    return PositionSummary(
      count: _intFrom(json['count']),
      averageRating: _doubleFrom(json['averageRating'] ?? json['average_rating']),
      totalGoals: _intFrom(json['totalGoals'] ?? json['total_goals']),
      totalAssists: _intFrom(json['totalAssists'] ?? json['total_assists']),
      totalShots: _intFrom(json['totalShots'] ?? json['total_shots']),
      totalPasses: _intFrom(json['totalPasses'] ?? json['total_passes']),
      totalTackles: _intFrom(json['totalTackles'] ?? json['total_tackles']),
    );
  }
}

class KeyPlayerInsight {
  final String name;
  final String position;
  final String status;
  final double rating;
  final double threatScore;

  const KeyPlayerInsight({
    required this.name,
    required this.position,
    this.status = '',
    this.rating = 0,
    this.threatScore = 0,
  });

  factory KeyPlayerInsight.fromJson(Map<String, dynamic> json) {
    return KeyPlayerInsight(
      name: (json['name'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      rating: _doubleFrom(json['rating']),
      threatScore: _doubleFrom(json['threatScore'] ?? json['threat_score']),
    );
  }
}

class RealismFlags {
  final bool hasRealOpponentSquad;
  final bool hasIndividualPlayerStats;
  final bool hasDeclaredStrengths;
  final bool hasDeclaredWeaknesses;

  const RealismFlags({
    this.hasRealOpponentSquad = false,
    this.hasIndividualPlayerStats = false,
    this.hasDeclaredStrengths = false,
    this.hasDeclaredWeaknesses = false,
  });

  factory RealismFlags.fromJson(Map<String, dynamic> json) {
    return RealismFlags(
      hasRealOpponentSquad: json['hasRealOpponentSquad'] == true,
      hasIndividualPlayerStats: json['hasIndividualPlayerStats'] == true,
      hasDeclaredStrengths: json['hasDeclaredStrengths'] == true,
      hasDeclaredWeaknesses: json['hasDeclaredWeaknesses'] == true,
    );
  }
}

// ─── TACTICAL PLAN ───────────────────────────────────────────────────────────
class TacticalPlan {
  final String formation;
  final String formationJustification;
  final String instructions;
  final List<String> strengths;
  final List<String> weaknesses;
  final String? dangerPrincipal;
  final String? blocDefensif;
  final String? pressingTrigger;
  final String? axeOffensif;
  final ConsignesCollectives? consignesCollectives;
  final PhasesArretees? phasesArretees;
  final VariantesSelonScore? variantesSelonScore;
  final String? messageVestiaire;
  final List<TacticalPlayer> startingXi;
  final OpponentOverview? opponent;
  final Map<String, PositionSummary> summaryByPosition;
  final List<KeyPlayerInsight> keyPlayers;
  final List<String> tacticalFocus;
  final String? aiSource;
  final RealismFlags? realism;

  TacticalPlan({
    required this.formation,
    this.formationJustification = '',
    required this.instructions,
    this.strengths = const [],
    this.weaknesses = const [],
    this.dangerPrincipal,
    this.blocDefensif,
    this.pressingTrigger,
    this.axeOffensif,
    this.consignesCollectives,
    this.phasesArretees,
    this.variantesSelonScore,
    this.messageVestiaire,
    required this.startingXi,
    this.opponent,
    this.summaryByPosition = const {},
    this.keyPlayers = const [],
    this.tacticalFocus = const [],
    this.aiSource,
    this.realism,
  });

  factory TacticalPlan.fromJson(Map<String, dynamic> json) {
    final dynamic summaryDynamic = json['summaryByPosition'] ??
        (json['analysis'] is Map ? (json['analysis'] as Map)['summaryByPosition'] : null);
    final summaryMap = <String, PositionSummary>{};
    if (summaryDynamic is Map) {
      summaryDynamic.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          summaryMap[key.toString()] = PositionSummary.fromJson(value);
        } else if (value is Map) {
          summaryMap[key.toString()] = PositionSummary.fromJson(
            value.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      });
    }

    final dynamic keyPlayersDynamic = json['keyPlayers'] ??
        (json['analysis'] is Map ? (json['analysis'] as Map)['keyPlayers'] : null);

    final dynamic focusDynamic = json['tacticalFocus'] ??
        (json['analysis'] is Map ? (json['analysis'] as Map)['tacticalFocus'] : null);

    final aiSource = (json['analysis'] is Map &&
            (json['analysis'] as Map)['aiSource'] != null)
        ? (json['analysis'] as Map)['aiSource'].toString()
        : (json['aiRecommendation'] is Map &&
                (json['aiRecommendation'] as Map)['source'] != null)
            ? (json['aiRecommendation'] as Map)['source'].toString()
            : null;

    return TacticalPlan(
      formation: json['formation'] ?? '',
      formationJustification: json['formation_justification'] ?? '',
      instructions: json['instructions'] ?? '',
      strengths: (json['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      dangerPrincipal: json['danger_principal'],
      blocDefensif: json['bloc_defensif'],
      pressingTrigger: json['pressing_trigger'],
      axeOffensif: json['axe_offensif'],
      consignesCollectives: json['consignes_collectives'] != null
          ? ConsignesCollectives.fromJson(json['consignes_collectives'])
          : null,
      phasesArretees: json['phases_arretees'] != null
          ? PhasesArretees.fromJson(json['phases_arretees'])
          : null,
      variantesSelonScore: json['variantes_selon_score'] != null
          ? VariantesSelonScore.fromJson(json['variantes_selon_score'])
          : null,
      messageVestiaire: json['message_vestiaire'],
      startingXi: (json['starting_xi'] as List<dynamic>?)
              ?.map((e) => TacticalPlayer.fromJson(e))
              .toList() ??
          [],
      opponent: json['opponent'] is Map<String, dynamic>
          ? OpponentOverview.fromJson(json['opponent'])
          : json['opponent'] is Map
              ? OpponentOverview.fromJson(
                  (json['opponent'] as Map).map((k, v) => MapEntry(k.toString(), v)),
                )
              : null,
      summaryByPosition: summaryMap,
      keyPlayers: (keyPlayersDynamic as List<dynamic>?)
              ?.map((item) {
                if (item is Map<String, dynamic>) {
                  return KeyPlayerInsight.fromJson(item);
                }
                if (item is Map) {
                  return KeyPlayerInsight.fromJson(
                    item.map((k, v) => MapEntry(k.toString(), v)),
                  );
                }
                return null;
              })
              .whereType<KeyPlayerInsight>()
              .toList() ??
          [],
      tacticalFocus: _stringListFrom(focusDynamic),
      aiSource: aiSource,
      realism: json['realism'] is Map<String, dynamic>
          ? RealismFlags.fromJson(json['realism'])
          : json['realism'] is Map
              ? RealismFlags.fromJson(
                  (json['realism'] as Map).map((k, v) => MapEntry(k.toString(), v)),
                )
              : null,
    );
  }
}

List<String> _stringListFrom(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

int _intFrom(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

double _doubleFrom(dynamic value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}
