
# Vertic Design System: Single Source of Truth

## 1. Philosophie & Leitprinzipien

Das Vertic Design System ist das Fundament unserer Benutzeroberflächen. Es ist die **einzige maßgebliche Quelle (Single Source of Truth)** für alle Design-Entscheidungen und UI-Implementierungen in den Vertic-Anwendungen.

**Unsere Ziele sind:**

*   **Konsistenz**: Ein nahtloses und wiedererkennbares Nutzererlebnis über alle Plattformen hinweg.
*   **Effizienz**: Beschleunigung des Entwicklungsprozesses durch eine Bibliothek wiederverwendbarer Komponenten und klarer Richtlinien.
*   **Qualität & Exzellenz**: Sicherstellung höchster Standards in den Bereichen UI, UX, Barrierefreiheit und Code-Qualität.
*   **Wartbarkeit & Skalierbarkeit**: Vereinfachung zukünftiger Design-Anpassungen und Erweiterungen durch zentrale Verwaltung der Design-Token.

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

*   **[Button](./components/01_buttons.md)**: Verschiedene Arten von Schaltflächen und deren Zustände.
*   **[Eingabefelder (Inputs)](./components/02_inputs.md)**: Textfelder, Dropdowns und andere Formularelemente.
*   **[Karten (Cards)](./components/03_cards.md)**: Container für zusammengehörige Inhalte.
*   **[Dialoge & Modals](./components/04_dialogs.md)**: Overlays für Benachrichtigungen und Aktionen.

### 2.3. Patterns (Muster)

Bewährte Lösungen für wiederkehrende Design-Probleme, die festlegen, wie Komponenten in verschiedenen Kontexten zusammenarbeiten.

*   **[Responsives Design](./patterns/01_responsive_design.md)**: Strategien zur Anpassung der UI an verschiedene Bildschirmgrößen.
*   **[Barrierefreiheit (Accessibility)](./patterns/02_accessibility.md)**: Richtlinien zur Sicherstellung, dass die App für alle Nutzer bedienbar ist.

## 3. Implementierungsstrategie: `ThemeExtensions`

Das Herzstück der Implementierung sind Flutter's **`ThemeExtension`s**. Dieser Ansatz ermöglicht uns, ein vollständig typisiertes, skalierbares und zentral verwaltetes Theming-System zu erstellen, das weit über die Standard-`ThemeData` hinausgeht. 