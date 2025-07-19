import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// **📝 VERTIC DESIGN SYSTEM - TYPOGRAFIE**
/// 
/// Material Design 3 basiertes Typografie-System mit:
/// - Responsive Schriftgrößen
/// - Vollständige Typografie-Hierarchie
/// - Optimiert für verschiedene Bildschirmgrößen
/// - Accessibility-konforme Lesbarkeit
class AppTypographyTheme extends ThemeExtension<AppTypographyTheme> {
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 DISPLAY STYLES (Große Überschriften)
  // ═══════════════════════════════════════════════════════════════
  
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 HEADLINE STYLES (Überschriften)
  // ═══════════════════════════════════════════════════════════════
  
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 TITLE STYLES (Titel)
  // ═══════════════════════════════════════════════════════════════
  
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 BODY STYLES (Fließtext)
  // ═══════════════════════════════════════════════════════════════
  
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 LABEL STYLES (Labels & Buttons)
  // ═══════════════════════════════════════════════════════════════
  
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 CUSTOM VERTIC STYLES
  // ═══════════════════════════════════════════════════════════════
  
  final TextStyle buttonText;
  final TextStyle captionText;
  final TextStyle overlineText;
  final TextStyle codeText;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════
  
  const AppTypographyTheme._internal({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
    required this.buttonText,
    required this.captionText,
    required this.overlineText,
    required this.codeText,
  });
  
  // ═══════════════════════════════════════════════════════════════
  // 📱 RESPONSIVE FACTORY (basierend auf Bildschirmbreite)
  // ═══════════════════════════════════════════════════════════════
  
  factory AppTypographyTheme.main(double screenWidth) {
    // Helper für die Erstellung von responsiven TextStyles
    TextStyle createStyle({
      required double defaultSize,
      required double minSize,
      double? maxSize,
      FontWeight weight = FontWeight.w400,
      double letterSpacing = 0,
      double height = 1.2,
      String family = 'Roboto',
    }) {
      return TextStyle(
        fontFamily: family,
        fontSize: responsiveValue(
          screenWidth,
          defaultValue: defaultSize,
          minValue: minSize,
          maxValue: maxSize,
        ),
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
      );
    }

    return AppTypographyTheme._internal(
      // Display Styles
      displayLarge: createStyle(defaultSize: 57, minSize: 48, weight: FontWeight.w400, letterSpacing: -0.25, height: 1.12),
      displayMedium: createStyle(defaultSize: 45, minSize: 38, weight: FontWeight.w400, height: 1.15),
      displaySmall: createStyle(defaultSize: 36, minSize: 30, weight: FontWeight.w400, height: 1.22),
      
      // Headline Styles
      headlineLarge: createStyle(defaultSize: 32, minSize: 28, weight: FontWeight.w400, height: 1.25),
      headlineMedium: createStyle(defaultSize: 28, minSize: 24, weight: FontWeight.w400, height: 1.28),
      headlineSmall: createStyle(defaultSize: 24, minSize: 21, weight: FontWeight.w400, height: 1.33),
      
      // Title Styles
      titleLarge: createStyle(defaultSize: 22, minSize: 19, weight: FontWeight.w500, letterSpacing: 0.15, height: 1.27),
      titleMedium: createStyle(defaultSize: 16, minSize: 15, weight: FontWeight.w500, letterSpacing: 0.15, height: 1.5),
      titleSmall: createStyle(defaultSize: 14, minSize: 13, weight: FontWeight.w500, letterSpacing: 0.1, height: 1.42),
      
      // Body Styles
      bodyLarge: createStyle(defaultSize: 16, minSize: 15, letterSpacing: 0.5, height: 1.5),
      bodyMedium: createStyle(defaultSize: 14, minSize: 13, letterSpacing: 0.25, height: 1.42),
      bodySmall: createStyle(defaultSize: 12, minSize: 11, letterSpacing: 0.4, height: 1.33),
      
      // Label Styles
      labelLarge: createStyle(defaultSize: 14, minSize: 13, weight: FontWeight.w500, letterSpacing: 0.1, height: 1.42),
      labelMedium: createStyle(defaultSize: 12, minSize: 11, weight: FontWeight.w500, letterSpacing: 0.5, height: 1.33),
      labelSmall: createStyle(defaultSize: 11, minSize: 10, weight: FontWeight.w500, letterSpacing: 0.5, height: 1.45),

      // Custom Vertic Styles
      buttonText: createStyle(defaultSize: 14, minSize: 13, weight: FontWeight.w500, letterSpacing: 0.1, height: 1.42),
      captionText: createStyle(defaultSize: 12, minSize: 11, letterSpacing: 0.4, height: 1.33),
      overlineText: createStyle(defaultSize: 10, minSize: 9, letterSpacing: 1.5, height: 1.6),
      codeText: createStyle(defaultSize: 13, minSize: 12, family: 'Fira Code', height: 1.5),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🔄 THEME EXTENSION IMPLEMENTATION
  // ═══════════════════════════════════════════════════════════════
  
  @override
  ThemeExtension<AppTypographyTheme> copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
    TextStyle? buttonText,
    TextStyle? captionText,
    TextStyle? overlineText,
    TextStyle? codeText,
  }) {
    return AppTypographyTheme._internal(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
      buttonText: buttonText ?? this.buttonText,
      captionText: captionText ?? this.captionText,
      overlineText: overlineText ?? this.overlineText,
      codeText: codeText ?? this.codeText,
    );
  }
  
  @override
  ThemeExtension<AppTypographyTheme> lerp(
    covariant ThemeExtension<AppTypographyTheme>? other,
    double t,
  ) {
    if (other is! AppTypographyTheme) return this;
    
    return AppTypographyTheme._internal(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t)!,
      displaySmall: TextStyle.lerp(displaySmall, other.displaySmall, t)!,
      headlineLarge: TextStyle.lerp(headlineLarge, other.headlineLarge, t)!,
      headlineMedium: TextStyle.lerp(headlineMedium, other.headlineMedium, t)!,
      headlineSmall: TextStyle.lerp(headlineSmall, other.headlineSmall, t)!,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t)!,
      titleMedium: TextStyle.lerp(titleMedium, other.titleMedium, t)!,
      titleSmall: TextStyle.lerp(titleSmall, other.titleSmall, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t)!,
      labelMedium: TextStyle.lerp(labelMedium, other.labelMedium, t)!,
      labelSmall: TextStyle.lerp(labelSmall, other.labelSmall, t)!,
      buttonText: TextStyle.lerp(buttonText, other.buttonText, t)!,
      captionText: TextStyle.lerp(captionText, other.captionText, t)!,
      overlineText: TextStyle.lerp(overlineText, other.overlineText, t)!,
      codeText: TextStyle.lerp(codeText, other.codeText, t)!,
    );
  }
} 