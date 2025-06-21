-- =====================================================
-- VERTIC SUPERUSER CREATION SCRIPT - FINAL CORRECTED
-- Database: test_db
-- 👑 MASTER ADMIN ACCOUNT ERSTELLEN
-- ✅ BASIERT AUF TATSÄCHLICHEN TABELLENSTRUKTUREN
-- ✅ KORRIGIERTE STAFF-LEVEL & USERINFO-VERKNÜPFUNG
-- =====================================================
-- Username: superuser
-- Password: super123
-- Email: superuser@staff.vertic.local
-- =====================================================

-- ========================================
-- 1. 🧹 BEREINIGUNG (falls Superuser existiert)
-- ========================================

-- Lösche alle existierenden Superuser-Einträge
DELETE FROM staff_user_permissions WHERE "staffUserId" IN (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local');
DELETE FROM staff_user_roles WHERE "staffUserId" IN (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local');
DELETE FROM staff_users WHERE email = 'superuser@staff.vertic.local';
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
-- 3. 👤 STAFF USER ERSTELLEN (KORREKTE SPALTEN!)
-- ========================================

-- Erstelle StaffUser-Eintrag mit korrekten Pflichtfeldern
INSERT INTO staff_users (
    "firstName",
    "lastName", 
    email,
    "employeeId",
    "staffLevel",
    "employmentStatus",
    "userInfoId",
    "createdAt",
    "createdBy"
) VALUES (
    'Super',
    'Administrator',
    'superuser@staff.vertic.local',
    'superuser',
    3,  -- KORRIGIERT: 3 = superUser (NICHT 99!)
    'active',
    (SELECT id FROM serverpod_user_info WHERE "userIdentifier" = 'superuser@staff.vertic.local'),  -- WICHTIG: userInfoId Verknüpfung!
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'system@temp.local')  -- System User als Creator
);

-- ========================================
-- 4. 🔗 SUPER ADMIN ROLLE ZUWEISEN (KORREKTE SPALTEN!)
-- ========================================

-- Weise dem Superuser die Super Admin Rolle zu
INSERT INTO staff_user_roles ("staffUserId", "roleId", "assignedAt", "assignedBy", "isActive")
SELECT 
    (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local'),
    (SELECT id FROM roles WHERE name = 'Super Admin'),
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'system@temp.local'),  -- System User als Assigner
    true
WHERE EXISTS (SELECT 1 FROM roles WHERE name = 'Super Admin');

-- ========================================
-- 5. 🔐 ALLE PERMISSIONS DIREKT ZUWEISEN (KORREKTE SPALTEN!)
-- ========================================

-- Weise ALLE Permissions direkt zu (als Backup)
INSERT INTO staff_user_permissions ("staffUserId", "permissionId", "grantedAt", "grantedBy", "isActive")
SELECT 
    (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local'),
    p.id,
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'system@temp.local'),  -- System User als Granter
    true
FROM permissions p
WHERE NOT EXISTS (
    SELECT 1 FROM staff_user_permissions sup 
    WHERE sup."staffUserId" = (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local')
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
    su.email,
    su."userInfoId",
    su."createdAt"
FROM staff_users su
WHERE su.email = 'superuser@staff.vertic.local';

-- Zeige zugewiesene Rollen
SELECT 
    '👑 SUPERUSER ROLES' as info,
    su."employeeId" as username,
    r.name as role_name,
    r."displayName",
    sur."assignedAt",
    sur."isActive"
FROM staff_users su
JOIN staff_user_roles sur ON su.id = sur."staffUserId"
JOIN roles r ON sur."roleId" = r.id
WHERE su.email = 'superuser@staff.vertic.local';

-- Zeige zugewiesene Permissions (direkt und über Rollen)
SELECT 
    '🔐 SUPERUSER PERMISSIONS SUMMARY' as info,
    su."employeeId" as username,
    COUNT(DISTINCT p.id) as total_permissions,
    COUNT(DISTINCT sup.id) as direct_permissions,
    COUNT(DISTINCT rp.id) as role_permissions
FROM staff_users su
LEFT JOIN staff_user_permissions sup ON su.id = sup."staffUserId" AND sup."isActive" = true
LEFT JOIN staff_user_roles sur ON su.id = sur."staffUserId" AND sur."isActive" = true
LEFT JOIN role_permissions rp ON sur."roleId" = rp."roleId"
LEFT JOIN permissions p ON (sup."permissionId" = p.id OR rp."permissionId" = p.id)
WHERE su.email = 'superuser@staff.vertic.local'
GROUP BY su."employeeId";

-- Zeige Serverpod Auth Status
SELECT 
    '🔐 AUTH VERIFICATION' as info,
    ui."userIdentifier",
    ui.email,
    ui."userName",
    ui."scopeNames",
    ui.blocked,
    CASE 
        WHEN ea.hash IS NOT NULL THEN '✅ Password Hash vorhanden' 
        ELSE '❌ FEHLER: Kein Password Hash' 
    END as password_status
FROM serverpod_user_info ui
LEFT JOIN serverpod_email_auth ea ON ui.id = ea."userId"
WHERE ui."userIdentifier" = 'superuser@staff.vertic.local';

-- Zeige userInfoId Verknüpfung
SELECT 
    '🔗 USERINFO LINK VERIFICATION' as info,
    su.id as staff_id,
    su.email as staff_email,
    su."userInfoId",
    ui.id as serverpod_id,
    ui.email as serverpod_email,
    ui."userIdentifier",
    CASE 
        WHEN su."userInfoId" = ui.id THEN '✅ Korrekte Verknüpfung'
        ELSE '❌ FEHLER: Verknüpfung stimmt nicht'
    END as link_status
FROM staff_users su
JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
WHERE su.email = 'superuser@staff.vertic.local';

-- Final Status Check
SELECT 
    '🎉 SETUP STATUS' as final_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM staff_users WHERE email = 'superuser@staff.vertic.local') THEN '✅ Staff User erstellt'
        ELSE '❌ Staff User FEHLT'
    END as staff_user_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM staff_users su
            JOIN serverpod_user_info ui ON su.email = ui.email
            JOIN serverpod_email_auth ea ON ui.id = ea."userId"
            WHERE su.email = 'superuser@staff.vertic.local' AND ea.hash LIKE '$2a$10$%'
        ) THEN '✅ Echter bcrypt Hash gesetzt'
        ELSE '❌ Hash FEHLT oder ungültig'
    END as auth_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM staff_users su
            JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
            WHERE su.email = 'superuser@staff.vertic.local'
        ) THEN '✅ userInfoId korrekt verknüpft'
        ELSE '❌ userInfoId Verknüpfung FEHLT'
    END as link_status,
    COALESCE((
        SELECT COUNT(*) FROM staff_user_permissions sup
        JOIN staff_users su ON sup."staffUserId" = su.id
        WHERE su.email = 'superuser@staff.vertic.local' AND sup."isActive" = true
    ), 0) as direct_permission_count,
    COALESCE((
        SELECT COUNT(*) FROM staff_user_roles sur
        JOIN staff_users su ON sur."staffUserId" = su.id
        WHERE su.email = 'superuser@staff.vertic.local' AND sur."isActive" = true
    ), 0) as role_count;

-- =====================================================
-- 🎉 SUPERUSER ERFOLGREICH ERSTELLT!
-- 
-- 📋 LOGIN CREDENTIALS:
--    Username: superuser
--    Password: super123
--    Email: superuser@staff.vertic.local
--    App: Vertic Staff App
--
-- 🔧 WICHTIGE ERKENNTNISSE:
--    - staffLevel = 3 (superUser) - NICHT 99!
--    - userInfoId muss mit serverpod_user_info.id verknüpft sein
--    - StaffUserType Enum: 0=staff, 1=hallAdmin, 2=facilityAdmin, 3=superUser
--    - Ohne korrekte userInfoId: "Staff-User nicht aktiv" Fehler
--    - Ohne korrekte staffLevel: "Invalid argument" Fehler
--
-- 🔧 NEXT STEPS:
--    1. Teste Login in Staff App
--    2. Prüfe Admin Dashboard Zugang
--    3. Alle 53+ Permissions sollten verfügbar sein
-- ===================================================== 