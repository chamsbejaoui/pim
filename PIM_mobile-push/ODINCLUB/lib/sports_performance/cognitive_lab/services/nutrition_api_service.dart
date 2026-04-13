import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nutrition_models.dart';

class NutritionApiService {
  static const String _baseUrl = 'http://10.0.2.2:3000/api/sports-performance/nutrition-lab';

  Future<PhysicalProfile?> getPhysicalProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/profile/$userId'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PhysicalProfile(
          userId: json['userId'] ?? userId,
          weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
          heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
          tourTaille: (json['tourTaille'] as num?)?.toDouble() ?? 0,
          tourCou: (json['tourCou'] as num?)?.toDouble() ?? 0,
          dateNaissance: json['dateNaissance'] != null ? DateTime.parse(json['dateNaissance']) : DateTime.now(),
          position: json['position'] ?? 'Unknown',
          graissePercent: (json['graissePercent'] as num?)?.toDouble(),
          masseMuscul: (json['masseMuscul'] as num?)?.toDouble(),
          bmr: (json['bmr'] as num?)?.toInt(),
          eauBase: (json['eauBase'] as num?)?.toDouble(),
        );
      }
    } catch (e) {
      print('Error fetching physical profile: $e');
    }
    return null;
  }

  Future<String?> savePhysicalProfile(PhysicalProfile profile) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/profile/${profile.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // succès
      }
      // Retourne le message d'erreur du serveur
      try {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'];
        if (message is List) return message.join(', ');
        return message?.toString() ?? 'Erreur ${response.statusCode}';
      } catch (_) {
        return 'Erreur ${response.statusCode}';
      }
    } catch (e) {
      return 'Réseau : $e';
    }
  }

  Future<bool> logNutrition(NutritionLog log) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(log.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error logging nutrition: $e');
      return false;
    }
  }

  Future<MetabolicStatus?> getMetabolicStatus(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/metabolic-status/$userId'));
      if (response.statusCode == 200) {
        return MetabolicStatus.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error fetching metabolic status: $e');
    }
    return null;
  }

  Future<WeeklyMealPlan?> getWeeklyMealPlan(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/weekly-plan/$userId'));
      if (response.statusCode == 200) {
        return WeeklyMealPlan.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error fetching weekly meal plan: $e');
    }
    return null;
  }

  Future<WeeklyMealPlan?> generateAiWeeklyPlan(String userId) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/weekly-plan/generate/$userId'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return WeeklyMealPlan.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error generating AI meal plan: $e');
    }
    return null;
  }
}
