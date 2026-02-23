import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/services/firebase_service.dart';

/// One entry in today's meal log.
class _LoggedMeal {
  final String name;
  final int calories;
  final int protein; // g
  final int carbs;   // g
  final int fat;     // g

  const _LoggedMeal({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory _LoggedMeal.fromJson(Map<String, dynamic> j) => _LoggedMeal(
        name: j['name'] as String? ?? '',
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        protein: (j['protein'] as num?)?.toInt() ?? 0,
        carbs: (j['carbs'] as num?)?.toInt() ?? 0,
        fat: (j['fat'] as num?)?.toInt() ?? 0,
      );
}

/// Manages the user's daily nutrition goals and today's intake log.
class NutritionProvider extends ChangeNotifier {
  final FirebaseService _service;

  NutritionGoals? _goals;
  bool _isLoading = false;
  String? _error;

  List<_LoggedMeal> _todayMeals = [];

  NutritionGoals? get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Today's logged meals as display-friendly list of (name, calories) pairs.
  List<({String name, int calories})> get todayMeals =>
      _todayMeals.map((m) => (name: m.name, calories: m.calories)).toList();

  int get todayCalories => _todayMeals.fold(0, (s, m) => s + m.calories);
  int get todayProtein  => _todayMeals.fold(0, (s, m) => s + m.protein);
  int get todayCarbs    => _todayMeals.fold(0, (s, m) => s + m.carbs);
  int get todayFat      => _todayMeals.fold(0, (s, m) => s + m.fat);

  NutritionProvider({FirebaseService? service})
      : _service = service ?? FirebaseService() {
    loadGoals();
    loadTodayIntake();
  }

  // ── Goals ────────────────────────────────────────────────────────────────

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

  // ── Daily Intake Log ──────────────────────────────────────────────────────

  String get _todayKey {
    final now = DateTime.now();
    return 'nutrition_log_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Load today's meal log from SharedPreferences.
  Future<void> loadTodayIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_todayKey);
    if (raw == null) {
      _todayMeals = [];
    } else {
      final list = jsonDecode(raw) as List<dynamic>;
      _todayMeals = list
          .map((e) => _LoggedMeal.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  /// Parse a gram string like "25g" or "25" into an int. Returns 0 on failure.
  int _parseGrams(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), '').split('.').first) ?? 0;

  /// Log a cooked recipe into today's intake.
  Future<void> logRecipe(Recipe recipe) async {
    final n = recipe.nutrition;
    final meal = _LoggedMeal(
      name: recipe.name,
      calories: n.calories,
      protein: _parseGrams(n.protein),
      carbs: _parseGrams(n.carbs),
      fat: _parseGrams(n.fat),
    );

    _todayMeals = [..._todayMeals, meal];
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _todayKey,
      jsonEncode(_todayMeals.map((m) => m.toJson()).toList()),
    );
  }
}
