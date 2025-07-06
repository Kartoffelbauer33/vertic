# 🗄️ VERTIC DATABASE SETUP - EINFACH & KLAR

**Komplettes SQL-Setup für die Vertic Datenbank in nur wenigen Schritten**

---

## 🚀 SCHNELLSTART (für Eilige)

```bash
1. PostgreSQL starten
2. DBeaver/pgAdmin öffnen → test_db verbinden
3. Script ausführen: 01_CLEAN_SETUP_FINAL_CORRECTED.sql
4. Staff App starten → Login: superuser / super123
5. FERTIG! ✅
```

---

## 📁 DATEIEN-ÜBERSICHT

| Datei | Zweck | Wann verwenden? |
|-------|-------|----------------|
| `01_CLEAN_SETUP_FINAL_CORRECTED.sql` | 🎯 **HAUPT-SETUP** | **IMMER ZUERST** - Erstellt alles |
| `REPAIR_TOOLS.sql` | 🛠️ **REPARATUR** | Nur bei Login-Problemen |
| `ADD_EXTERNAL_PROVIDER_PERMISSIONS.sql` | 🔗 **FREMDANBIETER** | Nur für Fitpass/Friction Integration |
| `UPDATE_SUPERUSER_EMAIL_VERIFICATION.sql` | 📧 **EMAIL-UPDATE** | Nur für Email-Verification System |

**Das war's! Nur 4 Dateien - keine Verwirrung mehr.** 🎉

---

## 🎯 KOMPLETTE SETUP-ANLEITUNG

### ⚡ SCHRITT 1: Datenbank vorbereiten

1. **PostgreSQL starten** (lokaler Server)
2. **DBeaver oder pgAdmin öffnen**
3. **Mit `test_db` verbinden**

### ⚡ SCHRITT 2: Haupt-Setup ausführen

```sql
-- Datei: 01_CLEAN_SETUP_FINAL_CORRECTED.sql
-- Diese Datei macht ALLES:
-- ✅ Löscht alte Daten
-- ✅ Erstellt RBAC-System (60+ Permissions, 6 Rollen)
-- ✅ Erstellt Superuser mit vollem Zugriff
-- ✅ Zeigt Verifikation an

-- Einfach das ganze Script in DBeaver/pgAdmin einfügen und ausführen!
```

### ⚡ SCHRITT 3: Anmelden

**Starte die Vertic Staff App und melde dich an:**

| Feld | Wert |
|------|------|
| **Username** | `superuser` |
| **Password** | `super123` |
| **Email** | `superuser@staff.vertic.local` |

### ✅ ERFOLGREICH!

Nach dem Login solltest du sehen:
- ✅ Admin-Dashboard ist sichtbar
- ✅ Alle Permissions sind geladen (60+)
- ✅ Vollzugriff auf alle Features

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

### ❌ Problem: "Staff-User nicht aktiv"

**Lösung:** Führe das Reparatur-Script aus:

```sql
-- Datei: REPAIR_TOOLS.sql
-- Repariert userInfoId Verknüpfungen
```

### ❌ Problem: "Invalid StaffUserType"

**Lösung:** Führe das Reparatur-Script aus:

```sql
-- Datei: REPAIR_TOOLS.sql
-- Korrigiert ungültige staffLevel Werte
```

**Nach dem Reparatur-Script sollte der Login funktionieren!**

---

## 🔧 ERWEITERTE FEATURES

### 🔗 Fremdanbieter-Integration (Fitpass, Friction)

```sql
-- NUR ausführen wenn du Fitpass/Friction integrieren willst:
ADD_EXTERNAL_PROVIDER_PERMISSIONS.sql
```

### 📧 Email-Verification System

```sql
-- NUR ausführen wenn du Email-Bestätigung aktivieren willst:
UPDATE_SUPERUSER_EMAIL_VERIFICATION.sql
```

---

## 📊 WAS WIRD ERSTELLT?

### 🔐 RBAC-System
- **60+ Permissions** in 9 Kategorien:
  - User Management (14)
  - Staff Management (7)
  - Ticket Management (10)
  - Product Management (8) - *Für POS Artikel-Verwaltung*
  - System Settings (4)
  - RBAC Management (3)
  - Facility Management (4)
  - Reporting & Analytics (4)
  - Status/Gym Management (8)

### 👥 Rollen-System
- **Super Admin** - Vollzugriff (alle 60+ Permissions)
- **Facility Admin** - Standort-Verwaltung
- **Artikel Manager** - POS Artikel-Verwaltung + Barcode-Scanning
- **Kassierer** - Ticketverkauf + Kasse
- **Support Staff** - Kundenbetreuung
- **Readonly User** - Nur-Lese-Zugriff

### 👤 Superuser-Account
- **Username:** `superuser`
- **Password:** `super123` ⚠️ *Bitte nach dem ersten Login ändern!*
- **Rolle:** Super Admin (alle Permissions)
- **Unified Auth:** Funktioniert mit Serverpod Authentication

---

## 🔒 SICHERHEITS-HINWEISE

### ⚠️ NACH DEM ERSTEN LOGIN:

1. **Password ändern** (über Staff App)
2. **Zusätzliche Admin-Accounts erstellen**
3. **Superuser-Account deaktivieren** (optional)

### 🏭 PRODUCTION DEPLOYMENT:

```sql
-- 1. Backup der Permissions erstellen
SELECT * FROM permissions;

-- 2. Neue sichere Passwords setzen
UPDATE serverpod_email_auth 
SET hash = '$2a$10$NEUER_SICHERER_HASH'
WHERE email = 'superuser@staff.vertic.local';

-- 3. Eigene Admin-Accounts erstellen (über Staff App)
```

---

## 🎓 TECHNISCHE DETAILS

### 🔑 Enum-Werte (WICHTIG!)
```sql
-- StaffUserType Enum:
0 = staff
1 = hallAdmin
2 = facilityAdmin  
3 = superUser

-- ❌ Alle anderen Werte sind UNGÜLTIG!
```

### 🔗 Kritische Verknüpfungen
```sql
-- Diese Verknüpfungen MÜSSEN stimmen:
staff_users.userInfoId = serverpod_user_info.id
staff_users.email = serverpod_user_info.email
serverpod_user_info.scopeNames = '["staff"]'
```

### 🧹 Bei kompletten Problemen
```sql
-- Kompletter Neustart:
1. 01_CLEAN_SETUP_FINAL_CORRECTED.sql ausführen
2. Staff App neustarten
3. Frisch anmelden
```

---

## ❓ HÄUFIGE FRAGEN

**Q: Muss ich mehrere Scripts ausführen?**
A: Nein! Nur `01_CLEAN_SETUP_FINAL_CORRECTED.sql` - das macht alles.

**Q: Was wenn der Login nicht funktioniert?**
A: `REPAIR_TOOLS.sql` ausführen - das repariert 99% aller Probleme.

**Q: Kann ich das Script mehrfach ausführen?**
A: Ja! Es löscht zuerst alle alten Daten und erstellt alles neu.

**Q: Wo finde ich weitere Admin-Funktionen?**
A: Nach dem Login → Admin-Tab → Vollzugriff auf User-Management, etc.

**Q: Wie erstelle ich neue Staff-Accounts?**
A: Nach Superuser-Login → Admin-Dashboard → Staff-Management

---

## 🎉 FERTIG!

**Das Setup ist jetzt kinderleicht:**
1. Ein Script ausführen
2. Anmelden
3. Arbeiten

**Bei Problemen:** Reparatur-Script ausführen und es läuft wieder.

**Viel Erfolg mit deinem Vertic System!** 🚀 