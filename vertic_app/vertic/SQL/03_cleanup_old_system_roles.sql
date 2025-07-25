-- =====================================================
-- SQL-Skript: Alte System-Rollen bereinigen
-- Zweck: Nur Superuser als System-Rolle behalten, alle anderen entfernen
-- Datum: 2025-01-23
-- =====================================================

-- WICHTIG: Dieses Skript sollte nur ausgeführt werden, wenn:
-- 1. Backup der Datenbank erstellt wurde
-- 2. Superuser-Rolle existiert und korrekt konfiguriert ist
-- 3. Keine aktiven Staff-User mit den zu löschenden Rollen verbunden sind

-- 1. Prüfung: Welche System-Rollen existieren aktuell?
SELECT 
    id,
    name,
    "displayName",
    "isSystemRole",
    "createdAt"
FROM roles 
WHERE "isSystemRole" = true
ORDER BY name;

-- 2. Prüfung: Superuser-Rolle existiert?
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM roles WHERE name = 'super_admin' AND "isSystemRole" = true) THEN
        RAISE EXCEPTION 'FEHLER: Superuser-Rolle (super_admin) nicht gefunden oder nicht als System-Rolle markiert!';
    END IF;
    
    RAISE NOTICE 'OK: Superuser-Rolle gefunden und korrekt konfiguriert.';
END $$;

-- 3. Backup der zu löschenden System-Rollen (für Rollback)
CREATE TEMP TABLE old_system_roles_backup AS
SELECT * FROM roles 
WHERE "isSystemRole" = true 
AND name != 'super_admin';

-- 4. Warnung: Zeige Staff-User, die betroffen sein könnten
SELECT 
    r.name as role_name,
    r."displayName",
    COUNT(sur."staffUserId") as affected_staff_users
FROM roles r
LEFT JOIN staff_user_roles sur ON r.id = sur."roleId"
WHERE r."isSystemRole" = true 
AND r.name != 'super_admin'
GROUP BY r.id, r.name, r."displayName"
HAVING COUNT(sur."staffUserId") > 0;

-- 5. Hauptoperation: Alte System-Rollen entfernen
-- 5a. Zuerst Role-Permission-Zuweisungen entfernen
DELETE FROM role_permissions 
WHERE "roleId" IN (
    SELECT id FROM roles 
    WHERE "isSystemRole" = true 
    AND name != 'super_admin'
);

-- 5b. Staff-User-Role-Zuweisungen entfernen
DELETE FROM staff_user_roles 
WHERE "roleId" IN (
    SELECT id FROM roles 
    WHERE "isSystemRole" = true 
    AND name != 'super_admin'
);

-- 5c. Die Rollen selbst löschen
DELETE FROM roles 
WHERE "isSystemRole" = true 
AND name != 'super_admin';

-- 6. Erfolgsmeldung und Statistik
DO $$
DECLARE
    remaining_system_roles INTEGER;
    deleted_roles INTEGER;
BEGIN
    SELECT COUNT(*) INTO remaining_system_roles 
    FROM roles 
    WHERE "isSystemRole" = true;
    
    deleted_roles := (SELECT COUNT(*) FROM old_system_roles_backup);
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'SYSTEM-ROLLEN BEREINIGUNG ABGESCHLOSSEN';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Gelöschte System-Rollen: %', deleted_roles;
    RAISE NOTICE 'Verbleibende System-Rollen: %', remaining_system_roles;
    RAISE NOTICE '========================================';
    
    IF remaining_system_roles = 1 THEN
        RAISE NOTICE '✅ ERFOLG: Nur noch Superuser als System-Rolle vorhanden!';
    ELSE
        RAISE WARNING '⚠️  WARNUNG: % System-Rollen gefunden (erwartet: 1).', remaining_system_roles;
    END IF;
END $$;

-- 7. Verifikation: Aktuelle System-Rollen anzeigen (sollte nur super_admin sein)
SELECT 
    id,
    name,
    "displayName",
    "isSystemRole",
    "createdAt"
FROM roles 
WHERE "isSystemRole" = true
ORDER BY name;

-- 8. Verifikation: Gelöschte Rollen anzeigen
SELECT 
    'GELÖSCHT' as status,
    name,
    "displayName",
    "createdAt"
FROM old_system_roles_backup
ORDER BY name;
