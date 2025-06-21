-- =====================================================
-- VERTIC SUPERUSER CREATION SCRIPT
-- Database: test_db
-- 👑 MASTER ADMIN ACCOUNT ERSTELLEN
-- =====================================================
-- Username: superuser
-- Password: super123
-- Scope: staff (für Staff App Zugang)
-- =====================================================

-- ========================================
-- 1. 🧹 BEREINIGUNG (falls Superuser existiert)
-- ========================================

-- Lösche alle existierenden Superuser-Einträge
DELETE FROM staff_user_permissions WHERE "staffUserId" IN (SELECT id FROM staff_users WHERE "employeeId" = 'superuser');
DELETE FROM staff_user_roles WHERE "staffUserId" IN (SELECT id FROM staff_users WHERE "employeeId" = 'superuser');
DELETE FROM staff_users WHERE "employeeId" = 'superuser';
DELETE FROM serverpod_email_auth WHERE email = 'superuser@staff.vertic.local';
DELETE FROM serverpod_user_info WHERE "userIdentifier" = 'superuser@staff.vertic.local';

-- ========================================
-- 2. 🔐 SERVERPOD UNIFIED AUTH ERSTELLEN
-- ========================================

-- Erstelle UserInfo im Serverpod Auth-System
INSERT INTO serverpod_user_info (
    "userIdentifier",
    email,
    "userName", 
    "fullName",
    created,
    blocked,
    "scopeNames"
) VALUES (
    'superuser@staff.vertic.local',
    'superuser@staff.vertic.local',
    'superuser',
    'Super Administrator',
    NOW(),
    false,
    '["staff"]'::json  -- WICHTIG: Staff Scope für Staff App
);

-- Erstelle EmailAuth mit ECHTEM bcrypt Hash für 'super123'
-- Hash wurde mit Dart generiert und getestet: BCrypt.checkpw("super123", hash) = true
INSERT INTO serverpod_email_auth (
    "userId",
    email,
    hash
) VALUES (
    (SELECT id FROM serverpod_user_info WHERE "userIdentifier" = 'superuser@staff.vertic.local'),
    'superuser@staff.vertic.local',
    '$2a$10$KNcGVTK1kwpwJhfwtaat5u1uOOOUJzIa51blIw2JcQ0K1tjrRTw62'  -- ECHTER GETESTETER HASH!
);

-- ========================================
-- 3. 👤 STAFF USER ERSTELLEN
-- ========================================

-- Erstelle StaffUser-Eintrag mit korrekter Verknüpfung
INSERT INTO staff_users (
    "userInfoId",
    "firstName",
    "lastName", 
    email,
    "employeeId",
    "staffLevel",
    "employmentStatus",
    "createdAt"
) VALUES (
    (SELECT id FROM serverpod_user_info WHERE "userIdentifier" = 'superuser@staff.vertic.local'),
    'Super',
    'Administrator',
    'superuser@staff.vertic.local',  -- WICHTIG: @staff.vertic.local für Staff App
    'superuser',
    3,  -- Höchstes Staff Level
    'active',
    NOW()
);

-- ========================================
-- 4. 🔗 SUPER ADMIN ROLLE ZUWEISEN
-- ========================================

-- Weise dem Superuser die Super Admin Rolle zu (falls vorhanden)
INSERT INTO staff_user_roles ("staffUserId", "roleId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM staff_users WHERE "employeeId" = 'superuser'),
    (SELECT id FROM roles WHERE name = 'Super Admin'),
    NOW(),
    (SELECT id FROM staff_users WHERE "employeeId" = 'superuser')
WHERE EXISTS (SELECT 1 FROM roles WHERE name = 'Super Admin');

-- ========================================
-- 5. 🔐 ALLE PERMISSIONS DIREKT ZUWEISEN (FALLBACK)
-- ========================================

-- Falls RBAC-System noch nicht initialisiert: Weise ALLE Permissions direkt zu
INSERT INTO staff_user_permissions ("staffUserId", "permissionId", "grantedAt", "grantedBy")
SELECT 
    (SELECT id FROM staff_users WHERE "employeeId" = 'superuser'),
    p.id,
    NOW(),
    (SELECT id FROM staff_users WHERE "employeeId" = 'superuser')
FROM permissions p
WHERE NOT EXISTS (
    SELECT 1 FROM staff_user_permissions sup 
    WHERE sup."staffUserId" = (SELECT id FROM staff_users WHERE "employeeId" = 'superuser')
    AND sup."permissionId" = p.id
);

-- ========================================
-- 6. ✅ VERIFIKATION - Vollständige Prüfung
-- ========================================

-- Zeige den erstellten Superuser mit allen Details
SELECT 
    '🎯 SUPERUSER VERIFICATION' as status,
    su.id as staff_id,
    su."employeeId" as username,
    su."firstName",
    su."lastName", 
    su."staffLevel",
    su."employmentStatus",
    su."userInfoId",
    ui."userIdentifier",
    ui."scopeNames",
    ui.blocked as is_blocked,
    ea.email as auth_email,
    CASE 
        WHEN ea.hash IS NOT NULL THEN '✅ Password Hash vorhanden' 
        ELSE '❌ FEHLER: Kein Password Hash' 
    END as password_status
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
LEFT JOIN serverpod_email_auth ea ON ui.id = ea."userId"
WHERE su."employeeId" = 'superuser';

-- Zeige zugewiesene Permissions (direkt und über Rollen)
SELECT 
    '🔐 SUPERUSER PERMISSIONS' as info,
    su."employeeId" as username,
    COUNT(DISTINCT p.id) as total_permissions,
    COUNT(DISTINCT sup.id) as direct_permissions,
    COUNT(DISTINCT rp.id) as role_permissions
FROM staff_users su
LEFT JOIN staff_user_permissions sup ON su.id = sup."staffUserId"
LEFT JOIN staff_user_roles sur ON su.id = sur."staffUserId"
LEFT JOIN role_permissions rp ON sur."roleId" = rp."roleId"
LEFT JOIN permissions p ON (sup."permissionId" = p.id OR rp."permissionId" = p.id)
WHERE su."employeeId" = 'superuser'
GROUP BY su."employeeId";

-- Final Status Check
SELECT 
    '🎉 SETUP STATUS' as final_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM staff_users WHERE "employeeId" = 'superuser') THEN '✅ Staff User erstellt'
        ELSE '❌ Staff User FEHLT'
    END as staff_user_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM staff_users su
            JOIN serverpod_email_auth ea ON su."userInfoId" = ea."userId"
            WHERE su."employeeId" = 'superuser' AND ea.hash LIKE '$2a$10$%'
        ) THEN '✅ Echter bcrypt Hash gesetzt'
        ELSE '❌ Hash FEHLT oder ungültig'
    END as auth_status,
    (
        SELECT COUNT(*) FROM staff_user_permissions sup
        JOIN staff_users su ON sup."staffUserId" = su.id
        WHERE su."employeeId" = 'superuser'
    ) as direct_permission_count;

-- =====================================================
-- 🎉 SUPERUSER ERFOLGREICH ERSTELLT!
-- 
-- 📋 LOGIN CREDENTIALS:
--    Username: superuser
--    Password: super123
--    App: Vertic Staff App
--    Hash: Echter bcrypt (getestet!)
--
-- 🔧 NEXT STEPS:
--    1. Falls Permissions = 0: Führe 01_CLEAN_SETUP.sql zuerst aus
--    2. Teste Login in Staff App
--    3. Prüfe Admin Dashboard Zugang
-- ===================================================== 