#!/bin/bash

# Deployment-Skript für Hetzner VPS
# Führe dieses Skript auf dem Server aus: bash deploy_to_hetzner.sh

echo "🚀 Starte Vertic Server Deployment..."

# Farben für bessere Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funktion für farbige Ausgabe
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Schritt 1: System-Updates
print_status "System-Updates..."
apt update -qq

# Schritt 2: Docker installieren falls nicht vorhanden
if ! command -v docker &> /dev/null; then
    print_warning "Docker wird installiert..."
    apt install -y docker.io docker-compose
    systemctl start docker
    systemctl enable docker
else
    print_status "Docker ist bereits installiert"
fi

# Schritt 3: Git installieren falls nicht vorhanden  
if ! command -v git &> /dev/null; then
    print_warning "Git wird installiert..."
    apt install -y git
else
    print_status "Git ist bereits installiert"
fi

# Schritt 4: Arbeitsverzeichnis erstellen
PROJECT_DIR="/opt/vertic"
if [ ! -d "$PROJECT_DIR" ]; then
    print_warning "Erstelle Projekt-Verzeichnis: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
else
    print_status "Projekt-Verzeichnis existiert bereits"
fi

cd "$PROJECT_DIR"

# Schritt 5: Repository klonen oder aktualisieren
if [ ! -d ".git" ]; then
    print_warning "Repository wird geklont..."
    echo "📥 Bitte gib deine Repository-URL ein:"
    read -p "Repository URL: " REPO_URL
    git clone "$REPO_URL" .
else
    print_status "Repository wird aktualisiert..."
    git fetch origin
    git reset --hard origin/main
    git pull origin main
fi

# Schritt 6: Ins Server-Verzeichnis wechseln
SERVER_DIR="vertic_app/vertic/vertic_server/vertic_server_server"
if [ -d "$SERVER_DIR" ]; then
    cd "$SERVER_DIR"
    print_status "Wechsle ins Server-Verzeichnis: $SERVER_DIR"
else
    print_error "Server-Verzeichnis nicht gefunden: $SERVER_DIR"
    exit 1
fi

# Schritt 7: PostgreSQL-Verbindung testen
print_status "Teste PostgreSQL-Verbindung..."
if pg_isready -h localhost -p 5432 -U postgres >/dev/null 2>&1; then
    print_status "PostgreSQL ist bereit"
else
    print_error "PostgreSQL ist nicht erreichbar!"
    print_warning "Stelle sicher, dass PostgreSQL läuft: systemctl status postgresql"
    exit 1
fi

# Schritt 8: Docker Containers stoppen falls sie laufen
if [ -f "docker-compose.staging.yaml" ]; then
    print_status "Stoppe alte Container..."
    docker-compose -f docker-compose.staging.yaml down >/dev/null 2>&1 || true
else
    print_error "docker-compose.staging.yaml nicht gefunden!"
    exit 1
fi

# Schritt 9: Docker Image bauen und starten
print_status "Baue und starte Serverpod Container..."
docker-compose -f docker-compose.staging.yaml up -d --build

# Schritt 10: Warten bis Server bereit ist
print_status "Warte auf Server-Start..."
sleep 10

# Schritt 11: Status prüfen
if docker-compose -f docker-compose.staging.yaml ps | grep -q "Up"; then
    print_status "✨ Deployment erfolgreich!"
    echo ""
    echo "🌐 Dein Serverpod Server läuft jetzt auf:"
    echo "   📡 API:      http://159.69.144.208:8080"
    echo "   📊 Insights: http://159.69.144.208:8081"  
    echo "   🌍 Web:      http://159.69.144.208:8082"
    echo ""
    echo "📱 Flutter Apps können jetzt verbinden mit:"
    echo "   flutter run --dart-define=USE_STAGING=true"
    echo ""
    echo "🔍 Logs anzeigen:"
    echo "   docker-compose -f docker-compose.staging.yaml logs -f"
else
    print_error "Deployment fehlgeschlagen!"
    echo "📋 Container-Status:"
    docker-compose -f docker-compose.staging.yaml ps
    echo ""
    echo "📋 Logs:"
    docker-compose -f docker-compose.staging.yaml logs --tail=20
    exit 1
fi 