import 'package:flutter/material.dart';

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
    // Responsive Skalierungsfaktor basierend auf Bildschirmbreite
    final double scale = _getScaleFactor(screenWidth);
    
    return AppTypographyTheme._internal(
      // Display Styles
      displayLarge: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 57.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 45.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 36.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.22,
      ),
      
      // Headline Styles
      headlineLarge: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 32.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 28.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 24.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.33,
      ),
      
      // Title Styles
      titleLarge: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 22.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16.0 * scale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14.0 * scale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      
      // Body Styles
      bodyLarge: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 12.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      
      // Label Styles
      labelLarge: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14.0 * scale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 12.0 * scale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 11.0 * scale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
      ),
      
      // Custom Vertic Styles
      buttonText: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14.0 * scale,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      captionText: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 12.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      overlineText: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 10.0 * scale,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        height: 1.6,
      ),
      codeText: TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 14.0 * scale,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.43,
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 📐 RESPONSIVE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════
  
  /// Berechnet den Skalierungsfaktor basierend auf der Bildschirmbreite
  static double _getScaleFactor(double screenWidth) {
    if (screenWidth < 600) {
      // Small screens (Smartphones)
      return 0.9;
    } else if (screenWidth < 840) {
      // Medium screens (Tablets)
      return 1.0;
    } else {
      // Large screens (Desktop)
      return 1.1;
    }
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