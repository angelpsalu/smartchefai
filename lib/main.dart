import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme/theme.dart';
import 'app/routes.dart';
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Check if onboarding is completed
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(SmartChefApp(showOnboarding: !onboardingComplete));
}

class SmartChefApp extends StatelessWidget {
  final bool showOnboarding;

  const SmartChefApp({
    super.key,
    this.showOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = UserProvider();
            // Load theme preference on startup
            provider.loadThemePreference();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => GroceryListProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return MaterialApp.router(
            title: 'SmartChef AI',
            debugShowCheckedModeBanner: false,
            
            // Theme Configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: userProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // Router Configuration
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
