# Vertic SQL Scripts - Aktualisierte Version

**Stand: 2025-08-09 nach Authentication-Fix und Rollen-Bereinigung**

## 🚀 Aktuelle, verwendbare Scripte

### 1. **CURRENT_SYSTEM_STATUS.sql** 
- **IMMER ZUERST AUSFÜHREN** für Diagnose
- Zeigt aktuellen System-Zustand
- Authentication-Status, Staff-Users, Rollen, Health-Checks
- Aktuell und korrekt nach allen Fixes

### 2. **EMERGENCY_REPAIRS.sql**
- Notfall-Reparaturen für kritische Probleme
- Password-Reset für Superuser auf "super123"
- Deaktivierung der verwirrenden "Super Administrator" Rolle
- Auth-Verknüpfung reparieren

### 3. **STAFF_MANAGEMENT.sql**
- Praktische Tools für Staff-Verwaltung  
- Staff-Overview, Superuser-Details, Rollen-Zuweisungen
- Auth-Probleme diagnostizieren, System-Statistiken

### 4. **Legacy Scripte (behalten für Setup)**
- `01_list_all_permissions.sql` - Berechtigungen auflisten
- `02_assign_all_permissions_to_superuser.sql` - Basis-Setup
- `03_cleanup_old_system_roles.sql` - System bereinigen
- `COMPLETE_SETUP_WITH_ROLES.sql` - Vollständiges Setup

## ⚠️ WICHTIGE SYSTEM-FACTS

### Authentication
- **Superuser**: `staffLevel = 1` (enum superUser) 
- **Login**: Email + Passwort über `serverpod_email_auth`
- **Password**: BCrypt Hash für "super123"
- **UserID-Kette**: `staff_users.userInfoId → serverpod_user_info.id → serverpod_email_auth.userId`

### Rollen-System  
- **Normale User**: `staffLevel = 0` + Rollen aus `roles` Tabelle
- **Superuser**: `staffLevel = 1` (brauchen KEINE Rollen)
- **Rollen-Zuweisungen**: `staff_user_roles` Tabelle
- **UI**: Checkbox für Superuser, Dropdown für normale Rollen

### Bekannte Fixes
- ✅ BCrypt Hash für "super123" korrekt gesetzt
- ✅ Verwirrende "Super Administrator" Rolle deaktiviert (ID 27)
- ✅ Authentication funktioniert über echtes Backend
- ✅ UI zeigt keine Duplikat-Superuser-Optionen mehr

## 🔄 Workflow bei Problemen

1. **Diagnose**: `CURRENT_SYSTEM_STATUS.sql` ausführen
2. **Problem identifizieren**: Welcher Bereich ist betroffen?
3. **Reparatur**: Entsprechenden Fix aus `EMERGENCY_REPAIRS.sql` verwenden
4. **Verifikation**: `CURRENT_SYSTEM_STATUS.sql` erneut ausführen

## 📋 Tabellen-Struktur (Referenz)

```sql
-- Staff Users
staff_users.staffLevel: 0=staff, 1=superUser (enum)
staff_users.userInfoId → serverpod_user_info.id

-- Authentication  
serverpod_email_auth.userId = serverpod_user_info.id
serverpod_email_auth.hash = BCrypt Hash

-- Rollen-System
roles (id, name, displayName, isActive)
staff_user_roles (staffUserId, roleId, isActive)
```

## 🗄️ Database Connection

**Remote Hetzner Database:**
- **Host**: `159.69.144.208:5432`
- **Database**: `vertic`
- **User**: `vertic_dev`
- **Password**: `GreifbarB2019`

## 🎯 Superuser Login

| Feld | Wert |
|------|------|
| **Username** | `superuser` |
| **Password** | `super123` |
| **Email** | `superuser@staff.vertic.local` |

---
**Alle veralteten SQL-Scripte wurden entfernt. Verwende nur die oben aufgelisteten aktuellen Scripte.**