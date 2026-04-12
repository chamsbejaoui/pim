import 'package:flutter/material.dart';

enum ReadinessStatus { optimal, bon, attention, risque, nonAnalyse }

class ReadinessFactor {
  final String icon;
  final String label;
  final String type; // ok | warn | bad

  const ReadinessFactor({required this.icon, required this.label, required this.type});

  factory ReadinessFactor.fromJson(Map<String, dynamic> json) => ReadinessFactor(
        icon: json['icon'] ?? '📊',
        label: json['label'] ?? '',
        type: json['type'] ?? 'ok',
      );
}

class ReadinessResult {
  final String id;
  final String playerId;
  final String playerName;
  final int score;
  final String status;
  final bool titulaire;
  final List<ReadinessFactor> factors;
  final String? analysis;
  final String? recommendation;
  final bool usedAi;
  final DateTime? analyzedAt;

  const ReadinessResult({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.score,
    required this.status,
    required this.titulaire,
    required this.factors,
    this.analysis,
    this.recommendation,
    this.usedAi = false,
    this.analyzedAt,
  });

  ReadinessStatus get statusEnum {
    switch (status) {
      case 'optimal': return ReadinessStatus.optimal;
      case 'bon': return ReadinessStatus.bon;
      case 'attention': return ReadinessStatus.attention;
      case 'risque': return ReadinessStatus.risque;
      default: return ReadinessStatus.nonAnalyse;
    }
  }

  Color get statusColor {
    switch (statusEnum) {
      case ReadinessStatus.optimal: return const Color(0xFF10B981);
      case ReadinessStatus.bon: return const Color(0xFF3B82F6);
      case ReadinessStatus.attention: return const Color(0xFFF59E0B);
      case ReadinessStatus.risque: return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }

  String get statusLabel {
    switch (statusEnum) {
      case ReadinessStatus.optimal: return 'Optimal';
      case ReadinessStatus.bon: return 'Bon';
      case ReadinessStatus.attention: return 'Attention';
      case ReadinessStatus.risque: return 'Risque';
      default: return 'Non analysé';
    }
  }

  factory ReadinessResult.fromJson(Map<String, dynamic> json) => ReadinessResult(
        id: json['id'] ?? '',
        playerId: json['playerId'] ?? '',
        playerName: json['playerName'] ?? '',
        score: (json['score'] ?? 0) is int ? json['score'] : (json['score'] as num).toInt(),
        status: json['status'] ?? 'nonAnalyse',
        titulaire: json['titulaire'] ?? false,
        factors: (json['factors'] as List? ?? [])
            .map((f) => ReadinessFactor.fromJson(f as Map<String, dynamic>))
            .toList(),
        analysis: json['analysis'],
        recommendation: json['recommendation'],
        usedAi: json['usedAi'] ?? false,
        analyzedAt: json['analyzedAt'] != null
            ? DateTime.tryParse(json['analyzedAt'].toString())
            : null,
      );
}
