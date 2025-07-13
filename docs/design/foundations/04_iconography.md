# Foundations: Ikonografie

Icons sind ein wesentlicher Bestandteil einer intuitiven Benutzeroberfläche. Sie dienen als schnelle, universell verständliche visuelle Hinweise für Aktionen, Status und Objekte.

## 1. Icon-Bibliothek

Wir verwenden eine einzige, konsistente Icon-Bibliothek für die gesamte Anwendung, um ein einheitliches Erscheinungsbild zu gewährleisten.

*   **Empfehlung**: **`Remix Icon`** oder **`Lucide`**. Beide bieten eine große Auswahl an klaren, modernen und gut lesbaren Icons im Outline-Stil, der gut zu unserem Design passt.
*   **Paket**: Wir nutzen ein Flutter-Paket wie `remixicon` oder `lucide_flutter`, um einfach auf die Icons zugreifen zu können.

```yaml
# pubspec.yaml
dependencies:
  # ...
  lucide_flutter: ^0.400.0 # Beispiel
```

## 2. Implementierung

Icons werden wie reguläre Widgets verwendet. Ihre Farbe und Größe sollten jedoch aus dem Design-System stammen, um Konsistenz zu gewährleisten.

```dart
import 'package:lucide_flutter/lucide_flutter.dart';

// ...

Icon(
  LucideIcons.search,
  color: Theme.of(context).appColors.textDefault,
  size: 24.0, // Standardgröße für Icons
)
```

## 3. Richtlinien zur Verwendung

*   **Konsistenz**: Verwenden Sie immer Icons aus der ausgewählten Bibliothek. Mischen Sie keine Stile (z.B. Outline- und Filled-Icons), es sei denn, dies ist explizit zur Anzeige eines Zustands (z.B. aktiv/inaktiv) vorgesehen.
*   **Bedeutung**: Wählen Sie Icons, deren Bedeutung klar und allgemein verständlich ist. Ein `?`-Icon für Hilfe ist besser als ein unklares Symbol.
*   **Größe**: Verwenden Sie eine begrenzte Anzahl von Standardgrößen (z.B. 16px, 20px, 24px), um die visuelle Harmonie zu wahren. Diese Größen können ebenfalls in `AppDimensionsTheme` definiert werden.
*   **Barrierefreiheit**:
    *   **Label**: Wenn ein Icon ohne Text als Button verwendet wird (z.B. in einer `IconButton`), muss es immer ein `tooltip` und ein `Semantics`-Label haben.
        ```dart
        IconButton(
          icon: Icon(LucideIcons.settings),
          tooltip: 'Einstellungen',
          onPressed: () {},
        )
        // Das Semantics-Widget wird vom IconButton oft schon intern bereitgestellt.
        // Bei reinen Icon-Anzeigen ohne Funktionalität kann es so aussehen:
        Semantics(
          label: 'Einstellungs-Icon',
          child: Icon(LucideIcons.settings),
        )
        ```
    *   **Touch-Ziel**: Der klickbare Bereich um ein Icon (`IconButton`) muss mindestens 48x48dp groß sein, auch wenn das Icon selbst kleiner ist.

## 4. Eigene Icons (Custom Icons)

In seltenen Fällen können eigene Icons (z.B. für das Firmenlogo) erforderlich sein.

*   **Format**: Verwenden Sie das **SVG-Format**, da es verlustfrei skaliert werden kann.
*   **Einbindung**: Nutzen Sie das `flutter_svg`-Paket, um SVG-Dateien als Widgets in der App anzuzeigen.
*   **Optimierung**: Optimieren Sie SVGs vor der Einbindung mit einem Tool wie [SVGOMG](https://jakearchibald.github.io/svgomg/), um die Dateigröße zu reduzieren.
*   **Verwaltung**: Eigene Icons werden im Ordner `assets/icons/` gespeichert und in der `pubspec.yaml` deklariert. 