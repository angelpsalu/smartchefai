/// Data models for SmartChef AI
///
/// All models follow immutable patterns with copyWith methods
/// for efficient state management.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Recipe model representing a cooking recipe
class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
  final List<String> steps;
  final int prepTime;
  final int cookTime;
  final String difficulty;
  final String cuisine;
  final List<String> dietaryTags;
  final Nutrition nutrition;
  final int servings;
  final String imageUrl;
  final double? similarityScore;
  final double? rating;

  // Aliases for compatibility
  List<String> get instructions => steps;

  const Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.steps,
    required this.prepTime,
    required this.cookTime,
    required this.difficulty,
    required this.cuisine,
    required this.dietaryTags,
    required this.nutrition,
    required this.servings,
    required this.imageUrl,
    this.similarityScore,
    this.rating,
  });
  
  /// Create a copy with modified fields
  Recipe copyWith({
    String? id,
    String? name,
    List<String>? ingredients,
    List<String>? steps,
    int? prepTime,
    int? cookTime,
    String? difficulty,
    String? cuisine,
    List<String>? dietaryTags,
    Nutrition? nutrition,
    int? servings,
    String? imageUrl,
    double? similarityScore,
    double? rating,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      difficulty: difficulty ?? this.difficulty,
      cuisine: cuisine ?? this.cuisine,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      nutrition: nutrition ?? this.nutrition,
      servings: servings ?? this.servings,
      imageUrl: imageUrl ?? this.imageUrl,
      similarityScore: similarityScore ?? this.similarityScore,
      rating: rating ?? this.rating,
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? json['idMeal']?.toString() ?? '',
      name: json['name'] ?? json['strMeal'] ?? '',
      ingredients: _parseIngredients(json),
      steps: _parseSteps(json),
      prepTime: _parseTime(json['prep_time'] ?? json['prepTime'] ?? 15),
      cookTime: _parseTime(json['cook_time'] ?? json['cookTime'] ?? 30),
      difficulty: json['difficulty'] ?? 'Medium',
      cuisine: json['cuisine'] ?? json['strArea'] ?? '',
      dietaryTags: List<String>.from(json['dietary_tags'] ?? json['strTags']?.split(',') ?? []),
      nutrition: Nutrition.fromJson(json['nutrition'] ?? {}),
      servings: json['servings'] ?? 4,
      imageUrl: json['image_url'] ?? json['strMealThumb'] ?? '',
      similarityScore: (json['similarity_score'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
    );
  }

  /// Parse a time value that may be int or String (e.g. "15 mins") to int minutes.
  static int _parseTime(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return 0;
  }

  static List<String> _parseIngredients(Map<String, dynamic> json) {
    if (json['ingredients'] != null) {
      return List<String>.from(json['ingredients']);
    }
    // Parse TheMealDB format
    final ingredients = <String>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        final measureStr = measure?.toString().trim() ?? '';
        ingredients.add(measureStr.isNotEmpty ? '$measureStr $ingredient' : ingredient);
      }
    }
    return ingredients;
  }

  static List<String> _parseSteps(Map<String, dynamic> json) {
    if (json['steps'] != null) {
      return List<String>.from(json['steps']);
    }
    // Parse TheMealDB format
    final instructions = json['strInstructions'] as String?;
    if (instructions != null && instructions.isNotEmpty) {
      return instructions
          .split(RegExp(r'\r?\n'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ingredients': ingredients,
    'steps': steps,
    'prep_time': prepTime,
    'cook_time': cookTime,

    'difficulty': difficulty,
    'cuisine': cuisine,
    'dietary_tags': dietaryTags,
    'nutrition': nutrition.toJson(),
    'servings': servings,
    'image_url': imageUrl,
    'rating': rating,
  };
}

/// Nutrition information for a recipe
class Nutrition {
  final int calories;
  final String protein;
  final String carbs;
  final String fat;
  final String fiber;

  const Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });
  
  /// Create a copy with modified fields
  Nutrition copyWith({
    int? calories,
    String? protein,
    String? carbs,
    String? fat,
    String? fiber,
  }) {
    return Nutrition(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
    );
  }

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: json['calories'] is int ? json['calories'] : int.tryParse(json['calories'].toString()) ?? 0,
      protein: json['protein']?.toString() ?? '0g',
      carbs: json['carbs']?.toString() ?? '0g',
      fat: json['fat']?.toString() ?? '0g',
      fiber: json['fiber']?.toString() ?? '0g',
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
  };
}

/// Search history entry
class SearchHistory {
  final String query;
  final DateTime timestamp;

  const SearchHistory({required this.query, required this.timestamp});

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      query: json['query'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now(),
    );
  }
}

/// Grocery list model
class GroceryList {
  final String id;
  final String userId;
  final String name;
  final List<GroceryItem> items;
  final Map<String, List<GroceryItem>> byCategory;
  final int totalItems;
  final List<String> recipes;
  final DateTime createdAt;
  final String status;

  const GroceryList({
    required this.id,
    required this.userId,
    this.name = '',
    required this.items,
    required this.byCategory,
    required this.totalItems,
    required this.recipes,
    required this.createdAt,
    required this.status,
  });
  
  /// Create a copy with modified fields
  GroceryList copyWith({
    String? id,
    String? userId,
    String? name,
    List<GroceryItem>? items,
    Map<String, List<GroceryItem>>? byCategory,
    int? totalItems,
    List<String>? recipes,
    DateTime? createdAt,
    String? status,
  }) {
    return GroceryList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      items: items ?? this.items,
      byCategory: byCategory ?? this.byCategory,
      totalItems: totalItems ?? this.totalItems,
      recipes: recipes ?? this.recipes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  factory GroceryList.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?)?.map((e) => GroceryItem.fromJson(e)).toList() ?? [];
    final byCategory = <String, List<GroceryItem>>{};
    for (var item in itemsList) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

    return GroceryList(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      items: itemsList,
      byCategory: byCategory,
      totalItems: json['total_items'] ?? itemsList.length,
      recipes: List<String>.from(json['recipes'] ?? []),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'items': items.map((e) => e.toJson()).toList(),
    'total_items': totalItems,
    'recipes': recipes,
    'status': status,
  };
}

/// Grocery item in a list
class GroceryItem {
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final bool checked;
  final List<String> recipes;

  const GroceryItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.checked = false,
    required this.recipes,
  });
  
  /// Create a copy with modified fields (immutable toggle)
  GroceryItem copyWith({
    String? name,
    double? quantity,
    String? unit,
    String? category,
    bool? checked,
    List<String>? recipes,
  }) {
    return GroceryItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      checked: checked ?? this.checked,
      recipes: recipes ?? this.recipes,
    );
  }

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? '',
      category: json['category'] ?? 'other',
      checked: json['checked'] ?? false,
      recipes: List<String>.from(json['recipes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'category': category,
    'checked': checked,
    'recipes': recipes,
  };
}

/// Detected ingredient from image analysis
class DetectedIngredient {
  final String name;
  final double confidence;
  final BoundingBox bbox;

  DetectedIngredient({
    required this.name,
    required this.confidence,
    required this.bbox,
  });

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    return DetectedIngredient(
      name: json['name'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      bbox: BoundingBox.fromJson(json['bbox'] ?? {}),
    );
  }
}

class BoundingBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  BoundingBox({required this.x1, required this.y1, required this.x2, required this.y2});

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x1: (json['x1'] as num?)?.toDouble() ?? 0.0,
      y1: (json['y1'] as num?)?.toDouble() ?? 0.0,
      x2: (json['x2'] as num?)?.toDouble() ?? 0.0,
      y2: (json['y2'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// AppUser model for Firestore
class AppUser {
  final String id;
  final String name;
  final String email;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final List<String> favoriteRecipes;
  final List<Map<String, dynamic>> searchHistory;
  final DateTime? createdAt;
  final int recipesCooked;
  final int currentStreak;
  final DateTime? lastCookedDate;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.dietaryPreferences,
    required this.allergies,
    required this.favoriteRecipes,
    required this.searchHistory,
    this.createdAt,
    this.recipesCooked = 0,
    this.currentStreak = 0,
    this.lastCookedDate,
    this.photoUrl,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    List<String>? favoriteRecipes,
    List<Map<String, dynamic>>? searchHistory,
    DateTime? createdAt,
    int? recipesCooked,
    int? currentStreak,
    DateTime? lastCookedDate,
    String? photoUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      allergies: allergies ?? this.allergies,
      favoriteRecipes: favoriteRecipes ?? this.favoriteRecipes,
      searchHistory: searchHistory ?? this.searchHistory,
      createdAt: createdAt ?? this.createdAt,
      recipesCooked: recipesCooked ?? this.recipesCooked,
      currentStreak: currentStreak ?? this.currentStreak,
      lastCookedDate: lastCookedDate ?? this.lastCookedDate,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      dietaryPreferences: List<String>.from(data['dietary_preferences'] ?? []),
      allergies: List<String>.from(data['allergies'] ?? []),
      favoriteRecipes: List<String>.from(data['favorite_recipes'] ?? []),
      searchHistory: List<Map<String, dynamic>>.from(data['search_history'] ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      recipesCooked: (data['recipes_cooked'] as num?)?.toInt() ?? 0,
      currentStreak: (data['current_streak'] as num?)?.toInt() ?? 0,
      lastCookedDate: (data['last_cooked_date'] as Timestamp?)?.toDate(),
      photoUrl: data['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'dietary_preferences': dietaryPreferences,
    'allergies': allergies,
    'favorite_recipes': favoriteRecipes,
    'search_history': searchHistory,
    'recipes_cooked': recipesCooked,
    'current_streak': currentStreak,
    'last_cooked_date': lastCookedDate != null
        ? Timestamp.fromDate(lastCookedDate!)
        : null,
    'photo_url': photoUrl,
  };
}

/// Meal plan for a single week, stored as one Firestore doc per user
class MealPlan {
  final String userId;
  /// Keys: 'monday'…'sunday'. Values: Map of slot → recipeId
  /// e.g. {'monday': {'breakfast': 'local-001', 'lunch': null, ...}}
  final Map<String, Map<String, String?>> days;
  final DateTime weekStart;
  final DateTime updatedAt;

  static const List<String> dayNames = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

  static const List<String> mealSlots = [
    'breakfast', 'lunch', 'dinner', 'snack',
  ];

  const MealPlan({
    required this.userId,
    required this.days,
    required this.weekStart,
    required this.updatedAt,
  });

  MealPlan copyWith({
    String? userId,
    Map<String, Map<String, String?>>? days,
    DateTime? weekStart,
    DateTime? updatedAt,
  }) {
    return MealPlan(
      userId: userId ?? this.userId,
      days: days ?? this.days,
      weekStart: weekStart ?? this.weekStart,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MealPlan.empty(String userId) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return MealPlan(
      userId: userId,
      days: {
        for (final d in dayNames)
          d: {for (final s in mealSlots) s: null},
      },
      weekStart: DateTime(monday.year, monday.month, monday.day),
      updatedAt: now,
    );
  }

  factory MealPlan.fromFirestore(Map<String, dynamic> data) {
    final rawDays = data['days'] as Map<String, dynamic>? ?? {};
    final days = <String, Map<String, String?>>{};

    for (final d in dayNames) {
      final dayData = rawDays[d];
      if (dayData is Map) {
        // New multi-slot format
        days[d] = {
          for (final s in mealSlots)
            s: (dayData[s] as String?),
        };
      } else if (dayData is String) {
        // Legacy single-recipe format → migrate to dinner slot
        days[d] = {
          for (final s in mealSlots)
            s: s == 'dinner' ? dayData : null,
        };
      } else {
        days[d] = {for (final s in mealSlots) s: null};
      }
    }

    return MealPlan(
      userId: data['user_id'] as String? ?? '',
      days: days,
      weekStart: (data['week_start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'user_id': userId,
    'days': {
      for (final entry in days.entries)
        entry.key: {
          for (final slot in entry.value.entries)
            if (slot.value != null) slot.key: slot.value,
        },
    },
    'week_start': Timestamp.fromDate(weekStart),
    'updated_at': FieldValue.serverTimestamp(),
  };
}

/// User's daily nutrition targets
class NutritionGoals {
  final String userId;
  final int dailyCalories;
  final int dailyProtein; // grams
  final int dailyCarbs;   // grams
  final int dailyFat;     // grams

  const NutritionGoals({
    required this.userId,
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyCarbs,
    required this.dailyFat,
  });

  NutritionGoals copyWith({
    String? userId,
    int? dailyCalories,
    int? dailyProtein,
    int? dailyCarbs,
    int? dailyFat,
  }) {
    return NutritionGoals(
      userId: userId ?? this.userId,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      dailyFat: dailyFat ?? this.dailyFat,
    );
  }

  factory NutritionGoals.defaults(String userId) => NutritionGoals(
    userId: userId,
    dailyCalories: 2000,
    dailyProtein: 50,
    dailyCarbs: 250,
    dailyFat: 70,
  );

  factory NutritionGoals.fromFirestore(Map<String, dynamic> data) {
    final userId = data['user_id'] as String? ?? '';
    final d = NutritionGoals.defaults(userId);
    return NutritionGoals(
      userId: userId,
      dailyCalories: (data['daily_calories'] as num?)?.toInt() ?? d.dailyCalories,
      dailyProtein: (data['daily_protein'] as num?)?.toInt() ?? d.dailyProtein,
      dailyCarbs: (data['daily_carbs'] as num?)?.toInt() ?? d.dailyCarbs,
      dailyFat: (data['daily_fat'] as num?)?.toInt() ?? d.dailyFat,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'user_id': userId,
    'daily_calories': dailyCalories,
    'daily_protein': dailyProtein,
    'daily_carbs': dailyCarbs,
    'daily_fat': dailyFat,
    'updated_at': FieldValue.serverTimestamp(),
  };
}
