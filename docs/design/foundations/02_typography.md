# Foundations: Typografie

Typografie ist die Stimme unseres Designs. Eine konsistente und hierarchische Typografie verbessert die Lesbarkeit, lenkt die Aufmerksamkeit des Nutzers und schafft eine klare Struktur.

## 1. Implementierung via `AppTextsTheme`

Ähnlich wie bei den Farben werden alle `TextStyle`-Definitionen in einer `ThemeExtension` namens `AppTextsTheme` zentralisiert.

**Grundprinzipien:**

*   **Keine manuellen `TextStyle`s**: Definieren Sie niemals `TextStyle` direkt in einem Widget.
*   **Ausschließlich über das Theme**: Verwenden Sie immer Stile aus dem Theme, z.B. `Theme.of(context).appTexts.headlineLarge`.
*   **Anpassung mit `copyWith`**: Wenn ein Stil leicht modifiziert werden muss (z.B. eine andere Farbe), verwenden Sie die `.copyWith()`-Methode. Beispiel: `Theme.of(context).appTexts.body.copyWith(color: Theme.of(context).appColors.primary)`.

```dart
/// lib/config/theme/typography.dart

import 'package:flutter/material.dart';

@immutable
class AppTextsTheme extends ThemeExtension<AppTextsTheme> {
  // Überschriften
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;

  // Body / Fließtext
  final TextStyle body;
  final TextStyle bodyEmphasis; // Für fettgedruckten Text
  final TextStyle bodySmall;

  // Sonstige
  final TextStyle label; // Für Formular-Labels oder Buttons
  final TextStyle caption; // Für Bildunterschriften oder kleine Hinweise

  const AppTextsTheme._({
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.body,
    required this.bodyEmphasis,
    required this.bodySmall,
    required this.label,
    required this.caption,
  });

  factory AppTextsTheme.main() {
    // Definieren Sie hier die Schriftfamilien
    const String fontRegular = 'Inter-Regular';
    const String fontBold = 'Inter-Bold';

    return const AppTextsTheme._(
      headlineLarge: TextStyle(fontFamily: fontBold, fontSize: 32, height: 1.25),
      headlineMedium: TextStyle(fontFamily: fontBold, fontSize: 24, height: 1.25),
      headlineSmall: TextStyle(fontFamily: fontBold, fontSize: 20, height: 1.25),
      
      body: TextStyle(fontFamily: fontRegular, fontSize: 16, height: 1.5),
      bodyEmphasis: TextStyle(fontFamily: fontBold, fontSize: 16, height: 1.5),
      bodySmall: TextStyle(fontFamily: fontRegular, fontSize: 14, height: 1.5),
      
      label: TextStyle(fontFamily: fontBold, fontSize: 16, height: 1),
      caption: TextStyle(fontFamily: fontRegular, fontSize: 12, height: 1.25),
    );
  }

  @override
  AppTextsTheme copyWith({
    // ... Parameter
  }) {
    // ... Implementierung
  }

  @override
  AppTextsTheme lerp(ThemeExtension<AppTextsTheme>? other, double t) {
    // ... Implementierung
  }
}
```

## 2. Typografie-Skala

Unsere Typografie-Skala stellt eine klare visuelle Hierarchie sicher.

*   **`headlineLarge` / `headlineMedium` / `headlineSmall`**: Für Seitentitel und wichtige Abschnittsüberschriften.
*   **`body`**: Der Standardstil für allen Fließtext.
*   **`bodyEmphasis`**: Für fettgedruckten oder anderweitig hervorgehobenen Fließtext.
*   **`bodySmall`**: Für sekundäre Informationen oder weniger wichtigen Text.
*   **`label`**: Wird typischerweise in Buttons und Formular-Labels verwendet.
*   **`caption`**: Für sehr kleine Texte wie Bildunterschriften oder Metadaten.

## 3. Schriftarten (Fonts)

1.  **Auswahl**: Wählen Sie eine oder maximal zwei Schriftfamilien für das gesamte Projekt aus (z.B. Inter, Roboto, Lato).
2.  **Einbindung**:
    *   Laden Sie die Schriftart-Dateien (z.B. `.ttf` oder `.otf`) herunter.
    *   Erstellen Sie einen `assets/fonts`-Ordner im Projekt.
    *   Deklarieren Sie die Schriftarten in der `pubspec.yaml`:
        ```yaml
        flutter:
          fonts:
            - family: Inter
              fonts:
                - asset: assets/fonts/Inter-Regular.ttf
                - asset: assets.md/fonts/Inter-Bold.ttf
                  weight: 700
        ```
3.  **Verwendung**: Verweisen Sie auf den `family`-Namen in den `TextStyle`-Definitionen in `AppTextsTheme`. 