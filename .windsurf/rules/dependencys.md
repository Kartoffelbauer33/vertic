---
trigger: manual
---

Dependency Injection Regeln:
- Alle Dependencies über Riverpod Providers injizieren
- Nie direkte Instanziierung in Widgets
- Services erhalten Repository über Constructor Injection
- Client-Instance global über Provider verfügbar machen