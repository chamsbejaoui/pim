import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/player_model.dart';
import '../models/simulation_result_model.dart';
import '../models/simulation_start_model.dart';
import 'api_config.dart';

class SimulationService {
  Future<List<PlayerModel>> fetchAvailablePlayers() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/simulation/available-players');
    final response = await http.get(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Available players failed: ${response.statusCode} ${response.body}',
      );
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

  Future<SimulationStartModel> startMatch({List<String>? playerIds}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/simulation/start');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: playerIds == null ? null : jsonEncode({'playerIds': playerIds}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Simulation start failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return SimulationStartModel.fromJson(decoded);
    }

    throw Exception('Simulation start returned invalid payload');
  }

  Future<List<SimulationResultModel>> endMatch(
    String matchId, {
    Map<String, dynamic>? stats,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/simulation/end/$matchId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: stats == null ? null : jsonEncode({'stats': stats}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Simulation end failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map(
            (item) =>
                SimulationResultModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map(
            (item) =>
                SimulationResultModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return const [];
  }
}
