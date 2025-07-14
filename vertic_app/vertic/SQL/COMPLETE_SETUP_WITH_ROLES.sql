-- ========================================
-- KOMPLETTES VERTIC SETUP MIT SYSTEMROLLEN
-- ========================================
-- Basiert auf den originalen Altlasten-Scripts
-- Erweitert um automatische Systemrollen-Erstellung

BEGIN;

-- ========================================
-- 1. TEMPORÄRER SYSTEM-USER FÜR FOREIGN KEYS
-- ========================================

-- Erstelle temporären System-User für Foreign Key Constraints
INSERT INTO staff_users 
(
    "firstName", 
    "lastName", 
    email, 
    "staffLevel", 
    "employmentStatus", 
    "createdAt"
) 
VALUES 
(
    'System', 
    'Initializer', 
    'system@vertic.local', 
    'superUser', 
    'active', 
    NOW()
) 
ON CONFLICT (email) DO NOTHING;

-- Hole die System-User ID
DO $$
DECLARE
    system_user_id INTEGER;
BEGIN
    SELECT id INTO system_user_id FROM staff_users WHERE email = 'system@vertic.local';
    
    IF system_user_id IS NULL THEN
        RAISE EXCEPTION 'System-User konnte nicht erstellt werden!';
    END IF;
    
    RAISE NOTICE '🔧 Temporärer System-User erstellt: ID %', system_user_id;
END $$;

-- ========================================
-- 2. ALLE PERMISSIONS ERSTELLEN
-- ========================================

-- User Management Permissions
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_view_users', 'Benutzer anzeigen', 'Kann registrierte Benutzer anzeigen', 'user_management', false, NOW()),
('can_create_users', 'Benutzer erstellen', 'Kann neue Benutzer registrieren', 'user_management', false, NOW()),
('can_edit_users', 'Benutzer bearbeiten', 'Kann Benutzerdaten bearbeiten', 'user_management', false, NOW()),
('can_delete_users', 'Benutzer löschen', 'Kann Benutzer löschen', 'user_management', true, NOW()),
('can_view_user_details', 'Benutzerdetails anzeigen', 'Kann detaillierte Benutzerinformationen anzeigen', 'user_management', false, NOW()),
('can_reset_user_passwords', 'Benutzer-Passwörter zurücksetzen', 'Kann Passwörter für Benutzer zurücksetzen', 'user_management', false, NOW()),
('can_manage_user_permissions', 'Benutzerberechtigungen verwalten', 'Kann Berechtigungen für Benutzer verwalten', 'user_management', true, NOW()),
('can_block_users', 'Benutzer sperren', 'Kann Benutzer temporär sperren', 'user_management', false, NOW()),
('can_unblock_users', 'Benutzer entsperren', 'Kann gesperrte Benutzer wieder entsperren', 'user_management', false, NOW()),
('can_view_user_profiles', 'Benutzerprofile anzeigen', 'Kann Benutzerprofile und Fotos anzeigen', 'user_management', false, NOW()),
('can_edit_user_profiles', 'Benutzerprofile bearbeiten', 'Kann Benutzerprofile und Fotos bearbeiten', 'user_management', false, NOW()),
('can_view_user_notes', 'Benutzernotizen anzeigen', 'Kann interne Notizen zu Benutzern anzeigen', 'user_management', false, NOW()),
('can_create_user_notes', 'Benutzernotizen erstellen', 'Kann neue Notizen zu Benutzern erstellen', 'user_management', false, NOW()),
('can_edit_user_notes', 'Benutzernotizen bearbeiten', 'Kann bestehende Benutzernotizen bearbeiten', 'user_management', false, NOW())

ON CONFLICT (name) DO NOTHING;

-- Staff Management Permissions
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_view_staff', 'Personal anzeigen', 'Kann Personalliste anzeigen', 'staff_management', false, NOW()),
('can_view_staff_users', 'Personal-Benutzer anzeigen', 'Kann Personal-Benutzer anzeigen', 'staff_management', false, NOW()),
('can_create_staff', 'Personal erstellen', 'Kann neues Personal anlegen', 'staff_management', true, NOW()),
('can_create_staff_users', 'Personal-Benutzer erstellen', 'Kann neue Personal-Benutzer erstellen', 'staff_management', true, NOW()),
('can_edit_staff', 'Personal bearbeiten', 'Kann Personaldaten bearbeiten', 'staff_management', false, NOW()),
('can_edit_staff_users', 'Personal-Benutzer bearbeiten', 'Kann Personal-Benutzerdaten bearbeiten', 'staff_management', false, NOW()),
('can_delete_staff', 'Personal löschen', 'Kann Personal löschen', 'staff_management', true, NOW()),
('can_delete_staff_users', 'Personal-Benutzer löschen', 'Kann Personal-Benutzer löschen', 'staff_management', true, NOW()),
('can_manage_staff_roles', 'Personal-Rollen verwalten', 'Kann Rollen für Personal verwalten', 'staff_management', true, NOW()),
('can_view_staff_permissions', 'Personal-Berechtigungen anzeigen', 'Kann Berechtigungen des Personals anzeigen', 'staff_management', false, NOW()),
('can_view_staff_schedules', 'Dienstpläne anzeigen', 'Kann Arbeitszeiten und Dienstpläne anzeigen', 'staff_management', false, NOW())

ON CONFLICT (name) DO NOTHING;

-- Ticket Management Permissions
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_view_tickets', 'Tickets anzeigen', 'Kann vorhandene Tickets anzeigen', 'ticket_management', false, NOW()),
('can_view_all_tickets', 'Alle Tickets anzeigen', 'Kann alle Tickets systemweit anzeigen', 'ticket_management', false, NOW()),
('can_create_tickets', 'Tickets erstellen', 'Kann neue Tickets erstellen', 'ticket_management', false, NOW()),
('can_edit_tickets', 'Tickets bearbeiten', 'Kann vorhandene Tickets bearbeiten', 'ticket_management', false, NOW()),
('can_delete_tickets', 'Tickets löschen', 'Kann Tickets löschen', 'ticket_management', true, NOW()),
('can_process_payments', 'Zahlungen verarbeiten', 'Kann Zahlungen für Tickets verarbeiten', 'ticket_management', false, NOW()),
('can_issue_refunds', 'Erstattungen veranlassen', 'Kann Erstattungen für Tickets veranlassen', 'ticket_management', true, NOW()),
('can_manage_ticket_types', 'Ticket-Typen verwalten', 'Kann Ticket-Typen erstellen und bearbeiten', 'ticket_management', true, NOW()),
('can_scan_tickets', 'Tickets scannen', 'Kann Tickets mit Scanner erfassen', 'ticket_management', false, NOW()),
('can_validate_tickets', 'Tickets validieren', 'Kann Gültigkeit von Tickets prüfen', 'ticket_management', false, NOW())

ON CONFLICT (name) DO NOTHING;

-- System Management Permissions
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_access_system_settings', 'Systemeinstellungen zugreifen', 'Kann auf Systemeinstellungen zugreifen', 'system_management', true, NOW()),
('can_modify_system_config', 'Systemkonfiguration ändern', 'Kann Systemkonfiguration ändern', 'system_management', true, NOW()),
('can_manage_system_backups', 'System-Backups verwalten', 'Kann System-Backups erstellen und verwalten', 'system_management', true, NOW()),
('can_access_admin_dashboard', 'Admin-Dashboard zugreifen', 'Kann auf das Admin-Dashboard zugreifen', 'system_management', true, NOW()),
('can_manage_permissions', 'Berechtigungen verwalten', 'Kann Systemberechtigungen verwalten', 'system_management', true, NOW()),
('can_manage_roles', 'Rollen verwalten', 'Kann Systemrollen verwalten', 'system_management', true, NOW()),
('can_assign_permissions', 'Berechtigungen zuweisen', 'Kann Berechtigungen an Benutzer zuweisen', 'system_management', true, NOW())

ON CONFLICT (name) DO NOTHING;

-- Facility Management Permissions
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_view_facilities', 'Einrichtungen anzeigen', 'Kann Einrichtungen anzeigen', 'facility_management', false, NOW()),
('can_create_facilities', 'Einrichtungen erstellen', 'Kann neue Einrichtungen erstellen', 'facility_management', true, NOW()),
('can_edit_facilities', 'Einrichtungen bearbeiten', 'Kann Einrichtungen bearbeiten', 'facility_management', true, NOW()),
('can_delete_facilities', 'Einrichtungen löschen', 'Kann Einrichtungen löschen', 'facility_management', true, NOW())

ON CONFLICT (name) DO NOTHING;

-- Reports & Analytics Permissions
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_view_reports', 'Berichte anzeigen', 'Kann Systemberichte anzeigen', 'reports_analytics', false, NOW()),
('can_access_financial_reports', 'Finanzberichte zugreifen', 'Kann auf Finanzberichte zugreifen', 'reports_analytics', true, NOW()),
('can_access_audit_logs', 'Audit-Logs zugreifen', 'Kann auf Audit-Logs zugreifen', 'reports_analytics', true, NOW()),
('can_export_reports', 'Berichte exportieren', 'Kann Berichte exportieren', 'reports_analytics', false, NOW())

ON CONFLICT (name) DO NOTHING;

-- Status Management Permissions
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_view_status_types', 'Status-Typen anzeigen', 'Kann Benutzer-Status-Typen anzeigen', 'user_management', false, NOW()),
('can_create_status_types', 'Status-Typen erstellen', 'Kann neue Benutzer-Status-Typen erstellen', 'user_management', true, NOW()),
('can_edit_status_types', 'Status-Typen bearbeiten', 'Kann Benutzer-Status-Typen bearbeiten', 'user_management', false, NOW()),
('can_delete_status_types', 'Status-Typen löschen', 'Kann Benutzer-Status-Typen löschen', 'user_management', true, NOW())

ON CONFLICT (name) DO NOTHING;

-- Gym Management Permissions
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_view_gyms', 'Hallen anzeigen', 'Kann Hallen/Gyms anzeigen', 'facility_management', false, NOW()),
('can_create_gyms', 'Hallen erstellen', 'Kann neue Hallen/Gyms erstellen', 'facility_management', true, NOW()),
('can_edit_gyms', 'Hallen bearbeiten', 'Kann Hallen/Gyms bearbeiten', 'facility_management', false, NOW()),
('can_delete_gyms', 'Hallen löschen', 'Kann Hallen/Gyms löschen', 'facility_management', true, NOW())

ON CONFLICT (name) DO NOTHING;

-- Product Management Permissions
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_view_products', 'Produkte anzeigen', 'Kann Produkte im Kassensystem anzeigen', 'product_management', false, NOW()),
('can_create_products', 'Produkte erstellen', 'Kann neue Produkte im Kassensystem erstellen', 'product_management', false, NOW()),
('can_edit_products', 'Produkte bearbeiten', 'Kann bestehende Produkte bearbeiten', 'product_management', false, NOW()),
('can_delete_products', 'Produkte löschen', 'Kann Produkte aus dem Kassensystem löschen', 'product_management', true, NOW()),
('can_manage_product_categories', 'Produktkategorien verwalten', 'Kann Produktkategorien erstellen und verwalten', 'product_management', false, NOW()),
('can_manage_product_stock', 'Lagerbestand verwalten', 'Kann Lagerbestände von Produkten verwalten', 'product_management', false, NOW()),
('can_scan_product_barcodes', 'Produkt-Barcodes scannen', 'Kann Barcodes von Produkten scannen', 'product_management', false, NOW()),
('can_access_favorites_category', 'Favoriten-Kategorie zugreifen', 'Kann auf die spezielle Favoriten-Kategorie zugreifen', 'product_management', false, NOW())

ON CONFLICT (name) DO NOTHING;

-- DACH Compliance Permissions (Deutschland, Österreich, Schweiz)
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_manage_tax_classes', 'Steuerklassen verwalten', 'Kann länderspezifische Steuerklassen verwalten', 'compliance_management', true, NOW()),
('can_setup_country_defaults', 'Länder-Standards einrichten', 'Kann Standard-Einstellungen für Länder konfigurieren', 'compliance_management', true, NOW()),
('can_manage_country_assignments', 'Länder-Zuordnungen verwalten', 'Kann Facilities zu Ländern zuordnen', 'compliance_management', true, NOW()),
('can_view_tax_reports', 'Steuerberichte anzeigen', 'Kann länderspezifische Steuerberichte anzeigen', 'compliance_management', false, NOW()),
('can_configure_tse_settings', 'TSE-Einstellungen konfigurieren', 'Kann TSE-Einstellungen für Deutschland konfigurieren', 'compliance_management', true, NOW()),
('can_configure_rksv_settings', 'RKSV-Einstellungen konfigurieren', 'Kann RKSV-Einstellungen für Österreich konfigurieren', 'compliance_management', true, NOW())

ON CONFLICT (name) DO NOTHING;

-- External Provider Permissions (Fitpass, Friction, etc.)
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "createdAt") VALUES
('can_view_external_providers', 'Externe Anbieter anzeigen', 'Kann externe Anbieter-Konfigurationen anzeigen', 'external_integration', false, NOW()),
('can_manage_external_providers', 'Externe Anbieter verwalten', 'Kann externe Anbieter-Integrationen verwalten', 'external_integration', true, NOW()),
('can_configure_fitpass', 'Fitpass konfigurieren', 'Kann Fitpass-Integration konfigurieren', 'external_integration', true, NOW()),
('can_configure_friction', 'Friction konfigurieren', 'Kann Friction-Integration konfigurieren', 'external_integration', true, NOW()),
('can_test_external_apis', 'Externe APIs testen', 'Kann Verbindungen zu externen APIs testen', 'external_integration', false, NOW())

ON CONFLICT (name) DO NOTHING;

-- ========================================
-- 3. SERVERPOD AUTH INTEGRATION
-- ========================================

-- UserInfo für Serverpod Auth erstellen
INSERT INTO serverpod_user_info 
(
    "userName", 
    email, 
    "fullName", 
    "created", 
    "imageUrl", 
    "scopeNames", 
    blocked
) 
VALUES 
(
    'superuser', 
    'superuser@staff.vertic.local', 
    'Super Administrator', 
    NOW(), 
    NULL, 
    '["vertic:staff"]', 
    false
) 
ON CONFLICT (email) DO NOTHING;

-- E-Mail Auth für Superuser erstellen  
INSERT INTO serverpod_email_auth 
(
    "userId", 
    email, 
    hash
) 
SELECT 
    ui.id,
    'superuser@staff.vertic.local',
    '$2a$10$zqWhlQnM1IZXWQUlTlh3BeQvOHuYIIcg7.CsEjlJUVBv8fNKdFnLy'  -- vertic123
FROM serverpod_user_info ui 
WHERE ui.email = 'superuser@staff.vertic.local'
ON CONFLICT ("userId") DO NOTHING;

-- ========================================
-- 4. STAFF-USER ERSTELLEN
-- ========================================

INSERT INTO staff_users 
(
    "userInfoId",
    "firstName", 
    "lastName", 
    email, 
    "employeeId",
    "staffLevel", 
    "employmentStatus", 
    "emailVerifiedAt",
    "createdAt"
) 
SELECT 
    ui.id,
    'Super',
    'Administrator', 
    'superuser@staff.vertic.local',
    'superuser',
    'superUser', 
    'active',
    NOW(),
    NOW()
FROM serverpod_user_info ui 
WHERE ui.email = 'superuser@staff.vertic.local'
ON CONFLICT (email) DO NOTHING;

-- ========================================
-- 5. SYSTEMROLLEN ERSTELLEN
-- ========================================

DO $$
DECLARE
    superuser_staff_id INTEGER;
BEGIN
    -- Hole Superuser Staff-ID
    SELECT id INTO superuser_staff_id FROM staff_users WHERE email = 'superuser@staff.vertic.local';
    
    IF superuser_staff_id IS NULL THEN
        RAISE EXCEPTION 'Superuser nicht gefunden! Staff-User muss zuerst erstellt werden.';
    END IF;
    
    RAISE NOTICE '🎭 Erstelle Systemrollen mit Staff-User ID %', superuser_staff_id;
    
    -- 1. Super Admin Rolle
    INSERT INTO roles (name, "displayName", description, color, "iconName", "isSystemRole", "isActive", "sortOrder", "createdAt", "createdBy") 
    VALUES ('super_admin', 'Super Administrator', 'Vollzugriff auf alle Systemfunktionen. Kann alle Berechtigungen verwalten und kritische Systemeinstellungen ändern.', '#D32F2F', 'admin_panel_settings', true, true, 1, NOW(), superuser_staff_id)
    ON CONFLICT (name) DO NOTHING;

    -- 2. Facility Admin Rolle
    INSERT INTO roles (name, "displayName", description, color, "iconName", "isSystemRole", "isActive", "sortOrder", "createdAt", "createdBy") 
    VALUES ('facility_admin', 'Facility Administrator', 'Verwaltung eines Standorts. Kann Personal, Kassen, Tickets und lokale Einstellungen verwalten.', '#1976D2', 'business', true, true, 2, NOW(), superuser_staff_id)
    ON CONFLICT (name) DO NOTHING;

    -- 3. Kassierer Rolle
    INSERT INTO roles (name, "displayName", description, color, "iconName", "isSystemRole", "isActive", "sortOrder", "createdAt", "createdBy") 
    VALUES ('kassierer', 'Kassierer', 'Ticketverkauf, Kundenbetreuung und Kassenfunktionen. Kern-Rolle für den täglichen Betrieb.', '#4CAF50', 'point_of_sale', true, true, 3, NOW(), superuser_staff_id)
    ON CONFLICT (name) DO NOTHING;

    -- 4. Support Staff Rolle
    INSERT INTO roles (name, "displayName", description, color, "iconName", "isSystemRole", "isActive", "sortOrder", "createdAt", "createdBy") 
    VALUES ('support_staff', 'Support Mitarbeiter', 'Kundenbetreuung, Problemlösung und grundlegende Verwaltungsaufgaben.', '#FF9800', 'support_agent', true, true, 4, NOW(), superuser_staff_id)
    ON CONFLICT (name) DO NOTHING;

    -- 5. Readonly User Rolle
    INSERT INTO roles (name, "displayName", description, color, "iconName", "isSystemRole", "isActive", "sortOrder", "createdAt", "createdBy") 
    VALUES ('readonly_user', 'Readonly User', 'Nur-Lese-Zugriff für Einblicke und Reporting. Keine Änderungen möglich.', '#607D8B', 'visibility', false, true, 5, NOW(), superuser_staff_id)
    ON CONFLICT (name) DO NOTHING;
    
END $$;

-- ========================================
-- 6. ALLE PERMISSIONS DEM SUPERUSER ZUWEISEN
-- ========================================

DO $$
DECLARE
    superuser_staff_id INTEGER;
    permission_record RECORD;
    permission_count INTEGER := 0;
BEGIN
    -- Hole Superuser Staff-ID
    SELECT id INTO superuser_staff_id FROM staff_users WHERE email = 'superuser@staff.vertic.local';
    
    -- Weise alle Permissions direkt zu
    FOR permission_record IN 
        SELECT id, name FROM permissions 
    LOOP
        INSERT INTO staff_user_permissions 
        (
            "staffUserId", 
            "permissionId", 
            "grantedAt", 
            "grantedBy", 
            "isActive"
        ) 
        VALUES 
        (
            superuser_staff_id, 
            permission_record.id, 
            NOW(), 
            superuser_staff_id, 
            true
        ) 
        ON CONFLICT ("staffUserId", "permissionId") DO NOTHING;
        
        permission_count := permission_count + 1;
    END LOOP;
    
    RAISE NOTICE '✅ % Permissions dem Superuser zugewiesen', permission_count;
END $$;

-- ========================================
-- 7. SUPER ADMIN ROLLE DEM SUPERUSER ZUWEISEN
-- ========================================

DO $$
DECLARE
    superuser_staff_id INTEGER;
    super_admin_role_id INTEGER;
BEGIN
    -- Hole IDs
    SELECT id INTO superuser_staff_id FROM staff_users WHERE email = 'superuser@staff.vertic.local';
    SELECT id INTO super_admin_role_id FROM roles WHERE name = 'super_admin';
    
    IF superuser_staff_id IS NOT NULL AND super_admin_role_id IS NOT NULL THEN
        -- Weise Super Admin Rolle zu
        INSERT INTO staff_user_roles 
        (
            "staffUserId", 
            "roleId", 
            "assignedAt", 
            "assignedBy", 
            "isActive",
            reason
        ) 
        VALUES 
        (
            superuser_staff_id, 
            super_admin_role_id, 
            NOW(), 
            superuser_staff_id, 
            true,
            'Initial Setup - Super Admin'
        ) 
        ON CONFLICT ("staffUserId", "roleId") DO NOTHING;
        
        RAISE NOTICE '✅ Super Admin Rolle dem Superuser zugewiesen';
    ELSE
        RAISE NOTICE '❌ Superuser oder Super Admin Rolle nicht gefunden';
    END IF;
END $$;

-- ========================================
-- 8. TEMPORÄREN SYSTEM-USER LÖSCHEN
-- ========================================

DELETE FROM staff_users WHERE email = 'system@vertic.local';

-- ========================================
-- 9. VERIFIKATION DER ERGEBNISSE
-- ========================================

SELECT '=== SETUP VERIFICATION ===' AS status;

-- Permissions Anzahl
SELECT 
    'Permissions:' AS category,
    COUNT(*) AS count
FROM permissions
UNION ALL
-- Rollen Anzahl  
SELECT 
    'Roles:' AS category,
    COUNT(*) AS count
FROM roles
UNION ALL
-- Superuser Permissions
SELECT 
    'Superuser Direct Permissions:' AS category,
    COUNT(*) AS count
FROM staff_user_permissions sup
JOIN staff_users su ON sup."staffUserId" = su.id
WHERE su.email = 'superuser@staff.vertic.local'
UNION ALL
-- Superuser Rollen
SELECT 
    'Superuser Roles:' AS category,
    COUNT(*) AS count
FROM staff_user_roles sur
JOIN staff_users su ON sur."staffUserId" = su.id
WHERE su.email = 'superuser@staff.vertic.local';

-- Details des Superusers
SELECT '=== SUPERUSER DETAILS ===' AS info;
SELECT 
    su.id as staff_id,
    su."firstName",
    su."lastName", 
    su.email,
    su."staffLevel",
    su."employmentStatus"
FROM staff_users su 
WHERE su.email = 'superuser@staff.vertic.local';

-- Zugewiesene Rollen
SELECT '=== ASSIGNED ROLES ===' AS info;
SELECT 
    r.name,
    r."displayName",
    sur."assignedAt",
    sur."isActive"
FROM staff_user_roles sur
JOIN roles r ON sur."roleId" = r.id
JOIN staff_users su ON sur."staffUserId" = su.id
WHERE su.email = 'superuser@staff.vertic.local';

-- System-Rollen Übersicht
SELECT '=== SYSTEM ROLES ===' AS info;
SELECT 
    name,
    "displayName",
    "isSystemRole",
    "isActive",
    "sortOrder"
FROM roles 
ORDER BY "sortOrder";

COMMIT; 