class RoleMapper {
  static const String admin = 'ADMIN';
  static const String clubResponsable = 'CLUB_RESPONSABLE';
  static const String staffTechnique = 'STAFF_TECHNIQUE';
  static const String analyst = 'ANALYST';
  static const String scout = 'SCOUT';
  static const String finance = 'FINANCIER';
  static const String player = 'JOUEUR';
  static const String staffMedical = 'STAFF_MEDICAL';

  static const Map<String, String> _aliasToCode = {
    'CLUB_MANAGER': clubResponsable,
    'COACH': staffTechnique,
    'MEDICAL': staffMedical,
    'FINANCE': finance,
    'PLAYER': player,
  };
  static const Map<String, String> _labelByCode = {
    admin: 'Administrateur',
    clubResponsable: 'Responsable du club',
    staffTechnique: 'Entraîneur',
    analyst: 'Analyste',
    scout: 'Scout',
    finance: 'Comptable',
    player: 'Joueur',
    staffMedical: 'Staff médical',
  };

  static String toLabel(String? code) {
    if (code == null) return '';
    return _labelByCode[code] ?? code;
  }

  static String toCode(String label) {
    final entry = _labelByCode.entries.firstWhere(
      (e) => e.value == label,
      orElse: () => const MapEntry('', ''),
    );
    return entry.key.isNotEmpty ? entry.key : label;
  }

  static String normalize(String? role) {
    if (role == null || role.isEmpty) return '';
    final trimmed = role.trim();
    if (_aliasToCode.containsKey(trimmed)) {
      return _aliasToCode[trimmed]!;
    }
    return toCode(trimmed);
  }

  static bool isAdmin(String? role) {
    return normalize(role) == admin;
  }

  static List<String> get labels => _labelByCode.values.toList();
}
