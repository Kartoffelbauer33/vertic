---
trigger: always_on
---

# Vertic Design System: Coding Regeln (AKTUALISIERT)

Diese Regeln sind verbindlich für jede UI-Entwicklung und stellen sicher, dass der Code den im **[Vertic Design System](docs/design/VERTIC_DESIGN_SYSTEM.md)** definierten Standards entspricht.

## 1. Absolute Grundlagen: Keine Ausnahmen

### 1.1. Single Source of Truth für Design-Token

**Verwenden Sie für alle Design-Token (Farben, Textstile, Abstände etc.) AUSSCHLIESSLICH die definierten `ThemeExtension`-Klassen.**

- **Rationale**: Dies ist das Kernprinzip des Systems. Es gewährleistet Konsistenz und ermöglicht globale Design-Änderungen an einer einzigen Stelle.
- **Korrekt**:
  ```dart
  Container(
    color: context.colors.primary,
    padding: context.spacing.pagePadding,
    child: Text(
      'Titel',
      style: context.typography.titleLarge,
    ),
  )
  ```
- **FALSCH**:
  ```dart
  // NIEMALS hartcodierte Werte verwenden!
  Container(
    color: Colors.blue,
    padding: const EdgeInsets.all(16.0),
    child: Text(
      'Titel',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
  )
  ```
- **Detail-Dokumentation**:
  - [Farben](docs/design/foundations/01_colors.md)
  - [Typografie](docs/design/foundations/02_typography.md)
  - [Abstände & Layout](docs/design/foundations/03_spacing_and_layout.md)

### 1.2. Vertic-Komponenten vor Standard-Flutter-Widgets

**Erstellen Sie keine einmaligen Widgets für gängige UI-Elemente. Nutzen Sie die vordefinierten Komponenten aus dem Design-System.**

- **Rationale**: Vermeidet redundanten Code und stellt sicher, dass alle Instanzen eines Elementtyps (z.B. alle primären Buttons) identisch aussehen und sich identisch verhalten.
- **Korrekt**:
  ```dart
  PrimaryButton(text: 'Speichern', onPressed: () {})
  VerticInput(label: 'E-Mail', type: VerticInputType.email)
  VerticChip(label: 'Filter', variant: VerticChipVariant.filled)
  ```
- **FALSCH**:
  ```dart
  ElevatedButton(child: Text('Speichern'), onPressed: () {})
  TextField(decoration: InputDecoration(labelText: 'E-Mail'))
  ```
- **Detail-Dokumentation**:
  - [Buttons](docs/design/components/01_buttons.md)
  - [Eingabefelder](docs/design/components/02_inputs.md)
  - [Chips & Badges](docs/design/components/05_chips_badges.md)

### 1.3. Theme-Extensions verwenden

**Nutzen Sie die praktischen BuildContext-Extensions für Theme-Zugriff:**

```dart
// Theme-Zugriff über Extensions
final colors = context.colors;
final spacing = context.spacing;
final typography = context.typography;
final shadows = context.shadows;
final animations = context.animations;

// Responsive Helpers
if (context.isCompact) {
  return Column(children: widgets);
}
return Row(children: widgets);
```

## 2. Transparente Input-Felder (GELÖST)

**Problem**: Input-Felder hatten graue Hintergründe die das Design störten.
**Lösung**: Das globale Theme wurde angepasst:

```dart
// In vertic_theme.dart
inputDecorationTheme: InputDecorationTheme(
  filled: false,
  fillColor: Colors.transparent,
  // ...
),
```

**Resultat**: ALLE Input-Komponenten (TextField, DropdownButton, etc.) sind jetzt transparent - für ein reduziertes, sauberes Design.

## 3. Responsivität & Barrierefreiheit (Standardmäßig)

Jede neue Komponente und jede neue Seite **MUSS** von Grund auf responsiv und barrierefrei sein.

### 3.1. Responsives Layout

- **Keine festen Breiten/Höhen**: Vermeiden Sie `width: 300`. Nutzen Sie `Expanded`, `Flexible` und `LayoutBuilder`.
- **Breakpoint-Logik**: Verwenden Sie responsive Helper für strukturelle Änderungen.

  ```dart
  // Fluid-First Ansatz
  Row(
    children: [
      Expanded(child: leftContent),
      Expanded(child: rightContent),
    ],
  )

  // Adaptive Anpassung bei Bedarf
  if (context.isCompact) {
    return Column(children: [leftContent, rightContent]);
  }
  ```

- **Detail-Dokumentation**: [Responsives Design](docs/design/patterns/01_responsive_design.md)

### 3.2. Barrierefreiheit (A11y)

- **Labels für alles Interaktive**: `IconButton`s benötigen `tooltip`s. Bilder benötigen semantische Labels.
  ```dart
  VerticIconButton(
    icon: Icons.settings,
    tooltip: 'Einstellungen',
    onPressed: () {},
  )
  ```
- **Mindest-Touch-Größe**: Interaktive Elemente müssen mindestens 48x48dp groß sein.
- **Fokus-Management**: Stellen Sie sicher, dass die Tastaturnavigation logisch ist.
- **Detail-Dokumentation**: [Barrierefreiheit](docs/design/patterns/02_accessibility.md)

## 4. Komponenten-Hierarchie & Architektur

### 4.1. Button-System

```
VerticButton (Basis)
├── PrimaryButton
├── SecondaryButton
├── DestructiveButton
├── VerticOutlineButton (ehemals OutlineButton)
├── GhostButton
├── LinkButton
└── VerticIconButton
```

### 4.2. Input-System

```
VerticInput (Basis)
├── VerticTextField
├── VerticDropdown
├── VerticCheckbox
└── VerticSwitch
```

### 4.3. Chip & Badge System

```
VerticChip (Basis)
├── VerticFilterChip
└── VerticActionChip

VerticBadge (Basis)
├── VerticStatusBadge
└── VerticNotificationBadge
```

## 5. Neue Komponenten-Kategorien

### 5.1. Progress & Loading

- **VerticProgressIndicator**: Linear und circular mit verschiedenen Größen
- **VerticLoadingIndicator**: Vollständige Loading-Komponente mit Nachricht
- **VerticSkeletonLoader**: Platzhalter für ladende Inhalte

### 5.2. Chips & Badges

- **VerticChip**: Interaktive Tags und Filter
- **VerticFilterChip**: Toggle-fähige Filter-Chips
- **VerticBadge**: Notification-Badges mit Zahlen
- **VerticStatusBadge**: Status-Anzeigen mit semantischen Farben

## 6. Theme-System Updates

### 6.1. Neue Theme-Extensions

```dart
// Vollständige Theme-Extensions
AppColorsTheme     // Alle Farben (Light/Dark)
AppTypographyTheme // Alle Textstile
AppSpacingTheme    // Abstände, Radien, Dimensionen
AppShadowsTheme    // Schatten & Elevation
AppAnimationsTheme // Animationsdauern & Kurven
```

### 6.2. Theme Provider für manuelles Switching

```dart
// Globaler ThemeProvider für Dark/Light Mode Toggle
ChangeNotifierProvider(
  create: (_) => ThemeProvider(),
  child: Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      return MaterialApp(
        themeMode: themeProvider.themeMode,
        theme: VerticTheme.light(),
        darkTheme: VerticTheme.dark(),
        // ...
      );
    },
  ),
)
```

## 7. Quick-Reference (AKTUALISIERT)

| Thema                  | Regel                                                         | Dokumentation                                               |
| ---------------------- | ------------------------------------------------------------- | ----------------------------------------------------------- |
| **Farben**             | `context.colors` verwenden                                    | [Link](docs/design/foundations/01_colors.md)                |
| **Texte**              | `context.typography` verwenden, mit `.copyWith()` anpassen    | [Link](docs/design/foundations/02_typography.md)            |
| **Abstände**           | `context.spacing` für `padding`, `SizedBox`                   | [Link](docs/design/foundations/03_spacing_and_layout.md)    |
| **Schatten**           | `context.shadows` verwenden                                   | [Link](docs/design/foundations/05_shadows_and_elevation.md) |
| **Animationen**        | `context.animations` für `duration` und `curve`               | [Link](docs/design/foundations/06_animations.md)            |
| **Buttons**            | `PrimaryButton`, `SecondaryButton` etc. verwenden             | [Link](docs/design/components/01_buttons.md)                |
| **Inputs**             | `VerticInput` verwenden (transparent by default)              | [Link](docs/design/components/02_inputs.md)                 |
| **Chips & Badges**     | `VerticChip`, `VerticBadge` Komponenten verwenden             | [Link](docs/design/components/05_chips_badges.md)           |
| **Progress & Loading** | `VerticProgressIndicator`, `VerticLoadingIndicator` verwenden | [Link](docs/design/components/06_progress_loading.md)       |
| **Responsivität**      | `context.isCompact`, `LayoutBuilder` verwenden                | [Link](docs/design/patterns/01_responsive_design.md)        |
| **Barrierefreiheit**   | Semantik, Fokus und Touch-Ziele sicherstellen                 | [Link](docs/design/patterns/02_accessibility.md)            |
| **Implementation**     | Vollständiger Workflow für Design-Umsetzung                   | [Link](docs/design/VERTIC_DESIGN_IMPLEMENTATION_GUIDE.md)   |
| **Hauptdokumentation** | -                                                             | [Link](docs/design/VERTIC_DESIGN_SYSTEM.md)                 |

## 8. Code-Review Checkliste

### 8.1. Theme-Compliance

- [ ] Keine hartcodierten Werte (Farben, Abstände, Typografie)
- [ ] Korrekte Theme-Zugriffe über `context.colors`, `context.spacing`, etc.
- [ ] Responsive Helpers verwendet (`context.isCompact`, etc.)
- [ ] Semantische Namensgebung (primary, error vs. blue, red)

### 8.2. Komponenten-Architektur

- [ ] Vertic-Komponenten vor Standard-Flutter-Widgets bevorzugt
- [ ] Konsistente API-Parameter
- [ ] Enum-basierte Varianten für verschiedene Stile
- [ ] Korrekte State-Management-Patterns

### 8.3. Responsive & Accessibility

- [ ] Flexible Layouts (`Expanded`, `Flexible`, `Wrap`)
- [ ] Touch-Ziele mindestens 48x48dp
- [ ] Semantische Labels für alle interaktiven Elemente
- [ ] WCAG AA-konformer Kontrast
- [ ] Tastaturnavigation funktional

### 8.4. Performance

- [ ] `const` Constructors wo möglich
- [ ] Effiziente Widget-Rebuilds
- [ ] Lazy Loading für große Listen
- [ ] Optimierte Bilder und Assets

## 9. Anti-Patterns vermeiden

### 9.1. Theme-Verstöße

```dart
// ❌ VERBOTEN
Container(
  color: Color(0xFF007AFF),
  padding: EdgeInsets.all(16.0),
)

// ✅ KORREKT
Container(
  color: context.colors.primary,
  padding: context.spacing.cardPadding,
)
```

### 9.2. Responsive-Verstöße

```dart
// ❌ VERBOTEN
Container(width: 300, child: content)

// ✅ KORREKT
Expanded(child: content)
```

### 9.3. Accessibility-Verstöße

```dart
// ❌ VERBOTEN
IconButton(icon: Icon(Icons.settings), onPressed: () {})

// ✅ KORREKT
VerticIconButton(
  icon: Icons.settings,
  tooltip: 'Einstellungen',
  onPressed: () {},
)
```

---

**Diese Regeln sind verbindlich und werden kontinuierlich mit dem Design-System weiterentwickelt.**

| **Barrierefreiheit** | Semantik, Fokus und Touch-Ziele sicherstellen | [Link](mdc:docs/design/patterns/02_accessibility.md) |
| **Hauptdokumentation** | - | [Link](mdc:docs/design/VERTIC_DESIGN_SYSTEM.md) |
