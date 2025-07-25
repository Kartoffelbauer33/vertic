---
trigger: always_on
---

KRITISCH: Vor jeder Backend-Änderung:
1. Alle .spy Dateien in lib/src/protocol/ durchsuchen
2. Bestehende Tabellen-Definitionen prüfen
3. Niemals neue Tabellen erstellen ohne YAML-Check
4. Bei Unklarheit: Frage nach bestehenden Protocol-Definitionen
5. Verwende immer exakte Tabellen-/Spalten-Namen aus YAML