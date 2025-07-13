import 'package:flutter/material.dart';

/// **📏 VERTIC DESIGN SYSTEM - ABSTÄNDE & DIMENSIONEN**
/// 
/// Responsive Spacing-System mit:
/// - Konsistente Abstände für alle Komponenten
/// - Responsive Anpassung an Bildschirmgrößen
/// - Material Design 3 konforme Werte
/// - Semantische Naming-Konventionen
class AppSpacingTheme extends ThemeExtension<AppSpacingTheme> {
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 BASIC SPACING VALUES
  // ═══════════════════════════════════════════════════════════════
  
  final double xs;      // 4dp
  final double sm;      // 8dp
  final double md;      // 16dp
  final double lg;      // 24dp
  final double xl;      // 32dp
  final double xxl;     // 48dp
  final double xxxl;    // 64dp
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 SEMANTIC SPACING
  // ═══════════════════════════════════════════════════════════════
  
  final EdgeInsets pagePadding;
  final EdgeInsets cardPadding;
  final EdgeInsets buttonPadding;
  final EdgeInsets inputPadding;
  final EdgeInsets dialogPadding;
  final EdgeInsets listItemPadding;
  final EdgeInsets sectionPadding;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════
  
  final double radiusXs;     // 4dp
  final double radiusSm;     // 8dp
  final double radiusMd;     // 12dp
  final double radiusLg;     // 16dp
  final double radiusXl;     // 24dp
  final double radiusRound;  // 999dp (vollständig rund)
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 COMPONENT DIMENSIONS
  // ═══════════════════════════════════════════════════════════════
  
  final double buttonHeight;
  final double buttonHeightSmall;
  final double buttonHeightLarge;
  final double inputHeight;
  final double appBarHeight;
  final double bottomNavHeight;
  final double listItemHeight;
  final double cardMinHeight;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 ICON SIZES
  // ═══════════════════════════════════════════════════════════════
  
  final double iconXs;      // 16dp
  final double iconSm;      // 20dp
  final double iconMd;      // 24dp
  final double iconLg;      // 32dp
  final double iconXl;      // 48dp
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════
  
  const AppSpacingTheme._internal({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
    required this.pagePadding,
    required this.cardPadding,
    required this.buttonPadding,
    required this.inputPadding,
    required this.dialogPadding,
    required this.listItemPadding,
    required this.sectionPadding,
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusRound,
    required this.buttonHeight,
    required this.buttonHeightSmall,
    required this.buttonHeightLarge,
    required this.inputHeight,
    required this.appBarHeight,
    required this.bottomNavHeight,
    required this.listItemHeight,
    required this.cardMinHeight,
    required this.iconXs,
    required this.iconSm,
    required this.iconMd,
    required this.iconLg,
    required this.iconXl,
  });
  
  // ═══════════════════════════════════════════════════════════════
  // 📱 RESPONSIVE FACTORY (basierend auf Bildschirmbreite)
  // ═══════════════════════════════════════════════════════════════
  
  factory AppSpacingTheme.main(double screenWidth) {
    // Responsive Skalierungsfaktor
    final double scale = _getScaleFactor(screenWidth);
    final bool isCompact = screenWidth < 600;
    
    return AppSpacingTheme._internal(
      // Basic spacing values
      xs: 4.0 * scale,
      sm: 8.0 * scale,
      md: 16.0 * scale,
      lg: 24.0 * scale,
      xl: 32.0 * scale,
      xxl: 48.0 * scale,
      xxxl: 64.0 * scale,
      
      // Semantic spacing
      pagePadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16.0 * scale : 24.0 * scale,
        vertical: isCompact ? 16.0 * scale : 20.0 * scale,
      ),
      cardPadding: EdgeInsets.all(isCompact ? 16.0 * scale : 20.0 * scale),
      buttonPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16.0 * scale : 24.0 * scale,
        vertical: isCompact ? 12.0 * scale : 16.0 * scale,
      ),
      inputPadding: EdgeInsets.symmetric(
        horizontal: 16.0 * scale,
        vertical: 12.0 * scale,
      ),
      dialogPadding: EdgeInsets.all(24.0 * scale),
      listItemPadding: EdgeInsets.symmetric(
        horizontal: 16.0 * scale,
        vertical: 12.0 * scale,
      ),
      sectionPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16.0 * scale : 24.0 * scale,
        vertical: 24.0 * scale,
      ),
      
      // Border radius
      radiusXs: 4.0,
      radiusSm: 8.0,
      radiusMd: 12.0,
      radiusLg: 16.0,
      radiusXl: 24.0,
      radiusRound: 999.0,
      
      // Component dimensions
      buttonHeight: isCompact ? 48.0 : 52.0,
      buttonHeightSmall: isCompact ? 36.0 : 40.0,
      buttonHeightLarge: isCompact ? 56.0 : 64.0,
      inputHeight: isCompact ? 48.0 : 52.0,
      appBarHeight: isCompact ? 56.0 : 64.0,
      bottomNavHeight: isCompact ? 60.0 : 72.0,
      listItemHeight: isCompact ? 56.0 : 64.0,
      cardMinHeight: isCompact ? 120.0 : 140.0,
      
      // Icon sizes
      iconXs: 16.0,
      iconSm: 20.0,
      iconMd: 24.0,
      iconLg: 32.0,
      iconXl: 48.0,
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 📐 HELPER METHODS
  // ═══════════════════════════════════════════════════════════════
  
  /// Berechnet den Skalierungsfaktor basierend auf der Bildschirmbreite
  static double _getScaleFactor(double screenWidth) {
    if (screenWidth < 600) {
      return 1.0;  // Baseline für Smartphones
    } else if (screenWidth < 840) {
      return 1.1;  // Etwas größer für Tablets
    } else {
      return 1.2;  // Größer für Desktop
    }
  }
  
  /// Erstellt einen SizedBox mit der angegebenen Höhe
  SizedBox verticalSpace(double multiplier) => SizedBox(height: md * multiplier);
  
  /// Erstellt einen SizedBox mit der angegebenen Breite
  SizedBox horizontalSpace(double multiplier) => SizedBox(width: md * multiplier);
  
  /// Erstellt Padding mit symmetrischen Werten
  EdgeInsets symmetric({double? horizontal, double? vertical}) {
    return EdgeInsets.symmetric(
      horizontal: (horizontal ?? 1) * md,
      vertical: (vertical ?? 1) * md,
    );
  }
  
  /// Erstellt Padding nur für bestimmte Seiten
  EdgeInsets only({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: (left ?? 0) * md,
      top: (top ?? 0) * md,
      right: (right ?? 0) * md,
      bottom: (bottom ?? 0) * md,
    );
  }
  
  /// Erstellt gleichmäßiges Padding
  EdgeInsets all(double multiplier) => EdgeInsets.all(md * multiplier);
  
  /// Erstellt einen BorderRadius mit dem angegebenen Radius
  BorderRadius borderRadius(double radius) => BorderRadius.circular(radius);
  
  // ═══════════════════════════════════════════════════════════════
  // 🔄 THEME EXTENSION IMPLEMENTATION
  // ═══════════════════════════════════════════════════════════════
  
  @override
  ThemeExtension<AppSpacingTheme> copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
    EdgeInsets? pagePadding,
    EdgeInsets? cardPadding,
    EdgeInsets? buttonPadding,
    EdgeInsets? inputPadding,
    EdgeInsets? dialogPadding,
    EdgeInsets? listItemPadding,
    EdgeInsets? sectionPadding,
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radiusRound,
    double? buttonHeight,
    double? buttonHeightSmall,
    double? buttonHeightLarge,
    double? inputHeight,
    double? appBarHeight,
    double? bottomNavHeight,
    double? listItemHeight,
    double? cardMinHeight,
    double? iconXs,
    double? iconSm,
    double? iconMd,
    double? iconLg,
    double? iconXl,
  }) {
    return AppSpacingTheme._internal(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
      pagePadding: pagePadding ?? this.pagePadding,
      cardPadding: cardPadding ?? this.cardPadding,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      inputPadding: inputPadding ?? this.inputPadding,
      dialogPadding: dialogPadding ?? this.dialogPadding,
      listItemPadding: listItemPadding ?? this.listItemPadding,
      sectionPadding: sectionPadding ?? this.sectionPadding,
      radiusXs: radiusXs ?? this.radiusXs,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radiusRound: radiusRound ?? this.radiusRound,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      buttonHeightSmall: buttonHeightSmall ?? this.buttonHeightSmall,
      buttonHeightLarge: buttonHeightLarge ?? this.buttonHeightLarge,
      inputHeight: inputHeight ?? this.inputHeight,
      appBarHeight: appBarHeight ?? this.appBarHeight,
      bottomNavHeight: bottomNavHeight ?? this.bottomNavHeight,
      listItemHeight: listItemHeight ?? this.listItemHeight,
      cardMinHeight: cardMinHeight ?? this.cardMinHeight,
      iconXs: iconXs ?? this.iconXs,
      iconSm: iconSm ?? this.iconSm,
      iconMd: iconMd ?? this.iconMd,
      iconLg: iconLg ?? this.iconLg,
      iconXl: iconXl ?? this.iconXl,
    );
  }
  
  @override
  ThemeExtension<AppSpacingTheme> lerp(
    covariant ThemeExtension<AppSpacingTheme>? other,
    double t,
  ) {
    if (other is! AppSpacingTheme) return this;
    
    return AppSpacingTheme._internal(
      xs: (xs * (1 - t) + other.xs * t),
      sm: (sm * (1 - t) + other.sm * t),
      md: (md * (1 - t) + other.md * t),
      lg: (lg * (1 - t) + other.lg * t),
      xl: (xl * (1 - t) + other.xl * t),
      xxl: (xxl * (1 - t) + other.xxl * t),
      xxxl: (xxxl * (1 - t) + other.xxxl * t),
      pagePadding: EdgeInsets.lerp(pagePadding, other.pagePadding, t)!,
      cardPadding: EdgeInsets.lerp(cardPadding, other.cardPadding, t)!,
      buttonPadding: EdgeInsets.lerp(buttonPadding, other.buttonPadding, t)!,
      inputPadding: EdgeInsets.lerp(inputPadding, other.inputPadding, t)!,
      dialogPadding: EdgeInsets.lerp(dialogPadding, other.dialogPadding, t)!,
      listItemPadding: EdgeInsets.lerp(listItemPadding, other.listItemPadding, t)!,
      sectionPadding: EdgeInsets.lerp(sectionPadding, other.sectionPadding, t)!,
      radiusXs: (radiusXs * (1 - t) + other.radiusXs * t),
      radiusSm: (radiusSm * (1 - t) + other.radiusSm * t),
      radiusMd: (radiusMd * (1 - t) + other.radiusMd * t),
      radiusLg: (radiusLg * (1 - t) + other.radiusLg * t),
      radiusXl: (radiusXl * (1 - t) + other.radiusXl * t),
      radiusRound: (radiusRound * (1 - t) + other.radiusRound * t),
      buttonHeight: (buttonHeight * (1 - t) + other.buttonHeight * t),
      buttonHeightSmall: (buttonHeightSmall * (1 - t) + other.buttonHeightSmall * t),
      buttonHeightLarge: (buttonHeightLarge * (1 - t) + other.buttonHeightLarge * t),
      inputHeight: (inputHeight * (1 - t) + other.inputHeight * t),
      appBarHeight: (appBarHeight * (1 - t) + other.appBarHeight * t),
      bottomNavHeight: (bottomNavHeight * (1 - t) + other.bottomNavHeight * t),
      listItemHeight: (listItemHeight * (1 - t) + other.listItemHeight * t),
      cardMinHeight: (cardMinHeight * (1 - t) + other.cardMinHeight * t),
      iconXs: (iconXs * (1 - t) + other.iconXs * t),
      iconSm: (iconSm * (1 - t) + other.iconSm * t),
      iconMd: (iconMd * (1 - t) + other.iconMd * t),
      iconLg: (iconLg * (1 - t) + other.iconLg * t),
      iconXl: (iconXl * (1 - t) + other.iconXl * t),
    );
  }
} 