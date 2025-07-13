# Foundations: Animationen

Animationen und Übergänge (Transitions) sind entscheidend, um eine dynamische und reaktionsschnelle Benutzeroberfläche zu schaffen. Gut gemachte Animationen geben dem Nutzer Feedback, leiten seine Aufmerksamkeit und verbessern das allgemeine Nutzungserlebnis.

## 1. Philosophie & Prinzipien

*   **Zweckgerichtet**: Jede Animation muss einen Zweck haben. Sie sollte entweder Feedback geben (z.B. bei einem Klick), den Nutzer durch einen Übergang führen oder eine Statusänderung anzeigen. Vermeiden Sie rein dekorative Animationen, die ablenken könnten.
*   **Subtil & Schnell**: Animationen sollten schnell und unaufdringlich sein. Die meisten UI-Animationen sollten im Bereich von **150ms bis 300ms** liegen.
*   **Performant**: Verwenden Sie performante Animations-Widgets (`AnimatedBuilder`, `FadeTransition`, `SlideTransition` etc.), um UI-Ruckeln (Jank) zu vermeiden. Animieren Sie `transform` und `opacity` anstelle von Eigenschaften, die ein teures `relayout` erzwingen (wie `width` oder `height`).

## 2. Implementierung via `AppAnimationsTheme`

Wir definieren Standard-Dauern (`Duration`) und -Kurven (`Curve`) in einer `ThemeExtension`, um konsistente Animationen in der gesamten App sicherzustellen.

```dart
/// lib/config/theme/animations.dart

import 'package:flutter/material.dart';

@immutable
class AppAnimationsTheme extends ThemeExtension<AppAnimationsTheme> {
  // Standard-Dauer für die meisten UI-Animationen
  final Duration short; // z.B. 150ms

  // Dauer für komplexere oder größere Übergänge
  final Duration medium; // z.B. 300ms

  // Standard-Animationskurve
  final Curve curve; // z.B. Curves.easeInOut

  const AppAnimationsTheme._({
    required this.short,
    required this.medium,
    required this.curve,
  });

  factory AppAnimationsTheme.main() {
    return const AppAnimationsTheme._(
      short: Duration(milliseconds: 150),
      medium: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ... copyWith und lerp
}
```

## 3. Anwendungsbereiche

### a) Implizite Animationen

Für einfache Animationen von einzelnen Eigenschaften (Farbe, Größe, Position) sind implizite Animations-Widgets die beste Wahl. Sie sind einfach zu verwenden und verwalten den `AnimationController` intern.

*   **`AnimatedContainer`**: Animiert Änderungen seiner Eigenschaften wie `color`, `width`, `height`, `padding`, `decoration`.
*   **`AnimatedOpacity`**: Animiert die Deckkraft eines Widgets.
*   **`AnimatedPositioned`**: Animiert die Position eines Widgets innerhalb eines `Stack`.

**Beispiel:** Ein Button, der seine Farbe bei Aktivierung ändert.

```dart
bool _isActive = false;

// ...

AnimatedContainer(
  duration: Theme.of(context).appAnimations.short,
  curve: Theme.of(context).appAnimations.curve,
  color: _isActive 
    ? Theme.of(context).appColors.primary 
    : Theme.of(context).appColors.surface,
  // ...
)
```

### b) Explizite Animationen & Übergänge

Für komplexere oder miteinander verbundene Animationen sowie für Seitenübergänge sind explizite Animationen erforderlich, bei denen Sie den `AnimationController` selbst verwalten.

*   **`FadeTransition`**: Für Ein- und Ausblendanimationen.
*   **`SlideTransition`**: Für Hinein- und Herausschieb-Animationen.
*   **`ScaleTransition`**: Für Skalierungsanimationen.
*   **`AnimatedBuilder`**: Ein vielseitiges Widget für benutzerdefinierte Animationen, das nur den Teil des Widget-Baums neu aufbaut, der von der Animation betroffen ist.

### c) Seitenübergänge (Page Transitions)

Für konsistente Navigation zwischen den Seiten definieren wir einen benutzerdefinierten `PageRouteBuilder`.

*   **Standard-Übergang**: Ein subtiler **Fade- und Slide-Übergang** ist oft eine gute Wahl.
*   **Implementierung**: Erstellen Sie eine wiederverwendbare Klasse, die von `PageRouteBuilder` erbt und die Standard-Dauer und -Kurven aus `AppAnimationsTheme` verwendet.

## 4. Bibliotheken

Für komplexere oder vordefinierte Animationen kann die Verwendung einer Bibliothek sinnvoll sein.

*   **`animations`**: Ein von Google bereitgestelltes Paket, das hochwertige, vorgefertigte Animationen wie `FadeThroughTransition` oder `SharedAxisTransition` enthält, die den Material-Design-Richtlinien entsprechen.
*   **`flutter_animate`**: Eine beliebte Bibliothek, die eine sehr einfache und lesbare Syntax zum Erstellen komplexer Animationen bietet. 