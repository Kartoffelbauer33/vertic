import 'package:flutter/material.dart';
import 'foundations/colors.dart';
import 'foundations/typography.dart';
import 'foundations/spacing.dart';
import 'foundations/shadows.dart';
import 'foundations/animations.dart';

/// **🎨 VERTIC DESIGN SYSTEM - HAUPTTHEME**
/// 
/// Zentrale Konfiguration des kompletten Design Systems.
/// Erstellt Material Design 3 konforme Themes mit Vertic Branding.
class VerticTheme {
  
  // Private constructor - nur statische Methoden
  VerticTheme._();
  
  // ═══════════════════════════════════════════════════════════════
  // 🌞 LIGHT THEME
  // ═══════════════════════════════════════════════════════════════
  
  static ThemeData light(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    
    // Foundation Themes erstellen
    final colors = AppColorsTheme.light();
    final typography = AppTypographyTheme.main(screenWidth);
    final spacing = AppSpacingTheme.main(screenWidth);
    final shadows = AppShadowsTheme.light();
    final animations = AppAnimationsTheme.main(reducedMotion: reduceMotion);
    
    // Material Design 3 ColorScheme aus unserem Farbsystem
    final colorScheme = ColorScheme.light(
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      tertiary: colors.tertiary,
      onTertiary: colors.onTertiary,
      tertiaryContainer: colors.tertiaryContainer,
      onTertiaryContainer: colors.onTertiaryContainer,
      error: colors.error,
      onError: colors.onError,
      errorContainer: colors.errorContainer,
      onErrorContainer: colors.onErrorContainer,
      surface: colors.surface,
      onSurface: colors.onSurface,
      surfaceContainerHighest: colors.surfaceVariant,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      shadow: colors.shadow,
      scrim: colors.scrim,
      inverseSurface: colors.inverseSurface,
      onInverseSurface: colors.onInverseSurface,
      inversePrimary: colors.inversePrimary,
    );
    
    // Material Design 3 TextTheme aus unserem Typografie-System
    final textTheme = TextTheme(
      displayLarge: typography.displayLarge,
      displayMedium: typography.displayMedium,
      displaySmall: typography.displaySmall,
      headlineLarge: typography.headlineLarge,
      headlineMedium: typography.headlineMedium,
      headlineSmall: typography.headlineSmall,
      titleLarge: typography.titleLarge,
      titleMedium: typography.titleMedium,
      titleSmall: typography.titleSmall,
      bodyLarge: typography.bodyLarge,
      bodyMedium: typography.bodyMedium,
      bodySmall: typography.bodySmall,
      labelLarge: typography.labelLarge,
      labelMedium: typography.labelMedium,
      labelSmall: typography.labelSmall,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        shadowColor: colors.shadow,
        surfaceTintColor: colors.surfaceVariant,
        titleTextStyle: typography.titleLarge.copyWith(
          color: colors.onSurface,
        ),
        toolbarHeight: spacing.appBarHeight,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: colors.surface,
        shadowColor: colors.shadow,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
        ),
        margin: EdgeInsets.all(spacing.sm),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.surfaceVariant,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: typography.buttonText,
          padding: spacing.buttonPadding,
          minimumSize: Size(0, spacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
          elevation: 1,
          shadowColor: colors.shadow,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: typography.buttonText,
          padding: spacing.buttonPadding,
          minimumSize: Size(0, spacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
          side: BorderSide(color: colors.outline),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: typography.buttonText,
          padding: spacing.buttonPadding,
          minimumSize: Size(0, spacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: Colors.transparent,
        contentPadding: spacing.inputPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        labelStyle: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        hintStyle: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        errorStyle: typography.bodySmall.copyWith(color: colors.error),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surfaceVariant,
        elevation: 3,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusLg),
        ),
        titleTextStyle: typography.headlineSmall.copyWith(
          color: colors.onSurface,
        ),
        contentTextStyle: typography.bodyMedium.copyWith(
          color: colors.onSurface,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 3,
        selectedLabelStyle: typography.labelSmall,
        unselectedLabelStyle: typography.labelSmall,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        disabledColor: colors.surfaceVariant.withValues(alpha: 0.5),
        selectedColor: colors.primaryContainer,
        secondarySelectedColor: colors.secondaryContainer,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        labelStyle: typography.labelMedium,
        secondaryLabelStyle: typography.labelMedium,
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSm),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: spacing.md,
      ),
      
      // Custom Extensions hinzufügen
      extensions: [
        colors,
        typography,
        spacing,
        shadows,
        animations,
      ],
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🌙 DARK THEME
  // ═══════════════════════════════════════════════════════════════
  
  static ThemeData dark(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    
    // Foundation Themes erstellen
    final colors = AppColorsTheme.dark();
    final typography = AppTypographyTheme.main(screenWidth);
    final spacing = AppSpacingTheme.main(screenWidth);
    final shadows = AppShadowsTheme.dark();
    final animations = AppAnimationsTheme.main(reducedMotion: reduceMotion);
    
    // Material Design 3 ColorScheme aus unserem Farbsystem
    final colorScheme = ColorScheme.dark(
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      tertiary: colors.tertiary,
      onTertiary: colors.onTertiary,
      tertiaryContainer: colors.tertiaryContainer,
      onTertiaryContainer: colors.onTertiaryContainer,
      error: colors.error,
      onError: colors.onError,
      errorContainer: colors.errorContainer,
      onErrorContainer: colors.onErrorContainer,
      surface: colors.surface,
      onSurface: colors.onSurface,
      surfaceContainerHighest: colors.surfaceVariant,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      shadow: colors.shadow,
      scrim: colors.scrim,
      inverseSurface: colors.inverseSurface,
      onInverseSurface: colors.onInverseSurface,
      inversePrimary: colors.inversePrimary,
    );
    
    // Material Design 3 TextTheme aus unserem Typografie-System
    final textTheme = TextTheme(
      displayLarge: typography.displayLarge,
      displayMedium: typography.displayMedium,
      displaySmall: typography.displaySmall,
      headlineLarge: typography.headlineLarge,
      headlineMedium: typography.headlineMedium,
      headlineSmall: typography.headlineSmall,
      titleLarge: typography.titleLarge,
      titleMedium: typography.titleMedium,
      titleSmall: typography.titleSmall,
      bodyLarge: typography.bodyLarge,
      bodyMedium: typography.bodyMedium,
      bodySmall: typography.bodySmall,
      labelLarge: typography.labelLarge,
      labelMedium: typography.labelMedium,
      labelSmall: typography.labelSmall,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        shadowColor: colors.shadow,
        surfaceTintColor: colors.surfaceVariant,
        titleTextStyle: typography.titleLarge.copyWith(
          color: colors.onSurface,
        ),
        toolbarHeight: spacing.appBarHeight,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: colors.surface,
        shadowColor: colors.shadow,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
        ),
        margin: EdgeInsets.all(spacing.sm),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.surfaceVariant,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: typography.buttonText,
          padding: spacing.buttonPadding,
          minimumSize: Size(0, spacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
          elevation: 1,
          shadowColor: colors.shadow,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: typography.buttonText,
          padding: spacing.buttonPadding,
          minimumSize: Size(0, spacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
          side: BorderSide(color: colors.outline),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: typography.buttonText,
          padding: spacing.buttonPadding,
          minimumSize: Size(0, spacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: Colors.transparent,
        contentPadding: spacing.inputPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        labelStyle: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        hintStyle: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        errorStyle: typography.bodySmall.copyWith(color: colors.error),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surfaceVariant,
        elevation: 3,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusLg),
        ),
        titleTextStyle: typography.headlineSmall.copyWith(
          color: colors.onSurface,
        ),
        contentTextStyle: typography.bodyMedium.copyWith(
          color: colors.onSurface,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 3,
        selectedLabelStyle: typography.labelSmall,
        unselectedLabelStyle: typography.labelSmall,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        disabledColor: colors.surfaceVariant.withValues(alpha: 0.5),
        selectedColor: colors.primaryContainer,
        secondarySelectedColor: colors.secondaryContainer,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        labelStyle: typography.labelMedium,
        secondaryLabelStyle: typography.labelMedium,
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSm),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: spacing.md,
      ),
      
      // Custom Extensions hinzufügen
      extensions: [
        colors,
        typography,
        spacing,
        shadows,
        animations,
      ],
    );
  }
} 