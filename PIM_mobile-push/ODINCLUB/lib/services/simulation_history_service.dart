import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/simulation_match_history_model.dart';
import 'api_config.dart';

class SimulationHistoryService {
  Future<List<SimulationMatchHistoryItem>> fetchHistory() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/simulation/history');
    final response = await http.get(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load match history: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map(
            (item) => SimulationMatchHistoryItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map(
            (item) => SimulationMatchHistoryItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    return const [];
  }
}
