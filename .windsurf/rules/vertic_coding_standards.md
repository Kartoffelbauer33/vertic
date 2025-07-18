---
trigger: always_on
description:
globs:
---
# Vertic Flutter & Serverpod Coding Standards

Diese Regel erzwingt konsistente Codierungsstandards und Best Practices für die Vertic Flutter- und Serverpod-Projekte. Die Einhaltung dieser Richtlinien trägt zur Aufrechterhaltung der Codequalität, Lesbarkeit und zur Vermeidung gängiger Fehler bei.

## Allgemeine Prinzipien

*   **Vollständigkeit**: Niemals TODOs oder unvollständige Funktionen hinterlassen. Alle Funktionen müssen vollständig implementiert sein.
*   **Reaktionsfähigkeit**: UI-Komponenten müssen reaktionsfähig sein und sowohl im Darkmode als auch im Lightmode korrekt funktionieren. Sie müssen zudem visuell ansprechend sein und den besten UX-Praktiken entsprechen.
*   **Code-Struktur**: Befolgen Sie Industriestandards für die Code-Struktur und pflegen Sie eine saubere, fehlerfreie Codebasis.
*   **Abhängigkeitsmanagement**: Nutzen Sie bestehende Abhängigkeiten in `pubspec.yaml`, wenn möglich. Neue Bibliotheken dürfen nur dann eingeführt werden, wenn dies der beste Ansatz ist und jede andere Alternative nicht mehr den Best Practices entspricht oder einen erheblichen Mehraufwand bedeutet.
*   **Keine Fallbacks**: Die Logik muss robust sein. Fehler sollten explizit behandelt werden, nicht mit stillen Fallbacks.
*   **Keine Provisorien**: Implementieren Sie vollständige Funktionen von Anfang an und vermeiden Sie temporären oder provisorischen Code.
*   **Linting**: Alle Lint-Fehler müssen behoben werden.

## Spezifische Regeldetails

### 1. Imports & Abhängigkeiten
*   **Korrekte Imports**: Stellen Sie immer sicher, dass alle notwendigen Pakete korrekt importiert sind (z.B. `package:flutter/material.dart`, `package:serverpod_client/serverpod_client.dart`, `package:test/test.dart`). Falls ein Paket fehlt, fügen Sie es zu `pubspec.yaml` hinzu und führen Sie `flutter pub get` oder `dart pub get` aus.
*   **Unbenutzte Imports entfernen**: Entfernen Sie alle unbenutzten `import`-Direktiven, um die Dateien sauber zu halten.
*   **Unnötige Imports vermeiden**: Importieren Sie keine Bibliotheken, deren Elemente bereits durch einen anderen Import bereitgestellt werden (z.B. `dart:typed_data`, wenn `package:flutter/foundation.dart` vorhanden ist).

### 2. Namenskonventionen
*   **`lowerCamelCase` für Konstanten**: Alle `const`- oder `final`-Deklarationen auf oberster Ebene und statische Felder sollten `lowerCamelCase` verwenden (z.B. `myConstant`, nicht `MY_CONSTANT`).
*   **Keine führenden Unterstriche für lokale Bezeichner**: Lokale Variablen sollten nicht mit einem Unterstrich beginnen (`no_leading_underscores_for_local_identifiers`).

### 3. Fehlervermeidung & Codequalität
*   **`BuildContext` über Async-Lücken**: Wenn `BuildContext` nach einem `await`-Aufruf im `State` eines `StatefulWidget` verwendet wird, überprüfen Sie immer `if (!mounted)` bevor Sie auf `context` oder andere Eigenschaften zugreifen, die davon abhängen, dass das Widget gemountet ist.
*   **Geschweifte Klammern für Kontrollstrukturen**: Verwenden Sie immer geschweifte Klammern `{}` für `if`, `else`, `for`, `while`, `do` und `try-catch-finally`-Anweisungen, auch für einzelne Anweisungen, um Mehrdeutigkeiten und Fehler zu vermeiden.
*   **Unbenutzten Code entfernen**: Löschen Sie alle unbenutzten Felder, Elemente und lokalen Variablen (`unused_field`, `unused_element`, `unused_local_variable`).
*   **Unnötige Null-Assertierungen (`!`) vermeiden**: Verwenden Sie den `!`-Operator nicht, wenn der Ausdruck bereits als nicht-null bekannt ist (`unnecessary_non_null_assertion`).
*   **Totem Code entfernen**: Stellen Sie sicher, dass es keinen unerreichbaren Code gibt (`dead_code`).
*   **Korrekte Null-Aware-Operatoren**: Ersetzen Sie redundante Null-Aware-Operatoren (`?.`, `??`) durch direkten Member-Zugriff (`.`) oder einfachere Null-Checks, wenn der Operand nicht null sein kann (`dead_null_aware_expression`, `invalid_null_aware_operator`).
*   **`final` Felder bevorzugen**: Deklarieren Sie Felder als `final`, wenn ihre Werte nur einmal während der Initialisierung zugewiesen werden (`prefer_final_fields`).
*   **String-Interpolation**: Bevorzugen Sie die String-Interpolation (`'Hallo $name'`) gegenüber der String-Verkettung mit dem `+`-Operator (`prefer_interpolation_to_compose_strings`, `unnecessary_brace_in_string_interps`).
*   **Veraltete Mitglieder**: Ersetzen Sie veraltete Mitglieder durch ihre empfohlenen Alternativen (z.B. verwenden Sie `.withValues()` anstelle von `.withOpacity()` für `Color`s).
*   **Keine `print`-Anweisungen**: Verwenden Sie `print()` nicht im Produktionscode. Verwenden Sie stattdessen ein geeignetes Logging-Framework (`avoid_print`).
*   **Widget-Struktur**: Stellen Sie sicher, dass das `child`-Argument immer das letzte in Widget-Konstruktoraufrufen ist (`sort_child_properties_last`).
*   **Whitespace**: Bevorzugen Sie `SizedBox` zum Hinzufügen von Whitespace zu Layouts anstelle von `Container` (`sized_box_for_whitespace`).
*   **Null-Aware-Zuweisung**: Verwenden Sie den `??=`-Operator für bedingte Zuweisungen, wenn auf null geprüft wird (`prefer_conditional_assignment`).

### 4. Logik & Typsicherheit
*   **Gültige Typ-Erweiterungen**: Stellen Sie sicher, dass Klassen nur andere Klassen erweitern (`extends_non_class`).
*   **Korrekte Super-Parameter**: Richten Sie die Verwendung von `super`-Parametern an den benannten Parametern des Superklassen-Konstruktors aus (`super_formal_parameter_without_associated_named`).
*   **Gültige Instanziierung**: Erstellen Sie Objekte nur von gültigen Klassentypen (`creation_with_non_type`).
*   **`override`-Annotation**: Verwenden Sie `@override` nur, wenn eine Methode tatsächlich eine Superklassenmethode überschreibt. Entfernen Sie es oder korrigieren Sie die Signatur, wenn dies nicht der Fall ist (`override_on_non_overriding_member`).
*   **Typargumente**: Stellen Sie sicher, dass korrekte Typen als Typargumente verwendet werden (z.B. `Widget` ist ein Typ) (`non_type_as_type_argument`).
*   **Kompatible Typ-Checks**: Stellen Sie sicher, dass Typgleichheitsprüfungen (`==`) kompatible Typen vergleichen (`unrelated_type_equality_checks`).

### 5. Dokumentation
*   **Keine `TODO`-Kommentare**: Alle `TODO`-Kommentare müssen vor dem Commit gelöst und entfernt werden. Implementieren Sie stattdessen alle Funktionen vollständig und ohne Platzhalter.
*   **Doc-Kommentare HTML**: Verwenden Sie Backticks für Code-Snippets in Dokumentationskommentaren, um Fehlinterpretationen als HTML zu vermeiden (`unintended_html_in_doc_comment`).

### 6. Fehlerbehandlung
*   **Umfassendes `try-catch`**: Verwenden Sie `try-catch`-Blöcke für alle Operationen, die fehlschlagen könnten, insbesondere bei Netzwerkaufrufen, Dateisystemzugriffen oder komplexer Logik.
*   **Spezifische Ausnahmen**: Fangen Sie spezifische Ausnahmen ab, anstatt generische `catch (e)`-Blöcke zu verwenden, um eine präzisere Fehlerbehandlung zu ermöglichen.
*   **Benutzerfreundliche Fehlermeldungen**: Zeigen Sie Endbenutzern keine rohen Fehlermeldungen an. Übersetzen Sie Fehler in klare, verständliche Nachrichten, die den Benutzern helfen, das Problem zu verstehen oder zu beheben.
*   **Fehlerzustände in der UI**: Reflektieren Sie Fehlerzustände in der UI, z.B. durch das Anzeigen von Fehlermeldungen, Ladeindikatoren oder das Deaktivieren von Eingabefeldern, um eine bessere User Experience zu gewährleisten.

### 7. Performance-Optimierung (Flutter)
*   **`const` Widgets**: Verwenden Sie `const` Konstruktoren für Widgets, wo immer möglich, um unnötige Rebuilds zu vermeiden und die Leistung zu verbessern.
*   **Lazy Loading mit `ListView.builder`**: Nutzen Sie `ListView.builder` für lange Listen, um nur die sichtbaren Elemente zu rendern und Speicher zu sparen.
*   **Minimale Rebuilds**: Strukturieren Sie Widgets so, dass Änderungen an einem Teil der UI nicht zu unnötigen Rebuilds anderer, unabhängiger Teile führen.
*   **Effiziente Datenverarbeitung**: Verarbeiten Sie große Datenmengen asynchron und auf separaten Isolaten, um die UI flüssig zu halten.
*   **Image Caching**: Verwenden Sie Image Caching für Bilder, um Ladezeiten zu reduzieren und den Netzwerkverkehr zu minimieren.

### 8. Sicherheit
*   **Eingabevalidierung**: Validieren Sie immer alle Benutzereingaben auf Client- und Serverseite, um Angriffe wie SQL-Injections oder Cross-Site Scripting (XSS) zu verhindern.
*   **Sichere Speicherung**: Speichern Sie sensible Daten (z.B. Tokens, Passwörter) niemals im Klartext. Verwenden Sie sichere Speichermechanismen wie `flutter_secure_storage` für Flutter und verschlüsselte Datenbankfelder für Serverpod.
*   **API-Schlüssel**: Verwalten Sie API-Schlüssel und andere Geheimnisse sicher. Speichern Sie sie nicht direkt im Code, sondern verwenden Sie Umgebungsvariablen oder sichere Konfigurationsdateien.
*   **Authentifizierung & Autorisierung**: Stellen Sie sicher, dass alle Endpunkte korrekt authentifiziert und autorisiert sind, und implementieren Sie robuste Berechtigungsprüfungen (RBAC) auf dem Server.

### 9. Logging
*   **Strukturiertes Logging**: Verwenden Sie ein Logging-Framework (z.B. `logger` für Flutter/Dart, integriertes Serverpod-Logging), um strukturierte Logs zu erzeugen, die leicht analysierbar sind.
*   **Sensible Daten vermeiden**: Protokollieren Sie niemals sensible Benutzerdaten (Passwörter, PII, Kreditkartennummern) in den Logs.
*   **Log-Level**: Verwenden Sie angemessene Log-Level (DEBUG, INFO, WARNING, ERROR, FATAL) für verschiedene Arten von Nachrichten.

### 10. UI/UX Best Practices
*   **Responsives Design**: Implementieren Sie responsives Design mit `MediaQuery` oder `LayoutBuilder`, um sicherzustellen, dass die App auf verschiedenen Bildschirmgrößen und -orientierungen gut aussieht und funktioniert.
*   **Barrierefreiheit (Accessibility)**: Berücksichtigen Sie Barrierefreiheit von Anfang an. Verwenden Sie semantische Widgets, sorgen Sie für ausreichenden Farbkontrast und implementieren Sie Textskalierung.
*   **Animationen & Übergänge**: Verwenden Sie subtile und funktionale Animationen und Übergänge, um die Benutzererfahrung zu verbessern und visuelles Feedback zu geben. Vermeiden Sie übermäßige oder ablenkende Animationen.
*   **Konsistentes Design-System**: Halten Sie sich an ein konsistentes Design-System (Farben, Typografie, Abstände, Komponenten) für ein einheitliches Erscheinungsbild.

### 11. State Management (Flutter)
*   **Einheitlicher Ansatz**: Wählen Sie eine State-Management-Lösung (z.B. Provider, Riverpod, BLoC, GetX) und wenden Sie diese konsistent im gesamten Projekt an. Vermeiden Sie die Mischung verschiedener Ansätze ohne triftigen Grund.
*   **Trennung von Concerns**: Trennen Sie Geschäftslogik und UI-Logik strikt. Widgets sollten so dumm wie möglich sein und nur UI-bezogene Aufgaben erledigen.
*   **Datenfluss**: Verstehen und implementieren Sie einen klaren, unidirektionalen Datenfluss, um die Nachvollziehbarkeit und Debugging zu erleichtern.

### 12. Backend/API-Interaktion (Serverpod)
*   **Asynchrone Operationen**: Alle API-Aufrufe müssen asynchron sein. Verwenden Sie `async/await` konsequent.
*   **Fehlerbehandlung auf dem Client**: Fangen Sie API-Fehler auf dem Client ab und behandeln Sie sie entsprechend, z.B. durch Anzeigen einer Fehlermeldung oder Wiederholungsversuche.
*   **Modellkonsistenz**: Stellen Sie sicher, dass die Serverseitigen Modelle und die Client-Modelle über den generierten Code (Serverpod) konsistent sind.
*   **Effiziente Endpunkte**: Entwerfen Sie Endpunkte so, dass sie nur die benötigten Daten zurückgeben und übermäßige Datenübertragungen vermeiden.

### 13. Datenbank-Interaktion (Serverpod)
*   **Transaktionen**: Verwenden Sie Datenbanktransaktionen für Operationen, die atomar sein müssen (entweder alle Operationen erfolgreich oder keine).
*   **Indizes**: Erstellen Sie geeignete Datenbankindizes, um die Abfrageleistung zu optimieren, insbesondere für häufig abgefragte Spalten oder Fremdschlüssel.
*   **Migrationen**: Verwalten Sie Datenbankschemaänderungen über Serverpod-Migrationen. Testen Sie Migrationen gründlich in einer Entwicklungsumgebung, bevor Sie sie auf Produktion anwenden.
*   **Sichere Abfragen**: Vermeiden Sie direkte String-Konkatenation in SQL-Abfragen. Verwenden Sie immer parametrisierte Abfragen oder ORM-Funktionen von Serverpod, um SQL-Injections zu verhindern.

### 14. Testen
*   **Umfassende Tests**: Implementieren Sie Unit-Tests, Widget-Tests und Integrationstests, um die Funktionalität, UI und die Interaktion mit dem Backend zu gewährleisten.
*   **Testabdeckung**: Streben Sie eine hohe Testabdeckung an, um Regressionen zu vermeiden und die Codequalität zu sichern.
*   **Mocks & Spies**: Verwenden Sie Mocks und Spies für externe Abhängigkeiten, um Tests isolierbar und schnell zu machen.
