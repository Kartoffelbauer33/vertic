-- =====================================================
-- SQL-Skript: Alle Permissions auflisten
-- Zweck: Übersicht über alle verfügbaren Permissions im System
-- Datum: 2025-01-23
-- =====================================================

-- 1. Alle Permissions nach Kategorie sortiert
SELECT 
    id,
    name,
    "displayName",
    description,
    category,
    "createdAt",
    "updatedAt"
FROM permissions 
ORDER BY category, name;

-- 2. Permissions-Statistik nach Kategorie
SELECT 
    category,
    COUNT(*) as permission_count
FROM permissions 
GROUP BY category 
ORDER BY permission_count DESC;

-- 3. Gesamtanzahl Permissions
SELECT COUNT(*) as total_permissions FROM permissions;

-- 4. Permissions mit Details für bessere Übersicht
SELECT 
    CONCAT('[', category, '] ', name) as permission_key,
    "displayName",
    description,
    CASE 
        WHEN "createdAt" IS NOT NULL THEN 'Aktiv'
        ELSE 'Inaktiv'
    END as status
FROM permissions 
ORDER BY category, name;

-- 5. Prüfung: Welche Permissions sind bereits dem Superuser zugewiesen?
SELECT 
    p.name as permission_name,
    p."displayName",
    p.category,
    CASE 
        WHEN rp."roleId" IS NOT NULL THEN 'ZUGEWIESEN'
        ELSE 'FEHLT'
    END as superuser_status
FROM permissions p
LEFT JOIN role_permissions rp ON p.id = rp."permissionId" 
    AND rp."roleId" = (SELECT id FROM roles WHERE name = 'super_admin')
ORDER BY superuser_status DESC, p.category, p.name;
