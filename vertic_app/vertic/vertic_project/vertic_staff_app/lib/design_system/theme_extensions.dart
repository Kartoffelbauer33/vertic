import 'package:flutter/material.dart';
import 'foundations/colors.dart';
import 'foundations/typography.dart';
import 'foundations/spacing.dart';
import 'foundations/shadows.dart';
import 'foundations/animations.dart';
import 'foundations/icons.dart';

/// **🎨 VERTIC DESIGN SYSTEM - THEME EXTENSIONS**
/// 
/// Praktische Extensions für einfachen Zugriff auf Design System Themes.
/// Verwendung: Theme.of(context).appColors.primary
extension VerticThemeExtensions on ThemeData {
  
  /// Zugriff auf das Farb-Theme
  AppColorsTheme get appColors {
    final theme = extension<AppColorsTheme>();
    if (theme == null) {
      throw Exception(
        'AppColorsTheme nicht gefunden! '
        'Stelle sicher, dass das Design System korrekt initialisiert wurde.',
      );
    }
    return theme;
  }
  
  /// Zugriff auf das Typografie-Theme
  AppTypographyTheme get appTypography {
    final theme = extension<AppTypographyTheme>();
    if (theme == null) {
      throw Exception(
        'AppTypographyTheme nicht gefunden! '
        'Stelle sicher, dass das Design System korrekt initialisiert wurde.',
      );
    }
    return theme;
  }
  
  /// Zugriff auf das Spacing-Theme
  AppSpacingTheme get appSpacing {
    final theme = extension<AppSpacingTheme>();
    if (theme == null) {
      throw Exception(
        'AppSpacingTheme nicht gefunden! '
        'Stelle sicher, dass das Design System korrekt initialisiert wurde.',
      );
    }
    return theme;
  }
  
  /// Zugriff auf das Schatten-Theme
  AppShadowsTheme get appShadows {
    final theme = extension<AppShadowsTheme>();
    if (theme == null) {
      throw Exception(
        'AppShadowsTheme nicht gefunden! '
        'Stelle sicher, dass das Design System korrekt initialisiert wurde.',
      );
    }
    return theme;
  }
  
  /// Zugriff auf das Animations-Theme
  AppAnimationsTheme get appAnimations {
    final theme = extension<AppAnimationsTheme>();
    if (theme == null) {
      throw Exception(
        'AppAnimationsTheme nicht gefunden! '
        'Stelle sicher, dass das Design System korrekt initialisiert wurde.',
      );
    }
    return theme;
  }

  /// Zugriff auf das Icon-Theme
  AppIconTheme get appIcons {
    final theme = extension<AppIconTheme>();
    if (theme == null) {
      throw Exception(
        'AppIconTheme nicht gefunden! '
        'Stelle sicher, dass das Design System korrekt initialisiert wurde.',
      );
    }
    return theme;
  }

}

/// **📱 CONTEXT EXTENSIONS für noch einfacheren Zugriff**
extension VerticContextExtensions on BuildContext {
  
  /// Direkter Zugriff auf Farben: context.colors.primary
  AppColorsTheme get colors => Theme.of(this).appColors;
  
  /// Direkter Zugriff auf Typografie: context.typography.headlineLarge
  AppTypographyTheme get typography => Theme.of(this).appTypography;
  
  /// Direkter Zugriff auf Spacing: context.spacing.md
  AppSpacingTheme get spacing => Theme.of(this).appSpacing;
  
  /// Direkter Zugriff auf Schatten: context.shadows.cardShadow
  AppShadowsTheme get shadows => Theme.of(this).appShadows;
  
  /// Direkter Zugriff auf Animationen: context.animations.fast
  AppAnimationsTheme get animations => Theme.of(this).appAnimations;

  /// Zugriff auf responsive Icon-Größen
  AppIconTheme get icons => Theme.of(this).appIcons;
  
  /// Bildschirmbreite für responsive Entscheidungen
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Bildschirmhöhe für responsive Entscheidungen
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Ist das Gerät im Landscape-Modus?
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;
  
  /// Ist das Gerät ein kleines Smartphone? (< 600dp)
  bool get isCompact => screenWidth < 600;
  
  /// Ist das Gerät ein Tablet? (600dp - 840dp)
  bool get isMedium => screenWidth >= 600 && screenWidth < 840;
  
  /// Ist das Gerät ein großer Bildschirm? (>= 840dp)
  bool get isExpanded => screenWidth >= 840;
  
  /// Sind reduzierte Animationen aktiviert?
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;
  
  /// Text-Skalierungsfaktor des Systems
  double get textScaleFactor => MediaQuery.of(this).textScaler.scale(1.0);
  
  /// Ist der Dark Mode aktiv?
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Ist der Light Mode aktiv?
  bool get isLightMode => Theme.of(this).brightness == Brightness.light;
} 