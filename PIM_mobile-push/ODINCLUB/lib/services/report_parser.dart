import '../models/ai_player.dart';

/// Extracts player stats from a scouting report text.
/// Supports both English and French keywords.
class ReportParser {
  static final _namePatterns = [
    RegExp(r'(?:player|name|joueur|nom)\s*[:\-–]\s*(.+)', caseSensitive: false),
    RegExp(r'^([A-Z][a-zÀ-ÿ]+(?:\s+[A-Z][a-zÀ-ÿ]+)+)', multiLine: true),
  ];

  static final _clubPatterns = [
    RegExp(r'(?:club|team|équipe|equipe)\s*[:\-–]\s*(.+)', caseSensitive: false),
  ];

  static final _agePatterns = [
    RegExp(r'(?:age|âge)\s*[:\-–]\s*(\d+)', caseSensitive: false),
    RegExp(r'(\d{1,2})\s*(?:ans|years?\s*old)', caseSensitive: false),
  ];

  static final _speedPatterns = [
    RegExp(r'(?:speed|vitesse|pace|rapidité)\s*[:\-–]\s*([\d.]+)',
        caseSensitive: false),
    RegExp(r'([\d.]+)\s*(?:km/?h|speed)', caseSensitive: false),
  ];

  static final _endurancePatterns = [
    RegExp(r'(?:endurance|stamina|endur)\s*[:\-–]\s*([\d.]+)',
        caseSensitive: false),
  ];

  static final _distancePatterns = [
    RegExp(r'(?:distance|dist)\s*[:\-–]\s*([\d.]+)', caseSensitive: false),
    RegExp(r'([\d.]+)\s*km', caseSensitive: false),
  ];

  static final _dribblesPatterns = [
    RegExp(r'(?:dribbles?|dribbling)\s*[:\-–]\s*([\d.]+)',
        caseSensitive: false),
  ];

  static final _shotsPatterns = [
    RegExp(r'(?:shots?|tirs?|shooting|frappe)\s*[:\-–]\s*([\d.]+)',
        caseSensitive: false),
  ];

  static final _injuriesPatterns = [
    RegExp(r'(?:injur(?:ies|y)|blessure?s?)\s*[:\-–]\s*(\d+)',
        caseSensitive: false),
  ];

  static final _heartRatePatterns = [
    RegExp(
        r'(?:heart[_\s]?rate|bpm|rythme?\s*cardiaque|fc|fréquence?\s*cardiaque)\s*[:\-–]\s*([\d.]+)',
        caseSensitive: false),
    RegExp(r'([\d.]+)\s*bpm', caseSensitive: false),
  ];

  static AiPlayer? extractFromText(String text) {
    final name = _extractString(text, _namePatterns);
    if (name == null || name.isEmpty) return null;

    return AiPlayer(
      name: name.trim(),
      club: _extractString(text, _clubPatterns)?.trim(),
      age: _extractInt(text, _agePatterns),
      speed: _extractDouble(text, _speedPatterns) ?? 50,
      endurance: _extractDouble(text, _endurancePatterns) ?? 50,
      distance: _extractDouble(text, _distancePatterns) ?? 5.0,
      dribbles: _extractDouble(text, _dribblesPatterns) ?? 10,
      shots: _extractDouble(text, _shotsPatterns) ?? 0,
      injuries: _extractInt(text, _injuriesPatterns) ?? 0,
      heartRate: _extractDouble(text, _heartRatePatterns) ?? 70,
    );
  }

  static List<AiPlayer> extractMultiple(String text) {
    final sections = text.split(RegExp(r'\n\s*(?:---|===|___)\s*\n'));
    final players = <AiPlayer>[];
    for (final section in sections) {
      if (section.trim().isEmpty) continue;
      final player = extractFromText(section);
      if (player != null) players.add(player);
    }
    return players;
  }

  static String? _extractString(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  static double? _extractDouble(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return double.tryParse(match.group(1)!);
      }
    }
    return null;
  }

  static int? _extractInt(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }
}
