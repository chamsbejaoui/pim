import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'player_value_models.dart';

class PlayerValueApi {
  PlayerValueApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.playerValueAiBaseUrl}$path');

  Future<PlayerValueResponse> predict(PlayerValueRequest request) async {
    final response = await _client.post(
      _uri('/predict-player-value'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Player value AI error: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PlayerValueResponse.fromJson(json);
  }
}
