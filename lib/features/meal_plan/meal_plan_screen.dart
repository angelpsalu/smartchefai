import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Redirects to the Planner tab (index 2) where the full meal plan UI lives.
class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate to planner tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/planner');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
