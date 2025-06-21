import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// **RoleSeeder - Initialisiert Standard-Rollen**
///
/// Erstellt die Basis-Rollen für das Kassensystem:
/// - Super Admin (System-Vollzugriff)
/// - Facility Admin (Standort-Verwaltung)
/// - Kassierer (Ticketverkauf & Kasse)
/// - Support Staff (Kundenbetreuung)
/// - Readonly User (Nur-Lese-Zugriff)
///
/// Jede Rolle bekommt logische Permission-Bundles zugewiesen.
class RoleSeeder {
  /// **Haupt-Methode: Initialisiert alle Standard-Rollen**
  static Future<bool> seedRoles(Session session) async {
    try {
      session.log('🎭 Starting Role Seeding...');

      // Prüfe ob Rollen bereits existieren
      final existingCount = await Role.db.count(session);
      if (existingCount > 0) {
        session.log(
            '⚠️ Roles already exist ($existingCount found). Skipping seeding.');
        return true;
      }

      // Prüfe ob Permissions existieren
      final permissionCount = await Permission.db.count(session);
      if (permissionCount == 0) {
        throw Exception(
            'Keine Permissions gefunden! Bitte zuerst Permission-Seeding durchführen.');
      }

      // Standard-Rollen erstellen
      await _createSuperAdminRole(session);
      await _createFacilityAdminRole(session);
      await _createKassiererRole(session);
      await _createSupportStaffRole(session);
      await _createReadonlyUserRole(session);

      final totalCount = await Role.db.count(session);
      session.log('✅ Role Seeding completed! Created $totalCount roles.');

      return true;
    } catch (e) {
      session.log('❌ Role Seeding failed: $e', level: LogLevel.error);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 👑 SUPER ADMIN ROLE (System-Vollzugriff)
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _createSuperAdminRole(Session session) async {
    // Rolle erstellen
    final role = Role(
      name: 'super_admin',
      displayName: 'Super Administrator',
      description:
          'Vollzugriff auf alle Systemfunktionen. Kann alle Berechtigungen verwalten und kritische Systemeinstellungen ändern.',
      color: '#D32F2F', // Rot - hohe Berechtigung
      iconName: 'admin_panel_settings',
      isSystemRole: true, // Kann nicht gelöscht werden
      isActive: true,
      sortOrder: 1, // Höchste Priorität
      createdAt: DateTime.now(),
      createdBy: 1, // System-User
    );

    final savedRole = await Role.db.insertRow(session, role);
    session.log('✅ Created role: ${savedRole.displayName}');

    // ALLE Permissions zuweisen (Super Admin hat alles)
    final allPermissions = await Permission.db.find(session);

    for (final permission in allPermissions) {
      await RolePermission.db.insertRow(
          session,
          RolePermission(
            roleId: savedRole.id!,
            permissionId: permission.id!,
            assignedAt: DateTime.now(),
            assignedBy: 1, // System-User
          ));
    }

    session
        .log('🔐 Super Admin: ${allPermissions.length} permissions assigned');
  }

  // ═══════════════════════════════════════════════════════════════
  // 🏢 FACILITY ADMIN ROLE (Standort-Verwaltung)
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _createFacilityAdminRole(Session session) async {
    final role = Role(
      name: 'facility_admin',
      displayName: 'Facility Administrator',
      description:
          'Verwaltung eines Standorts. Kann Personal, Kassen, Tickets und lokale Einstellungen verwalten.',
      color: '#1976D2', // Blau - Management
      iconName: 'business',
      isSystemRole: true,
      isActive: true,
      sortOrder: 2,
      createdAt: DateTime.now(),
      createdBy: 1,
    );

    final savedRole = await Role.db.insertRow(session, role);
    session.log('✅ Created role: ${savedRole.displayName}');

    // Permission-Bundle für Facility Admin
    final facilityAdminPermissions = [
      // Staff Management (ohne kritische System-Permissions)
      'can_view_staff_users',
      'can_create_staff_users',
      'can_edit_staff_users',
      'can_view_staff_permissions',
      'can_view_staff_schedules',

      // User Management
      'can_view_users',
      'can_view_user_details',
      'can_create_users',
      'can_edit_users',
      'can_block_users',
      'can_unblock_users',
      'can_view_user_profiles',
      'can_edit_user_profiles',
      'can_view_user_notes',
      'can_create_user_notes',
      'can_edit_user_notes',

      // Ticket Management (komplett)
      'can_sell_tickets',
      'can_view_tickets',
      'can_validate_tickets',
      'can_refund_tickets',
      'can_cancel_tickets',
      'can_transfer_tickets',
      'can_manage_subscriptions',
      'can_renew_subscriptions',
      'can_recharge_point_cards',
      'can_view_point_balance',
      'can_manage_ticket_types',
      'can_view_ticket_pricing',
      'can_edit_ticket_pricing',

      // Facility/Gym Management
      'can_view_facilities',
      'can_edit_facilities',
      'can_view_gyms',
      'can_create_gyms',
      'can_edit_gyms',

      // System Settings (eingeschränkt)
      'can_view_system_settings',

      // Document Management
      'can_view_documents',
      'can_upload_documents',
      'can_edit_documents',
      'can_download_documents',

      // Billing Configuration
      'can_view_billing_config',
      'can_edit_billing_config',
      'can_create_billing_config',

      // Identity Management
      'can_validate_identity_qr',
      'can_force_qr_rotation',

      // Printer Management
      'can_view_printer_settings',
      'can_manage_printers',
      'can_test_printers',
      'can_configure_receipt_layout',

      // Reporting & Analytics
      'can_view_reports',
      'can_export_reports',
      'can_view_financial_reports',
      'can_view_daily_reports',
      'can_view_monthly_reports',
      'can_view_user_analytics',
      'can_view_ticket_analytics',
    ];

    await _assignPermissionsToRole(
        session, savedRole.id!, facilityAdminPermissions);
    session.log(
        '🔐 Facility Admin: ${facilityAdminPermissions.length} permissions assigned');
  }

  // ═══════════════════════════════════════════════════════════════
  // 💰 KASSIERER ROLE (Ticketverkauf & Kasse)
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _createKassiererRole(Session session) async {
    final role = Role(
      name: 'kassierer',
      displayName: 'Kassierer',
      description:
          'Ticketverkauf, Kundenbetreuung und Kassenfunktionen. Kern-Rolle für den täglichen Betrieb.',
      color: '#4CAF50', // Grün - operative Rolle
      iconName: 'point_of_sale',
      isSystemRole: true,
      isActive: true,
      sortOrder: 3,
      createdAt: DateTime.now(),
      createdBy: 1,
    );

    final savedRole = await Role.db.insertRow(session, role);
    session.log('✅ Created role: ${savedRole.displayName}');

    // Permission-Bundle für Kassierer
    final kassiererPermissions = [
      // Ticket Management (Verkauf & Validierung)
      'can_sell_tickets',
      'can_view_tickets',
      'can_validate_tickets',
      'can_refund_tickets',
      'can_recharge_point_cards',
      'can_view_point_balance',
      'can_renew_subscriptions',
      'can_view_ticket_pricing',

      // User Management (eingeschränkt)
      'can_view_users',
      'can_view_user_details',
      'can_view_user_profiles',
      'can_view_user_notes',
      'can_create_user_notes',

      // Identity Management
      'can_validate_identity_qr',

      // Document Management (nur Anzeige)
      'can_view_documents',
      'can_download_documents',

      // Reporting (nur Tagesberichte)
      'can_view_reports',
      'can_view_daily_reports',
    ];

    await _assignPermissionsToRole(
        session, savedRole.id!, kassiererPermissions);
    session.log(
        '🔐 Kassierer: ${kassiererPermissions.length} permissions assigned');
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎧 SUPPORT STAFF ROLE (Kundenbetreuung)
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _createSupportStaffRole(Session session) async {
    final role = Role(
      name: 'support_staff',
      displayName: 'Support Mitarbeiter',
      description:
          'Kundenbetreuung, Problemlösung und grundlegende Verwaltungsaufgaben.',
      color: '#FF9800', // Orange - Support
      iconName: 'support_agent',
      isSystemRole: true,
      isActive: true,
      sortOrder: 4,
      createdAt: DateTime.now(),
      createdBy: 1,
    );

    final savedRole = await Role.db.insertRow(session, role);
    session.log('✅ Created role: ${savedRole.displayName}');

    // Permission-Bundle für Support Staff
    final supportPermissions = [
      // User Management (erweitert)
      'can_view_users',
      'can_view_user_details',
      'can_edit_users',
      'can_view_user_profiles',
      'can_edit_user_profiles',
      'can_view_user_notes',
      'can_create_user_notes',
      'can_edit_user_notes',

      // Ticket Management (Support)
      'can_view_tickets',
      'can_validate_tickets',
      'can_transfer_tickets',
      'can_view_point_balance',
      'can_view_ticket_pricing',

      // Identity Management
      'can_validate_identity_qr',
      'can_force_qr_rotation',

      // Document Management
      'can_view_documents',
      'can_download_documents',

      // Reporting (Analytics)
      'can_view_reports',
      'can_view_user_analytics',
      'can_view_ticket_analytics',
    ];

    await _assignPermissionsToRole(session, savedRole.id!, supportPermissions);
    session.log(
        '🔐 Support Staff: ${supportPermissions.length} permissions assigned');
  }

  // ═══════════════════════════════════════════════════════════════
  // 👁️ READONLY USER ROLE (Nur-Lese-Zugriff)
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _createReadonlyUserRole(Session session) async {
    final role = Role(
      name: 'readonly_user',
      displayName: 'Readonly User',
      description:
          'Nur-Lese-Zugriff für Einblicke und Reporting. Keine Änderungen möglich.',
      color: '#607D8B', // Grau - nur Lesen
      iconName: 'visibility',
      isSystemRole: false, // Kann gelöscht werden
      isActive: true,
      sortOrder: 5,
      createdAt: DateTime.now(),
      createdBy: 1,
    );

    final savedRole = await Role.db.insertRow(session, role);
    session.log('✅ Created role: ${savedRole.displayName}');

    // Permission-Bundle für Readonly User (nur Anzeige-Permissions)
    final readonlyPermissions = [
      'can_view_users',
      'can_view_user_details',
      'can_view_user_profiles',
      'can_view_user_notes',
      'can_view_tickets',
      'can_view_point_balance',
      'can_view_ticket_pricing',
      'can_view_documents',
      'can_view_system_settings',
      'can_view_billing_config',
      'can_view_facilities',
      'can_view_gyms',
      'can_view_printer_settings',
      'can_view_reports',
      'can_view_daily_reports',
      'can_view_monthly_reports',
      'can_view_user_analytics',
      'can_view_ticket_analytics',
      'can_view_performance_metrics',
    ];

    await _assignPermissionsToRole(session, savedRole.id!, readonlyPermissions);
    session.log(
        '🔐 Readonly User: ${readonlyPermissions.length} permissions assigned');
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔧 HELPER METHODEN
  // ═══════════════════════════════════════════════════════════════

  /// **Weist Permission-Liste einer Rolle zu**
  static Future<void> _assignPermissionsToRole(
    Session session,
    int roleId,
    List<String> permissionNames,
  ) async {
    for (final permissionName in permissionNames) {
      // Finde Permission by Name
      final permission = await Permission.db.findFirstRow(
        session,
        where: (t) => t.name.equals(permissionName),
      );

      if (permission != null) {
        // Prüfe ob bereits zugewiesen
        final existing = await RolePermission.db.findFirstRow(
          session,
          where: (t) =>
              t.roleId.equals(roleId) & t.permissionId.equals(permission.id!),
        );

        if (existing == null) {
          await RolePermission.db.insertRow(
              session,
              RolePermission(
                roleId: roleId,
                permissionId: permission.id!,
                assignedAt: DateTime.now(),
                assignedBy: 1, // System-User
              ));
        }
      } else {
        session.log('⚠️ Permission not found: $permissionName',
            level: LogLevel.warning);
      }
    }
  }

  /// **Holt Standard-Rolle für neue StaffUser**
  static Future<Role?> getDefaultRole(Session session) async {
    try {
      // Default ist "Kassierer" - die häufigste Rolle
      final defaultRole = await Role.db.findFirstRow(
        session,
        where: (t) => t.name.equals('kassierer') & t.isActive.equals(true),
      );

      return defaultRole;
    } catch (e) {
      session.log('❌ Failed to get default role: $e', level: LogLevel.error);
      return null;
    }
  }
}
