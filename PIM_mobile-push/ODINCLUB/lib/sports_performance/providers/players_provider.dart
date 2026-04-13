import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import '../services/api_client.dart';
import '../services/players_service.dart';

// Service Provider
final apiClientProvider = Provider((ref) => ApiClient());

final playersServiceProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return PlayersService(apiClient);
});

// Players List Provider
final playersProvider = FutureProvider<List<Player>>((ref) async {
  final service = ref.read(playersServiceProvider);
  return service.getPlayers();
});

// Single Player Provider
final playerProvider =
    FutureProvider.family<Player, String>((ref, playerId) async {
  final service = ref.read(playersServiceProvider);
  return service.getPlayer(playerId);
});

// Player Create/Update State Provider
final playerFormProvider =
    StateNotifierProvider<PlayerFormNotifier, AsyncValue<Player?>>((ref) {
  final service = ref.read(playersServiceProvider);
  return PlayerFormNotifier(service, ref);
});

class PlayerFormNotifier extends StateNotifier<AsyncValue<Player?>> {
  final PlayersService _service;
  final Ref _ref;

  PlayerFormNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<Player?> createPlayer(Player player) async {
    state = const AsyncValue.loading();
    try {
      final createdPlayer = await _service.createPlayer(player);
      state = AsyncValue.data(createdPlayer);
      _ref.invalidate(playersProvider); // Refresh the list
      return createdPlayer;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<Player?> updatePlayer(String id, Player player) async {
    state = const AsyncValue.loading();
    try {
      final updatedPlayer = await _service.updatePlayer(id, player);
      state = AsyncValue.data(updatedPlayer);
      _ref.invalidate(playersProvider); // Refresh the list
      _ref.invalidate(playerProvider(id)); // Refresh specific player
      return updatedPlayer;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<bool> deletePlayer(String id) async {
    try {
      await _service.deletePlayer(id);
      _ref.invalidate(playersProvider); // Refresh the list
      return true;
    } catch (e) {
      return false;
    }
  }
}
