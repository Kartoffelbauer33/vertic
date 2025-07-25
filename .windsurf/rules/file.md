---
trigger: always_on
---

Strikte Ordnerstruktur einhalten:
lib/src/features/[feature_name]/
- models/ (Data Classes)
- providers/ (Riverpod Providers)  
- repositories/ (Serverpod API Calls)
- services/ (Business Logic)
- widgets/ (Feature Widgets)
- screens/ (Screen-Level Widgets)
Jede Klasse in separate Datei, maximal 150 Zeilen