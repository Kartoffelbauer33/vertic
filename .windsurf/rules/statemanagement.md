---
trigger: always_on
---

Riverpod State Management Regeln:
- Immer Riverpod Providers verwenden, nie setState()
- Ein Provider pro Use Case, nicht für gesamte Features
- State Management in separate providers/ Ordner
- Providers-Dateiname: [feature]_providers.dart
- Widgets konsumieren nur Providers, keine direkte Business Logic