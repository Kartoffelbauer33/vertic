# Foundations: Schatten & Erhöhung (Elevation)

Schatten und Erhöhung (Elevation) sind entscheidend, um eine visuelle Hierarchie und Tiefe in der Benutzeroberfläche zu schaffen. Sie helfen dabei, interaktive oder wichtige Elemente vom Hintergrund abzuheben.

## 1. Implementierung via `AppShadowsTheme`

Wir zentralisieren alle `BoxShadow`-Definitionen in einer `ThemeExtension` namens `AppShadowsTheme`, um eine konsistente Anwendung von Schatten im gesamten Projekt zu gewährleisten.

**Grundprinzipien:**

*   **Vordefinierte Stufen**: Anstatt `BoxShadow` manuell zu erstellen, verwenden Sie eine der vordefinierten Schattenstufen aus dem Theme (z.B. `Theme.of(context).appShadows.low`).
*   **Konsistente Lichtquelle**: Alle Schatten sind so gestaltet, als ob das Licht von oben links kommt, was ein natürliches und konsistentes Erscheinungsbild erzeugt.

```dart
/// lib/config/theme/shadows.dart

import 'package:flutter/material.dart';

@immutable
class AppShadowsTheme extends ThemeExtension<AppShadowsTheme> {
  // Kein Schatten
  final List<BoxShadow> none;

  // Leichter Schatten für schwebende Elemente im Ruhezustand
  final List<BoxShadow> low;
  
  // Mittlerer Schatten für hervorgehobene oder interaktive Elemente (z.B. bei Hover)
  final List<BoxShadow> medium;

  // Starker Schatten für Elemente, die deutlich im Vordergrund stehen müssen (z.B. modale Dialoge)
  final List<BoxShadow> high;

  const AppShadowsTheme._({
    required this.none,
    required this.low,
    required this.medium,
    required this.high,
  });

  factory AppShadowsTheme.main() {
    // Die Farbwerte sollten aus einem neutralen Farbschema stammen,
    // oft ein Schwarz mit geringer Deckkraft.
    const shadowColor = Color(0x1A000000); // Beispiel: Schwarz mit 10% Deckkraft

    return const AppShadowsTheme._(
      none: [],
      low: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 8.0,
          offset: Offset(0, 2),
        ),
      ],
      medium: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 16.0,
          offset: Offset(0, 4),
        ),
      ],
      high: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 32.0,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  // ... copyWith und lerp
}
```

## 2. Schatten-Hierarchie

Unsere Schatten-Hierarchie hilft dabei, die relative Wichtigkeit und Interaktivität von Elementen zu kommunizieren.

*   **`none`**: Für flache Elemente, die auf derselben Ebene wie der Hintergrund liegen.
*   **`low`**: Der Standard-Schatten für die meisten "schwebenden" Elemente wie Karten (`Card`) oder nicht interaktive Banner. Er hebt das Element leicht vom Hintergrund ab.
*   **`medium`**: Wird verwendet, um ein Element hervorzuheben, oft als Reaktion auf eine Benutzerinteraktion wie `onHover`. Es signalisiert, dass ein Element interaktiv ist.
*   **`high`**: Reserviert für Elemente, die temporär über allen anderen Inhalten schweben, wie z.B. modale Dialoge, Menüs oder wichtige Benachrichtigungen. Dieser starke Schatten lenkt den Fokus des Nutzers auf das Element im Vordergrund.

## 3. Anwendung

Die Schatten werden typischerweise in der `decoration`-Eigenschaft eines `Container` verwendet.

```dart
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).appColors.surface,
    borderRadius: BorderRadius.circular(Theme.of(context).appDimensions.radiusDefault),
    boxShadow: Theme.of(context).appShadows.low, // Anwendung des Schattens
  ),
  child: // ...
)
``` 