# Fastlane Architektur (Staff-App)

Diese Dokumentation beschreibt die Architektur, den Funktionsumfang und die Integrationspunkte der Fastlane in der Vertic Staff App.

## Ziele
- Kiosk-Modus mit drei Kernmodi: Registrierung, Login, Check-in
- Sperrung der restlichen Staff-App während der Fastlane aktiv ist
- Entsperren durch 5x Logo-Tap (Touch) oder Cmd+V Shortcut (Desktop), danach Staff-Login
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

## Navigation & Lock
- Sidebar-Eintrag auf Route `/fastlane` (siehe `main.dart` → `_getVisiblePages`)
- Während `FastlaneStateProvider.isActive == true` wird Navigation außerhalb der Fastlane blockiert
- Entsperren:
  - 5x Tap auf das Fastlane-Icon links oben (innerhalb 3 Sekunden)
  - Desktop: Shortcut `Cmd + V` (5x)
  - Staff-Login-Dialog erscheint; bei Erfolg wird der Kiosk-Lock deaktiviert

## Server-Integration
- Client: `test_server_client`
- Registrierung:
  - `unifiedAuth.clientSignUpUnified(email, password, firstName, lastName)`
  - `unifiedAuth.completeClientRegistration(...)` zum Speichern der Profildaten
  - Optional: `userProfile.uploadProfilePhoto(email, photoData)`
  - Kinder: `userProfile.addChildAccount(parentId, ...)`
- Check-in (für spätere Implementierung):
  - `identity.validateIdentityQrCode(code, facilityId)` (siehe `BackgroundScannerService`)

## Design System
- Alle Komponenten verwenden `context.colors`, `context.spacing`, `context.typography`
- Buttons/Inputs über `design_system/components`
- Schrittleiste gemäß Design-Richtlinien, ohne harte Farben/Werte

## Erweiterbarkeit
- Weitere Modi (`login`, `checkIn`, `loginAndRegistration`, `allInOne`) sind vorbereitet
- Einstellungen (Policy, Farben, Texte) können zentral ergänzt werden

## Sicherheit & Compliance
- Keine Speicherung sensibler Daten im UI-State
- Zustimmungen werden clientseitig erfasst (Checkboxen); serverseitige Dokument-Agreements sind vorbereitet (siehe `document_management_endpoint.dart`)
- Minderjährige werden über separaten Child-Flow unterstützt

## QA-Checkliste
- Responsives Verhalten auf Desktop/Tablet geprüft
- Dark/Light Mode geprüft
- Lint-frei
- Server-Calls mit existierenden Endpoints validiert


