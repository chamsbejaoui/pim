import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/notification_model.dart';

class NotificationsProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (unreadOnly) params['unreadOnly'] = 'true';

      final data = await _api.get('/notifications', queryParams: params.isNotEmpty ? params : null);

      if (data is Map) {
        if (data['notifications'] is List) {
          _notifications = (data['notifications'] as List)
              .map((n) => NotificationModel.fromJson(n))
              .toList();
        }
        _unreadCount = data['unreadCount'] ?? 0;
      } else if (data is List) {
        _notifications = data.map((n) => NotificationModel.fromJson(n)).toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur lors du chargement des notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.patch('/notifications/$id/read');
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
        await fetchNotifications();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.patch('/notifications/read-all');
      _unreadCount = 0;
      await fetchNotifications();
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _api.delete('/notifications/$id');
      _notifications.removeWhere((n) => n.id == id);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (_) {}
  }
}
