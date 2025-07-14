# 🗄️ VERTIC DATABASE SETUP - REMOTE EDITION

**Komplettes SQL-Setup für die Remote Hetzner-Database in nur einem Schritt**

---

## 🚀 SCHNELLSTART (für Eilige)

```bash
1. pgAdmin4 mit Hetzner verbinden (159.69.144.208:5432/vertic)
2. Script ausführen: COMPLETE_VERTIC_SETUP.sql
3. Lokalen Server starten: dart run bin/main.dart
4. Staff App starten → Login: superuser / super123
5. FERTIG! ✅
```

---

## 📁 DATEIEN-ÜBERSICHT (Vereinfacht!)

| Datei | Zweck | Wann verwenden? |
|-------|-------|----------------|
| `COMPLETE_VERTIC_SETUP.sql` | 🎯 **HAUPT-SETUP** | **EINMAL AUSFÜHREN** - Erstellt alles |
| `REPAIR_TOOLS.sql` | 🛠️ **REPARATUR** | Nur bei Login-Problemen |
| `CLEANUP_DUPLICATE_USERS.sql` | 🚫 **BUGFIX** | Bei E-Mail-Duplikaten |

**Das war's! Nur noch 3 Dateien - maximale Einfachheit.** 🎉

---

## 🎯 SETUP-ANLEITUNG FÜR REMOTE-DATABASE

### ⚡ SCHRITT 1: Remote-Database-Verbindung

**In pgAdmin4:**
- **Host**: `159.69.144.208`
- **Port**: `5432`
- **Database**: `vertic`
- **Username**: `vertic_dev`
- **Password**: `GreifbarB2019`

### ⚡ SCHRITT 2: Komplettes Setup ausführen

```sql
-- Datei: COMPLETE_VERTIC_SETUP.sql
-- Diese Datei macht ALLES:
-- ✅ Löscht alte Daten (sicher)
-- ✅ Erstellt RBAC-System (45+ Permissions, 6 Rollen)
-- ✅ Erstellt Superuser mit vollem Zugriff
-- ✅ Fügt DACH-Compliance Permissions hinzu
-- ✅ Zeigt Verifikation an

-- Einfach das ganze Script in pgAdmin4 einfügen und ausführen!
```

### ⚡ SCHRITT 3: Lokalen Server starten

```bash
cd vertic_server/vertic_server_server
dart run bin/main.dart
```

**Der Server verbindet sich automatisch mit der Remote-Database!**

### ⚡ SCHRITT 4: Anmelden

**Starte die Vertic Staff App und melde dich an:**

| Feld | Wert |
|------|------|
| **Username** | `superuser` |
| **Password** | `super123` |
| **Email** | `superuser@staff.vertic.local` |

---

## 🏗️ ARCHITEKTUR

### **Remote-Database + Lokaler Server Setup:**

```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────┐
│   Staff App     │───▶│   Lokaler Server     │───▶│ Remote Database │
│  (localhost)    │    │  (localhost:8080)    │    │ (Hetzner:5432)  │
└─────────────────┘    └──────────────────────┘    └─────────────────┘

┌─────────────────┐    ┌──────────────────────┐
│  Client App     │───▶│   Lokaler Server     │
│  (localhost)    │    │  (localhost:8080)    │  
└─────────────────┘    └──────────────────────┘
```

**Vorteile:**
- ✅ **Shared Database**: Beide Entwickler arbeiten mit denselben Daten
- ✅ **Lokaler Server**: Schnelle Development-Zyklen
- ✅ **Remote Data**: Konsistente Daten für das Team
- ✅ **Einfache Migration**: Später leicht auf Production umstellbar

---

## 🛠️ TROUBLESHOOTING

### ❌ Problem: "Benutzer nicht gefunden"

**Lösung:** Führe das Reparatur-Script aus:

```sql
-- Datei: REPAIR_TOOLS.sql
-- Repariert alle häufigen Auth-Probleme automatisch
```

### ❌ Problem: "0 Permissions geladen"

**Lösung:** Führe das Reparatur-Script aus:

```sql
-- Datei: REPAIR_TOOLS.sql
-- Weist alle fehlenden Permissions zu
```

### ❌ Problem: Server kann sich nicht mit Database verbinden

**Prüfe diese Dateien:**
- `config/development.yaml` → Database-Host sollte `159.69.144.208` sein
- `config/passwords.yaml` → Database-Password sollte `GreifbarB2019` sein

### ❌ Problem: Doppelte E-Mail-Adressen

**Lösung:**
```sql
-- Datei: CLEANUP_DUPLICATE_USERS.sql
-- Behebt Race-Condition-Bug mit doppelten AppUsern
```

---

## 📊 WAS WIRD ERSTELLT?

### 🔐 RBAC-System
- **45+ Permissions** in 8 Kategorien:
  - User Management (9)
  - Staff Management (5)
  - Product Management (8) - *Für POS Artikel-Verwaltung*
  - Ticket Management (8)
  - System Settings (4)
  - RBAC Management (3)
  - Facility Management (4)
  - DACH Compliance (6) - *Deutschland/Österreich TSE/RKSV*

### 👥 Rollen-System
- **Super Admin** - Vollzugriff (alle 45+ Permissions)
- **Facility Admin** - Standort-Verwaltung
- **Artikel Manager** - POS Artikel-Verwaltung + Barcode-Scanning
- **Kassierer** - Ticketverkauf + Kasse + Artikel-Anzeige
- **Support Staff** - Kundenbetreuung
- **Readonly User** - Nur-Lese-Zugriff

### 👤 Superuser-Account
- **Username:** `superuser`
- **Password:** `super123` ⚠️ *Bitte nach dem ersten Login ändern!*
- **Rolle:** Super Admin (alle Permissions)
- **Database:** Remote (Hetzner)
- **Server:** Lokal (localhost:8080)

---

## 🔒 SICHERHEITS-HINWEISE

### ⚠️ NACH DEM ERSTEN LOGIN:

1. **Password ändern** (über Staff App)
2. **Zusätzliche Admin-Accounts erstellen**
3. **Remote-Database regelmäßig backupen**

### 🏭 PRODUCTION DEPLOYMENT:

```bash
# 1. Hetzner-Database für Production klonen
# 2. Neue sichere Passwords setzen
# 3. SSL-Verbindungen aktivieren
# 4. Firewall-Regeln verschärfen
```

---

## ❓ HÄUFIGE FRAGEN

**Q: Warum ist der Server lokal aber die Database remote?**
A: **Beste Balance**: Schnelle Development + Shared Data für Team

**Q: Muss ich mehrere Scripts ausführen?**
A: **Nein!** Nur `COMPLETE_VERTIC_SETUP.sql` - das macht alles.

**Q: Was wenn der Login nicht funktioniert?**
A: `REPAIR_TOOLS.sql` ausführen - das repariert 99% aller Probleme.

**Q: Können beide Entwickler gleichzeitig arbeiten?**
A: **Ja!** Jeder startet seinen lokalen Server, beide nutzen dieselbe Remote-Database.

**Q: Wie erstelle ich neue Staff-Accounts?**
A: Nach Superuser-Login → Admin-Dashboard → Staff-Management

---

## 🎉 REMOTE-SETUP FERTIG!

**Das neue Setup ist optimal für Team-Entwicklung:**
1. **Ein Script ausführen** (Remote-Database)
2. **Lokalen Server starten**
3. **Anmelden und arbeiten**

**Bei Problemen:** Reparatur-Script ausführen und es läuft wieder.

**Viel Erfolg mit eurem Remote-Database Team-Setup!** 🚀 
