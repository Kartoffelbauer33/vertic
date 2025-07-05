# 🔄 VERTIC GIT MANAGEMENT GUIDE

**Sichere und effiziente Git-Workflows für das Vertic-Projekt**  
**Version:** 2.1 (E-Mail-Bestätigung Update)  
**Aktualisiert:** 2025-01-16

---

## 📋 INHALTSVERZEICHNIS

1. [🎯 Git-Strategie](#git-strategie)
2. [🔐 Sicherheitsrichtlinien](#sicherheitsrichtlinien)
3. [📧 E-Mail-Bestätigungsfeatures](#e-mail-bestätigungsfeatures)
4. [🚀 Standard-Workflows](#standard-workflows)
5. [🌐 Remote Server Deployment](#remote-server-deployment)
6. [🛠️ Troubleshooting](#troubleshooting)
7. [📊 Best Practices](#best-practices)

---

## 🎯 GIT-STRATEGIE

### **Repository-Struktur**
```
Leon_vertic/ (Hauptrepository)
├── .git/                          # Git-Metadaten
├── .gitignore                     # Ignore-Regeln
├── vertic_app/                    # Hauptanwendung
│   ├── vertic/
│   │   ├── vertic_project/
│   │   │   ├── vertic_client_app/     # Client App (E-Mail-Bestätigung)
│   │   │   └── vertic_staff_app/      # Staff App (E-Mail-Bestätigung)
│   │   └── vertic_server/
│   │       └── vertic_server_server/  # Backend (E-Mail-Endpoints)
│   └── DOKUMENTATION.md
└── README.md
```

### **Branch-Strategie**
- **main:** Production-ready Code mit E-Mail-Bestätigungssystem
- **develop:** Development Branch für neue Features
- **feature/email-verification:** E-Mail-Bestätigungsfeatures (✅ abgeschlossen)
- **hotfix/:** Kritische Bugfixes

---

## 🔐 SICHERHEITSRICHTLINIEN

### **⚠️ KRITISCHE REGELN - NIEMALS VERGESSEN!**

#### **1. KEINE PASSWÖRTER IN GIT**
```bash
# ❌ NIEMALS committen:
password: "GreifbarB2019"
POSTGRES_PASSWORD=GreifbarB2019
DATABASE_PASSWORD: "secret123"

# ✅ IMMER verwenden:
password: ${POSTGRES_PASSWORD}
POSTGRES_PASSWORD: ${DATABASE_PASSWORD}
```

#### **2. .gitignore ERWEITERN**
```gitignore
# Passwörter & Secrets
.env
.env.local
.env.production
*.key
*.pem
config/secrets.yaml

# E-Mail-Bestätigungskeys (falls verwendet)
email_verification_keys/
*.verification.key

# Development
.vscode/settings.json
.idea/
*.log
```

#### **3. GIT HISTORY BEREINIGEN (falls erforderlich)**
```bash
# Passwörter aus Git-History entfernen
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch config/secrets.yaml' \
  --prune-empty --tag-name-filter cat -- --all

# Alternative: BFG Repo-Cleaner
java -jar bfg.jar --delete-files "*.env" --delete-files "secrets.yaml"
git reflog expire --expire=now --all && git gc --prune=now --aggressive
```

---

## 📧 E-MAIL-BESTÄTIGUNGSFEATURES

### **🎯 NEUE COMMITS FÜR E-MAIL-SYSTEM**

#### **Server-Side Commits:**
```bash
# Backend-Endpoints für E-Mail-Bestätigung
git add vertic_app/vertic/vertic_server/vertic_server_server/lib/src/endpoints/unified_auth_endpoint.dart
git commit -m "feat: E-Mail-Bestätigungsendpoints implementiert

- createStaffUserWithEmail: Staff-User mit echter E-Mail erstellen
- verifyStaffEmail: E-Mail-Bestätigungscode validieren  
- staffSignInFlexible: Login mit Username ODER E-Mail

Closes #123"

# Datenbank-Schema Erweiterungen
git add vertic_app/vertic/vertic_server/vertic_server_server/lib/src/models/staff_user.spy.yaml
git commit -m "feat: E-Mail-Bestätigung Datenbank-Schema

- emailVerifiedAt Feld zu StaffUser hinzugefügt
- employmentStatus erweitert: pending_verification, active, etc.
- Migration vorbereitet für E-Mail-Bestätigungssystem"

# Protocol-Erweiterungen
git add vertic_app/vertic/vertic_server/vertic_server_server/lib/src/protocol/unified_auth_response.yaml
git commit -m "feat: E-Mail-Bestätigungsprotokoll erweitert

- requiresEmailVerification Flag hinzugefügt
- verificationCode für Development-Modus
- Flexible Response für Staff-Erstellung"
```

#### **Client-Side Commits:**
```bash
# E-Mail-Bestätigungsseite für Staff App
git add vertic_app/vertic/vertic_project/vertic_staff_app/lib/pages/admin/email_verification_page.dart
git commit -m "feat: E-Mail-Bestätigungsseite für Staff-App

- Automatische Code-Einfügung für Development
- Orange Development-Hinweis für Testing
- Sofortige Navigation zurück nach Bestätigung
- Responsive Design für verschiedene Bildschirmgrößen"

# RBAC Management Integration
git add vertic_app/vertic/vertic_project/vertic_staff_app/lib/pages/admin/rbac_management_page.dart
git commit -m "feat: E-Mail-Bestätigung in RBAC Management integriert

- Automatische Navigation zur E-Mail-Bestätigungsseite
- requiresEmailVerification Check implementiert
- Echte E-Mail-Adressen in Staff-Management möglich"

# Flexible Login-Optionen
git add vertic_app/vertic/vertic_project/vertic_staff_app/lib/auth/staff_auth_provider.dart
git commit -m "feat: Flexibler Staff-Login implementiert

- Login mit Username ODER E-Mail möglich
- Automatische Erkennung: @ = E-Mail, sonst Username
- staffSignInFlexible Endpoint integriert"
```

### **📊 E-MAIL-BESTÄTIGUNGSFEATURES STATUS**
```bash
# Aktueller Status prüfen
git log --oneline --grep="email" --grep="verification" --all

# E-Mail-bezogene Dateien anzeigen
git ls-files | grep -E "(email|verification)"

# Letzte E-Mail-Bestätigungscommits
git log --oneline -10 --grep="E-Mail"
```

---

## 🚀 STANDARD-WORKFLOWS

### **1. FEATURE ENTWICKLUNG (E-Mail-Bestätigung Beispiel)**

#### **Neues Feature starten:**
```bash
# Feature-Branch erstellen
git checkout -b feature/email-verification-enhancements
git push -u origin feature/email-verification-enhancements

# Entwicklung
# ... E-Mail-Bestätigungsfeatures implementieren ...

# Commits mit aussagekräftigen Nachrichten
git add .
git commit -m "feat: E-Mail-Bestätigungscode-Ablaufzeit implementiert

- Bestätigungscodes laufen nach 24h ab
- Automatische Cleanup-Routine für abgelaufene Codes
- Benutzerfreundliche Fehlermeldungen bei abgelaufenen Codes"

# Feature abschließen
git push origin feature/email-verification-enhancements
```

#### **Feature in main mergen:**
```bash
# Zu main wechseln und aktualisieren
git checkout main
git pull origin main

# Feature mergen
git merge feature/email-verification-enhancements
git push origin main

# Feature-Branch löschen
git branch -d feature/email-verification-enhancements
git push origin --delete feature/email-verification-enhancements
```

### **2. HOTFIX WORKFLOW**

#### **Kritischer Bugfix (E-Mail-System):**
```bash
# Hotfix-Branch von main
git checkout main
git pull origin main
git checkout -b hotfix/email-verification-fix

# Bugfix implementieren
# ... E-Mail-Bestätigungsfehler beheben ...

git add .
git commit -m "fix: E-Mail-Bestätigungscode Validierung korrigiert

- Regex für STAFF_<timestamp> Format korrigiert
- Fehlerbehandlung für ungültige Codes verbessert
- Development-Bypass für Code '123456' beibehalten

Fixes #456"

# Hotfix deployen
git push origin hotfix/email-verification-fix

# In main mergen
git checkout main
git merge hotfix/email-verification-fix
git push origin main

# Hotfix-Branch löschen
git branch -d hotfix/email-verification-fix
git push origin --delete hotfix/email-verification-fix
```

### **3. LOKALE ENTWICKLUNG → PRODUCTION**

#### **Vollständiger Workflow:**
```bash
# 1. Lokale Änderungen (E-Mail-Features)
cd vertic_app/vertic/vertic_server/vertic_server_server
# ... E-Mail-Bestätigungsendpoints entwickeln ...
serverpod generate

# 2. Testen
dart run bin/main.dart
# ... E-Mail-Bestätigungsfeatures testen ...

# 3. Committen
git add .
git commit -m "feat: E-Mail-Bestätigungssystem Production-ready

- Alle E-Mail-Bestätigungsendpoints implementiert
- Datenbank-Migration für emailVerifiedAt Spalte
- Development-Modus mit automatischer Code-Einfügung
- Flexible Login-Optionen (Username/E-Mail)
- Account-Status Management (pending_verification, active)

Testing:
- ✅ Staff-User-Erstellung mit E-Mail
- ✅ E-Mail-Bestätigungsseite
- ✅ Flexibler Login
- ✅ Account-Aktivierung

Ready for production deployment."

# 4. Pushen
git push origin main

# 5. Production Deployment
ssh root@159.69.144.208
cd /opt/vertic
git pull origin main
# ... Deployment-Schritte ...
```

---

## 🌐 REMOTE SERVER DEPLOYMENT

### **1. SERVER-VORBEREITUNG**
```bash
# SSH-Verbindung
ssh root@159.69.144.208

# Repository-Status prüfen
cd /opt/vertic
git status
git log --oneline -5

# E-Mail-Bestätigungsfeatures prüfen
git log --oneline --grep="email" -10
```

### **2. SICHERE DEPLOYMENT-SCHRITTE**
```bash
# 1. Backup erstellen (mit E-Mail-Bestätigungsdaten)
sudo -u postgres pg_dump test_db > backup_before_email_update_$(date +%Y%m%d_%H%M%S).sql

# 2. Code aktualisieren
git stash  # Falls lokale Änderungen vorhanden
git pull origin main
git stash pop  # Falls erforderlich

# 3. E-Mail-Bestätigungsfeatures prüfen
grep -r "createStaffUserWithEmail\|verifyStaffEmail\|staffSignInFlexible" vertic_app/vertic/vertic_server/vertic_server_server/lib/src/endpoints/

# 4. Code generieren
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod generate

# 5. E-Mail-Bestätigungsmodelle prüfen
ls -la lib/src/generated/ | grep -E "(staff_user|unified_auth_response)"

# 6. Container neu bauen und starten
docker-compose -f docker-compose.staging.yaml build --no-cache
docker-compose -f docker-compose.staging.yaml up -d

# 7. E-Mail-Bestätigungssystem testen
curl -X POST http://localhost:8080/unifiedAuth/createStaffUserWithEmail
curl -X POST http://localhost:8080/unifiedAuth/verifyStaffEmail
curl -X POST http://localhost:8080/unifiedAuth/staffSignInFlexible
```

### **3. DEPLOYMENT-VERIFIKATION**
```bash
# Container-Status
docker ps
docker logs vertic-kassensystem-server --tail 20

# E-Mail-Bestätigungsendpoints testen
curl http://159.69.144.208:8080/

# E-Mail-Bestätigungsstatus in Datenbank prüfen
sudo -u postgres psql -d test_db -c "
SELECT 
    \"employeeId\", 
    email, 
    \"employmentStatus\", 
    \"emailVerifiedAt\" 
FROM staff_users 
ORDER BY \"createdAt\" DESC 
LIMIT 5;
"

# Git-Status dokumentieren
git log --oneline -1 > /tmp/current_deployment.txt
echo "Deployed at: $(date)" >> /tmp/current_deployment.txt
```

---

## 🛠️ TROUBLESHOOTING

### **1. MERGE-KONFLIKTE (E-Mail-Features)**
```bash
# Konflikt-Situation
git pull origin main
# CONFLICT (content): Merge conflict in vertic_app/vertic/vertic_server/vertic_server_server/lib/src/endpoints/unified_auth_endpoint.dart

# Konflikte manuell lösen
code vertic_app/vertic/vertic_server/vertic_server_server/lib/src/endpoints/unified_auth_endpoint.dart

# Nach dem Lösen:
git add vertic_app/vertic/vertic_server/vertic_server_server/lib/src/endpoints/unified_auth_endpoint.dart
git commit -m "resolve: Merge-Konflikt in E-Mail-Bestätigungsendpoints gelöst

- createStaffUserWithEmail und verifyStaffEmail Methoden vereint
- Beide Implementierungen beibehalten
- E-Mail-Bestätigungslogik konsolidiert"
```

### **2. VERSEHENTLICHE COMMITS RÜCKGÄNGIG MACHEN**
```bash
# Letzten Commit rückgängig (behalten Änderungen)
git reset --soft HEAD~1

# Letzten Commit komplett rückgängig
git reset --hard HEAD~1

# Bestimmten Commit rückgängig (sicher)
git revert <commit-hash>
git commit -m "revert: E-Mail-Bestätigungsfeature temporär entfernt

Grund: Kompatibilitätsprobleme mit bestehender Authentifizierung
Wird in separatem Branch neu implementiert"
```

### **3. PASSWÖRTER VERSEHENTLICH COMMITTED**
```bash
# SOFORT handeln:
# 1. Passwort aus Datei entfernen
sed -i 's/password: "GreifbarB2019"/password: ${POSTGRES_PASSWORD}/g' config/staging.yaml

# 2. Commit mit Korrektur
git add config/staging.yaml
git commit -m "security: Klartext-Passwort durch Environment Variable ersetzt"

# 3. Git History bereinigen (falls erforderlich)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch config/staging.yaml' \
  --prune-empty --tag-name-filter cat -- --all

# 4. Force Push (VORSICHT!)
git push --force-with-lease origin main

# 5. Passwort auf Server ändern
ssh root@159.69.144.208
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'NewSecurePassword123';"
```

### **4. REPOSITORY KORRUPTION**
```bash
# Repository-Integrität prüfen
git fsck --full

# Repository reparieren
git gc --aggressive --prune=now

# Falls alles fehlschlägt: Neu klonen
cd ..
git clone https://github.com/Kartoffelbauer33/vertic.git vertic_backup
cd vertic_backup
# Lokale Änderungen manuell übertragen
```

---

## 📊 BEST PRACTICES

### **1. COMMIT-NACHRICHTEN (E-Mail-Bestätigung Beispiele)**

#### **Gute Commit-Nachrichten:**
```bash
# Feature-Commits
git commit -m "feat: E-Mail-Bestätigungssystem für Staff-User implementiert

- createStaffUserWithEmail Endpoint hinzugefügt
- verifyStaffEmail Endpoint für Code-Validierung
- staffSignInFlexible für Username/E-Mail Login
- emailVerifiedAt Feld in StaffUser Schema
- employmentStatus Management (pending_verification, active)

Breaking Changes: Keine
Testing: ✅ Alle E-Mail-Bestätigungsflows getestet
Migration: Manuelle SQL-Migration erforderlich"

# Bugfix-Commits
git commit -m "fix: E-Mail-Bestätigungscode Regex korrigiert

Problem: STAFF_<timestamp> Format wurde nicht erkannt
Lösung: Regex von '^STAFF_[0-9]+$' zu '^STAFF_[0-9]{13}$' geändert
Testing: ✅ Bestätigungscodes werden korrekt validiert

Fixes #789"

# Documentation-Commits
git commit -m "docs: E-Mail-Bestätigungssystem Dokumentation erweitert

- Vollständige API-Dokumentation für neue Endpoints
- Entwicklungsworkflow für E-Mail-Features dokumentiert
- Troubleshooting-Guide für häufige Probleme
- Migration-Anleitung für Datenbank-Schema"
```

#### **Schlechte Commit-Nachrichten (vermeiden):**
```bash
# ❌ Zu vage
git commit -m "fixes"
git commit -m "email stuff"
git commit -m "updates"

# ❌ Keine Beschreibung
git commit -m "feat: email verification"

# ❌ Mehrere unrelated Änderungen
git commit -m "feat: email verification + bugfixes + documentation + refactoring"
```

### **2. BRANCH-MANAGEMENT**

#### **Branch-Naming-Konventionen:**
```bash
# Features
feature/email-verification-system
feature/staff-user-management
feature/flexible-login-options

# Bugfixes
fix/email-verification-regex
fix/staff-login-authentication
fix/database-migration-error

# Hotfixes
hotfix/critical-email-verification-bug
hotfix/staff-login-failure

# Documentation
docs/email-verification-api
docs/deployment-guide-update
```

### **3. .gitignore OPTIMIERUNG (E-Mail-System)**
```gitignore
# Vertic-spezifische Ignores
vertic_app/vertic/vertic_server/vertic_server_server/.env
vertic_app/vertic/vertic_server/vertic_server_server/config/secrets.yaml

# E-Mail-Bestätigungssystem
email_verification_codes.txt
email_templates/secrets/
*.verification.key

# Flutter
**/android/local.properties
**/ios/Flutter/flutter_export_environment.sh
**/lib/generated/
**/build/

# Serverpod
**/migrations/*/migration.json
**/generated/
**/.serverpod_cache/

# Development
.vscode/settings.json
.idea/workspace.xml
*.log
debug.log

# Backups
backup_*.sql
*.backup
```

### **4. PRE-COMMIT HOOKS (E-Mail-System)**
```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "🔍 Pre-Commit Checks für E-Mail-Bestätigungssystem..."

# 1. Passwort-Check
if grep -r "password.*:" --include="*.yaml" --include="*.dart" --exclude-dir=.git .; then
    echo "❌ FEHLER: Klartext-Passwörter gefunden!"
    echo "   Verwende Environment Variables: \${PASSWORD}"
    exit 1
fi

# 2. E-Mail-Bestätigungsendpoints prüfen
if ! grep -r "createStaffUserWithEmail\|verifyStaffEmail\|staffSignInFlexible" vertic_app/vertic/vertic_server/vertic_server_server/lib/src/endpoints/ > /dev/null; then
    echo "⚠️  WARNUNG: E-Mail-Bestätigungsendpoints nicht gefunden"
fi

# 3. Serverpod Code-Generation prüfen
cd vertic_app/vertic/vertic_server/vertic_server_server
if ! serverpod generate --dry-run > /dev/null 2>&1; then
    echo "❌ FEHLER: Serverpod Code-Generation fehlgeschlagen"
    echo "   Führe 'serverpod generate' aus"
    exit 1
fi

echo "✅ Pre-Commit Checks erfolgreich"
```

### **5. RELEASE-MANAGEMENT (E-Mail-System)**
```bash
# Release-Branch erstellen
git checkout -b release/v2.1.0-email-verification
git push -u origin release/v2.1.0-email-verification

# Release-Notes erstellen
cat > RELEASE_NOTES_v2.1.0.md << 'EOF'
# Vertic v2.1.0 - E-Mail-Bestätigungssystem

## 🚀 Neue Features
- **E-Mail-Bestätigungssystem für Staff-User**
  - Echte E-Mail-Adressen statt Fake-E-Mails
  - Automatische Code-Einfügung für Development
  - Flexible Login-Optionen (Username oder E-Mail)

## 🔧 API-Änderungen
- **Neue Endpoints:**
  - `POST /unifiedAuth/createStaffUserWithEmail`
  - `POST /unifiedAuth/verifyStaffEmail`
  - `POST /unifiedAuth/staffSignInFlexible`

## 🗄️ Datenbank-Migration
```sql
ALTER TABLE staff_users ADD COLUMN "emailVerifiedAt" timestamp without time zone;
UPDATE staff_users SET "employmentStatus" = 'active' WHERE "employeeId" = 'superuser';
```

## 📱 Client-Apps
- **Staff App:** E-Mail-Bestätigungsseite mit automatischer Code-Einfügung
- **Development-Modus:** Orange Hinweise für Testing

## 🔄 Migration von v2.0.x
1. Datenbank-Migration ausführen (siehe oben)
2. Server neu starten
3. Apps neu builden

## 🐛 Bekannte Probleme
- Serverpod-Migrations können fehlschlagen → Manuelle SQL-Ausführung erforderlich

## 📞 Support
Bei Problemen: Siehe VERTIC_DEVELOPMENT_GUIDE.md
EOF

# Release-Tag erstellen
git tag -a v2.1.0 -m "Release v2.1.0: E-Mail-Bestätigungssystem

- Vollständiges E-Mail-Bestätigungssystem implementiert
- Staff-User können mit echten E-Mail-Adressen erstellt werden
- Flexible Login-Optionen (Username/E-Mail)
- Development-friendly mit automatischer Code-Einfügung
- Production-ready mit Account-Status Management"

git push origin v2.1.0
```

---

## 📞 QUICK REFERENCE

### **Häufige Git-Befehle (E-Mail-System)**
```bash
# E-Mail-bezogene Commits anzeigen
git log --oneline --grep="email" --grep="verification" --all

# E-Mail-Bestätigungsfeatures Status
git diff HEAD~1 --name-only | grep -E "(email|verification)"

# Letzten E-Mail-Commit rückgängig
git revert $(git log --oneline --grep="email" -1 --format="%H")

# E-Mail-Features in anderem Branch
git checkout feature/email-enhancements
git cherry-pick <commit-hash>

# Deployment-Status prüfen
ssh root@159.69.144.208 "cd /opt/vertic && git log --oneline -1"
```

### **Sicherheits-Checkliste vor jedem Push**
```bash
# 1. Passwort-Check
grep -r "password.*:" --include="*.yaml" --include="*.dart" --exclude-dir=.git .

# 2. .env Dateien prüfen
find . -name ".env*" -not -path "./.git/*"

# 3. E-Mail-Bestätigungsendpoints vorhanden
grep -r "createStaffUserWithEmail" vertic_app/vertic/vertic_server/vertic_server_server/lib/src/endpoints/

# 4. Serverpod Code generiert
cd vertic_app/vertic/vertic_server/vertic_server_server && serverpod generate --dry-run

# 5. Commit-Nachricht aussagekräftig
git log --oneline -1
```

---

**🎯 MIT DIESEM GUIDE:**
- ✅ **Sichere Git-Workflows** ohne Passwort-Leaks
- ✅ **E-Mail-Bestätigungsfeatures** ordentlich versioniert
- ✅ **Professionelle Commit-Nachrichten** für bessere Nachverfolgung
- ✅ **Effiziente Deployment-Prozesse** für Production
- ✅ **Troubleshooting-Strategien** für häufige Git-Probleme

**🚀 E-MAIL-BESTÄTIGUNGSSYSTEM ERFOLGREICH IN GIT INTEGRIERT!** 