-- =====================================================
-- VERTIC DATABASE CLEAN SETUP SCRIPT
-- Database: test_db
-- 🧹 KOMPLETT BEREINIGUNG & NEU-INITIALISIERUNG
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
-- 2. 🔐 RBAC SYSTEM - KOMPLETTE INITIALISIERUNG (53 PERMISSIONS)
-- ========================================

-- Erstelle alle wichtigsten Permissions
INSERT INTO permissions (name, "displayName", description, category, "isSystemCritical", "iconName", "createdAt") VALUES
-- 🔹 User Management (Essential)
('can_view_users', 'Benutzer anzeigen', 'Kann Benutzer anzeigen', 'user_management', true, 'people', NOW()),
('can_create_users', 'Benutzer erstellen', 'Kann neue Benutzer erstellen', 'user_management', true, 'person_add', NOW()),
('can_edit_users', 'Benutzer bearbeiten', 'Kann Benutzer bearbeiten', 'user_management', true, 'edit', NOW()),
('can_delete_users', 'Benutzer löschen', 'Kann Benutzer löschen', 'user_management', true, 'delete', NOW()),
('can_view_user_details', 'Benutzerdetails anzeigen', 'Kann detaillierte Benutzerinformationen anzeigen', 'user_management', false, 'info', NOW()),
('can_reset_user_passwords', 'Passwörter zurücksetzen', 'Kann Benutzerpasswörter zurücksetzen', 'user_management', true, 'lock_reset', NOW()),
('can_manage_user_permissions', 'Benutzerberechtigungen verwalten', 'Kann Benutzerberechtigungen verwalten', 'user_management', true, 'security', NOW()),
('can_block_users', 'Benutzer sperren', 'Kann Benutzer sperren', 'user_management', true, 'block', NOW()),
('can_unblock_users', 'Benutzer entsperren', 'Kann Benutzer entsperren', 'user_management', true, 'check_circle', NOW()),
('can_view_user_profiles', 'Benutzerprofile anzeigen', 'Kann Benutzerprofile anzeigen', 'user_management', false, 'account_circle', NOW()),
('can_edit_user_profiles', 'Benutzerprofile bearbeiten', 'Kann Benutzerprofile bearbeiten', 'user_management', true, 'edit', NOW()),
('can_view_user_notes', 'Benutzernotizen anzeigen', 'Kann Benutzernotizen anzeigen', 'user_management', false, 'note', NOW()),
('can_create_user_notes', 'Benutzernotizen erstellen', 'Kann Benutzernotizen erstellen', 'user_management', false, 'note_add', NOW()),
('can_edit_user_notes', 'Benutzernotizen bearbeiten', 'Kann Benutzernotizen bearbeiten', 'user_management', false, 'edit_note', NOW()),

-- 🔹 Staff Management (Essential) - BEIDE VARIANTEN!
('can_view_staff', 'Mitarbeiter anzeigen', 'Kann Mitarbeiter anzeigen', 'staff_management', true, 'badge', NOW()),
('can_view_staff_users', 'Staff-User anzeigen', 'Kann Staff-User anzeigen', 'staff_management', true, 'badge', NOW()),
('can_create_staff', 'Mitarbeiter erstellen', 'Kann neue Mitarbeiter erstellen', 'staff_management', true, 'person_add_alt', NOW()),
('can_create_staff_users', 'Staff-User erstellen', 'Kann neue Staff-User erstellen', 'staff_management', true, 'person_add_alt', NOW()),
('can_edit_staff', 'Mitarbeiter bearbeiten', 'Kann Mitarbeiter bearbeiten', 'staff_management', true, 'edit', NOW()),
('can_edit_staff_users', 'Staff-User bearbeiten', 'Kann Staff-User bearbeiten', 'staff_management', true, 'edit', NOW()),
('can_delete_staff', 'Mitarbeiter löschen', 'Kann Mitarbeiter löschen', 'staff_management', true, 'person_remove', NOW()),
('can_delete_staff_users', 'Staff-User löschen', 'Kann Staff-User löschen', 'staff_management', true, 'person_remove', NOW()),
('can_manage_staff_roles', 'Mitarbeiterrollen verwalten', 'Kann Mitarbeiterrollen verwalten', 'staff_management', true, 'admin_panel_settings', NOW()),
('can_view_staff_permissions', 'Staff-Permissions anzeigen', 'Kann Staff-Permissions anzeigen', 'staff_management', false, 'security', NOW()),
('can_view_staff_schedules', 'Dienstpläne anzeigen', 'Kann Dienstpläne anzeigen', 'staff_management', false, 'schedule', NOW()),

-- 🔹 Ticket Management (Essential) - ERWEITERT!
('can_view_tickets', 'Tickets anzeigen', 'Kann Tickets anzeigen', 'ticket_management', true, 'confirmation_number', NOW()),
('can_view_all_tickets', 'Alle Tickets anzeigen', 'Kann alle Tickets anzeigen', 'ticket_management', true, 'confirmation_number', NOW()),
('can_create_tickets', 'Tickets erstellen', 'Kann neue Tickets erstellen', 'ticket_management', true, 'add_box', NOW()),
('can_edit_tickets', 'Tickets bearbeiten', 'Kann Tickets bearbeiten', 'ticket_management', true, 'edit_note', NOW()),
('can_delete_tickets', 'Tickets löschen', 'Kann Tickets löschen', 'ticket_management', true, 'delete_sweep', NOW()),
('can_process_payments', 'Zahlungen verarbeiten', 'Kann Zahlungen verarbeiten', 'ticket_management', true, 'payment', NOW()),
('can_issue_refunds', 'Rückerstattungen durchführen', 'Kann Rückerstattungen durchführen', 'ticket_management', true, 'money_off', NOW()),
('can_manage_ticket_types', 'Tickettypen verwalten', 'Kann Tickettypen verwalten', 'ticket_management', true, 'category', NOW()),
('can_scan_tickets', 'Tickets scannen', 'Kann Tickets scannen', 'ticket_management', false, 'qr_code_scanner', NOW()),
('can_validate_tickets', 'Tickets validieren', 'Kann Tickets validieren', 'ticket_management', false, 'verified', NOW()),

-- 🔹 System Administration (Critical)
('can_access_system_settings', 'Systemeinstellungen', 'Kann Systemeinstellungen zugreifen', 'system_settings', true, 'settings', NOW()),
('can_modify_system_config', 'Systemkonfiguration', 'Kann Systemkonfiguration ändern', 'system_settings', true, 'tune', NOW()),
('can_manage_system_backups', 'Systemsicherungen verwalten', 'Kann Systemsicherungen verwalten', 'system_settings', true, 'backup', NOW()),
('can_access_admin_dashboard', 'Admin Dashboard', 'Kann auf das Admin Dashboard zugreifen', 'system_settings', true, 'admin_panel_settings', NOW()),

-- 🔹 RBAC Management (Critical)
('can_manage_permissions', 'Permissions verwalten', 'Kann Permissions erstellen, bearbeiten und löschen', 'rbac_management', true, 'security', NOW()),
('can_manage_roles', 'Rollen verwalten', 'Kann Rollen erstellen, bearbeiten und löschen', 'rbac_management', true, 'admin_panel_settings', NOW()),
('can_assign_permissions', 'Permissions zuweisen', 'Kann Permissions an Benutzer und Rollen zuweisen', 'rbac_management', true, 'assignment', NOW()),

-- 🔹 Facility Management (Important)
('can_view_facilities', 'Einrichtungen anzeigen', 'Kann Einrichtungen anzeigen', 'facility_management', false, 'business', NOW()),
('can_create_facilities', 'Einrichtungen erstellen', 'Kann neue Einrichtungen erstellen', 'facility_management', true, 'add_business', NOW()),
('can_edit_facilities', 'Einrichtungen bearbeiten', 'Kann Einrichtungen bearbeiten', 'facility_management', true, 'edit', NOW()),
('can_delete_facilities', 'Einrichtungen löschen', 'Kann Einrichtungen löschen', 'facility_management', true, 'delete', NOW()),

-- 🔹 Reporting & Analytics (Important)
('can_view_reports', 'Berichte anzeigen', 'Kann Berichte anzeigen', 'reporting_analytics', false, 'assessment', NOW()),
('can_access_financial_reports', 'Finanzberichte', 'Kann Finanzberichte einsehen', 'reporting_analytics', true, 'account_balance', NOW()),
('can_access_audit_logs', 'Audit-Logs', 'Kann Audit-Logs einsehen', 'reporting_analytics', true, 'fact_check', NOW()),
('can_export_reports', 'Berichte exportieren', 'Kann Berichte exportieren', 'reporting_analytics', false, 'file_download', NOW()),

-- 🔹 Status Management (Important)
('can_view_status_types', 'Status-Typen anzeigen', 'Kann Status-Typen anzeigen', 'status_management', false, 'category', NOW()),
('can_create_status_types', 'Status-Typen erstellen', 'Kann Status-Typen erstellen', 'status_management', true, 'add', NOW()),
('can_edit_status_types', 'Status-Typen bearbeiten', 'Kann Status-Typen bearbeiten', 'status_management', true, 'edit', NOW()),
('can_delete_status_types', 'Status-Typen löschen', 'Kann Status-Typen löschen', 'status_management', true, 'delete', NOW()),

-- 🔹 Gym Management (Important)
('can_view_gyms', 'Gyms anzeigen', 'Kann Gyms anzeigen', 'gym_management', false, 'fitness_center', NOW()),
('can_create_gyms', 'Gyms erstellen', 'Kann Gyms erstellen', 'gym_management', true, 'add', NOW()),
('can_edit_gyms', 'Gyms bearbeiten', 'Kann Gyms bearbeiten', 'gym_management', true, 'edit', NOW()),
('can_delete_gyms', 'Gyms löschen', 'Kann Gyms löschen', 'gym_management', true, 'delete', NOW());

-- ========================================
-- 3. 👥 ROLLEN-SYSTEM ERSTELLEN
-- ========================================

INSERT INTO roles (name, "displayName", description, "isSystemRole", "createdAt", "createdBy") VALUES
('Super Admin', 'Super Administrator', 'Vollzugriff auf alle Systemfunktionen', true, NOW(), 1),
('Facility Admin', 'Einrichtungsadministrator', 'Verwaltung einer spezifischen Einrichtung', true, NOW(), 1),
('Kassierer', 'Kassierer/in', 'Ticketverkauf und Kassenoperationen', true, NOW(), 1),
('Support Staff', 'Support-Mitarbeiter', 'Kundenbetreuung und grundlegende Operationen', true, NOW(), 1),
('Readonly User', 'Nur-Lese-Benutzer', 'Nur-Lese-Zugriff auf ausgewählte Bereiche', true, NOW(), 1);

-- ========================================
-- 4. 🔗 ROLLEN-PERMISSIONS ZUWEISUNGEN
-- ========================================

-- Super Admin bekommt ALLE Permissions
INSERT INTO role_permissions ("roleId", "permissionId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM roles WHERE name = 'Super Admin'),
    id,
    NOW(),
    1
FROM permissions;

-- Kassierer bekommt grundlegende Permissions
INSERT INTO role_permissions ("roleId", "permissionId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM roles WHERE name = 'Kassierer'),
    id,
    NOW(),
    1
FROM permissions 
WHERE name IN (
    'can_view_users', 'can_create_users', 'can_edit_users',
    'can_view_tickets', 'can_create_tickets', 'can_process_payments',
    'can_scan_tickets', 'can_validate_tickets',
    'can_view_facilities'
);

-- Support Staff bekommt erweiterte User-Management Permissions
INSERT INTO role_permissions ("roleId", "permissionId", "assignedAt", "assignedBy")
SELECT 
    (SELECT id FROM roles WHERE name = 'Support Staff'),
    id,
    NOW(),
    1
FROM permissions 
WHERE name IN (
    'can_view_users', 'can_create_users', 'can_edit_users', 'can_view_user_details',
    'can_view_tickets', 'can_edit_tickets', 'can_issue_refunds',
    'can_view_facilities', 'can_view_reports'
);

-- ========================================
-- 5. ✅ VERIFIKATION - Zeige Setup-Ergebnis
-- ========================================

SELECT 'SETUP COMPLETED' as status, 
       (SELECT COUNT(*) FROM permissions) as total_permissions,
       (SELECT COUNT(*) FROM roles) as total_roles,
       (SELECT COUNT(*) FROM role_permissions) as total_role_permissions;

-- Zeige alle Rollen mit Permission-Anzahl
SELECT 
    r.name as role_name,
    r."displayName",
    COUNT(p.id) as permission_count
FROM roles r
LEFT JOIN role_permissions rp ON r.id = rp."roleId"
LEFT JOIN permissions p ON rp."permissionId" = p.id
GROUP BY r.id, r.name, r."displayName"
ORDER BY permission_count DESC;

-- =====================================================
-- ✅ SETUP ABGESCHLOSSEN!
-- 📋 Nächster Schritt: Führe "02_CREATE_SUPERUSER.sql" aus
-- ===================================================== 