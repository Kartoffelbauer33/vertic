# Fastlane Architektur (Staff-App)

Diese Dokumentation beschreibt die Architektur, den Funktionsumfang und die Integrationspunkte der Fastlane in der Vertic Staff App.

## Ziele
- Kiosk-Modus mit drei Kernmodi: Registrierung, Login, Check-in
- Sperrung der restlichen Staff-App während der Fastlane aktiv ist
- Entsperren durch 5x Logo-Tap (Touch) oder OS-spezifischen, konfliktfreien Shortcut (z. B. macOS: Cmd+Shift+U; Windows/Linux: Alt+Shift+U; pro OS konfigurierbar), danach Staff-Login
- Responsives UI, Dark/Light konform, Nutzung des Vertic Design Systems

## Dateien und Struktur
- `lib/services/fastlane/fastlane_state_provider.dart`
  - Hält Kiosk-Status (`isActive`) und aktuellen Modus (`FastlaneMode`)
- `lib/pages/fastlane/fastlane_page.dart`
  - Einstieg in die Fastlane, Modusauswahl, Logo-Tap-Exit und Modus-Routing
- `lib/pages/fastlane/fastlane_registration_page.dart`
  - Vierstufiger Registrierungsflow mit Schrittleiste
  - Schritt 1: Name, Geburtsdatum, Geschlecht, Adresse, Email, Telefon, Profilbild
  - Schritt 2: Notfallkontakt
  - Schritt 3: Kinder hinzufügen
  - Schritt 4: Übersicht, Zustimmungen (Hausordnung, AGB, Datenschutz), Senden, Willkommensbildschirm
- `lib/widgets/fastlane/staff_unlock_dialog.dart`
  - Staff-Login-Dialog zum Entsperren der Fastlane

### Registrierung: Validierung, Fehlerzustände & A11y (verbindliche Spezifikation)
- Validierung (Client + Server):
  - Email: syntaktische Prüfung (RFC-konforme, praxisnahe Regex), MX-Check optional.
  - Telefon: E.164-Format (z. B. `+491234567890`).
  - Adresse: Pflichtfelder (Straße, Hausnummer, PLZ, Stadt, Land) vollständig.
  - Passwort: Mindestlänge 12, mind. 1 Groß-, 1 Kleinbuchstabe, 1 Ziffer, 1 Sonderzeichen; häufige/geleakte Passwörter ablehnen.
  - Geburtsdatum/Alter: Mindestalter und Maximalalter konfigurierbar; für Kinder: Duplikaterkennung pro Erziehungsberechtigtem (Name + DOB + optionaler Identifier).
- UX-Fehlerverhalten:
  - Inline-Feldfehler mit klaren, lokalen Meldungen; Fokus auf fehlerhaftes Feld.
  - Serverfehler-Mapping (z. B. „Email bereits verwendet“, „Telefon ungültig“).
  - Wiederholungsversuche mit Backoff-Hinweis bei transienten Fehlern.
- Barrierefreiheit:
  - Vollständige Tastaturnavigation; sichtbarer Fokus; logische Tab-Reihenfolge.
  - Screenreader-Labels; ARIA-Rollen/Attribute für Stepper/Progress.
- Foto-Handling:
  - Kameraberechtigung mit erklärender Begründung; Fallback: Galerie (sofern zulässig) oder Schritt überspringen.
  - Formate/Größen: JPEG/PNG, Max-Größe X MB (konfigurierbar); Client-seitige Größenanpassung/Kompression erlaubt.
  - Offline-Fall: Upload-Queue oder explizite Skip-Option; keine Persistenz sensibler Daten über den aktuellen Screen hinaus.

## Navigation & Lock
- Sidebar-Eintrag auf Route `/fastlane` (siehe `main.dart` → `_getVisiblePages`)
- Während `FastlaneStateProvider.isActive == true` wird Navigation außerhalb der Fastlane blockiert
- Entsperren:
  - 5x Tap auf das Fastlane-Icon links oben (innerhalb 3 Sekunden)
  - Desktop: Shortcut (konfliktfrei, OS-spezifisch, nicht kollidierend mit Paste):
    - macOS: `Cmd + Shift + U` (alternativ: 5x Zwei-Finger-Tap auf Touchpad)
    - Windows/Linux: `Alt + Shift + U`
  - Throttling: max. 5 Entsperrversuche pro Minute (konfigurierbar) zur Brute-Force-Prävention
  - Audit-Logging: Jeder Entsperrversuch wird mit Zeitstempel, Gerät/Client, optionaler Nutzerkennung und Ergebnis (erfolgreich/fehlgeschlagen) protokolliert
  - Konfigurierbarkeit: Shortcut pro OS konfigurierbar; Standardwerte siehe oben. Rationale: Vermeidung von Kollisionen mit Einfügen (z. B. `Cmd+V`).
  - Staff-Login-Dialog erscheint; bei Erfolg wird der Kiosk-Lock deaktiviert

- Lock-Durchsetzung (nicht umgehbar):
  - Route-Guard: Navigationsversuche zu Nicht-Fastlane-Routen werden abgewiesen, solange `isActive == true`.
  - Deep-Link-Interceptor: Eingehende Deep-Links (inkl. initial handling) werden abgefangen und verworfen.
  - Browser/URL-Änderungen: `pushState`/`popstate` während Lock ignorieren; Back/Forward-Navigation blockieren.
  - Global-Hotkeys & Back-Handler: Globale Shortcuts und Zurück-Buttons schlucken/ignorieren.
  - Inaktivitäts-Timer: Bei Maus-/Tastatur-/Touch-Ereignissen Timer zurücksetzen; nach Timeout automatisch re-lock.
  - App-Lebenszyklus: Beim Resume/Visibility-Change automatisch re-lock.

- Staff-Login-Sitzung: Umfang & Laufzeit (verbindlich):
  - Maximale Entsperrdauer: Standard 10 Minuten (konfigurierbar pro Deployment); danach automatischer Re-Lock.
  - Manuelle Re-Lock-Aktion: UI-Schaltfläche „Sperren“ für sofortiges Re-Locking.
  - Re-Lock-Trigger: Staff-Logout, App geht in Hintergrund/kehrt zurück, Crash/Neustart (Recovery erzwingt Lock), Ablauf des Inaktivitäts-Timers.
  - Sitzungsinvalidierung: Token-Ablauf/Refresh erzwingen; Server-seitige Revokation muss Client-Sitzung sofort beenden (Push/Long-Poll/Next-Call).
  - Audit: Unlock- und Lock-Ereignisse mit Zeitstempel, Actor (Staff-ID, Rolle), Ergebnis, Kontext (z. B. Grund/Trigger) protokollieren.

## Server-Integration
- Client: `test_server_client`
- Registrierung:
  - `unifiedAuth.clientSignUpUnified(email, password, firstName, lastName)`
  - `unifiedAuth.completeClientRegistration(...)` zum Speichern der Profildaten
  - Optional: `userProfile.uploadProfilePhoto(email, photoData)`
  - Kinder: `userProfile.addChildAccount(parentId, ...)`
- Check-in (für spätere Implementierung):
  - `identity.validateIdentityQrCode(code, facilityId)` (siehe `BackgroundScannerService`)

- Sicherheits- und Betriebsanforderungen (verbindlich):
  1) Transport: Ausnahmslos TLS für alle Endpoints; wo möglich Zertifikat-Pinning; Zugangsdaten/Credentials niemals loggen.
  2) Secrets: Ausschließlich aus sicherem Speicher/Environment (nicht im Repo, nicht im Client gebundled); Rotation und Zugriffskontrollen vorsehen.
  3) Idempotenz: Für Sign-up- und Child-Add-Flows Idempotency-Keys verlangen/verarbeiten.
  4) Resilienz: Retries mit exponentiellem Backoff + Jitter; Benutzer sichtbare Retry-Status/Prompts.
  5) Umgebungen: `test_server_client` strikt über Env-Flags/DI kapseln; nie in Produktion verwenden.
  6) Versionierung: Payload-Versionen mit Rück-/Vorwärtskompatibilität; Breaking-Changes migrationsfähig dokumentieren.
  7) Check-in: Rate-Limits für QR-Validierung, Toleranz für Clock-Skew, vollständiger Audit-Trail (wer/was/wann/wo/Ergebnis).

## Design System
- Alle Komponenten verwenden `context.colors`, `context.spacing`, `context.typography`
- Buttons/Inputs über `design_system/components`
- Schrittleiste gemäß Design-Richtlinien, ohne harte Farben/Werte

## Erweiterbarkeit
- Weitere Modi (`login`, `checkIn`, `loginAndRegistration`, `allInOne`) sind vorbereitet
- Einstellungen (Policy, Farben, Texte) können zentral ergänzt werden

## Sicherheit & Compliance
- Datenschutz (Definition & Speicherung):
  - PII: Namen, DOB, Kontaktdaten, Adresse; SPI: Fotos, Ausweis-/ID-Daten.
  - Keine Persistenz über den aktuellen Screen hinaus; keine Caches in LocalStorage/SharedPreferences/Dateisystem.
- Logging-Policy:
  - PII/SPI in Logs strikt geschwärzt; Fehlertexte ohne sensible Inhalte.
  - Analytics in Kiosk-Flows standardmäßig deaktiviert; Opt-In/Opt-Out steuern.
- Einwilligungen:
  - Persistiere: Dokument-ID, Version, Zeitstempel, Locale, Signierenden (Beziehung/Identität).
  - Endpunkte/Prozesse für Abruf und Widerruf von Einwilligungen bereitstellen.
- Minderjährige/Kinderkonten:
  - Erziehungsberechtigten-Beziehung hinterlegen (Guardian/Parent); alters- und rechtsraumabhängige Prüfungen erzwingen.

## QA-Checkliste
- Automatisierte Tests:
  - [ ] Unit-/Widget-Tests für `FastlaneStateProvider`, Route-Guards, Deep-Link-Interceptor
  - [ ] Golden-Tests für Kern-Screens (Registrierungsschritte, Unlock-Dialog)
  - [ ] E2E: Registrierung, Unlock/Re-Lock inkl. Fehlerpfade
- Qualität & Sicherheit:
  - [ ] `flutter analyze` ohne Warnungen/Fehler
  - [ ] Dependency Vulnerability/SCA-Scan (CI)
  - [ ] Keine hartcodierten Secrets; Env-Variablen überprüft
- Performance-Budgets (Richtwerte):
  - [ ] Cold Start ≤ X s, First Frame ≤ Y ms, keine Jank-Spitzen in Kiosk-Loops
  - [ ] Speicherauslastung in Kiosk-Loops innerhalb Budget
- Internationalisierung & A11y:
  - [ ] Keine hartcodierten Strings; i18n-Abdeckung geprüft
  - [ ] TalkBack/VoiceOver: Labels, Fokusführung, Kontrast ok


