/// Centralized app constants — avoids scattered hardcoded strings.
library;

/// SharedPreferences key names.
abstract final class PrefKeys {
  static const String favoriteIds = 'favorite_ids';
  static const String onboardingComplete = 'onboarding_complete';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String selectedLanguage = 'selected_language';
  static const String darkMode = 'dark_mode';
  static const String activeGroceryListId = 'active_grocery_list_id';
  static const String groceryItems = 'grocery_items';
}

/// External URLs used in the app.
abstract final class AppUrls {
  static const String helpAndFaq = 'https://smartchefai.web.app/help';
  static const String feedbackEmail =
      'mailto:feedback@smartchef.ai?subject=SmartChef%20AI%20Feedback';
  static const String playStore =
      'https://play.google.com/store/apps/details?id=com.example.smartchefai';
  static const String webBase = 'https://smartchefai.web.app';

  static String recipeShareUrl(String recipeId) =>
      '$webBase/recipe/$recipeId';
}

/// App metadata.
abstract final class AppMeta {
  static const String appName = 'SmartChef AI';
  static const String version = '1.0.0';
  static const String defaultInitials = 'U';
  static const String defaultLanguage = 'English';
  static const List<String> supportedLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
  ];
}
