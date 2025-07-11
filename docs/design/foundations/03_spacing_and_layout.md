# Foundations: Abstände & Layout

Ein konsistentes Abstands- und Layoutsystem (Spacing) ist entscheidend für eine aufgeräumte, visuell ansprechende und harmonische Benutzeroberfläche. Es schafft einen visuellen Rhythmus und verbessert die Lesbarkeit.

## 1. Implementierung via `AppDimensionsTheme`

Alle Werte für Abstände, Radien und andere Größen werden in der `AppDimensionsTheme` `ThemeExtension` definiert.

**Grundprinzipien:**

*   **Keine magischen Zahlen**: Verwenden Sie niemals hartcodierte numerische Werte für `padding`, `margin` oder `SizedBox`.
*   **Ausschließlich über das Theme**: Greifen Sie auf die vordefinierten Werte zu, z.B. `Theme.of(context).appDimensions.spacingMedium`.
*   **Responsive Anpassung**: Die `AppDimensionsTheme` kann responsive Werte basierend auf der Bildschirmgröße bereitstellen.

```dart
/// lib/config/theme/dimensions.dart

import 'package:flutter/material.dart';

@immutable
class AppDimensionsTheme extends ThemeExtension<AppDimensionsTheme> {
  // Bas-Abstände
  final double spacingXXS; // 2.0
  final double spacingXS;  // 4.0
  final double spacingS;   // 8.0
  final double spacingM;   // 16.0
  final double spacingL;   // 24.0
  final double spacingXL;  // 32.0
  final double spacingXXL; // 48.0

  // Seiten-Padding
  final EdgeInsets pagePadding;

  // Radien
  final double radiusSmall;
  final double radiusDefault;
  final double radiusLarge;

  const AppDimensionsTheme._({
    // ...
  });

  // Responsive Factory, die die Bildschirmbreite berücksichtigt
  factory AppDimensionsTheme.main(double screenWidth) {
    final isSmallScreen = screenWidth < 600;
    
    return AppDimensionsTheme._(
      spacingXXS: 2.0,
      spacingXS: 4.0,
      spacingS: 8.0,
      spacingM: 16.0,
      spacingL: isSmallScreen ? 20.0 : 24.0,
      spacingXL: isSmallScreen ? 28.0 : 32.0,
      spacingXXL: isSmallScreen ? 40.0 : 48.0,
      pagePadding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      radiusSmall: 4.0,
      radiusDefault: 8.0,
      radiusLarge: 16.0,
    );
  }

  // ... copyWith und lerp
}
```

## 2. Abstands-Skala (Spacing Scale)

Wir verwenden eine multiplikative Skala, die auf einer Basiseinheit von 4.0 oder 8.0 basiert. Dies sorgt für einen konsistenten visuellen Rhythmus.

*   `spacingXXS` (2px): Für sehr feine Anpassungen.
*   `spacingXS` (4px): Minimaler Abstand zwischen kleinen Elementen.
*   `spacingS` (8px): Abstand zwischen eng zusammengehörigen Elementen (z.B. Icon und Text).
*   `spacingM` (16px): Standardabstand zwischen den meisten UI-Elementen.
*   `spacingL` (24px): Abstand zwischen größeren UI-Gruppen oder Sektionen.
*   `spacingXL` (32px): Großer vertikaler Abstand.
*   `spacingXXL` (48px): Sehr großer Abstand zur Trennung von Hauptbereichen.

**Anwendung:**

*   **`SizedBox`**: Der bevorzugte Weg, um Abstände in `Column`s und `Row`s zu erzeugen.
    *   `SizedBox(height: Theme.of(context).appDimensions.spacingM)`
*   **`Padding`**: Um den inneren Abstand eines Widgets zu steuern.
    *   `Padding(padding: Theme.of(context).appDimensions.pagePadding, ...)`
*   **`gap` (in Flex-Layouts)**: Für `Row` oder `Column`, wenn eine Bibliothek wie `flex_gap` verwendet wird.

## 3. Radien

Einheitliche Eckradien tragen zu einem kohärenten Erscheinungsbild bei.

*   `radiusSmall`: Für kleine Elemente wie Tags oder Badges.
*   `radiusDefault`: Standardradius für Buttons, Eingabefelder und Karten.
*   `radiusLarge`: Für größere Container oder modale Dialoge.

**Anwendung:**
`borderRadius: BorderRadius.circular(Theme.of(context).appDimensions.radiusDefault)`

## 4. Layout & Raster

Für das übergeordnete Seitenlayout verwenden wir `ResponsiveGrid` oder `LayoutBuilder`, um eine anpassungsfähige Benutzeroberfläche zu schaffen. Die `pagePadding`-Eigenschaft sorgt für einen konsistenten "sicheren Bereich" am Rand des Bildschirms. 