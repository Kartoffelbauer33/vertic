-- =====================================================
-- VERTIC COMPLETE DATABASE SETUP - ALL IN ONE
-- Database: test_db
-- 🎯 KOMPLETTES SETUP IN EINEM SCRIPT
-- ✅ RBAC-System + Superuser + Verifikation
-- =====================================================

-- ========================================
-- 1. 🧹 VOLLSTÄNDIGE BEREINIGUNG
-- ========================================

-- Lösche alle User-related Daten
DELETE FROM staff_user_permissions;
DELETE FROM staff_user_roles;
DELETE FROM staff_users;

-- Lösche alle RBAC-Daten
DELETE FROM role_permissions;
DELETE FROM roles;
DELETE FROM permissions;

-- Lösche alle Serverpod Auth-Daten
DELETE FROM serverpod_user_info;
DELETE FROM serverpod_auth_key;
DELETE FROM serverpod_email_auth;
DELETE FROM serverpod_email_create_request;
DELETE FROM serverpod_email_reset;
DELETE FROM serverpod_email_failed_sign_in;

-- Lösche alle App-spezifischen User-Daten
DELETE FROM app_users;
DELETE FROM user_identities;

-- ========================================
-- 2. 👤 SYSTEM-USER ERSTELLEN (FÜR FOREIGN KEYS)
-- ========================================

-- Erstelle temporären System-User für Foreign Key Constraints
INSERT INTO staff_users (
    "firstName", "lastName", "email", "staffLevel", "employmentStatus", "createdAt"
) VALUES (
    'System', 'Administrator', 'system@temp.local', 3, 'active', NOW()
);

-- ========================================
-- 3. 🔐 RBAC SYSTEM - PERMISSIONS (60+ STÜCK)
-- ========================================

-- Erstelle alle Permissions (KORREKTE SPALTEN!)
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "iconName", "color", "createdAt") VALUES
-- 🔹 User Management (Essential)
('can_view_users', 'Benutzer anzeigen', 'Kann Benutzer anzeigen', 'user_management', true, 'people', '#2196F3', NOW()),
('can_create_users', 'Benutzer erstellen', 'Kann neue Benutzer erstellen', 'user_management', true, 'person_add', '#4CAF50', NOW()),
('can_edit_users', 'Benutzer bearbeiten', 'Kann Benutzer bearbeiten', 'user_management', true, 'edit', '#FF9800', NOW()),
('can_delete_users', 'Benutzer löschen', 'Kann Benutzer löschen', 'user_management', true, 'delete', '#F44336', NOW()),
('can_view_user_details', 'Benutzerdetails anzeigen', 'Kann detaillierte Benutzerinformationen anzeigen', 'user_management', false, 'info', '#2196F3', NOW()),
('can_reset_user_passwords', 'Passwörter zurücksetzen', 'Kann Benutzerpasswörter zurücksetzen', 'user_management', true, 'lock_reset', '#FF5722', NOW()),
('can_manage_user_permissions', 'Benutzerberechtigungen verwalten', 'Kann Benutzerberechtigungen verwalten', 'user_management', true, 'security', '#9C27B0', NOW()),
('can_block_users', 'Benutzer sperren', 'Kann Benutzer sperren', 'user_management', true, 'block', '#F44336', NOW()),
('can_unblock_users', 'Benutzer entsperren', 'Kann Benutzer entsperren', 'user_management', true, 'check_circle', '#4CAF50', NOW()),
('can_view_user_profiles', 'Benutzerprofile anzeigen', 'Kann Benutzerprofile anzeigen', 'user_management', false, 'account_circle', '#607D8B', NOW()),
('can_edit_user_profiles', 'Benutzerprofile bearbeiten', 'Kann Benutzerprofile bearbeiten', 'user_management', true, 'edit', '#FF9800', NOW()),
('can_view_user_notes', 'Benutzernotizen anzeigen', 'Kann Benutzernotizen anzeigen', 'user_management', false, 'note', '#795548', NOW()),
('can_create_user_notes', 'Benutzernotizen erstellen', 'Kann Benutzernotizen erstellen', 'user_management', false, 'note_add', '#4CAF50', NOW()),
('can_edit_user_notes', 'Benutzernotizen bearbeiten', 'Kann Benutzernotizen bearbeiten', 'user_management', false, 'edit_note', '#FF9800', NOW()),

-- 🔹 Staff Management (Essential) - BEIDE VARIANTEN!
('can_view_staff', 'Mitarbeiter anzeigen', 'Kann Mitarbeiter anzeigen', 'staff_management', true, 'badge', '#3F51B5', NOW()),
('can_view_staff_users', 'Staff-User anzeigen', 'Kann Staff-User anzeigen', 'staff_management', true, 'badge', '#3F51B5', NOW()),
('can_create_staff', 'Mitarbeiter erstellen', 'Kann neue Mitarbeiter erstellen', 'staff_management', true, 'person_add_alt', '#4CAF50', NOW()),
('can_create_staff_users', 'Staff-User erstellen', 'Kann neue Staff-User erstellen', 'staff_management', true, 'person_add_alt', '#4CAF50', NOW()),
('can_edit_staff', 'Mitarbeiter bearbeiten', 'Kann Mitarbeiter bearbeiten', 'staff_management', true, 'edit', '#FF9800', NOW()),
('can_edit_staff_users', 'Staff-User bearbeiten', 'Kann Staff-User bearbeiten', 'staff_management', true, 'edit', '#FF9800', NOW()),
('can_delete_staff', 'Mitarbeiter löschen', 'Kann Mitarbeiter löschen', 'staff_management', true, 'person_remove', '#F44336', NOW()),
('can_delete_staff_users', 'Staff-User löschen', 'Kann Staff-User löschen', 'staff_management', true, 'person_remove', '#F44336', NOW()),
('can_manage_staff_roles', 'Mitarbeiterrollen verwalten', 'Kann Mitarbeiterrollen verwalten', 'staff_management', true, 'admin_panel_settings', '#9C27B0', NOW()),
('can_view_staff_permissions', 'Staff-Permissions anzeigen', 'Kann Staff-Permissions anzeigen', 'staff_management', false, 'security', '#9C27B0', NOW()),
('can_view_staff_schedules', 'Dienstpläne anzeigen', 'Kann Dienstpläne anzeigen', 'staff_management', false, 'schedule', '#607D8B', NOW()),

-- 🔹 Ticket Management (Essential) - ERWEITERT!
('can_view_tickets', 'Tickets anzeigen', 'Kann Tickets anzeigen', 'ticket_management', true, 'confirmation_number', '#2196F3', NOW()),
('can_view_all_tickets', 'Alle Tickets anzeigen', 'Kann alle Tickets anzeigen', 'ticket_management', true, 'confirmation_number', '#2196F3', NOW()),
('can_create_tickets', 'Tickets erstellen', 'Kann neue Tickets erstellen', 'ticket_management', true, 'add_box', '#4CAF50', NOW()),
('can_edit_tickets', 'Tickets bearbeiten', 'Kann Tickets bearbeiten', 'ticket_management', true, 'edit_note', '#FF9800', NOW()),
('can_delete_tickets', 'Tickets löschen', 'Kann Tickets löschen', 'ticket_management', true, 'delete_sweep', '#F44336', NOW()),
('can_process_payments', 'Zahlungen verarbeiten', 'Kann Zahlungen verarbeiten', 'ticket_management', true, 'payment', '#4CAF50', NOW()),
('can_issue_refunds', 'Rückerstattungen durchführen', 'Kann Rückerstattungen durchführen', 'ticket_management', true, 'money_off', '#FF5722', NOW()),
('can_manage_ticket_types', 'Tickettypen verwalten', 'Kann Tickettypen verwalten', 'ticket_management', true, 'category', '#9C27B0', NOW()),
('can_scan_tickets', 'Tickets scannen', 'Kann Tickets scannen', 'ticket_management', false, 'qr_code_scanner', '#607D8B', NOW()),
('can_validate_tickets', 'Tickets validieren', 'Kann Tickets validieren', 'ticket_management', false, 'verified', '#4CAF50', NOW()),

-- 🔹 System Administration (Critical)
('can_access_system_settings', 'Systemeinstellungen', 'Kann Systemeinstellungen zugreifen', 'system_settings', true, 'settings', '#607D8B', NOW()),
('can_modify_system_config', 'Systemkonfiguration', 'Kann Systemkonfiguration ändern', 'system_settings', true, 'tune', '#FF5722', NOW()),
('can_manage_system_backups', 'Systemsicherungen verwalten', 'Kann Systemsicherungen verwalten', 'system_settings', true, 'backup', '#795548', NOW()),
('can_access_admin_dashboard', 'Admin Dashboard', 'Kann auf das Admin Dashboard zugreifen', 'system_settings', true, 'admin_panel_settings', '#9C27B0', NOW()),

-- 🔹 RBAC Management (Critical)
('can_manage_permissions', 'Permissions verwalten', 'Kann Permissions erstellen, bearbeiten und löschen', 'rbac_management', true, 'security', '#F44336', NOW()),
('can_manage_roles', 'Rollen verwalten', 'Kann Rollen erstellen, bearbeiten und löschen', 'rbac_management', true, 'admin_panel_settings', '#9C27B0', NOW()),
('can_assign_permissions', 'Permissions zuweisen', 'Kann Permissions an Benutzer und Rollen zuweisen', 'rbac_management', true, 'assignment', '#FF9800', NOW()),

-- 🔹 Facility Management (Important)
('can_view_facilities', 'Einrichtungen anzeigen', 'Kann Einrichtungen anzeigen', 'facility_management', false, 'business', '#607D8B', NOW()),
('can_create_facilities', 'Einrichtungen erstellen', 'Kann neue Einrichtungen erstellen', 'facility_management', true, 'add_business', '#4CAF50', NOW()),
('can_edit_facilities', 'Einrichtungen bearbeiten', 'Kann Einrichtungen bearbeiten', 'facility_management', true, 'edit', '#FF9800', NOW()),
('can_delete_facilities', 'Einrichtungen löschen', 'Kann Einrichtungen löschen', 'facility_management', true, 'delete', '#F44336', NOW()),

-- 🔹 Reporting & Analytics (Important)
('can_view_reports', 'Berichte anzeigen', 'Kann Berichte anzeigen', 'reporting_analytics', false, 'assessment', '#2196F3', NOW()),
('can_access_financial_reports', 'Finanzberichte', 'Kann Finanzberichte einsehen', 'reporting_analytics', true, 'account_balance', '#4CAF50', NOW()),
('can_access_audit_logs', 'Audit-Logs', 'Kann Audit-Logs einsehen', 'reporting_analytics', true, 'fact_check', '#FF5722', NOW()),
('can_export_reports', 'Berichte exportieren', 'Kann Berichte exportieren', 'reporting_analytics', false, 'file_download', '#607D8B', NOW()),

-- 🔹 Status Management (Important)  
('can_view_status_types', 'Status-Typen anzeigen', 'Kann Status-Typen anzeigen', 'status_management', false, 'category', '#607D8B', NOW()),
('can_create_status_types', 'Status-Typen erstellen', 'Kann Status-Typen erstellen', 'status_management', true, 'add', '#4CAF50', NOW()),
('can_edit_status_types', 'Status-Typen bearbeiten', 'Kann Status-Typen bearbeiten', 'status_management', true, 'edit', '#FF9800', NOW()),
('can_delete_status_types', 'Status-Typen löschen', 'Kann Status-Typen löschen', 'status_management', true, 'delete', '#F44336', NOW()),

-- 🔹 Gym Management (Important)
('can_view_gyms', 'Gyms anzeigen', 'Kann Gyms anzeigen', 'gym_management', false, 'fitness_center', '#607D8B', NOW()),
('can_create_gyms', 'Gyms erstellen', 'Kann Gyms erstellen', 'gym_management', true, 'add', '#4CAF50', NOW()),
('can_edit_gyms', 'Gyms bearbeiten', 'Kann Gyms bearbeiten', 'gym_management', true, 'edit', '#FF9800', NOW()),
('can_delete_gyms', 'Gyms löschen', 'Kann Gyms löschen', 'gym_management', true, 'delete', '#F44336', NOW()),

-- 🔹 Product Management (POS Artikel-Verwaltung)
('can_view_products', 'Artikel anzeigen', 'Kann Artikel im POS anzeigen', 'product_management', false, 'inventory', '#607D8B', NOW()),
('can_create_products', 'Artikel erstellen', 'Kann neue Artikel über Scanner hinzufügen', 'product_management', true, 'add_shopping_cart', '#4CAF50', NOW()),
('can_edit_products', 'Artikel bearbeiten', 'Kann bestehende Artikel bearbeiten', 'product_management', true, 'edit', '#FF9800', NOW()),
('can_delete_products', 'Artikel löschen', 'Kann Artikel löschen', 'product_management', true, 'delete', '#F44336', NOW()),
('can_manage_product_categories', 'Kategorien verwalten', 'Kann Artikel-Kategorien erstellen und bearbeiten', 'product_management', true, 'category', '#9C27B0', NOW()),
('can_manage_product_stock', 'Lagerbestand verwalten', 'Kann Lagerbestände anpassen', 'product_management', false, 'inventory_2', '#FF5722', NOW()),
('can_scan_product_barcodes', 'Barcode scannen', 'Kann Barcodes für Artikel-Erfassung scannen', 'product_management', false, 'qr_code_scanner', '#2196F3', NOW()),
('can_access_favorites_category', 'Favoriten-Kategorie verwalten', 'Kann Artikel zur Favoriten-Kategorie hinzufügen', 'product_management', false, 'star', '#FFC107', NOW());

-- ========================================
-- 4. 👥 ROLLEN-SYSTEM ERSTELLEN
-- ========================================

INSERT INTO roles (name, "displayName", description, "color", "iconName", "isSystemRole", "isActive", "sortOrder", "createdAt", "createdBy") VALUES
('Super Admin', 'Super Administrator', 'Vollzugriff auf alle Systemfunktionen', '#F44336', 'admin_panel_settings', true, true, 1, NOW(), (SELECT id FROM staff_users WHERE email = 'system@temp.local')),
('Facility Admin', 'Einrichtungsadministrator', 'Verwaltung einer spezifischen Einrichtung', '#9C27B0', 'business', true, true, 2, NOW(), (SELECT id FROM staff_users WHERE email = 'system@temp.local')),
('Artikel Manager', 'Artikel-Manager', 'Vollständige Artikel-Verwaltung und Barcode-Scanning', '#FF5722', 'inventory', true, true, 3, NOW(), (SELECT id FROM staff_users WHERE email = 'system@temp.local')),
('Kassierer', 'Kassierer/in', 'Ticketverkauf und Kassenoperationen', '#4CAF50', 'payment', true, true, 4, NOW(), (SELECT id FROM staff_users WHERE email = 'system@temp.local')),
('Support Staff', 'Support-Mitarbeiter', 'Kundenbetreuung und grundlegende Operationen', '#2196F3', 'support_agent', true, true, 5, NOW(), (SELECT id FROM staff_users WHERE email = 'system@temp.local')),
('Readonly User', 'Nur-Lese-Benutzer', 'Nur-Lese-Zugriff auf ausgewählte Bereiche', '#607D8B', 'visibility', true, true, 6, NOW(), (SELECT id FROM staff_users WHERE email = 'system@temp.local'));

-- ========================================
-- 5. 🔗 ROLLEN-PERMISSIONS ZUWEISUNGEN
-- ========================================

-- Super Admin bekommt ALLE Permissions
INSERT INTO role_permissions ("roleId", "permissionId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM roles WHERE name = 'Super Admin'),
    id,
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'system@temp.local')
FROM permissions;

-- Kassierer bekommt grundlegende Permissions + Artikel-Anzeige
INSERT INTO role_permissions ("roleId", "permissionId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM roles WHERE name = 'Kassierer'),
    id,
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'system@temp.local')
FROM permissions 
WHERE name IN (
    'can_view_users', 'can_create_users', 'can_edit_users',
    'can_view_tickets', 'can_create_tickets', 'can_process_payments',
    'can_scan_tickets', 'can_validate_tickets',
    'can_view_facilities',
    'can_view_products'
);

-- Artikel Manager bekommt alle Artikel-Management Permissions
INSERT INTO role_permissions ("roleId", "permissionId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM roles WHERE name = 'Artikel Manager'),
    id,
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'system@temp.local')
FROM permissions 
WHERE name IN (
    'can_view_users', 'can_create_users', 'can_edit_users',
    'can_view_tickets', 'can_create_tickets', 'can_process_payments',
    'can_scan_tickets', 'can_validate_tickets',
    'can_view_facilities',
    'can_view_products', 'can_create_products', 'can_edit_products', 'can_delete_products',
    'can_manage_product_categories', 'can_manage_product_stock', 
    'can_scan_product_barcodes', 'can_access_favorites_category'
);

-- Support Staff bekommt erweiterte User-Management Permissions + Artikel-Anzeige
INSERT INTO role_permissions ("roleId", "permissionId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM roles WHERE name = 'Support Staff'),
    id,
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'system@temp.local')
FROM permissions 
WHERE name IN (
    'can_view_users', 'can_create_users', 'can_edit_users', 'can_view_user_details',
    'can_view_tickets', 'can_edit_tickets', 'can_issue_refunds',
    'can_view_facilities', 'can_view_reports',
    'can_view_products'
);

-- ========================================
-- 6. 🔐 SUPERUSER ERSTELLEN (UNIFIED AUTH)
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
    '["staff"]'::json
);

-- Erstelle EmailAuth mit bcrypt Hash für 'super123'
INSERT INTO serverpod_email_auth (
    "userId",
    email,
    hash
) VALUES (
    (SELECT id FROM serverpod_user_info WHERE "userIdentifier" = 'superuser@staff.vertic.local'),
    'superuser@staff.vertic.local',
    '$2a$10$KNcGVTK1kwpwJhfwtaat5u1uOOOUJzIa51blIw2JcQ0K1tjrRTw62'
);

-- Erstelle StaffUser-Eintrag
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
    3,
    'active',
    (SELECT id FROM serverpod_user_info WHERE "userIdentifier" = 'superuser@staff.vertic.local'),
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'system@temp.local')
);

-- Weise Super Admin Rolle zu
INSERT INTO staff_user_roles ("staffUserId", "roleId", "assignedAt", "assignedBy", "isActive")
SELECT 
    (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local'),
    (SELECT id FROM roles WHERE name = 'Super Admin'),
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'system@temp.local'),
    true;

-- Weise ALLE Permissions direkt zu (als Backup)
INSERT INTO staff_user_permissions ("staffUserId", "permissionId", "grantedAt", "grantedBy", "isActive")
SELECT 
    (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local'),
    p.id,
    NOW(),
    (SELECT id FROM staff_users WHERE email = 'system@temp.local'),
    true
FROM permissions p;

-- ========================================
-- 7. ✅ SETUP VERIFIKATION
-- ========================================

-- Gesamtstatistik
SELECT 
    '🎉 COMPLETE SETUP FINISHED!' as status,
    (SELECT COUNT(*) FROM permissions) as total_permissions,
    (SELECT COUNT(*) FROM roles) as total_roles,
    (SELECT COUNT(*) FROM staff_users WHERE email = 'superuser@staff.vertic.local') as superuser_created,
    (SELECT COUNT(*) FROM staff_user_permissions WHERE "staffUserId" = (SELECT id FROM staff_users WHERE email = 'superuser@staff.vertic.local')) as superuser_permissions;

-- Superuser Details
SELECT 
    '👑 SUPERUSER LOGIN CREDENTIALS' as info,
    'superuser' as username,
    'super123' as password,
    'superuser@staff.vertic.local' as email,
    su."staffLevel" as staff_level,
    su."employmentStatus" as status
FROM staff_users su
WHERE su.email = 'superuser@staff.vertic.local';

-- =====================================================
-- ✅ SETUP KOMPLETT!
-- 
-- 📋 LOGIN:
--    Username: superuser
--    Password: super123
--    Email: superuser@staff.vertic.local
-- 
-- 🎯 FERTIG! Starte die Staff App und melde dich an.
-- ===================================================== 