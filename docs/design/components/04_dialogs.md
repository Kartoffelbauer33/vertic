# Components: Dialoge (Dialogs)

Dialoge sind modale Fenster, die über dem restlichen App-Inhalt schweben. Sie dienen dazu, die Aufmerksamkeit des Nutzers auf eine wichtige Information oder eine erforderliche Aktion zu lenken.

## 1. Arten von Dialogen

*   **Bestätigungsdialog (`ConfirmationDialog`)**: Wird verwendet, um eine kritische Aktion vom Nutzer bestätigen zu lassen (z.B. "Möchten Sie dieses Element wirklich löschen?"). Enthält typischerweise einen Titel, eine kurze Beschreibung und zwei Buttons (z.B. "Abbrechen" und "Löschen").
*   **Informationsdialog (`InfoDialog`)**: Dient dazu, dem Nutzer eine wichtige Information mitzuteilen, die er zur Kenntnis nehmen muss. Enthält meist nur einen "OK"-Button.
*   **Benutzerdefinierter Dialog (`CustomDialog`)**: Eine flexiblere Dialog-Komponente, die beliebige Inhalte aufnehmen kann, z.B. ein Formular oder eine Auswahl-Liste.

## 2. Implementierung

Anstatt die Dialog-Widgets direkt zu erstellen, definieren wir globale Helper-Funktionen, die `showDialog` von Flutter aufrufen. Dies stellt sicher, dass alle Dialoge ein konsistentes Aussehen und Verhalten haben (z.B. den gleichen Schatten, die gleiche Eintrittsanimation).

```dart
/// lib/widgets/design_system/dialogs/custom_dialog.dart

import 'package:flutter/material.dart';

// Basis-Dialog-Komponente
class CustomDialog extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;

  const CustomDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
      // Styling aus dem Design System
      backgroundColor: Theme.of(context).appColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Theme.of(context).appDimensions.radiusLarge),
      ),
      titleTextStyle: Theme.of(context).appTexts.headlineSmall,
      contentTextStyle: Theme.of(context).appTexts.body,
    );
  }
}


/// lib/services/dialog_service.dart

Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmText = 'Bestätigen',
  String cancelText = 'Abbrechen',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => CustomDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        PrimaryButton(
          onPressed: () => Navigator.of(context).pop(true),
          text: confirmText,
        ),
      ],
    ),
  );
}
```

## 3. Richtlinien

*   **Kurz halten**: Der Inhalt eines Dialogs sollte kurz und prägnant sein. Vermeiden Sie lange Texte oder komplexes Scrolling innerhalb eines Dialogs.
*   **Klarer Fokus**: Ein Dialog sollte nur eine einzige Aufgabe oder Information behandeln.
*   **Aktionen**: Die Aktionen sollten klar beschriftet sein. Die destruktive oder gefährlichere Aktion (z.B. "Löschen") sollte oft weniger prominent gestaltet sein (z.B. als `TextButton`) als die sichere Aktion (z.B. "Abbrechen").
*   **Nicht übermäßig verwenden**: Modale Dialoge unterbrechen den Nutzerfluss. Verwenden Sie sie nur, wenn es absolut notwendig ist. Für weniger wichtige Benachrichtigungen sind `SnackBar`s oder Banner oft eine bessere Alternative.
*   **Schließen**: Der Nutzer sollte einen Dialog immer schließen können, entweder durch einen expliziten Button ("Abbrechen", "Schließen") oder durch einen Klick auf den abgedunkelten Hintergrund (Scrim). 