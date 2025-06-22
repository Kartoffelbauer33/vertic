# 🚀 VERTIC DEVELOPMENT GUIDE

**Vollständige Anleitung für die Entwicklung am Vertic-System**

---

## 📋 INHALTSVERZEICHNIS

1. [🏗️ Entwicklungsumgebung Setup](#entwicklungsumgebung-setup)
2. [🔧 Lokale Entwicklung](#lokale-entwicklung)
3. [🌐 Remote Server Entwicklung](#remote-server-entwicklung)
4. [🗄️ Datenbank Management](#datenbank-management)
5. [🔐 RBAC System](#rbac-system)
6. [📱 App Development](#app-development)
7. [🐳 Docker & Deployment](#docker--deployment)
8. [🛠️ Troubleshooting](#troubleshooting)

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
```

### Superuser Login Daten
- **Email**: `superuser@staff.vertic.local`
- **Password**: `super123`
- **App**: Staff App

### Datenbank-Backup
```bash
# Auf dem Server
docker exec vertic-postgres pg_dump -U vertic_user test_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Migration erstellen
```bash
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod create-migration
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

### Staff App (Admin App)
```bash
cd vertic_project/vertic_staff_app

# Lokal gegen lokalen Server
flutter run

# Gegen Remote Server  
flutter run --dart-define=SERVER_URL=http://159.69.144.208:8080
```

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

#### 2. Serverpod Generate Fehler
```bash
# Flutter PATH prüfen
echo $PATH
export PATH="$PATH:/opt/flutter/bin:$HOME/.pub-cache/bin"

# Dependencies neu installieren
dart pub get
serverpod generate
```

#### 3. Docker Build Fehler
```bash
# IMMER vom Repository-Root bauen!
cd Leon_vertic
docker build -f vertic_app/vertic/vertic_server/vertic_server_server/Dockerfile -t vertic-server .
```

#### 4. Database Connection Fehler
```bash
# Postgres Container prüfen
docker ps | grep postgres
docker logs vertic-postgres

# Connection String prüfen
# config/development.yaml oder production.yaml
```

#### 5. Permission Fehler in Apps
```bash
# RBAC System neu initialisieren
# 1. 01_CLEAN_SETUP_FINAL_CORRECTED.sql ausführen
# 2. 02_CREATE_SUPERUSER_FINAL_CORRECTED.sql ausführen
# 3. Mit superuser@staff.vertic.local / super123 einloggen
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
5. **RBAC System** vor App-Tests initialisieren
6. **Keine Klartextpasswörter** in Git committen
7. **Regelmäßige Backups** der Produktionsdatenbank

### Git Workflow
```bash
# Änderungen committen
git add .
git commit -m "feat: neue Feature Beschreibung"
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
- **Superuser**: `superuser@staff.vertic.local` / `super123`

---

**🎯 HAPPY CODING!** 

Bei Problemen: Erst diese Dokumentation checken, dann troubleshooten! 🚀 