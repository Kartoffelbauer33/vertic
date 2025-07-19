import 'dart:ui';

import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// **💡 VERTIC DESIGN SYSTEM - ICONS**
///
/// Definiert ein Set von responsiven Icon-Größen.
/// Die Größen skalieren fließend mit der Bildschirmbreite, um eine
/// konsistente visuelle Hierarchie auf allen Geräten zu gewährleisten.
@immutable
class AppIconTheme extends ThemeExtension<AppIconTheme> {
  // ═══════════════════════════════════════════════════════════════
  // 🎯 ICON SIZES
  // ═══════════════════════════════════════════════════════════════

  /// Kleine Icons, z.B. für Buttons oder dichte UI-Elemente.
  /// Default: 18, Min: 16, Max: 20
  final double small;

  /// Standard-Icon-Größe für die meisten Anwendungsfälle.
  /// Default: 22, Min: 20, Max: 26
  final double medium;

  /// Große Icons, z.B. für Page-Header oder hervorzuhebende Aktionen.
  /// Default: 28, Min: 24, Max: 32
  final double large;

  /// Extra große Icons, für besondere Anwendungsfälle.
  /// Default: 36, Min: 30, Max: 42
  final double extraLarge;

  // ═══════════════════════════════════════════════════════════════
  // 🎯 CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════

  const AppIconTheme._internal({
    required this.small,
    required this.medium,
    required this.large,
    required this.extraLarge,
  });

  // ═══════════════════════════════════════════════════════════════
  // 📱 RESPONSIVE FACTORY
  // ═══════════════════════════════════════════════════════════════

  factory AppIconTheme.main(double screenWidth) {
    return AppIconTheme._internal(
      small: responsiveValue(screenWidth, defaultValue: 18, minValue: 16, maxValue: 20),
      medium: responsiveValue(screenWidth, defaultValue: 22, minValue: 20, maxValue: 26),
      large: responsiveValue(screenWidth, defaultValue: 28, minValue: 24, maxValue: 32),
      extraLarge: responsiveValue(screenWidth, defaultValue: 36, minValue: 30, maxValue: 42),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔄 THEME EXTENSION IMPLEMENTATION
  // ═══════════════════════════════════════════════════════════════

  @override
  AppIconTheme copyWith({
    double? small,
    double? medium,
    double? large,
    double? extraLarge,
  }) {
    return AppIconTheme._internal(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      extraLarge: extraLarge ?? this.extraLarge,
    );
  }

  @override
  AppIconTheme lerp(ThemeExtension<AppIconTheme>? other, double t) {
    if (other is! AppIconTheme) {
      return this;
    }
    return AppIconTheme._internal(
      small: lerpDouble(small, other.small, t)!,
      medium: lerpDouble(medium, other.medium, t)!,
      large: lerpDouble(large, other.large, t)!,
      extraLarge: lerpDouble(extraLarge, other.extraLarge, t)!,
    );
  }
}
