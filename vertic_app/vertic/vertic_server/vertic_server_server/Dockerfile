# Serverpod Production Dockerfile - Mit Server-seitigem Code Generation
FROM dart:3.5.4-sdk AS build

# Arbeitsverzeichnis setzen
WORKDIR /app

# ZUERST: pubspec.yaml und serverpod config kopieren
COPY pubspec.yaml .
COPY config/ config/

# Abhängigkeiten installieren
RUN dart pub get

# DANN: Source Code kopieren (OHNE generated Dateien!)
COPY bin/ bin/
COPY lib/ lib/
COPY migrations/ migrations/

# WICHTIG: Generated Dateien löschen falls vorhanden
RUN rm -rf lib/src/generated/* || true

# SERVERPOD GENERATE DIREKT AUF SERVER AUSFÜHREN
RUN dart pub global activate serverpod_cli
RUN serverpod generate

# Server kompilieren
RUN dart compile exe bin/main.dart -o bin/server

# Production Image - Ubuntu für bessere Kompatibilität
FROM ubuntu:22.04

# System-Abhängigkeiten installieren
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Server Binary und Konfiguration kopieren
COPY --from=build /app/bin/server /usr/local/bin/vertic_server
COPY --from=build /app/config /app/config
COPY --from=build /app/migrations /app/migrations

# Startup Script erstellen das Environment Variables verwendet
RUN echo '#!/bin/bash' > /usr/local/bin/start_vertic.sh && \
    echo 'echo "Starting Serverpod with Environment Variables..."' >> /usr/local/bin/start_vertic.sh && \
    echo 'echo "SERVERPOD_DATABASE_HOST: $SERVERPOD_DATABASE_HOST"' >> /usr/local/bin/start_vertic.sh && \
    echo 'echo "SERVERPOD_DATABASE_NAME: $SERVERPOD_DATABASE_NAME"' >> /usr/local/bin/start_vertic.sh && \
    echo 'exec /usr/local/bin/vertic_server --mode staging --apply-migrations' >> /usr/local/bin/start_vertic.sh && \
    chmod +x /usr/local/bin/start_vertic.sh

# User erstellen für Sicherheit
RUN useradd -r -s /bin/false serverpod
RUN chown -R serverpod:serverpod /app

# Arbeitsverzeichnis setzen
WORKDIR /app

# Ports freigeben
EXPOSE 8080 8081 8082

# User wechseln
USER serverpod

# STARTUP SCRIPT MIT EXPLIZITEM --mode staging UND ENVIRONMENT VARIABLES
CMD ["/usr/local/bin/start_vertic.sh"]
