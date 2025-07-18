import 'package:flutter/material.dart';

/// **🎨 VERTIC DESIGN SYSTEM - FARBEN**
/// 
/// Material Design 3 basiertes Farbsystem mit:
/// - Semantische Farbnamen (nicht visuelle)
/// - Vollständige Light/Dark Theme Unterstützung
/// - Accessibility-konforme Kontraste
/// - Vertic Brand Identity Integration
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 PRIMARY BRAND COLORS
  // ═══════════════════════════════════════════════════════════════
  
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 SECONDARY COLORS
  // ═══════════════════════════════════════════════════════════════
  
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 TERTIARY/ACCENT COLORS
  // ═══════════════════════════════════════════════════════════════
  
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 SURFACE COLORS
  // ═══════════════════════════════════════════════════════════════
  
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 BACKGROUND COLORS
  // ═══════════════════════════════════════════════════════════════
  
  final Color background;
  final Color onBackground;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 STATUS COLORS
  // ═══════════════════════════════════════════════════════════════
  
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 OUTLINE & BORDER COLORS
  // ═══════════════════════════════════════════════════════════════
  
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════
  
  const AppColorsTheme._internal({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
  });
  
  // ═══════════════════════════════════════════════════════════════
  // 🌞 LIGHT THEME
  // ═══════════════════════════════════════════════════════════════
  
  factory AppColorsTheme.light() => const AppColorsTheme._internal(
    // Primary - Vertic Teal Brand
    primary: Color(0xFF00897B),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB2DFDB),
    onPrimaryContainer: Color(0xFF004D40),
    
    // Secondary - Complementary Blue
    secondary: Color(0xFF0277BD),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFB3E5FC),
    onSecondaryContainer: Color(0xFF01579B),
    
    // Tertiary - Accent Orange
    tertiary: Color(0xFFFF6F00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFE0B2),
    onTertiaryContainer: Color(0xFFE65100),
    
    // Surface Hierarchy (Light)
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF1C1B1F),
    surfaceVariant: Color(0xFFE7E0EC),
    onSurfaceVariant: Color(0xFF49454F),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F2FA),
    surfaceContainer: Color(0xFFF3EDF7),
    surfaceContainerHigh: Color(0xFFECE6F0),
    surfaceContainerHighest: Color(0xFFE6E0E9),
    
    // Background
    background: Color(0xFFFFFBFF),
    onBackground: Color(0xFF1C1B1F),
    
    // Status Colors
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    
    warning: Color(0xFFFF8F00),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFE0B2),
    onWarningContainer: Color(0xFFE65100),
    
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFC8E6C9),
    onSuccessContainer: Color(0xFF1B5E20),
    
    info: Color(0xFF1976D2),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFBBDEFB),
    onInfoContainer: Color(0xFF0D47A1),
    
    // Outline & Utility
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFF80CBC4),
  );
  
  // ═══════════════════════════════════════════════════════════════
  // 🌙 DARK THEME
  // ═══════════════════════════════════════════════════════════════
  
  factory AppColorsTheme.dark() => const AppColorsTheme._internal(
    // Primary - Vertic Teal Brand (Dark)
    primary: Color(0xFF80CBC4),
    onPrimary: Color(0xFF003D36),
    primaryContainer: Color(0xFF00695C),
    onPrimaryContainer: Color(0xFFB2DFDB),
    
    // Secondary - Complementary Blue (Dark)
    secondary: Color(0xFF81D4FA),
    onSecondary: Color(0xFF003C71),
    secondaryContainer: Color(0xFF0277BD),
    onSecondaryContainer: Color(0xFFB3E5FC),
    
    // Tertiary - Accent Orange (Dark)
    tertiary: Color(0xFFFFB74D),
    onTertiary: Color(0xFF8A4000),
    tertiaryContainer: Color(0xFFFF8F00),
    onTertiaryContainer: Color(0xFFFFE0B2),
    
    // Surface Hierarchy (Dark)
    surface: Color(0xFF10131C),
    onSurface: Color(0xFFE6E0E9),
    surfaceVariant: Color(0xFF49454F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    surfaceContainerLowest: Color(0xFF0F0D13),
    surfaceContainerLow: Color(0xFF1D1B20),
    surfaceContainer: Color(0xFF211F26),
    surfaceContainerHigh: Color(0xFF2B2930),
    surfaceContainerHighest: Color(0xFF36343B),
    
    // Background
    background: Color(0xFF10131C),
    onBackground: Color(0xFFE6E0E9),
    
    // Status Colors (Dark)
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    
    warning: Color(0xFFFFCC02),
    onWarning: Color(0xFF452B00),
    warningContainer: Color(0xFFFF8F00),
    onWarningContainer: Color(0xFFFFE0B2),
    
    success: Color(0xFFA5D6A7),
    onSuccess: Color(0xFF0A5D0E),
    successContainer: Color(0xFF2E7D32),
    onSuccessContainer: Color(0xFFC8E6C9),
    
    info: Color(0xFF90CAF9),
    onInfo: Color(0xFF003258),
    infoContainer: Color(0xFF1976D2),
    onInfoContainer: Color(0xFFBBDEFB),
    
    // Outline & Utility
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE6E0E9),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: Color(0xFF00897B),
  );
  
  // ═══════════════════════════════════════════════════════════════
  // 🔄 THEME EXTENSION IMPLEMENTATION
  // ═══════════════════════════════════════════════════════════════
  
  @override
  ThemeExtension<AppColorsTheme> copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? background,
    Color? onBackground,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? outline,
    Color? outlineVariant,
    Color? shadow,
    Color? scrim,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
  }) {
    return AppColorsTheme._internal(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      surfaceContainerLowest: surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      onInverseSurface: onInverseSurface ?? this.onInverseSurface,
      inversePrimary: inversePrimary ?? this.inversePrimary,
    );
  }
  
  @override
  ThemeExtension<AppColorsTheme> lerp(
    covariant ThemeExtension<AppColorsTheme>? other,
    double t,
  ) {
    if (other is! AppColorsTheme) return this;
    
    return AppColorsTheme._internal(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondaryContainer: Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      onTertiary: Color.lerp(onTertiary, other.onTertiary, t)!,
      tertiaryContainer: Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      onTertiaryContainer: Color.lerp(onTertiaryContainer, other.onTertiaryContainer, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      surfaceContainerLowest: Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t)!,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest: Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      onInverseSurface: Color.lerp(onInverseSurface, other.onInverseSurface, t)!,
      inversePrimary: Color.lerp(inversePrimary, other.inversePrimary, t)!,
    );
  }
} 