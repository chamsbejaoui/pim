import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/player_model.dart';
import 'api_config.dart';

class PlayerService {
  Future<List<PlayerModel>> fetchPlayers() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/players');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load players');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map((item) => PlayerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map((item) => PlayerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return const [];
  }

  Future<PlayerModel> fetchPlayer(String playerId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/players/$playerId');
    final response = await http.get(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load player');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return PlayerModel.fromJson(decoded);
    }

    throw Exception('Unexpected player response format');
  }

  Future<PlayerModel> clearMedical(String playerId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/players/$playerId/clear-medical',
    );
    final response = await http.post(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to clear medical status: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return PlayerModel.fromJson(decoded);
    }

    throw Exception('Unexpected clear medical response format');
  }
}
