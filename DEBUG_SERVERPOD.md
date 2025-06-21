# SERVERPOD DEBUG - Ports nicht erreichbar

## SOFORT AUSFÜHREN AUF DEM SERVER:

```bash
# 1. Container-Status prüfen
docker ps
docker logs vertic-server --tail 20

# 2. Ports prüfen
netstat -tlnp | grep -E ':(8080|8081|8082)'
ss -tlnp | grep -E ':(8080|8081|8082)'

# 3. UFW Firewall prüfen
ufw status
ufw allow 8080/tcp
ufw allow 8081/tcp  
ufw allow 8082/tcp
ufw reload

# 4. Container neu starten mit Debug
docker stop vertic-server
docker rm vertic-server

# 5. Container mit Host-Netzwerk testen
docker run -d \
  --name vertic-server \
  --network host \
  vertic-server

# 6. Logs prüfen
docker logs vertic-server -f
```

## PROBLEM-ANALYSE:

**Wahrscheinliche Ursachen:**
1. Serverpod bindet nicht an 0.0.0.0 sondern localhost
2. UFW blockiert die Ports
3. Container-Netzwerk-Problem

## LÖSUNG 1: HOST-NETZWERK VERWENDEN

```bash
# Container stoppen
docker stop vertic-server postgres
docker rm vertic-server postgres

# PostgreSQL mit Host-Netzwerk
docker run -d \
  --name postgres \
  --network host \
  -e POSTGRES_DB=test_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=GreifbarB2019 \
  postgres:15

# Serverpod mit Host-Netzwerk  
docker run -d \
  --name vertic-server \
  --network host \
  vertic-server

# Testen
curl http://localhost:8080/
curl http://127.0.0.1:8080/
```

## LÖSUNG 2: KONFIGURATION PRÜFEN

Die `production.yaml` muss korrekt konfiguriert sein:

```yaml
apiServer:
  port: 8080
  publicHost: 159.69.144.208
  publicPort: 8080
  publicScheme: http
```

## LÖSUNG 3: MIGRATIONS ANWENDEN

```bash
# Migrations anwenden (für leere Tabellen)
docker exec -it vertic-server /usr/local/bin/vertic_server --apply-migrations

# Oder manuell im Container
docker exec -it vertic-server bash
cd /app
/usr/local/bin/vertic_server --apply-migrations
```

## VOLLSTÄNDIGER NEUSTART:

```bash
# Alles stoppen
docker stop vertic-server postgres
docker rm vertic-server postgres

# PostgreSQL starten
docker run -d \
  --name postgres \
  --network host \
  -e POSTGRES_DB=test_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=GreifbarB2019 \
  postgres:15

# Warten
sleep 5

# Serverpod starten
docker run -d \
  --name vertic-server \
  --network host \
  vertic-server

# Migrations anwenden
sleep 10
docker exec vertic-server /usr/local/bin/vertic_server --apply-migrations

# Testen
curl http://159.69.144.208:8080/
``` 