import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/event.dart';

class EventsProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Event> _events = [];
  Event? _selectedEvent;
  Map<String, List<Event>> _calendarEvents = {};
  List<EventParticipant> _participants = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;
  Map<String, List<Event>> get calendarEvents => _calendarEvents;
  List<EventParticipant> get participants => _participants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void selectEvent(Event? e) {
    _selectedEvent = e;
    notifyListeners();
  }

  Future<void> fetchEvents({
    String? eventType,
    String? teamId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (eventType != null) params['eventType'] = eventType;
      if (teamId != null) params['teamId'] = teamId;
      if (status != null) params['status'] = status;

      final data = await _api.get('/events', queryParams: params);

      if (data is Map && data['data'] != null && data['data']['events'] != null) {
        _events = (data['data']['events'] as List)
            .map((e) => Event.fromJson(e))
            .toList();
      } else if (data is Map && data['data'] is List) {
        _events = (data['data'] as List)
            .map((e) => Event.fromJson(e))
            .toList();
      } else if (data is List) {
        _events = data.map((e) => Event.fromJson(e)).toList();
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur lors du chargement des événements';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCalendar(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/events/calendar', queryParams: {
        'startDate': startDate.toIso8601String().split('T').first,
        'endDate': endDate.toIso8601String().split('T').first,
      });

      _calendarEvents = {};
      
      if (data is Map && data['data'] != null && data['data']['calendar'] != null) {
        final calendarMap = data['data']['calendar'] as Map;
        debugPrint('--- FETCHED CALENDAR DATA ---');
        debugPrint('Keys from backend: ${calendarMap.keys.toList()}');
        
        for (var dateKey in calendarMap.keys) {
          final items = calendarMap[dateKey];
          if (items is List) {
            for (var e in items) {
              try {
                final event = Event.fromJson(e);
                final localDate = event.startDate.toLocal();
                final key = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
                if (_calendarEvents[key] == null) _calendarEvents[key] = [];
                _calendarEvents[key]!.add(event);
                debugPrint('Parsed event into key: $key');
              } catch (err) {
                debugPrint('Error parsing event: $err');
              }
            }
          }
        }
      } else if (data is Map && data['calendar'] != null) {
        // Fallback in case ApiService changes
        final calendarMap = data['calendar'] as Map;
        for (var dateKey in calendarMap.keys) {
          final items = calendarMap[dateKey];
          if (items is List) {
            for (var e in items) {
              try {
                final event = Event.fromJson(e);
                final localDate = event.startDate.toLocal();
                final key = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
                if (_calendarEvents[key] == null) _calendarEvents[key] = [];
                _calendarEvents[key]!.add(event);
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {
      // Ignore strict parsing failures, just leave empty calendar.
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchEvent(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/events/$id');
      if (data is Map && data['data'] != null) {
        _selectedEvent = Event.fromJson(data['data']);
      } else {
        _selectedEvent = Event.fromJson(data);
      }
    } catch (e) {
      _error = 'Erreur lors du chargement';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/events', body: eventData);
      await fetchEvents();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur inattendue: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEvent(String id, Map<String, dynamic> eventData) async {
    try {
      await _api.put('/events/$id', body: eventData);
      await fetchEvents();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(String id) async {
    try {
      await _api.delete('/events/$id');
      _events.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchParticipants(String eventId) async {
    try {
      final data = await _api.get('/events/$eventId/participants');
      if (data is Map && data['participants'] is List) {
        _participants = (data['participants'] as List)
            .map((p) => EventParticipant.fromJson(p))
            .toList();
      } else if (data is List) {
        _participants =
            data.map((p) => EventParticipant.fromJson(p)).toList();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateEventStatus(String id, String status) async {
    try {
      await _api.patch('/events/$id/status', body: {'status': status});
      await fetchEvents();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  List<Event> getEventsForDay(DateTime day) {
    final localDate = day.toLocal();
    final key = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
    debugPrint('Seeking events for key: $key - Found: ${_calendarEvents[key]?.length ?? 0}');
    return _calendarEvents[key] ?? [];
  }
}
