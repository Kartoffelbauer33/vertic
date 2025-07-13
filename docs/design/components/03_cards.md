# Components: Karten (Cards)

Karten sind eine der vielseitigsten Komponenten in einem UI-System. Sie dienen als Container, um zusammengehörige Informationen und Aktionen auf einer visuell abgegrenzten Fläche zu gruppieren.

## 1. Anatomie einer Karte

Eine typische Karte besteht aus mehreren optionalen Teilen:

*   **Container**: Der äußere Wrapper mit Hintergrundfarbe, abgerundeten Ecken und Schatten.
*   **Header** (optional): Kann ein Bild, einen Titel und einen Untertitel enthalten.
*   **Inhalt (Content)**: Der Hauptbereich der Karte, der Text, Bilder oder andere Widgets enthalten kann.
*   **Footer / Aktionen** (optional): Ein Bereich am unteren Rand der Karte, der oft Buttons oder Links enthält.

## 2. Implementierung

Wir erstellen eine `CustomCard`-Komponente, die als flexibler Wrapper dient. Anstatt starre Slots für Header, Content und Footer vorzugeben, übergeben wir einfach ein `child`-Widget. Dies gibt uns maximale Flexibilität bei der Gestaltung des Karteninhalts.

Das Styling (Hintergrund, Radius, Schatten) wird jedoch von der `CustomCard` selbst gesteuert, um Konsistenz zu gewährleisten.

```dart
/// lib/widgets/design_system/cards/custom_card.dart

import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final dimensions = Theme.of(context).appDimensions;
    final shadows = Theme.of(context).appShadows;
    final animations = Theme.of(context).appAnimations;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(dimensions.radiusDefault),
      child: AnimatedContainer(
        duration: animations.short,
        padding: padding ?? EdgeInsets.all(dimensions.spacingM),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(dimensions.radiusDefault),
          boxShadow: shadows.low,
        ),
        child: child,
      ),
    );
  }
}
```

## 3. Anwendungsbeispiele

### a) Einfache Informationskarte

```dart
CustomCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Titel der Karte', style: Theme.of(context).appTexts.headlineSmall),
      SizedBox(height: Theme.of(context).appDimensions.spacingS),
      Text('Dies ist der Inhalt der Karte.', style: Theme.of(context).appTexts.body),
    ],
  ),
)
```

### b) Klickbare Karte mit Aktionen

```dart
CustomCard(
  onTap: () {
    // Navigiere zu den Details
  },
  child: Column(
    children: [
      // ... Inhalt
      Divider(color: Theme.of(context).appColors.border),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: () {}, child: Text('Aktion')),
        ],
      )
    ],
  ),
)
```

## 4. Richtlinien

*   **Konsistenter Inhalt**: Der Abstand und die Typografie innerhalb einer Karte sollten den allgemeinen Design-System-Regeln folgen.
*   **Nicht überladen**: Halten Sie den Inhalt einer Karte fokussiert und prägnant. Eine Karte sollte eine Haupteinheit von Informationen darstellen.
*   **Interaktivität**: Wenn eine ganze Karte klickbar ist (`onTap`), stellen Sie sicher, dass dies durch einen `hover`-Effekt (z.B. durch Anheben des Schattens auf `medium`) visuell angedeutet wird. Verwenden Sie `InkWell` oder `InkResponse` für den Ripple-Effekt bei Klicks. 