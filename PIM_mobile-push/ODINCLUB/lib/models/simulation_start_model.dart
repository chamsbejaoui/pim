import 'player_model.dart';
import 'simulation_player_model.dart';

class SimulationStartModel {
  const SimulationStartModel({
    required this.matchId,
    required this.teamA,
    required this.teamB,
  });

  final String matchId;
  final List<PlayerModel> teamA;
  final List<SimulationPlayerModel> teamB;

  factory SimulationStartModel.fromJson(Map<String, dynamic> json) {
    final teamAJson = json['teamA'];
    final teamBJson = json['teamB'];

    return SimulationStartModel(
      matchId: (json['matchId'] ?? '').toString(),
      teamA: teamAJson is List
          ? teamAJson
                .map(
                  (item) => PlayerModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : const [],
      teamB: teamBJson is List
          ? teamBJson
                .map(
                  (item) => SimulationPlayerModel.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const [],
    );
  }
}
