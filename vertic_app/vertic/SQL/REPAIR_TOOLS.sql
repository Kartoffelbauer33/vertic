-- =====================================================
-- VERTIC REPAIR TOOLS - TROUBLESHOOTING
-- Repariert häufige Probleme mit dem Auth-System
-- =====================================================

-- ========================================
-- 🔧 TOOL 1: PERMISSION-CHECK & REPARATUR
-- ========================================

-- Zeige aktuelle Situation
SELECT 
    'CURRENT STATUS' as info,
    (SELECT COUNT(*) FROM permissions) as total_permissions,
    (SELECT COUNT(*) FROM staff_user_permissions sup 
     JOIN staff_users su ON sup."staffUserId" = su.id 
     WHERE su."employeeId" = 'superuser') as superuser_permissions,
    (SELECT "staffLevel" FROM staff_users WHERE "employeeId" = 'superuser') as staff_level,
    (SELECT "userInfoId" FROM staff_users WHERE "employeeId" = 'superuser') as user_info_id;

-- Weise ALLE fehlenden Permissions dem Superuser zu
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

-- ========================================
-- 🔧 TOOL 2: STAFF-LEVEL REPARATUR
-- ========================================

-- Finde ungültige staffLevel Werte
SELECT 
    '❌ INVALID STAFF LEVELS' as info,
    id, email, "employeeId", "staffLevel",
    CASE 
        WHEN "staffLevel" = 99 THEN 'Legacy superUser (99) → sollte 3 sein'
        WHEN "staffLevel" IS NULL THEN 'NULL Wert → sollte 0 (staff) sein'
        ELSE 'Unbekannter Wert → sollte 0-3 sein'
    END as problem_description
FROM staff_users 
WHERE "staffLevel" NOT IN (0, 1, 2, 3);

-- Repariere ungültige staffLevel Werte
UPDATE staff_users SET "staffLevel" = 3 WHERE "staffLevel" = 99;
UPDATE staff_users SET "staffLevel" = 0 WHERE "staffLevel" IS NULL;
UPDATE staff_users SET "staffLevel" = 0 WHERE "staffLevel" NOT IN (0, 1, 2, 3);

-- ========================================
-- 🔧 TOOL 3: USERINFO-VERKNÜPFUNG REPARATUR
-- ========================================

-- Zeige Verknüpfungsprobleme
SELECT 
    '❌ STAFF USERS WITHOUT USERINFO LINK' as info,
    su.id as staff_id,
    su.email as staff_email,
    su."employeeId",
    su."userInfoId",
    ui.id as matching_serverpod_id,
    CASE 
        WHEN ui.id IS NOT NULL THEN '✅ Match gefunden - kann verknüpft werden'
        ELSE '❌ Kein Serverpod User mit dieser Email'
    END as repair_status
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su.email = ui.email
WHERE su."userInfoId" IS NULL;

-- Repariere Verknüpfungen basierend auf Email-Matching
UPDATE staff_users 
SET "userInfoId" = (
    SELECT ui.id 
    FROM serverpod_user_info ui 
    WHERE ui.email = staff_users.email
)
WHERE "userInfoId" IS NULL 
AND EXISTS (
    SELECT 1 FROM serverpod_user_info ui 
    WHERE ui.email = staff_users.email
);

-- ========================================
-- 🔧 TOOL 4: SUPERUSER KOMPLETT-CHECK
-- ========================================

-- Prüfe kritische Verknüpfungen
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

-- ========================================
-- 🔧 TOOL 5: AUTH-SYSTEM VERIFIKATION  
-- ========================================

-- Zeige Serverpod Auth Status
SELECT 
    '🔐 AUTH VERIFICATION' as info,
    ui."userIdentifier",
    ui.email,
    ui."userName",
    ui."scopeNames",
    ui.blocked,
    CASE 
        WHEN ea.hash IS NOT NULL AND ea.hash LIKE '$2a$10$%' THEN '✅ Gültiger bcrypt Hash' 
        WHEN ea.hash IS NOT NULL THEN '⚠️ Hash vorhanden aber Format unbekannt'
        ELSE '❌ FEHLER: Kein Password Hash' 
    END as password_status
FROM serverpod_user_info ui
LEFT JOIN serverpod_email_auth ea ON ui.id = ea."userId"
WHERE ui."userIdentifier" = 'superuser@staff.vertic.local';

-- ========================================
-- ✅ FINAL REPAIR VERIFICATION
-- ========================================

-- Finaler Status nach Reparatur
SELECT 
    '🎉 REPAIR COMPLETED' as info,
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
    END as permission_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM staff_users su
            JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
            WHERE su."employeeId" = 'superuser'
        ) THEN '✅ UserInfo korrekt verknüpft'
        ELSE '❌ UserInfo Verknüpfung FEHLT'
    END as link_status;

-- =====================================================
-- 🛠️ VERWENDUNG:
-- 
-- Führe dieses Script aus wenn:
-- - Login fehlschlägt ("Benutzer nicht gefunden")
-- - Permissions fehlen (0 Permissions geladen)  
-- - "Staff-User nicht aktiv" Fehler
-- - "Invalid StaffUserType" Fehler
-- 
-- Nach dem Script sollte der Superuser-Login funktionieren!
-- ===================================================== 