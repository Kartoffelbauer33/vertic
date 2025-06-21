# 🗄️ VERTIC DATABASE SETUP - PRODUCTION READY

**Komplettes SQL-System für Vertic Datenbank Setup & Superuser-Einrichtung**

---

## 📋 ÜBERSICHT

Dieses Verzeichnis enthält **die essentiellen SQL-Dateien** für einen kompletten, produktionsreifen Vertic Database Setup:

| Datei | Zweck | Ausführungsreihenfolge | Status |
|-------|-------|----------------------|--------|
| `01_CLEAN_SETUP_FINAL_CORRECTED.sql` | 🧹 **Vollständige DB-Bereinigung + RBAC-System Setup** | **ZUERST** | ✅ Produktionsreif |
| `02_CREATE_SUPERUSER_FINAL_CORRECTED.sql` | 👑 **Superuser-Erstellung mit Unified Auth** | **DANACH** | ✅ Echter bcrypt Hash |
| `check_superuser.sql` | ✅ **Permission-Check & Reparatur** | **Optional** | ✅ Verifikation |
| `FIND_INVALID_STAFF_LEVEL.sql` | 🔧 **StaffLevel Enum Reparatur** | **Bei Bedarf** | ✅ Reparatur-Tool |
| `FIX_STAFF_USER_LINK_CORRECT.sql` | 🔗 **UserInfo-Verknüpfung reparieren** | **Bei Bedarf** | ✅ Reparatur-Tool |

---

## 🚀 KOMPLETTE SETUP-ANLEITUNG

### ⚡ SCHNELLSTART (für Entwickler)
```bash
# 1. PostgreSQL starten
# 2. In DBeaver/pgAdmin verbinden zu test_db
# 3. Script 1 ausführen → Script 2 ausführen → FERTIG!
```

### 🔧 DETAILLIERTE ANLEITUNG

#### 1️⃣ **SCHRITT 1: Database Clean Setup**
```sql
-- 📁 Datei: 01_CLEAN_SETUP_FINAL_CORRECTED.sql
-- 🎯 Zweck: Komplette Datenbank-Bereinigung + RBAC-Initialisierung

-- Was passiert:
-- ✅ Löscht ALLE bestehenden User/Auth/RBAC Daten
-- ✅ Erstellt 53 essentielle Permissions in 8 Kategorien
-- ✅ Erstellt 5 Standard-Rollen (Super Admin, Facility Admin, Kassierer, etc.)
-- ✅ Weist Permissions automatisch zu Rollen zu
-- ✅ Zeigt vollständige Verifikation an
-- ✅ Verwendet korrekte staffLevel Werte (0,1,2,3)

-- Ausführung in DBeaver/pgAdmin:
-- File → Execute SQL Script → 01_CLEAN_SETUP_FINAL_CORRECTED.sql
```

#### 2️⃣ **SCHRITT 2: Superuser erstellen**
```sql
-- 📁 Datei: 02_CREATE_SUPERUSER_FINAL_CORRECTED.sql  
-- 🎯 Zweck: Master-Admin-Account mit vollem Zugriff

-- Was passiert:
-- ✅ Erstellt Serverpod UserInfo mit korrektem staff scope
-- ✅ Setzt ECHTEN getesteten bcrypt Hash für Password "super123"
-- ✅ Erstellt StaffUser-Eintrag mit korrekter userInfoId Verknüpfung
-- ✅ Verwendet staffLevel = 3 (superUser) - NICHT 99!
-- ✅ Weist Super Admin Rolle zu (ALLE 53 Permissions)
-- ✅ Fallback: Direkte Permission-Zuweisung falls RBAC leer
-- ✅ Umfassende Verifikation mit Statistiken

-- Ausführung in DBeaver/pgAdmin:
-- File → Execute SQL Script → 02_CREATE_SUPERUSER_FINAL_CORRECTED.sql
```

---

## 🎯 RESULTAT NACH SETUP

### 🔐 **Vollständiges RBAC System**
- **53 Permissions** in 8 Kategorien:
  - `user_management` (14 Permissions)
  - `staff_management` (7 Permissions) 
  - `ticket_management` (10 Permissions)
  - `system_settings` (4 Permissions)
  - `rbac_management` (3 Permissions)
  - `facility_management` (4 Permissions)
  - `reporting_analytics` (4 Permissions)
  - `status_management` (4 Permissions)
  - `gym_management` (4 Permissions)
- **5 Rollen** mit unterschiedlichen Berechtigungen
- **Super Admin** mit ALLEN Permissions

### 👤 **Production-Ready Superuser**
| Attribut | Wert | Beschreibung |
|----------|------|-------------|
| **Username** | `superuser` | Login-Name für Staff App |
| **Password** | `super123` | Getestetes Standard-Passwort |
| **Email** | `superuser@staff.vertic.local` | ⚠️ **WICHTIG**: @staff Domain! |
| **Scope** | `["staff"]` | Zugang zur Staff App |
| **Hash** | `$2a$10$KNc...` | Echter bcrypt Hash (getestet!) |
| **Rolle** | `Super Admin` | Alle 53 Permissions |
| **StaffLevel** | `3` | superUser (NICHT 99!) |
| **UserInfoId** | `Verknüpft` | Korrekte Serverpod-Verknüpfung |

### ✅ **Funktionen nach Setup**
- ✅ Login in Vertic Staff App funktioniert
- ✅ Admin Dashboard vollständig zugänglich  
- ✅ Alle RBAC Permissions aktiv (53 Permissions geladen)
- ✅ Unified Authentication konfiguriert
- ✅ Ticket-System, User-Management, etc. voll funktionsfähig

---

## 🔧 KRITISCHE ERKENNTNISSE & TROUBLESHOOTING

### ❌ **"Staff-User nicht aktiv" Fehler**
**Ursache:** `userInfoId` Feld in `staff_users` ist NULL oder falsch verknüpft
```sql
-- DIAGNOSE:
SELECT su.email, su."userInfoId", ui.id 
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
WHERE su.email = 'superuser@staff.vertic.local';

-- LÖSUNG: Führe FIX_STAFF_USER_LINK_CORRECT.sql aus
```

### ❌ **"Invalid argument(s): Value cannot be converted to StaffUserType"**
**Ursache:** `staffLevel` Feld enthält ungültige Werte (z.B. 99, NULL)
```sql
-- DIAGNOSE:
SELECT email, "staffLevel" FROM staff_users 
WHERE "staffLevel" NOT IN (0,1,2,3);

-- LÖSUNG: Führe FIND_INVALID_STAFF_LEVEL.sql aus
```

### 🔧 **StaffUserType Enum Werte (KRITISCH!)**
```
0 = staff
1 = hallAdmin  
2 = facilityAdmin
3 = superUser

❌ ALLE anderen Werte (99, NULL, etc.) sind UNGÜLTIG!
```

### 🔗 **Serverpod-Staff Verknüpfung**
```sql
-- KORREKTE Verknüpfung:
staff_users.userInfoId = serverpod_user_info.id
staff_users.email = serverpod_user_info.email

-- FALSCHE Feldnamen (existieren nicht):
-- serverpodUserId ❌
-- serverpod_user_id ❌
```

### 🔐 **Unified Authentication Setup**
```sql
-- KRITISCHE Felder für Staff App Login:
serverpod_user_info.scopeNames = '["staff"]'
serverpod_user_info.blocked = false
serverpod_email_auth.hash = '$2a$10$...' (echter bcrypt Hash)
```

---

## 🛠️ REPARATUR-TOOLS

### 🔧 **Permission-Check & Reparatur**
```sql
-- Datei: check_superuser.sql
-- Prüft und repariert Superuser Permissions
-- Führt automatische Reparatur durch
```

### 🔧 **StaffLevel Enum Reparatur**
```sql
-- Datei: FIND_INVALID_STAFF_LEVEL.sql
-- Findet alle ungültigen staffLevel Werte
-- Korrigiert automatisch:
-- - 99 → 3 (superUser)
-- - NULL → 0 (staff)
-- - Andere → 0 (staff)
```

### 🔧 **UserInfo-Verknüpfung reparieren**
```sql
-- Datei: FIX_STAFF_USER_LINK_CORRECT.sql
-- Verknüpft Staff Users mit Serverpod UserInfo
-- Basiert auf Email-Matching
-- Zeigt detaillierte Verifikation
```

---

## 🏭 PRODUCTION DEPLOYMENT

### 🔒 **Sicherheits-Checkliste**
```sql
-- 1. Password ändern nach erstem Login
UPDATE serverpod_email_auth 
SET hash = '$2a$10$NEUER_SICHERER_HASH'
WHERE email = 'superuser@staff.vertic.local';

-- 2. Zusätzliche Admin-Accounts erstellen
-- 3. Superuser-Account deaktivieren falls gewünscht
-- 4. Backup der Permissions-Konfiguration erstellen
```

### 🚀 **Deployment-Reihenfolge**
1. **Database Migration**: Serverpod Migrationen ausführen
2. **RBAC Setup**: `01_CLEAN_SETUP_FINAL_CORRECTED.sql` ausführen
3. **Superuser**: `02_CREATE_SUPERUSER_FINAL_CORRECTED.sql` ausführen  
4. **Verification**: Login testen
5. **Repair (falls nötig)**: Reparatur-Tools ausführen
6. **Security**: Passwords anpassen
7. **Backup**: DB-State sichern

---

## 🔧 ERWEITERTE TROUBLESHOOTING-SZENARIEN

### ❌ **"Benutzer nicht gefunden"**
**Ursache:** Email-Format oder Scope falsch
```sql
-- PRÜFUNG:
SELECT ui."userIdentifier", ui."scopeNames", ea.email 
FROM serverpod_user_info ui
JOIN serverpod_email_auth ea ON ui.id = ea."userId" 
WHERE ui."userIdentifier" LIKE '%superuser%';

-- LÖSUNG: Re-run 02_CREATE_SUPERUSER_FINAL_CORRECTED.sql
```

### ❌ **"Ungültige Anmeldedaten"**  
**Ursache:** Password Hash ungültig
```sql
-- PRÜFUNG:
SELECT hash, LENGTH(hash), LEFT(hash, 7) as hash_type
FROM serverpod_email_auth 
WHERE email = 'superuser@staff.vertic.local';

-- LÖSUNG: Re-run 02_CREATE_SUPERUSER_FINAL_CORRECTED.sql mit korrektem Hash
```

### ❌ **"0 Permissions geladen"**
**Ursache:** RBAC-System leer oder isActive=false
```sql
-- PRÜFUNG:
SELECT COUNT(*) as total_permissions FROM permissions;
SELECT COUNT(*) as assigned_permissions 
FROM staff_user_permissions sup
JOIN staff_users su ON sup."staffUserId" = su.id  
WHERE su."employeeId" = 'superuser' AND sup."isActive" = true;

-- LÖSUNG: check_superuser.sql ausführen
```

### ❌ **"Admin Tab nicht sichtbar"**
**Ursache:** Permission `can_access_admin_dashboard` fehlt
```sql
-- PRÜFUNG:
SELECT p.name 
FROM staff_users su
JOIN staff_user_permissions sup ON su.id = sup."staffUserId"
JOIN permissions p ON sup."permissionId" = p.id
WHERE su."employeeId" = 'superuser' 
AND p.name = 'can_access_admin_dashboard';

-- LÖSUNG: check_superuser.sql ausführen
```

### ❌ **Server-Logs zeigen "StaffUser nicht gefunden für UserInfo.id=X"**
**Ursache:** userInfoId Verknüpfung fehlt oder ist falsch
```sql
-- PRÜFUNG:
SELECT su.id, su.email, su."userInfoId", ui.id as actual_id
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su.email = ui.email
WHERE su.email = 'superuser@staff.vertic.local';

-- LÖSUNG: FIX_STAFF_USER_LINK_CORRECT.sql ausführen
```

---

## 🗂️ DATEI-STRUKTUR (BEREINIGT)

```
📁 SQL/
├── 📄 01_CLEAN_SETUP_FINAL_CORRECTED.sql      # Master RBAC Setup
├── 📄 02_CREATE_SUPERUSER_FINAL_CORRECTED.sql # Superuser-Erstellung  
├── 📄 check_superuser.sql                     # Permission-Verifikation
├── 📄 FIND_INVALID_STAFF_LEVEL.sql           # StaffLevel Reparatur
├── 📄 FIX_STAFF_USER_LINK_CORRECT.sql        # UserInfo-Link Reparatur
└── 📄 README.md                              # Diese Dokumentation

✅ Bereinigt - Redundante Dateien entfernt:
   ├── DEBUG_AUTH_SYSTEM.sql
   ├── DEBUG_SUPERUSER_STATUS.sql
   ├── FIX_STAFF_LEVEL.sql
   ├── FIX_STAFF_USER_LINK.sql
   └── delete_app_users.sql
```

---

## 🎓 TECHNISCHE DETAILS

### 🔑 **RBAC Permissions Kategorien**
- **User Management**: Benutzerverwaltung, Password-Reset, Profile
- **Staff Management**: Mitarbeiter, Rollen, Hierarchien, Dienstpläne  
- **Ticket Management**: Verkauf, Validierung, Rückerstattungen, Typen
- **System Settings**: Admin-Panel, Konfiguration, Backups
- **RBAC Management**: Permissions, Rollen verwalten
- **Facility Management**: Einrichtungen, Standorte
- **Reporting & Analytics**: Berichte, Finanzen, Audit-Logs
- **Status Management**: Status-Typen verwalten
- **Gym Management**: Gym-Verwaltung

### 🏗️ **Architektur-Hinweise** 
- **Unified Auth**: Ein Login-System für Staff & Client Apps
- **Scope-basiert**: `staff` vs `client` Bereiche getrennt
- **bcrypt Hashing**: Production-ready Password-Sicherheit
- **Serverpod Integration**: Nahtlose Framework-Integration
- **Enum-basierte Levels**: StaffUserType mit festen Werten 0-3

### 🔗 **Datenbank-Beziehungen**
```sql
-- Kritische Verknüpfungen:
staff_users.userInfoId → serverpod_user_info.id
staff_user_permissions.staffUserId → staff_users.id
staff_user_roles.staffUserId → staff_users.id
role_permissions.roleId → roles.id
serverpod_email_auth.userId → serverpod_user_info.id
```

---

## ✅ **SETUP ERFOLGREICH!**

Nach erfolgreichem Setup kannst du:
- 🎯 **Staff App Login**: Username `superuser`, Password `super123`
- 🎛️ **Admin Dashboard**: Vollzugriff auf alle Features
- 👥 **User Management**: Neue Staff-Accounts erstellen
- 🔐 **RBAC**: Permissions & Rollen verwalten  
- 🎫 **Ticket System**: Verkauf, Validierung, Reports
- 🏢 **Facility Management**: Standorte verwalten

### 🔧 **Bei Problemen:**
1. Prüfe Server-Logs auf spezifische Fehlermeldungen
2. Führe entsprechende Reparatur-Tools aus
3. Verifikation mit `check_superuser.sql`
4. Bei anhaltenden Problemen: Kompletter Neustart mit Setup-Scripts

**🚀 Das System ist jetzt Production-Ready und voll funktionsfähig!** 

---

## 📝 **CHANGELOG & LESSONS LEARNED**

### 🔧 **Kritische Erkenntnisse aus Troubleshooting:**
1. **staffLevel = 99 ist ungültig** → Muss 0,1,2,3 sein
2. **userInfoId Verknüpfung ist essentiell** → Ohne diese: "Staff-User nicht aktiv"
3. **Feldname ist userInfoId** → NICHT serverpodUserId
4. **Email-Matching bei Reparatur** → Automatische Verknüpfung möglich
5. **bcrypt Hash muss korrekt sein** → $2a$10$... Format
6. **Staff Scope ist kritisch** → ["staff"] für Staff App Zugang
7. **Enum-Werte sind strikt** → StaffUserType akzeptiert nur 0-3

### 🚀 **Verbesserungen implementiert:**
- ✅ Korrekte staffLevel Werte in allen Scripts
- ✅ Automatische userInfoId Verknüpfung
- ✅ Umfassende Verifikation und Diagnostik
- ✅ Reparatur-Tools für häufige Probleme
- ✅ Detaillierte Fehlerbeschreibungen
- ✅ Production-ready Sicherheitshinweise 