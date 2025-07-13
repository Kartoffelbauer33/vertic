# Components: Progress & Loading

Progress- und Loading-Komponenten informieren Nutzer über den Status von laufenden Operationen und verbessern das Nutzererlebnis durch visuelles Feedback bei Wartezeiten.

## 1. Progress Indicators

### 1.1. VerticProgressIndicator (Linear)

Lineare Fortschrittsbalken zeigen den Fortschritt einer Operation in Prozent an.

**Eigenschaften:**
- `value`: Fortschrittswert (0.0 bis 1.0), null für unbestimmten Fortschritt
- `label`: Optionale Beschriftung über dem Balken
- `sublabel`: Optionale Zusatzinformation unter dem Balken
- `showPercentage`: Zeigt Prozentangabe an (nur bei bestimmtem Fortschritt)

```dart
// Bestimmter Fortschritt mit Prozentanzeige
VerticProgressIndicator.linear(
  value: 0.7,
  label: 'Upload Progress',
  showPercentage: true,
)

// Unbestimmter Fortschritt
VerticProgressIndicator.linear(
  label: 'Processing...',
  sublabel: 'This may take a few moments',
)

// Einfacher Fortschrittsbalken
VerticProgressIndicator.linear(
  value: 0.45,
)
```

### 1.2. VerticProgressIndicator (Circular)

Kreisförmige Fortschrittsanzeigen für kompaktere Darstellung.

**Eigenschaften:**
- `value`: Fortschrittswert (0.0 bis 1.0), null für unbestimmten Fortschritt
- `size`: Größe des Kreises (VerticProgressSize enum)
- `showPercentage`: Zeigt Prozentangabe in der Mitte an

```dart
// Verschiedene Größen
VerticProgressIndicator.circular(
  value: 0.75,
  size: VerticProgressSize.small,
  showPercentage: true,
)

VerticProgressIndicator.circular(
  value: 0.5,
  size: VerticProgressSize.medium,
  showPercentage: true,
)

VerticProgressIndicator.circular(
  value: 0.25,
  size: VerticProgressSize.large,
  showPercentage: true,
)

// Unbestimmter kreisförmiger Fortschritt
VerticProgressIndicator.circular(
  size: VerticProgressSize.medium,
)
```

### 1.3. Progress-Größen

Das `VerticProgressSize` enum definiert standardisierte Größen:

- `VerticProgressSize.small`: 32x32dp
- `VerticProgressSize.medium`: 48x48dp (Standard)
- `VerticProgressSize.large`: 64x64dp

## 2. Loading Indicators

### 2.1. VerticLoadingIndicator

Vollständige Loading-Komponente mit Spinner und optionaler Nachricht.

**Eigenschaften:**
- `message`: Optionale Nachricht unter dem Spinner
- `size`: Größe des Spinners (VerticProgressSize enum)

```dart
// Einfacher Loading-Spinner
VerticLoadingIndicator()

// Mit Nachricht
VerticLoadingIndicator(
  message: 'Loading data...',
)

// Verschiedene Größen
VerticLoadingIndicator(
  size: VerticProgressSize.small,
  message: 'Loading...',
)

VerticLoadingIndicator(
  size: VerticProgressSize.large,
  message: 'Processing your request',
)
```

### 2.2. Button Loading States

Loading-Zustände in Buttons für Aktions-Feedback.

```dart
// Buttons mit Loading-Zustand
PrimaryButton(
  text: 'Saving...',
  isLoading: true,
  onPressed: () {}, // Wird automatisch deaktiviert
)

SecondaryButton(
  text: 'Processing',
  isLoading: true,
  onPressed: () {},
)
```

## 3. Skeleton Loaders

### 3.1. VerticSkeletonLoader

Platzhalter-Komponenten für Inhalte, die geladen werden.

**Eigenschaften:**
- `width`: Breite des Skeleton-Elements
- `height`: Höhe des Skeleton-Elements
- `borderRadius`: Optionale Rundung der Ecken

```dart
// Einfacher Skeleton-Block
VerticSkeletonLoader(
  width: double.infinity,
  height: 20,
)

// Runder Skeleton (für Avatars)
VerticSkeletonLoader(
  width: 40,
  height: 40,
  borderRadius: BorderRadius.circular(20),
)

// Skeleton für Karten-Layout
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        VerticSkeletonLoader(
          width: 40,
          height: 40,
          borderRadius: BorderRadius.circular(20),
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VerticSkeletonLoader(width: double.infinity, height: 16),
              SizedBox(height: context.spacing.xs),
              VerticSkeletonLoader(width: 120, height: 14),
            ],
          ),
        ),
      ],
    ),
    SizedBox(height: context.spacing.md),
    VerticSkeletonLoader(width: double.infinity, height: 100),
  ],
)
```

## 4. Verwendungsrichtlinien

### 4.1. Wann welche Komponente verwenden

**Lineare Progress Indicators:**
- Datei-Uploads/Downloads
- Mehrstufige Formulare
- Installation/Setup-Prozesse
- Lange Operationen mit bekannter Dauer

**Kreisförmige Progress Indicators:**
- Kompakte Bereiche
- In-Button-Loading (kleine Größe)
- Dashboard-Widgets
- Kurze Operationen

**Loading Indicators:**
- Seitenladezeiten
- API-Aufrufe
- Datenverarbeitung
- Allgemeine Wartezeiten

**Skeleton Loaders:**
- Listen-/Grid-Inhalte beim ersten Laden
- Karten-basierte Layouts
- Profilseiten
- Komplexe UI-Strukturen

### 4.2. Timing & Performance

```dart
// Zeige Loading sofort bei Aktionsstart
setState(() {
  isLoading = true;
});

try {
  await performOperation();
} finally {
  setState(() {
    isLoading = false;
  });
}

// Mindest-Loading-Zeit für bessere UX
const minLoadingTime = Duration(milliseconds: 500);
final stopwatch = Stopwatch()..start();

await performOperation();

final elapsed = stopwatch.elapsed;
if (elapsed < minLoadingTime) {
  await Future.delayed(minLoadingTime - elapsed);
}
```

### 4.3. Accessibility

- **Screen Reader**: Alle Loading-Komponenten haben semantische Labels
- **Live Regions**: Statusänderungen werden automatisch angekündigt
- **Fokus-Management**: Fokus bleibt auf auslösendem Element während Loading

```dart
// Automatische Semantik für Screenreader
Semantics(
  label: 'Loading, please wait',
  child: VerticLoadingIndicator(
    message: 'Processing your request...',
  ),
)
```

## 5. Layout & Positioning

### 5.1. Zentrierte Loading-Zustände

```dart
// Vollbild-Loading
Center(
  child: VerticLoadingIndicator(
    message: 'Loading application...',
  ),
)

// Loading in Karten
Card(
  child: Container(
    height: 200,
    child: Center(
      child: VerticLoadingIndicator(
        message: 'Loading content...',
      ),
    ),
  ),
)
```

### 5.2. Inline Progress

```dart
// Progress in Listen-Items
ListTile(
  title: Text('File Upload'),
  subtitle: VerticProgressIndicator.linear(
    value: uploadProgress,
    showPercentage: true,
  ),
)

// Progress in Cards
Card(
  child: Padding(
    padding: context.spacing.cardPadding,
    child: Column(
      children: [
        Text('Installation Progress'),
        SizedBox(height: context.spacing.sm),
        VerticProgressIndicator.linear(
          value: installProgress,
          label: 'Installing components...',
          showPercentage: true,
        ),
      ],
    ),
  ),
)
```

## 6. Theming & Customization

### 6.1. Theme-Integration

Alle Progress- und Loading-Komponenten nutzen das Vertic Design System:

```dart
// Farben aus dem Theme
final colors = context.colors;
final progressColor = colors.primary;
final backgroundColor = colors.surfaceVariant;

// Animationen aus dem Theme
final animationDuration = context.animations.medium;
final animationCurve = context.animations.easeInOut;

// Typografie für Labels
final labelStyle = context.typography.bodyMedium;
final sublabelStyle = context.typography.bodySmall;
```

### 6.2. Responsive Verhalten

- Progress-Komponenten passen sich automatisch an verfügbaren Platz an
- Skeleton-Loader verwenden flexible Breiten (`double.infinity`)
- Größen skalieren mit dem System-Text-Scale-Factor

## 7. Error States

### 7.1. Progress mit Fehlerzustand

```dart
// Progress-Komponente mit Error-Styling
VerticProgressIndicator.linear(
  value: 0.3,
  label: 'Upload failed',
  // Verwendet Error-Farbe aus Theme
)

// Loading mit Retry-Option
Column(
  children: [
    Icon(Icons.error, color: context.colors.error),
    SizedBox(height: context.spacing.sm),
    Text('Loading failed'),
    SizedBox(height: context.spacing.md),
    SecondaryButton(
      text: 'Retry',
      onPressed: () => retryOperation(),
    ),
  ],
)
```

---

Diese Progress- und Loading-Komponenten bieten eine konsistente und benutzerfreundliche Möglichkeit, Wartezeiten und Operationsstatus in der Vertic-Anwendung zu kommunizieren. 