class SimulationPlayerModel {
  const SimulationPlayerModel({
    required this.id,
    required this.name,
    required this.position,
  });

  final String id;
  final String name;
  final String position;

  factory SimulationPlayerModel.fromJson(Map<String, dynamic> json) {
    return SimulationPlayerModel(
      id: _stringFrom(json, ['id', '_id', 'playerId']) ?? '',
      name: _stringFrom(json, ['name', 'fullName', 'playerName']) ?? 'Unknown',
      position: _stringFrom(json, ['position', 'role']) ?? 'Unknown',
    );
  }

  static String? _stringFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }
}
