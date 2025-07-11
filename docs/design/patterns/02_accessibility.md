# Patterns: Barrierefreiheit (Accessibility, A11y)

Barrierefreiheit bedeutet, eine Anwendung so zu gestalten und zu entwickeln, dass sie von allen Menschen, einschließlich Menschen mit Behinderungen, genutzt werden kann. Dies ist nicht nur ein ethisches Gebot, sondern erweitert auch die potenzielle Nutzerbasis unserer Anwendung. Flutter bietet hervorragende Werkzeuge, um barrierefreie Apps zu erstellen.

## 1. Grundprinzipien

*   **Wahrnehmbar**: Die Informationen und UI-Komponenten müssen für die Nutzer wahrnehmbar sein (z.B. durch Alternativtexte für Bilder).
*   **Bedienbar**: Alle UI-Komponenten und die Navigation müssen bedienbar sein (z.B. per Tastatur oder Screenreader).
*   **Verständlich**: Die Informationen und die Bedienung der UI müssen verständlich sein.
*   **Robust**: Die Inhalte müssen von einer Vielzahl von assistiven Technologien (z.B. Screenreadern) zuverlässig interpretiert werden können.

## 2. Praktische Umsetzung in Flutter

### a) Semantik (`Semantics` Widget)
Das `Semantics`-Widget ist das wichtigste Werkzeug für die Barrierefreiheit in Flutter. Es versieht ein Widget mit einer Beschreibung seiner Bedeutung. Viele Flutter-Widgets (wie `Text`, `IconButton`, `Checkbox`) erstellen bereits automatisch ein Semantics-Widget. Manchmal müssen wir jedoch manuell nachhelfen.

**Anwendungsfälle:**
*   **Icons ohne Text**: Ein `IconButton` nur mit einem Icon muss ein `tooltip` haben, das Flutter automatisch in ein `Semantics`-Label umwandelt.
    ```dart
    IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Einstellungen', // Wichtig für Screenreader und Maus-Hover
      onPressed: () {},
    )
    ```
*   **Benutzerdefinierte Widgets**: Komplexe, selbst erstellte Widgets benötigen oft ein manuelles `Semantics`-Widget, um ihre Funktion zu beschreiben.
    ```dart
    Semantics(
      label: 'Bewertung von 4 aus 5 Sternen',
      child: MyCustomStarRating(rating: 4),
    )
    ```
*   **Bilder**: Decorative Bilder sollten von Screenreadern ignoriert werden (`ExcludeSemantics`). Informative Bilder benötigen eine Beschreibung.
    ```dart
    Semantics(
      label: 'Ein Foto des Matterhorns bei Sonnenaufgang.',
      child: Image.asset('assets/images/matterhorn.jpg'),
    )
    ```

### b) Tastaturnavigation & Fokus
Alle interaktiven Elemente müssen über die Tastatur (insbesondere die Tab-Taste) erreichbar und bedienbar sein.
*   **Fokus-Indikator**: Stellen Sie sicher, dass das aktuell fokussierte Element immer einen sichtbaren Fokus-Ring oder eine andere deutliche Hervorhebung hat. Das `FocusRing`-Widget oder das Styling von `focusColor` in `ThemeData` können hier helfen.
*   **Logische Reihenfolge**: Die Reihenfolge, in der Elemente mit der Tab-Taste angesprungen werden, sollte logisch und vorhersehbar sein. Normalerweise entspricht dies der visuellen Reihenfolge auf dem Bildschirm.

### c) Touch-Ziele
Die Mindestgröße für jedes interaktive Element sollte **48x48 logische Pixel** betragen. Dies stellt sicher, dass Nutzer die Elemente leicht und ohne versehentliche Klicks auf benachbarte Elemente treffen können.
*   Verwenden Sie `SizedBox` oder `Container` mit `constraints`, um sicherzustellen, dass auch kleine Widgets wie `IconButton`s einen ausreichend großen Touch-Bereich haben.

### d) Farbkontrast & Textgröße
*   **Kontrast**: Das Kontrastverhältnis zwischen Textfarbe und Hintergrundfarbe muss den [WCAG AA-Standards](https://webaim.org/resources/contrastchecker/) entsprechen (mindestens 4.5:1 für normalen Text und 3:1 für großen Text).
*   **Textgröße**: Nutzer müssen die Möglichkeit haben, die Schriftgröße in ihren Geräteeinstellungen zu ändern. Unsere App muss darauf reagieren, indem sie den Text entsprechend skaliert, ohne dass es zu Layout-Problemen (Overflows) kommt. Dies wird durch `MediaQuery.textScaleFactor` ermöglicht. Verwenden Sie flexible Layouts, damit der Text mehr Platz einnehmen kann.

## 3. Testing
Die Flutter-Entwicklertools bieten einen **Accessibility Inspector**, mit dem Sie den Semantik-Baum Ihrer Anwendung visualisieren und häufige Probleme (wie fehlende Labels oder zu kleine Touch-Ziele) identifizieren können. Nutzen Sie dieses Werkzeug regelmäßig. 