-- =====================================================
-- SQL-Skript: Alle Permissions an Superuser zuweisen
-- Zweck: Sicherstellen, dass der Superuser ALLE Permissions hat
-- Datum: 2025-01-23
-- =====================================================

-- WICHTIG: Dieses Skript sollte nur ausgeführt werden, wenn:
-- 1. Der Superuser existiert (name = 'super_admin')
-- 2. Permissions existieren
-- 3. Backup der Datenbank erstellt wurde

-- 1. Prüfung: Superuser-Rolle existiert oder erstellen
DO $$
BEGIN
    -- Prüfe ob Superuser-Rolle existiert, falls nicht erstelle sie
    IF NOT EXISTS (SELECT 1 FROM roles WHERE name = 'super_admin') THEN
        INSERT INTO roles (name, "displayName", description, "isSystemRole", "isActive", "sortOrder", "createdAt", "createdBy")
        VALUES ('super_admin', 'Super Administrator', 'Vollzugriff auf alle Systemfunktionen. Kann alle Berechtigungen verwalten und kritische Systemeinstellungen ändern.', true, true, 0, NOW(), 1);
        
        RAISE NOTICE 'Superuser-Rolle erstellt.';
    ELSE
        RAISE NOTICE 'OK: Superuser-Rolle bereits vorhanden.';
    END IF;
END $$;

-- 2. Prüfung: Permissions existieren?
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM permissions) = 0 THEN
        RAISE EXCEPTION 'FEHLER: Keine Permissions gefunden! Bitte zuerst Permission-Seeding ausführen.';
    END IF;
    
    RAISE NOTICE 'OK: % Permissions gefunden.', (SELECT COUNT(*) FROM permissions);
END $$;

-- 3. Backup der aktuellen Superuser-Permissions (für Rollback)
CREATE TEMP TABLE superuser_permissions_backup AS
SELECT rp.* 
FROM role_permissions rp
JOIN roles r ON rp."roleId" = r.id
WHERE r.name = 'super_admin';

-- 4. Hauptoperation: Alle fehlenden Permissions zuweisen
-- Verwende Staff-User ID 1 (Superuser) als assignedBy
INSERT INTO role_permissions ("roleId", "permissionId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM roles WHERE name = 'super_admin') as "roleId",
    p.id as "permissionId",
    NOW() as "assignedAt",
    1 as "assignedBy"  -- Staff-User ID 1 (Superuser)
FROM permissions p
WHERE NOT EXISTS (
    SELECT 1 
    FROM role_permissions rp 
    WHERE rp."roleId" = (SELECT id FROM roles WHERE name = 'super_admin')
    AND rp."permissionId" = p.id
);

-- 5. Erfolgsmeldung und Statistik
DO $$
DECLARE
    total_permissions INTEGER;
    superuser_permissions INTEGER;
    newly_assigned INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_permissions FROM permissions;
    
    SELECT COUNT(*) INTO superuser_permissions 
    FROM role_permissions rp
    JOIN roles r ON rp."roleId" = r.id
    WHERE r.name = 'super_admin';
    
    newly_assigned := superuser_permissions - (SELECT COUNT(*) FROM superuser_permissions_backup);
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'SUPERUSER PERMISSIONS UPDATE ABGESCHLOSSEN';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Gesamt Permissions im System: %', total_permissions;
    RAISE NOTICE 'Superuser Permissions vorher: %', (SELECT COUNT(*) FROM superuser_permissions_backup);
    RAISE NOTICE 'Superuser Permissions nachher: %', superuser_permissions;
    RAISE NOTICE 'Neu zugewiesene Permissions: %', newly_assigned;
    RAISE NOTICE '========================================';
    
    IF superuser_permissions = total_permissions THEN
        RAISE NOTICE '✅ ERFOLG: Superuser hat jetzt ALLE Permissions!';
    ELSE
        RAISE WARNING '⚠️  WARNUNG: Superuser hat nicht alle Permissions (%/%).', superuser_permissions, total_permissions;
    END IF;
END $$;

-- 6. Verifikation: Fehlende Permissions anzeigen (sollte leer sein)
SELECT 
    p.name as missing_permission,
    p."displayName",
    p.category
FROM permissions p
WHERE NOT EXISTS (
    SELECT 1 
    FROM role_permissions rp 
    WHERE rp."roleId" = (SELECT id FROM roles WHERE name = 'super_admin')
    AND rp."permissionId" = p.id
)
ORDER BY p.category, p.name;
