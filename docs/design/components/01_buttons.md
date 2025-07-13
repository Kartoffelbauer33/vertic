# Components: Buttons

Buttons sind die grundlegendsten interaktiven Elemente. Sie lösen eine Aktion aus, wenn ein Nutzer darauf klickt. Unser Design-System definiert verschiedene Arten von Buttons für unterschiedliche Zwecke und Hierarchien.

## 1. Arten von Buttons

### a) `PrimaryButton`
Der `PrimaryButton` ist für die primäre, wichtigste Aktion auf einem Bildschirm vorgesehen (z.B. "Speichern", "Senden", "Anmelden"). Es sollte in der Regel nur einen `PrimaryButton` pro Ansicht geben.

*   **Aussehen**: Gefüllt mit der Primärfarbe (`primary`), Text in `textOnPrimary`.
*   **Zustände**: Muss visuelles Feedback für `hover`, `pressed` und `disabled` geben.

### b) `SecondaryButton`
Der `SecondaryButton` ist für sekundäre Aktionen gedacht, die weniger wichtig sind als die primäre Aktion (z.B. "Abbrechen", "Zurück").

*   **Aussehen**: Hat einen sichtbaren Rahmen in der Primärfarbe, aber einen transparenten oder Oberflächen-Hintergrund (`surface`).
*   **Zustände**: Bietet ebenfalls Feedback für `hover`, `pressed` und `disabled`.

### c) `TextButton` (oder `TertiaryButton`)
Der `TextButton` ist für die am wenigsten wichtigen Aktionen, die keine große visuelle Aufmerksamkeit erfordern (z.B. "Passwort vergessen?", "Mehr anzeigen").

*   **Aussehen**: Hat keinen Rahmen oder Hintergrund, besteht nur aus Text. Die Interaktivität wird durch die Textfarbe und eventuell eine Unterstreichung bei `hover` angezeigt.

### d) `IconButton`
Für Aktionen, die durch ein Icon klar repräsentiert werden können, um Platz zu sparen. Muss immer ein `tooltip` für die Barrierefreiheit haben.

## 2. Implementierung

Wir erstellen für jeden Button-Typ ein eigenes, wiederverwendbares Widget. Diese Widgets kapseln die gesamte Styling- und Zustandslogik.

```dart
/// lib/widgets/design_system/buttons/primary_button.dart

import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Greife auf das Design System zu
    final colors = Theme.of(context).appColors;
    final texts = Theme.of(context).appTexts;
    final dimensions = Theme.of(context).appDimensions;
    final animations = Theme.of(context).appAnimations;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.textOnPrimary,
        disabledBackgroundColor: colors.primary.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dimensions.radiusDefault),
        ),
        padding: EdgeInsets.symmetric(
          vertical: dimensions.spacingS,
          horizontal: dimensions.spacingM,
        ),
        textStyle: texts.label,
        animationDuration: animations.short,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(colors.textOnPrimary),
              ),
            )
          : Text(text),
    );
  }
}
```

## 3. Zustände (States)

Jede interaktive Komponente muss klar ihre verschiedenen Zustände kommunizieren:

*   **`Normal`**: Der Standardzustand.
*   **`Hover`** (nur Desktop/Web): Wenn der Mauszeiger über dem Element schwebt. Löst oft eine leichte Änderung der Hintergrundfarbe oder des Schattens aus.
*   **`Pressed`/`Active`**: Wenn der Nutzer das Element aktiv drückt. Typischerweise wird der Button leicht dunkler oder kleiner.
*   **`Disabled`**: Wenn die Aktion nicht verfügbar ist. Der Button ist ausgegraut und reagiert nicht auf Klicks.
*   **`Loading`**: Wenn nach dem Klick eine asynchrone Aktion ausgeführt wird. Oft wird ein Ladeindikator (`CircularProgressIndicator`) anstelle des Textes angezeigt.
*   **`Focus`**: Wenn das Element über die Tastaturnavigation ausgewählt wird. Es sollte ein sichtbarer Fokus-Ring angezeigt werden. 