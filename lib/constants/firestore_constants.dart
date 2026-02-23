/// Firestore collection and document path constants.
/// Use these instead of raw strings to avoid typos and enable easy refactoring.
class FirestoreCollections {
  FirestoreCollections._();

  static const String recipes = 'recipes';
  static const String users = 'users';
  static const String groceryLists = 'grocery_lists';
  static const String mealPlans = 'meal_plans';
  static const String nutritionGoals = 'nutrition_goals';
  static const String health = '_health';
}

class FirestoreFields {
  FirestoreFields._();

  static const String userId = 'userId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

/// UI layout constants
class AppLayout {
  AppLayout._();

  static const double recipeCardAspectRatio = 0.75;
}
