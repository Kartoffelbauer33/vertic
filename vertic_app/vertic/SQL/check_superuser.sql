-- =====================================================
-- SUPERUSER PERMISSION CHECK & REPAIR
-- Prüft und repariert Superuser Permissions
-- ✅ PRODUCTION-READY VERIFICATION SCRIPT
-- =====================================================

-- 1. Zeige aktuelle Situation
SELECT 
    'CURRENT STATUS' as info,
    (SELECT COUNT(*) FROM permissions) as total_permissions,
    (SELECT COUNT(*) FROM staff_user_permissions sup 
     JOIN staff_users su ON sup."staffUserId" = su.id 
     WHERE su."employeeId" = 'superuser') as superuser_permissions,
    (SELECT "staffLevel" FROM staff_users WHERE "employeeId" = 'superuser') as staff_level,
    (SELECT "userInfoId" FROM staff_users WHERE "employeeId" = 'superuser') as user_info_id;

-- 2. Prüfe kritische Verknüpfungen
SELECT 
    'CRITICAL LINKS CHECK' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM staff_users su
            JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
            WHERE su."employeeId" = 'superuser'
        ) THEN '✅ userInfoId korrekt verknüpft'
        ELSE '❌ userInfoId Verknüpfung FEHLT'
    END as userinfo_link,
    CASE 
        WHEN (SELECT "staffLevel" FROM staff_users WHERE "employeeId" = 'superuser') IN (0,1,2,3) 
        THEN '✅ staffLevel gültig (' || (SELECT "staffLevel" FROM staff_users WHERE "employeeId" = 'superuser') || ')'
        ELSE '❌ staffLevel ungültig (' || (SELECT "staffLevel" FROM staff_users WHERE "employeeId" = 'superuser') || ')'
    END as staff_level_check;

-- 3. Weise ALLE fehlenden Permissions dem Superuser zu
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

-- 4. Zeige finales Ergebnis
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

-- 5. Detaillierte Verifikation
SELECT 
    'DETAILED VERIFICATION' as info,
    su."employeeId" as username,
    su."staffLevel" as staff_level,
    su."userInfoId" as user_info_id,
    ui.id as serverpod_id,
    ui."userIdentifier",
    COUNT(sup.id) as direct_permissions,
    COUNT(sur.id) as roles_assigned
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
LEFT JOIN staff_user_permissions sup ON su.id = sup."staffUserId" AND sup."isActive" = true
LEFT JOIN staff_user_roles sur ON su.id = sur."staffUserId" AND sur."isActive" = true
WHERE su."employeeId" = 'superuser'
GROUP BY su."employeeId", su."staffLevel", su."userInfoId", ui.id, ui."userIdentifier"; 