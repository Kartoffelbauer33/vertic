# Components: Chips & Badges

Chips und Badges sind kompakte UI-Elemente, die zur Darstellung von Informationen, Filtern und Aktionen verwendet werden. Sie helfen dabei, Inhalte zu kategorisieren und wichtige Informationen hervorzuheben.

## 1. Chips

### 1.1. VerticChip

Chips sind interaktive Elemente, die für Filter, Tags oder Aktionen verwendet werden.

**Varianten:**
- `VerticChipVariant.filled`: Gefüllter Chip mit Hintergrundfarbe
- `VerticChipVariant.outlined`: Chip nur mit Rahmen
- `VerticChipVariant.elevated`: Chip mit Schatten für Erhöhung

**Eigenschaften:**
- `label`: Der Text des Chips
- `icon`: Optionales Icon am Anfang
- `selected`: Ob der Chip ausgewählt ist
- `onPressed`: Callback für Tap-Ereignisse
- `onDeleted`: Callback für Lösch-Aktion (zeigt X-Icon)

```dart
// Basis-Chip
VerticChip(
  label: 'Filter',
  variant: VerticChipVariant.filled,
  onPressed: () => print('Chip gedrückt'),
)

// Chip mit Icon
VerticChip(
  label: 'Favoriten',
  icon: Icons.star,
  onPressed: () {},
)

// Löschbarer Chip
VerticChip(
  label: 'Tag',
  onPressed: () {},
  onDeleted: () => print('Chip gelöscht'),
)

// Ausgewählter Chip
VerticChip(
  label: 'Aktiv',
  selected: true,
  onPressed: () {},
)
```

### 1.2. VerticFilterChip

Spezielle Chips für Filter-Funktionalität mit Toggle-Verhalten.

```dart
VerticFilterChip(
  label: 'Alle',
  selected: isAllSelected,
  onSelected: (selected) {
    setState(() {
      isAllSelected = selected;
    });
  },
)

// Filter-Chip mit Icon
VerticFilterChip(
  label: 'Aktiv',
  icon: Icons.check_circle,
  selected: showActive,
  onSelected: (selected) {
    setState(() {
      showActive = selected;
    });
  },
)
```

### 1.3. Design-Prinzipien für Chips

- **Kompakt**: Chips sollten kurze, prägnante Labels haben
- **Konsistent**: Verwenden Sie einheitliche Chip-Stile innerhalb einer Gruppe
- **Gruppierung**: Verwenden Sie `Wrap` für mehrere Chips mit konsistentem Spacing
- **Accessibility**: Alle Chips haben automatische Semantik für Screenreader

## 2. Badges

### 2.1. VerticBadge (Notification Badge)

Badges zeigen Zahlen oder Status-Indikatoren über anderen Elementen an.

**Eigenschaften:**
- `count`: Die anzuzeigende Zahl
- `maxCount`: Maximale Zahl (zeigt "99+" bei Überschreitung)
- `color`: Badge-Farbe (VerticBadgeColor enum)
- `child`: Das Element, über dem der Badge angezeigt wird

```dart
// Einfacher Notification Badge
VerticBadge(
  count: 5,
  child: Icon(Icons.notifications),
)

// Badge mit Maximum
VerticBadge(
  count: 150,
  maxCount: 99, // Zeigt "99+"
  child: Icon(Icons.mail),
)

// Farbiger Badge
VerticBadge(
  count: 3,
  color: VerticBadgeColor.error,
  child: Icon(Icons.error),
)

// Dot Badge (ohne Zahl)
VerticBadge.dot(
  child: Icon(Icons.settings),
)
```

### 2.2. VerticStatusBadge

Status-Badges zeigen den Zustand von Elementen an.

**Eigenschaften:**
- `label`: Der Status-Text
- `color`: Badge-Farbe (VerticBadgeColor enum)
- `variant`: Stil-Variante (filled oder outlined)

```dart
// Status-Badges
VerticStatusBadge(
  label: 'Online',
  color: VerticBadgeColor.success,
)

VerticStatusBadge(
  label: 'Offline',
  color: VerticBadgeColor.error,
)

VerticStatusBadge(
  label: 'Pending',
  color: VerticBadgeColor.warning,
)

// Outlined Status Badge
VerticStatusBadge(
  label: 'Info',
  color: VerticBadgeColor.info,
  variant: VerticBadgeVariant.outlined,
)
```

### 2.3. Badge-Farben

Das `VerticBadgeColor` enum bietet semantische Farben:

- `VerticBadgeColor.primary`: Hauptfarbe
- `VerticBadgeColor.secondary`: Sekundärfarbe
- `VerticBadgeColor.success`: Grün für Erfolg
- `VerticBadgeColor.warning`: Orange für Warnungen
- `VerticBadgeColor.error`: Rot für Fehler
- `VerticBadgeColor.info`: Blau für Informationen

## 3. Verwendungsrichtlinien

### 3.1. Wann Chips verwenden

- **Filter**: Zum Ein-/Ausschalten von Filteroptionen
- **Tags**: Zur Kategorisierung von Inhalten
- **Auswahl**: Für Multi-Select-Szenarien
- **Aktionen**: Für sekundäre Aktionen in kompakter Form

### 3.2. Wann Badges verwenden

- **Benachrichtigungen**: Anzahl ungelesener Nachrichten/Benachrichtigungen
- **Status**: Aktueller Zustand eines Elements
- **Kennzeichnung**: Wichtige Informationen hervorheben

### 3.3. Layout & Spacing

```dart
// Chip-Gruppen mit Wrap
Wrap(
  spacing: context.spacing.sm,
  runSpacing: context.spacing.sm,
  children: [
    VerticChip(label: 'Alle', onPressed: () {}),
    VerticChip(label: 'Aktiv', onPressed: () {}),
    VerticChip(label: 'Inaktiv', onPressed: () {}),
  ],
)

// Badge-Gruppen
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    VerticBadge(count: 5, child: Icon(Icons.mail)),
    VerticBadge(count: 12, child: Icon(Icons.notifications)),
    VerticBadge.dot(child: Icon(Icons.settings)),
  ],
)
```

## 4. Accessibility

### 4.1. Semantik

- Chips haben automatische Semantik-Labels basierend auf ihrem Text
- Badges werden als "Badge mit [Anzahl]" von Screenreadern gelesen
- Status-Badges werden mit ihrem Label und Zustand angekündigt

### 4.2. Touch-Ziele

- Alle interaktiven Chips haben mindestens 48x48dp Touch-Bereiche
- Badges selbst sind nicht interaktiv, aber ihre Child-Elemente können es sein

## 5. Implementierungsdetails

### 5.1. Theme-Integration

Alle Chip- und Badge-Komponenten nutzen das Vertic Design System:

```dart
// Farben aus dem Theme
final colors = context.colors;
final chipColor = selected ? colors.primaryContainer : colors.surfaceVariant;

// Spacing aus dem Theme
final padding = EdgeInsets.symmetric(
  horizontal: context.spacing.sm,
  vertical: context.spacing.xs,
);

// Typografie aus dem Theme
final textStyle = context.typography.labelMedium;
```

### 5.2. Responsive Verhalten

- Chips passen sich automatisch an den verfügbaren Platz an
- Bei kleinen Bildschirmen werden Chip-Gruppen automatisch umgebrochen
- Badge-Größen skalieren mit der Textgröße des Systems

---

Diese Komponenten bieten eine konsistente und flexible Lösung für kompakte Informationsdarstellung und Interaktion in der Vertic-Anwendung. 