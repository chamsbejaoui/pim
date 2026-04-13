import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  // Backend URL from config
  static String get baseUrl => AppConfig.apiBaseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Save token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Remove token (logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // Register user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? position,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      };
      if (position != null && position.isNotEmpty) {
        body['position'] = position;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await saveToken(data['access_token']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Verify email
  Future<Map<String, dynamic>> verifyEmail(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Email verification failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Request failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'newPassword': newPassword}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Password reset failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: await _authHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get pending users (admin only)
  Future<Map<String, dynamic>> getPendingUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/pending'),
        headers: await _authHeaders(),
      );

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final users = data is List
            ? data
            : (data is Map<String, dynamic> ? (data['users'] ?? []) : []);
        return {
          'success': true,
          'data': {'users': users},
        };
      } else {
        return {
          'success': false,
          'message': data is Map<String, dynamic>
              ? (data['message'] ?? 'Failed to get pending users')
              : 'Failed to get pending users',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get all users (admin only)
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: await _authHeaders(),
      );

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final users = data is List
            ? data
            : (data is Map<String, dynamic> ? (data['users'] ?? []) : []);
        return {
          'success': true,
          'data': {'users': users},
        };
      } else {
        return {
          'success': false,
          'message': data is Map<String, dynamic>
              ? (data['message'] ?? 'Failed to get users')
              : 'Failed to get users',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Approve user (admin only)
  Future<Map<String, dynamic>> approveUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/approve'),
        headers: await _authHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to approve user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Reject user (admin only)
  Future<Map<String, dynamic>> rejectUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/reject'),
        headers: await _authHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reject user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Players
  Future<Map<String, dynamic>> getPlayers({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/players?page=$page&limit=$limit'),
        headers: await _authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get players',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getPlayer(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/players/$id'),
        headers: await _authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get player',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> createPlayer(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/players'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to create player',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updatePlayer(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/players/$id'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update player',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deletePlayer(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/players/$id'),
        headers: await _authHeaders(),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete player',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getPlayerAnalyses(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/players/$id/analyses'),
        headers: await _authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get analyses',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getSeasonSquad(String season) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/squad/season/$season'),
        headers: await _authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get season squad',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Coaches
  Future<Map<String, dynamic>> getCoaches({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coaches?page=$page&limit=$limit'),
        headers: await _authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get coaches',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getCoach(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coaches/$id'),
        headers: await _authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get coach',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getFinanceAiInsights({
    List<String> focusCategories = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/finance/ai/insights'),
        headers: await _authHeaders(),
        body: jsonEncode({'focusCategories': focusCategories}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get finance AI insights',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> createCoach(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/coaches'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to create coach',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateCoach(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/coaches/$id'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update coach',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteCoach(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/coaches/$id'),
        headers: await _authHeaders(),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete coach',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Chemistry
  Future<Map<String, dynamic>> rateChemistryPair({
    required String season,
    required String playerAId,
    required String playerBId,
    required double rating,
    String? observedBy,
    String? tacticalZone,
    String? notes,
  }) async {
    try {
      final body = {
        'season': season,
        'playerAId': playerAId,
        'playerBId': playerBId,
        'rating': rating,
        if (observedBy != null && observedBy.isNotEmpty)
          'observedBy': observedBy,
        if (tacticalZone != null && tacticalZone.isNotEmpty)
          'tacticalZone': tacticalZone,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chemistry/rate-pair'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to rate pair',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getChemistryMatrix(String season) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chemistry/matrix/$season'),
        headers: await _authHeaders(),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get chemistry matrix',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getChemistryGraph(String season) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chemistry/graph/$season'),
        headers: await _authHeaders(),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get chemistry graph',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getChemistryBestPairs({
    String? season,
    int limit = 10,
    double threshold = 8,
    bool includeAiInsights = false,
  }) async {
    try {
      final query = <String, String>{
        'limit': '$limit',
        'threshold': '$threshold',
        'includeAiInsights': '$includeAiInsights',
      };
      if (season != null && season.isNotEmpty) {
        query['season'] = season;
      }

      final uri = Uri.parse(
        '$baseUrl/chemistry/best-pairs',
      ).replace(queryParameters: query);
      final response = await http.get(uri, headers: await _authHeaders());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get best pairs',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getChemistryConflicts({
    String? season,
    int limit = 10,
    double threshold = 4.5,
    bool includeAiInsights = false,
  }) async {
    try {
      final query = <String, String>{
        'limit': '$limit',
        'threshold': '$threshold',
        'includeAiInsights': '$includeAiInsights',
      };
      if (season != null && season.isNotEmpty) {
        query['season'] = season;
      }

      final uri = Uri.parse(
        '$baseUrl/chemistry/conflicts',
      ).replace(queryParameters: query);
      final response = await http.get(uri, headers: await _authHeaders());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get chemistry conflicts',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> scoreChemistryLineup({
    required List<String> playerIds,
    String? season,
    bool includeAiInsights = false,
  }) async {
    try {
      final body = {
        'playerIds': playerIds,
        'includeAiInsights': includeAiInsights,
        if (season != null && season.isNotEmpty) 'season': season,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chemistry/score-lineup'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to score lineup chemistry',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> generateChemistryStartingXi({
    String? season,
    String formation = '4-3-3',
    bool includeAiInsights = true,
    List<String>? candidatePlayerIds,
    int? poolLimit,
  }) async {
    try {
      final body = {
        'formation': formation,
        'includeAiInsights': includeAiInsights,
        if (season != null && season.isNotEmpty) 'season': season,
        if (candidatePlayerIds != null && candidatePlayerIds.isNotEmpty)
          'candidatePlayerIds': candidatePlayerIds,
        if (poolLimit != null) 'poolLimit': poolLimit,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chemistry/generate-starting-xi'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to generate chemistry starting XI',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getChemistryPlayerNetwork(
    String playerId, {
    String? season,
    bool includeAiInsights = false,
  }) async {
    try {
      final query = <String, String>{'includeAiInsights': '$includeAiInsights'};
      if (season != null && season.isNotEmpty) {
        query['season'] = season;
      }

      final uri = Uri.parse(
        '$baseUrl/chemistry/player/$playerId/network',
      ).replace(queryParameters: query);
      final response = await http.get(uri, headers: await _authHeaders());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get player chemistry network',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> listPlayerStyleProfiles({
    String? season,
    int limit = 120,
  }) async {
    try {
      final query = <String, String>{'limit': '$limit'};
      if (season != null && season.isNotEmpty) {
        query['season'] = season;
      }

      final uri = Uri.parse(
        '$baseUrl/player-profiles',
      ).replace(queryParameters: query);
      final response = await http.get(uri, headers: await _authHeaders());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to list player style profiles',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> upsertPlayerStyleProfile({
    required String playerId,
    required String season,
    required Map<String, dynamic> style,
    List<String>? preferredStyles,
    String? notes,
    String? updatedBy,
  }) async {
    try {
      final body = {
        'season': season,
        ...style,
        if (preferredStyles != null) 'preferredStyles': preferredStyles,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (updatedBy != null && updatedBy.isNotEmpty) 'updatedBy': updatedBy,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/player-profiles/$playerId'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to save player style profile',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> analyzeChemistryPairProfile({
    required String season,
    required String playerAId,
    required String playerBId,
    bool includeAiInsights = true,
  }) async {
    try {
      final body = {
        'season': season,
        'playerAId': playerAId,
        'playerBId': playerBId,
        'includeAiInsights': includeAiInsights,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chemistry/analyze-pair-profile'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message':
            data['message'] ?? 'Failed to analyze pair profile chemistry',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> analyzeSquadChemistryProfile({
    required String season,
    List<String>? formations,
    bool includeAiInsights = true,
  }) async {
    try {
      final body = {
        'season': season,
        'includeAiInsights': includeAiInsights,
        if (formations != null && formations.isNotEmpty) 'formations': formations,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chemistry/analyze-squad-profile'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to analyze squad chemistry',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> setChemistryManualScore({
    required String season,
    required String playerAId,
    required String playerBId,
    required double manualScore,
    String? manualScoreBy,
    String? manualScoreReason,
  }) async {
    try {
      final body = {
        'season': season,
        'playerAId': playerAId,
        'playerBId': playerBId,
        'manualScore': manualScore,
        if (manualScoreBy != null && manualScoreBy.isNotEmpty)
          'manualScoreBy': manualScoreBy,
        if (manualScoreReason != null && manualScoreReason.isNotEmpty)
          'manualScoreReason': manualScoreReason,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chemistry/set-manual-score'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to set manual chemistry score',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
