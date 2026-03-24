/// Utility to parse spoken text into individual ingredient names.
///
/// Handles multiple input patterns:
/// - Comma-separated: "chicken, rice, tomatoes"
/// - "and" keyword: "chicken and rice and tomatoes"
/// - Mixed: "chicken, rice and tomatoes"
/// - Natural language: "I have chicken rice tomatoes"
///
/// Example:
/// ```dart
/// final ingredients = parseIngredients("chicken, tomatoes and onions");
/// // Returns: ["chicken", "tomatoes", "onions"]
/// ```
class IngredientParser {
  /// Parse spoken text into a list of ingredient names.
  static List<String> parse(String spokenText) {
    if (spokenText.trim().isEmpty) return [];

    // Normalize the text
    String normalized = spokenText.toLowerCase().trim();

    // Remove common filler phrases
    final fillerPhrases = [
      'i have',
      'i got',
      'i need',
      'i want',
      'can you find',
      'find recipes with',
      'find recipes for',
      'search for',
      'using',
      'with',
    ];

    for (final phrase in fillerPhrases) {
      normalized = normalized.replaceAll(phrase, '');
    }

    // Replace "and" with commas for consistent splitting
    normalized = normalized.replaceAll(' and ', ',');

    // Split by commas
    List<String> parts = normalized.split(',');

    // Clean up each part
    List<String> ingredients = parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => part.length > 1) // Filter out single characters
        .map((part) => _capitalizeFirstLetter(part))
        .toList();

    // Remove duplicates (case-insensitive)
    final seen = <String>{};
    ingredients = ingredients.where((ingredient) {
      final lower = ingredient.toLowerCase();
      if (seen.contains(lower)) return false;
      seen.add(lower);
      return true;
    }).toList();

    return ingredients;
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
