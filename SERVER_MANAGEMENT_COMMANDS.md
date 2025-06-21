# 🚀 VERTIC SERVER MANAGEMENT - KOMPLETTE ANLEITUNG

## 🔐 SSH-VERBINDUNG EINRICHTEN UND REPARIEREN

### **WARUM SSH NICHT FUNKTIONIERT:**
1. **Hetzner Cloud blockiert SSH standardmäßig von extern**
2. **SSH-Service ist nicht richtig konfiguriert**
3. **Firewall blockiert Port 22 intern**

### **SSH DAUERHAFT REPARIEREN:**

#### **1. ÜBER HETZNER CONSOLE EINLOGGEN:**
```
1. Gehe zu: console.hetzner.cloud
2. Server "vertic" → "Console" Tab
3. Login: root
4. Passwort eingeben
```

#### **2. SSH-SERVICE KONFIGURIEREN:**
```bash
# SSH-Konfiguration bearbeiten
nano /etc/ssh/sshd_config

# Diese Zeilen ändern/hinzufügen:
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes

# SSH-Service neustarten
systemctl restart sshd
systemctl enable sshd

# SSH-Status prüfen
systemctl status sshd
```

#### **3. FIREWALL KONFIGURIEREN:**
```bash
# UFW-Firewall prüfen
ufw status

# SSH-Port freigeben
ufw allow 22/tcp
ufw allow ssh

# Firewall neu laden
ufw reload
```

#### **4. HETZNER CLOUD FIREWALL PRÜFEN:**
```
In Hetzner Console → Firewalls → firewall-1:
✅ Port 22 - TCP - Any IPv4, Any IPv6 - SSH
```

---

## 🚀 POWERSHELL SSH-BEFEHLE

### **SSH-VERBINDUNG:**
```powershell
# Standard SSH-Verbindung
ssh root@159.69.144.208

# SSH mit Verbose-Output (für Debugging)
ssh -v root@159.69.144.208

# SSH mit spezifischem Port
ssh -p 22 root@159.69.144.208
```

### **WINDOWS SSH-CLIENT INSTALLIEREN:**
```powershell
# SSH-Client installieren (falls nicht vorhanden)
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# SSH-Service starten
Start-Service ssh-agent
Set-Service -Name ssh-agent -StartupType Automatic
```

---

## 🐳 DOCKER MANAGEMENT BEFEHLE

### **STANDARD STARTUP-PROZEDUR:**
```bash
# 1. Ins Vertic-Verzeichnis wechseln
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server

# 2. Container-Status prüfen
docker ps -a

# 3. Alle Container starten
docker-compose up -d

# 4. Status prüfen
docker-compose ps

# 5. Logs anzeigen
docker-compose logs vertic-server
```

### **NOTFALL-NEUSTART:**
```bash
# Alles stoppen
docker-compose down

# Container entfernen
docker-compose rm -f

# Neu starten
docker-compose up -d

# Status prüfen
docker-compose ps
```

### **LOGS UND DEBUGGING:**
```bash
# Server-Logs anzeigen
docker-compose logs vertic-server | tail -50

# Live-Logs verfolgen
docker-compose logs -f vertic-server

# PostgreSQL-Logs
docker-compose logs vertic-postgres

# Alle Container-Logs
docker-compose logs
```

---

## 🔍 SYSTEM-DIAGNOSE BEFEHLE

### **GRUNDLEGENDE CHECKS:**
```bash
# Festplattenspeicher prüfen
df -h

# RAM-Verbrauch prüfen
free -h

# Laufende Prozesse
top

# Docker-Status
systemctl status docker

# Docker starten (falls gestoppt)
systemctl start docker
```

### **NETZWERK-TESTS:**
```bash
# API-Test intern
curl http://localhost:8080/

# Port-Status prüfen
netstat -tulpn | grep :8080
netstat -tulpn | grep :5432

# PostgreSQL-Verbindung testen
pg_isready -h localhost -p 5432
```

---

## 🚨 NOTFALL-CHECKLISTE

### **WENN SERVER NICHT ERREICHBAR:**
```bash
1. systemctl status docker
2. systemctl start docker
3. cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server
4. docker-compose down
5. docker-compose up -d
6. docker-compose ps
7. curl http://localhost:8080/
```

### **WENN DOCKER PROBLEME HAT:**
```bash
1. systemctl restart docker
2. docker system prune -f
3. docker-compose up -d --build
4. docker-compose logs vertic-server
```

---

## 📱 POWERSHELL-TESTS VON WINDOWS

### **API-VERBINDUNG TESTEN:**
```powershell
# HTTP-Test
Invoke-WebRequest -Uri "http://159.69.144.208:8080/" -Method GET

# Port-Test
Test-NetConnection -ComputerName 159.69.144.208 -Port 8080
Test-NetConnection -ComputerName 159.69.144.208 -Port 22
```

---

## 📂 WICHTIGE PFADE

```bash
# Hauptverzeichnis
/opt/vertic/

# Docker-Compose
/opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server/docker-compose.yaml

# Environment-Datei
/opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server/.env

# SSH-Konfiguration
/etc/ssh/sshd_config
```

---

## 🔧 SSH-TROUBLESHOOTING

### **WENN SSH IMMER NOCH NICHT GEHT:**
```bash
# 1. SSH-Service Status
systemctl status sshd

# 2. SSH-Konfiguration prüfen
cat /etc/ssh/sshd_config | grep -E "Port|PermitRoot|Password"

# 3. SSH-Logs anzeigen
journalctl -u sshd -f

# 4. Firewall-Status
ufw status verbose

# 5. SSH-Service komplett neu installieren
apt update
apt install --reinstall openssh-server
systemctl enable sshd
systemctl start sshd
```

### **ALTERNATIVE: SSH-KEY ERSTELLEN:**
```powershell
# Auf Windows SSH-Key erstellen
ssh-keygen -t rsa -b 4096 -C "deine@email.com"

# Public Key auf Server kopieren (über Hetzner Console)
# Dann mit Key verbinden:
ssh -i ~/.ssh/id_rsa root@159.69.144.208
```

---

## ⚡ SCHNELL-BEFEHLE

```bash
# Server komplett neustarten
reboot

# Docker schnell neustarten
systemctl restart docker && cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server && docker-compose up -d

# Alle Services prüfen
systemctl status docker sshd ufw
```

# SERVER MANAGEMENT COMMANDS - Vertic Production

## KRITISCHE DOCKER-NETZWERK-KONFIGURATION

### Problem: Container können nicht miteinander kommunizieren
**Lösung**: Alle Container müssen im selben Docker-Netzwerk laufen

```bash
# 1. Alle Container stoppen und entfernen
docker stop vertic-server postgres
docker rm vertic-server postgres

# 2. Docker-Netzwerk erstellen (falls nicht vorhanden)
docker network create vertic-network

# 3. PostgreSQL Container starten (ZUERST!)
docker run -d \
  --name postgres \
  --network vertic-network \
  -e POSTGRES_DB=test_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=GreifbarB2019 \
  -p 5432:5432 \
  postgres:15

# 4. Warten bis PostgreSQL bereit ist
docker exec postgres pg_isready -U postgres -d test_db

# 5. Docker Image neu bauen (mit aktualisierter config/production.yaml)
cd /opt/vertic/vertic/vertic_app/vertic/vertic_server/vertic_server_server
docker build -t vertic-server .

# 6. Serverpod Container starten (NACH PostgreSQL!)
docker run -d \
  --name vertic-server \
  --network vertic-network \
  -p 8080:8080 -p 8081:8081 -p 8082:8082 \
  vertic-server

# 7. Status überprüfen
docker ps
docker logs vertic-server
```

## FIREWALL-KONFIGURATION

```bash
# UFW Regeln für alle benötigten Ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8080/tcp  # Serverpod API
sudo ufw allow 8081/tcp  # Serverpod Insights
sudo ufw allow 8082/tcp  # Serverpod Web
sudo ufw allow 5432/tcp  # PostgreSQL (für pgAdmin)
sudo ufw reload
sudo ufw status
```

## SERVERPOD-ENDPUNKTE TESTEN

```bash
# API Server
curl http://159.69.144.208:8080/

# Insights Dashboard
curl http://159.69.144.208:8081/

# Web Interface
curl http://159.69.144.208:8082/
```

## DATENBANK-ZUGRIFF

```bash
# Direkt in PostgreSQL Container
docker exec -it postgres psql -U postgres -d test_db

# Datenbank-Liste anzeigen
docker exec -it postgres psql -U postgres -d test_db -c "\l"

# Tabellen anzeigen
docker exec -it postgres psql -U postgres -d test_db -c "\dt"
```

## TROUBLESHOOTING

### Container-Logs anzeigen
```bash
docker logs vertic-server
docker logs postgres
```

### Container-Netzwerk prüfen
```bash
docker network ls
docker network inspect vertic-network
```

### Container-Status prüfen
```bash
docker ps -a
docker exec vertic-server ps aux
```

### Migrations anwenden
```bash
docker exec -it vertic-server /usr/local/bin/vertic_server --apply-migrations
```

## WICHTIGE KONFIGURATIONSDATEIEN

- `config/production.yaml` - Hauptkonfiguration (Database Host: `postgres`)
- `config/passwords.yaml` - Datenbankpasswörter
- `config/generator.yaml` - Code-Generierung (database: true)

## PGADMIN ZUGRIFF

pgAdmin läuft separat und kann über den Browser erreicht werden:
- URL: http://159.69.144.208/pgadmin4
- Database Host: 159.69.144.208 (nicht localhost!)
- Port: 5432
- Database: test_db
- Username: postgres
- Password: GreifbarB2019 