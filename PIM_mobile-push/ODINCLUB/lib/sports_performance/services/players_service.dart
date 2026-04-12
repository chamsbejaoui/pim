import '../models/player.dart';
import 'api_client.dart';

class PlayersService {
  final ApiClient _apiClient;

  PlayersService(this._apiClient);

  // Get all players
  Future<List<Player>> getPlayers() async {
    try {
      final response = await _apiClient.get('/players');
      final List<dynamic> data = response.data;
      return data.map((json) => Player.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des joueurs: $e');
    }
  }

  // Get player by ID
  Future<Player> getPlayer(String id) async {
    try {
      final response = await _apiClient.get('/players/$id');
      return Player.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du joueur: $e');
    }
  }

  // Create player
  Future<Player> createPlayer(Player player) async {
    try {
      final response = await _apiClient.post(
        '/players',
        data: player.toJson(),
      );
      return Player.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la création du joueur: $e');
    }
  }

  // Update player
  Future<Player> updatePlayer(String id, Player player) async {
    try {
      final response = await _apiClient.patch(
        '/players/$id',
        data: player.toJson(),
      );
      return Player.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du joueur: $e');
    }
  }

  // Delete player
  Future<void> deletePlayer(String id) async {
    try {
      await _apiClient.delete('/players/$id');
    } catch (e) {
      throw Exception('Erreur lors de la suppression du joueur: $e');
    }
  }
}
