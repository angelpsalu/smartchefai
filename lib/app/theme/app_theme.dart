import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// SmartChefAI Theme Configuration
/// Material 3 compliant with custom brand styling
class AppTheme {
  AppTheme._();

  // Light Theme
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: AppColors.lightColorScheme,
    textTheme: AppTypography.textTheme,
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: false,
      backgroundColor: AppColors.lightColorScheme.surface,
      foregroundColor: AppColors.lightColorScheme.onSurface,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
        color: AppColors.lightColorScheme.onSurface,
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      color: AppColors.lightColorScheme.surface,
      surfaceTintColor: AppColors.lightColorScheme.surfaceTint,
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    
    // Filled Button Theme
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightColorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(
          color: AppColors.lightColorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(
          color: AppColors.lightColorScheme.error,
          width: 1,
        ),
      ),
      hintStyle: AppTypography.textTheme.bodyLarge?.copyWith(
        color: AppColors.lightColorScheme.onSurfaceVariant,
      ),
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      elevation: 0,
      pressElevation: 2,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      labelStyle: AppTypography.textTheme.labelMedium,
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.lightColorScheme.surface,
      selectedItemColor: AppColors.lightColorScheme.primary,
      unselectedItemColor: AppColors.lightColorScheme.onSurfaceVariant,
      selectedLabelStyle: AppTypography.textTheme.labelSmall,
      unselectedLabelStyle: AppTypography.textTheme.labelSmall,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    
    // Navigation Bar Theme (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 80,
      backgroundColor: AppColors.lightColorScheme.surface,
      indicatorColor: AppColors.lightColorScheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.lightColorScheme.primary,
            fontWeight: FontWeight.w600,
          );
        }
        return AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.lightColorScheme.onSurfaceVariant,
        );
      }),
    ),
    
    // Dialog Theme
    dialogTheme: DialogThemeData(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      titleTextStyle: AppTypography.textTheme.headlineSmall?.copyWith(
        color: AppColors.lightColorScheme.onSurface,
      ),
      contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.lightColorScheme.onSurfaceVariant,
      ),
    ),
    
    // Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      backgroundColor: AppColors.lightColorScheme.surface,
      dragHandleColor: AppColors.lightColorScheme.onSurfaceVariant,
      dragHandleSize: const Size(32, 4),
      showDragHandle: true,
    ),
    
    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      backgroundColor: AppColors.lightColorScheme.inverseSurface,
      contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.lightColorScheme.onInverseSurface,
      ),
    ),
    
    // Divider Theme
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: AppColors.lightColorScheme.outlineVariant,
    ),
    
    // List Tile Theme
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      titleTextStyle: AppTypography.textTheme.bodyLarge,
      subtitleTextStyle: AppTypography.textTheme.bodyMedium,
    ),
    
    // Tab Bar Theme
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.lightColorScheme.primary,
      unselectedLabelColor: AppColors.lightColorScheme.onSurfaceVariant,
      labelStyle: AppTypography.textTheme.titleSmall,
      unselectedLabelStyle: AppTypography.textTheme.titleSmall,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: AppColors.lightColorScheme.primary,
          width: 3,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(3),
        ),
      ),
    ),
    
    // Progress Indicator Theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.lightColorScheme.primary,
      linearTrackColor: AppColors.lightColorScheme.primaryContainer,
      circularTrackColor: AppColors.lightColorScheme.primaryContainer,
    ),
    
    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.lightColorScheme.onPrimary;
        }
        return AppColors.lightColorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.lightColorScheme.primary;
        }
        return AppColors.lightColorScheme.surfaceContainerHighest;
      }),
    ),
  );

  // Dark Theme
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: AppColors.darkColorScheme,
    textTheme: AppTypography.textTheme,
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: false,
      backgroundColor: AppColors.darkColorScheme.surface,
      foregroundColor: AppColors.darkColorScheme.onSurface,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
        color: AppColors.darkColorScheme.onSurface,
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      color: AppColors.darkColorScheme.surface,
      surfaceTintColor: AppColors.darkColorScheme.surfaceTint,
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    
    // Filled Button Theme
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(88, AppSpacing.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkColorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        borderSide: BorderSide(
          color: AppColors.darkColorScheme.primary,
          width: 2,
        ),
      ),
      hintStyle: AppTypography.textTheme.bodyLarge?.copyWith(
        color: AppColors.darkColorScheme.onSurfaceVariant,
      ),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.darkColorScheme.surface,
      selectedItemColor: AppColors.darkColorScheme.primary,
      unselectedItemColor: AppColors.darkColorScheme.onSurfaceVariant,
      selectedLabelStyle: AppTypography.textTheme.labelSmall,
      unselectedLabelStyle: AppTypography.textTheme.labelSmall,
    ),
    
    // Navigation Bar Theme (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 80,
      backgroundColor: AppColors.darkColorScheme.surface,
      indicatorColor: AppColors.darkColorScheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    
    // Dialog Theme
    dialogTheme: DialogThemeData(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusXl,
      ),
      titleTextStyle: AppTypography.textTheme.headlineSmall?.copyWith(
        color: AppColors.darkColorScheme.onSurface,
      ),
      contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.darkColorScheme.onSurfaceVariant,
      ),
    ),
    
    // Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      backgroundColor: AppColors.darkColorScheme.surface,
      dragHandleColor: AppColors.darkColorScheme.onSurfaceVariant,
      dragHandleSize: const Size(32, 4),
      showDragHandle: true,
    ),
    
    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      backgroundColor: AppColors.darkColorScheme.inverseSurface,
      contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.darkColorScheme.onInverseSurface,
      ),
    ),
    
    // Divider Theme
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: AppColors.darkColorScheme.outlineVariant,
    ),
  );
}
