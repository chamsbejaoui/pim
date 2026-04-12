enum AlertStatus { safe, warning, injured }

enum AlertDecision { play, limit, substitute }

class AlertModel {
  const AlertModel({
    required this.playerId,
    required this.playerName,
    required this.risk,
    required this.fatigue,
    required this.load,
    required this.minutes,
    required this.injuryType,
    required this.severity,
    required this.recoveryDays,
    required this.status,
    required this.decision,
    required this.reasons,
    required this.notify,
    required this.createdAt,
  });

  final String playerId;
  final String playerName;
  final double risk;
  final double fatigue;
  final double load;
  final int minutes;
  final String? injuryType;
  final String? severity;
  final int? recoveryDays;
  final AlertStatus status;
  final AlertDecision decision;
  final List<String> reasons;
  final bool notify;
  final DateTime createdAt;

  String get title {
    switch (status) {
      case AlertStatus.injured:
        return 'High Risk';
      case AlertStatus.warning:
        return 'Warning';
      case AlertStatus.safe:
        return 'Safe';
    }
  }

  String get message {
    switch (status) {
      case AlertStatus.injured:
        return 'SUBSTITUTE PLAYER IMMEDIATELY';
      case AlertStatus.warning:
        return 'Reduce intensity';
      case AlertStatus.safe:
        return 'Player stable';
    }
  }
}
