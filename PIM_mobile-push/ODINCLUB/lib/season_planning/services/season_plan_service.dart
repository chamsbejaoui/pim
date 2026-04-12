import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../models/season_plan.dart';

class SeasonPlanService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  static Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<SeasonPlan>> getPlans() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/season-plans'), headers: await _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((j) => SeasonPlan.fromJson(j)).toList();
      }
      throw HttpException('Failed to load plans: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching season plans: $e');
    }
  }

  static Future<SeasonPlan> createPlan(SeasonPlan plan) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/season-plans'),
            headers: await _headers,
            body: json.encode(plan.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 201) {
        return SeasonPlan.fromJson(json.decode(response.body));
      }
      throw HttpException('Failed to create plan: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating season plan: $e');
    }
  }

  static Future<SeasonPlanDashboard> getDashboard(String planId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/season-plans/$planId/dashboard'),
            headers: await _headers,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return SeasonPlanDashboard.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      throw HttpException('Failed to load season dashboard: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching season dashboard: $e');
    }
  }

  static Future<SeasonPlan> updateCollectivePreparation({
    required String planId,
    required CollectivePreparation preparation,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/season-plans/$planId/collective-preparation'),
            headers: await _headers,
            body: json.encode(preparation.toJson()),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SeasonPlan.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }

      throw HttpException(
        'Failed to update collective preparation: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error updating collective preparation: $e');
    }
  }

  static Future<SeasonPlan> addWeeklyCheckin({
    required String planId,
    required WeeklyCollectiveCheckin checkin,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/season-plans/$planId/weekly-checkins'),
            headers: await _headers,
            body: json.encode(checkin.toJson()),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SeasonPlan.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }

      throw HttpException('Failed to add weekly check-in: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error adding weekly check-in: $e');
    }
  }

  /// Demande à l'IA de générer les micro-cycles d'un macro-cycle
  static Future<SeasonPlan> generateWithAi({
    required String planId,
    required String macroId,
    required int weeksCount,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/season-plans/$planId/macro/$macroId/generate'),
            headers: await _headers,
            body: json.encode({'weeksCount': weeksCount}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SeasonPlan.fromJson(json.decode(response.body));
      }
      throw HttpException('AI generation failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error calling AI generate: $e');
    }
  }
}
