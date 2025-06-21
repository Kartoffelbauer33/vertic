-- SUPERUSER PERMISSION CHECK & REPAIR
-- Prüfe und repariere Superuser Permissions

-- 1. Zeige aktuelle Situation
SELECT 
    'CURRENT STATUS' as info,
    (SELECT COUNT(*) FROM permissions) as total_permissions,
    (SELECT COUNT(*) FROM staff_user_permissions sup 
     JOIN staff_users su ON sup."staffUserId" = su.id 
     WHERE su."employeeId" = 'superuser') as superuser_permissions;

-- 2. Weise ALLE fehlenden Permissions dem Superuser zu
INSERT INTO staff_user_permissions ("staffUserId", "permissionId", "grantedAt", "grantedBy", "isActive")
SELECT 
    (SELECT id FROM staff_users WHERE "employeeId" = 'superuser'),
    p.id,
    NOW(),
    (SELECT id FROM staff_users WHERE "employeeId" = 'superuser'),
    true
FROM permissions p
WHERE NOT EXISTS (
    SELECT 1 FROM staff_user_permissions sup 
    WHERE sup."staffUserId" = (SELECT id FROM staff_users WHERE "employeeId" = 'superuser')
    AND sup."permissionId" = p.id
);

-- 3. Zeige finales Ergebnis
SELECT 
    'FINAL STATUS' as info,
    (SELECT COUNT(*) FROM permissions) as total_permissions,
    (SELECT COUNT(*) FROM staff_user_permissions sup 
     JOIN staff_users su ON sup."staffUserId" = su.id 
     WHERE su."employeeId" = 'superuser' AND sup."isActive" = true) as superuser_permissions,
    CASE 
        WHEN (SELECT COUNT(*) FROM permissions) = 
             (SELECT COUNT(*) FROM staff_user_permissions sup 
              JOIN staff_users su ON sup."staffUserId" = su.id 
              WHERE su."employeeId" = 'superuser' AND sup."isActive" = true)
        THEN '✅ SUPERUSER HAT ALLE PERMISSIONS'
        ELSE '❌ FEHLER: Permissions fehlen'
    END as status; 