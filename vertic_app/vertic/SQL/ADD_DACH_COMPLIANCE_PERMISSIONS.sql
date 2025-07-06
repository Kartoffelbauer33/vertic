-- =====================================================
-- VERTIC DACH-COMPLIANCE: NEUE PERMISSIONS
-- Datum: Juli 2025
-- Beschreibung: Fügt die erforderlichen RBAC-Permissions 
--               für das DACH-Compliance-System hinzu
-- =====================================================

-- 1. Neue DACH-spezifische Permissions hinzufügen
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "iconName", "color", "createdAt") VALUES

-- 🇩🇪🇦🇹🇨🇭 DACH-Compliance Management
('can_manage_tax_classes', 
 'Steuerklassen verwalten', 
 'Kann Steuerklassen für DACH-Länder erstellen und bearbeiten', 
 'dach_compliance', 
 true, 
 'account_balance', 
 '#4CAF50', 
 NOW()),

('can_setup_country_defaults', 
 'Länder-Setup durchführen', 
 'Kann Standard-Setups für Deutschland und Österreich durchführen', 
 'dach_compliance', 
 true, 
 'flag', 
 '#FF5722', 
 NOW()),

('can_manage_country_assignments', 
 'Länder-Zuordnungen verwalten', 
 'Kann Facilities Ländern zuordnen (SuperUser-only)', 
 'dach_compliance', 
 true, 
 'business', 
 '#9C27B0', 
 NOW()),

('can_view_tax_reports', 
 'Steuer-Reports anzeigen', 
 'Kann DACH-Compliance und Steuer-Reports einsehen', 
 'dach_compliance', 
 false, 
 'assessment', 
 '#2196F3', 
 NOW()),

('can_configure_tse_settings', 
 'TSE-Einstellungen verwalten', 
 'Kann TSE-Konfiguration für Deutschland verwalten', 
 'dach_compliance', 
 true, 
 'security', 
 '#FF9800', 
 NOW()),

('can_configure_rksv_settings', 
 'RKSV-Einstellungen verwalten', 
 'Kann RKSV-Konfiguration für Österreich verwalten', 
 'dach_compliance', 
 true, 
 'verified_user', 
 '#795548', 
 NOW());

-- 2. Super Admin Rolle bekommt automatisch alle neuen Permissions
INSERT INTO role_permissions ("roleId", "permissionId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM roles WHERE name = 'Super Admin'),
    p.id,
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local')
FROM permissions p
WHERE p.category = 'dach_compliance'
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp 
    WHERE rp."roleId" = (SELECT id FROM roles WHERE name = 'Super Admin')
    AND rp."permissionId" = p.id
  );

-- 3. SuperUser bekommt alle neuen Permissions direkt (als Backup)
INSERT INTO staff_user_permissions ("staffUserId", "permissionId", "grantedAt", "grantedBy", "isActive")
SELECT 
    (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local'),
    p.id,
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local'),
    true
FROM permissions p
WHERE p.category = 'dach_compliance'
  AND NOT EXISTS (
    SELECT 1 FROM staff_user_permissions sup 
    WHERE sup."staffUserId" = (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local')
    AND sup."permissionId" = p.id
  );

-- 4. Facility Admin bekommt ausgewählte DACH-Permissions
INSERT INTO role_permissions ("roleId", "permissionId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM roles WHERE name = 'Facility Admin'),
    p.id,
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local')
FROM permissions p 
WHERE p.name IN ('can_view_tax_reports', 'can_manage_tax_classes')
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp 
    WHERE rp."roleId" = (SELECT id FROM roles WHERE name = 'Facility Admin')
    AND rp."permissionId" = p.id
  );

-- 5. Validierung: Neue DACH-Permissions anzeigen
SELECT 
    '🇩🇪🇦🇹 DACH-COMPLIANCE PERMISSIONS ADDED' as status,
    p.name,
    p."displayName",
    p.description,
    COUNT(rp."roleId") as assigned_roles
FROM permissions p
LEFT JOIN role_permissions rp ON p.id = rp."permissionId"
WHERE p.category = 'dach_compliance'
GROUP BY p.id, p.name, p."displayName", p.description
ORDER BY p.name;

-- 6. Validierung: SuperUser DACH-Permission-Count
SELECT 
    '👑 SUPERUSER DACH-PERMISSIONS' as info,
    COUNT(*) as dach_permissions_count,
    CASE 
        WHEN COUNT(*) = 6 THEN '✅ Alle DACH-Permissions zugewiesen'
        ELSE '❌ Fehlende DACH-Permissions'
    END as status
FROM staff_user_permissions sup
JOIN permissions p ON sup."permissionId" = p.id
WHERE sup."staffUserId" = (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local')
  AND p.category = 'dach_compliance'
  AND sup."isActive" = true;

-- =====================================================
-- HINWEISE FÜR ENTWICKLER:
-- 
-- 1. Diese Permissions sind erforderlich für:
--    - TaxManagementEndpoint.setupGermanyDefaults()
--    - TaxManagementEndpoint.setupAustriaDefaults()
--    - FacilityEndpoint.assignCountryToFacility()
--    - Zukünftige TSE/RKSV-Integration
--
-- 2. Standard-Rollen-Zuweisungen:
--    - Super Admin: ALLE DACH-Permissions
--    - Facility Admin: Steuerklassen + Reports
--    - Andere Rollen: Keine DACH-Permissions (manuell zuweisen)
--
-- 3. Bei neuen DACH-Features weitere Permissions hier hinzufügen
-- ===================================================== 