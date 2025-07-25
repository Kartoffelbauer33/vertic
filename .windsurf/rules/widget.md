---
trigger: always_on
---

WICHTIG: Flutter Widget-Regeln befolgen:
- Maximal 100 Zeilen pro Widget-Datei
- Bei mehr als 50 Zeilen: Widget in kleinere Komponenten aufteilen
- Keine Business Logic in Widgets - nur UI-Code
- Jedes Widget in separate Datei
- Widget-Namen: [Feature][Component]Widget.dart (z.B. UserProfileWidget.dart)