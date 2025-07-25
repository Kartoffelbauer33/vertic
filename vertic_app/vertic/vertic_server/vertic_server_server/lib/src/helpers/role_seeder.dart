import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// **RoleSeeder - Initialisiert NUR die Superuser-Systemrolle**
///
/// Erstellt nur noch die eine Systemrolle:
/// - Super Administrator (System-Vollzugriff, nicht löschbar)
///
/// Alle anderen Rollen werden von Superusern manuell erstellt.
/// Keine hardcodierten Standard-Rollen mehr!
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

      // NUR Superuser-Systemrolle erstellen
      await _createSuperAdminRole(session);
      
      // Alle anderen Rollen werden von Superusern manuell erstellt!

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
  // 🚫 ALLE ANDEREN ROLLEN ENTFERNT
  // ═══════════════════════════════════════════════════════════════
  // Nur noch Superuser als Systemrolle!
  // Alle anderen Rollen werden von Superusern manuell erstellt.

  // ═══════════════════════════════════════════════════════════════
  // 🔧 HELPER METHODEN
  // ═══════════════════════════════════════════════════════════════
  // Alle Helper-Methoden entfernt, da nur noch Superuser erstellt wird

  /// **Holt Standard-Rolle für neue StaffUser**
  /// Da es keine Standard-Rollen mehr gibt, gibt null zurück
  static Future<Role?> getDefaultRole(Session session) async {
    try {
      // Keine Standard-Rolle mehr - Superuser muss Rollen manuell zuweisen
      session.log('ℹ️ No default role available - roles must be assigned manually by superuser');
      return null;
    } catch (e) {
      session.log('❌ Failed to get default role: $e', level: LogLevel.error);
      return null;
    }
  }
}
