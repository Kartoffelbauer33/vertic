# 🚀 VERTIC KASSENSYSTEM - PROFESSIONAL DEPLOYMENT GUIDE

## 📋 Übersicht
Professioneller Serverpod-Deployment-Guide für das Vertic Kassensystem auf Hetzner VPS.
System optimiert für Zuverlässigkeit, Skalierbarkeit und einfache Wartung.

## 🏗️ Architektur

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Flutter Client    │    │   Flutter Staff     │    │   Web Interface     │
│   (Kunden-App)      │    │   (Personal-App)    │    │   (Admin-Panel)     │
└─────────┬───────────┘    └─────────┬───────────┘    └─────────┬───────────┘
          │                          │                          │
          └─────────────┬────────────┼──────────────────────────┘
                        │            │
                 ┌──────▼────────────▼──────┐
                 │   Serverpod API Server   │ :8080
                 │   + Insights Server      │ :8081
                 │   + Web Server           │ :8082
                 └──────────┬───────────────┘
                            │
                    ┌───────▼───────┐
                    │  PostgreSQL   │ :5432
                    │   Database    │
                    └───────────────┘
```

## 🛠️ Systemvoraussetzungen

### Server-Spezifikationen (Aktuell: Hetzner CX21)
- **CPU:** 2 vCPU Cores
- **RAM:** 4 GB
- **Storage:** 40 GB SSD
- **Netzwerk:** 20 TB Traffic
- **OS:** Ubuntu 24.04.2 LTS

### Installierte Software
- PostgreSQL 16.9
- Docker & Docker Compose
- SSH Server
- pgAdmin4 Web Interface

## 🚀 Deployment-Prozess

### 1. Vorbereitungen
```bash
# Auf dem Server - Cleanup falls nötig
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server
docker-compose -f docker-compose.staging.yaml down --volumes
docker system prune -f

# Neueste Version holen
cd /opt/vertic
git pull origin main
```

### 2. Build & Deployment
```bash
# Zum Server-Verzeichnis wechseln
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server

# Build starten (dauert ~5-10 Minuten)
docker-compose -f docker-compose.staging.yaml build --no-cache

# Services starten
docker-compose -f docker-compose.staging.yaml up -d

# Status prüfen
docker-compose -f docker-compose.staging.yaml ps
docker-compose -f docker-compose.staging.yaml logs -f vertic-server
```

### 3. Health Checks
```bash
# API Server Test
curl -f http://159.69.144.208:8080/health

# Insights Server Test  
curl -f http://159.69.144.208:8081/health

# Web Interface Test
curl -f http://159.69.144.208:8082
```

## 🔧 Konfiguration

### Environment Variables
- `RUNMODE=staging` - Deployment-Modus
- `SERVER_ID=vertic-primary` - Server-Identifikation
- `LOGGING=normal` - Log-Level
- `ROLE=monolith` - Server-Typ

### Ports & Services
- **8080** - Hauptsächliche API
- **8081** - Monitoring & Insights
- **8082** - Web-Interface & Admin-Panel

### Datenbank
- **Host:** host.docker.internal
- **Port:** 5432
- **Database:** vertic
- **User:** postgres

## 📊 Monitoring & Logs

### Container-Status
```bash
docker ps                                    # Laufende Container
docker-compose logs -f vertic-server        # Server-Logs live
docker stats                                # Ressourcen-Verbrauch
```

### Health Monitoring
```bash
# Automatischer Health Check alle 30s
docker inspect vertic-kassensystem-server --format='{{.State.Health.Status}}'

# Manuelle Tests
curl http://159.69.144.208:8080/health
curl http://159.69.144.208:8081/metrics     # Prometheus-Metriken
```

### Log-Management
- **Automatic Rotation:** Täglich, 7 Tage aufbewahrt
- **Error Logs:** 30 Tage aufbewahrt
- **Location:** Named Volume `vertic_kassensystem_logs`

## 🔒 Sicherheit

### Best Practices Implementiert
- ✅ Non-root Container User (`verticsrv`)
- ✅ Minimales Production Image (Debian Slim)
- ✅ Resource Limits & Health Checks
- ✅ Network Isolation
- ✅ Log Rotation
- ✅ Secure Configuration Management

### Firewall (Hetzner)
- **Port 22:** SSH Access
- **Port 8080-8082:** API Services
- **Port 5432:** PostgreSQL (localhost only)

## 📈 Performance-Tuning

### Aktuelle Optimierungen
- **Isolates:** 2 (für CX21 Server)
- **Max Connections:** 25 (PostgreSQL)
- **Concurrent Requests:** 100
- **Request Timeout:** 30s
- **Future Calls:** 3 concurrent

### Scaling-Optionen
- Vertikale Skalierung: Upgrade auf CX31 (4 vCPU, 8GB RAM)
- Horizontale Skalierung: Load Balancer + Multiple Instanzen
- Database Scaling: PostgreSQL Read Replicas

## 🚨 Troubleshooting

### Häufige Probleme

#### Container startet nicht
```bash
# Logs prüfen
docker-compose logs vertic-server

# PostgreSQL-Verbindung testen
docker run --rm postgres:16-alpine pg_isready -h 159.69.144.208 -p 5432 -U postgres
```

#### Speicher-Probleme
```bash
# Speicher freigeben
docker system prune -f
docker volume prune -f

# Disk Usage prüfen
df -h
docker system df
```

#### Performance-Probleme
```bash
# Resource Usage
docker stats vertic-kassensystem-server

# PostgreSQL Performance  
sudo -u postgres psql -d vertic -c "SELECT * FROM pg_stat_activity;"
```

### Support-Kontakte
- **Server-Provider:** Hetzner Cloud Support
- **Emergency Access:** Hetzner VNC Console
- **Database:** pgAdmin4 - http://159.69.144.208/pgadmin4

## 🔄 Update-Prozess

### Reguläre Updates
1. **Code Updates:**
   ```bash
   cd /opt/vertic
   git pull origin main
   cd vertic_app/vertic/vertic_server/vertic_server_server
   docker-compose -f docker-compose.staging.yaml up -d --build
   ```

2. **Dependency Updates:**
   ```bash
   # pubspec.yaml anpassen
   # Rebuild erforderlich
   docker-compose -f docker-compose.staging.yaml build --no-cache
   ```

3. **Serverpod Updates:**
   ```bash
   # Alle pubspec.yaml files aktualisieren
   # Migration scripts prüfen
   # Staged Deployment empfohlen
   ```

## 📱 Client-Integration

### Flutter Apps Konfiguration
```dart
// config/environment.dart
static const String serverUrl = 'http://159.69.144.208:8080/';
```

### Build Commands
```bash
# Development
flutter run --dart-define=USE_STAGING=true

# Production Build
flutter build apk --dart-define=SERVER_URL=http://159.69.144.208:8080/
flutter build web --dart-define=SERVER_URL=http://159.69.144.208:8080/
```

## 💡 Best Practices

### Code-Qualität
- Alle Lints aktiviert
- Comprehensive Testing
- Code Generation automatisiert
- API Documentation

### Operations
- Automated Health Checks
- Structured Logging
- Performance Monitoring
- Backup Strategies

### Security
- Regular Updates
- Secure Configuration
- Access Control
- Audit Logging

---

**System Status:** ✅ Production Ready  
**Last Updated:** Dezember 2024  
**Version:** 1.0.0  
**Maintained by:** Vertic Development Team 