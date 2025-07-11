# 🚀 VERTIC HETZNER SERVER - MASTER MANAGEMENT GUIDE

**Umfassende Dokumentation aller kritischen Erkenntnisse aus 8 Stunden Troubleshooting**  
*Alles was du über den Hetzner Server wissen musst - von Setup bis Deployment*  
**Version:** 2.1 (E-Mail-Bestätigung Update)  
**Aktualisiert:** 2025-01-16

---

## 📋 SYSTEM ÜBERSICHT

### 🖥️ **SERVER DETAILS**
- **Provider:** Hetzner Cloud
- **Typ:** CX21 (2 vCPU, 4 GB RAM, 40 GB SSD)
- **IP:** `159.69.144.208`
- **OS:** Ubuntu 24.04.2 LTS
- **Location:** `/opt/vertic/`

### 🐳 **DOCKER ARCHITEKTUR**
```
🌐 Internet
    ↓
🔥 Hetzner Firewall (Ports 22, 80, 8080-8082)
    ↓
🖥️ Ubuntu Server (159.69.144.208)
    ├── 🐳 Docker Container: vertic-server (Port 8080-8082)
    │   └── 📧 E-Mail-Bestätigungssystem
    └── 🗄️ PostgreSQL System Service (Port 5432)
        └── 📧 emailVerifiedAt Spalte
```

### ⚠️ **KRITISCHE ERKENNTNISSE**
1. **PostgreSQL läuft NICHT in Docker** - System-Service auf Ubuntu
2. **Docker Container verbindet zu System-PostgreSQL** via `host.docker.internal`
3. **Docker Build MUSS vom Repository-Root** ausgeführt werden
4. **Serverpod 2.8.0 braucht generator.yaml** mit `database: true`
5. **E-Mail-Bestätigungssystem** erfordert manuelle Datenbank-Migration
6. **Ubuntu 24.04 hat IPv6-Probleme** - aber läuft jetzt stabil

---

## 📧 **E-MAIL-BESTÄTIGUNGSSYSTEM INTEGRATION**

### **🗄️ DATENBANK-SCHEMA ERWEITERUNGEN**
```sql
-- Neue Spalte in staff_users Tabelle
ALTER TABLE staff_users ADD COLUMN "emailVerifiedAt" timestamp without time zone;

-- Account-Status Management
employment_status:
- 'pending_verification' -- Neu erstellt, E-Mail nicht bestätigt
- 'active'              -- E-Mail bestätigt, kann sich anmelden
- 'on_leave'            -- Temporär deaktiviert
- 'terminated'          -- Dauerhaft deaktiviert
- 'suspended'           -- Administrativ gesperrt
```

### **🚀 NEUE SERVER-ENDPOINTS**
```
POST /unifiedAuth/createStaffUserWithEmail
- Erstellt Staff-User mit echter E-Mail
- Setzt employmentStatus: 'pending_verification'
- Generiert Bestätigungscode: STAFF_<timestamp>

POST /unifiedAuth/verifyStaffEmail  
- Validiert Bestätigungscode
- Aktiviert Account (employmentStatus: 'active')
- Setzt emailVerifiedAt: NOW()

POST /unifiedAuth/staffSignInFlexible
- Login mit Username ODER E-Mail möglich
- Automatische Erkennung: @ = E-Mail, sonst Username
```

### **🔧 MIGRATION DURCHFÜHRUNG**
```bash
# Auf Server via pgAdmin
http://159.69.144.208/pgadmin4

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

---

## 🔐 SSH ZUGANG & MANAGEMENT

### **SSH-VERBINDUNG**
```powershell
# Standard SSH (von Windows)
ssh root@159.69.144.208

# Mit spezifischem Key
ssh -i C:\Users\guntr\.ssh\vertic_server root@159.69.144.208

# SSH-Status prüfen
systemctl status sshd
```

### **SSH PROBLEME LÖSEN**
```bash
# SSH-Service reparieren
systemctl restart sshd
systemctl enable sshd

# Firewall prüfen
ufw status
ufw allow 22/tcp

# SSH-Logs anzeigen
journalctl -u sshd -f
```

### **HETZNER CONSOLE BACKUP**
- **URL:** https://console.hetzner.cloud
- **Server:** vertic → Console Tab
- **Login:** root / [Passwort aus Hetzner]

---

## 🗄️ POSTGRESQL SYSTEM (KRITISCH!)

### **WARUM SYSTEM-POSTGRESQL?**
- **Docker PostgreSQL hatte Probleme** mit Persistenz
- **System-Service ist stabiler** für Production
- **Einfachere Backups** und Wartung
- **pgAdmin4 läuft direkt** auf System-PostgreSQL
- **E-Mail-Bestätigungsfeatures** erfordern stabile Datenbank

### **POSTGRESQL MANAGEMENT**
```bash
# Service-Status
systemctl status postgresql
systemctl start postgresql
systemctl restart postgresql

# Direkte Verbindung
sudo -u postgres psql -d test_db

# E-Mail-Bestätigungsstatus prüfen
sudo -u postgres psql -d test_db -c "
SELECT 
    \"employeeId\", 
    email, 
    \"employmentStatus\", 
    \"emailVerifiedAt\" 
FROM staff_users;
"

# Verbindung testen (aus Docker)
pg_isready -h host.docker.internal -p 5432 -U postgres

# Backup erstellen
sudo -u postgres pg_dump test_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### **POSTGRESQL KONFIGURATION**
- **Host:** `localhost` (System) / `host.docker.internal` (Docker)
- **Port:** `5432`
- **Database:** `test_db`
- **User:** `postgres`
- **Password:** `GreifbarB2019`

---

## 🐳 DOCKER CONTAINER MANAGEMENT

### **CONTAINER ARCHITEKTUR**
```yaml
# docker-compose.staging.yaml
services:
  vertic-server:
    build: ../../../../..  # Build vom Repository-Root!
    ports:
      - "8080:8080"  # API Server (inkl. E-Mail-Endpoints)
      - "8081:8081"  # Insights Dashboard  
      - "8082:8082"  # Web Interface
    environment:
      - RUNMODE=staging
    extra_hosts:
      - "host.docker.internal:host-gateway"  # PostgreSQL Zugang
```

### **DOCKER BEFEHLE**
```bash
# Container-Status
docker ps
docker-compose -f docker-compose.staging.yaml ps

# Logs anzeigen (E-Mail-Bestätigungsaktivitäten)
docker logs vertic-kassensystem-server | grep -E "(createStaffUserWithEmail|verifyStaffEmail|staffSignInFlexible)"
docker-compose -f docker-compose.staging.yaml logs -f

# Container neu starten
docker-compose -f docker-compose.staging.yaml restart
docker-compose -f docker-compose.staging.yaml down
docker-compose -f docker-compose.staging.yaml up -d

# Build & Deploy (KRITISCH: Vom Repository-Root!)
cd /opt/vertic
docker build -f vertic_app/vertic/vertic_server/vertic_server_server/Dockerfile -t vertic-server .
cd vertic_app/vertic/vertic_server/vertic_server_server
docker-compose -f docker-compose.staging.yaml up -d
```

### **E-MAIL-BESTÄTIGUNGSSYSTEM TESTEN**
```bash
# Health-Check für E-Mail-Endpoints
curl -X POST http://159.69.144.208:8080/unifiedAuth/createStaffUserWithEmail \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","username":"testuser",...}'

# Container-Logs für E-Mail-Aktivitäten
docker logs vertic-kassensystem-server --tail 100 | grep -E "STAFF_[0-9]+"
```

---

## 🔧 SERVERPOD KONFIGURATION

### **KRITISCHE KONFIGURATIONSDATEIEN**
```bash
# Staging-Konfiguration
/opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server/config/staging.yaml

# Generator-Konfiguration (ZWINGEND!)
/opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server/config/generator.yaml
```

### **config/staging.yaml - WICHTIGE EINSTELLUNGEN**
```yaml
apiServer:
  port: 8080
  publicHost: 159.69.144.208  # Hetzner IP
  publicPort: 8080

database:
  host: host.docker.internal  # System-PostgreSQL
  port: 5432
  name: test_db
  user: postgres
  requireSsl: false
```

### **config/generator.yaml - KRITISCH!**
```yaml
type: server
database: true  # OHNE DIESE ZEILE GEHT NICHTS!
client_package_path: ../vertic_server_client

# Flutter clients für E-Mail-Bestätigungsseiten
flutter_clients:
  - path: ../../vertic_project/vertic_client_app
    name: vertic_client_app
  - path: ../../vertic_project/vertic_staff_app  
    name: vertic_staff_app
```

### **SERVERPOD CODE-GENERIERUNG**
```bash
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server

# Dependencies installieren
dart pub get

# Code generieren (NACH JEDER ÄNDERUNG!)
serverpod generate

# Prüfen ob E-Mail-Bestätigungsmodelle generiert wurden
ls -la lib/src/generated/ | grep -E "(staff_user|unified_auth_response)"

# E-Mail-Bestätigungsendpoints prüfen
grep -r "createStaffUserWithEmail\|verifyStaffEmail\|staffSignInFlexible" lib/src/endpoints/
```

---

## 🚀 DEPLOYMENT WORKFLOW

### **1. LOKALE ENTWICKLUNG → SERVER DEPLOYMENT (UPDATED)**
```bash
# 1. Lokal entwickeln und E-Mail-Features testen
cd Leon_vertic/vertic_app/vertic/vertic_server/vertic_server_server
dart run bin/main.dart

# 2. E-Mail-Bestätigungsfeatures testen
# - Staff-User mit E-Mail erstellen
# - E-Mail-Bestätigungsseite testen
# - Flexibler Login testen

# 3. Code committen (OHNE Passwörter!)
git add .
git commit -m "feat: E-Mail-Bestätigungssystem implementiert"
git push origin main

# 4. Auf Server deployen
ssh root@159.69.144.208
cd /opt/vertic
git pull origin main
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod generate
docker-compose -f docker-compose.staging.yaml build --no-cache
docker-compose -f docker-compose.staging.yaml up -d
```

### **2. DEPLOYMENT-SCRIPT (AUTOMATISIERT)**
```bash
# Deployment-Script verwenden
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server
bash deploy_to_hetzner.sh
```

### **3. DEPLOYMENT VERIFIKATION (UPDATED)**
```bash
# Health-Checks
curl http://159.69.144.208:8080/
curl http://159.69.144.208:8081/
curl http://159.69.144.208:8082/

# E-Mail-Bestätigungsendpoints testen
curl -X POST http://159.69.144.208:8080/unifiedAuth/createStaffUserWithEmail
curl -X POST http://159.69.144.208:8080/unifiedAuth/verifyStaffEmail
curl -X POST http://159.69.144.208:8080/unifiedAuth/staffSignInFlexible

# Container-Status
docker ps
docker logs vertic-kassensystem-server --tail 20

# Database-Verbindung und E-Mail-Status
pg_isready -h localhost -p 5432 -U postgres
sudo -u postgres psql -d test_db -c "SELECT COUNT(*) FROM staff_users WHERE \"employmentStatus\" = 'pending_verification';"
```

---

## 🌐 NETZWERK & FIREWALL

### **HETZNER CLOUD FIREWALL**
```
Inbound Rules:
✅ Port 22 (SSH)     - TCP - 0.0.0.0/0
✅ Port 80 (HTTP)    - TCP - 0.0.0.0/0
✅ Port 8080 (API)   - TCP - 0.0.0.0/0 (inkl. E-Mail-Endpoints)
✅ Port 8081 (Insights) - TCP - 0.0.0.0/0
✅ Port 8082 (Web)   - TCP - 0.0.0.0/0
```

### **UBUNTU UFW FIREWALL**
```bash
# Status prüfen
ufw status verbose

# Ports freigeben
ufw allow 22/tcp
ufw allow 80/tcp  
ufw allow 8080/tcp  # E-Mail-Bestätigungsendpoints
ufw allow 8081/tcp
ufw allow 8082/tcp

# UFW neu laden
ufw reload
```

### **PORT-TESTS (UPDATED)**
```bash
# Intern (auf Server)
netstat -tlnp | grep -E ':(22|80|8080|8081|8082|5432)'
ss -tlnp | grep -E ':(8080|8081|8082)'

# E-Mail-Endpoints testen
curl -X POST http://localhost:8080/unifiedAuth/createStaffUserWithEmail
curl -X POST http://localhost:8080/unifiedAuth/verifyStaffEmail

# Extern (von Windows)
Test-NetConnection -ComputerName 159.69.144.208 -Port 8080
Test-NetConnection -ComputerName 159.69.144.208 -Port 22
```

---

## 📊 MONITORING & LOGS

### **SERVICE STATUS (UPDATED)**
```bash
# Alle wichtigen Services
systemctl status docker postgresql ssh ufw

# Docker Container
docker ps
docker stats

# E-Mail-Bestätigungsaktivitäten
docker logs vertic-kassensystem-server | grep -E "(createStaffUserWithEmail|verifyStaffEmail|STAFF_[0-9]+)"

# Disk Space
df -h
du -sh /opt/vertic/
```

### **LOG MANAGEMENT (UPDATED)**
```bash
# Serverpod Server Logs mit E-Mail-Filter
docker logs vertic-kassensystem-server --tail 100 -f | grep -E "(email|STAFF_|verification)"

# System Logs
journalctl -u docker -f
journalctl -u postgresql -f
journalctl -u ssh -f

# E-Mail-Bestätigungsstatistiken
sudo -u postgres psql -d test_db -c "
SELECT 
    \"employmentStatus\", 
    COUNT(*) 
FROM staff_users 
GROUP BY \"employmentStatus\";
"
```

### **PERFORMANCE MONITORING (UPDATED)**
```bash
# CPU & Memory
top
htop
free -h

# Docker Ressourcen
docker stats vertic-kassensystem-server

# PostgreSQL Performance mit E-Mail-Aktivitäten
sudo -u postgres psql -d test_db -c "
SELECT 
    query, 
    calls, 
    total_time, 
    mean_time 
FROM pg_stat_statements 
WHERE query LIKE '%staff_users%' OR query LIKE '%email%'
ORDER BY total_time DESC 
LIMIT 10;
"
```

---

## 🗄️ PGADMIN4 WEB-INTERFACE (UPDATED)

### **ZUGANG**
- **URL:** http://159.69.144.208/pgadmin4/
- **Login:** `guntram@greifbar-bouldern.at`
- **Password:** `[siehe Server]`

### **DATABASE CONNECTION**
- **Host:** `159.69.144.208` (NICHT localhost!)
- **Port:** `5432`
- **Database:** `test_db`
- **Username:** `postgres`
- **Password:** `GreifbarB2019`

### **E-MAIL-BESTÄTIGUNGSQUERIES**
```sql
-- E-Mail-Bestätigungsstatus aller Staff-User
SELECT 
    "employeeId",
    email,
    "employmentStatus",
    "emailVerifiedAt",
    "createdAt"
FROM staff_users
ORDER BY "createdAt" DESC;

-- Pending E-Mail-Bestätigungen
SELECT COUNT(*) as pending_verifications
FROM staff_users 
WHERE "employmentStatus" = 'pending_verification';

-- Letzte E-Mail-Bestätigungsaktivitäten
SELECT 
    "employeeId",
    email,
    "emailVerifiedAt"
FROM staff_users 
WHERE "emailVerifiedAt" IS NOT NULL
ORDER BY "emailVerifiedAt" DESC
LIMIT 10;
```

---

## 🔄 BACKUP & RESTORE (UPDATED)

### **AUTOMATISCHE BACKUPS (UPDATED)**
```bash
# Backup-Script erstellen
cat > /opt/vertic/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/vertic/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Database Backup mit E-Mail-Bestätigungsdaten
sudo -u postgres pg_dump test_db > $BACKUP_DIR/vertic_db_$DATE.sql

# E-Mail-Bestätigungsstatistiken
sudo -u postgres psql -d test_db -c "
SELECT 
    'Backup Statistics' as info,
    COUNT(*) as total_staff_users,
    COUNT(CASE WHEN \"employmentStatus\" = 'active' THEN 1 END) as active_users,
    COUNT(CASE WHEN \"employmentStatus\" = 'pending_verification' THEN 1 END) as pending_users,
    COUNT(CASE WHEN \"emailVerifiedAt\" IS NOT NULL THEN 1 END) as verified_emails
FROM staff_users;
" >> $BACKUP_DIR/email_verification_stats_$DATE.txt

# Code Backup
tar -czf $BACKUP_DIR/vertic_code_$DATE.tar.gz /opt/vertic/vertic_app/

# Alte Backups löschen (7 Tage)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*.txt" -mtime +7 -delete

echo "$(date): Backup completed - $DATE (with email verification data)"
EOF

chmod +x /opt/vertic/backup.sh

# Crontab für tägliche Backups
echo "0 2 * * * /opt/vertic/backup.sh" | crontab -
```

---

## 🚨 NOTFALL-PROCEDURES (UPDATED)

### **E-MAIL-BESTÄTIGUNGSSYSTEM REPARIEREN**
```bash
# 1. E-Mail-Spalte fehlt
ALTER TABLE staff_users ADD COLUMN "emailVerifiedAt" timestamp without time zone;

# 2. Alle Staff-User auf 'pending_verification'
UPDATE staff_users SET "employmentStatus" = 'pending_verification' WHERE "employmentStatus" IS NULL;

# 3. Superuser aktivieren
UPDATE staff_users 
SET "employmentStatus" = 'active', "emailVerifiedAt" = NOW()
WHERE "employeeId" = 'superuser';

# 4. Migration als erfolgreich markieren
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
VALUES ('vertic_server', '20250622230632803', now())
ON CONFLICT ("module")
DO UPDATE SET "version" = '20250622230632803', "timestamp" = now();
```

### **KOMPLETTER SERVER-NEUSTART**
```bash
# 1. Services stoppen
docker-compose -f docker-compose.staging.yaml down
systemctl stop postgresql

# 2. Server rebooten
reboot

# 3. Nach Neustart prüfen
systemctl status postgresql docker
docker ps

# 4. E-Mail-Bestätigungssystem testen
curl -X POST http://159.69.144.208:8080/unifiedAuth/createStaffUserWithEmail

# 5. Services starten
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server
docker-compose -f docker-compose.staging.yaml up -d
```

---

## 📱 FLUTTER APP ENTWICKLUNG GEGEN SERVER (UPDATED)

### **ENVIRONMENT KONFIGURATION**
```dart
// vertic_staff_app/lib/config/environment.dart
static const String _stagingServer = 'http://159.69.144.208:8080/';

// E-Mail-Bestätigungsendpoints verfügbar:
// - createStaffUserWithEmail
// - verifyStaffEmail  
// - staffSignInFlexible
```

### **APP GEGEN SERVER STARTEN (UPDATED)**
```bash
# Staff App gegen Hetzner Server (mit E-Mail-Features)
cd vertic_project/vertic_staff_app
flutter run --dart-define=USE_STAGING=true

# E-Mail-Bestätigungsfeatures testen:
# 1. Neuen Staff-User erstellen
# 2. Automatische Navigation zur E-Mail-Bestätigungsseite
# 3. Code automatisch eingefügt
# 4. E-Mail bestätigen
# 5. Login mit Username UND E-Mail testen

# Client App gegen Hetzner Server
cd ../vertic_client_app
flutter run --dart-define=USE_STAGING=true
```

### **APP DEBUGGING (UPDATED)**
```bash
# Flutter Logs mit E-Mail-Filter
flutter logs | grep -E "(email|verification|STAFF_)"

# Network Debugging für E-Mail-Endpoints
flutter run --dart-define=USE_STAGING=true --verbose | grep -E "(createStaffUserWithEmail|verifyStaffEmail)"

# App mit DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 🔧 WARTUNG & UPDATES (UPDATED)

### **REGELMÄSSIGE WARTUNG (MONATLICH)**
```bash
# System Updates
apt update && apt upgrade -y

# Docker Updates
docker-compose -f docker-compose.staging.yaml pull
docker system prune -f

# E-Mail-Bestätigungsstatistiken prüfen
sudo -u postgres psql -d test_db -c "
SELECT 
    \"employmentStatus\", 
    COUNT(*) 
FROM staff_users 
GROUP BY \"employmentStatus\";
"

# Backup prüfen
ls -la /opt/vertic/backups/

# Logs rotieren
journalctl --vacuum-time=30d
```

### **CODE UPDATES (UPDATED)**
```bash
# Repository aktualisieren
cd /opt/vertic
git pull origin main

# Serverpod Code regenerieren (inkl. E-Mail-Features)
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod generate

# E-Mail-Bestätigungsendpoints prüfen
grep -r "createStaffUserWithEmail\|verifyStaffEmail\|staffSignInFlexible" lib/src/endpoints/

# Container neu bauen
docker-compose -f docker-compose.staging.yaml build --no-cache
docker-compose -f docker-compose.staging.yaml up -d
```

---

## 🎯 KRITISCHE ERKENNTNISSE - NIEMALS VERGESSEN! (UPDATED)

### ⚠️ **E-MAIL-BESTÄTIGUNGSSYSTEM**
```bash
# ❌ FALSCH (Serverpod Migration):
dart run bin/main.dart --apply-migrations
# Scheitert an "account_cleanup_logs already exists"

# ✅ RICHTIG (Manuelle SQL-Migration):
# 1. pgAdmin öffnen
# 2. ALTER TABLE staff_users ADD COLUMN "emailVerifiedAt" timestamp;
# 3. UPDATE staff_users SET "employmentStatus" = 'active' WHERE "employeeId" = 'superuser';
# 4. Migration als erfolgreich markieren
```

### ⚠️ **DOCKER BUILD CONTEXT**
```bash
# ❌ FALSCH (funktioniert nicht):
cd vertic_app/vertic/vertic_server/vertic_server_server
docker build -t vertic-server .

# ✅ RICHTIG (funktioniert):
cd /opt/vertic  # Repository-Root!
docker build -f vertic_app/vertic/vertic_server/vertic_server_server/Dockerfile -t vertic-server .
```

### ⚠️ **SERVERPOD GENERATOR**
```yaml
# config/generator.yaml - ZWINGEND ERFORDERLICH!
type: server
database: true  # OHNE DIESE ZEILE: "database feature is disabled"

# Flutter clients für E-Mail-Bestätigungsseiten
flutter_clients:
  - path: ../../vertic_project/vertic_staff_app
    name: vertic_staff_app
```

### ⚠️ **DEPLOYMENT REIHENFOLGE (UPDATED)**
```bash
# 1. Git Pull
git pull origin main

# 2. Code Generate (inkl. E-Mail-Features)
serverpod generate

# 3. E-Mail-Endpoints prüfen
grep -r "createStaffUserWithEmail" lib/src/endpoints/

# 4. Docker Build (vom Root!)
cd /opt/vertic && docker build -f vertic_app/vertic/vertic_server/vertic_server_server/Dockerfile -t vertic-server .

# 5. Container Start
cd vertic_app/vertic/vertic_server/vertic_server_server && docker-compose -f docker-compose.staging.yaml up -d
```

---

## 📞 QUICK REFERENCE (UPDATED)

### **WICHTIGE PFADE**
```
/opt/vertic/                                    # Hauptverzeichnis
/opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server/  # Server-Code
/opt/vertic/vertic_app/vertic/SQL/              # SQL-Scripts
/var/lib/postgresql/16/main/                    # PostgreSQL Daten
/var/log/pgadmin/                              # pgAdmin Logs
```

### **WICHTIGE BEFEHLE (UPDATED)**
```bash
# SSH
ssh root@159.69.144.208

# Container Status mit E-Mail-Features
docker ps && docker logs vertic-kassensystem-server --tail 10 | grep -E "(email|STAFF_)"

# Services Status
systemctl status docker postgresql ssh

# E-Mail-Bestätigungsstatus
sudo -u postgres psql -d test_db -c "SELECT \"employeeId\", \"employmentStatus\", \"emailVerifiedAt\" FROM staff_users;"

# Deployment mit E-Mail-Features
cd /opt/vertic && git pull && cd vertic_app/vertic/vertic_server/vertic_server_server && serverpod generate && docker-compose -f docker-compose.staging.yaml up -d --build
```

### **WICHTIGE URLS**
- **API:** http://159.69.144.208:8080 (inkl. E-Mail-Endpoints)
- **Insights:** http://159.69.144.208:8081
- **Web:** http://159.69.144.208:8082
- **pgAdmin:** http://159.69.144.208/pgadmin4/
- **Hetzner Console:** https://console.hetzner.cloud

### **E-MAIL-BESTÄTIGUNGSENDPOINTS**
```
POST /unifiedAuth/createStaffUserWithEmail
POST /unifiedAuth/verifyStaffEmail
POST /unifiedAuth/staffSignInFlexible
```

---

**🎯 MIT DIESER DOKUMENTATION KANNST DU:**
- ✅ **Server vollständig verwalten** ohne Rätselraten
- ✅ **E-Mail-Bestätigungssystem überwachen** und debuggen
- ✅ **Deployments sicher durchführen** mit bewährten Prozeduren
- ✅ **Probleme schnell lösen** mit konkreten Lösungsansätzen
- ✅ **System überwachen** und warten
- ✅ **Notfälle bewältigen** mit klaren Prozeduren

**🚀 ALLE 8 STUNDEN TROUBLESHOOTING-ERKENNTNISSE + E-MAIL-BESTÄTIGUNGSSYSTEM SIND JETZT DOKUMENTIERT!** 