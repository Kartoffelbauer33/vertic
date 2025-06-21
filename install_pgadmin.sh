#!/bin/bash

# pgAdmin 4 Web-Interface Installation Script
# Für Ubuntu 22.04 LTS

echo "=== pgAdmin 4 Web-Interface Installation ==="

# 1. Repository-Schlüssel hinzufügen
echo "Repository-Schlüssel hinzufügen..."
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

# 2. Repository hinzufügen
echo "Repository hinzufügen..."
echo 'deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/jammy pgadmin4 main' > /etc/apt/sources.list.d/pgadmin4.list

# 3. Pakete aktualisieren
echo "Pakete aktualisieren..."
apt update

# 4. pgAdmin4 Web installieren
echo "pgAdmin4 installieren..."
apt install -y pgadmin4-web

# 5. Apache2 installieren (falls nicht vorhanden)
echo "Apache2 installieren..."
apt install -y apache2

# 6. pgAdmin Web-Setup ausführen
echo "pgAdmin Web-Setup..."
echo "Bitte folgende Daten eingeben:"
echo "Email: admin@vertic.local"
echo "Password: GreifbarB2019"
/usr/pgadmin4/bin/setup-web.sh

# 7. Apache2 aktivieren und starten
echo "Apache2 starten..."
systemctl enable apache2
systemctl start apache2

# 8. UFW Regel für Port 80 hinzufügen
echo "Firewall-Regel hinzufügen..."
ufw allow 80/tcp
ufw reload

# 9. Status prüfen
echo "=== Installation abgeschlossen ==="
echo "pgAdmin Web-Interface verfügbar unter:"
echo "http://159.69.144.208/pgadmin4/"
echo ""
echo "Login-Daten:"
echo "Email: admin@vertic.local"
echo "Password: GreifbarB2019"
echo ""
echo "Database-Verbindung:"
echo "Host: 159.69.144.208"
echo "Port: 5432"
echo "Database: test_db"
echo "Username: postgres"
echo "Password: GreifbarB2019"

systemctl status apache2 