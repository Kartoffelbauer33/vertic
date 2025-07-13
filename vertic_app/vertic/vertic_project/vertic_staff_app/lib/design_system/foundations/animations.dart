import 'package:flutter/material.dart';

/// **🎬 VERTIC DESIGN SYSTEM - ANIMATIONEN**
/// 
/// Konsistente Animations-Definitionen mit:
/// - Material Design 3 Motion Guidelines
/// - Performance-optimierte Timing-Werte
/// - Semantische Animation-Presets
/// - Accessibility-freundliche Konfiguration
class AppAnimationsTheme extends ThemeExtension<AppAnimationsTheme> {
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 DURATION VALUES
  // ═══════════════════════════════════════════════════════════════
  
  final Duration instant;       // 0ms - Sofortige Änderungen
  final Duration fast;          // 150ms - Schnelle Übergänge
  final Duration medium;        // 250ms - Standard-Übergänge
  final Duration slow;          // 400ms - Langsame Übergänge
  final Duration verySlow;      // 600ms - Sehr langsame Übergänge
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 ANIMATION CURVES
  // ═══════════════════════════════════════════════════════════════
  
  final Curve easeIn;           // Beschleunigung am Anfang
  final Curve easeOut;          // Verlangsamung am Ende
  final Curve easeInOut;        // Standard-Kurve
  final Curve bounce;           // Sprungeffekt
  final Curve elastic;          // Elastischer Effekt
  final Curve overshoot;        // Überschießender Effekt
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 SEMANTIC ANIMATIONS
  // ═══════════════════════════════════════════════════════════════
  
  final Duration buttonTap;     // Button-Tap-Feedback
  final Duration pageTransition; // Seitenwechsel
  final Duration dialogShow;    // Dialog ein-/ausblenden
  final Duration menuSlide;     // Menü-Animationen
  final Duration cardFlip;      // Karten-Animationen
  final Duration loadingSpinner; // Loading-Animationen
  final Duration fadeInOut;     // Fade-Effekte
  final Duration slideUpDown;   // Slide-Animationen
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════
  
  const AppAnimationsTheme._internal({
    required this.instant,
    required this.fast,
    required this.medium,
    required this.slow,
    required this.verySlow,
    required this.easeIn,
    required this.easeOut,
    required this.easeInOut,
    required this.bounce,
    required this.elastic,
    required this.overshoot,
    required this.buttonTap,
    required this.pageTransition,
    required this.dialogShow,
    required this.menuSlide,
    required this.cardFlip,
    required this.loadingSpinner,
    required this.fadeInOut,
    required this.slideUpDown,
  });
  
  // ═══════════════════════════════════════════════════════════════
  // 🏭 FACTORY CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════
  
  factory AppAnimationsTheme.main({bool reducedMotion = false}) {
    // Accessibility: Reduzierte Animationen für Nutzer mit Motion-Sensitivität
    final double motionScale = reducedMotion ? 0.5 : 1.0;
    
    return AppAnimationsTheme._internal(
      // Basic durations
      instant: const Duration(milliseconds: 0),
      fast: Duration(milliseconds: (150 * motionScale).round()),
      medium: Duration(milliseconds: (250 * motionScale).round()),
      slow: Duration(milliseconds: (400 * motionScale).round()),
      verySlow: Duration(milliseconds: (600 * motionScale).round()),
      
      // Animation curves
      easeIn: Curves.easeIn,
      easeOut: Curves.easeOut,
      easeInOut: Curves.easeInOut,
      bounce: Curves.bounceOut,
      elastic: Curves.elasticOut,
      overshoot: Curves.elasticInOut,
      
      // Semantic animations
      buttonTap: Duration(milliseconds: (100 * motionScale).round()),
      pageTransition: Duration(milliseconds: (300 * motionScale).round()),
      dialogShow: Duration(milliseconds: (250 * motionScale).round()),
      menuSlide: Duration(milliseconds: (200 * motionScale).round()),
      cardFlip: Duration(milliseconds: (400 * motionScale).round()),
      loadingSpinner: Duration(milliseconds: (1000 * motionScale).round()),
      fadeInOut: Duration(milliseconds: (200 * motionScale).round()),
      slideUpDown: Duration(milliseconds: (300 * motionScale).round()),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 ANIMATION HELPER METHODS
  // ═══════════════════════════════════════════════════════════════
  
  /// Erstellt eine Fade-Animation
  AnimationController createFadeController(TickerProvider vsync) {
    return AnimationController(
      duration: fadeInOut,
      vsync: vsync,
    );
  }
  
  /// Erstellt eine Slide-Animation
  AnimationController createSlideController(TickerProvider vsync) {
    return AnimationController(
      duration: slideUpDown,
      vsync: vsync,
    );
  }
  
  /// Erstellt eine Scale-Animation für Buttons
  AnimationController createButtonController(TickerProvider vsync) {
    return AnimationController(
      duration: buttonTap,
      vsync: vsync,
    );
  }
  
  /// Erstellt eine Rotation-Animation
  AnimationController createRotationController(TickerProvider vsync) {
    return AnimationController(
      duration: loadingSpinner,
      vsync: vsync,
    );
  }
  
  /// Standard Tween für Opacity-Animationen
  Tween<double> get opacityTween => Tween<double>(begin: 0.0, end: 1.0);
  
  /// Standard Tween für Scale-Animationen
  Tween<double> get scaleTween => Tween<double>(begin: 0.8, end: 1.0);
  
  /// Standard Tween für Slide-Animationen
  Tween<Offset> get slideUpTween => 
      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero);
  
  /// Standard Tween für Slide-Down-Animationen
  Tween<Offset> get slideDownTween => 
      Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero);
  
  /// Standard Tween für Slide-Left-Animationen
  Tween<Offset> get slideLeftTween => 
      Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero);
  
  /// Standard Tween für Slide-Right-Animationen
  Tween<Offset> get slideRightTween => 
      Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero);
  
  // ═══════════════════════════════════════════════════════════════
  // 🎯 PREDEFINED ANIMATIONS
  // ═══════════════════════════════════════════════════════════════
  
  /// Erstellt eine kombinierte Fade + Scale Animation
  Animation<double> createFadeScaleAnimation(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: easeOut,
    );
  }
  
  /// Erstellt eine Slide + Fade Animation
  Animation<double> createSlideFadeAnimation(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: easeInOut,
    );
  }
  
  /// Erstellt eine Bounce Animation
  Animation<double> createBounceAnimation(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: bounce,
    );
  }
  
  /// Erstellt eine Elastic Animation
  Animation<double> createElasticAnimation(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: elastic,
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🔄 THEME EXTENSION IMPLEMENTATION
  // ═══════════════════════════════════════════════════════════════
  
  @override
  ThemeExtension<AppAnimationsTheme> copyWith({
    Duration? instant,
    Duration? fast,
    Duration? medium,
    Duration? slow,
    Duration? verySlow,
    Curve? easeIn,
    Curve? easeOut,
    Curve? easeInOut,
    Curve? bounce,
    Curve? elastic,
    Curve? overshoot,
    Duration? buttonTap,
    Duration? pageTransition,
    Duration? dialogShow,
    Duration? menuSlide,
    Duration? cardFlip,
    Duration? loadingSpinner,
    Duration? fadeInOut,
    Duration? slideUpDown,
  }) {
    return AppAnimationsTheme._internal(
      instant: instant ?? this.instant,
      fast: fast ?? this.fast,
      medium: medium ?? this.medium,
      slow: slow ?? this.slow,
      verySlow: verySlow ?? this.verySlow,
      easeIn: easeIn ?? this.easeIn,
      easeOut: easeOut ?? this.easeOut,
      easeInOut: easeInOut ?? this.easeInOut,
      bounce: bounce ?? this.bounce,
      elastic: elastic ?? this.elastic,
      overshoot: overshoot ?? this.overshoot,
      buttonTap: buttonTap ?? this.buttonTap,
      pageTransition: pageTransition ?? this.pageTransition,
      dialogShow: dialogShow ?? this.dialogShow,
      menuSlide: menuSlide ?? this.menuSlide,
      cardFlip: cardFlip ?? this.cardFlip,
      loadingSpinner: loadingSpinner ?? this.loadingSpinner,
      fadeInOut: fadeInOut ?? this.fadeInOut,
      slideUpDown: slideUpDown ?? this.slideUpDown,
    );
  }
  
  @override
  ThemeExtension<AppAnimationsTheme> lerp(
    covariant ThemeExtension<AppAnimationsTheme>? other,
    double t,
  ) {
    if (other is! AppAnimationsTheme) return this;
    
    return AppAnimationsTheme._internal(
      instant: _lerpDuration(instant, other.instant, t),
      fast: _lerpDuration(fast, other.fast, t),
      medium: _lerpDuration(medium, other.medium, t),
      slow: _lerpDuration(slow, other.slow, t),
      verySlow: _lerpDuration(verySlow, other.verySlow, t),
      easeIn: t < 0.5 ? easeIn : other.easeIn,
      easeOut: t < 0.5 ? easeOut : other.easeOut,
      easeInOut: t < 0.5 ? easeInOut : other.easeInOut,
      bounce: t < 0.5 ? bounce : other.bounce,
      elastic: t < 0.5 ? elastic : other.elastic,
      overshoot: t < 0.5 ? overshoot : other.overshoot,
      buttonTap: _lerpDuration(buttonTap, other.buttonTap, t),
      pageTransition: _lerpDuration(pageTransition, other.pageTransition, t),
      dialogShow: _lerpDuration(dialogShow, other.dialogShow, t),
      menuSlide: _lerpDuration(menuSlide, other.menuSlide, t),
      cardFlip: _lerpDuration(cardFlip, other.cardFlip, t),
      loadingSpinner: _lerpDuration(loadingSpinner, other.loadingSpinner, t),
      fadeInOut: _lerpDuration(fadeInOut, other.fadeInOut, t),
      slideUpDown: _lerpDuration(slideUpDown, other.slideUpDown, t),
    );
  }
  
  /// Helper method zum Interpolieren von Duration-Werten
  Duration _lerpDuration(Duration a, Duration b, double t) {
    return Duration(
      milliseconds: (a.inMilliseconds * (1 - t) + b.inMilliseconds * t).round(),
    );
  }
} 