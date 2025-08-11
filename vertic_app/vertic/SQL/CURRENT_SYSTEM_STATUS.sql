-- 🔍 AKTUELLER SYSTEM-STATUS - Vertic RBAC & Authentication
-- 
-- Dieses Script zeigt den aktuellen Zustand des Systems nach allen Updates
-- Verwende IMMER dieses Script zur Diagnose - alle anderen sind veraltet
--
-- Stand: 2025-08-09 nach Authentifizierungs-Fix und Rollen-Bereinigung
-- ========================================================================

-- 1. AUTHENTICATION STATUS - Superuser Login
SELECT 
    '=== 🔐 AUTHENTICATION STATUS ===' as section,
    su.id as staff_id,
    su."employeeId",
    su."firstName",
    su."lastName", 
    su.email,
    su."staffLevel",
    CASE 
        WHEN su."staffLevel" = 0 THEN 'staff'
        WHEN su."staffLevel" = 1 THEN 'superUser ✅'
        ELSE 'unknown'
    END as level_name,
    su."userInfoId",
    ui.id as serverpod_user_id,
    ui.email as serverpod_email,
    CASE 
        WHEN ea."userId" IS NOT NULL THEN '✅ Auth konfiguriert'
        ELSE '❌ Keine Auth'
    END as auth_status
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
LEFT JOIN serverpod_email_auth ea ON ea."userId" = ui.id
WHERE su."employeeId" = 'superuser' OR su.id = 1;

-- 2. ALLE STAFF USERS - Overview
SELECT 
    '=== 👥 ALLE STAFF USERS ===' as section,
    su.id,
    su."employeeId", 
    su."firstName",
    su."lastName",
    su.email,
    CASE 
        WHEN su."staffLevel" = 0 THEN 'staff'
        WHEN su."staffLevel" = 1 THEN 'superUser'
        ELSE 'unknown'
    END as level,
    su."employmentStatus",
    CASE 
        WHEN su."userInfoId" IS NOT NULL THEN '✅ Verknüpft'
        ELSE '❌ Nicht verknüpft'
    END as auth_link_status
FROM staff_users su
ORDER BY su."staffLevel" DESC, su.id;

-- 3. AKTIVE ROLLEN SYSTEM
SELECT 
    '=== 🎭 AKTIVE ROLLEN ===' as section,
    r.id,
    r.name,
    r."displayName",
    r.description,
    r."isSystemRole",
    r."isActive",
    COUNT(sur."staffUserId") as assigned_users
FROM roles r
LEFT JOIN staff_user_roles sur ON r.id = sur."roleId" AND sur."isActive" = true
WHERE r."isActive" = true
GROUP BY r.id, r.name, r."displayName", r.description, r."isSystemRole", r."isActive"
ORDER BY r."isSystemRole" DESC, r."displayName";

-- 4. ROLLEN-ZUWEISUNGEN
SELECT 
    '=== 🔗 ROLLEN-ZUWEISUNGEN ===' as section,
    su.id as staff_id,
    su."employeeId",
    su."firstName" || ' ' || su."lastName" as full_name,
    CASE 
        WHEN su."staffLevel" = 1 THEN '👑 Superuser (alle Rechte)'
        ELSE string_agg(r."displayName", ', ')
    END as assigned_roles
FROM staff_users su
LEFT JOIN staff_user_roles sur ON su.id = sur."staffUserId" AND sur."isActive" = true
LEFT JOIN roles r ON sur."roleId" = r.id AND r."isActive" = true
GROUP BY su.id, su."employeeId", su."firstName", su."lastName", su."staffLevel"
ORDER BY su."staffLevel" DESC, su.id;

-- 5. SYSTEM HEALTH CHECK
SELECT 
    '=== ⚡ SYSTEM HEALTH CHECK ===' as section,
    'Superuser Auth' as check_type,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ OK'
        ELSE '❌ FEHLT'
    END as status,
    COUNT(*) as count
FROM staff_users su
JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
JOIN serverpod_email_auth ea ON ea."userId" = ui.id
WHERE su."staffLevel" = 1

UNION ALL

SELECT 
    '=== ⚡ SYSTEM HEALTH CHECK ===' as section,
    'Aktive Rollen' as check_type,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ OK'
        ELSE '⚠️ KEINE'
    END as status,
    COUNT(*) as count
FROM roles r
WHERE r."isActive" = true AND r.id != 27 -- Ausgenommen deaktivierte Super Admin Rolle

UNION ALL

SELECT 
    '=== ⚡ SYSTEM HEALTH CHECK ===' as section,
    'Deaktivierte Super Admin Rolle' as check_type,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Korrekt deaktiviert'
        ELSE '⚠️ Nicht gefunden'
    END as status,
    COUNT(*) as count
FROM roles r
WHERE r.id = 27 AND r."isActive" = false;

-- 6. WICHTIGE SYSTEM FACTS
SELECT 
    '=== 📋 SYSTEM FACTS ===' as section,
    'Authentifizierung' as kategorie,
    '• Superuser: staffLevel=1 (enum superUser)
• Login: Email + Passwort über serverpod_email_auth  
• Password: BCrypt Hash für "super123"
• UserID Kette: staff_users.userInfoId → serverpod_user_info.id → serverpod_email_auth.userId' as details

UNION ALL

SELECT 
    '=== 📋 SYSTEM FACTS ===' as section,
    'Rollen-System' as kategorie,
    '• Normale User: staffLevel=0 + Rollen aus roles Tabelle
• Superuser: staffLevel=1 (brauchen keine Rollen)
• Rollen-Zuweisungen: staff_user_roles Tabelle
• UI: Checkbox für Superuser, Dropdown für normale Rollen' as details

UNION ALL

SELECT 
    '=== 📋 SYSTEM FACTS ===' as section,
    'Bekannte Fixes' as kategorie,
    '• BCrypt Hash für super123 korrekt gesetzt
• Verwirrende "Super Administrator" Rolle deaktiviert  
• Authentication funktioniert über echtes Backend
• UI zeigt keine Duplikat-Superuser-Optionen mehr' as details;