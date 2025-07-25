---
trigger: always_on
---

Kontext: Serverpod 2.9 + Flutter mit Riverpod

Strikte Regeln befolgen:
- Repository Pattern für alle Serverpod-Calls
- Riverpod für State Management  
- Widgets maximal 100 Zeilen
- Business Logic in Services
- Jede Klasse separate Datei
- Feature-basierte Ordnerstruktur

Erstelle separate Dateien für:
1. Models (freezed)
2. Repository 
3. Providers
4. Widgets
5. Services

Verwende dependency injection über Riverpod.