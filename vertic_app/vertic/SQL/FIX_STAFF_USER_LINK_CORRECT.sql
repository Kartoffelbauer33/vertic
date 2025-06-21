-- =====================================================
-- FIX STAFF USER SERVERPOD LINK (COMPREHENSIVE)
-- Verknüpft StaffUser mit Serverpod UserInfo über userInfoId
-- ✅ UMFASSENDES REPARATUR-TOOL FÜR USERINFO-VERKNÜPFUNGEN
-- =====================================================
-- 
-- 🔧 WICHTIGE ERKENNTNISSE:
-- - Feldname: userInfoId (NICHT serverpodUserId!)
-- - Verknüpfung: staff_users.userInfoId = serverpod_user_info.id
-- - Ohne Verknüpfung: "Staff-User nicht aktiv" Fehler
-- - Email-Matching: staff_users.email = serverpod_user_info.email
-- =====================================================

-- 1. Zeige alle Serverpod UserInfo Einträge
SELECT 
    '🔐 ALL SERVERPOD USER INFO' as info,
    id,
    "userIdentifier",
    email,
    "userName",
    "fullName",
    blocked,
    "scopeNames",
    created
FROM serverpod_user_info 
ORDER BY id;

-- 2. Zeige alle Staff Users mit ihren aktuellen Verknüpfungen
SELECT 
    '👤 ALL STAFF USERS & LINKS' as info,
    su.id as staff_id,
    su."firstName",
    su."lastName", 
    su.email as staff_email,
    su."employeeId",
    su."staffLevel",
    su."employmentStatus",
    su."userInfoId",
    ui.id as serverpod_id,
    ui.email as serverpod_email,
    CASE 
        WHEN su."userInfoId" IS NULL THEN '❌ Keine Verknüpfung'
        WHEN su."userInfoId" = ui.id THEN '✅ Korrekte Verknüpfung'
        ELSE '⚠️ Falsche Verknüpfung'
    END as link_status
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
ORDER BY su.id;

-- 3. Finde Staff Users ohne userInfoId Verknüpfung
SELECT 
    '❌ STAFF USERS WITHOUT USERINFO LINK' as info,
    su.id as staff_id,
    su.email as staff_email,
    su."employeeId",
    su."userInfoId",
    ui.id as matching_serverpod_id,
    ui.email as matching_serverpod_email,
    CASE 
        WHEN ui.id IS NOT NULL THEN '✅ Match gefunden - kann verknüpft werden'
        ELSE '❌ Kein Serverpod User mit dieser Email'
    END as repair_status
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su.email = ui.email
WHERE su."userInfoId" IS NULL
ORDER BY su.id;

-- 4. AUTOMATISCHE REPARATUR: Verknüpfe Staff Users mit Serverpod UserInfo
-- Basierend auf Email-Matching
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

-- 5. SPEZIELLE REPARATUR: Superuser mit bekannter ID verknüpfen
-- Falls der Superuser eine spezifische UserInfo ID haben soll
UPDATE staff_users 
SET "userInfoId" = (
    SELECT id FROM serverpod_user_info 
    WHERE email = 'superuser@staff.vertic.local'
)
WHERE email = 'superuser@staff.vertic.local'
AND "userInfoId" IS NULL;

-- 6. Prüfe das Ergebnis nach Reparatur
SELECT 
    '✅ AFTER REPAIR' as info,
    su.id as staff_id,
    su."firstName",
    su."lastName",
    su.email as staff_email,
    su."employeeId", 
    su."staffLevel",
    su."employmentStatus",
    su."userInfoId",
    ui.id as serverpod_id,
    ui.email as serverpod_email,
    ui."userIdentifier",
    CASE 
        WHEN su."userInfoId" IS NULL THEN '❌ Immer noch keine Verknüpfung'
        WHEN su."userInfoId" = ui.id AND su.email = ui.email THEN '✅ Perfekte Verknüpfung'
        WHEN su."userInfoId" = ui.id AND su.email != ui.email THEN '⚠️ ID stimmt, Email unterschiedlich'
        ELSE '❌ Fehlerhafte Verknüpfung'
    END as link_status
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
ORDER BY su.id;

-- 7. Zeige spezifische Verknüpfung für Superuser
SELECT 
    '👑 SUPERUSER LINK VERIFICATION' as info,
    su.id as staff_id,
    su.email as staff_email,
    su."employeeId",
    su."userInfoId",
    ui.id as serverpod_id,
    ui.email as serverpod_email,
    ui."userIdentifier",
    ui."scopeNames",
    CASE 
        WHEN su."userInfoId" = ui.id THEN '✅ Korrekte Verknüpfung'
        ELSE '❌ FEHLER: Verknüpfung stimmt nicht'
    END as link_status,
    CASE 
        WHEN ui."scopeNames"::text LIKE '%staff%' THEN '✅ Staff Scope vorhanden'
        ELSE '❌ Staff Scope FEHLT'
    END as scope_status
FROM staff_users su
JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
WHERE su.email = 'superuser@staff.vertic.local';

-- 8. Final Statistics
SELECT 
    '📊 FINAL LINK STATISTICS' as info,
    COUNT(*) as total_staff_users,
    COUNT(CASE WHEN "userInfoId" IS NOT NULL THEN 1 END) as linked_users,
    COUNT(CASE WHEN "userInfoId" IS NULL THEN 1 END) as unlinked_users,
    ROUND(
        COUNT(CASE WHEN "userInfoId" IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 
        2
    ) as link_percentage,
    CASE 
        WHEN COUNT(CASE WHEN "userInfoId" IS NULL THEN 1 END) = 0 
        THEN '✅ ALLE STAFF USERS SIND VERKNÜPFT!'
        ELSE '❌ FEHLER: ' || COUNT(CASE WHEN "userInfoId" IS NULL THEN 1 END) || ' User(s) noch nicht verknüpft'
    END as status
FROM staff_users; 