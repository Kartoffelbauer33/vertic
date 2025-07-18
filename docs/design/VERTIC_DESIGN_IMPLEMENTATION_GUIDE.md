# Vertic Design Implementation Guide

Dieser Guide definiert **verbindliche Regeln und Workflows** für die Umsetzung von Designs in der Vertic-Anwendung. Er stellt sicher, dass alle UI-Entwicklungen konsistent, wartbar und dem Design-System entsprechend umgesetzt werden.

## 1. Grundprinzipien (Nicht verhandelbar)

### 1.1. Single Source of Truth
**REGEL:** Alle Design-Token (Farben, Abstände, Typografie, etc.) werden AUSSCHLIESSLICH über das Theme-System verwaltet.

```dart
// ✅ KORREKT
Container(
  color: context.colors.primary,
  padding: context.spacing.pagePadding,
  child: Text('Titel', style: context.typography.titleLarge),
)

// ❌ VERBOTEN
Container(
  color: Colors.blue,
  padding: EdgeInsets.all(16.0),
  child: Text('Titel', style: TextStyle(fontSize: 24)),
)
```

### 1.2. Komponenten-First Ansatz
**REGEL:** Verwenden Sie IMMER vordefinierte Vertic-Komponenten vor Standard-Flutter-Widgets.

```dart
// ✅ KORREKT
PrimaryButton(text: 'Speichern', onPressed: () {})
VerticInput(label: 'E-Mail', type: VerticInputType.email)

// ❌ VERBOTEN (außer wenn keine Vertic-Alternative existiert)
ElevatedButton(child: Text('Speichern'), onPressed: () {})
TextField(decoration: InputDecoration(labelText: 'E-Mail'))
```

### 1.3. Responsive-First Design
**REGEL:** Jede neue Komponente und Seite MUSS von Grund auf responsiv sein.

```dart
// ✅ KORREKT - Flexibles Layout
Row(
  children: [
    Expanded(child: leftContent),
    Expanded(child: rightContent),
  ],
)

// ✅ KORREKT - Adaptive Anpassung
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

// ❌ VERBOTEN - Feste Breiten
Container(width: 300, child: content)
```

### 1.4. Accessibility-First
**REGEL:** Barrierefreiheit ist KEIN nachträglicher Add-on, sondern von Anfang an integriert.

```dart
// ✅ KORREKT
VerticIconButton(
  icon: Icons.settings,
  tooltip: 'Einstellungen',
  onPressed: () {},
)

// ✅ KORREKT
Semantics(
  label: 'Bewertung: 4 von 5 Sternen',
  child: StarRating(rating: 4),
)
```

## 2. Design-zu-Code Workflow

### 2.1. Phase 1: Design-Analyse

**Vor jeder Implementierung:**

1. **Design-Token identifizieren**
   - Welche Farben werden verwendet? (Sind sie im Theme vorhanden?)
   - Welche Abstände/Spacing? (Entsprechen sie unserem 4dp-Grid?)
   - Welche Typografie? (Ist der Stil im Theme definiert?)

2. **Komponenten-Mapping**
   - Welche Vertic-Komponenten können verwendet werden?
   - Müssen neue Komponenten erstellt werden?
   - Können bestehende Komponenten erweitert werden?

3. **Responsive Verhalten definieren**
   - Wie verhält sich das Layout auf verschiedenen Bildschirmgrößen?
   - Wo sind Breakpoints nötig?
   - Welche Inhalte können sich anpassen vs. umstrukturieren?

### 2.2. Phase 2: Theme-Erweiterung (falls nötig)

**Wenn neue Design-Token benötigt werden:**

```dart
// 1. Neue Farbe in AppColorsTheme hinzufügen
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  final Color newSemanticColor;
  
  // In light() und dark() factories hinzufügen
  factory AppColorsTheme.light() {
    return const AppColorsTheme._(
      newSemanticColor: Color(0xFF...), // Light-Variante
      // ...
    );
  }
}

// 2. Neue Abstände in AppSpacingTheme
class AppSpacingTheme extends ThemeExtension<AppSpacingTheme> {
  final EdgeInsets newSemanticPadding;
  // ...
}

// 3. Neue Typografie in AppTypographyTheme
class AppTypographyTheme extends ThemeExtension<AppTypographyTheme> {
  final TextStyle newSemanticStyle;
  // ...
}
```

### 2.3. Phase 3: Komponenten-Entwicklung

**Neue Komponenten folgen diesem Template:**

```dart
// lib/design_system/components/new_component.dart

import 'package:flutter/material.dart';
import '../theme_extensions.dart';

enum NewComponentVariant { primary, secondary }
enum NewComponentSize { small, medium, large }

class NewComponent extends StatelessWidget {
  final String text;
  final NewComponentVariant variant;
  final NewComponentSize size;
  final VoidCallback? onPressed;
  final bool isDisabled;
  
  const NewComponent({
    super.key,
    required this.text,
    this.variant = NewComponentVariant.primary,
    this.size = NewComponentSize.medium,
    this.onPressed,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    // Theme-Zugriff über Extensions
    final colors = context.colors;
    final typography = context.typography;
    final spacing = context.spacing;
    final animations = context.animations;
    
    // Responsive Verhalten
    final isCompact = context.isCompact;
    
    // Variant-basiertes Styling
    final backgroundColor = _getBackgroundColor(colors);
    final textColor = _getTextColor(colors);
    final padding = _getPadding(spacing);
    
    return AnimatedContainer(
      duration: animations.short,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(spacing.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          child: Padding(
            padding: spacing.buttonPadding,
            child: Text(
              text,
              style: typography.labelMedium.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getBackgroundColor(AppColorsTheme colors) {
    if (isDisabled) return colors.surfaceVariant;
    
    switch (variant) {
      case NewComponentVariant.primary:
        return colors.primary;
      case NewComponentVariant.secondary:
        return colors.secondary;
    }
  }
  
  // Weitere Helper-Methoden...
}
```

### 2.4. Phase 4: Integration & Export

```dart
// 1. In design_system.dart exportieren
export 'components/new_component.dart';

// 2. In Showcase-App integrieren
Widget _buildNewComponentTab() {
  return SingleChildScrollView(
    padding: context.spacing.pagePadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('New Component'),
        SizedBox(height: context.spacing.md),
        
        // Alle Varianten zeigen
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: [
            NewComponent(text: 'Primary', variant: NewComponentVariant.primary),
            NewComponent(text: 'Secondary', variant: NewComponentVariant.secondary),
            NewComponent(text: 'Disabled', isDisabled: true),
          ],
        ),
      ],
    ),
  );
}
```

## 3. Code-Review Checkliste

### 3.1. Theme-Compliance

- [ ] **Keine hartcodierten Werte**: Alle Farben, Abstände, Typografie über Theme-Extensions
- [ ] **Korrekte Theme-Zugriffe**: `context.colors`, `context.spacing`, etc.
- [ ] **Responsive Helpers**: `context.isCompact`, `context.isTablet`, etc. verwendet
- [ ] **Semantic Naming**: Farben nach Zweck benannt (primary, error), nicht nach Aussehen (blue, red)

### 3.2. Komponenten-Architektur

- [ ] **Vertic-Komponenten bevorzugt**: Standard-Flutter-Widgets nur wenn nötig
- [ ] **Konsistente API**: Parameter-Namen folgen etablierten Patterns
- [ ] **Variant-System**: Enum-basierte Varianten für verschiedene Stile
- [ ] **State-Management**: Zustand korrekt über StatefulWidget oder Provider

### 3.3. Responsive Design

- [ ] **Flexible Layouts**: `Expanded`, `Flexible`, `Wrap` statt fester Größen
- [ ] **Breakpoint-Logik**: `LayoutBuilder` für strukturelle Änderungen
- [ ] **Touch-Ziele**: Mindestens 48x48dp für interaktive Elemente
- [ ] **Text-Skalierung**: Layout bricht nicht bei vergrößerter Schrift

### 3.4. Accessibility

- [ ] **Semantische Labels**: Alle interaktiven Elemente haben Labels/Tooltips
- [ ] **Kontrast**: WCAG AA-konform (4.5:1 für normalen Text)
- [ ] **Tastaturnavigation**: Vollständig per Tastatur bedienbar
- [ ] **Screen Reader**: Komponenten werden korrekt vorgelesen

### 3.5. Performance

- [ ] **Const Constructors**: Wo möglich für bessere Performance
- [ ] **Efficient Rebuilds**: Minimale Widget-Rebuilds durch korrekte State-Struktur
- [ ] **Lazy Loading**: Listen verwenden `ListView.builder` bei vielen Items
- [ ] **Image Optimization**: Bilder in angemessener Auflösung und Format

## 4. Häufige Anti-Patterns vermeiden

### 4.1. Theme-Verstöße

```dart
// ❌ ANTI-PATTERN: Hartcodierte Werte
Container(
  color: Color(0xFF007AFF),
  padding: EdgeInsets.all(16.0),
  margin: EdgeInsets.symmetric(horizontal: 24.0),
)

// ✅ KORREKT: Theme-basiert
Container(
  color: context.colors.primary,
  padding: context.spacing.cardPadding,
  margin: EdgeInsets.symmetric(horizontal: context.spacing.lg),
)
```

### 4.2. Responsive Anti-Patterns

```dart
// ❌ ANTI-PATTERN: Feste Breiten
Container(
  width: 300,
  child: Column(children: [...]),
)

// ❌ ANTI-PATTERN: MediaQuery-Abuse
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth < 600) {
    return MobileLayout();
  } else if (screenWidth < 1200) {
    return TabletLayout();
  } else {
    return DesktopLayout();
  }
}

// ✅ KORREKT: Flexible Layouts mit Helper
Widget build(BuildContext context) {
  if (context.isCompact) {
    return Column(children: widgets);
  }
  return Row(children: widgets.map((w) => Expanded(child: w)).toList());
}
```

### 4.3. Accessibility Anti-Patterns

```dart
// ❌ ANTI-PATTERN: Icon ohne Label
IconButton(
  icon: Icon(Icons.settings),
  onPressed: () {},
)

// ❌ ANTI-PATTERN: Zu kleine Touch-Ziele
GestureDetector(
  onTap: () {},
  child: Container(
    width: 20,
    height: 20,
    child: Icon(Icons.close),
  ),
)

// ✅ KORREKT: Accessibility-konform
VerticIconButton(
  icon: Icons.settings,
  tooltip: 'Einstellungen',
  onPressed: () {},
)
```

## 5. Maintenance & Updates

### 5.1. Design-System Updates

**Workflow für Theme-Änderungen:**

1. **Analyse**: Welche Komponenten sind betroffen?
2. **Update**: Theme-Extensions anpassen
3. **Test**: Showcase-App und alle betroffenen Seiten testen
4. **Dokumentation**: Änderungen dokumentieren
5. **Migration**: Breaking Changes kommunizieren

### 5.2. Neue Komponenten

**Checkliste für neue Komponenten:**

1. **Design Review**: Entspricht das Design den Vertic-Standards?
2. **API Design**: Ist die Komponenten-API konsistent und intuitiv?
3. **Implementation**: Folgt der Code den etablierten Patterns?
4. **Testing**: Alle Zustände und Varianten getestet?
5. **Documentation**: Vollständige Dokumentation erstellt?
6. **Showcase**: In Design-System-Showcase integriert?

### 5.3. Refactoring

**Regelmäßige Wartungsaufgaben:**

- **Theme-Audit**: Überprüfung auf hartcodierte Werte
- **Komponenten-Audit**: Veraltete oder redundante Komponenten identifizieren
- **Performance-Audit**: Ineffiziente Patterns aufspüren
- **Accessibility-Audit**: Barrierefreiheit-Standards überprüfen

## 6. Tools & Automation

### 6.1. Linting Rules

```yaml
# analysis_options.yaml
linter:
  rules:
    # Design System Enforcement
    - avoid_print
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - sized_box_for_whitespace
    - sort_child_properties_last
    
    # Accessibility
    - use_build_context_synchronously
    - avoid_web_libraries_in_flutter
```

### 6.2. Code Generation

```dart
// Script für neue Komponenten generieren
// tools/generate_component.dart

void generateComponent(String componentName) {
  final template = '''
class $componentName extends StatelessWidget {
  const $componentName({super.key});
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    
    return Container(
      // Implementation...
    );
  }
}
''';
  
  // Template in Datei schreiben...
}
```

### 6.3. Visual Regression Testing

```dart
// test/design_system_test.dart
void main() {
  group('Design System Components', () {
    testWidgets('PrimaryButton renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VerticTheme.light(),
          home: Scaffold(
            body: PrimaryButton(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );
      
      expect(find.text('Test Button'), findsOneWidget);
      // Weitere Assertions...
    });
  });
}
```

---

**Dieser Guide ist verbindlich für alle UI-Entwicklungen in der Vertic-Anwendung und wird kontinuierlich weiterentwickelt.** 