import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../models/event_player.dart';
import '../services/api_client.dart';
import '../services/events_service.dart';

// Service Provider
final eventsServiceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return EventsService(apiClient);
});

// Events List Provider (with optional filters)
final eventsProvider = FutureProvider.autoDispose
    .family<List<Event>, EventsFilter?>((ref, filter) async {
  final service = ref.read(eventsServiceProvider);
  return service.getEvents(
    startDate: filter?.startDate,
    endDate: filter?.endDate,
    status: filter?.status,
  );
});

class EventsFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final EventStatus? status;

  EventsFilter({this.startDate, this.endDate, this.status});
}

// Single Event Provider
final eventProvider =
    FutureProvider.family<Event, String>((ref, eventId) async {
  final service = ref.read(eventsServiceProvider);
  return service.getEvent(eventId);
});

// Event Players Provider
final eventPlayersProvider =
    FutureProvider.family<List<EventPlayer>, String>((ref, eventId) async {
  final service = ref.read(eventsServiceProvider);
  return service.getEventPlayers(eventId);
});

// Event Form State Provider
final eventFormProvider =
    StateNotifierProvider<EventFormNotifier, AsyncValue<Event?>>((ref) {
  final service = ref.read(eventsServiceProvider);
  return EventFormNotifier(service, ref);
});

class EventFormNotifier extends StateNotifier<AsyncValue<Event?>> {
  final EventsService _service;
  final Ref _ref;

  EventFormNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<Event?> createEvent(Event event) async {
    state = const AsyncValue.loading();
    try {
      final createdEvent = await _service.createEvent(event);
      state = AsyncValue.data(createdEvent);
      // Invalidate events list
      _ref.invalidate(eventsProvider);
      return createdEvent;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<Event?> updateEvent(String id, Event event) async {
    state = const AsyncValue.loading();
    try {
      final updatedEvent = await _service.updateEvent(id, event);
      state = AsyncValue.data(updatedEvent);
      _ref.invalidate(eventsProvider);
      _ref.invalidate(eventProvider(id));
      return updatedEvent;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<Event?> closeEvent(String id) async {
    state = const AsyncValue.loading();
    try {
      final closedEvent = await _service.closeEvent(id);
      state = AsyncValue.data(closedEvent);
      _ref.invalidate(eventsProvider);
      _ref.invalidate(eventProvider(id));
      return closedEvent;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<EventPlayer?> addPlayerToEvent(String eventId, String playerId) async {
    try {
      final eventPlayer = await _service.addPlayerToEvent(eventId, playerId);
      _ref.invalidate(eventPlayersProvider(eventId));
      return eventPlayer;
    } catch (e) {
      return null;
    }
  }

  Future<EventPlayer?> updateEventPlayerStatus(
    String eventId,
    String playerId,
    ParticipationStatus status,
  ) async {
    try {
      final updatedPlayer = await _service.updateEventPlayer(
        eventId,
        playerId,
        status: status.value,
      );
      _ref.invalidate(eventPlayersProvider(eventId));
      return updatedPlayer;
    } catch (e) {
      return null;
    }
  }

  Future<bool> removePlayerFromEvent(String eventId, String playerId) async {
    try {
      await _service.removePlayerFromEvent(eventId, playerId);
      _ref.invalidate(eventPlayersProvider(eventId));
      return true;
    } catch (e) {
      return false;
    }
  }
  Future<bool> deleteEvent(String id) async {
    try {
      await _service.deleteEvent(id);
      _ref.invalidate(eventsProvider); // Refresh the list
      return true;
    } catch (e) {
      return false;
    }
  }
}
