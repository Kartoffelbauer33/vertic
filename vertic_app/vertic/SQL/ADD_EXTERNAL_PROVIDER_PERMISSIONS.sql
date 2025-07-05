-- =====================================================
-- VERTIC FREMDANBIETER-INTEGRATION: NEUE PERMISSIONS
-- Datum: Dezember 2024
-- Beschreibung: Fügt die erforderlichen RBAC-Permissions 
--               für das Fremdanbieter-System hinzu
-- =====================================================

-- 1. Neue Permission-Kategorie für externe Provider
-- Diese wird automatisch durch die existierenden Permissions erstellt

-- 2. Neue Permissions hinzufügen
INSERT INTO permissions (name, description, category, created_at) VALUES
-- Grundberechtigung: QR-Codes von externen Providern scannen und validieren
('can_validate_external_providers', 
 'Externe Provider QR-Codes scannen und validieren (Fitpass, Friction, etc.)', 
 'external_providers', 
 NOW()),

-- Admin-Berechtigung: Provider-Konfigurationen verwalten
('can_manage_external_providers', 
 'Externe Provider konfigurieren und verwalten (API-Keys, Einstellungen)', 
 'external_providers', 
 NOW()),

-- Analytics-Berechtigung: Statistiken und Reports anzeigen
('can_view_provider_stats', 
 'Provider-Statistiken und Check-in-Analytics anzeigen', 
 'external_providers', 
 NOW());

-- 3. Standard-Rollen mit neuen Permissions verknüpfen

-- STAFF-Rolle: Kann externe QR-Codes scannen
INSERT INTO role_permissions (role_id, permission_id, created_at)
SELECT 
    r.id as role_id,
    p.id as permission_id,
    NOW() as created_at
FROM roles r, permissions p 
WHERE r.name = 'staff' 
  AND p.name = 'can_validate_external_providers'
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp 
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- HALL_ADMIN-Rolle: Kann Provider verwalten und Statistiken einsehen
INSERT INTO role_permissions (role_id, permission_id, created_at)
SELECT 
    r.id as role_id,
    p.id as permission_id,
    NOW() as created_at
FROM roles r, permissions p 
WHERE r.name = 'hall_admin' 
  AND p.name IN ('can_validate_external_providers', 'can_manage_external_providers', 'can_view_provider_stats')
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp 
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- SUPERUSER-Rolle: Hat automatisch alle Permissions (durch is_superuser_permission)
-- Keine explizite Zuweisung nötig

-- 4. Validierung: Neue Permissions anzeigen
SELECT 
    p.name,
    p.description,
    p.category,
    COUNT(rp.role_id) as assigned_roles
FROM permissions p
LEFT JOIN role_permissions rp ON p.id = rp.permission_id
WHERE p.category = 'external_providers'
GROUP BY p.id, p.name, p.description, p.category
ORDER BY p.name;

-- 5. Validierung: Rollen-Zuweisungen anzeigen
SELECT 
    r.name as role_name,
    p.name as permission_name,
    p.category
FROM roles r
JOIN role_permissions rp ON r.id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE p.category = 'external_providers'
ORDER BY r.name, p.name;

-- =====================================================
-- HINWEISE FÜR ENTWICKLER:
-- 
-- 1. Diese Permissions sind erforderlich für:
--    - ExternalProviderEndpoint.processExternalCheckin()
--    - ExternalProviderEndpoint.configureProvider()
--    - ExternalProviderEndpoint.getProviderStats()
--
-- 2. Standard-Rollen-Zuweisungen:
--    - staff: kann externe QR-Codes scannen
--    - hall_admin: kann Provider verwalten + scannen + Stats
--    - superuser: hat automatisch alle Permissions
--
-- 3. Bei neuen Rollen müssen die Permissions manuell
--    zugewiesen werden über die Staff-Management-UI
-- ===================================================== 