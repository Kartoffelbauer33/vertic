import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// **PermissionSeeder - Initialisiert Basis-Permissions**
///
/// Erstellt alle 50+ Permissions für das Kassensystem basierend auf den Endpoints:
/// - User Management (AppUser-Verwaltung)
/// - Staff Management (StaffUser-Verwaltung)
/// - Ticket Management (Ticket-Verkauf/Verwaltung)
/// - System Settings (Einstellungen/Konfiguration)
/// - Identity Management (QR-Codes/Validierung)
/// - Document Management (PDF-Dokumente)
/// - Billing Configuration (Abrechnungseinstellungen)
/// - Facility/Gym Management (Standort-Verwaltung)
/// - Printer Management (Kassendrucker)
/// - Reporting & Analytics (Berichte/Auswertungen)
class PermissionSeeder {
  /// **Haupt-Methode: Initialisiert alle Permissions**
  static Future<bool> seedPermissions(Session session) async {
    try {
      session.log('🌱 Starting Permission Seeding...');

      // Prüfe ob Permissions bereits existieren
      final existingCount = await Permission.db.count(session);
      if (existingCount > 0) {
        session.log(
            '⚠️ Permissions already exist ($existingCount found). Skipping seeding.');
        return true;
      }

      // Alle Permission-Kategorien seeden
      await _seedUserManagementPermissions(session);
      await _seedStaffManagementPermissions(session);
      await _seedTicketManagementPermissions(session);
      await _seedSystemSettingsPermissions(session);
      await _seedIdentityManagementPermissions(session);
      await _seedDocumentManagementPermissions(session);
      await _seedBillingConfigurationPermissions(session);
      await _seedFacilityGymManagementPermissions(session);
      await _seedPrinterManagementPermissions(session);
      await _seedReportingAnalyticsPermissions(session);

      final totalCount = await Permission.db.count(session);
      session.log(
          '✅ Permission Seeding completed! Created $totalCount permissions.');

      return true;
    } catch (e) {
      session.log('❌ Permission Seeding failed: $e', level: LogLevel.error);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 👥 USER MANAGEMENT PERMISSIONS (AppUser-Verwaltung)
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _seedUserManagementPermissions(Session session) async {
    final permissions = [
      // Basis User-Verwaltung
      _createPermission(
        'can_view_users',
        'Benutzer anzeigen',
        'Kann alle Benutzer im System einsehen',
        'user_management',
        iconName: 'people_outline',
        color: '#2196F3',
      ),
      _createPermission(
        'can_view_user_details',
        'Benutzer-Details anzeigen',
        'Kann detaillierte Informationen einzelner Benutzer einsehen',
        'user_management',
        iconName: 'person_outline',
        color: '#2196F3',
      ),
      _createPermission(
        'can_create_users',
        'Benutzer erstellen',
        'Kann neue Benutzer im System anlegen',
        'user_management',
        iconName: 'person_add',
        color: '#4CAF50',
      ),
      _createPermission(
        'can_edit_users',
        'Benutzer bearbeiten',
        'Kann Benutzerdaten bearbeiten und aktualisieren',
        'user_management',
        iconName: 'edit',
        color: '#FF9800',
      ),
      _createPermission(
        'can_delete_users',
        'Benutzer löschen',
        'Kann Benutzer permanent aus dem System entfernen',
        'user_management',
        iconName: 'delete_forever',
        color: '#F44336',
        isSystemCritical: true,
      ),

      // User Status/Blocking
      _createPermission(
        'can_block_users',
        'Benutzer blockieren',
        'Kann Benutzer temporär oder permanent blockieren',
        'user_management',
        iconName: 'block',
        color: '#FF5722',
      ),
      _createPermission(
        'can_unblock_users',
        'Benutzer entsperren',
        'Kann blockierte Benutzer wieder freischalten',
        'user_management',
        iconName: 'check_circle',
        color: '#4CAF50',
      ),

      // User Profile Management
      _createPermission(
        'can_view_user_profiles',
        'Profile anzeigen',
        'Kann Benutzerprofile mit Details einsehen',
        'user_management',
        iconName: 'account_circle',
        color: '#2196F3',
      ),
      _createPermission(
        'can_edit_user_profiles',
        'Profile bearbeiten',
        'Kann Benutzerprofile bearbeiten und aktualisieren',
        'user_management',
        iconName: 'edit',
        color: '#FF9800',
      ),
      _createPermission(
        'can_manage_profile_photos',
        'Profilbilder verwalten',
        'Kann Profilbilder hochladen, ändern und löschen',
        'user_management',
        iconName: 'photo_camera',
        color: '#9C27B0',
      ),
      _createPermission(
        'can_approve_users',
        'Benutzer freigeben',
        'Kann neue Benutzer freigeben oder ablehnen',
        'user_management',
        iconName: 'verified_user',
        color: '#4CAF50',
      ),

      // User Notes (CRM)
      _createPermission(
        'can_view_user_notes',
        'Notizen anzeigen',
        'Kann Benutzernotizen und CRM-Einträge einsehen',
        'user_management',
        iconName: 'note_alt',
        color: '#607D8B',
      ),
      _createPermission(
        'can_create_user_notes',
        'Notizen erstellen',
        'Kann neue Notizen zu Benutzern hinzufügen',
        'user_management',
        iconName: 'note_add',
        color: '#4CAF50',
      ),
      _createPermission(
        'can_edit_user_notes',
        'Notizen bearbeiten',
        'Kann bestehende Benutzernotizen bearbeiten',
        'user_management',
        iconName: 'edit_note',
        color: '#FF9800',
      ),
      _createPermission(
        'can_delete_user_notes',
        'Notizen löschen',
        'Kann Benutzernotizen löschen',
        'user_management',
        iconName: 'delete',
        color: '#F44336',
      ),

      // User Status Management
      _createPermission(
        'can_view_user_status_types',
        'Status-Typen anzeigen',
        'Kann verfügbare Benutzer-Status-Typen einsehen',
        'user_management',
        iconName: 'category',
        color: '#9C27B0',
      ),
      _createPermission(
        'can_view_user_statuses',
        'Benutzer-Status anzeigen',
        'Kann Status von Benutzern einsehen',
        'user_management',
        iconName: 'info',
        color: '#2196F3',
      ),
      _createPermission(
        'can_manage_user_statuses',
        'Benutzer-Status verwalten',
        'Kann Status von Benutzern ändern und verwalten',
        'user_management',
        iconName: 'toggle_on',
        color: '#FF9800',
      ),
    ];

    for (final permission in permissions) {
      await Permission.db.insertRow(session, permission);
    }

    session.log(
        '✅ User Management Permissions seeded (${permissions.length} permissions)');
  }

  // ═══════════════════════════════════════════════════════════════
  // 👨‍💼 STAFF MANAGEMENT PERMISSIONS (Personal-Verwaltung)
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _seedStaffManagementPermissions(Session session) async {
    final permissions = [
      // Staff User Basis-Verwaltung
      _createPermission(
        'can_view_staff_users',
        'Personal anzeigen',
        'Kann alle Mitarbeiter im System einsehen',
        'staff_management',
        iconName: 'badge',
        color: '#3F51B5',
      ),
      _createPermission(
        'can_create_staff_users',
        'Personal anlegen',
        'Kann neue Mitarbeiter anlegen',
        'staff_management',
        iconName: 'person_add',
        color: '#4CAF50',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_edit_staff_users',
        'Personal bearbeiten',
        'Kann Mitarbeiterdaten bearbeiten',
        'staff_management',
        iconName: 'edit',
        color: '#FF9800',
      ),
      _createPermission(
        'can_delete_staff_users',
        'Personal löschen',
        'Kann Mitarbeiter aus dem System entfernen',
        'staff_management',
        iconName: 'person_remove',
        color: '#F44336',
        isSystemCritical: true,
      ),

      // Permission Management (RBAC)
      _createPermission(
        'can_manage_permissions',
        'Berechtigungen verwalten',
        'Kann Berechtigungen an Mitarbeiter vergeben und entziehen',
        'staff_management',
        iconName: 'security',
        color: '#FF5722',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_view_staff_permissions',
        'Berechtigungen anzeigen',
        'Kann Berechtigungen von Mitarbeitern einsehen',
        'staff_management',
        iconName: 'visibility',
        color: '#607D8B',
      ),
      _createPermission(
        'can_manage_roles',
        'Rollen verwalten',
        'Kann Rollen erstellen, bearbeiten und zuweisen',
        'staff_management',
        iconName: 'group',
        color: '#9C27B0',
        isSystemCritical: true,
      ),

      // **ADMIN DASHBOARD ACCESS**
      _createPermission(
        'can_access_admin_dashboard',
        'Admin-Dashboard zugreifen',
        'Kann auf das Admin-Dashboard und erweiterte Verwaltungstools zugreifen',
        'staff_management',
        iconName: 'admin_panel_settings',
        color: '#E91E63',
        isSystemCritical: true,
      ),

      // HR-spezifische Permissions
      _createPermission(
        'can_view_staff_contracts',
        'Arbeitsverträge anzeigen',
        'Kann Arbeitsverträge und HR-Daten einsehen',
        'staff_management',
        iconName: 'description',
        color: '#795548',
      ),
      _createPermission(
        'can_manage_staff_salaries',
        'Gehälter verwalten',
        'Kann Gehaltsdaten bearbeiten und verwalten',
        'staff_management',
        iconName: 'attach_money',
        color: '#4CAF50',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_view_staff_schedules',
        'Dienstpläne anzeigen',
        'Kann Arbeitszeiten und Dienstpläne einsehen',
        'staff_management',
        iconName: 'schedule',
        color: '#2196F3',
      ),
    ];

    for (final permission in permissions) {
      await Permission.db.insertRow(session, permission);
    }

    session.log(
        '✅ Staff Management Permissions seeded (${permissions.length} permissions)');
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎫 TICKET MANAGEMENT PERMISSIONS (Kassensystem)
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _seedTicketManagementPermissions(Session session) async {
    final permissions = [
      // Ticket-Verkauf
      _createPermission(
        'can_sell_tickets',
        'Tickets verkaufen',
        'Kann Tickets an der Kasse verkaufen',
        'ticket_management',
        iconName: 'sell',
        color: '#4CAF50',
      ),
      _createPermission(
        'can_view_tickets',
        'Tickets anzeigen',
        'Kann verkaufte Tickets einsehen und anzeigen',
        'ticket_management',
        iconName: 'confirmation_number',
        color: '#2196F3',
      ),
      _createPermission(
        'can_view_all_tickets',
        'Alle Tickets anzeigen',
        'Kann alle Tickets im System einsehen (nicht nur eigene)',
        'ticket_management',
        iconName: 'list_alt',
        color: '#3F51B5',
      ),
      _createPermission(
        'can_validate_tickets',
        'Tickets validieren',
        'Kann Tickets beim Einlass prüfen und entwerten',
        'ticket_management',
        iconName: 'verified',
        color: '#4CAF50',
      ),

      // Ticket-Verwaltung
      _createPermission(
        'can_refund_tickets',
        'Tickets stornieren',
        'Kann Tickets stornieren und Rückerstattungen verarbeiten',
        'ticket_management',
        iconName: 'assignment_return',
        color: '#FF9800',
      ),
      _createPermission(
        'can_cancel_tickets',
        'Tickets annullieren',
        'Kann Tickets ungültig machen und annullieren',
        'ticket_management',
        iconName: 'cancel',
        color: '#F44336',
      ),
      _createPermission(
        'can_transfer_tickets',
        'Tickets übertragen',
        'Kann Tickets zwischen Kunden übertragen',
        'ticket_management',
        iconName: 'swap_horiz',
        color: '#9C27B0',
      ),

      // Abonnements
      _createPermission(
        'can_manage_subscriptions',
        'Abos verwalten',
        'Kann Abonnements erstellen, ändern und kündigen',
        'ticket_management',
        iconName: 'subscriptions',
        color: '#FF5722',
      ),
      _createPermission(
        'can_renew_subscriptions',
        'Abos verlängern',
        'Kann Abonnements verlängern und erneuern',
        'ticket_management',
        iconName: 'autorenew',
        color: '#4CAF50',
      ),

      // Punktekarten
      _createPermission(
        'can_recharge_point_cards',
        'Punktekarten aufladen',
        'Kann Punkte auf Punktekarten aufladen',
        'ticket_management',
        iconName: 'add_circle',
        color: '#2196F3',
      ),
      _createPermission(
        'can_view_point_balance',
        'Punktestand anzeigen',
        'Kann Punktestände von Kunden einsehen',
        'ticket_management',
        iconName: 'account_balance',
        color: '#607D8B',
      ),

      // Ticket-Typen-Verwaltung
      _createPermission(
        'can_manage_ticket_types',
        'Ticket-Typen verwalten',
        'Kann Ticket-Typen erstellen, bearbeiten und löschen',
        'ticket_management',
        iconName: 'category',
        color: '#9C27B0',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_view_ticket_pricing',
        'Preise anzeigen',
        'Kann Ticket-Preise und Preisgestaltung einsehen',
        'ticket_management',
        iconName: 'local_offer',
        color: '#FF9800',
      ),
      _createPermission(
        'can_edit_ticket_pricing',
        'Preise bearbeiten',
        'Kann Ticket-Preise ändern und anpassen',
        'ticket_management',
        iconName: 'edit',
        color: '#FF5722',
        isSystemCritical: true,
      ),
    ];

    for (final permission in permissions) {
      await Permission.db.insertRow(session, permission);
    }

    session.log(
        '✅ Ticket Management Permissions seeded (${permissions.length} permissions)');
  }

  // ═══════════════════════════════════════════════════════════════
  // ⚙️ SYSTEM SETTINGS PERMISSIONS
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _seedSystemSettingsPermissions(Session session) async {
    final permissions = [
      _createPermission(
        'can_view_system_settings',
        'Systemeinstellungen anzeigen',
        'Kann Systemeinstellungen einsehen',
        'system_settings',
        iconName: 'settings',
        color: '#607D8B',
      ),
      _createPermission(
        'can_edit_system_settings',
        'Systemeinstellungen bearbeiten',
        'Kann Systemeinstellungen ändern und anpassen',
        'system_settings',
        iconName: 'settings_applications',
        color: '#FF9800',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_reset_system_settings',
        'Einstellungen zurücksetzen',
        'Kann Systemeinstellungen auf Standard zurücksetzen',
        'system_settings',
        iconName: 'restore',
        color: '#F44336',
        isSystemCritical: true,
      ),
    ];

    for (final permission in permissions) {
      await Permission.db.insertRow(session, permission);
    }

    session.log(
        '✅ System Settings Permissions seeded (${permissions.length} permissions)');
  }

  // ═══════════════════════════════════════════════════════════════
  // 🆔 IDENTITY MANAGEMENT PERMISSIONS (QR-Codes)
  // ═══════════════════════════════════════════════════════════════

  static Future<void> _seedIdentityManagementPermissions(
      Session session) async {
    final permissions = [
      _createPermission(
        'can_manage_identity_settings',
        'QR-Einstellungen verwalten',
        'Kann QR-Code und Identitäts-Einstellungen verwalten',
        'identity_management',
        iconName: 'qr_code',
        color: '#9C27B0',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_force_qr_rotation',
        'QR-Rotation erzwingen',
        'Kann QR-Code-Rotation für User erzwingen',
        'identity_management',
        iconName: 'autorenew',
        color: '#FF5722',
      ),
      _createPermission(
        'can_validate_identity_qr',
        'QR-Codes validieren',
        'Kann QR-Codes von Kunden validieren und prüfen',
        'identity_management',
        iconName: 'verified',
        color: '#4CAF50',
      ),
    ];

    for (final permission in permissions) {
      await Permission.db.insertRow(session, permission);
    }

    session.log(
        '✅ Identity Management Permissions seeded (${permissions.length} permissions)');
  }

  // Weitere Permission-Kategorien folgen...
  // (Document Management, Billing Config, Facility/Gym, Printer, Reporting)

  // ═══════════════════════════════════════════════════════════════
  // 🗂️ PRIVATE HELPER METHODEN
  // ═══════════════════════════════════════════════════════════════

  static Permission _createPermission(
    String name,
    String displayName,
    String description,
    String category, {
    String? iconName,
    String? color,
    bool isSystemCritical = false,
  }) {
    return Permission(
      name: name,
      displayName: displayName,
      description: description,
      category: category,
      iconName: iconName,
      color: color,
      isSystemCritical: isSystemCritical,
      createdAt: DateTime.now(),
    );
  }

  // Restliche Seeder-Methoden werden im nächsten Teil implementiert...
  static Future<void> _seedDocumentManagementPermissions(
      Session session) async {
    final permissions = [
      _createPermission(
        'can_view_documents',
        'Dokumente anzeigen',
        'Kann Registrierungsdokumente und PDFs einsehen',
        'document_management',
        iconName: 'description',
        color: '#795548',
      ),
      _createPermission(
        'can_upload_documents',
        'Dokumente hochladen',
        'Kann neue Dokumente und PDFs hochladen',
        'document_management',
        iconName: 'upload_file',
        color: '#4CAF50',
      ),
      _createPermission(
        'can_edit_documents',
        'Dokumente bearbeiten',
        'Kann Dokumente bearbeiten und aktualisieren',
        'document_management',
        iconName: 'edit',
        color: '#FF9800',
      ),
      _createPermission(
        'can_delete_documents',
        'Dokumente löschen',
        'Kann Dokumente permanent löschen',
        'document_management',
        iconName: 'delete_forever',
        color: '#F44336',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_download_documents',
        'Dokumente herunterladen',
        'Kann Dokumente herunterladen und exportieren',
        'document_management',
        iconName: 'download',
        color: '#2196F3',
      ),
    ];

    for (final permission in permissions) {
      await Permission.db.insertRow(session, permission);
    }

    session.log(
        '✅ Document Management Permissions seeded (${permissions.length} permissions)');
  }

  static Future<void> _seedBillingConfigurationPermissions(
      Session session) async {
    final permissions = [
      _createPermission(
        'can_view_billing_config',
        'Abrechnungsconfig anzeigen',
        'Kann Abrechnungskonfigurationen einsehen',
        'billing_management',
        iconName: 'receipt_long',
        color: '#4CAF50',
      ),
      _createPermission(
        'can_edit_billing_config',
        'Abrechnungsconfig bearbeiten',
        'Kann Abrechnungseinstellungen ändern',
        'billing_management',
        iconName: 'edit',
        color: '#FF9800',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_create_billing_config',
        'Abrechnungsconfig erstellen',
        'Kann neue Abrechnungskonfigurationen erstellen',
        'billing_management',
        iconName: 'add_circle',
        color: '#4CAF50',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_delete_billing_config',
        'Abrechnungsconfig löschen',
        'Kann Abrechnungskonfigurationen löschen',
        'billing_management',
        iconName: 'delete',
        color: '#F44336',
        isSystemCritical: true,
      ),
    ];

    for (final permission in permissions) {
      await Permission.db.insertRow(session, permission);
    }

    session.log(
        '✅ Billing Configuration Permissions seeded (${permissions.length} permissions)');
  }

  static Future<void> _seedFacilityGymManagementPermissions(
      Session session) async {
    final permissions = [
      // Facility Management
      _createPermission(
        'can_view_facilities',
        'Standorte anzeigen',
        'Kann alle Standorte und Einrichtungen einsehen',
        'facility_management',
        iconName: 'business',
        color: '#3F51B5',
      ),
      _createPermission(
        'can_create_facilities',
        'Standorte erstellen',
        'Kann neue Standorte anlegen',
        'facility_management',
        iconName: 'add_business',
        color: '#4CAF50',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_edit_facilities',
        'Standorte bearbeiten',
        'Kann Standort-Daten bearbeiten',
        'facility_management',
        iconName: 'edit',
        color: '#FF9800',
      ),
      _createPermission(
        'can_delete_facilities',
        'Standorte löschen',
        'Kann Standorte löschen',
        'facility_management',
        iconName: 'delete_forever',
        color: '#F44336',
        isSystemCritical: true,
      ),

      // Gym Management
      _createPermission(
        'can_view_gyms',
        'Hallen anzeigen',
        'Kann alle Kletter-/Boulderhallen einsehen',
        'facility_management',
        iconName: 'fitness_center',
        color: '#2196F3',
      ),
      _createPermission(
        'can_create_gyms',
        'Hallen erstellen',
        'Kann neue Hallen anlegen',
        'facility_management',
        iconName: 'add',
        color: '#4CAF50',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_edit_gyms',
        'Hallen bearbeiten',
        'Kann Hallen-Daten bearbeiten',
        'facility_management',
        iconName: 'edit',
        color: '#FF9800',
      ),
      _createPermission(
        'can_delete_gyms',
        'Hallen löschen',
        'Kann Hallen löschen',
        'facility_management',
        iconName: 'delete',
        color: '#F44336',
        isSystemCritical: true,
      ),
    ];

    for (final permission in permissions) {
      await Permission.db.insertRow(session, permission);
    }

    session.log(
        '✅ Facility/Gym Management Permissions seeded (${permissions.length} permissions)');
  }

  static Future<void> _seedPrinterManagementPermissions(Session session) async {
    final permissions = [
      _createPermission(
        'can_view_printer_settings',
        'Drucker-Einstellungen anzeigen',
        'Kann Kassendrucker-Konfigurationen einsehen',
        'printer_management',
        iconName: 'print',
        color: '#607D8B',
      ),
      _createPermission(
        'can_manage_printers',
        'Drucker verwalten',
        'Kann Kassendrucker konfigurieren und verwalten',
        'printer_management',
        iconName: 'settings',
        color: '#FF9800',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_test_printers',
        'Drucker testen',
        'Kann Testdrucke durchführen',
        'printer_management',
        iconName: 'print',
        color: '#4CAF50',
      ),
      _createPermission(
        'can_configure_receipt_layout',
        'Kassenbon-Layout konfigurieren',
        'Kann Layout und Format der Kassenbons anpassen',
        'printer_management',
        iconName: 'receipt',
        color: '#9C27B0',
      ),
    ];

    for (final permission in permissions) {
      await Permission.db.insertRow(session, permission);
    }

    session.log(
        '✅ Printer Management Permissions seeded (${permissions.length} permissions)');
  }

  static Future<void> _seedReportingAnalyticsPermissions(
      Session session) async {
    final permissions = [
      // Basis-Reporting
      _createPermission(
        'can_view_reports',
        'Berichte anzeigen',
        'Kann Standard-Berichte und Auswertungen einsehen',
        'reporting_analytics',
        iconName: 'assessment',
        color: '#2196F3',
      ),
      _createPermission(
        'can_export_reports',
        'Berichte exportieren',
        'Kann Berichte als PDF/Excel exportieren',
        'reporting_analytics',
        iconName: 'file_download',
        color: '#4CAF50',
      ),

      // Finanz-Reporting
      _createPermission(
        'can_view_financial_reports',
        'Finanzberichte anzeigen',
        'Kann Umsatz- und Finanzberichte einsehen',
        'reporting_analytics',
        iconName: 'account_balance',
        color: '#4CAF50',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_view_daily_reports',
        'Tagesberichte anzeigen',
        'Kann Tagesabschlüsse und Kassenberichte einsehen',
        'reporting_analytics',
        iconName: 'today',
        color: '#FF9800',
      ),
      _createPermission(
        'can_view_monthly_reports',
        'Monatsberichte anzeigen',
        'Kann Monatsauswertungen und Statistiken einsehen',
        'reporting_analytics',
        iconName: 'calendar_month',
        color: '#9C27B0',
      ),

      // Analytics
      _createPermission(
        'can_view_user_analytics',
        'Kunden-Analytics anzeigen',
        'Kann Kundenstatistiken und -analysen einsehen',
        'reporting_analytics',
        iconName: 'people',
        color: '#3F51B5',
      ),
      _createPermission(
        'can_view_ticket_analytics',
        'Ticket-Analytics anzeigen',
        'Kann Ticketverkauf-Statistiken einsehen',
        'reporting_analytics',
        iconName: 'confirmation_number',
        color: '#FF5722',
      ),
      _createPermission(
        'can_view_performance_metrics',
        'Performance-Metriken anzeigen',
        'Kann System-Performance und Metriken einsehen',
        'reporting_analytics',
        iconName: 'speed',
        color: '#607D8B',
      ),

      // Export & Backup
      _createPermission(
        'can_create_data_exports',
        'Daten-Exporte erstellen',
        'Kann umfangreiche Datenexporte erstellen',
        'reporting_analytics',
        iconName: 'backup',
        color: '#795548',
        isSystemCritical: true,
      ),
      _createPermission(
        'can_access_audit_logs',
        'Audit-Logs einsehen',
        'Kann System-Audit-Logs und Protokolle einsehen',
        'reporting_analytics',
        iconName: 'history',
        color: '#9E9E9E',
        isSystemCritical: true,
      ),
    ];

    for (final permission in permissions) {
      await Permission.db.insertRow(session, permission);
    }

    session.log(
        '✅ Reporting & Analytics Permissions seeded (${permissions.length} permissions)');
  }
}
