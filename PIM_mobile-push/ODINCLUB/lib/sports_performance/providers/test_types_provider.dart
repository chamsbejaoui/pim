import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/test_type.dart';
import '../services/api_client.dart';
import '../services/test_types_service.dart';

// Service Provider
final testTypesServiceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return TestTypesService(apiClient);
});

// Test Types List Provider
final testTypesProvider =
    FutureProvider.autoDispose.family<List<TestType>, bool>((ref, activeOnly) async {
  final service = ref.read(testTypesServiceProvider);
  return service.getTestTypes(activeOnly: activeOnly);
});

// Active Test Types Provider (shortcut)
final activeTestTypesProvider = FutureProvider<List<TestType>>((ref) async {
  final service = ref.read(testTypesServiceProvider);
  return service.getTestTypes(activeOnly: true);
});

// Single Test Type Provider
final testTypeProvider =
    FutureProvider.family<TestType, String>((ref, testTypeId) async {
  final service = ref.read(testTypesServiceProvider);
  return service.getTestType(testTypeId);
});

// Test Type Form State Provider
final testTypeFormProvider =
    StateNotifierProvider<TestTypeFormNotifier, AsyncValue<TestType?>>((ref) {
  final service = ref.read(testTypesServiceProvider);
  return TestTypeFormNotifier(service, ref);
});

class TestTypeFormNotifier extends StateNotifier<AsyncValue<TestType?>> {
  final TestTypesService _service;
  final Ref _ref;

  TestTypeFormNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<TestType?> createTestType(TestType testType) async {
    state = const AsyncValue.loading();
    try {
      final createdTestType = await _service.createTestType(testType);
      state = AsyncValue.data(createdTestType);
      _ref.invalidate(testTypesProvider);
      _ref.invalidate(activeTestTypesProvider);
      return createdTestType;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<TestType?> updateTestType(String id, TestType testType) async {
    state = const AsyncValue.loading();
    try {
      final updatedTestType = await _service.updateTestType(id, testType);
      state = AsyncValue.data(updatedTestType);
      _ref.invalidate(testTypesProvider);
      _ref.invalidate(activeTestTypesProvider);
      _ref.invalidate(testTypeProvider(id));
      return updatedTestType;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<bool> deleteTestType(String id) async {
    try {
      await _service.deleteTestType(id);
      _ref.invalidate(testTypesProvider);
      _ref.invalidate(activeTestTypesProvider);
      return true;
    } catch (e) {
      return false;
    }
  }
}
