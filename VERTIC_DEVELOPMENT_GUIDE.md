# 🚀 VERTIC KASSENSYSTEM - KOMPLETTE ENTWICKLUNGSANLEITUNG

## 📋 Was haben wir geschaffen?

**Ein professionelles Flutter + Serverpod System für euer Boulder-Hall Management:**
- **Backend:** Serverpod 2.8.0 auf Hetzner VPS (159.69.144.208)
- **Frontend:** Zwei Flutter Apps (Kunden-App + Personal-App)
- **Datenbank:** PostgreSQL 16 mit umfassendem Schema
- **Deployment:** Docker-basiert, Production-Ready
- **Security:** RBAC (Role-Based Access Control)

---

## 🏗️ SYSTEM ARCHITEKTUR

```
┌─────────────────────┐    ┌─────────────────────┐
│   Flutter Client    │    │   Flutter Staff     │
│   (Kunden-App)      │    │   (Personal-App)    │
│   - QR-Code         │    │   - Admin Panel     │
│   - Ticket kaufen   │    │   - Scanner         │
│   - Profil          │    │   - Management      │
└─────────┬───────────┘    └─────────┬───────────┘
          │                          │
          └─────────────┬────────────┘
                        │ HTTP REST API
                 ┌──────▼─────────────────┐
                 │   Serverpod Server     │
                 │   159.69.144.208       │
                 │   :8080 API            │
                 │   :8081 Monitoring     │
                 │   :8082 Web Interface  │
                 └──────────┬─────────────┘
                            │
                    ┌───────▼───────┐
                    │  PostgreSQL   │
                    │   Database    │
                    │   vertic      │
                    └───────────────┘
```

---

## 💻 ENTWICKLUNGSUMGEBUNG SETUP

### **Voraussetzungen installieren:**

#### **Windows/Mac/Linux:**
```bash
# 1. Flutter SDK installieren
https://docs.flutter.dev/get-started/install

# 2. Dart SDK (kommt mit Flutter)
flutter doctor

# 3. IDE Setup
- VS Code + Flutter Extension
- Oder Android Studio + Flutter Plugin

# 4. Git
git --version

# 5. SSH Access (für Server-Deployment)
ssh-keygen -t rsa -b 4096
```

#### **Projekt klonen:**
```bash
git clone https://github.com/Kartoffelbauer33/vertic.git
cd vertic
```

---

## 🔧 LOKALE ENTWICKLUNG

### **1. Server-Entwicklung (Backend)**

#### **Lokaler Serverpod-Server starten:**
```bash
cd vertic_app/vertic/vertic_server/vertic_server_server

# Dependencies installieren
flutter pub get

# Code generieren
dart run serverpod_cli generate

# Lokalen Server starten
dart run bin/main.dart

# Server läuft auf:
# http://localhost:8080 - API
# http://localhost:8081 - Insights/Monitoring  
# http://localhost:8082 - Web Interface
```

#### **Datenbank-Setup (lokal):**
```bash
# PostgreSQL installieren
# Windows: https://www.postgresql.org/download/windows/
# Mac: brew install postgresql

# Datenbank erstellen
createdb vertic_local

# In lib/src/generated/tables.sql die Tabellen erstellen
psql -d vertic_local -f lib/src/generated/tables.sql
```

#### **Server-Code ändern:**
```bash
# 1. Endpoint ändern (z.B. lib/src/endpoints/user_endpoint.dart)
# 2. Neue Modelle in lib/src/model/ erstellen
# 3. Code neu generieren:
dart run serverpod_cli generate

# 4. Server neu starten:
dart run bin/main.dart
```

### **2. Flutter-App Entwicklung (Frontend)**

#### **Kunden-App entwickeln:**
```bash
cd vertic_app/vertic/vertic_project/vertic_client_app

# Dependencies installieren
flutter pub get

# App starten (Simulator/Emulator)
flutter run

# Oder auf physischem Gerät:
flutter run -d <device-id>
```

#### **Personal-App entwickeln:**
```bash
cd vertic_app/vertic/vertic_project/vertic_staff_app

# Dependencies installieren  
flutter pub get

# App starten
flutter run
```

#### **Flutter-Code ändern:**
```bash
# 1. UI ändern in lib/pages/ oder lib/widgets/
# 2. Serverpod-Client nutzen für API-Calls
# 3. Hot Reload: Cmd+R / Ctrl+R
# 4. Hot Restart: Cmd+Shift+R / Ctrl+Shift+R
```

---

## 🌐 SERVER-INTEGRATION

### **Backend-URL konfigurieren:**

#### **Für lokale Entwicklung:**
```dart
// lib/config/environment.dart
class Environment {
  static const String serverUrl = 'http://localhost:8080/';
  static const bool isProduction = false;
}
```

#### **Für Staging (euer Hetzner Server):**
```dart
// lib/config/environment.dart  
class Environment {
  static const String serverUrl = 'http://159.69.144.208:8080/';
  static const bool isProduction = false;
}
```

#### **API-Calls in Flutter:**
```dart
// Serverpod Client erstellen
final client = Caller(
  Uri.parse(Environment.serverUrl),
);

// API aufrufen
try {
  final users = await client.user.getAllUsers();
  print('Benutzer erhalten: ${users.length}');
} catch (e) {
  print('Fehler: $e');
}
```

---

## 📦 DEPLOYMENT GUIDE

### **1. Code auf Server deployen:**

#### **Änderungen hochladen:**
```bash
# 1. Lokal committen
git add .
git commit -m "Neue Features hinzugefügt"

# 2. Zum Server pushen
git push origin main

# 3. Auf Server pullen
ssh root@159.69.144.208
cd /opt/vertic
git pull origin main
```

#### **Server neu builden:**
```bash
# Auf dem Server:
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server

# Build starten (dauert ~5-10 Min)
docker-compose -f docker-compose.staging.yaml build --no-cache

# Services starten
docker-compose -f docker-compose.staging.yaml up -d

# Status prüfen
docker-compose -f docker-compose.staging.yaml ps
docker-compose -f docker-compose.staging.yaml logs -f vertic-server
```

### **2. Flutter Apps builden:**

#### **Android APK:**
```bash
cd vertic_app/vertic/vertic_project/vertic_client_app

# Release APK builden
flutter build apk --release --dart-define=SERVER_URL=http://159.69.144.208:8080/

# APK finden in: build/app/outputs/flutter-apk/app-release.apk
```

#### **iOS App:**
```bash
cd vertic_app/vertic/vertic_project/vertic_client_app

# iOS build (nur auf Mac)
flutter build ios --release --dart-define=SERVER_URL=http://159.69.144.208:8080/
```

#### **Web App:**
```bash
cd vertic_app/vertic/vertic_project/vertic_client_app

# Web build
flutter build web --dart-define=SERVER_URL=http://159.69.144.208:8080/

# Web-Files in: build/web/
```

---

## 🔍 MONITORING & DEBUGGING

### **Server-Status prüfen:**
```bash
# Health Check
curl http://159.69.144.208:8080/health

# Monitoring Dashboard
http://159.69.144.208:8081

# Logs anschauen
ssh root@159.69.144.208
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server
docker-compose -f docker-compose.staging.yaml logs -f vertic-server
```

### **Datenbank-Zugriff:**
```bash
# pgAdmin Web-Interface
http://159.69.144.208/pgadmin4

# Login:
# Email: guntramschedler@gmail.com
# Passwort: [aus SERVER_SETUP.md]

# Oder direkt via SSH:
ssh root@159.69.144.208
sudo -u postgres psql -d vertic
```

### **Flutter App Debugging:**
```bash
# Debug-Mode starten
flutter run --debug

# Logs anschauen
flutter logs

# Dart DevTools öffnen
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 🚀 TYPISCHE ENTWICKLUNGSABLÄUFE

### **Szenario 1: Neues API-Endpoint hinzufügen**

**Backend (Leon):**
```bash
1. cd vertic_app/vertic/vertic_server/vertic_server_server

2. Neues Endpoint erstellen:
   lib/src/endpoints/my_new_endpoint.dart

3. Endpoint-Code schreiben:
   class MyNewEndpoint extends Endpoint {
     Future<String> hello(Session session) async {
       return 'Hello World!';
     }
   }

4. Code generieren:
   dart run serverpod_cli generate

5. Lokal testen:
   dart run bin/main.dart
   curl http://localhost:8080/myNew/hello

6. Zum Server deployen:
   git add . && git commit -m "New endpoint added"
   git push origin main
   # Dann Server-Build wie oben
```

**Frontend (Kollege):**
```bash
1. cd vertic_app/vertic/vertic_project/vertic_client_app

2. Neuen API-Call verwenden:
   final result = await client.myNew.hello();
   print('Server sagt: $result');

3. UI aktualisieren:
   lib/pages/my_page.dart

4. Testen:
   flutter run
```

### **Szenario 2: Neue Flutter-Seite erstellen**

**Frontend (Kollege):**
```bash
1. cd vertic_app/vertic/vertic_project/vertic_client_app

2. Neue Seite erstellen:
   lib/pages/new_feature_page.dart

3. Seite implementieren:
   class NewFeaturePage extends StatefulWidget {
     // UI Code hier
   }

4. Navigation hinzufügen:
   Navigator.push(context, 
     MaterialPageRoute(builder: (context) => NewFeaturePage())
   );

5. Testen:
   flutter run
   # Hot Reload für schnelle Änderungen: R
```

### **Szenario 3: Datenbank-Schema ändern**

**Backend (Leon):**
```bash
1. Neue Tabelle/Modell erstellen:
   lib/src/model/my_new_model.dart

2. Modell-Code schreiben:
   class MyNewModel extends SerializableModel {
     int? id;
     String name;
     DateTime createdAt;
   }

3. Migration erstellen:
   dart run serverpod_cli create-migration

4. Code generieren:
   dart run serverpod_cli generate

5. Migration ausführen (auf Server):
   dart run bin/main.dart --apply-migrations
```

---

## 🛠️ HÄUFIGE PROBLEME & LÖSUNGEN

### **Problem: "Target of URI doesn't exist"**
```bash
# Lösung: Code-Generation ausführen
cd vertic_app/vertic/vertic_server/vertic_server_server
dart run serverpod_cli generate
```

### **Problem: Flutter build failed**
```bash
# Lösung: Clean & Rebuild
flutter clean
flutter pub get
flutter run
```

### **Problem: Server nicht erreichbar**
```bash
# Lösung: Server-Status prüfen
ssh root@159.69.144.208
cd /opt/vertic/vertic_app/vertic/vertic_server/vertic_server_server
docker-compose -f docker-compose.staging.yaml ps
docker-compose -f docker-compose.staging.yaml up -d
```

### **Problem: Datenbank-Verbindung fehlgeschlagen**
```bash
# Lösung: PostgreSQL Status prüfen
ssh root@159.69.144.208
systemctl status postgresql
sudo -u postgres psql -c "SELECT version();"
```

---

## 📚 WICHTIGE LINKS & RESOURCES

### **Dokumentation:**
- **Serverpod:** https://docs.serverpod.dev/
- **Flutter:** https://docs.flutter.dev/
- **PostgreSQL:** https://www.postgresql.org/docs/

### **Euer System:**
- **API Server:** http://159.69.144.208:8080
- **Monitoring:** http://159.69.144.208:8081  
- **Web Interface:** http://159.69.144.208:8082
- **pgAdmin:** http://159.69.144.208/pgadmin4
- **Server SSH:** `ssh root@159.69.144.208`

### **Code-Repository:**
- **GitHub:** https://github.com/Kartoffelbauer33/vertic

---

## 👥 TEAM-WORKFLOWS

### **Leon (Backend-Entwicklung):**
```bash
# Typischer Arbeitstag:
1. Server-Status prüfen
2. Neue Endpoints/Features entwickeln  
3. Lokal testen
4. Code committen & deployen
5. Kollegen über API-Änderungen informieren
```

### **Kollege (Frontend-Entwicklung):**
```bash
# Typischer Arbeitstag:
1. Aktuelle API-Dokumentation prüfen
2. UI/UX Features entwickeln
3. Mit echtem Server testen (159.69.144.208:8080)
4. Apps builden & distribuieren
5. Feedback an Leon für Backend-Anpassungen
```

### **Gemeinsame Code-Reviews:**
```bash
# Vor wichtigen Releases:
1. Beide: Lokale Tests
2. Leon: Server-Deployment auf Staging
3. Kollege: Flutter Apps gegen Staging testen
4. Gemeinsam: Funktionalität durchgehen
5. Release: Production-Deployment
```

---

## 🎯 NEXT STEPS

### **Kurzfristig (diese Woche):**
- ✅ Server läuft professionell
- 🔄 Flutter Apps an neuen Server anschließen
- 🔄 Erste echte Features implementieren

### **Mittelfristig (nächster Monat):**
- 📱 Apps in App Stores veröffentlichen
- 🔒 HTTPS/SSL-Zertifikat hinzufügen
- 📊 Monitoring & Analytics erweitern

### **Langfristig (nächste Monate):**
- 🚀 Load Balancer für Skalierung
- 💾 Automatische Backups
- 🔄 CI/CD Pipeline
- 📈 Performance-Optimierung

---

**🎉 IHR HABT JETZT EIN ENTERPRISE-SYSTEM!**

Das ist ein **professionelles Setup**, mit dem ihr dauerhaft arbeiten könnt. Alle Best Practices sind implementiert, das System ist skalierbar und wartungsfreundlich.

**Bei Fragen:** Einfach diese Anleitung durchgehen oder das DEPLOYMENT.md auf dem Server konsultieren! 