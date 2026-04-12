import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ai_player.dart';
import '../models/ai_prediction.dart';

/// Service to interact with the NestJS Backend (port 3000)
/// which proxies AI requests to the Python FastAPI model (port 8000).
class AiApiService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String _parseError(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (body is Map) {
        return body['detail'] ??
            body['message'] ??
            body['error'] ??
            'Error ${response.statusCode}';
      }
    } catch (_) {}
    return 'Error ${response.statusCode}';
  }

  // ─── Players CRUD ──────────────────────────────────────────

  static Future<List<AiPlayer>> fetchPlayers() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/players'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AiPlayer.fromJson(json)).toList();
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error fetching players: $e');
    }
  }

  static Future<AiPlayer> getPlayer(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/players/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return AiPlayer.fromJson(json.decode(response.body));
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error fetching player: $e');
    }
  }

  static Future<AiPlayer> createPlayer(AiPlayer player) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/players'),
            headers: _headers,
            body: json.encode(player.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return AiPlayer.fromJson(json.decode(response.body));
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error creating player: $e');
    }
  }

  /// Convenience: create a player from a raw map (used by report import, bridge, create form).
  static Future<AiPlayer> createPlayerFromMap(Map<String, dynamic> data) async {
    final player = AiPlayer.fromJson(data);
    return createPlayer(player);
  }

  static Future<AiPlayer> updatePlayer(AiPlayer player) async {
    if (player.id == null) throw Exception('Player ID is required for update');
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/players/${player.id}'),
            headers: _headers,
            body: json.encode(player.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return AiPlayer.fromJson(json.decode(response.body));
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error updating player: $e');
    }
  }

  static Future<void> deletePlayer(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/players/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw HttpException(_parseError(response));
      }
    } catch (e) {
      throw Exception('Error deleting player: $e');
    }
  }

  static Future<int> getPlayerCount() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/players/count'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total'] as int;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ─── AI Prediction ─────────────────────────────────────────

  static Map<String, dynamic> _buildAiPayload(AiPlayer player) {
    // Python AI and PredictPlayerDto require firstName + lastName separately
    final parts = player.name.trim().split(' ');
    final firstName = parts.isNotEmpty ? parts.first : player.name;
    final lastName  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return {
      'firstName': firstName,
      'lastName':  lastName,
      'speed': player.speed,
      'endurance': player.endurance,
      'distance': player.distance,
      'dribbles': player.dribbles,
      'shots': player.shots,
      'injuries': player.injuries,
      'heart_rate': player.heartRate,
      if (player.label != null) 'label': player.label,
      if (player.age != null) 'age': player.age,
      if (player.dateOfBirth != null) 'dateOfBirth': player.dateOfBirth,
      if (player.position != null) 'position': player.position,
    };
  }

  static Future<AiPrediction> predictPlayer(AiPlayer player) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/predict'),
            headers: _headers,
            body: json.encode(_buildAiPayload(player)),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AiPrediction.fromJson(json.decode(response.body));
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error predicting player: $e');
    }
  }

  static Future<Map<String, dynamic>> trainModel(
      List<AiPlayer> players) async {
    try {
      final payload = players.map((p) => _buildAiPayload(p)).toList();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/train'),
            headers: _headers,
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error training model: $e');
    }
  }

  static Future<Map<String, dynamic>> getAiMetrics() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/ai/metrics'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getAiStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/ai/status'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'unknown'};
    } catch (e) {
      return {'status': 'offline'};
    }
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/ai/health'), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ai_service'] == 'online';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ─── AI Insights ───────────────────────────────────────────

  static Future<Map<String, dynamic>> findSimilarPlayers(
      AiPlayer player) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/similar'),
            headers: _headers,
            body: json.encode(_buildAiPayload(player)),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error finding similar players: $e');
    }
  }

  static Future<Map<String, dynamic>> getPlayerPotential(
      AiPlayer player) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/potential'),
            headers: _headers,
            body: json.encode(_buildAiPayload(player)),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error getting potential score: $e');
    }
  }

  static Future<Map<String, dynamic>> getDevelopmentPlan(
      AiPlayer player) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/development-plan'),
            headers: _headers,
            body: json.encode(_buildAiPayload(player)),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error getting development plan: $e');
    }
  }

  // ─── Archive ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> archivePlayers(List<String> ids) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/players/archive'),
            headers: _headers,
            body: json.encode({'ids': ids}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error archiving players: $e');
    }
  }

  static Future<List<AiPlayer>> fetchArchivedPlayers() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/players/archived'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AiPlayer.fromJson(json)).toList();
      }
      throw HttpException(_parseError(response));
    } catch (e) {
      throw Exception('Error fetching archived players: $e');
    }
  }
}
