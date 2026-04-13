import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../models/medical_history_record_model.dart';
import '../models/medical_result_model.dart';
import 'api_config.dart';

class MedicalService {
  Future<MedicalResultModel> analyze({
    required String playerId,
    required double fatigue,
    required double minutes,
    required double load,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/medical/analyze/$playerId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fatigue': fatigue, 'minutes': minutes, 'load': load}),
    );

    if (kDebugMode) {
      debugPrint('Medical analyze status: ${response.statusCode}');
      debugPrint('Medical analyze response: ${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Medical analysis failed: ${response.statusCode} ${response.body}',
      );
    }

    try {
      if (response.body.trim().isEmpty) {
        throw Exception('Empty response body');
      }

      dynamic decoded = jsonDecode(response.body);
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }

      if (decoded is Map<String, dynamic>) {
        var payload = decoded;
        final data = decoded['data'];
        final result = decoded['result'];
        if (data is Map<String, dynamic>) {
          payload = data;
        } else if (result is Map<String, dynamic>) {
          payload = result;
        }
        return MedicalResultModel.fromJson(payload);
      }
    } catch (error) {
      throw Exception('Medical analysis parse failed: $error');
    }

    throw Exception('Unexpected response format');
  }

  Future<List<MedicalHistoryRecordModel>> fetchHistory({
    required String playerId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/medical/history/$playerId');
    final response = await http.get(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load medical history: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map(
            (item) => MedicalHistoryRecordModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    return const [];
  }
}
