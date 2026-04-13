import '../models/event_report.dart';
import '../models/player_report.dart';
import 'api_client.dart';

class ReportsService {
  final ApiClient _apiClient;

  ReportsService(this._apiClient);

  // Generate all reports (event report + all player reports)
  Future<Map<String, dynamic>> generateAllReports(String eventId) async {
    try {
      final response =
          await _apiClient.post('/events/$eventId/generate-reports');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la génération des rapports: $e');
    }
  }

  // Get event report
  Future<EventReport> getEventReport(String eventId) async {
    try {
      final response = await _apiClient.get('/events/$eventId/report');
      return EventReport.fromJson(response.data);
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération du rapport événement: $e');
    }
  }

  // Get player report
  Future<PlayerReport> getPlayerReport(String eventPlayerId) async {
    try {
      final response =
          await _apiClient.get('/event-players/$eventPlayerId/report');
      return PlayerReport.fromJson(response.data);
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération du rapport joueur: $e');
    }
  }

  // Get event ranking
  Future<List<RankedPlayer>> getEventRanking(String eventId) async {
    try {
      final response = await _apiClient.get('/events/$eventId/ranking');
      final List<dynamic> data = response.data;
      return data.map((json) => RankedPlayer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération du classement: $e');
    }
  }

  // Get top players
  Future<List<TopPlayer>> getTopPlayers(String eventId) async {
    try {
      final response = await _apiClient.get('/events/$eventId/top-players');
      final List<dynamic> data = response.data;
      return data.map((json) => TopPlayer.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des top players: $e');
    }
  }
  // Get player progression (Tests vs Matches)
  Future<Map<String, dynamic>> getPlayerProgression(String playerId) async {
    try {
      final response = await _apiClient.get('/players/$playerId/progression');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la progression: $e');
    }
  }
}
