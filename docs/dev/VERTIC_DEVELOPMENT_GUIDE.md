# 🚀 VERTIC DEVELOPMENT GUIDE

**Vollständige Anleitung für die Entwicklung am Vertic-System**  
**Version:** 2.1 (E-Mail-Bestätigung Update)  
**Aktualisiert:** 2025-01-16

---

## 📋 INHALTSVERZEICHNIS

1. [🏗️ Entwicklungsumgebung Setup](#entwicklungsumgebung-setup)
2. [🔧 Lokale Entwicklung](#lokale-entwicklung)
3. [🌐 Remote Server Entwicklung](#remote-server-entwicklung)
4. [🗄️ Datenbank Management](#datenbank-management)
5. [📧 E-Mail-Bestätigungssystem](#e-mail-bestätigungssystem)
6. [🔐 RBAC System](#rbac-system)
7. [📱 App Development](#app-development)
8. [🐳 Docker & Deployment](#docker--deployment)
9. [🛠️ Troubleshooting](#troubleshooting)

---

## 🏗️ ENTWICKLUNGSUMGEBUNG SETUP

### Voraussetzungen
- **Flutter 3.24+**
- **Dart 3.5+**
- **Docker & Docker Compose**
- **PostgreSQL Client Tools**
- **VS Code** mit Flutter Extension

### Projekt-Struktur
```
Leon_vertic/
├── vertic_app/vertic/
│   ├── vertic_project/
│   │   ├── vertic_client_app/     # 📱 Client App (User)
│   │   └── vertic_staff_app/      # 👨‍💼 Staff App (Admin)
│   └── vertic_server/
│       ├── vertic_server_client/  # 📡 Generated Client
│       └── vertic_server_server/  # 🖥️ Backend Server
└── SQL/                           # 🗄️ Database Scripts
```

---

## 🔧 LOKALE ENTWICKLUNG

### 1. Repository klonen
```bash
git clone <repository-url>
cd Leon_vertic
```

### 2. Dependencies installieren
```bash
# Server Dependencies
cd vertic_app/vertic/vertic_server/vertic_server_server
dart pub get

# Client App Dependencies  
cd ../../vertic_project/vertic_client_app
flutter pub get

# Staff App Dependencies
cd ../vertic_staff_app
flutter pub get
```

### 3. Lokale Datenbank starten
```bash
cd vertic_app/vertic/vertic_server/vertic_server_server
docker-compose up -d postgres
```

### 4. Code generieren (WICHTIG!)
```bash
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod generate
```

### 5. Server lokal starten
```bash
dart bin/main.dart --apply-migrations
```

---

## 🌐 REMOTE SERVER ENTWICKLUNG

### Server-Informationen
- **IP**: `159.69.144.208`
- **OS**: Ubuntu 22.04 LTS
- **Server**: Serverpod auf Port 8080
- **Database**: PostgreSQL auf Port 5432

### SSH Verbindung
```bash
ssh root@159.69.144.208
```

### Code auf Server aktualisieren
```bash
# Auf dem Server
cd /opt/vertic/vertic
git pull origin main

# Code regenerieren
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod generate

# Docker neu bauen und starten
docker-compose -f docker-compose.prod.yaml build
docker-compose -f docker-compose.prod.yaml up -d
```

### ⚠️ KRITISCHE BEFEHLE FÜR ENTWICKLUNG GEGEN SERVER

**Wenn du gegen den Remote Server entwickeln willst:**

```bash
# 1. Server IP in Client-Apps konfigurieren
# In vertic_client_app/lib/config/
# In vertic_staff_app/lib/config/
# Setze SERVER_URL = 'http://159.69.144.208:8080'

# 2. Apps gegen Remote Server starten
cd vertic_project/vertic_client_app
flutter run --dart-define=SERVER_URL=http://159.69.144.208:8080/

cd ../vertic_staff_app  
flutter run --dart-define=SERVER_URL=http://159.69.144.208:8080/
```

---

## 🗄️ DATENBANK MANAGEMENT

### pgAdmin4 Zugang
- **URL**: http://159.69.144.208/pgadmin4/browser/
- **Login**: `guntram@greifbar-bouldern.at` / `[internal]`
- **Database**: `test_db`

### Wichtige SQL Scripts
```bash
# RBAC System initialisieren (53 Permissions + 5 Rollen)
01_CLEAN_SETUP_FINAL_CORRECTED.sql

# Superuser erstellen
02_CREATE_SUPERUSER_FINAL_CORRECTED.sql

# E-Mail-Bestätigung für bestehende User
UPDATE_SUPERUSER_EMAIL_VERIFICATION.sql
```

### Superuser Login Daten
- **Username**: `superuser` ODER **E-Mail**: `superuser@staff.vertic.local`
- **Password**: `super123`
- **App**: Staff App
- **Status**: `active` (E-Mail bestätigt)

### Datenbank-Backup
```bash
# Auf dem Server
docker exec vertic-postgres pg_dump -U vertic_user test_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Migration erstellen
```bash
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod create-migration

# Bei Problemen: Manuelle SQL-Ausführung über PgAdmin
```

---

## 📧 E-MAIL-BESTÄTIGUNGSSYSTEM

### **✅ VOLLSTÄNDIG IMPLEMENTIERT**

#### **Neue Staff-User-Erstellung mit E-Mail-Bestätigung:**
```dart
// Admin erstellt Staff-User
final result = await client.unifiedAuth.createStaffUserWithEmail(
  'admin@greifbar-bouldern.at', // Echte E-Mail
  'admin',                      // Username
  'sicheresPasswort',           // Password
  'Max',                        // Vorname
  'Administrator',              // Nachname
  StaffUserType.admin,          // Staff-Level
);

// Automatische Navigation zur E-Mail-Bestätigung
if (result.requiresEmailVerification == true) {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => EmailVerificationPage(
      email: email,
      verificationCode: result.verificationCode!, // STAFF_<timestamp>
    ),
  ));
}
```

#### **E-Mail-Bestätigungsseite:**
- ✅ **Automatische Code-Einfügung** (Entwicklungsmodus)
- ✅ **Orange Development-Hinweis** für Testing
- ✅ **Sofortige Navigation** zurück nach Bestätigung

#### **Flexibler Staff-Login:**
```dart
// Login mit Username ODER E-Mail
final result = await client.unifiedAuth.staffSignInFlexible(
  'admin',                      // ODER 'admin@greifbar-bouldern.at'
  'sicheresPasswort',
);
```

### **Datenbank-Schema Erweiterungen:**
```sql
-- Neue Spalte in staff_users
ALTER TABLE staff_users ADD COLUMN "emailVerifiedAt" timestamp without time zone;

-- Account-Status Management
employment_status:
- 'pending_verification' -- Neu erstellt, E-Mail nicht bestätigt
- 'active'              -- E-Mail bestätigt, kann sich anmelden
- 'on_leave'            -- Temporär deaktiviert
- 'terminated'          -- Dauerhaft deaktiviert
- 'suspended'           -- Administrativ gesperrt
```

---

## 🔐 RBAC SYSTEM

### Permissions System
**53 Permissions in 9 Kategorien:**
- `user_management` (14 Permissions)
- `staff_management` (11 Permissions)  
- `ticket_management` (10 Permissions)
- `system_settings` (4 Permissions)
- `rbac_management` (3 Permissions)
- `facility_management` (4 Permissions)
- `reporting_analytics` (4 Permissions)
- `status_management` (4 Permissions)
- `gym_management` (4 Permissions)

### Rollen System
1. **Super Admin** - Alle 53 Permissions
2. **Facility Admin** - Einrichtungsverwaltung  
3. **Kassierer** - Ticketverkauf (9 Permissions)
4. **Support Staff** - Kundenbetreuung (9 Permissions)
5. **Readonly User** - Nur-Lese-Zugriff

### RBAC Tabellen
- `permissions` - Alle verfügbaren Berechtigungen
- `roles` - Rollendefinitionen
- `role_permissions` - Rollen ↔ Permissions Zuordnung
- `staff_user_roles` - User ↔ Rollen Zuordnung
- `staff_user_permissions` - Direkte User ↔ Permissions

---

## 📱 APP DEVELOPMENT

### Client App (User App)
```bash
cd vertic_project/vertic_client_app

# Lokal gegen lokalen Server
flutter run

# Gegen Remote Server
flutter run --dart-define=SERVER_URL=http://159.69.144.208:8080
```

### Staff App (Admin App) - UPDATED
```bash
cd vertic_project/vertic_staff_app

# Lokal gegen lokalen Server
flutter run

# Gegen Remote Server  
flutter run --dart-define=SERVER_URL=http://159.69.144.208:8080
```

#### **Neue Staff-App Features:**
- ✅ **E-Mail-Bestätigungsseite** (`EmailVerificationPage`)
- ✅ **Flexible Login-Optionen** (Username oder E-Mail)
- ✅ **Automatische Code-Einfügung** für Development
- ✅ **Echte E-Mail-Adressen** in Staff-Management

### Server Client Update
**Nach Änderungen am Server:**
```bash
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod generate

# Client Code wird automatisch in vertic_server_client/ generiert
# Apps müssen neu gebuildet werden
```

---

## 🐳 DOCKER & DEPLOYMENT

### Lokale Entwicklung
```bash
# Nur Datenbank starten
docker-compose up -d postgres

# Komplettes System lokal
docker-compose up -d
```

### Production Deployment
```bash
# Auf dem Server
cd /opt/vertic/vertic/vertic_app/vertic/vertic_server/vertic_server_server

# Build & Deploy
docker-compose -f docker-compose.prod.yaml build
docker-compose -f docker-compose.prod.yaml up -d

# Status prüfen
docker-compose -f docker-compose.prod.yaml ps
docker-compose -f docker-compose.prod.yaml logs -f
```

### Container Management
```bash
# Services stoppen
docker-compose -f docker-compose.prod.yaml down

# Services neu starten
docker-compose -f docker-compose.prod.yaml restart

# Logs anzeigen
docker logs vertic-server
docker logs vertic-postgres
```

---

## 🛠️ TROUBLESHOOTING

### Häufige Probleme

#### 1. "Database feature is disabled"
```bash
# Lösung: generator.yaml erstellen
cat > config/generator.yaml << 'EOF'
type: server
database: true
client_package_path: ../vertic_server_client
EOF

serverpod generate
```

#### 2. Migration Fehler (E-Mail-System)
```bash
# Problem: "account_cleanup_logs" already exists
# Lösung: Manuelle SQL-Ausführung über PgAdmin

# 1. Spalte hinzufügen
ALTER TABLE staff_users ADD COLUMN "emailVerifiedAt" timestamp without time zone;

# 2. Superuser aktivieren
UPDATE staff_users 
SET 
    "employmentStatus" = 'active',
    "emailVerifiedAt" = NOW()
WHERE 
    "employeeId" = 'superuser';

# 3. Migration als erfolgreich markieren
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
VALUES ('vertic_server', '20250622230632803', now())
ON CONFLICT ("module")
DO UPDATE SET "version" = '20250622230632803', "timestamp" = now();
```

#### 3. Serverpod Generate Fehler
```bash
# Flutter PATH prüfen
echo $PATH
export PATH="$PATH:/opt/flutter/bin:$HOME/.pub-cache/bin"

# Dependencies neu installieren
dart pub get
serverpod generate
```

#### 4. Docker Build Fehler
```bash
# IMMER vom Repository-Root bauen!
cd Leon_vertic
docker build -f vertic_app/vertic/vertic_server/vertic_server_server/Dockerfile -t vertic-server .
```

#### 5. E-Mail-Bestätigungsprobleme
```bash
# E-Mail-Bestätigungsseite nicht erreichbar:
# 1. Prüfe ob EmailVerificationPage existiert
# 2. Prüfe Navigation-Code in RBAC-Management
# 3. Prüfe Server-Response: requiresEmailVerification = true

# Code nicht automatisch eingefügt:
# 1. Development-Mode aktiv?
# 2. verificationCode in Response vorhanden?
# 3. _fillDevelopmentCode() Methode aufgerufen?
```

### Debug Befehle
```bash
# Server Status
curl http://159.69.144.208:8080/

# Container Logs
docker logs vertic-server --tail 100 -f

# Database Connect
docker exec -it vertic-postgres psql -U vertic_user -d test_db

# Flutter Doctor
flutter doctor -v

# Serverpod Version
serverpod --version
```

---

## 🔥 KRITISCHE REGELN

### ⚠️ NIEMALS VERGESSEN:

1. **Ubuntu 22.04 LTS** verwenden - NIEMALS 24.04!
2. **`serverpod generate`** nach JEDER Server-Änderung
3. **Docker Build vom Repository-Root** ausführen
4. **generator.yaml mit database: true** ist ZWINGEND
5. **E-Mail-Bestätigungssystem** vor App-Tests initialisieren
6. **Manuelle SQL-Migration** bei Serverpod-Problemen
7. **Keine Klartextpasswörter** in Git committen
8. **Regelmäßige Backups** der Produktionsdatenbank

### Git Workflow
```bash
# Änderungen committen
git add .
git commit -m "feat: E-Mail-Bestätigungssystem implementiert"
git push origin main

# Auf Server deployen
ssh root@159.69.144.208
cd /opt/vertic/vertic
git pull origin main
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod generate
docker-compose -f docker-compose.prod.yaml build
docker-compose -f docker-compose.prod.yaml up -d
```

---

## 📞 QUICK REFERENCE

### Wichtige URLs
- **Server API**: http://159.69.144.208:8080
- **pgAdmin4**: http://159.69.144.208/pgadmin4/
- **GitHub**: [Repository URL]

### Wichtige Befehle
```bash
# Code generieren
serverpod generate

# Apps starten (gegen Remote)
flutter run --dart-define=SERVER_URL=http://159.69.144.208:8080

# Server deployen
docker-compose -f docker-compose.prod.yaml up -d --build

# Logs anzeigen
docker-compose -f docker-compose.prod.yaml logs -f
```

### Login Daten
- **SSH**: `root@159.69.144.208`
- **pgAdmin**: `guntram@greifbar-bouldern.at`
- **Superuser**: `superuser` / `super123` (Username oder E-Mail möglich)

### Neue E-Mail-Bestätigungsfeatures
```dart
// Staff-User mit E-Mail erstellen
client.unifiedAuth.createStaffUserWithEmail(...)

// E-Mail bestätigen  
client.unifiedAuth.verifyStaffEmail(email, code)

// Flexibler Login
client.unifiedAuth.staffSignInFlexible(usernameOrEmail, password)
```

---

**🎯 HAPPY CODING!** 

Das E-Mail-Bestätigungssystem ist vollständig implementiert und produktionsbereit! Bei Problemen: Erst diese Dokumentation checken, dann troubleshooten! 🚀 