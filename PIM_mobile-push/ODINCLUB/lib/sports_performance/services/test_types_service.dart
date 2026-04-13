import '../models/test_type.dart';
import 'api_client.dart';

class TestTypesService {
  final ApiClient _apiClient;

  TestTypesService(this._apiClient);

  // Get all test types
  Future<List<TestType>> getTestTypes({bool activeOnly = false}) async {
    try {
      final response = await _apiClient.get(
        '/test-types',
        queryParameters: activeOnly ? {'activeOnly': 'true'} : null,
      );
      final List<dynamic> data = response.data;
      return data.map((json) => TestType.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des types de tests: $e');
    }
  }

  // Get test type by ID
  Future<TestType> getTestType(String id) async {
    try {
      final response = await _apiClient.get('/test-types/$id');
      return TestType.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du type de test: $e');
    }
  }

  // Create test type
  Future<TestType> createTestType(TestType testType) async {
    try {
      final response = await _apiClient.post(
        '/test-types',
        data: testType.toJson(),
      );
      return TestType.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la création du type de test: $e');
    }
  }

  // Update test type
  Future<TestType> updateTestType(String id, TestType testType) async {
    try {
      final response = await _apiClient.patch(
        '/test-types/$id',
        data: testType.toJson(),
      );
      return TestType.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du type de test: $e');
    }
  }

  // Delete test type
  Future<void> deleteTestType(String id) async {
    try {
      await _apiClient.delete('/test-types/$id');
    } catch (e) {
      throw Exception('Erreur lors de la suppression du type de test: $e');
    }
  }
}
