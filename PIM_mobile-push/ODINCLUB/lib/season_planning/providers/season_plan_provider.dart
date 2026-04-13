import 'package:flutter/material.dart';
import '../models/season_plan.dart';
import '../services/season_plan_service.dart';

class SeasonPlanProvider extends ChangeNotifier {
  final SeasonPlanService _service = SeasonPlanService();
  List<SeasonPlan> _plans = [];
  bool _isLoading = false;

  List<SeasonPlan> get plans => _plans;
  bool get isLoading => _isLoading;

  Future<void> fetchPlans() async {
    _isLoading = true;
    notifyListeners();
    try {
      _plans = await SeasonPlanService.getPlans();
    } catch (e) {
      print('Error fetching plans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPlan(SeasonPlan plan) async {
    try {
      final newPlan = await SeasonPlanService.createPlan(plan);
      _plans.add(newPlan);
      notifyListeners();
    } catch (e) {
      print('Error creating plan: $e');
      rethrow;
    }
  }
}
