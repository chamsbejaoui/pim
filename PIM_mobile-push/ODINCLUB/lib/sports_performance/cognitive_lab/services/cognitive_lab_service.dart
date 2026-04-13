import '../models/cognitive_session.dart';
import '../../services/api_client.dart';

class CognitiveLabService {
  final ApiClient _apiClient;

  CognitiveLabService(this._apiClient);

  Future<CognitiveSession> createSession(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/cognitive-lab/sessions', data: data);
      return CognitiveSession.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la création de la session cognitive: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboard(String playerId) async {
    try {
      final response = await _apiClient.get('/cognitive-lab/dashboard/$playerId');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du dashboard cognitif: $e');
    }
  }

  Future<Map<String, dynamic>> getSquadOverview() async {
    try {
      final response = await _apiClient.get('/cognitive-lab/squad-today');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du squad overview: $e');
    }
  }
}
