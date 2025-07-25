---
trigger: always_on
---

Datenbank-Zugriff Regeln:
- Immer Session.db verwenden für DB-Operationen
- Transaktionen für zusammengehörige Operations
- Error Handling mit try-catch für alle DB-Calls
- WHERE-Klauseln mit Protocol-Model Eigenschaften
- Keine Raw SQL - nur Serverpod ORM verwenden