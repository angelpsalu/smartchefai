import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartchefai/constants/firestore_constants.dart';
import 'package:smartchefai/models/models.dart';

/// Firebase Service - Direct Firestore integration
/// Replaces Python backend with serverless Firebase
/// 
/// Features:
/// - Singleton pattern for consistent state
/// - Offline-first caching strategy
/// - Automatic retry with exponential backoff
/// - TheMealDB API fallback for recipe data
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // TheMealDB API for recipe data (FREE backup source)
  static const String _mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const double _minVisionConfidence = 0.65;
  late final Dio _dio;

  // Local cache with expiration
  List<Recipe> _cachedRecipes = [];
  DateTime? _cacheTimestamp;
  static const Duration _cacheExpiration = Duration(minutes: 30);
  bool _initialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );
    
    // Add retry interceptor for network resilience
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            try {
              final response = await _retryRequest(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
    
    // Enable Firestore offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    _initialized = true;
  }
  
  /// Check if error should be retried
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError;
  }
  
  /// Retry request with exponential backoff
  Future<Response> _retryRequest(RequestOptions options, [int retryCount = 0]) async {
    const maxRetries = 3;
    if (retryCount >= maxRetries) {
      throw DioException(requestOptions: options);
    }
    
    await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
    return _dio.fetch(options);
  }
  
  /// Check if cache is valid
  bool get _isCacheValid {
    if (_cachedRecipes.isEmpty || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheExpiration;
  }

  // ==================== AI IMAGE ANALYSIS ====================

  // Google Cloud Vision REST API key.
  // DO NOT hard-code this value. Pass it at build time:
  //   flutter run --dart-define=VISION_API_KEY=your_key_here
  //   flutter build apk --dart-define=VISION_API_KEY=your_key_here
  // Store the key in a local file (e.g. dart_defines/dev.json) that is gitignored.
  static const String _visionApiKey =
      String.fromEnvironment('VISION_API_KEY');

  static const String _visionApiBaseUrl =
      'https://vision.googleapis.com/v1/images:annotate';

  // Allowlist approach: only labels whose lowercase description contains one of
  // these food-related keywords are kept. Everything else is dropped.
  static const Set<String> _foodKeywords = {
    // Generic food categories
    'food', 'vegetable', 'fruit', 'ingredient', 'produce', 'grocery',
    'cuisine', 'dish', 'meal', 'recipe', 'cooking', 'spice', 'herb',
    'meat', 'fish', 'seafood', 'dairy', 'grain', 'nut', 'legume',
    'staple food', 'whole food', 'superfood', 'natural food',
    // Vegetables
    'tomato', 'carrot', 'broccoli', 'onion', 'garlic', 'pepper',
    'cucumber', 'celery', 'spinach', 'lettuce', 'cabbage', 'cauliflower',
    'potato', 'corn', 'pea', 'zucchini', 'eggplant', 'asparagus',
    'kale', 'radish', 'beet', 'mushroom', 'artichoke', 'leek',
    'scallion', 'shallot', 'fennel', 'pumpkin', 'squash', 'bok choy',
    'arugula', 'watercress', 'endive', 'chili', 'jalapeño', 'ginger',
    // Fruits
    'apple', 'banana', 'orange', 'lemon', 'lime', 'strawberry',
    'blueberry', 'raspberry', 'grape', 'watermelon', 'mango',
    'pineapple', 'avocado', 'peach', 'pear', 'cherry', 'plum',
    'kiwi', 'papaya', 'coconut', 'pomegranate', 'fig', 'apricot',
    'grapefruit', 'melon', 'berry', 'citrus',
    // Proteins
    'chicken', 'beef', 'pork', 'lamb', 'turkey', 'duck', 'salmon',
    'tuna', 'shrimp', 'crab', 'lobster', 'egg', 'tofu', 'tempeh',
    'sausage', 'bacon', 'ham', 'poultry', 'prawn',
    // Dairy
    'cheese', 'milk', 'butter', 'cream', 'yogurt', 'mozzarella',
    'cheddar', 'parmesan', 'feta', 'ricotta',
    // Grains & Starches
    'rice', 'pasta', 'bread', 'noodle', 'flour', 'oat', 'wheat',
    'barley', 'quinoa', 'couscous', 'tortilla', 'cereal',
    // Herbs & Spices
    'basil', 'oregano', 'cilantro', 'parsley', 'mint', 'thyme',
    'rosemary', 'sage', 'dill', 'turmeric', 'cumin', 'paprika',
    'cinnamon', 'coriander', 'cardamom', 'clove', 'nutmeg',
    // Legumes & Nuts
    'bean', 'lentil', 'chickpea', 'peanut', 'almond', 'walnut',
    'cashew', 'pecan', 'hazelnut', 'pistachio',
    // Condiments & Others
    'olive', 'oil', 'vinegar', 'sauce', 'soup', 'salad', 'honey',
    'jam', 'chocolate', 'sugar', 'salt', 'stock', 'broth',
  };

  /// Analyze an image for food ingredients using Google Cloud Vision.
  ///
  /// Returns detected ingredients sorted by confidence descending.
  /// Throws on network error or invalid API key.
  Future<List<DetectedIngredient>> analyzeImage(XFile imageFile) async {
    if (_visionApiKey.isEmpty) {
      throw Exception(
        'VISION_API_KEY is not set. '
        'Run with: flutter run --dart-define-from-file=dart_defines/dev.json',
      );
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await _dio.post<Map<String, dynamic>>(
      _visionApiBaseUrl,
      queryParameters: {'key': _visionApiKey},
      data: {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 20}
            ],
          }
        ]
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 30),
        // Allow 4xx through so we can parse Google's error message body
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.data == null) {
      throw Exception('Empty response from Vision API');
    }

    // Surface 4xx errors with the actual Google error message
    if ((response.statusCode ?? 0) >= 400) {
      final body = response.data!;
      final errMsg = ((body['error'] as Map?))?['message'] ?? 'HTTP ${response.statusCode}';
      throw Exception('Vision API error: $errMsg');
    }

    final responses =
        response.data!['responses'] as List<dynamic>? ?? [];
    if (responses.isEmpty) return [];

    final firstResponse = responses.first as Map<String, dynamic>;
    // Vision API returns an error object in the response when the request fails
    // (e.g. quota exceeded, invalid image). Surface it instead of returning [].
    if (firstResponse.containsKey('error')) {
      final err = firstResponse['error'] as Map<String, dynamic>;
      throw Exception('Vision API error: ${err['message'] ?? err}');
    }

    final labels =
        firstResponse['labelAnnotations'] as List<dynamic>? ?? [];

    return _filterLabels(labels);
  }

  List<DetectedIngredient> _filterLabels(List<dynamic> labels) {
    final filtered = labels
        .map((l) => l as Map<String, dynamic>)
        .where((l) => (l['score'] as num? ?? 0).toDouble() >= _minVisionConfidence)
        .where((l) {
          final desc = (l['description'] as String? ?? '').toLowerCase();
          return _foodKeywords.any((keyword) => desc.contains(keyword));
        })
        .map((l) => DetectedIngredient(
              name: l['description'] as String? ?? '',
              confidence: (l['score'] as num).toDouble(),
              bbox: BoundingBox(x1: 0, y1: 0, x2: 0, y2: 0),
            ))
        .toList();
    filtered.sort((a, b) => b.confidence.compareTo(a.confidence));
    return filtered;
  }

  // ==================== AUTHENTICATION ====================

  /// Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;
  
  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Sign in with email/password
  Future<firebase_auth.UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Register with email/password
  Future<firebase_auth.UserCredential> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await credential.user?.updateDisplayName(name);
      
      // Create user profile in Firestore
      await createUserProfile(
        name: name,
        email: email,
      );
      
      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  /// Sign in with Google
  Future<firebase_auth.UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Create user profile if first time
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await createUserProfile(
          name: googleUser.displayName ?? 'User',
          email: googleUser.email,
        );
      }
      
      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  /// Handle Firebase Auth exceptions with user-friendly messages
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      clearCache();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Auth state stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // ==================== RECIPES (Firestore + TheMealDB) ====================

  /// Get all recipes from Firestore + TheMealDB
  /// Uses cache-first strategy with expiration
  Future<List<Recipe>> getAllRecipes({int limit = 100, bool forceRefresh = false}) async {
    // Return valid cache unless force refresh
    if (!forceRefresh && _isCacheValid) {
      return _cachedRecipes.take(limit).toList();
    }

    try {
      // Try Firestore first
      final firestoreRecipes = await _getFirestoreRecipes(limit);
      
      if (firestoreRecipes.isNotEmpty) {
        _cachedRecipes = firestoreRecipes;
        _cacheTimestamp = DateTime.now();
        return _cachedRecipes;
      }
      
      // Fallback to TheMealDB + local JSON
      final localRecipes = await _loadLocalRecipes();
      final mealDbRecipes = await _fetchMealDbRecipes();
      
      _cachedRecipes = [...localRecipes, ...mealDbRecipes];
      _cacheTimestamp = DateTime.now();
      
      // Seed Firestore with recipes for future use (non-blocking)
      if (_cachedRecipes.isNotEmpty) {
        _seedFirestoreRecipes(_cachedRecipes).catchError((e) {
          debugPrint('Failed to seed Firestore: $e');
        });
      }
      
      return _cachedRecipes.take(limit).toList();
    } catch (e) {
      // Ultimate fallback to local
      debugPrint('Error loading recipes: $e');
      _cachedRecipes = await _loadLocalRecipes();
      _cacheTimestamp = DateTime.now();
      return _cachedRecipes.take(limit).toList();
    }
  }

  /// Get recipes from Firestore
  Future<List<Recipe>> _getFirestoreRecipes(int limit) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.recipes)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Recipe.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Seed Firestore with initial recipes
  Future<void> _seedFirestoreRecipes(List<Recipe> recipes) async {
    try {
      final batch = _firestore.batch();
      
      for (final recipe in recipes.take(50)) {
        final docRef = _firestore.collection(FirestoreCollections.recipes).doc(recipe.id);
        batch.set(docRef, recipe.toJson(), SetOptions(merge: true));
      }
      
      await batch.commit();
    } catch (e) {
      // Silent fail - seeding is optional
    }
  }

  /// Load recipes from local JSON file
  Future<List<Recipe>> _loadLocalRecipes() async {
    try {
      final jsonString = await rootBundle.loadString('data/recipes.json');
      final jsonData = json.decode(jsonString);
      final recipes = (jsonData['recipes'] as List?) ?? jsonData;
      return (recipes as List).map((r) => Recipe.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch recipes from TheMealDB API
  Future<List<Recipe>> _fetchMealDbRecipes() async {
    final recipes = <Recipe>[];
    final categories = ['Chicken', 'Beef', 'Vegetarian', 'Seafood', 'Pasta', 'Dessert'];

    for (final category in categories) {
      try {
        final response = await _dio.get(
          '$_mealDbBaseUrl/filter.php',
          queryParameters: {'c': category},
        );

        final meals = response.data['meals'] as List?;
        if (meals != null) {
          for (final meal in meals.take(5)) {
            // Get full recipe details
            try {
              final detailResponse = await _dio.get(
                '$_mealDbBaseUrl/lookup.php',
                queryParameters: {'i': meal['idMeal']},
              );
              final detailMeals = detailResponse.data['meals'] as List?;
              if (detailMeals != null && detailMeals.isNotEmpty) {
                recipes.add(_mealDbDetailToRecipe(detailMeals.first));
              }
            } catch (e) {
              recipes.add(_mealDbToRecipe(meal, category));
            }
          }
        }
      } catch (e) {
        continue;
      }
    }

    return recipes;
  }

  Recipe _mealDbToRecipe(Map<String, dynamic> meal, String category) {
    return Recipe(
      id: meal['idMeal'] ?? '',
      name: meal['strMeal'] ?? '',
      ingredients: [],
      steps: [],
      prepTime: 15,
      cookTime: 30,
      difficulty: 'medium',
      cuisine: category,
      dietaryTags: category == 'Vegetarian' ? ['vegetarian'] : [],
      nutrition: Nutrition(calories: 350, protein: '25g', carbs: '30g', fat: '15g', fiber: '5g'),
      servings: 4,
      imageUrl: meal['strMealThumb'] ?? '',
    );
  }

  Recipe _mealDbDetailToRecipe(Map<String, dynamic> meal) {
    final ingredients = <String>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add('${measure ?? ''} $ingredient'.trim());
      }
    }

    final instructions = meal['strInstructions'] ?? '';
    final steps = instructions.toString()
        .split(RegExp(r'\r?\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Recipe(
      id: meal['idMeal'] ?? '',
      name: meal['strMeal'] ?? '',
      ingredients: ingredients,
      steps: steps,
      prepTime: 15,
      cookTime: 30,
      difficulty: 'medium',
      cuisine: meal['strArea'] ?? 'International',
      dietaryTags: _extractDietaryTags(meal),
      nutrition: Nutrition(calories: 350, protein: '25g', carbs: '30g', fat: '15g', fiber: '5g'),
      servings: 4,
      imageUrl: meal['strMealThumb'] ?? '',
    );
  }

  List<String> _extractDietaryTags(Map<String, dynamic> meal) {
    final tags = <String>[];
    final category = meal['strCategory']?.toString().toLowerCase() ?? '';
    if (category.contains('vegetarian')) tags.add('vegetarian');
    if (category.contains('vegan')) tags.add('vegan');
    if (category.contains('seafood')) tags.add('seafood');
    return tags;
  }

  /// Get single recipe by ID
  Future<Recipe?> getRecipe(String recipeId) async {
    // Check cache first
    final cached = _cachedRecipes.where((r) => r.id == recipeId).firstOrNull;
    if (cached != null) return cached;

    // Try Firestore
    try {
      final doc = await _firestore.collection(FirestoreCollections.recipes).doc(recipeId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Recipe.fromJson(data);
      }
    } catch (e) {
      // Continue to TheMealDB
    }

    // Try TheMealDB lookup
    try {
      final response = await _dio.get(
        '$_mealDbBaseUrl/lookup.php',
        queryParameters: {'i': recipeId},
      );
      final meals = response.data['meals'] as List?;
      if (meals != null && meals.isNotEmpty) {
        return _mealDbDetailToRecipe(meals.first);
      }
    } catch (e) {
      // Recipe not found
    }

    return null;
  }

  /// Search recipes
  Future<List<Recipe>> searchRecipes(String query, {int limit = 15}) async {
    final results = <Recipe>[];

    // Search TheMealDB
    try {
      final response = await _dio.get(
        '$_mealDbBaseUrl/search.php',
        queryParameters: {'s': query},
      );
      final meals = response.data['meals'] as List?;
      if (meals != null) {
        for (final meal in meals) {
          results.add(_mealDbDetailToRecipe(meal));
        }
      }
    } catch (e) {
      // Continue with cache search
    }

    // Search local cache
    final queryLower = query.toLowerCase();
    final localMatches = _cachedRecipes.where((r) =>
        r.name.toLowerCase().contains(queryLower) ||
        r.cuisine.toLowerCase().contains(queryLower) ||
        r.ingredients.any((i) => i.toLowerCase().contains(queryLower))).toList();

    for (final recipe in localMatches) {
      if (!results.any((r) => r.id == recipe.id)) {
        results.add(recipe);
      }
    }

    return results.take(limit).toList();
  }

  /// Search recipes by ingredients
  Future<List<Recipe>> searchByIngredients(List<String> ingredients, {int limit = 15}) async {
    final results = <Recipe>[];

    if (ingredients.isNotEmpty) {
      try {
        final response = await _dio.get(
          '$_mealDbBaseUrl/filter.php',
          queryParameters: {'i': ingredients.first},
        );

        final meals = response.data['meals'] as List?;
        if (meals != null) {
          for (final meal in meals.take(limit)) {
            try {
              final detailResponse = await _dio.get(
                '$_mealDbBaseUrl/lookup.php',
                queryParameters: {'i': meal['idMeal']},
              );
              final detailMeals = detailResponse.data['meals'] as List?;
              if (detailMeals != null && detailMeals.isNotEmpty) {
                results.add(_mealDbDetailToRecipe(detailMeals.first));
              }
            } catch (e) {
              results.add(_mealDbToRecipe(meal, 'Mixed'));
            }
          }
        }
      } catch (e) {
        // Continue with cache
      }
    }

    // Search local cache
    if (results.length < limit) {
      final ingredientLower = ingredients.map((i) => i.toLowerCase()).toList();
      final localMatches = _cachedRecipes.where((r) =>
          r.ingredients.any((i) => ingredientLower.any((ing) => i.toLowerCase().contains(ing)))).toList();

      for (final recipe in localMatches) {
        if (!results.any((r) => r.id == recipe.id) && results.length < limit) {
          results.add(recipe);
        }
      }
    }

    return results;
  }

  // ==================== USER PROFILE (Firestore) ====================

  /// Create or update user profile in Firestore
  Future<void> createUserProfile({
    required String name,
    required String email,
    List<String>? dietaryPreferences,
    List<String>? allergies,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection(FirestoreCollections.users).doc(user.uid).set({
      'name': name,
      'email': email,
      'dietary_preferences': dietaryPreferences ?? [],
      'allergies': allergies ?? [],
      'favorite_recipes': [],
      'search_history': [],
      'recipes_cooked': 0,
      'current_streak': 0,
      'last_cooked_date': null,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user profile from Firestore
  Future<AppUser?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection(FirestoreCollections.users).doc(user.uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
    } catch (e) {
      // User profile not found
    }
    return null;
  }

  /// Update user preferences
  Future<void> updatePreferences({
    required List<String> dietaryPreferences,
    required List<String> allergies,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection(FirestoreCollections.users).doc(user.uid).update({
      'dietary_preferences': dietaryPreferences,
      'allergies': allergies,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Increment recipes cooked counter and update streak
  Future<AppUser?> incrementRecipesCooked() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection(FirestoreCollections.users).doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final now = DateTime.now();
    final lastCooked = (data['last_cooked_date'] as Timestamp?)?.toDate();
    int currentStreak = (data['current_streak'] as num?)?.toInt() ?? 0;

    // Streak logic: increment if last cooked yesterday or today, reset if gap > 1 day
    if (lastCooked != null) {
      final daysSinceLast = now.difference(lastCooked).inDays;
      if (daysSinceLast <= 1) {
        // Continue or maintain streak
        if (daysSinceLast == 1) currentStreak++;
        // Same day: keep streak as-is
      } else {
        currentStreak = 1; // Reset streak
      }
    } else {
      currentStreak = 1; // First time cooking
    }

    await _firestore.collection(FirestoreCollections.users).doc(user.uid).update({
      'recipes_cooked': FieldValue.increment(1),
      'current_streak': currentStreak,
      'last_cooked_date': Timestamp.fromDate(now),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return getUserProfile();
  }

  /// Upload user profile photo to Firebase Storage and save URL to Firestore.
  /// Returns the public download URL.
  Future<String> uploadProfilePhoto(XFile imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final bytes = await imageFile.readAsBytes();
    final ref = _storage.ref().child('users/${user.uid}/profile.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final downloadUrl = await ref.getDownloadURL();

    await _firestore.collection(FirestoreCollections.users).doc(user.uid).update({
      'photo_url': downloadUrl,
      'updated_at': FieldValue.serverTimestamp(),
    });

    return downloadUrl;
  }

  /// Remove user profile photo from Firebase Storage and clear the URL in Firestore.
  Future<void> removeProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final ref = _storage.ref().child('users/${user.uid}/profile.jpg');
      await ref.delete();
    } catch (_) {
      // File may not exist — ignore
    }

    await _firestore.collection(FirestoreCollections.users).doc(user.uid).update({
      'photo_url': null,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ==================== FAVORITES (Firestore) ====================

  /// Get user's favorite recipe IDs
  Future<List<String>> getFavoriteIds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final doc = await _firestore.collection(FirestoreCollections.users).doc(user.uid).get();
      if (doc.exists) {
        return List<String>.from(doc.data()?['favorite_recipes'] ?? []);
      }
    } catch (e) {
      // Return empty
    }
    return [];
  }

  /// Add recipe to favorites
  Future<void> addFavorite(String recipeId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection(FirestoreCollections.users).doc(user.uid).update({
      'favorite_recipes': FieldValue.arrayUnion([recipeId]),
    });
  }

  /// Remove recipe from favorites
  Future<void> removeFavorite(String recipeId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection(FirestoreCollections.users).doc(user.uid).update({
      'favorite_recipes': FieldValue.arrayRemove([recipeId]),
    });
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String recipeId) async {
    final favorites = await getFavoriteIds();
    final isFavorite = favorites.contains(recipeId);
    
    if (isFavorite) {
      await removeFavorite(recipeId);
    } else {
      await addFavorite(recipeId);
    }
    
    return !isFavorite;
  }

  // ==================== GROCERY LISTS (Firestore) ====================

  /// Create a new grocery list
  Future<String> createGroceryList({
    required String name,
    required List<GroceryItem> items,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = await _firestore.collection(FirestoreCollections.groceryLists).add({
      'user_id': user.uid,
      'name': name,
      'items': items.map((e) => e.toJson()).toList(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    return docRef.id;
  }

  /// Get user's grocery lists
  Future<List<GroceryList>> getGroceryLists() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.groceryLists)
          .where('user_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GroceryList.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get single grocery list
  Future<GroceryList?> getGroceryList(String listId) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.groceryLists).doc(listId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return GroceryList.fromJson(data);
      }
    } catch (e) {
      // Not found
    }
    return null;
  }

  /// Update grocery list
  Future<void> updateGroceryList(String listId, {
    String? name,
    List<GroceryItem>? items,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (name != null) updates['name'] = name;
    if (items != null) updates['items'] = items.map((e) => e.toJson()).toList();

    await _firestore.collection(FirestoreCollections.groceryLists).doc(listId).update(updates);
  }

  /// Delete grocery list
  Future<void> deleteGroceryList(String listId) async {
    await _firestore.collection(FirestoreCollections.groceryLists).doc(listId).delete();
  }

  /// Toggle grocery item checked status (immutable pattern)
  Future<void> toggleGroceryItem(String listId, String itemName) async {
    final list = await getGroceryList(listId);
    if (list == null) return;

    final items = list.items.map((item) {
      if (item.name == itemName) {
        return item.copyWith(checked: !item.checked);
      }
      return item;
    }).toList();

    await updateGroceryList(listId, items: items);
  }

  // ==================== SEARCH HISTORY (Firestore) ====================

  /// Add search to history
  Future<void> addSearchHistory(String query) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection(FirestoreCollections.users).doc(user.uid).update({
      'search_history': FieldValue.arrayUnion([
        {
          'query': query,
          'timestamp': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }

  /// Get search history
  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final doc = await _firestore.collection(FirestoreCollections.users).doc(user.uid).get();
      if (doc.exists) {
        return List<Map<String, dynamic>>.from(doc.data()?['search_history'] ?? []);
      }
    } catch (e) {
      // Return empty
    }
    return [];
  }

  // ==================== MEAL PLAN (Firestore) ====================

  /// Fetch the current user's meal plan. Returns null if none saved yet.
  Future<MealPlan?> getMealPlan() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection(FirestoreCollections.mealPlans).doc(user.uid).get();
      if (!doc.exists) return null;
      return MealPlan.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('getMealPlan error: $e');
      return null;
    }
  }

  /// Save (overwrite) the user's meal plan to Firestore.
  Future<void> saveMealPlan(MealPlan plan) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection(FirestoreCollections.mealPlans)
        .doc(user.uid)
        .set(plan.toFirestore());
  }

  // ==================== NUTRITION GOALS (Firestore) ====================

  /// Fetch the current user's nutrition goals. Returns null if none saved.
  Future<NutritionGoals?> getNutritionGoals() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc =
          await _firestore.collection(FirestoreCollections.nutritionGoals).doc(user.uid).get();
      if (!doc.exists) return null;
      return NutritionGoals.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('getNutritionGoals error: $e');
      return null;
    }
  }

  /// Save (overwrite) the user's nutrition goals to Firestore.
  Future<void> saveNutritionGoals(NutritionGoals goals) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection(FirestoreCollections.nutritionGoals)
        .doc(user.uid)
        .set(goals.toFirestore());
  }

  // ==================== HEALTH CHECK ====================

  Future<bool> healthCheck() async {
    try {
      // Check Firestore connection
      await _firestore.collection(FirestoreCollections.health).doc('check').get();
      return true;
    } catch (e) {
      // Fallback to TheMealDB check
      try {
        final response = await _dio.get('$_mealDbBaseUrl/random.php');
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    }
  }

  /// Clear local cache
  void clearCache() {
    _cachedRecipes.clear();
  }
}

