-- =====================================================
-- SQL-Skript: Alle Permissions auflisten (AKTUALISIERT 2025-08-09)
-- Zweck: Übersicht über alle verfügbaren Permissions im System
-- Angepasst an: Neues staffLevel-System ohne super_admin Rolle
-- =====================================================

-- 1. Alle Permissions nach Kategorie sortiert
SELECT 
    '=== 🔐 ALLE PERMISSIONS ===' as section,
    p.id,
    p.name,
    p."displayName",
    p.description,
    p.category,
    p."createdAt"::date as created_date
FROM permissions p
ORDER BY p.category, p.name;

-- 2. Permissions-Statistik nach Kategorie
SELECT 
    '=== 📊 KATEGORIE STATISTIK ===' as section,
    p.category,
    COUNT(*) as permission_count,
    string_agg(p.name, ', ' ORDER BY p.name) as permission_list
FROM permissions p
GROUP BY p.category 
ORDER BY permission_count DESC;

-- 3. Gesamtanzahl Permissions
SELECT 
    '=== 📈 GESAMT-ÜBERSICHT ===' as section,
    COUNT(*) as total_permissions,
    COUNT(DISTINCT category) as categories_count
FROM permissions;

-- 4. Permissions mit Details für bessere Übersicht
SELECT 
    '=== 📋 PERMISSION DETAILS ===' as section,
    CONCAT('[', p.category, '] ', p.name) as permission_key,
    p."displayName",
    p.description,
    CASE 
        WHEN p."createdAt" IS NOT NULL THEN '✅ Aktiv'
        ELSE '❌ Inaktiv'
    END as status
FROM permissions p
ORDER BY p.category, p.name;

-- 5. NEUE LOGIK: Permissions und Rollen-Zuweisungen (ohne super_admin)
SELECT 
    '=== 🎭 PERMISSION-ROLLEN-ZUWEISUNGEN ===' as section,
    p.name as permission_name,
    p."displayName",
    p.category,
    r.name as role_name,
    r."displayName" as role_display_name,
    CASE 
        WHEN r."isActive" = true THEN '✅ Aktive Rolle'
        WHEN r."isActive" = false THEN '❌ Deaktivierte Rolle'
        ELSE '⚠️ Keine Rolle'
    END as role_status
FROM permissions p
LEFT JOIN role_permissions rp ON p.id = rp."permissionId"
LEFT JOIN roles r ON rp."roleId" = r.id
ORDER BY p.category, p.name, r."displayName";

-- 6. HINWEIS: Superuser-Permissions (staffLevel=1 hat ALLE Permissions automatisch)
SELECT 
    '=== 👑 SUPERUSER INFO ===' as section,
    'Superuser (staffLevel=1) haben automatisch ALLE Permissions' as info,
    'Keine explizite Rollen-Zuweisung nötig' as details,
    COUNT(*) || ' Permissions verfügbar für Superuser' as total_permissions
FROM permissions;
