-- 👥 STAFF MANAGEMENT TOOLS - Vertic System
--
-- Praktische Tools für Staff-User Verwaltung
-- ========================================================================

-- 📊 STAFF OVERVIEW - Alle Staff-User mit Details
SELECT 
    '=== 📊 STAFF OVERVIEW ===' as section,
    su.id,
    su."employeeId",
    su."firstName" || ' ' || su."lastName" as full_name,
    su.email,
    CASE 
        WHEN su."staffLevel" = 0 THEN '👤 Staff'
        WHEN su."staffLevel" = 1 THEN '👑 Superuser'
        ELSE '❓ Unknown'
    END as user_type,
    su."employmentStatus",
    CASE 
        WHEN su."userInfoId" IS NOT NULL THEN '✅ Auth aktiv'
        ELSE '❌ Keine Auth'
    END as auth_status,
    su."createdAt"::date as created_date,
    string_agg(r."displayName", ', ') as assigned_roles
FROM staff_users su
LEFT JOIN staff_user_roles sur ON su.id = sur."staffUserId" AND sur."isActive" = true
LEFT JOIN roles r ON sur."roleId" = r.id AND r."isActive" = true
GROUP BY su.id, su."employeeId", su."firstName", su."lastName", su.email, su."staffLevel", su."employmentStatus", su."userInfoId", su."createdAt"
ORDER BY su."staffLevel" DESC, su.id;

-- 🔍 SUPERUSER DETAILS - Detaillierte Superuser-Analyse
SELECT 
    '=== 👑 SUPERUSER DETAILS ===' as section,
    su.id as staff_id,
    su."employeeId",
    su."firstName" || ' ' || su."lastName" as full_name,
    su.email as staff_email,
    su."userInfoId",
    ui.id as serverpod_user_id,
    ui.email as serverpod_email,
    LEFT(ea.hash, 30) || '...' as password_hash_preview,
    LENGTH(ea.hash) as hash_length,
    CASE 
        WHEN ea.hash LIKE '$2a$%' OR ea.hash LIKE '$2b$%' THEN '✅ BCrypt'
        ELSE '❌ Unbekannt'
    END as hash_type,
    su."lastLoginAt",
    su."createdAt"::date as created_date
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
LEFT JOIN serverpod_email_auth ea ON ea."userId" = ui.id
WHERE su."staffLevel" = 1
ORDER BY su.id;

-- 🎭 ROLLEN-ZUWEISUNGEN - Welcher User hat welche Rollen
SELECT 
    '=== 🎭 ROLLEN-ZUWEISUNGEN ===' as section,
    su.id as staff_id,
    su."employeeId",
    su."firstName" || ' ' || su."lastName" as staff_name,
    r.id as role_id,
    r.name as role_name,
    r."displayName" as role_display_name,
    sur."assignedAt"::date as assigned_date,
    CASE 
        WHEN sur."expiresAt" IS NOT NULL AND sur."expiresAt" < NOW() THEN '⚠️ Abgelaufen'
        WHEN sur."isActive" = false THEN '❌ Deaktiviert'
        ELSE '✅ Aktiv'
    END as status
FROM staff_user_roles sur
JOIN staff_users su ON sur."staffUserId" = su.id
JOIN roles r ON sur."roleId" = r.id
ORDER BY su.id, r."displayName";

-- 🔐 AUTH-PROBLEME FINDEN - Diagnose defekter Authentication
SELECT 
    '=== 🔐 AUTH-PROBLEME ===' as section,
    su.id,
    su."employeeId",
    su."firstName" || ' ' || su."lastName" as staff_name,
    CASE 
        WHEN su."userInfoId" IS NULL THEN '❌ Keine userInfoId'
        WHEN ui.id IS NULL THEN '❌ serverpod_user_info nicht gefunden'
        WHEN ea."userId" IS NULL THEN '❌ serverpod_email_auth nicht gefunden'
        WHEN ea.hash IS NULL OR ea.hash = '' THEN '❌ Kein Password-Hash'
        ELSE '✅ Auth vollständig'
    END as problem,
    su."userInfoId",
    ui.id as found_user_info_id,
    ea."userId" as found_email_auth_user_id
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su."userInfoId" = ui.id
LEFT JOIN serverpod_email_auth ea ON ea."userId" = ui.id
WHERE su."employmentStatus" = 'active'
ORDER BY 
    CASE 
        WHEN su."userInfoId" IS NULL THEN 1
        WHEN ui.id IS NULL THEN 2 
        WHEN ea."userId" IS NULL THEN 3
        WHEN ea.hash IS NULL OR ea.hash = '' THEN 4
        ELSE 5
    END, su.id;

-- 📈 SYSTEM STATISTIKEN
SELECT 
    '=== 📈 SYSTEM STATISTIKEN ===' as section,
    'Staff Users' as kategorie,
    COUNT(*) as total_count,
    COUNT(CASE WHEN "staffLevel" = 1 THEN 1 END) as superuser_count,
    COUNT(CASE WHEN "staffLevel" = 0 THEN 1 END) as normal_staff_count,
    COUNT(CASE WHEN "employmentStatus" = 'active' THEN 1 END) as active_count,
    COUNT(CASE WHEN "userInfoId" IS NOT NULL THEN 1 END) as auth_configured_count
FROM staff_users

UNION ALL

SELECT 
    '=== 📈 SYSTEM STATISTIKEN ===' as section,
    'Rollen' as kategorie,
    COUNT(*) as total_count,
    COUNT(CASE WHEN "isActive" = true THEN 1 END) as active_count,
    COUNT(CASE WHEN "isSystemRole" = true THEN 1 END) as system_roles_count,
    0 as unused1,
    0 as unused2
FROM roles

UNION ALL

SELECT 
    '=== 📈 SYSTEM STATISTIKEN ===' as section,
    'Rollen-Zuweisungen' as kategorie,
    COUNT(*) as total_assignments,
    COUNT(CASE WHEN "isActive" = true THEN 1 END) as active_assignments,
    COUNT(DISTINCT "staffUserId") as users_with_roles,
    0 as unused1,
    0 as unused2
FROM staff_user_roles;