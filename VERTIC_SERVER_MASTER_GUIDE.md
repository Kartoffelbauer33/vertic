# 🚀 VERTIC HETZNER SERVER - MASTER MANAGEMENT GUIDE

**Umfassende Dokumentation aller kritischen Erkenntnisse aus 8 Stunden Troubleshooting**  
*Alles was du über den Hetzner Server wissen musst - von Setup bis Deployment*

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
    └── 🗄️ PostgreSQL System Service (Port 5432)
```

### ⚠️ **KRITISCHE ERKENNTNISSE**
1. **PostgreSQL läuft NICHT in Docker** - System-Service auf Ubuntu
2. **Docker Container verbindet zu System-PostgreSQL** via `host.docker.internal`
3. **Docker Build MUSS vom Repository-Root** ausgeführt werden
4. **Serverpod 2.8.0 braucht generator.yaml** mit `database: true`
5. **Ubuntu 24.04 hat IPv6-Probleme** - aber läuft jetzt stabil

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

### **POSTGRESQL MANAGEMENT**
```bash
# Service-Status
systemctl status postgresql
systemctl start postgresql
systemctl restart postgresql

# Direkte Verbindung
sudo -u postgres psql -d test_db

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
      - "8080:8080"  # API Server
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

# Logs anzeigen
docker logs vertic-kassensystem-server
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

### **DOCKER TROUBLESHOOTING**
```bash
# Container-Details
docker inspect vertic-kassensystem-server

# In Container einsteigen
docker exec -it vertic-kassensystem-server sh

# Docker-Netzwerk prüfen
docker network ls
docker network inspect vertic_kassensystem_network

# Ressourcen-Verbrauch
docker stats
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
```

### **SERVERPOD CODE-GENERIERUNG**
```bash
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server

# Dependencies installieren
dart pub get

# Code generieren (NACH JEDER ÄNDERUNG!)
serverpod generate

# Prüfen ob Database-Modelle generiert wurden
ls -la lib/src/generated/ | grep -E "(app_user|staff_user|document_display_rule)"
```

---

## 🚀 DEPLOYMENT WORKFLOW

### **1. LOKALE ENTWICKLUNG → SERVER DEPLOYMENT**
```bash
# 1. Lokal entwickeln und testen
cd Leon_vertic/vertic_app/vertic/vertic_server/vertic_server_server
dart run bin/main.dart

# 2. Code committen (OHNE Passwörter!)
git add .
git commit -m "feat: neue Features"
git push origin main

# 3. Auf Server deployen
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

### **3. DEPLOYMENT VERIFIKATION**
```bash
# Health-Checks
curl http://159.69.144.208:8080/
curl http://159.69.144.208:8081/
curl http://159.69.144.208:8082/

# Container-Status
docker ps
docker logs vertic-kassensystem-server --tail 20

# Database-Verbindung
pg_isready -h localhost -p 5432 -U postgres
```

---

## 🌐 NETZWERK & FIREWALL

### **HETZNER CLOUD FIREWALL**
```
Inbound Rules:
✅ Port 22 (SSH)     - TCP - 0.0.0.0/0
✅ Port 80 (HTTP)    - TCP - 0.0.0.0/0
✅ Port 8080 (API)   - TCP - 0.0.0.0/0
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
ufw allow 8080/tcp
ufw allow 8081/tcp
ufw allow 8082/tcp

# UFW neu laden
ufw reload
```

### **PORT-TESTS**
```bash
# Intern (auf Server)
netstat -tlnp | grep -E ':(22|80|8080|8081|8082|5432)'
ss -tlnp | grep -E ':(8080|8081|8082)'

# Extern (von Windows)
Test-NetConnection -ComputerName 159.69.144.208 -Port 8080
Test-NetConnection -ComputerName 159.69.144.208 -Port 22
```

---

## 📊 MONITORING & LOGS

### **SERVICE STATUS**
```bash
# Alle wichtigen Services
systemctl status docker postgresql ssh ufw

# Docker Container
docker ps
docker stats

# Disk Space
df -h
du -sh /opt/vertic/
```

### **LOG MANAGEMENT**
```bash
# Serverpod Server Logs
docker logs vertic-kassensystem-server --tail 100 -f

# System Logs
journalctl -u docker -f
journalctl -u postgresql -f
journalctl -u ssh -f

# Log-Rotation (automatisch)
# Logs werden täglich rotiert, 7 Tage aufbewahrt
```

### **PERFORMANCE MONITORING**
```bash
# CPU & Memory
top
htop
free -h

# Docker Ressourcen
docker stats vertic-kassensystem-server

# PostgreSQL Performance
sudo -u postgres psql -d test_db -c "SELECT * FROM pg_stat_activity;"
```

---

## 🗄️ PGADMIN4 WEB-INTERFACE

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

### **PGADMIN MANAGEMENT**
```bash
# pgAdmin Status
systemctl status apache2
systemctl status pgadmin4

# pgAdmin Logs
tail -f /var/log/pgadmin/pgadmin4.log

# pgAdmin neu starten
systemctl restart apache2
```

---

## 🔄 BACKUP & RESTORE

### **AUTOMATISCHE BACKUPS**
```bash
# Backup-Script erstellen
cat > /opt/vertic/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/vertic/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Database Backup
sudo -u postgres pg_dump test_db > $BACKUP_DIR/vertic_db_$DATE.sql

# Code Backup
tar -czf $BACKUP_DIR/vertic_code_$DATE.tar.gz /opt/vertic/vertic_app/

# Alte Backups löschen (7 Tage)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "$(date): Backup completed - $DATE"
EOF

chmod +x /opt/vertic/backup.sh

# Crontab für tägliche Backups
echo "0 2 * * * /opt/vertic/backup.sh" | crontab -
```

### **MANUAL BACKUP**
```bash
# Database Backup
sudo -u postgres pg_dump test_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Komplettes System Backup
tar -czf vertic_full_backup_$(date +%Y%m%d).tar.gz /opt/vertic/
```

### **RESTORE PROZEDUR**
```bash
# Database Restore
sudo -u postgres psql -d test_db < backup_file.sql

# Code Restore
cd /opt/vertic
git reset --hard HEAD
git pull origin main
```

---

## 🚨 NOTFALL-PROCEDURES

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

# 4. Services starten
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server
docker-compose -f docker-compose.staging.yaml up -d
```

### **DOCKER PROBLEME**
```bash
# Docker komplett neu starten
systemctl restart docker

# Container-Cache leeren
docker system prune -f

# Images neu bauen
cd /opt/vertic
docker build -f vertic_app/vertic/vertic_server/vertic_server_server/Dockerfile -t vertic-server . --no-cache
```

### **POSTGRESQL PROBLEME**
```bash
# PostgreSQL neu starten
systemctl restart postgresql

# Verbindung testen
pg_isready -h localhost -p 5432 -U postgres

# Logs prüfen
journalctl -u postgresql -f
```

### **NETZWERK PROBLEME**
```bash
# Firewall neu laden
ufw reload

# Docker-Netzwerk neu erstellen
docker network rm vertic_kassensystem_network
docker-compose -f docker-compose.staging.yaml up -d
```

---

## 📱 FLUTTER APP ENTWICKLUNG GEGEN SERVER

### **ENVIRONMENT KONFIGURATION**
```dart
// vertic_staff_app/lib/config/environment.dart
static const String _stagingServer = 'http://159.69.144.208:8080/';
```

### **APP GEGEN SERVER STARTEN**
```bash
# Staff App gegen Hetzner Server
cd vertic_project/vertic_staff_app
flutter run --dart-define=USE_STAGING=true

# Client App gegen Hetzner Server
cd ../vertic_client_app
flutter run --dart-define=USE_STAGING=true

# Custom Server URL
flutter run --dart-define=SERVER_URL=http://159.69.144.208:8080/
```

### **APP DEBUGGING**
```bash
# Flutter Logs
flutter logs

# Network Debugging
flutter run --dart-define=USE_STAGING=true --verbose

# App mit DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 🔧 WARTUNG & UPDATES

### **REGELMÄSSIGE WARTUNG (MONATLICH)**
```bash
# System Updates
apt update && apt upgrade -y

# Docker Updates
docker-compose -f docker-compose.staging.yaml pull
docker system prune -f

# Backup prüfen
ls -la /opt/vertic/backups/

# Logs rotieren
journalctl --vacuum-time=30d
```

### **CODE UPDATES**
```bash
# Repository aktualisieren
cd /opt/vertic
git pull origin main

# Serverpod Code regenerieren
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod generate

# Container neu bauen
docker-compose -f docker-compose.staging.yaml build --no-cache
docker-compose -f docker-compose.staging.yaml up -d
```

### **SICHERHEITS-UPDATES**
```bash
# Fail2ban Status
systemctl status fail2ban

# SSH-Logs prüfen
journalctl -u sshd | grep "Failed password"

# Firewall-Logs
ufw status verbose
```

---

## 🎯 KRITISCHE ERKENNTNISSE - NIEMALS VERGESSEN!

### ⚠️ **DOCKER BUILD CONTEXT**
```bash
# ❌ FALSCH (funktioniert nicht):
cd vertic_app/vertic/vertic_server/vertic_server_server
docker build -t vertic-server .

# ✅ RICHTIG (funktioniert):
cd /opt/vertic  # Repository-Root!
docker build -f vertic_app/vertic/vertic_server/vertic_server_server/Dockerfile -t vertic-server .
```

### ⚠️ **POSTGRESQL VERBINDUNG**
```yaml
# ❌ FALSCH (Container-zu-Container):
database:
  host: postgres

# ✅ RICHTIG (Container-zu-System):
database:
  host: host.docker.internal
```

### ⚠️ **SERVERPOD GENERATOR**
```yaml
# config/generator.yaml - ZWINGEND ERFORDERLICH!
type: server
database: true  # OHNE DIESE ZEILE: "database feature is disabled"
```

### ⚠️ **FIREWALL REIHENFOLGE**
```bash
# 1. ERST UFW konfigurieren
ufw allow 22/tcp

# 2. DANN UFW aktivieren
ufw --force enable

# 3. NIEMALS SSH-Port blockieren!
```

### ⚠️ **DEPLOYMENT REIHENFOLGE**
```bash
# 1. Git Pull
git pull origin main

# 2. Code Generate
serverpod generate

# 3. Docker Build (vom Root!)
cd /opt/vertic && docker build -f vertic_app/vertic/vertic_server/vertic_server_server/Dockerfile -t vertic-server .

# 4. Container Start
cd vertic_app/vertic/vertic_server/vertic_server_server && docker-compose -f docker-compose.staging.yaml up -d
```

---

## 📞 QUICK REFERENCE

### **WICHTIGE PFADE**
```
/opt/vertic/                                    # Hauptverzeichnis
/opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server/  # Server-Code
/opt/vertic/vertic_app/vertic/SQL/              # SQL-Scripts
/var/lib/postgresql/16/main/                    # PostgreSQL Daten
/var/log/pgadmin/                              # pgAdmin Logs
```

### **WICHTIGE BEFEHLE**
```bash
# SSH
ssh root@159.69.144.208

# Container Status
docker ps && docker logs vertic-kassensystem-server --tail 10

# Services Status
systemctl status docker postgresql ssh

# Deployment
cd /opt/vertic && git pull && cd vertic_app/vertic/vertic_server/vertic_server_server && serverpod generate && docker-compose -f docker-compose.staging.yaml up -d --build
```

### **WICHTIGE URLS**
- **API:** http://159.69.144.208:8080
- **Insights:** http://159.69.144.208:8081
- **Web:** http://159.69.144.208:8082
- **pgAdmin:** http://159.69.144.208/pgadmin4/
- **Hetzner Console:** https://console.hetzner.cloud

---

**🎯 MIT DIESER DOKUMENTATION KANNST DU:**
- ✅ **Server vollständig verwalten** ohne Rätselraten
- ✅ **Deployments sicher durchführen** mit bewährten Prozeduren
- ✅ **Probleme schnell lösen** mit konkreten Lösungsansätzen
- ✅ **System überwachen** und warten
- ✅ **Notfälle bewältigen** mit klaren Prozeduren

**🚀 ALLE 8 STUNDEN TROUBLESHOOTING-ERKENNTNISSE SIND JETZT DOKUMENTIERT!** 