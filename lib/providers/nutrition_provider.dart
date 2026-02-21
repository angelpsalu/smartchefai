import 'package:flutter/material.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/services/firebase_service.dart';

/// Manages the user's daily nutrition goals.
class NutritionProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  NutritionGoals? _goals;
  bool _isLoading = false;
  String? _error;

  NutritionGoals? get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NutritionProvider() {
    loadGoals();
  }

  /// Fetch goals from Firestore. Leaves _goals null if none saved yet.
  Future<void> loadGoals() async {
    if (_service.currentUser == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _goals = await _service.getNutritionGoals();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save new goals to Firestore and update local state.
  Future<void> saveGoals({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = _service.currentUser?.uid ?? '';
      final goals = NutritionGoals(
        userId: uid,
        dailyCalories: calories,
        dailyProtein: protein,
        dailyCarbs: carbs,
        dailyFat: fat,
      );
      await _service.saveNutritionGoals(goals);
      _goals = goals;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
