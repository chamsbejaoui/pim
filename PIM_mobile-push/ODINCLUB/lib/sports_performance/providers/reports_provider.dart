import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_report.dart';
import '../models/player_report.dart';
import '../services/api_client.dart';
import '../services/reports_service.dart';

// Service Provider
final reportsServiceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return ReportsService(apiClient);
});

// Event Report Provider
final eventReportProvider =
    FutureProvider.family<EventReport, String>((ref, eventId) async {
  final service = ref.read(reportsServiceProvider);
  return service.getEventReport(eventId);
});

// Player Report Provider
final playerReportProvider =
    FutureProvider.family<PlayerReport, String>((ref, eventPlayerId) async {
  final service = ref.read(reportsServiceProvider);
  return service.getPlayerReport(eventPlayerId);
});

// Event Ranking Provider
final eventRankingProvider =
    FutureProvider.family<List<RankedPlayer>, String>((ref, eventId) async {
  final service = ref.read(reportsServiceProvider);
  return service.getEventRanking(eventId);
});

// Top Players Provider
final topPlayersProvider =
    FutureProvider.family<List<TopPlayer>, String>((ref, eventId) async {
  final service = ref.read(reportsServiceProvider);
  return service.getTopPlayers(eventId);
});

// Player Progression Provider
final playerProgressionProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, playerId) async {
  final service = ref.read(reportsServiceProvider);
  return service.getPlayerProgression(playerId);
});

// Report Generation State Provider
final reportGenerationProvider =
    StateNotifierProvider<ReportGenerationNotifier, AsyncValue<bool>>((ref) {
  final service = ref.read(reportsServiceProvider);
  return ReportGenerationNotifier(service, ref);
});

class ReportGenerationNotifier extends StateNotifier<AsyncValue<bool>> {
  final ReportsService _service;
  final Ref _ref;

  ReportGenerationNotifier(this._service, this._ref)
      : super(const AsyncValue.data(false));

  Future<bool> generateAllReports(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _service.generateAllReports(eventId);
      state = const AsyncValue.data(true);
      
      // Invalidate all related providers
      _ref.invalidate(eventReportProvider(eventId));
      _ref.invalidate(eventRankingProvider(eventId));
      _ref.invalidate(topPlayersProvider(eventId));
      
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(false);
  }
}
