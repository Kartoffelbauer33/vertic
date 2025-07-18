import 'package:flutter/material.dart';

/// **🌫️ VERTIC DESIGN SYSTEM - SCHATTEN & ELEVATION**
/// 
/// Material Design 3 basiertes Schatten-System mit:
/// - Konsistente Elevation-Werte
/// - Light/Dark Theme Unterstützung
/// - Performance-optimierte BoxShadows
/// - Semantische Schatten-Definitionen
class AppShadowsTheme extends ThemeExtension<AppShadowsTheme> {
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 ELEVATION SHADOWS
  // ═══════════════════════════════════════════════════════════════
  
  final List<BoxShadow> elevation0;  // Keine Elevation
  final List<BoxShadow> elevation1;  // Leichte Elevation (Buttons)
  final List<BoxShadow> elevation2;  // Mittlere Elevation (Cards)
  final List<BoxShadow> elevation3;  // Höhere Elevation (Dialogs)
  final List<BoxShadow> elevation4;  // Hohe Elevation (Navigation Drawer)
  final List<BoxShadow> elevation5;  // Sehr hohe Elevation (Modal Sheets)
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 SEMANTIC SHADOWS
  // ═══════════════════════════════════════════════════════════════
  
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> buttonShadow;
  final List<BoxShadow> dialogShadow;
  final List<BoxShadow> menuShadow;
  final List<BoxShadow> tooltipShadow;
  final List<BoxShadow> appBarShadow;
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════
  
  const AppShadowsTheme._internal({
    required this.elevation0,
    required this.elevation1,
    required this.elevation2,
    required this.elevation3,
    required this.elevation4,
    required this.elevation5,
    required this.cardShadow,
    required this.buttonShadow,
    required this.dialogShadow,
    required this.menuShadow,
    required this.tooltipShadow,
    required this.appBarShadow,
  });
  
  // ═══════════════════════════════════════════════════════════════
  // 🌞 LIGHT THEME SHADOWS
  // ═══════════════════════════════════════════════════════════════
  
  factory AppShadowsTheme.light() => const AppShadowsTheme._internal(
    elevation0: [],
    
    elevation1: [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 1,
      ),
    ],
    
    elevation2: [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 2,
      ),
    ],
    
    elevation3: [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 4),
        blurRadius: 8,
        spreadRadius: 3,
      ),
    ],
    
    elevation4: [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 2),
        blurRadius: 3,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 6),
        blurRadius: 10,
        spreadRadius: 4,
      ),
    ],
    
    elevation5: [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 4),
        blurRadius: 4,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 8),
        blurRadius: 12,
        spreadRadius: 6,
      ),
    ],
    
    // Semantic shadows (Light)
    cardShadow: [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 2,
      ),
    ],
    
    buttonShadow: [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 1,
      ),
    ],
    
    dialogShadow: [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 4),
        blurRadius: 4,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 8),
        blurRadius: 12,
        spreadRadius: 6,
      ),
    ],
    
    menuShadow: [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 2),
        blurRadius: 3,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 6),
        blurRadius: 10,
        spreadRadius: 4,
      ),
    ],
    
    tooltipShadow: [
      BoxShadow(
        color: Color(0x1F000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 4),
        blurRadius: 8,
        spreadRadius: 3,
      ),
    ],
    
    appBarShadow: [
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 2),
        blurRadius: 4,
        spreadRadius: 0,
      ),
    ],
  );
  
  // ═══════════════════════════════════════════════════════════════
  // 🌙 DARK THEME SHADOWS
  // ═══════════════════════════════════════════════════════════════
  
  factory AppShadowsTheme.dark() => const AppShadowsTheme._internal(
    elevation0: [],
    
    elevation1: [
      BoxShadow(
        color: Color(0x3D000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 1,
      ),
    ],
    
    elevation2: [
      BoxShadow(
        color: Color(0x3D000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 2,
      ),
    ],
    
    elevation3: [
      BoxShadow(
        color: Color(0x3D000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 4),
        blurRadius: 8,
        spreadRadius: 3,
      ),
    ],
    
    elevation4: [
      BoxShadow(
        color: Color(0x3D000000),
        offset: Offset(0, 2),
        blurRadius: 3,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 6),
        blurRadius: 10,
        spreadRadius: 4,
      ),
    ],
    
    elevation5: [
      BoxShadow(
        color: Color(0x3D000000),
        offset: Offset(0, 4),
        blurRadius: 4,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 8),
        blurRadius: 12,
        spreadRadius: 6,
      ),
    ],
    
    // Semantic shadows (Dark) - Verstärkt für bessere Sichtbarkeit
    cardShadow: [
      BoxShadow(
        color: Color(0x3D000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 2,
      ),
    ],
    
    buttonShadow: [
      BoxShadow(
        color: Color(0x3D000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 1,
      ),
    ],
    
    dialogShadow: [
      BoxShadow(
        color: Color(0x3D000000),
        offset: Offset(0, 4),
        blurRadius: 4,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 8),
        blurRadius: 12,
        spreadRadius: 6,
      ),
    ],
    
    menuShadow: [
      BoxShadow(
        color: Color(0x3D000000),
        offset: Offset(0, 2),
        blurRadius: 3,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 6),
        blurRadius: 10,
        spreadRadius: 4,
      ),
    ],
    
    tooltipShadow: [
      BoxShadow(
        color: Color(0x3D000000),
        offset: Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 4),
        blurRadius: 8,
        spreadRadius: 3,
      ),
    ],
    
    appBarShadow: [
      BoxShadow(
        color: Color(0x29000000),
        offset: Offset(0, 2),
        blurRadius: 4,
        spreadRadius: 0,
      ),
    ],
  );
  
  // ═══════════════════════════════════════════════════════════════
  // 🔄 THEME EXTENSION IMPLEMENTATION
  // ═══════════════════════════════════════════════════════════════
  
  @override
  ThemeExtension<AppShadowsTheme> copyWith({
    List<BoxShadow>? elevation0,
    List<BoxShadow>? elevation1,
    List<BoxShadow>? elevation2,
    List<BoxShadow>? elevation3,
    List<BoxShadow>? elevation4,
    List<BoxShadow>? elevation5,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? buttonShadow,
    List<BoxShadow>? dialogShadow,
    List<BoxShadow>? menuShadow,
    List<BoxShadow>? tooltipShadow,
    List<BoxShadow>? appBarShadow,
  }) {
    return AppShadowsTheme._internal(
      elevation0: elevation0 ?? this.elevation0,
      elevation1: elevation1 ?? this.elevation1,
      elevation2: elevation2 ?? this.elevation2,
      elevation3: elevation3 ?? this.elevation3,
      elevation4: elevation4 ?? this.elevation4,
      elevation5: elevation5 ?? this.elevation5,
      cardShadow: cardShadow ?? this.cardShadow,
      buttonShadow: buttonShadow ?? this.buttonShadow,
      dialogShadow: dialogShadow ?? this.dialogShadow,
      menuShadow: menuShadow ?? this.menuShadow,
      tooltipShadow: tooltipShadow ?? this.tooltipShadow,
      appBarShadow: appBarShadow ?? this.appBarShadow,
    );
  }
  
  @override
  ThemeExtension<AppShadowsTheme> lerp(
    covariant ThemeExtension<AppShadowsTheme>? other,
    double t,
  ) {
    if (other is! AppShadowsTheme) return this;
    
    return AppShadowsTheme._internal(
      elevation0: _lerpBoxShadowList(elevation0, other.elevation0, t),
      elevation1: _lerpBoxShadowList(elevation1, other.elevation1, t),
      elevation2: _lerpBoxShadowList(elevation2, other.elevation2, t),
      elevation3: _lerpBoxShadowList(elevation3, other.elevation3, t),
      elevation4: _lerpBoxShadowList(elevation4, other.elevation4, t),
      elevation5: _lerpBoxShadowList(elevation5, other.elevation5, t),
      cardShadow: _lerpBoxShadowList(cardShadow, other.cardShadow, t),
      buttonShadow: _lerpBoxShadowList(buttonShadow, other.buttonShadow, t),
      dialogShadow: _lerpBoxShadowList(dialogShadow, other.dialogShadow, t),
      menuShadow: _lerpBoxShadowList(menuShadow, other.menuShadow, t),
      tooltipShadow: _lerpBoxShadowList(tooltipShadow, other.tooltipShadow, t),
      appBarShadow: _lerpBoxShadowList(appBarShadow, other.appBarShadow, t),
    );
  }
  
  /// Helper method zum Interpolieren von BoxShadow-Listen
  List<BoxShadow> _lerpBoxShadowList(
    List<BoxShadow> a,
    List<BoxShadow> b,
    double t,
  ) {
    if (a.isEmpty && b.isEmpty) return [];
    if (a.isEmpty) return b.map((shadow) => BoxShadow.lerp(null, shadow, t)!).toList();
    if (b.isEmpty) return a.map((shadow) => BoxShadow.lerp(shadow, null, t)!).toList();
    
    final int length = a.length > b.length ? a.length : b.length;
    final List<BoxShadow> result = [];
    
    for (int i = 0; i < length; i++) {
      final BoxShadow? shadowA = i < a.length ? a[i] : null;
      final BoxShadow? shadowB = i < b.length ? b[i] : null;
      final BoxShadow? lerped = BoxShadow.lerp(shadowA, shadowB, t);
      if (lerped != null) result.add(lerped);
    }
    
    return result;
  }
} 