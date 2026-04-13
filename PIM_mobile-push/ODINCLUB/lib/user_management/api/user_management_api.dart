import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../communication/models/communication_models.dart';
import '../../config/app_config.dart';
import '../models/user_management_models.dart';

class UserManagementApi {
  UserManagementApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    return AppConfig.apiBaseUrl;
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload, {
    String? token,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> payload, {
    required String token,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> _delete(
    String path, {
    required String token,
  }) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _decode(response);
  }

  Future<List<dynamic>> _getList(String path, {String? token}) async {
    final response = await _client.get(
      _buildUri(path),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      return [];
    }

    throw Exception(_extractError(response));
  }

  Future<Map<String, dynamic>> _getObject(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    final response = await _client.get(
      _buildUri(path, query),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    }

    throw Exception(_extractError(response));
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {
      // ignore
    }
    return 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}';
  }

  Future<SessionModel> login(String email, String password) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    final user = (data['user'] as Map<String, dynamic>? ?? <String, dynamic>{});

    return SessionModel(
      token: (data['accessToken'] ?? '').toString(),
      userId: (user['sub'] ?? '').toString(),
      role: (user['role'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      status: (user['status'] ?? '').toString(),
      clubId: user['clubId']?.toString(),
      clubName: user['clubName']?.toString(),
      firstName: user['firstName']?.toString(),
      lastName: user['lastName']?.toString(),
      photoUrl: user['photoUrl']?.toString(),
    );
  }

  Future<void> registerResponsable(Map<String, dynamic> payload) async {
    await _post('/auth/register/responsable', payload);
  }

  Future<void> registerMember(Map<String, dynamic> payload) async {
    await _post('/auth/register/member', payload);
  }

  Future<void> verifyEmail(String email, String code) async {
    await _post('/auth/verify-email', {'email': email, 'code': code});
  }

  Future<void> requestForgotPassword(String email) async {
    await _post('/auth/forgot-password/request', {'email': email});
  }

  Future<void> resetForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _post('/auth/forgot-password/reset', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  Future<List<ClubModel>> getActiveClubs() async {
    final list = await _getList('/clubs/active');
    return list
        .whereType<Map<String, dynamic>>()
        .map(ClubModel.fromJson)
        .toList();
  }

  Future<List<ClubModel>> getPendingClubs(String token) async {
    final list = await _getList('/clubs/pending', token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ClubModel.fromJson)
        .toList();
  }

  Future<void> approveClub(String token, String clubId, bool approve) async {
    await _patch('/clubs/$clubId/approval', {
      'status': approve ? 'ACTIVE' : 'REJECTED',
    }, token: token);
  }

  Future<List<UserModel>> getPendingUsers(String token) async {
    final list = await _getList('/users/pending', token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  Future<void> approveUser(String token, String userId, bool approve) async {
    await _patch('/users/$userId/approval', {
      'status': approve ? 'ACTIVE' : 'REJECTED',
    }, token: token);
  }

  Future<UserModel> updateUser(
    String token,
    String userId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _patch('/users/$userId', payload, token: token);
    return UserModel.fromJson(data);
  }

  Future<void> deleteUser(String token, String userId) async {
    await _delete('/users/$userId', token: token);
  }

  Future<List<UserModel>> getUsers(String token) async {
    final list = await _getList('/users', token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  Future<List<ChatUserModel>> getChatUsers(
    String token, {
    String? search,
  }) async {
    final response = await _client.get(
      _buildUri('/chat/users', {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final decoded = _decodeDynamic(response);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ChatUserModel.fromJson)
        .toList();
  }

  Future<List<ConversationModel>> getConversations(
    String token, {
    String? search,
    int page = 1,
    int limit = 30,
  }) async {
    final data = await _getObject(
      '/chat/conversations',
      token: token,
      query: {
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final items = (data['items'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(ConversationModel.fromJson)
        .toList();
  }

  Future<ConversationModel> createDirectConversation(
    String token,
    String targetUserId,
  ) async {
    final data = await _post('/chat/conversations/direct', {
      'targetUserId': targetUserId,
    }, token: token);
    return ConversationModel.fromJson(data);
  }

  Future<List<ChatMessageModel>> getMessages(
    String token,
    String conversationId, {
    int limit = 40,
    DateTime? before,
  }) async {
    final data = await _getObject(
      '/chat/conversations/$conversationId/messages',
      token: token,
      query: {
        'limit': '$limit',
        if (before != null) 'before': before.toIso8601String(),
      },
    );

    final items = (data['items'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromJson)
        .toList();
  }

  Future<ChatMessageModel> sendChatMessage({
    required String token,
    required String conversationId,
    String? text,
    UploadedDocumentModel? file,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = <String, dynamic>{
      if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
      if (file != null) 'file': file.toJson(),
      if (metadata != null) 'metadata': metadata,
    };
    final data = await _post(
      '/chat/conversations/$conversationId/messages',
      payload,
      token: token,
    );
    return ChatMessageModel.fromJson(data);
  }

  Future<void> deleteChatMessage({
    required String token,
    required String messageId,
    required String scope,
  }) async {
    final response = await _client.delete(
      _buildUri('/chat/messages/$messageId', {'scope': scope}),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _decode(response);
  }

  Future<void> sendAnnouncement({
    required String token,
    required String title,
    required String text,
    List<String>? targetUserIds,
    List<String>? targetRoles,
  }) async {
    await _post('/chat/announcements', {
      'title': title,
      'text': text,
      if (targetUserIds != null && targetUserIds.isNotEmpty)
        'targetUserIds': targetUserIds,
      if (targetRoles != null && targetRoles.isNotEmpty)
        'targetRoles': targetRoles,
    }, token: token);
  }

  Future<List<NotificationModel>> getNotifications(
    String token, {
    bool unreadOnly = false,
    String? type,
    int limit = 80,
  }) async {
    final response = await _client.get(
      _buildUri('/notifications', {
        'unreadOnly': unreadOnly.toString(),
        'limit': '$limit',
        if (type != null && type.isNotEmpty) 'type': type,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final decoded = _decodeDynamic(response);
    if (decoded is! List) {
      return [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  Future<void> markNotificationsRead(
    String token,
    List<String> notificationIds,
  ) async {
    if (notificationIds.isEmpty) {
      return;
    }
    await _post('/notifications/mark-read', {
      'notificationIds': notificationIds,
    }, token: token);
  }

  Future<void> deleteNotification(String token, String notificationId) async {
    await _delete('/notifications/$notificationId', token: token);
  }

  Future<void> createEmergencyNotification({
    required String token,
    required String title,
    required String body,
    String severity = 'HIGH',
    List<String>? targetUserIds,
    List<String>? targetRoles,
  }) async {
    await _post('/notifications/emergency', {
      'title': title,
      'body': body,
      'severity': severity,
      if (targetUserIds != null && targetUserIds.isNotEmpty)
        'targetUserIds': targetUserIds,
      if (targetRoles != null && targetRoles.isNotEmpty)
        'targetRoles': targetRoles,
    }, token: token);
  }

  Future<void> createMedicalAlert({
    required String token,
    required String title,
    required String body,
    required List<String> targetPlayerIds,
    String severity = 'MEDIUM',
    bool includeCoaches = true,
    bool includeResponsables = false,
    bool confidential = true,
  }) async {
    await _post('/notifications/medical-alert', {
      'title': title,
      'body': body,
      'severity': severity,
      'targetPlayerIds': targetPlayerIds,
      'includeCoaches': includeCoaches,
      'includeResponsables': includeResponsables,
      'confidential': confidential,
    }, token: token);
  }

  Future<void> createTrainingReminder({
    required String token,
    required String title,
    required String body,
    required DateTime scheduleAt,
    List<String>? targetUserIds,
    List<String>? targetRoles,
    String? trainingId,
  }) async {
    await _post('/notifications/training-reminder', {
      'title': title,
      'body': body,
      'scheduleAt': scheduleAt.toIso8601String(),
      if (trainingId != null && trainingId.isNotEmpty) 'trainingId': trainingId,
      if (targetUserIds != null && targetUserIds.isNotEmpty)
        'targetUserIds': targetUserIds,
      if (targetRoles != null && targetRoles.isNotEmpty)
        'targetRoles': targetRoles,
    }, token: token);
  }

  Future<UploadedDocumentModel> uploadDocument({
    required String token,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri('/uploads'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final data = _decode(response);
    return UploadedDocumentModel.fromJson(data);
  }

  Stream<Map<String, dynamic>> subscribeSse({
    required String token,
    required String path,
  }) async* {
    final request = http.Request('GET', _buildUri(path));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    });

    final streamed = await _client.send(request);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Failed to open stream on $path');
    }

    await for (final line
        in streamed.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) {
        continue;
      }
      final raw = line.replaceFirst('data:', '').trim();
      if (raw.isEmpty) {
        continue;
      }
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          yield decoded;
        }
      } catch (_) {
        // ignore malformed stream lines
      }
    }
  }

  dynamic _decodeDynamic(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    }
    throw Exception(_extractError(response));
  }
}
