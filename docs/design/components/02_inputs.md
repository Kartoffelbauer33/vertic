# Components: Eingabefelder (Inputs)

Eingabefelder sind entscheidend für die Interaktion mit dem Nutzer und das Sammeln von Daten. Ein konsistentes Design für alle Formularelemente ist daher von großer Bedeutung.

## 1. `CustomTextField`

Wir erstellen eine zentrale Komponente `CustomTextField`, die als Wrapper um das `TextFormField` von Flutter dient. Dieser Wrapper vereinheitlicht das Styling und die Handhabung von Labels, Fehlermeldungen und Icons.

## 2. Implementierung

Das `CustomTextField`-Widget sollte flexibel sein, um verschiedene Anwendungsfälle (normaler Text, Passwort, E-Mail) abzudecken.

```dart
/// lib/widgets/design_system/inputs/custom_text_field.dart

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final texts = Theme.of(context).appTexts;
    final dimensions = Theme.of(context).appDimensions;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: texts.body,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        
        // Styling aus dem Design System
        labelStyle: texts.body.copyWith(color: colors.textSubtle),
        hintStyle: texts.body.copyWith(color: colors.textSubtle.withOpacity(0.5)),
        errorStyle: texts.caption.copyWith(color: colors.error),
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(dimensions.radiusDefault),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(dimensions.radiusDefault),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(dimensions.radiusDefault),
          borderSide: BorderSide(color: colors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(dimensions.radiusDefault),
          borderSide: BorderSide(color: colors.error, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(dimensions.radiusDefault),
          borderSide: BorderSide(color: colors.error, width: 2.0),
        ),
        
        contentPadding: EdgeInsets.symmetric(
          vertical: dimensions.spacingS,
          horizontal: dimensions.spacingM,
        ),
      ),
    );
  }
}
```

## 3. Zustände und Validierung

*   **`Label`**: Ein kurzer Text, der beschreibt, welche Eingabe erwartet wird. Er schwebt oft über dem Feld, wenn es fokussiert wird.
*   **`Placeholder`/`Hint`**: Ein Beispieltext im Feld, der verschwindet, sobald der Nutzer zu tippen beginnt.
*   **Zustände**:
    *   **`Normal`**: Standardzustand.
    *   **`Focus`**: Wenn der Nutzer in das Feld geklickt hat. Der Rahmen wird oft in der Primärfarbe hervorgehoben.
    *   **`Disabled`**: Das Feld ist ausgegraut und kann nicht bearbeitet werden.
    *   **`Error`**: Wenn die Eingabe ungültig ist. Der Rahmen wird rot gefärbt und eine `errorText`-Nachricht wird unter dem Feld angezeigt.
*   **Validierung**: Die `validator`-Eigenschaft wird verwendet, um die Eingabe zu überprüfen und bei Bedarf den `errorText` zu erzeugen. Die Validierung sollte immer sowohl auf dem Client (für sofortiges Feedback) als auch auf dem Server (aus Sicherheitsgründen) stattfinden.

## 4. Andere Formularelemente

Neben Textfeldern umfasst das Design-System auch andere Formularelemente:

*   **`DropdownButton`**: Für die Auswahl aus einer vordefinierten Liste.
*   **`Checkbox` / `Switch`**: Für boolesche Ja/Nein-Entscheidungen.
*   **`Radio`**: Für die Auswahl einer einzigen Option aus einer kleinen Gruppe.

All diese Komponenten sollten ebenfalls als wiederverwendbare Widgets mit einem einheitlichen Styling, das auf den `ThemeExtension`s basiert, erstellt werden. 