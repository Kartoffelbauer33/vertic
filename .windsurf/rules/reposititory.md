---
trigger: always_on
---

Serverpod Integration über Repository Pattern:
- Alle Serverpod Client-Calls nur in Repository-Klassen
- Repository in separaten repositories/ Ordner
- Repository-Dateiname: [feature]_repository.dart
- Nie direkte Client-Calls in Widgets oder Providers
- Exception Handling in Repository-Ebene