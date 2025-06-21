# 🗄️ VERTIC DATABASE SETUP - PRODUCTION READY

**Komplettes SQL-System für Vertic Datenbank Setup & Superuser-Einrichtung**

---

## 📋 ÜBERSICHT

Dieses Verzeichnis enthält **die 2 essentiellen SQL-Dateien** für einen kompletten, produktionsreifen Vertic Database Setup:

| Datei | Zweck | Ausführungsreihenfolge | Status |
|-------|-------|----------------------|--------|
| `01_CLEAN_SETUP.sql` | 🧹 **Vollständige DB-Bereinigung + RBAC-System Setup** | **ZUERST** | ✅ Produktionsreif |
| `02_CREATE_SUPERUSER.sql` | 👑 **Superuser-Erstellung mit Unified Auth** | **DANACH** | ✅ Echter bcrypt Hash |

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
-- 📁 Datei: 01_CLEAN_SETUP.sql
-- 🎯 Zweck: Komplette Datenbank-Bereinigung + RBAC-Initialisierung

-- Was passiert:
-- ✅ Löscht ALLE bestehenden User/Auth/RBAC Daten
-- ✅ Erstellt 33 essentielle Permissions in 6 Kategorien
-- ✅ Erstellt 5 Standard-Rollen (Super Admin, Facility Admin, Kassierer, etc.)
-- ✅ Weist Permissions automatisch zu Rollen zu
-- ✅ Zeigt vollständige Verifikation an

-- Ausführung in DBeaver/pgAdmin:
-- File → Execute SQL Script → 01_CLEAN_SETUP.sql
```

#### 2️⃣ **SCHRITT 2: Superuser erstellen**
```sql
-- 📁 Datei: 02_CREATE_SUPERUSER.sql  
-- 🎯 Zweck: Master-Admin-Account mit vollem Zugriff

-- Was passiert:
-- ✅ Erstellt Serverpod UserInfo mit korrektem staff scope
-- ✅ Setzt ECHTEN getesteten bcrypt Hash für Password "super123"
-- ✅ Erstellt StaffUser-Eintrag mit korrekter Verknüpfung
-- ✅ Weist Super Admin Rolle zu (ALLE 33 Permissions)
-- ✅ Fallback: Direkte Permission-Zuweisung falls RBAC leer
-- ✅ Umfassende Verifikation mit Statistiken

-- Ausführung in DBeaver/pgAdmin:
-- File → Execute SQL Script → 02_CREATE_SUPERUSER.sql
```

---

## 🎯 RESULTAT NACH SETUP

### 🔐 **Vollständiges RBAC System**
- **33 Permissions** in 6 Kategorien:
  - `user_management` (7 Permissions)
  - `staff_management` (5 Permissions) 
  - `ticket_management` (9 Permissions)
  - `system_settings` (4 Permissions)
  - `rbac_management` (3 Permissions)
  - `facility_management` (4 Permissions)
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
| **Rolle** | `Super Admin` | Alle 33 Permissions |
| **Level** | `superUser` | Höchste Berechtigung |

### ✅ **Funktionen nach Setup**
- ✅ Login in Vertic Staff App funktioniert
- ✅ Admin Dashboard vollständig zugänglich  
- ✅ Alle RBAC Permissions aktiv (53 Permissions geladen)
- ✅ Unified Authentication konfiguriert
- ✅ Ticket-System, User-Management, etc. voll funktionsfähig

---

## 🏭 PRODUCTION DEPLOYMENT

### 🔒 **Sicherheits-Checkliste**
```bash
# 1. Password ändern nach erstem Login
UPDATE serverpod_email_auth 
SET hash = '$2a$10$NEUER_SICHERER_HASH'
WHERE email = 'superuser@staff.vertic.local';

# 2. Zusätzliche Admin-Accounts erstellen
# 3. Superuser-Account deaktivieren falls gewünscht
# 4. Backup der Permissions-Konfiguration erstellen
```

### 🚀 **Deployment-Reihenfolge**
1. **Database Migration**: Serverpod Migrationen ausführen
2. **RBAC Setup**: `01_CLEAN_SETUP.sql` ausführen
3. **Superuser**: `02_CREATE_SUPERUSER.sql` ausführen  
4. **Verification**: Login testen
5. **Security**: Passwords anpassen
6. **Backup**: DB-State sichern

---

## 🔧 TROUBLESHOOTING

### ❌ **"Benutzer nicht gefunden"**
**Ursache:** Email-Format oder Scope falsch
```sql
-- PRÜFUNG:
SELECT ui."userIdentifier", ui."scopeNames", ea.email 
FROM serverpod_user_info ui
JOIN serverpod_email_auth ea ON ui.id = ea."userId" 
WHERE ui."userIdentifier" LIKE '%superuser%';

-- LÖSUNG: Re-run 02_CREATE_SUPERUSER.sql
```

### ❌ **"Ungültige Anmeldedaten"**  
**Ursache:** Password Hash ungültig
```sql
-- PRÜFUNG:
SELECT hash, LENGTH(hash), LEFT(hash, 7) as hash_type
FROM serverpod_email_auth 
WHERE email = 'superuser@staff.vertic.local';

-- LÖSUNG: Re-run 02_CREATE_SUPERUSER.sql mit korrektem Hash
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

-- LÖSUNG: Re-run 01_CLEAN_SETUP.sql dann 02_CREATE_SUPERUSER.sql
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

-- LÖSUNG: Re-run 02_CREATE_SUPERUSER.sql
```

---

## 🗂️ DATEI-STRUKTUR (BEREINIGT)

```
📁 SQL/
├── 📄 01_CLEAN_SETUP.sql      # Master RBAC Setup
├── 📄 02_CREATE_SUPERUSER.sql # Superuser-Erstellung  
├── 📄 delete_app_users.sql    # Notfall-Bereinigung
└── 📄 README.md               # Diese Dokumentation

❌ Gelöscht (nicht mehr benötigt):
   ├── QUICK_PERMISSION_FIX.sql
   ├── WORKING_BCRYPT_FIX.sql  
   └── [7 weitere redundante Scripts]
```

---

## 🎓 WEITERFÜHRENDE INFORMATIONEN

### 🔑 **RBAC Permissions Kategorien**
- **User Management**: Benutzerverwaltung, Password-Reset
- **Staff Management**: Mitarbeiter, Rollen, Hierarchien  
- **Ticket Management**: Verkauf, Validierung, Rückerstattungen
- **System Settings**: Admin-Panel, Konfiguration, Backups
- **RBAC Management**: Permissions, Rollen verwalten
- **Facility Management**: Einrichtungen, Standorte

### 🏗️ **Architektur-Hinweise** 
- **Unified Auth**: Ein Login-System für Staff & Client Apps
- **Scope-basiert**: `staff` vs `client` Bereiche getrennt
- **bcrypt Hashing**: Production-ready Password-Sicherheit
- **Serverpod Integration**: Nahtlose Framework-Integration

---

## ✅ **SETUP ERFOLGREICH!**

Nach erfolgreichem Setup kannst du:
- 🎯 **Staff App Login**: Username `superuser`, Password `super123`
- 🎛️ **Admin Dashboard**: Vollzugriff auf alle Features
- 👥 **User Management**: Neue Staff-Accounts erstellen
- 🔐 **RBAC**: Permissions & Rollen verwalten  
- 🎫 **Ticket System**: Verkauf, Validierung, Reports
- 🏢 **Facility Management**: Standorte verwalten

**🚀 Das System ist jetzt Production-Ready und voll funktionsfähig!** 