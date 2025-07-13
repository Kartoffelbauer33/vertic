# Patterns: Responsives Design

Ein responsives Design in Vertic ist **standardmäßig fließend ("fluid")**. Unsere UI passt sich kontinuierlich an jede Bildschirmgröße an, anstatt nur bei festen Haltepunkten (Breakpoints) umzuspringen. Dies wird erreicht, indem wir die leistungsstarken, auf Flexbox basierenden Layout-Mechanismen von Flutter als primäres Werkzeug nutzen.

## 1. Philosophie: Fluid First

*   **Fließend statt starr**: Wir entwerfen keine Layouts für 3 feste Größen (Smartphone, Tablet, Desktop). Wir entwerfen ein einziges, flexibles Layout, das sich auf **allen** Größen dazwischen korrekt und ästhetisch ansprechend verhält. Feste Breiten sind die absolute Ausnahme.
*   **Flexibilität ist der Kern**: Wir verwenden flexible Layout-Widgets (`Row`, `Column`, `Flex`, `Expanded`, `Wrap`), die sich natürlich an den verfügbaren Platz anpassen. Das Layout "fließt" in den ihm zur Verfügung gestellten Raum.
*   **Adaptive Anpassung als Ergänzung**: An bestimmten Punkten, an denen ein fließendes Layout nicht mehr ausreicht, nehmen wir gezielte, größere **strukturelle** Änderungen vor. Zum Beispiel wird eine `Row` auf einem sehr schmalen Bildschirm zu einer `Column`. Dies ist eine adaptive, keine rein responsive Änderung.

## 2. Die Werkzeugkiste für fluides Design

Dies sind die primären Werkzeuge, um unsere "Fluid First"-Philosophie umzusetzen.

### a) `Row`, `Column`, `Flex`
Die Grundpfeiler jedes Layouts. Sie ordnen Widgets horizontal oder vertikal an. In Kombination mit `Expanded` und `Flexible` entfalten sie ihr volles Potenziales.

### b) `Expanded` und `Flexible`
Das wichtigste Duo für fluides Design.
*   `Expanded`: Zwingt ein Widget, den maximal verfügbaren Platz entlang der Hauptachse einer `Row` oder `Column` einzunehmen. Ideal für Hauptinhaltsbereiche.
*   `Flexible`: Gibt einem Widget die Flexibilität, den verfügbaren Platz zu füllen, aber erlaubt ihm auch, kleiner zu sein, wenn der Inhalt dies zulässt.

```dart
// Ein klassisches 2-Spalten-Layout, das sich jeder Breite anpasst.
Row(
  children: [
    // Die Seitenleiste nimmt den Platz ein, den sie benötigt.
    SideBar(), 
    // Der Hauptinhalt füllt den Rest des Bildschirms, egal wie breit er ist.
    Expanded(
      child: MainContent(),
    ),
  ],
)
```

### c) `Wrap`
Perfekt für Inhalte, die bei Platzmangel in die nächste Zeile umbrechen sollen, wie z.B. eine Liste von Tags oder Chips. Dies ist responsives Verhalten ohne eine einzige Zeile expliziter Logik.

```dart
// Diese Chips werden auf einem breiten Bildschirm nebeneinander und
// auf einem schmalen Bildschirm untereinander dargestellt.
Wrap(
  spacing: 8.0,
  runSpacing: 4.0,
  children: <Widget>[
    Chip(label: Text('Design')),
    Chip(label: Text('Fluid Layout')),
    Chip(label: Text('Flutter')),
    Chip(label: Text('Vertic')),
    // ... weitere Chips
  ],
)
```

### d) `FractionallySizedBox`
Dimensioniert ein Widget als Bruchteil des verfügbaren Platzes. Nützlich für Elemente, die immer einen bestimmten Prozentsatz des Bildschirms einnehmen sollen.

---

## 3. Adaptive Anpassungen mit `LayoutBuilder`

Wenn ein fluides Layout an seine Grenzen stößt, verwenden wir `LayoutBuilder`, um die **Struktur** der UI adaptiv zu verändern. Wir vermeiden es, `LayoutBuilder` nur zur Abfrage von festen Breiten zu verwenden.

**Anwendungsfall**: Eine Einstellungsseite hat links eine Navigationsleiste und rechts den Inhalt. Auf einem schmalen Bildschirm ist das nicht mehr sinnvoll.

```dart
LayoutBuilder(
  builder: (context, constraints) {
    // Entscheidung basiert auf der verfügbaren Breite
    if (constraints.maxWidth < 600) {
      // STRUKTURÄNDERUNG: Wechsle zu einem Layout mit Tabs
      return SettingsViewWithTabs();
    } else {
      // STRUKTUR: Bleibe beim 2-Spalten-Layout
      return SettingsViewWithSideNavigation();
    }
  },
)
```

## 4. Globale vs. Lokale Metriken

*   **`LayoutBuilder` (Lokal)**: Stellt die Größe des **Eltern-Widgets** zur Verfügung. Dies ist in 90% der Fälle die richtige Wahl, da es die Komponente entkoppelt und wiederverwendbar macht. Eine Komponente sollte sich nur für den Platz interessieren, der ihr zugewiesen wurde, nicht für den gesamten Bildschirm.

*   **`MediaQuery` (Global)**: Stellt die Größe des **gesamten Bildschirms** zur Verfügung. Dies sollte sparsam und nur für globale Anpassungen verwendet werden, z.B. für Seiten-Paddings, die auf allen Seiten konsistent sein sollen. Eine übermäßige Verwendung von `MediaQuery` kann zu unnötigen Rebuilds führen und macht Komponenten weniger modular.

## 5. Best Practices & zu vermeidende Muster

*   **✓ MACHEN**: Denke in Verhältnissen und Flexibilität. Nutze `Expanded` und `Wrap`.
*   **✓ MACHEN**: Baue Komponenten so, dass sie sich dem Raum anpassen, den sie erhalten.
*   **✓ MACHEN**: Verwende `LayoutBuilder` für strukturelle Änderungen.

*   **✗ VERMEIDEN**: Feste Breiten und Höhen (`width: 300`). Dies ist das Gegenteil von fluidem Design.
*   **✗ VERMEIDEN**: Komplexe `if/else`-Ketten basierend auf `MediaQuery.of(context).size.width`. Dies führt zu starrem, schwer wartbarem Code.
*   **✗ VERMEIDEN**: `Positioned` in einem `Stack` ohne eine klare responsive Strategie. Dies führt fast immer zu Overflows auf anderen Bildschirmgrößen. 