# Foundations: Farben

Farben sind das emotionalste Element eines Design-Systems. Unsere Farbpalette ist sorgfältig ausgewählt, um die Markenidentität von Vertic zu stärken, Lesbarkeit zu gewährleisten und eine klare visuelle Hierarchie zu schaffen.

## 1. Implementierung via `AppColorsTheme`

Alle Farben werden in einer `ThemeExtension` namens `AppColorsTheme` zentralisiert. Dies erzwingt die Verwendung unseres Farbsystems und verhindert hartcodierte Farbwerte im Code.

**Grundprinzipien:**

*   **Keine direkten Farbwerte**: Greifen Sie niemals direkt auf `Color(0xFF...)` oder `Colors.blue` in Widgets zu.
*   **Ausschließlich über das Theme**: Verwenden Sie immer `Theme.of(context).appColors.primary` oder eine ähnliche semantische Variable.
*   **Semantische Namen**: Farben werden nach ihrem Zweck benannt (z.B. `primary`, `background`, `textEmphasis`), nicht nach ihrem visuellen Erscheinungsbild (`darkBlue`, `lightGrey`).

```dart
/// lib/config/theme/colors.dart

import 'package:flutter/material.dart';

// Definieren Sie hier die konkreten Farbwerte für Light und Dark
const _primaryLight = Color(0xFF007AFF);
const _primaryDark = Color(0xFF0A84FF);
// ... weitere Farbdefinitionen

@immutable
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface; // Für Karten, Dialog-Hintergründe etc.
  final Color error;
  final Color success;
  final Color warning;
  
  // Textfarben
  final Color textDefault; // Standard-Text
  final Color textEmphasis; // Hervorgehobener Text
  final Color textSubtle; // Weniger wichtiger Text, Hinweise
  final Color textOnPrimary; // Text auf primärfarbigem Hintergrund
  
  // Rahmen- und Trennfarben
  final Color border;
  final Color divider;

  const AppColorsTheme._({
    required this.primary,
    required this.secondary,
    // ...
  });

  // Light Theme Farbpalette
  factory AppColorsTheme.light() {
    return const AppColorsTheme._(
      primary: _primaryLight,
      // ...
    );
  }

  // Dark Theme Farbpalette
  factory AppColorsTheme.dark() {
    return const AppColorsTheme._(
      primary: _primaryDark,
      // ...
    );
  }

  @override
  AppColorsTheme copyWith({
    // ... Parameter für jede Farbe
  }) {
    // ... Implementierung
  }

  @override
  AppColorsTheme lerp(ThemeExtension<AppColorsTheme>? other, double t) {
    // ... Implementierung
  }
}
```

## 2. Farbpalette

### Primärfarben
*   `primary`: Hauptinteraktionsfarbe für Buttons, Links und aktive Elemente.
*   `secondary`: Für weniger wichtige Aktionen oder zur Hervorhebung.

### Neutrale Farben
*   `background`: Hintergrundfarbe für ganze Seiten.
*   `surface`: Hintergrundfarbe für schwebende Elemente wie Karten oder Dialoge.
*   `border`: Für Rahmen um Container oder Eingabefelder.
*   `divider`: Für Trennlinien.

### Textfarben
*   `textDefault`: Standardfarbe für die meisten Texte.
*   `textEmphasis`: Für Überschriften oder wichtigen Text.
*   `textSubtle`: Für sekundären Text, Platzhalter oder Hinweise.
*   `textOnPrimary`: Für Text, der auf einem primärfarbigen Hintergrund platziert wird, um den Kontrast zu gewährleisten.

### Semantische Farben
*   `error`: Für Fehlermeldungen, Validierungsfehler.
*   `success`: Für Erfolgsmeldungen.
*   `warning`: Für Warnhinweise.

## 3. Dark & Light Mode

Das Design-System muss sowohl einen Light- als auch einen Dark-Mode vollständig unterstützen. Jede Farbe in `AppColorsTheme` muss für beide Modi definiert sein. Die Auswahl des richtigen Themes erfolgt automatisch durch Flutter basierend auf den Systemeinstellungen des Nutzers. 