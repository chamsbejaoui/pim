import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../services/api_client.dart';
import '../services/exercises_service.dart';

final exercisesServiceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return ExercisesService(apiClient);
});

// All Exercises Provider
final exercisesProvider = FutureProvider.autoDispose<List<Exercise>>((ref) async {
  final service = ref.read(exercisesServiceProvider);
  return service.getExercises();
});

// Filtered Exercises Provider (Family)
final filteredExercisesProvider = FutureProvider.autoDispose.family<List<Exercise>, Map<String, dynamic>>((ref, filters) async {
  final service = ref.read(exercisesServiceProvider);
  return service.getExercises(
    category: filters['category'],
    aiGenerated: filters['aiGenerated'],
  );
});

// Player Insights Provider
final playerInsightsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, playerId) async {
  final service = ref.read(exercisesServiceProvider);
  return service.getPlayerInsights(playerId);
});

// AI Drill Generation Notifier
final aiDrillGenerationProvider = StateNotifierProvider<AiDrillGenerationNotifier, AsyncValue<Exercise?>>((ref) {
  final service = ref.read(exercisesServiceProvider);
  return AiDrillGenerationNotifier(service, ref);
});

class AiDrillGenerationNotifier extends StateNotifier<AsyncValue<Exercise?>> {
  final ExercisesService _service;
  final Ref _ref;

  AiDrillGenerationNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<Exercise?> generateDrill(Map<String, dynamic> context) async {
    state = const AsyncValue.loading();
    try {
      final drill = await _service.generateAiDrill(context);
      state = AsyncValue.data(drill);
      _ref.invalidate(exercisesProvider);
      return drill;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
}
