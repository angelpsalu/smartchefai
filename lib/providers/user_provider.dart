import 'package:flutter/foundation.dart';
import 'package:smartchefai/models/models.dart';
import 'package:smartchefai/services/api_service.dart';

/// User Provider for profile management
class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  /// Create new user
  Future<void> createUser(String name, String email) async {
    _setLoading(true);
    _setError(null);

    try {
      final userId = await _apiService.createUser({
        'name': name,
        'email': email,
        'dietary_preferences': [],
        'allergies': [],
      });
      _currentUser = User(
        id: userId,
        name: name,
        email: email,
        dietaryPreferences: [],
        allergies: [],
        favoriteRecipes: [],
        searchHistory: [],
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to create user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get user profile
  Future<void> getUser(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      _currentUser = await _apiService.getUser(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update user preferences
  Future<void> setPreferences(List<String> dietaryPrefs, List<String> allergies) async {
    if (_currentUser == null) {
      _setError('No user logged in');
      return;
    }

    try {
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        dietaryPreferences: dietaryPrefs,
        allergies: allergies,
        favoriteRecipes: _currentUser!.favoriteRecipes,
        searchHistory: _currentUser!.searchHistory,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to update preferences: $e');
    }
  }

  /// Logout
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Private helpers
  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String? error) {
    _error = error;
  }
}
