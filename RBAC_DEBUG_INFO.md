# 🔍 RBAC System Debug-Guide

## Problem-Diagnose

Du hast berichtet, dass die Rollenerstellung sichtbar ist, aber die Permission-Zuweisung nicht funktioniert. Hier ist eine systematische Überprüfung:

## 🔧 Sofort-Lösung

**1. SQL-Script ausführen:**
```sql
-- Führe aus: debug_and_fix_rbac_system.sql
```

**2. Server neustarten:**
```bash
cd vertic_server_server
dart run bin/main.dart
```

**3. Frontend-Test:**
- Gehe zu Admin → RBAC Management → Rollen-Tab
- Klicke "Neue Rolle" 
- Erstelle eine Test-Rolle (z.B. "Kassierer")
- Klicke auf das Schlüssel-Icon (🔐) neben der Rolle
- Du solltest die Permission-Verwaltung sehen

## 🐛 Debug-Schritte

### Backend-Check:
1. **Permissions vorhanden?**
   - Prüfe ob `can_manage_roles` in der `permissions` Tabelle existiert
   - Alle RBAC-Permissions sollten da sein

2. **Superuser korrekt?**
   - `staff_users` Tabelle: `staffLevel = 1` für Superuser
   - Email: `superuser@staff.vertic.local`

3. **Server-Logs prüfen:**
   ```
   🔍 DEBUG: staffUser.staffLevel = 1
   👑 SUPERUSER: Automatisch alle Permissions gewährt
   ```

### Frontend-Check:
1. **Permission-Provider geladen?**
   - Debug-Output: `isInitialized: true`
   - Debug-Output: `permissions count: 50+`

2. **RBAC-Tab sichtbar?**
   - Rollen-Tab sollte verfügbar sein
   - "Neue Rolle" Button sichtbar

3. **Role-Permission-Manager:**
   - Beim Klick auf 🔐-Icon sollte sich ein Dialog öffnen
   - Permissions als Checkboxen sichtbar

## ⚡ Quick-Fix

Falls immer noch nicht funktioniert, führe in pgAdmin aus:

```sql
-- Stelle sicher dass Superuser alle Permissions hat (Fallback)
UPDATE staff_users 
SET "staffLevel" = 1 
WHERE email = 'superuser@staff.vertic.local';

-- Prüfe ob kritische Permission existiert
SELECT * FROM permissions WHERE name = 'can_manage_roles';

-- Falls nicht vorhanden, manuell hinzufügen:
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") 
VALUES ('can_manage_roles', 'Rollen verwalten', 'Kann Rollen erstellen, bearbeiten und zuweisen', 'rbac_management', true, NOW())
ON CONFLICT (name) DO NOTHING;
```

## 📋 Erwartetes Verhalten nach Fix

1. **Login als Superuser** funktioniert ✅
2. **RBAC Management Menu** ist sichtbar ✅
3. **"Neue Rolle" Button** ist klickbar ✅
4. **Rolle erstellen** funktioniert ✅
5. **🔐 Permission-Icon** öffnet Permission-Manager ✅
6. **Permissions zuweisen** funktioniert ✅
7. **Staff-User erstellen** mit Rollenauswahl ✅

## 🚀 Test-Workflow

1. Erstelle Rolle "Test Kassierer"
2. Weise Permissions zu: `can_view_users`, `can_create_tickets`
3. Erstelle Staff-User und weise ihm diese Rolle zu
4. Teste dass der Staff-User nur diese Permissions hat

Das System sollte dann vollständig funktionieren! 🎉