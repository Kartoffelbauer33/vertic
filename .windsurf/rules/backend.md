---
trigger: always_on
---

Kontext: Bestehende Serverpod 2.9 Backend mit umfangreichen YAML-Protokollen

KRITISCH - Vor Coding:
1. Prüfe alle .spy Dateien in lib/src/protocol/
2. Analysiere bestehende Endpoints in lib/src/endpoints/
3. Verwende exakte Namen aus Protocol-Definitionen
4. Erweitere bestehende Strukturen, erstelle keine neuen

Regeln:
- Nur Serverpod ORM verwenden
- Session.db für DB-Operations
- Bestehende Auth-System nutzen
- Transaktionen für Multi-Operations
- Error Handling mit ServerpodException