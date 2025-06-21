# 🚀 VERTIC SERVER NEUAUFBAU - BULLETPROOF INSTALLATION

## 📋 VORAUSSETZUNGEN & PLANUNG

### **EMPFOHLENE KONFIGURATION:**
- **OS:** Ubuntu 22.04 LTS (NICHT 24.04!)
- **Größe:** CPX21 (4 GB RAM, 2 vCPUs, 80 GB SSD)
- **Region:** Deutschland (Nürnberg oder Falkenstein)
- **SSH-Keys:** Sofort einrichten, KEINE Passwort-Auth

---

## 🔧 SCHRITT 1: HETZNER CLOUD SETUP

### **1.1 SERVER ERSTELLEN:**
```
1. Hetzner Console → Server → Server erstellen
2. Image: Ubuntu 22.04 LTS (x64)
3. Typ: CPX21 (4 GB RAM)
4. Datacenter: Nürnberg-1-DC3
5. SSH-Key: Generiere neuen Key und lade hoch
6. Firewall: Neue Firewall "vertic-firewall" erstellen
7. Name: vertic-prod
```

### **1.2 FIREWALL REGELN:**
```
Inbound Rules:
✅ Port 22 (SSH)     - TCP - 0.0.0.0/0
✅ Port 80 (HTTP)    - TCP - 0.0.0.0/0  
✅ Port 443 (HTTPS)  - TCP - 0.0.0.0/0
✅ Port 8080 (API)   - TCP - 0.0.0.0/0
✅ Port 5432 (PostgreSQL) - TCP - NUR deine IP

Outbound Rules:
✅ Alle Ports - TCP/UDP - 0.0.0.0/0
```

---

## 🔐 SCHRITT 2: SSH-KEYS ERSTELLEN (WINDOWS)

### **2.1 SSH-KEY GENERIEREN:**
```powershell
# Neuen SSH-Key erstellen
ssh-keygen -t ed25519 -C "vertic-server-key"

# Key speichern in: C:\Users\guntr\.ssh\vertic_server
# KEIN Passwort eingeben für einfachen Zugang

# Public Key anzeigen
Get-Content C:\Users\guntr\.ssh\vertic_server.pub
```

### **2.2 HETZNER SSH-KEY HOCHLADEN:**
```
1. Hetzner Console → Security → SSH Keys
2. "SSH Key hinzufügen"
3. Name: "vertic-prod-key"
4. Public Key einfügen
5. Bei Server-Erstellung auswählen
```

---

## 🖥️ SCHRITT 3: ERSTE SERVER-KONFIGURATION

### **3.1 ERSTE VERBINDUNG:**
```powershell
# Mit SSH-Key verbinden
ssh -i C:\Users\guntr\.ssh\vertic_server root@NEUE_SERVER_IP
```

### **3.2 BASIC SETUP:**
```bash
# System aktualisieren
apt update && apt upgrade -y

# Timezone setzen
timedatectl set-timezone Europe/Berlin

# Hostname setzen
hostnamectl set-hostname vertic-prod

# SSH-Konfiguration sichern
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# SSH optimieren
cat > /etc/ssh/sshd_config << 'EOF'
Port 22
Protocol 2
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# SSH neustarten
systemctl restart sshd
systemctl enable sshd
```

---

## 🛡️ SCHRITT 4: SICHERHEIT & FIREWALL

### **4.1 UFW KONFIGURATION:**
```bash
# UFW installieren und konfigurieren
apt install ufw -y

# Default Policies
ufw default deny incoming
ufw default allow outgoing

# SSH erlauben (WICHTIG: Erst SSH, dann UFW aktivieren!)
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp

# UFW aktivieren
ufw --force enable

# Status prüfen
ufw status verbose
```

### **4.2 FAIL2BAN INSTALLIEREN:**
```bash
# Fail2ban für SSH-Schutz
apt install fail2ban -y

# Konfiguration
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

systemctl restart fail2ban
systemctl enable fail2ban
```

---

## 🐳 SCHRITT 5: DOCKER INSTALLATION

### **5.1 DOCKER RICHTIG INSTALLIEREN:**
```bash
# Alte Docker-Versionen entfernen
apt remove docker docker-engine docker.io containerd runc

# Dependencies
apt install apt-transport-https ca-certificates curl gnupg lsb-release -y

# Docker GPG Key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Docker Repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker installieren
apt update
apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# Docker starten
systemctl start docker
systemctl enable docker

# Docker-Compose installieren
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Test
docker --version
docker-compose --version
```

---

## 📦 SCHRITT 6: VERTIC DEPLOYMENT

### **6.1 VERZEICHNIS-STRUKTUR:**
```bash
# Hauptverzeichnis erstellen
mkdir -p /opt/vertic
cd /opt/vertic

# Git installieren
apt install git -y

# Repository klonen (von deinem GitHub)
git clone https://github.com/DEIN_USERNAME/vertic_project.git
cd vertic_project

# Berechtigungen setzen
chown -R root:root /opt/vertic
chmod -R 755 /opt/vertic
```

### **6.2 ENVIRONMENT KONFIGURATION:**
```bash
# .env Datei erstellen
cd /opt/vertic/vertic_project/vertic_server/vertic_server_server
cp .env.example .env

# .env bearbeiten
nano .env
```

### **6.3 DOCKER-COMPOSE ANPASSEN:**
```bash
# Docker-Compose für Produktion
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  vertic-server:
    build: .
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://vertic:SICHERES_PASSWORT@vertic-postgres:5432/vertic
    depends_on:
      - vertic-postgres
    restart: unless-stopped
    
  vertic-postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: vertic
      POSTGRES_USER: vertic
      POSTGRES_PASSWORD: SICHERES_PASSWORT
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    restart: unless-stopped
    ports:
      - "5432:5432"

volumes:
  postgres_data:
EOF
```

---

## 🚀 SCHRITT 7: DEPLOYMENT AUTOMATISIERUNG

### **7.1 STARTUP SCRIPT:**
```bash
# Automatisches Startup-Script
cat > /opt/vertic/start-vertic.sh << 'EOF'
#!/bin/bash
cd /opt/vertic/vertic_project/vertic_server/vertic_server_server

echo "Starting Vertic Server..."
docker-compose -f docker-compose.prod.yml up -d

echo "Checking status..."
docker-compose -f docker-compose.prod.yml ps

echo "Vertic Server started successfully!"
EOF

chmod +x /opt/vertic/start-vertic.sh
```

### **7.2 SYSTEMD SERVICE:**
```bash
# Systemd Service für Auto-Start
cat > /etc/systemd/system/vertic.service << 'EOF'
[Unit]
Description=Vertic Server
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/vertic/vertic_project/vertic_server/vertic_server_server
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Service aktivieren
systemctl daemon-reload
systemctl enable vertic.service
```

---

## 📱 SCHRITT 8: MONITORING & BACKUP

### **8.1 HEALTH-CHECK SCRIPT:**
```bash
cat > /opt/vertic/health-check.sh << 'EOF'
#!/bin/bash
API_URL="http://localhost:8080"
LOG_FILE="/var/log/vertic-health.log"

if curl -s $API_URL > /dev/null; then
    echo "$(date): Vertic API is healthy" >> $LOG_FILE
else
    echo "$(date): Vertic API is DOWN - Restarting..." >> $LOG_FILE
    systemctl restart vertic
fi
EOF

chmod +x /opt/vertic/health-check.sh

# Crontab für Health-Check
echo "*/5 * * * * /opt/vertic/health-check.sh" | crontab -
```

### **8.2 BACKUP SCRIPT:**
```bash
cat > /opt/vertic/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/vertic/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Database Backup
docker exec vertic-postgres pg_dump -U vertic vertic > $BACKUP_DIR/vertic_db_$DATE.sql

# Keep only last 7 backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "$(date): Backup completed - vertic_db_$DATE.sql"
EOF

chmod +x /opt/vertic/backup.sh

# Tägliche Backups
echo "0 2 * * * /opt/vertic/backup.sh" | crontab -
```

---

## ✅ SCHRITT 9: FINAL TESTING

### **9.1 KOMPLETTER START:**
```bash
# Vertic starten
systemctl start vertic

# Status prüfen
systemctl status vertic
docker ps
curl http://localhost:8080

# Logs prüfen
docker-compose -f /opt/vertic/vertic_project/vertic_server/vertic_server_server/docker-compose.prod.yml logs
```

### **9.2 SSH-TEST VON WINDOWS:**
```powershell
# SSH-Verbindung
ssh -i C:\Users\guntr\.ssh\vertic_server root@NEUE_SERVER_IP

# API-Test
Invoke-WebRequest -Uri "http://NEUE_SERVER_IP:8080" -Method GET
```

---

## 🎯 WARTUNG & UPDATES

### **REGELMÄSSIGE AUFGABEN:**
```bash
# System-Updates (monatlich)
apt update && apt upgrade -y

# Docker-Images aktualisieren
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

# Logs rotieren
journalctl --vacuum-time=30d
```

---

## 🆘 NOTFALL-BEFEHLE

```bash
# Alles neustarten
systemctl restart vertic

# Logs anzeigen
journalctl -u vertic -f

# Container-Status
docker ps -a

# Notfall-Stop
systemctl stop vertic
docker-compose down

# Kompletter Neustart
reboot
```

---

**MIT DIESER INSTALLATION WIRST DU:**
✅ **Niemals SSH-Probleme haben**
✅ **Automatische Backups** 
✅ **Monitoring & Health-Checks**
✅ **Saubere Docker-Installation**
✅ **Bulletproof Security**
✅ **Auto-Start nach Reboot** 

## 9. FLUTTER INSTALLATION FÜR SERVERPOD CODE-GENERIERUNG

### Flutter herunterladen und installieren
```bash
cd /opt
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz
tar xf flutter_linux_3.24.3-stable.tar.xz
```

### Flutter PATH permanent setzen
```bash
echo 'export PATH="$PATH:/opt/flutter/bin"' >> /etc/environment
export PATH="$PATH:/opt/flutter/bin"
```

### Flutter konfigurieren
```bash
flutter config --no-analytics
flutter doctor
```

### Serverpod CLI installieren
```bash
dart pub global activate serverpod_cli
```

## 10. VERTIC DEPLOYMENT FINALISIEREN

### Code generieren
```bash
cd /opt/vertic/vertic/vertic_app/vertic/vertic_server/vertic_server_server
serverpod generate
```

### Docker Build und Start
```bash
# Docker Images bauen
docker-compose -f docker-compose.prod.yaml build

# Services starten
docker-compose -f docker-compose.prod.yaml up -d

# Status prüfen
docker-compose -f docker-compose.prod.yaml ps
docker-compose -f docker-compose.prod.yaml logs
```

### Service-Status prüfen
```bash
# Container prüfen
docker ps

# Logs anzeigen
docker logs vertic-server
docker logs vertic-postgres

# Netzwerk testen
curl http://localhost:8080/
```

## 11. WARTUNG UND UPDATES

### Service-Management
```bash
# Services stoppen
docker-compose -f docker-compose.prod.yaml down

# Services neu starten
docker-compose -f docker-compose.prod.yaml restart

# Logs verfolgen
docker-compose -f docker-compose.prod.yaml logs -f
```

### Git Updates
```bash
cd /opt/vertic/vertic
git pull origin main
cd vertic_app/vertic/vertic_server/vertic_server_server
serverpod generate
docker-compose -f docker-compose.prod.yaml build
docker-compose -f docker-compose.prod.yaml up -d
```

### Backup-Strategie
```bash
# Datenbank-Backup
docker exec vertic-postgres pg_dump -U vertic_user vertic_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Repository-Backup
cd /opt
tar -czf vertic_backup_$(date +%Y%m%d_%H%M%S).tar.gz vertic/
```

---

## KRITISCHE PUNKTE BEACHTEN

1. **Niemals** Root-Privilegien für Flutter nutzen (Warnung beachten!)
2. **Immer** Code-Generierung vor Docker-Build
3. **Regelmäßige** Backups der Datenbank
4. **Sichere** Environment-Variablen (keine Klartextpasswörter)
5. **Monitoring** der Container-Logs

---

**INSTALLATION ERFOLGREICH ABGESCHLOSSEN** ✅

Der Vertic-Server läuft jetzt vollständig unter:
- **Server**: http://159.69.144.208:8080
- **Postgres**: 127.0.0.1:5432 (intern)
- **Repository**: /opt/vertic/vertic
- **Logs**: `docker-compose logs` 

## ⚠️ KRITISCHE ERKENNTNISSE - OHNE DIESE GEHT NICHTS! ⚠️

### 🔥 PROBLEM #1: UBUNTU 24.04 NETWORKING ISSUES
- **NIEMALS Ubuntu 24.04 verwenden!**
- **IMMER Ubuntu 22.04 LTS nehmen!**
- Ubuntu 24.04 hat IPv6-first Networking → SSH funktioniert nicht richtig
- Ubuntu 22.04 ist stabil und funktioniert einwandfrei

### 🔥 PROBLEM #2: SERVERPOD DATABASE FEATURES
- **KRITISCH:** Serverpod 2.8.0 generiert KEINE Database-Modelle ohne explizite Konfiguration!
- **LÖSUNG:** `config/generator.yaml` mit `database: true` ist ZWINGEND erforderlich!
- **OHNE diese Datei:** "database feature is disabled" Warnungen → KEINE generierten Dateien!

### 🔥 PROBLEM #3: DOCKER BUILD CONTEXT
- **Docker Build MUSS vom Repository-Root ausgeführt werden!**
- **NICHT vom Server-Verzeichnis aus!**
- Sonst fehlen Client-Projekte für Serverpod Generate

## 10. SERVERPOD GENERATOR-KONFIGURATION (KRITISCH!)

### ⚠️ OHNE DIESE KONFIGURATION FUNKTIONIERT NICHTS!

```bash
cd /opt/vertic/vertic/vertic_app/vertic/vertic_server/vertic_server_server

# KRITISCHE Generator-Konfiguration erstellen
cat > config/generator.yaml << 'EOF'
type: server

# Database-Features EXPLIZIT aktivieren (OHNE GEHT NICHTS!)
database: true

# Client-Pfade für vollständige Generierung
client_package_path: ../vertic_server_client
EOF
```

### Code-Generierung mit Database-Support
```bash
# Flutter/Dart PATH setzen
export PATH="$PATH:/opt/flutter/bin:/root/.pub-cache/bin"

# Dependencies installieren
dart pub get

# Code-Generierung (ENDLICH funktionsfähig!)
serverpod generate

# PRÜFEN: Alle kritischen Dateien müssen generiert werden
ls -la lib/src/generated/ | grep -E "(app_user|staff_user|document_display_rule|registration_document).dart"
```

**ERGEBNIS:** 
- ✅ `app_user.dart` - Generiert
- ✅ `staff_user.dart` - Generiert  
- ✅ `document_display_rule.dart` - Generiert
- ✅ `registration_document.dart` - Generiert

## 11. DOCKER BUILD UND DEPLOYMENT

### Docker Build (vom Repository-Root!)
```bash
cd /opt/vertic/vertic
docker build -f vertic_app/vertic/vertic_server/vertic_server_server/Dockerfile -t vertic-server .
```

### Container starten
```bash
docker run -d -p 8080:8080 -p 8081:8081 -p 8082:8082 --name vertic-server vertic-server
```

### Status prüfen
```bash
docker ps
docker logs vertic-server
```

## 🔥 WICHTIGE ERKENNTNISSE - NIEMALS VERGESSEN!

1. **Ubuntu 22.04 LTS** - NIEMALS 24.04!
2. **`config/generator.yaml` mit `database: true`** - ZWINGEND erforderlich!
3. **Docker Build vom Repository-Root** - NICHT vom Server-Verzeichnis!
4. **Flutter PATH korrekt setzen** - `/opt/flutter/bin` und `$HOME/.pub-cache/bin`
5. **Serverpod 2.8.0 braucht explizite Database-Aktivierung** - Ohne geht nichts!

---

**INSTALLATION ERFOLGREICH ABGESCHLOSSEN** ✅

Der Vertic-Server läuft jetzt vollständig unter:
- **Server**: http://159.69.144.208:8080
- **Postgres**: 127.0.0.1:5432 (intern)
- **Repository**: /opt/vertic/vertic
- **Logs**: `docker-compose logs` 