
# Vertic Design System: Single Source of Truth

## 1. Philosophie & Leitprinzipien

Das Vertic Design System ist das Fundament unserer Benutzeroberflächen. Es ist die **einzige maßgebliche Quelle (Single Source of Truth)** für alle Design-Entscheidungen und UI-Implementierungen in den Vertic-Anwendungen.

**Unsere Ziele sind:**

*   **Konsistenz**: Ein nahtloses und wiedererkennbares Nutzererlebnis über alle Plattformen hinweg.
*   **Effizienz**: Beschleunigung des Entwicklungsprozesses durch eine Bibliothek wiederverwendbarer Komponenten und klarer Richtlinien.
*   **Qualität & Exzellenz**: Sicherstellung höchster Standards in den Bereichen UI, UX, Barrierefreiheit und Code-Qualität.
*   **Wartbarkeit & Skalierbarkeit**: Vereinfachung zukünftiger Design-Änderungen und Erweiterungen durch zentrale Verwaltung der Design-Token.

## 2. Struktur des Design-Systems

Unser System ist in drei logische Bereiche unterteilt, die auf den Prinzipien des Atomic Design aufbauen:

### 2.1. Foundations (Grundlagen)

Die unteilbaren, grundlegenden Bausteine unserer UI. Sie definieren das grundlegende Erscheinungsbild.

*   **[Farben](./foundations/01_colors.md)**: Definition der Farbpalette, semantische Zuordnung und Theming für Light- & Dark-Mode.
*   **[Typografie](./foundations/02_typography.md)**: Schriftarten, Schriftgrößen, Schriftschnitte und Textstile für eine klare Hierarchie.
*   **[Abstände & Layout](./foundations/03_spacing_and_layout.md)**: Konsistente Abstände, Ränder, Raster und Layout-Regeln.
*   **[Ikonografie](./foundations/04_iconography.md)**: Richtlinien zur Verwendung und Verwaltung von Icons.
*   **[Schatten & Erhöhung](./foundations/05_shadows_and_elevation.md)**: Standardisierte Schatten für eine konsistente Tiefenwirkung.
*   **[Animationen](./foundations/06_animations.md)**: Prinzipien für Animationen und Übergänge.

### 2.2. Components (Komponenten)

Wiederverwendbare UI-Elemente, die aus den Grundlagen zusammengesetzt sind. Sie sind die Bausteine für komplexere Ansichten.

*   **[Buttons](./components/01_buttons.md)**: Verschiedene Arten von Schaltflächen und deren Zustände.
*   **[Eingabefelder (Inputs)](./components/02_inputs.md)**: Textfelder, Dropdowns und andere Formularelemente.
*   **[Karten (Cards)](./components/03_cards.md)**: Container für zusammengehörige Inhalte.
*   **[Chips & Badges](./components/05_chips_badges.md)**: Kompakte Informations- und Aktionselemente.
*   **[Progress & Loading](./components/06_progress_loading.md)**: Fortschrittsanzeigen und Ladezustände.

### 2.3. Patterns (Muster)

Bewährte Lösungen für wiederkehrende Design-Probleme, die festlegen, wie Komponenten in verschiedenen Kontexten zusammenarbeiten.

*   **[Responsives Design](./patterns/01_responsive_design.md)**: Strategien zur Anpassung der UI an verschiedene Bildschirmgrößen.
*   **[Barrierefreiheit (Accessibility)](./patterns/02_accessibility.md)**: Richtlinien zur Sicherstellung, dass die App für alle Nutzer bedienbar ist.

## 3. Implementierungsstrategie: `ThemeExtensions`

Das Herzstück der Implementierung sind Flutter's **`ThemeExtension`s**. Dieser Ansatz ermöglicht uns, ein vollständig typisiertes, skalierbares und zentral verwaltetes Theming-System zu erstellen, das weit über die Standard-`ThemeData` hinausgeht.

### 3.1. Zentrale Theme-Extensions

```dart
// lib/design_system/foundations/
AppColorsTheme     // Alle Farben (Light/Dark)
AppTypographyTheme // Alle Textstile
AppSpacingTheme    // Abstände, Radien, Dimensionen
AppShadowsTheme    // Schatten & Elevation
AppAnimationsTheme // Animationsdauern & Kurven
```

### 3.2. Zugriff über Theme-Extensions

```dart
// Korrekte Verwendung - über Theme-Extensions
Container(
  color: context.colors.primary,
  padding: context.spacing.pagePadding,
  child: Text(
    'Titel',
    style: context.typography.titleLarge,
  ),
)

// FALSCH - Hartcodierte Werte
Container(
  color: Colors.blue,
  padding: EdgeInsets.all(16.0),
  child: Text(
    'Titel',
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  ),
)
```

### 3.3. Praktische Helper-Extensions

```dart
// lib/design_system/theme_extensions.dart
extension VerticBuildContextExtensions on BuildContext {
  AppColorsTheme get colors => Theme.of(this).extension<AppColorsTheme>()!;
  AppTypographyTheme get typography => Theme.of(this).extension<AppTypographyTheme>()!;
  AppSpacingTheme get spacing => Theme.of(this).extension<AppSpacingTheme>()!;
  AppShadowsTheme get shadows => Theme.of(this).extension<AppShadowsTheme>()!;
  AppAnimationsTheme get animations => Theme.of(this).extension<AppAnimationsTheme>()!;
  
  // Responsive Helpers
  bool get isCompact => MediaQuery.of(this).size.width < 600;
  bool get isTablet => MediaQuery.of(this).size.width >= 600 && MediaQuery.of(this).size.width < 1200;
  bool get isDesktop => MediaQuery.of(this).size.width >= 1200;
}
```

## 4. Vertic Theme-Konfiguration

### 4.1. Globales Theme (vertic_theme.dart)

Das globale Theme wird in `lib/design_system/vertic_theme.dart` definiert und konfiguriert sowohl Material Design 3 als auch unsere eigenen Extensions:

```dart
class VerticTheme {
  static ThemeData light(BuildContext context) {
    final colors = AppColorsTheme.light();
    final typography = AppTypographyTheme.main(screenWidth);
    final spacing = AppSpacingTheme.main(screenWidth);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: _buildColorScheme(colors),
      textTheme: _buildTextTheme(typography),
      
      // WICHTIG: Input-Felder transparent
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: Colors.transparent,
        // ... weitere Konfiguration
      ),
      
      extensions: [colors, typography, spacing, shadows, animations],
    );
  }
}
```

### 4.2. Transparente Input-Felder

**Problem gelöst:** Input-Felder waren grau hinterlegt.
**Lösung:** `filled: false` und `fillColor: Colors.transparent` im globalen `inputDecorationTheme`.

Dies betrifft ALLE Input-Komponenten (TextField, DropdownButton, etc.) und sorgt für ein reduziertes, sauberes Design.

## 5. Komponenten-Architektur

### 5.1. Vertic-Komponenten vs. Standard-Flutter-Widgets

```dart
// Vertic-Komponenten (bevorzugt)
PrimaryButton(text: 'Speichern', onPressed: () {})
VerticInput(label: 'E-Mail', type: VerticInputType.email)
VerticChip(label: 'Filter', variant: VerticChipVariant.filled)

// Standard-Flutter (nur wenn nötig)
TextField(decoration: InputDecoration(...))
ElevatedButton(child: Text('Button'), onPressed: () {})
```

### 5.2. Komponenten-Hierarchie

```
VerticButton (Basis)
├── PrimaryButton
├── SecondaryButton  
├── DestructiveButton
├── VerticOutlineButton
├── GhostButton
├── LinkButton
└── VerticIconButton
```

## 6. Design-Token-System

### 6.1. Farbsystem

```dart
// Semantische Farben (nicht visuelle!)
colors.primary          // Hauptaktionen
colors.secondary        // Sekundäre Aktionen  
colors.success          // Erfolgsmeldungen
colors.warning          // Warnungen
colors.error           // Fehler
colors.surface         // Kartenhintergründe
colors.background      // Seitenhintergrund
colors.outline         // Rahmenlinien
```

### 6.2. Spacing-System

```dart
// Basis-Spacing (4dp-Grid)
spacing.xs    // 4dp
spacing.sm    // 8dp  
spacing.md    // 16dp
spacing.lg    // 24dp
spacing.xl    // 32dp
spacing.xxl   // 48dp

// Semantische Abstände
spacing.pagePadding    // Seitenränder
spacing.cardPadding    // Karten-Innenabstand
spacing.buttonPadding  // Button-Innenabstand
```

### 6.3. Typografie-Hierarchie

```dart
// Material Design 3 kompatibel
typography.displayLarge    // Große Überschriften
typography.headlineMedium  // Sektionsüberschriften
typography.titleLarge      // Kartentitel
typography.bodyMedium      // Standardtext
typography.labelMedium     // Button-Text
```

## 7. Responsive Design-Prinzipien

### 7.1. Fluid-First Ansatz

```dart
// Flexibles Layout (bevorzugt)
Row(
  children: [
    Expanded(child: leftContent),
    Expanded(child: rightContent),
  ],
)

// Adaptive Anpassungen bei Bedarf
LayoutBuilder(
  builder: (context, constraints) {
    if (context.isCompact) {
      return Column(children: [leftContent, rightContent]);
    }
    return Row(children: [
      Expanded(child: leftContent),
      Expanded(child: rightContent),
    ]);
  },
)
```

### 7.2. Breakpoints

```dart
// Responsive Helper
bool get isCompact => width < 600;   // Smartphone
bool get isTablet => width < 1200;   // Tablet  
bool get isDesktop => width >= 1200; // Desktop
```

## 8. Barrierefreiheit (A11y)

### 8.1. Mindestanforderungen

- **Touch-Ziele**: Mindestens 48x48dp für interaktive Elemente
- **Kontrast**: WCAG AA-konform (4.5:1 für normalen Text)
- **Semantik**: Alle interaktiven Elemente haben Labels/Tooltips
- **Tastaturnavigation**: Vollständig per Tastatur bedienbar

### 8.2. Implementierung

```dart
// Icon-Buttons mit Tooltip
VerticIconButton(
  icon: Icons.settings,
  tooltip: 'Einstellungen',
  onPressed: () {},
)

// Semantische Labels
Semantics(
  label: 'Bewertung: 4 von 5 Sternen',
  child: StarRating(rating: 4),
)
```

## 9. Zukünftige Entwicklung & Wartung

### 9.1. Design-System Updates

1. **Zentrale Änderungen**: Alle Design-Updates erfolgen in den Foundation-Klassen
2. **Automatische Propagation**: Änderungen werden automatisch in alle Komponenten übernommen
3. **Versionierung**: Design-System-Versionen werden dokumentiert
4. **Testing**: Visuelle Regression-Tests für alle Komponenten

### 9.2. Neue Komponenten

1. **Design Review**: Neue Komponenten werden zuerst im Design-System definiert
2. **Implementation**: Komponenten folgen den etablierten Patterns
3. **Documentation**: Vollständige Dokumentation mit Beispielen
4. **Showcase**: Integration in die Design-System-Showcase-App

### 9.3. Code-Review-Checkliste

- [ ] Verwendung von Theme-Extensions statt hartcodierter Werte
- [ ] Responsive Design implementiert
- [ ] Barrierefreiheit berücksichtigt
- [ ] Konsistente Namensgebung
- [ ] Dokumentation aktualisiert

## 10. Tools & Resources

### 10.1. Design-System-Showcase

Die Showcase-App (`pages/design_system_showcase_page.dart`) dient als:
- **Dokumentation**: Visuelle Übersicht aller Komponenten
- **Testing**: Manuelle Tests für alle Zustände
- **Entwicklung**: Playground für neue Komponenten

### 10.2. Theme-Debugging

```dart
// Debug-Helper für Theme-Werte
void debugTheme(BuildContext context) {
  print('Primary Color: ${context.colors.primary}');
  print('Page Padding: ${context.spacing.pagePadding}');
  print('Title Style: ${context.typography.titleLarge}');
}
```

---

**Dieses Design-System ist ein lebendiges Dokument und wird kontinuierlich weiterentwickelt, um den Anforderungen der Vertic-Anwendungen gerecht zu werden.** 