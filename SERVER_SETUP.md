# Kassensystem Server Dokumentation

## 🖥️ Server-Details

**Provider:** Hetzner Cloud  
**Standort:** Nürnberg (eu-central)  
**Server-Typ:** CX21 (2 vCPU, 4 GB RAM, 40 GB SSD)  
**Betriebssystem:** Ubuntu 24.04.2 LTS  
**IP-Adresse:** 159.69.144.208  
**Hostname:** vertiv  

## 🔐 Zugang & Authentifizierung

### SSH-Zugang
```bash
ssh root@159.69.144.208
```
- **Benutzer:** root
- **Authentifizierung:** SSH-Key (kein Passwort)
- **SSH-Key Name:** "Kassensystem Team Key"

### Desktop-Zugang (Remote Desktop)
```
Server: 159.69.144.208:3389
Benutzer: kassensystem
Passwort: [bei Einrichtung gesetzt]
```

## 🛡️ Firewall-Konfiguration

**Aktive Regeln (eingehend):**
- **Port 22 (SSH):** Vollzugriff - Server-Verwaltung
- **Port 80 (HTTP):** Vollzugriff - Webserver
- **Port 443 (HTTPS):** Vollzugriff - Sicherer Webserver  
- **Port 3389 (RDP):** Vollzugriff - Remote Desktop
- **Port 8080:** [Für Serverpod vorbereitet]

**Gesperrte Ports:**
- **Port 5432 (PostgreSQL):** Nur localhost - Datenbank-Sicherheit

## 🗄️ Installierte Software

### Datenbank
- **PostgreSQL 16.9** 
  - Service: `postgresql.service`
  - Status: Aktiv
  - Benutzer: `postgres`
  - Passwort: `kassensystem123`
  - Datenbanken: `postgres` (Standard), `vertic` (Kassensystem)

### Web-Management
- **pgAdmin4** (Web-Interface)
  - URL: http://159.69.144.208/pgadmin4
  - E-Mail: `guntramschedler@gmail.com`
  - Passwort: [bei Setup gesetzt]
  - Server-Verbindung: `Kassensystem Local` → Database `vertic`

### Container-Platform
- **Docker** (neueste Version)
  - Service: `docker.service`
  - Status: Aktiv
- **Docker Compose** 
  - Für Multi-Container-Deployments

### Desktop-Umgebung
- **Ubuntu Desktop Minimal**
- **XRDP** (Remote Desktop Server)
  - Service: `xrdp.service`
  - Status: Aktiv

### Webserver
- **Apache2**
  - Service: `apache2.service` 
  - Status: Aktiv
  - pgAdmin4 läuft auf `/pgadmin4`

## 📊 System-Status

### Speicher & Performance
- **Festplatte:** 7.9% belegt (von 74.79GB)
- **RAM:** ~31% verwendet
- **Swap:** 0% verwendet
- **System Load:** Niedrig (0.0)

### Services
```bash
# Status prüfen:
systemctl status postgresql
systemctl status docker  
systemctl status xrdp
systemctl status apache2
```

## 🌐 Web-Interfaces

### pgAdmin4 (Datenbank-Management)
- **URL:** http://159.69.144.208/pgadmin4
- **Funktionen:** 
  - PostgreSQL-Verwaltung
  - Query-Editor
  - Datenbank-Erstellung
  - Backup/Restore

### Künftig: Serverpod API
- **URL:** http://159.69.144.208:8080 (geplant)
- **Status:** Noch nicht deployed

## 📁 Wichtige Verzeichnisse

```
/var/lib/postgresql/    # PostgreSQL-Daten
/var/log/postgresql/    # PostgreSQL-Logs
/var/lib/pgadmin/       # pgAdmin4-Konfiguration
/opt/                   # Für Anwendungen (z.B. Serverpod-Code)
/home/kassensystem/     # Desktop-Benutzer Home
```

## 🚀 Nächste Schritte für Serverpod

### 1. Code-Repository vorbereiten
- `.gitignore` erstellen (Passwörter ausschließen)
- GitHub Repository erstellen (privat)
- Code nach GitHub pushen

### 2. Serverpod-Konfiguration
```yaml
# config/production.yaml
apiServer:
  port: 8080
  publicHost: 159.69.144.208
  publicScheme: http

database:
  host: localhost
  port: 5432
  name: vertic
  user: postgres
  password: kassensystem123
```

### 3. Docker-Deployment
```bash
# Auf Server:
cd /opt
git clone [dein-repo]
docker-compose up -d
```

## 🛠️ Wartung & Troubleshooting

### Häufige Befehle
```bash
# System-Updates
apt update && apt upgrade -y

# Service-Status prüfen
systemctl status [service-name]

# Logs anzeigen
journalctl -u [service-name] -f

# Docker-Container verwalten
docker ps
docker-compose logs -f

# Festplattenspeicher prüfen
df -h

# RAM-Verwendung prüfen  
free -h
```

### Bei Problemen

**SSH-Verbindung verloren:**
```bash
# Hetzner Console im Browser verwenden
# Oder Server über Hetzner Cloud-Panel neustarten
```

**pgAdmin4 nicht erreichbar:**
```bash
systemctl restart apache2
systemctl status apache2
```

**PostgreSQL-Probleme:**
```bash
systemctl restart postgresql
sudo -u postgres psql -c "SELECT version();"
```

**Docker-Issues:**
```bash
systemctl restart docker
docker system prune  # Aufräumen
```

## 📋 Checkliste: System-Bereitschaft

- ✅ Server läuft und ist erreichbar
- ✅ SSH-Zugang funktioniert
- ✅ PostgreSQL installiert und läuft
- ✅ Datenbank "vertic" erstellt
- ✅ pgAdmin4 Web-Interface verfügbar
- ✅ Docker installiert und betriebsbereit
- ✅ Firewall konfiguriert
- ✅ Remote Desktop verfügbar
- ⏳ Serverpod-Code deployment (nächster Schritt)
- ⏳ Flutter-App Verbindung testen

## 💰 Kosten-Tracking

**Monatliche Kosten:**
- **Hetzner CX21:** €5,83/Monat
- **Backups (optional):** €1,17/Monat
- **Traffic:** Kostenlos (20TB inklusive)

**Gesamtkosten:** ~€7/Monat

## 📞 Support-Kontakte

**Hetzner Cloud:**
- Panel: https://console.hetzner.cloud
- Support: support@hetzner.com

**Emergency Access:**
- Hetzner Cloud Console (Browser)
- VNC-Zugang über Cloud-Panel

---

**Letzte Aktualisierung:** Juni 2025  
**Server-Name:** vertiv  
**Projekt:** Kassensystem mit Flutter + Serverpod