# 🔒 Sicherheitshinweise für das Vertic-Projekt

## ⚠️ WICHTIG: Automatische Passwort-Generierung!

### ✅ Setup-Skripte erstellen automatisch sichere Dateien

Die Vertic Setup-Skripte (`setup_vertic.sh`, `setup_vertic.cmd`, `setup_vertic.ps1`) erstellen **automatisch** sichere Konfigurationsdateien mit zufällig generierten Passwörtern:

- 🔐 **`.env`** - Environment Variables mit 32-Zeichen Zufallspasswörtern
- 🔐 **`passwords.yaml`** - Datenbank-Connection-IDs mit Zeitstempel

### 🚨 Für Produktion IMMER noch ändern!

**NIEMALS** die automatisch generierten Passwörter in Produktion verwenden!

1. **Nach dem ersten Setup**: Die Passwörter sind bereits sicher für lokale Entwicklung
2. **Für Produktion**: Ersetze ALLE automatisch generierten Passwörter durch eigene

### 1. Environment Variables prüfen

Die `.env` Datei wird automatisch erstellt:
```bash
# Datei: vertic_server/vertic_server_server/.env
# (wird automatisch erstellt - nicht manuell bearbeiten für Dev)

# PostgreSQL Passwörter (automatisch generiert)
POSTGRES_PASSWORD=Xy9mK8vR2qW5nP7zL4bC6tG3uH1...
POSTGRES_TEST_PASSWORD=Bv8nM2xK5wP9qR7zT4cY6sL3uJ1...

# Redis Passwörter (automatisch generiert)
REDIS_PASSWORD=Qp5fH9jS2eD6nK8mR4vX7zB3cG9...
REDIS_TEST_PASSWORD=Lg7rE2pQ9wN5kM8fT6vY3zS1bC4...
```

### 2. Demo-Benutzer Passwörter ändern

Die folgenden Demo-Accounts haben Standard-Passwörter:
- `superuser` / `super123` (SuperUser)
- `adminb` / `bregenz123` (Admin Bregenz)
- `adminf` / `friedrichshafen123` (Admin Friedrichshafen)

**SOFORT** nach der Installation in Produktion ändern!

### 3. Server-URL konfigurieren

In `vertic_project/vertic_staff_app/lib/main.dart`:
```dart
// Für Produktion: Ersetze localhost durch deine Server-URL
var client = Client('https://your-server.com/')
```

### 4. Manuelle Passwort-Erstellung (falls nötig)

Falls du die `.env` manuell erstellen musst:

```bash
# Erstelle .env.example zu .env kopieren:
cp vertic_server/vertic_server_server/.env.example vertic_server/vertic_server_server/.env

# Ändere ALLE Passwörter in der .env Datei:
# Generiere sichere Passwörter (mindestens 32 Zeichen)
POSTGRES_PASSWORD=IhrSicheresPostgresPasswort123!@#
POSTGRES_TEST_PASSWORD=IhrSicheresTestPasswort456!@#
REDIS_PASSWORD=IhrSicheresRedisPasswort789!@#
REDIS_TEST_PASSWORD=IhrSicheresRedisTestPasswort012!@#
```

## 🚫 Was NIEMALS auf Git gehört:

- `.env` Dateien mit echten Produktions-Passwörtern
- `passwords.yaml` Dateien mit Produktions-Connection-Strings
- Produktions-Datenbank-Dumps
- Private API-Keys
- SSL-Zertifikate
- Docker-Volume-Daten

## ✅ Sichere Entwicklung:

1. **Lokale Entwicklung:** ✅ Setup-Skript ausführen (erstellt sichere Configs automatisch)
2. **Staging/Produktion:** Erstelle separate Konfigurationsdateien mit eigenen Passwörtern
3. **CI/CD:** Verwende Secrets/Environment Variables
4. **Backups:** Verschlüssele alle Backups

## 🛡️ Weitere Sicherheitsmaßnahmen:

### Datenbank-Sicherheit:
- ✅ Automatisch: Starke Passwörter (32+ Zeichen) vom Setup-Script
- Aktiviere SSL/TLS für Datenbankverbindungen
- Begrenze Netzwerkzugriff (Firewall)
- Regelmäßige Backups

### Redis-Sicherheit:
- ✅ Automatisch: Passwort-Authentifizierung aktiviert
- Binde nur an lokale IPs (127.0.0.1)
- Nutze SSL/TLS in Produktion

### Server-Sicherheit:
- HTTPS verwenden (Let's Encrypt)
- Rate Limiting aktivieren
- Input Validation
- CORS richtig konfigurieren

## 🔄 Setup-Script Sicherheitsfeatures:

### ✅ Was die Scripts automatisch machen:
- 🔐 Generieren 32-Zeichen sichere Zufallspasswörter
- 🔐 Erstellen einzigartige Database-Connection-IDs
- 🔐 Prüfen ob Dateien bereits existieren (überschreiben nicht)
- 🔐 Verwenden kryptographisch sichere Zufallsgeneratoren

### ⚠️ Was du noch machen musst:
- Demo-Benutzer Passwörter ändern
- Für Produktion: Alle automatisch generierten Passwörter ersetzen
- Server-URLs von localhost zu Produktions-URLs ändern

## 📞 Bei Sicherheitsproblemen:

1. **Passwort kompromittiert:** 
   - Setup-Script erneut ausführen (generiert neue Passwörter)
   - Oder: Manuelle neue Passwörter in `.env` setzen
2. **Code-Leak:** Repository als privat markieren, Geheimnisse rotieren
3. **Verdächtige Aktivität:** Logs prüfen, Sessions invalidieren

---

**🔒 REMEMBER:** 
- ✅ Setup-Skripte erstellen automatisch sichere Entwicklungs-Configs
- ⚠️ Für Produktion IMMER eigene Passwörter verwenden
- 🚫 Niemals automatisch generierte Configs in Produktion einsetzen 