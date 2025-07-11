# pgAdmin 4 Web-Interface Installation

## SOFORT AUSFÜHREN AUF DEM SERVER

Loggen Sie sich auf dem Server ein und führen Sie diese Befehle aus:

```bash
# 1. Repository-Schlüssel hinzufügen
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

# 2. Repository hinzufügen
echo 'deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/jammy pgadmin4 main' > /etc/apt/sources.list.d/pgadmin4.list

# 3. Pakete aktualisieren
apt update

# 4. pgAdmin4 Web installieren
apt install -y pgadmin4-web

# 5. Apache2 installieren (falls nicht vorhanden)
apt install -y apache2

# 6. pgAdmin Web-Setup ausführen (INTERAKTIV!)
/usr/pgadmin4/bin/setup-web.sh
```

**Bei der Setup-Abfrage eingeben:**
- Email: `admin@vertic.local`
- Password: `GreifbarB2019`

```bash
# 7. Apache2 aktivieren und starten
systemctl enable apache2
systemctl start apache2

# 8. UFW Regel für Port 80 hinzufügen
ufw allow 80/tcp
ufw reload

# 9. Status prüfen
systemctl status apache2
```

## ZUGRIFF AUF PGADMIN

Nach der Installation ist pgAdmin verfügbar unter:
**http://159.69.144.208/pgadmin4/**

### Login-Daten:
- **Email**: admin@vertic.local
- **Password**: GreifbarB2019

### Database-Server hinzufügen:
1. Rechtsklick auf "Servers" → "Register" → "Server"
2. **General Tab**:
   - Name: `Vertic Production`
3. **Connection Tab**:
   - Host: `159.69.144.208`
   - Port: `5432`
   - Database: `test_db`
   - Username: `postgres`
   - Password: `GreifbarB2019`

## TROUBLESHOOTING

### Apache2 Status prüfen:
```bash
systemctl status apache2
journalctl -u apache2 -f
```

### pgAdmin Logs prüfen:
```bash
tail -f /var/log/pgadmin/pgadmin4.log
```

### Ports prüfen:
```bash
netstat -tlnp | grep :80
ufw status
```

### Neustart falls nötig:
```bash
systemctl restart apache2
systemctl restart pgadmin4
```

## ALTERNATIVE: DOCKER PGADMIN

Falls die Installation fehlschlägt, können Sie pgAdmin auch als Docker-Container starten:

```bash
docker run -d \
  --name pgadmin \
  --network vertic-network \
  -p 80:80 \
  -e PGADMIN_DEFAULT_EMAIL=admin@vertic.local \
  -e PGADMIN_DEFAULT_PASSWORD=GreifbarB2019 \
  dpage/pgadmin4
```

Dann Zugriff über: **http://159.69.144.208/** 