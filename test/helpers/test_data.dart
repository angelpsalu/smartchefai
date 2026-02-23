import 'package:smartchefai/models/models.dart';

/// Shared test fixtures — canonical, minimal data used across all tests.
class TestData {
  TestData._();

  static Nutrition nutrition = const Nutrition(
    calories: 350,
    protein: '25g',
    carbs: '40g',
    fat: '10g',
    fiber: '5g',
  );

  static Recipe recipe = Recipe(
    id: 'r1',
    name: 'Test Pasta',
    ingredients: ['pasta', 'tomato', 'cheese'],
    steps: ['Boil pasta', 'Add sauce', 'Serve'],
    prepTime: 10,
    cookTime: 20,
    difficulty: 'Easy',
    cuisine: 'Italian',
    dietaryTags: ['vegetarian'],
    nutrition: nutrition,
    servings: 2,
    imageUrl: 'https://example.com/pasta.jpg',
    rating: 4.5,
  );

  static Recipe recipe2 = Recipe(
    id: 'r2',
    name: 'Test Salad',
    ingredients: ['lettuce', 'tomato'],
    steps: ['Chop', 'Mix'],
    prepTime: 5,
    cookTime: 0,
    difficulty: 'Easy',
    cuisine: 'American',
    dietaryTags: ['vegan', 'gluten-free'],
    nutrition: const Nutrition(
      calories: 120,
      protein: '3g',
      carbs: '10g',
      fat: '2g',
      fiber: '3g',
    ),
    servings: 1,
    imageUrl: 'https://example.com/salad.jpg',
  );

  static AppUser appUser = AppUser(
    id: 'uid-1',
    name: 'Test User',
    email: 'test@example.com',
    dietaryPreferences: ['vegetarian'],
    allergies: ['nuts'],
    favoriteRecipes: ['r1'],
    searchHistory: [],
    recipesCooked: 5,
    currentStreak: 3,
  );

  static NutritionGoals nutritionGoals = const NutritionGoals(
    userId: 'uid-1',
    dailyCalories: 2000,
    dailyProtein: 50,
    dailyCarbs: 250,
    dailyFat: 70,
  );

  static GroceryItem groceryItem = const GroceryItem(
    name: 'Tomato',
    quantity: 2.0,
    unit: 'pcs',
    category: 'vegetables',
    recipes: ['r1'],
  );
}
