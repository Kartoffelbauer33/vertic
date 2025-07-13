# Components

Komponenten sind die wiederverwendbaren Bausteine unserer Benutzeroberfläche. Sie werden aus den [Foundations](../foundations) (Farben, Textstilen, etc.) zusammengesetzt und bilden die Grundlage für alle Ansichten in der Anwendung.

## Philosophie

*   **Wiederverwendbarkeit**: Erstellen Sie für jedes wiederkehrende UI-Element eine Komponente. Vermeiden Sie das Kopieren und Einfügen von Widget-Bäumen.
*   **Kapselung**: Eine Komponente sollte ihre eigene Logik und ihr eigenes Styling kapseln. Die Aussenwelt interagiert mit ihr nur über eine klar definierte API (Konstruktor-Parameter und Callbacks).
*   **Zustandslosigkeit bevorzugen**: Erstellen Sie Komponenten wann immer möglich als `StatelessWidget`. Logik und Zustandsverwaltung sollten von übergeordneten Widgets oder State-Management-Lösungen gehandhabt werden.
*   **Anpassbarkeit**: Komponenten sollten so flexibel sein, dass sie in verschiedenen Kontexten verwendet werden können, aber so starr, dass sie die Design-Konsistenz wahren.

## Struktur & Speicherort

Alle Design-System-Komponenten werden im Verzeichnis `lib/widgets/design_system/` abgelegt.

```
lib/
└── widgets/
    └── design_system/
        ├── buttons/
        │   ├── primary_button.dart
        │   └── secondary_button.dart
        ├── inputs/
        │   └── custom_text_field.dart
        └── ...
```

## Vorhandene Komponenten

*   **[Buttons](./01_buttons.md)**: Für alle klickbaren Aktionen.
*   **[Eingabefelder (Inputs)](./02_inputs.md)**: Für die Dateneingabe durch den Nutzer.
*   **[Karten (Cards)](./03_cards.md)**: Zur Gruppierung von zusammengehörigen Informationen.
*   **[Dialoge (Dialogs)](./04_dialogs.md)**: Für modale Interaktionen und Benachrichtigungen. 