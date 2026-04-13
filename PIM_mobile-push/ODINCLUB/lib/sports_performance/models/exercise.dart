import 'package:flutter/material.dart';

enum ExerciseCategory {
  physical('Physical'),
  technical('Technical'),
  tactical('Tactical'),
  cognitive('Cognitive');

  final String value;
  const ExerciseCategory(this.value);

  static ExerciseCategory fromString(String value) {
    return ExerciseCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExerciseCategory.physical,
    );
  }

  String get label {
    switch (this) {
      case ExerciseCategory.physical: return 'Physique';
      case ExerciseCategory.technical: return 'Technique';
      case ExerciseCategory.tactical: return 'Tactique';
      case ExerciseCategory.cognitive: return 'Cognitif';
    }
  }

  Color get color {
    switch (this) {
      case ExerciseCategory.physical: return Colors.orange;
      case ExerciseCategory.technical: return Colors.blue;
      case ExerciseCategory.tactical: return Colors.green;
      case ExerciseCategory.cognitive: return Colors.purple;
    }
  }
}

enum IntensityLevel {
  low('Low'),
  medium('Medium'),
  high('High');

  final String value;
  const IntensityLevel(this.value);

  static IntensityLevel fromString(String value) {
    return IntensityLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IntensityLevel.medium,
    );
  }

  String get label {
    switch (this) {
      case IntensityLevel.low: return 'Basse';
      case IntensityLevel.medium: return 'Moyenne';
      case IntensityLevel.high: return 'Haute';
    }
  }

  Color get color {
    switch (this) {
      case IntensityLevel.low: return Colors.blue;
      case IntensityLevel.medium: return Colors.orange;
      case IntensityLevel.high: return Colors.red;
    }
  }
}

enum PitchPosition {
  gk('GK'),
  def('DEF'),
  mid('MID'),
  att('ATT');

  final String value;
  const PitchPosition(this.value);

  static PitchPosition fromString(String value) {
    return PitchPosition.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PitchPosition.def,
    );
  }
}

class TechnicalData {
  final String description;
  final String sets;
  final String reps;
  final List<String> coachingCues;
  final List<String> equipment;
  final List<String> steps; // Added steps
  final String restTime;

  TechnicalData({
    required this.description,
    required this.sets,
    required this.reps,
    required this.coachingCues,
    required this.equipment,
    required this.steps, // Added to constructor
    required this.restTime,
  });

  factory TechnicalData.fromJson(Map<String, dynamic> json) {
    return TechnicalData(
      description: json['description'] ?? '',
      sets: json['sets']?.toString() ?? '',
      reps: json['reps']?.toString() ?? '',
      coachingCues: List<String>.from(json['coachingCues'] ?? []),
      equipment: List<String>.from(json['equipment'] ?? []),
      steps: List<String>.from(json['steps'] ?? []), // Added mapping
      restTime: json['restTime'] ?? '',
    );
  }
}

class PerformanceImpact {
  final double speed;
  final double endurance;
  final double technique;

  PerformanceImpact({
    required this.speed,
    required this.endurance,
    required this.technique,
  });

  factory PerformanceImpact.fromJson(Map<String, dynamic> json) {
    return PerformanceImpact(
      speed: (json['speed'] ?? 0).toDouble(),
      endurance: (json['endurance'] ?? 0).toDouble(),
      technique: (json['technique'] ?? 0).toDouble(),
    );
  }
}

class GenerationContext {
  final String objective;
  final int playerFatigueAtGeneration;
  final String aiModelUsed;
  final double aiConfidenceScore;

  GenerationContext({
    required this.objective,
    required this.playerFatigueAtGeneration,
    required this.aiModelUsed,
    required this.aiConfidenceScore,
  });

  factory GenerationContext.fromJson(Map<String, dynamic> json) {
    return GenerationContext(
      objective: json['objective'] ?? '',
      playerFatigueAtGeneration: json['playerFatigueAtGeneration'] ?? 0,
      aiModelUsed: json['aiModelUsed'] ?? '',
      aiConfidenceScore: (json['aiConfidenceScore'] ?? 0).toDouble(),
    );
  }
}

class CompletedSession {
  final String playerId;
  final DateTime completedAt;
  final int durationSeconds;
  final int lapsCount;

  CompletedSession({
    required this.playerId,
    required this.completedAt,
    required this.durationSeconds,
    required this.lapsCount,
  });

  factory CompletedSession.fromJson(Map<String, dynamic> json) {
    return CompletedSession(
      playerId: json['playerId'] ?? '',
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : DateTime.now(),
      durationSeconds: json['durationSeconds'] ?? 0,
      lapsCount: json['lapsCount'] ?? 0,
    );
  }
}

class Exercise {
  final String id;
  final String name;
  final ExerciseCategory category;
  final int difficulty;
  final double duration;
  final IntensityLevel intensity;
  final List<PitchPosition> targetPositions;
  final bool aiGenerated;
  final String? imageUrl;
  final GenerationContext? generationContext;
  final TechnicalData? technicalData;
  final PerformanceImpact? performanceImpact;
  final List<CompletedSession> completedSessions;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.intensity,
    required this.targetPositions,
    required this.aiGenerated,
    this.imageUrl,
    this.generationContext,
    this.technicalData,
    this.performanceImpact,
    this.completedSessions = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      category: ExerciseCategory.fromString(json['category'] ?? ''),
      difficulty: json['difficulty'] ?? 3,
      duration: (json['duration'] ?? 0).toDouble(),
      intensity: IntensityLevel.fromString(json['intensity'] ?? ''),
      targetPositions: (json['targetPositions'] as List?)
              ?.map((p) => PitchPosition.fromString(p))
              .toList() ??
          [],
      aiGenerated: json['aiGenerated'] ?? false,
      imageUrl: json['imageUrl'],
      generationContext: json['generationContext'] != null
          ? GenerationContext.fromJson(json['generationContext'])
          : null,
      technicalData: json['technicalData'] != null
          ? TechnicalData.fromJson(json['technicalData'])
          : null,
      performanceImpact: json['performanceImpact'] != null
          ? PerformanceImpact.fromJson(json['performanceImpact'])
          : null,
      completedSessions: (json['completedSessions'] as List?)
              ?.map((s) => CompletedSession.fromJson(s))
              .toList() ??
          [],
    );
  }
}
