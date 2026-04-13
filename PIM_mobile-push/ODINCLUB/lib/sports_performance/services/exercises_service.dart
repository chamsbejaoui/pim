import '../models/exercise.dart';
import 'api_client.dart';

class ExercisesService {
  final ApiClient _apiClient;

  ExercisesService(this._apiClient);

  // Get all exercises
  Future<List<Exercise>> getExercises({String? category, bool? aiGenerated}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (category != null) queryParams['category'] = category;
      if (aiGenerated != null) queryParams['aiGenerated'] = aiGenerated.toString();

      final response = await _apiClient.get(
        '/exercises',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Exercise.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des exercices: $e');
    }
  }

  // Get exercise by ID
  Future<Exercise> getExercise(String id) async {
    try {
      final response = await _apiClient.get('/exercises/$id');
      return Exercise.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'exercice: $e');
    }
  }

  // Generate AI Drill
  Future<Exercise> generateAiDrill(Map<String, dynamic> context) async {
    try {
      final response = await _apiClient.post(
        '/exercises/ai-generate',
        data: context,
      );
      return Exercise.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la génération de l\'exercice IA: $e');
    }
  }

  // Adapt Difficulty
  Future<Exercise> adaptDifficulty(String id, double performanceRatio) async {
    try {
      final response = await _apiClient.patch(
        '/exercises/$id/adapt',
        data: {'performanceRatio': performanceRatio},
      );
      return Exercise.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de l\'adaptation de la difficulté: $e');
    }
  }

  // Get AI insights for a player
  Future<Map<String, dynamic>> getPlayerInsights(String playerId) async {
    try {
      final response = await _apiClient.get('/exercises/insights/$playerId');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des insights joueur: $e');
    }
  }

  // Delete exercise
  Future<void> deleteExercise(String id) async {
    try {
      await _apiClient.delete('/exercises/$id');
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'exercice: $e');
    }
  }

  // Update exercise
  Future<Exercise> updateExercise(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('/exercises/$id', data: data);
      return Exercise.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'exercice: $e');
    }
  }

  // Record exercise session completion
  Future<Map<String, dynamic>> recordCompletion(
    String exerciseId, {
    required String playerId,
    required int durationSeconds,
    required int lapsCount,
  }) async {
    try {
      final response = await _apiClient.post(
        '/exercises/$exerciseId/complete',
        data: {
          'playerId': playerId,
          'durationSeconds': durationSeconds,
          'lapsCount': lapsCount,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement de la session: $e');
    }
  }
}
