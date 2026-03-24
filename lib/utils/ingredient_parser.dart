import 'food_keywords.dart';

/// Utility to parse spoken text into individual ingredient names.
///
/// Handles multiple input patterns:
/// - Comma-separated: "chicken, rice, tomatoes"
/// - "and" keyword: "chicken and rice and tomatoes"
/// - Mixed: "chicken, rice and tomatoes"
/// - Space-separated: "chicken rice tomatoes"
/// - Natural language: "I have chicken rice tomatoes"
///
/// Non-food words are filtered out. Compound ingredients like "olive oil"
/// are kept together.
class IngredientParser {
  /// Parse spoken text into a list of ingredient names.
  static List<String> parse(String spokenText) {
    if (spokenText.trim().isEmpty) return [];

    // Normalize the text
    String normalized = spokenText.toLowerCase().trim();

    // Remove common filler phrases
    const fillerPhrases = [
      'i would like',
      "i'd like",
      'i want to make',
      'make something with',
      'cook something with',
      'find recipes with',
      'find recipes for',
      'recipes using',
      'recipes for',
      'can you find',
      'search for',
      'let me see',
      'what about',
      'how about',
      'cook with',
      'i have',
      'i got',
      'i need',
      'i want',
      'using',
      'with',
    ];

    for (final phrase in fillerPhrases) {
      normalized = normalized.replaceAll(phrase, '');
    }

    // Replace "and" with commas for consistent splitting
    normalized = normalized.replaceAll(' and ', ',');

    // Split by commas
    final parts = normalized.split(',');

    // For each part, do smart space-based splitting
    final ingredients = <String>[];
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      ingredients.addAll(_smartSplit(trimmed));
    }

    // Filter to food keywords only, excluding generic categories
    final filtered = ingredients
        .where((i) => _isFoodWord(i.toLowerCase()))
        .where((i) => !kGenericFoodCategories.contains(i.toLowerCase()))
        .where((i) => i.length > 1)
        .map(_capitalizeFirstLetter)
        .toList();

    // Remove duplicates (case-insensitive)
    final seen = <String>{};
    return filtered.where((ingredient) {
      final lower = ingredient.toLowerCase();
      if (seen.contains(lower)) return false;
      seen.add(lower);
      return true;
    }).toList();
  }

  /// Split a multi-word string into individual ingredients,
  /// preserving known compound ingredients (e.g. "olive oil").
  static List<String> _smartSplit(String text) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= 1) return [text];

    // Greedily match compound ingredients (longest match first)
    final results = <String>[];
    int i = 0;
    while (i < words.length) {
      bool matched = false;
      // Try 3-word, then 2-word compounds
      for (int len = 3; len >= 2 && i + len <= words.length; len--) {
        final candidate = words.sublist(i, i + len).join(' ');
        if (kCompoundIngredients.contains(candidate)) {
          results.add(candidate);
          i += len;
          matched = true;
          break;
        }
      }
      if (!matched) {
        results.add(words[i]);
        i++;
      }
    }
    return results;
  }

  /// Check if a word (or compound) is a recognized food keyword.
  /// Uses substring matching to handle plurals (e.g. "tomatoes" matches "tomato").
  static bool _isFoodWord(String word) {
    if (kFoodKeywords.contains(word)) return true;
    return kFoodKeywords.any(
      (keyword) => word.contains(keyword) || keyword.contains(word),
    );
  }

  /// Capitalize the first letter of a string.
  static String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Add a new ingredient to an existing list (with duplicate check).
  static List<String> addIngredient(
    List<String> currentIngredients,
    String newIngredient,
  ) {
    final normalized = newIngredient.trim();
    if (normalized.isEmpty) return currentIngredients;

    // Check for case-insensitive duplicates
    final lowerCaseIngredients =
        currentIngredients.map((i) => i.toLowerCase()).toList();

    if (lowerCaseIngredients.contains(normalized.toLowerCase())) {
      return currentIngredients; // Already exists
    }

    return [...currentIngredients, _capitalizeFirstLetter(normalized)];
  }
}
