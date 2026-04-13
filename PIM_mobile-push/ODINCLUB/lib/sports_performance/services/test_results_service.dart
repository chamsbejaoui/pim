import '../models/test_result.dart';
import 'api_client.dart';

class TestResultsService {
  final ApiClient _apiClient;

  TestResultsService(this._apiClient);

  // Get all test results for an event player
  Future<List<TestResult>> getTestResults(String eventPlayerId) async {
    try {
      final response =
          await _apiClient.get('/event-players/$eventPlayerId/test-results');
      final List<dynamic> data = response.data;
      return data.map((json) => TestResult.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des résultats de tests: $e');
    }
  }

  // Create test result
  Future<TestResult> createTestResult(
    String eventPlayerId,
    String testTypeId,
    double rawValue, {
    String? notes,
    String? recordedBy,
  }) async {
    try {
      final response = await _apiClient.post(
        '/event-players/$eventPlayerId/test-results',
        data: {
          'testTypeId': testTypeId,
          'rawValue': rawValue,
          if (notes != null) 'notes': notes,
          if (recordedBy != null) 'recordedBy': recordedBy,
        },
      );
      return TestResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la création du résultat de test: $e');
    }
  }

  // Update test result
  Future<TestResult> updateTestResult(
    String id,
    double rawValue, {
    String? notes,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/test-results/$id',
        data: {
          'rawValue': rawValue,
          if (notes != null) 'notes': notes,
        },
      );
      return TestResult.fromJson(response.data);
    } catch (e) {
      throw Exception(
          'Erreur lors de la mise à jour du résultat de test: $e');
    }
  }

  // Delete test result
  Future<void> deleteTestResult(String id) async {
    try {
      await _apiClient.delete('/test-results/$id');
    } catch (e) {
      throw Exception(
          'Erreur lors de la suppression du résultat de test: $e');
    }
  }
}
