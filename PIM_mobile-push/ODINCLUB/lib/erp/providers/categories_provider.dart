import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/category.dart';

class CategoriesProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/categories');
      if (data is List) {
        _categories = data.map((c) => Category.fromJson(c)).toList();
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Erreur lors du chargement des catégories';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory(String name, {int? ageMin, int? ageMax}) async {
    try {
      await _api.post('/categories', body: {
        'name': name,
        if (ageMin != null) 'ageMin': ageMin,
        if (ageMax != null) 'ageMax': ageMax,
      });
      await fetchCategories();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _api.delete('/categories/$id');
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
