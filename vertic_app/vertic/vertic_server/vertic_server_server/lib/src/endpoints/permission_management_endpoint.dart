import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../helpers/permission_seeder.dart';
import '../helpers/role_seeder.dart';
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';

/// **Permission Management Endpoint**
///
/// Verwaltet das RBAC-System:
/// - Permission-Seeding (erstmalige Initialisierung)
/// - Permission-Verwaltung (CRUD-Operationen)
/// - Role-Management
/// - Berechtigungs-Zuweisungen
class PermissionManagementEndpoint extends Endpoint {
  /// **Initialisiert alle Basis-Permissions (50+ Permissions)**
  ///
  /// Nur für SuperUser oder bei leerem System verfügbar
  Future<bool> seedPermissions(Session session) async {
    try {
      // Prüfe ob bereits Permissions existieren
      final existingCount = await Permission.db.count(session);

      if (existingCount > 0) {
        session.log(
            '⚠️ Permissions already exist ($existingCount found). Aborting seed.');
        throw Exception('Permissions bereits vorhanden. Seeding abgebrochen.');
      }

      // Permissions seeden
      final success = await PermissionSeeder.seedPermissions(session);

      if (success) {
        final totalCount = await Permission.db.count(session);
        session.log(
            '✅ Permission Seeding erfolgreich! $totalCount Permissions erstellt.');
        return true;
      } else {
        throw Exception('Permission Seeding fehlgeschlagen');
      }
    } catch (e) {
      session.log('❌ seedPermissions Error: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Initialisiert alle Standard-Rollen mit Permission-Bundles**
  Future<bool> seedRoles(Session session) async {
    try {
      // Prüfe ob bereits Rollen existieren
      final existingCount = await Role.db.count(session);

      if (existingCount > 0) {
        session.log(
            '⚠️ Roles already exist ($existingCount found). Aborting seed.');
        throw Exception('Rollen bereits vorhanden. Seeding abgebrochen.');
      }

      // Rollen seeden
      final success = await RoleSeeder.seedRoles(session);

      if (success) {
        final totalCount = await Role.db.count(session);
        session.log('✅ Role Seeding erfolgreich! $totalCount Rollen erstellt.');
        return true;
      } else {
        throw Exception('Role Seeding fehlgeschlagen');
      }
    } catch (e) {
      session.log('❌ seedRoles Error: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Komplettes RBAC-System-Seeding (Permissions + Roles)**
  Future<bool> seedCompleteRBAC(Session session) async {
    try {
      session.log('🚀 Starting complete RBAC seeding...');

      // 1. Permissions seeden
      final permissionsSuccess = await seedPermissions(session);
      if (!permissionsSuccess) {
        throw Exception('Permission seeding failed');
      }

      // 2. Rollen seeden
      final rolesSuccess = await seedRoles(session);
      if (!rolesSuccess) {
        throw Exception('Role seeding failed');
      }

      session.log('🎉 Complete RBAC seeding successful!');
      return true;
    } catch (e) {
      session.log('❌ seedCompleteRBAC Error: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Holt alle verfügbaren Permissions**
  Future<List<Permission>> getAllPermissions(Session session) async {
    try {
      // TODO: Hier sollte Permission-Check rein: can_view_permissions
      // await PermissionHelper.requirePermission(session, 'can_view_permissions');

      final permissions = await Permission.db.find(session);

      session.log('📋 Retrieved ${permissions.length} permissions');
      return permissions;
    } catch (e) {
      session.log('❌ getAllPermissions Error: $e', level: LogLevel.error);
      return [];
    }
  }

  /// **🧽 BEREINIGUNG: Entfernt alle alten Systemrollen außer Superuser**
  ///
  /// Diese Methode:
  /// 1. Löscht alle Systemrollen außer 'super_admin'
  /// 2. Stellt sicher, dass Superuser ALLE Permissions hat
  /// 3. Behebt das Problem mit fehlenden CRUD-Buttons
  Future<bool> cleanupOldSystemRoles(Session session) async {
    try {
      session.log('🧽 Starting cleanup of old system roles...');

      // 1. Finde alle Systemrollen außer super_admin
      final oldSystemRoles = await Role.db.find(
        session,
        where: (t) =>
            t.isSystemRole.equals(true) & t.name.notEquals('super_admin'),
      );

      session
          .log('🔍 Found ${oldSystemRoles.length} old system roles to remove');

      // 2. Lösche alte Systemrollen und ihre Permissions
      for (final role in oldSystemRoles) {
        // Erst alle RolePermissions löschen
        await RolePermission.db.deleteWhere(
          session,
          where: (t) => t.roleId.equals(role.id!),
        );

        // Dann alle StaffUserRoles löschen
        await StaffUserRole.db.deleteWhere(
          session,
          where: (t) => t.roleId.equals(role.id!),
        );

        // Schließlich die Rolle selbst löschen
        await Role.db.deleteRow(session, role);
        session.log('❌ Removed old system role: ${role.displayName}');
      }

      // 4. Finale Statistik
      final remainingRoles = await Role.db.count(session);
      session.log('✅ Cleanup completed! Remaining roles: $remainingRoles');

      return true;
    } catch (e) {
      session.log('❌ cleanupOldSystemRoles Error: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Holt Permissions nach Kategorie**
  Future<List<Permission>> getPermissionsByCategory(
    Session session,
    String category,
  ) async {
    try {
      final permissions = await Permission.db.find(
        session,
        where: (t) => t.category.equals(category),
        orderBy: (t) => t.displayName,
      );

      session.log(
          '📂 Retrieved ${permissions.length} permissions for category: $category');
      return permissions;
    } catch (e) {
      session.log('❌ getPermissionsByCategory Error: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// **Erstellt eine neue Permission**
  Future<Permission?> createPermission(
    Session session,
    Permission permission,
  ) async {
    try {
      // TODO: Permission-Check: can_create_permissions
      // await PermissionHelper.requirePermission(session, 'can_create_permissions');

      // Prüfe auf doppelte Namen
      final existing = await Permission.db.findFirstRow(
        session,
        where: (t) => t.name.equals(permission.name),
      );

      if (existing != null) {
        throw Exception(
            'Permission mit Namen "${permission.name}" existiert bereits');
      }

      // Timestamps setzen
      permission.createdAt = DateTime.now();

      final newPermission = await Permission.db.insertRow(session, permission);

      session.log('✅ Permission created: ${newPermission.name}');
      return newPermission;
    } catch (e) {
      session.log('❌ createPermission Error: $e', level: LogLevel.error);
      return null;
    }
  }

  /// **Aktualisiert eine Permission**
  Future<Permission?> updatePermission(
    Session session,
    Permission permission,
  ) async {
    try {
      // TODO: Permission-Check: can_edit_permissions
      // await PermissionHelper.requirePermission(session, 'can_edit_permissions');

      // Prüfe ob Permission existiert
      final existing = await Permission.db.findById(session, permission.id!);
      if (existing == null) {
        throw Exception('Permission nicht gefunden');
      }

      // Timestamps setzen
      permission.updatedAt = DateTime.now();

      final updatedPermission =
          await Permission.db.updateRow(session, permission);

      session.log('✅ Permission updated: ${updatedPermission.name}');
      return updatedPermission;
    } catch (e) {
      session.log('❌ updatePermission Error: $e', level: LogLevel.error);
      return null;
    }
  }

  /// **Löscht eine Permission (VORSICHT!)**
  Future<bool> deletePermission(Session session, int permissionId) async {
    try {
      // TODO: Permission-Check: can_delete_permissions (SuperUser only)
      // await PermissionHelper.requirePermission(session, 'can_delete_permissions');

      // Prüfe ob Permission in Verwendung
      final usageCount = await StaffUserPermission.db.count(
        session,
        where: (t) => t.permissionId.equals(permissionId),
      );

      if (usageCount > 0) {
        throw Exception(
            'Permission kann nicht gelöscht werden - noch $usageCount Zuweisungen vorhanden');
      }

      final roleUsageCount = await RolePermission.db.count(
        session,
        where: (t) => t.permissionId.equals(permissionId),
      );

      if (roleUsageCount > 0) {
        throw Exception(
            'Permission kann nicht gelöscht werden - noch $roleUsageCount Rollen-Zuweisungen vorhanden');
      }

      // Permission löschen (Serverpod 2.8 Syntax)
      final deleted = await Permission.db
          .deleteWhere(session, where: (t) => t.id.equals(permissionId));

      if (deleted == 0) {
        throw Exception('Permission nicht gefunden');
      }

      session.log('✅ Permission deleted: ID $permissionId');
      return true;
    } catch (e) {
      session.log('❌ cleanupOldSystemRoles Error: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Holt alle verfügbaren Rollen**
  Future<List<Role>> getAllRoles(Session session) async {
    try {
      final roles = await Role.db.find(
        session,
        orderBy: (t) => t.sortOrder,
      );

      session.log('🎭 Retrieved ${roles.length} roles');
      return roles;
    } catch (e) {
      session.log('❌ getAllRoles Error: $e', level: LogLevel.error);
      return [];
    }
  }

  /// **Holt nur aktive Rollen**
  Future<List<Role>> getActiveRoles(Session session) async {
    try {
      final roles = await Role.db.find(
        session,
        where: (t) => t.isActive.equals(true),
        orderBy: (t) => t.sortOrder,
      );

      session.log('🎭 Retrieved ${roles.length} active roles');
      return roles;
    } catch (e) {
      session.log('❌ getActiveRoles Error: $e', level: LogLevel.error);
      return [];
    }
  }

  /// **Erstellt eine neue Rolle**
  Future<Role?> createRole(Session session, Role role) async {
    try {
      // TODO: Permission-Check: can_create_roles
      // await PermissionHelper.requirePermission(session, 'can_create_roles');

      // Prüfe auf doppelte Namen
      final existing = await Role.db.findFirstRow(
        session,
        where: (t) => t.name.equals(role.name),
      );

      if (existing != null) {
        throw Exception('Rolle mit Namen "${role.name}" existiert bereits');
      }

      // Timestamps setzen
      role.createdAt = DateTime.now();

      // Aktuelle Staff-User-ID ermitteln (REQUIRED für Roles)
      final currentStaffUserId =
          await StaffAuthHelper.getAuthenticatedStaffUserId(session);
      if (currentStaffUserId == null) {
        throw Exception(
            'Keine gültige Staff-Authentifizierung gefunden - Rollen-Erstellung erfordert Staff-Login');
      }
      role.createdBy = currentStaffUserId;

      final newRole = await Role.db.insertRow(session, role);

      session.log('✅ Role created: ${newRole.displayName}');
      return newRole;
    } catch (e) {
      session.log('❌ createRole Error: $e', level: LogLevel.error);
      return null;
    }
  }

  /// **Aktualisiert eine Rolle**
  Future<Role?> updateRole(Session session, Role role) async {
    try {
      // TODO: Permission-Check: can_edit_roles
      // await PermissionHelper.requirePermission(session, 'can_edit_roles');

      // Prüfe ob Rolle existiert
      final existing = await Role.db.findById(session, role.id!);
      if (existing == null) {
        throw Exception('Rolle nicht gefunden');
      }

      // System-Rollen schützen
      if (existing.isSystemRole && role.name != existing.name) {
        throw Exception('System-Rollen können nicht umbenannt werden');
      }

      // Timestamps setzen
      role.updatedAt = DateTime.now();

      final updatedRole = await Role.db.updateRow(session, role);

      session.log('✅ Role updated: ${updatedRole.displayName}');
      return updatedRole;
    } catch (e) {
      session.log('❌ updateRole Error: $e', level: LogLevel.error);
      return null;
    }
  }

  /// **Löscht eine Rolle (VORSICHT!)**
  Future<bool> deleteRole(Session session, int roleId) async {
    try {
      // TODO: Permission-Check: can_delete_roles (SuperUser only)
      // await PermissionHelper.requirePermission(session, 'can_delete_roles');

      // Prüfe ob Rolle existiert
      final role = await Role.db.findById(session, roleId);
      if (role == null) {
        throw Exception('Rolle nicht gefunden');
      }

      // System-Rollen schützen
      if (role.isSystemRole) {
        throw Exception('System-Rollen können nicht gelöscht werden');
      }

      // Prüfe ob Rolle in Verwendung
      final usageCount = await StaffUserRole.db.count(
        session,
        where: (t) => t.roleId.equals(roleId),
      );

      if (usageCount > 0) {
        throw Exception(
            'Rolle kann nicht gelöscht werden - noch $usageCount Zuweisungen vorhanden');
      }

      // Erst Role-Permissions löschen
      await RolePermission.db.deleteWhere(
        session,
        where: (t) => t.roleId.equals(roleId),
      );

      // Dann Rolle löschen
      final deleted =
          await Role.db.deleteWhere(session, where: (t) => t.id.equals(roleId));

      if (deleted == 0) {
        throw Exception('Rolle nicht gefunden');
      }

      session.log('✅ Role deleted: ${role.displayName}');
      return true;
    } catch (e) {
      session.log('❌ deleteRole Error: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Weist Permission an Rolle zu**
  Future<bool> assignPermissionToRole(
    Session session,
    int roleId,
    int permissionId,
  ) async {
    try {
      // TODO: Permission-Check: can_manage_roles
      // await PermissionHelper.requirePermission(session, 'can_manage_roles');

      // Prüfe ob bereits zugewiesen
      final existing = await RolePermission.db.findFirstRow(
        session,
        where: (t) =>
            t.roleId.equals(roleId) & t.permissionId.equals(permissionId),
      );

      if (existing != null) {
        throw Exception('Permission bereits an Rolle zugewiesen');
      }

      // Aktuelle Staff-User-ID ermitteln
      final currentStaffUserId =
          await StaffAuthHelper.getAuthenticatedStaffUserId(session);
      if (currentStaffUserId == null) {
        throw Exception('Keine gültige Staff-Authentifizierung gefunden');
      }

      // Permission zuweisen
      await RolePermission.db.insertRow(
          session,
          RolePermission(
            roleId: roleId,
            permissionId: permissionId,
            assignedAt: DateTime.now(),
            assignedBy: currentStaffUserId,
          ));

      session.log(
          '✅ Permission assigned to role: Role $roleId → Permission $permissionId');
      return true;
    } catch (e) {
      session.log('❌ assignPermissionToRole Error: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Entfernt Permission von Rolle**
  Future<bool> removePermissionFromRole(
    Session session,
    int roleId,
    int permissionId,
  ) async {
    try {
      // TODO: Permission-Check: can_manage_roles
      // await PermissionHelper.requirePermission(session, 'can_manage_roles');

      final deleted = await RolePermission.db.deleteWhere(
        session,
        where: (t) =>
            t.roleId.equals(roleId) & t.permissionId.equals(permissionId),
      );

      if (deleted == 0) {
        throw Exception('Permission-Zuweisung an Rolle nicht gefunden');
      }

      session.log(
          '✅ Permission removed from role: Role $roleId → Permission $permissionId');
      return true;
    } catch (e) {
      session.log('❌ removePermissionFromRole Error: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// **Holt alle Permissions einer Rolle**
  Future<List<Permission>> getRolePermissions(
      Session session, int roleId) async {
    try {
      // Hole alle Permission-IDs der Rolle
      final rolePermissions = await RolePermission.db.find(
        session,
        where: (t) => t.roleId.equals(roleId),
      );

      if (rolePermissions.isEmpty) {
        return [];
      }

      final permissionIds =
          rolePermissions.map((rp) => rp.permissionId).toSet();

      // Hole die Permission-Objekte
      final permissions = await Permission.db.find(
        session,
        where: (t) => t.id.inSet(permissionIds),
        orderBy: (t) => t.category,
      );

      session.log('🔍 Role $roleId has ${permissions.length} permissions');
      return permissions;
    } catch (e) {
      session.log('❌ getRolePermissions Error: $e', level: LogLevel.error);
      return [];
    }
  }

  /// **Weist Rolle an StaffUser zu**
  Future<bool> assignRoleToStaff(
    Session session,
    int staffUserId,
    int roleId, {
    DateTime? expiresAt,
  }) async {
    try {
      // TODO: Permission-Check: can_manage_roles
      // await PermissionHelper.requirePermission(session, 'can_manage_roles');

      // Prüfe ob bereits zugewiesen
      final existing = await StaffUserRole.db.findFirstRow(
        session,
        where: (t) =>
            t.staffUserId.equals(staffUserId) & t.roleId.equals(roleId),
      );

      if (existing != null) {
        throw Exception('Rolle bereits zugewiesen');
      }

      // Aktuelle Staff-User-ID ermitteln
      final currentStaffUserId =
          await StaffAuthHelper.getAuthenticatedStaffUserId(session);
      if (currentStaffUserId == null) {
        throw Exception('Keine gültige Staff-Authentifizierung gefunden');
      }

      // Rolle zuweisen
      await StaffUserRole.db.insertRow(
          session,
          StaffUserRole(
            staffUserId: staffUserId,
            roleId: roleId,
            assignedAt: DateTime.now(),
            assignedBy: currentStaffUserId,
            isActive: true,
            expiresAt: expiresAt,
          ));

      session.log('✅ Role assigned: Staff $staffUserId → Role $roleId');
      return true;
    } catch (e) {
      session.log('❌ assignRoleToStaff Error: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Entfernt Rolle von StaffUser**
  Future<bool> removeRoleFromStaff(
    Session session,
    int staffUserId,
    int roleId,
  ) async {
    try {
      // TODO: Permission-Check: can_manage_roles
      // await PermissionHelper.requirePermission(session, 'can_manage_roles');

      final deleted = await StaffUserRole.db.deleteWhere(
        session,
        where: (t) =>
            t.staffUserId.equals(staffUserId) & t.roleId.equals(roleId),
      );

      if (deleted == 0) {
        throw Exception('Rollen-Zuweisung nicht gefunden');
      }

      session.log('✅ Role removed: Staff $staffUserId → Role $roleId');
      return true;
    } catch (e) {
      session.log('❌ removeRoleFromStaff Error: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Holt alle Rollen eines StaffUsers**
  Future<List<Role>> getStaffRoles(Session session, int staffUserId) async {
    try {
      final now = DateTime.now();

      // Hole alle Rollen-Zuweisungen des Staff-Users
      final staffRoles = await StaffUserRole.db.find(
        session,
        where: (t) => t.staffUserId.equals(staffUserId),
      );

      final validRoleIds = <int>[];

      for (final sr in staffRoles) {
        // Prüfe Gültigkeit
        if (sr.expiresAt == null || sr.expiresAt!.isAfter(now)) {
          validRoleIds.add(sr.roleId);
        }
      }

      if (validRoleIds.isEmpty) {
        return [];
      }

      final roles = await Role.db.find(
        session,
        where: (t) =>
            t.id.inSet(validRoleIds.toSet()) & t.isActive.equals(true),
        orderBy: (t) => t.sortOrder,
      );

      session.log('🔍 Staff $staffUserId has ${roles.length} roles');
      return roles;
    } catch (e) {
      session.log('❌ getStaffRoles Error: $e', level: LogLevel.error);
      return [];
    }
  }

  /// **Weist Permission an StaffUser zu**
  Future<bool> assignPermissionToStaff(
    Session session,
    int staffUserId,
    int permissionId, {
    DateTime? expiresAt,
    int? grantedBy,
  }) async {
    try {
      // TODO: Permission-Check: can_manage_permissions
      // await PermissionHelper.requirePermission(session, 'can_manage_permissions');

      // Prüfe ob bereits zugewiesen
      final existing = await StaffUserPermission.db.findFirstRow(
        session,
        where: (t) =>
            t.staffUserId.equals(staffUserId) &
            t.permissionId.equals(permissionId),
      );

      if (existing != null) {
        throw Exception('Permission bereits zugewiesen');
      }

      // Permission zuweisen (mit korrekten Required-Feldern)
      final staffPermission = StaffUserPermission(
        staffUserId: staffUserId,
        permissionId: permissionId,
        grantedAt: DateTime.now(),
        grantedBy: grantedBy ?? 1, // TODO: Aktuelle Staff-User-ID verwenden
        expiresAt: expiresAt,
      );

      await StaffUserPermission.db.insertRow(session, staffPermission);

      session.log(
          '✅ Permission assigned: Staff $staffUserId → Permission $permissionId');
      return true;
    } catch (e) {
      session.log('❌ assignPermissionToStaff Error: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **Entfernt Permission von StaffUser**
  Future<bool> removePermissionFromStaff(
    Session session,
    int staffUserId,
    int permissionId,
  ) async {
    try {
      // TODO: Permission-Check: can_manage_permissions
      // await PermissionHelper.requirePermission(session, 'can_manage_permissions');

      final deleted = await StaffUserPermission.db.deleteWhere(
        session,
        where: (t) =>
            t.staffUserId.equals(staffUserId) &
            t.permissionId.equals(permissionId),
      );

      if (deleted == 0) {
        throw Exception('Permission-Zuweisung nicht gefunden');
      }

      session.log(
          '✅ Permission removed: Staff $staffUserId → Permission $permissionId');
      return true;
    } catch (e) {
      session.log('❌ removePermissionFromStaff Error: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// **Holt alle Permissions eines StaffUsers (vereinfacht)**
  Future<List<Permission>> getStaffPermissions(
      Session session, int staffUserId) async {
    try {
      // Vereinfachte Version ohne komplexe Queries
      final staffPermissions = await StaffUserPermission.db.find(
        session,
        where: (t) => t.staffUserId.equals(staffUserId),
      );

      final permissionIds = <int>[];
      final now = DateTime.now();

      for (final sp in staffPermissions) {
        // Prüfe Gültigkeit UND isActive Flag
        if (sp.isActive &&
            (sp.expiresAt == null || sp.expiresAt!.isAfter(now))) {
          permissionIds.add(sp.permissionId);
        }
      }

      if (permissionIds.isEmpty) {
        return [];
      }

      final permissions = await Permission.db.find(
        session,
        where: (t) => t.id.inSet(permissionIds.toSet()),
      );

      session
          .log('🔍 Staff $staffUserId has ${permissions.length} permissions');
      return permissions;
    } catch (e) {
      session.log('❌ getStaffPermissions Error: $e', level: LogLevel.error);
      return [];
    }
  }

  /// **System-Info: Zeigt Permission-Statistiken**
  Future<PermissionStatsResponse> getPermissionStats(Session session) async {
    try {
      final totalPermissions = await Permission.db.count(session);
      final totalRoles = await Role.db.count(session);
      final totalStaffPermissions = await StaffUserPermission.db.count(session);
      final totalRolePermissions = await RolePermission.db.count(session);
      final totalStaffRoles = await StaffUserRole.db.count(session);

      // Kategorien-Statistik über Serverpod ORM (sicherer als unsafeQuery)
      final userManagementCount = await Permission.db
          .count(session, where: (t) => t.category.equals('user'));
      final ticketManagementCount = await Permission.db
          .count(session, where: (t) => t.category.equals('tickets'));
      final staffManagementCount = await Permission.db
          .count(session, where: (t) => t.category.equals('staff'));
      final facilityManagementCount = await Permission.db
          .count(session, where: (t) => t.category.equals('facility'));
      final systemManagementCount = await Permission.db
          .count(session, where: (t) => t.category.equals('system'));
      final reportsAnalyticsCount = await Permission.db
          .count(session, where: (t) => t.category.equals('reports'));
      final documentManagementCount = await Permission.db
          .count(session, where: (t) => t.category.equals('document'));
      final billingManagementCount = await Permission.db
          .count(session, where: (t) => t.category.equals('billing'));
      final printerManagementCount = await Permission.db
          .count(session, where: (t) => t.category.equals('printer'));
      final auditMonitoringCount = await Permission.db
          .count(session, where: (t) => t.category.equals('audit'));

      final stats = PermissionStatsResponse(
        totalPermissions: totalPermissions,
        totalRoles: totalRoles,
        totalStaffPermissions: totalStaffPermissions,
        totalRolePermissions: totalRolePermissions,
        totalStaffRoles: totalStaffRoles,
        userManagementCount: userManagementCount,
        ticketManagementCount: ticketManagementCount,
        staffManagementCount: staffManagementCount,
        facilityManagementCount: facilityManagementCount,
        systemManagementCount: systemManagementCount,
        reportsAnalyticsCount: reportsAnalyticsCount,
        documentManagementCount: documentManagementCount,
        billingManagementCount: billingManagementCount,
        printerManagementCount: printerManagementCount,
        auditMonitoringCount: auditMonitoringCount,
        timestamp: DateTime.now().toIso8601String(),
      );

      session.log('📊 Permission stats generated');
      return stats;
    } catch (e) {
      session.log('❌ getPermissionStats Error: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// **Holt alle Berechtigungen für einen Staff-User (ohne Session.authenticated)**
  ///
  /// Diese Methode ist für Staff-Auth gedacht, wo wir die Staff-User-ID
  /// direkt haben und nicht über Serverpod-Session-Auth gehen.
  Future<List<String>> getStaffUserPermissions(
      Session session, int staffUserId) async {
    try {
      session.log('🔒 Loading permissions for Staff-User: $staffUserId');

      // PermissionHelper verwenden, der Caching beinhaltet
      final permissionsSet = await PermissionHelper.getUserPermissions(
        session,
        staffUserId,
      );

      session.log(
          '✅ Fetched ${permissionsSet.length} permissions for Staff-User $staffUserId');
      return permissionsSet.toList();
    } catch (e) {
      session.log('❌ getStaffUserPermissions Error: $e', level: LogLevel.error);
      return [];
    }
  }

  /// **Holt alle Berechtigungen für den aktuell eingeloggten Benutzer.**
  ///
  /// Diese Methode ist für den Client-Aufruf gedacht (z.B. beim App-Start),
  /// um die UI-Permissions zu initialisieren. Sie nutzt den serverseitigen
  /// PermissionHelper, der wiederum Caching verwendet.
  Future<List<String>> getCurrentUserPermissions(Session session) async {
    try {
      final authUserId =
          await StaffAuthHelper.getAuthenticatedStaffUserId(session);

      if (authUserId == null) {
        session.log('⚠️ getCurrentUserPermissions: User nicht eingeloggt.');
        return [];
      }

      // PermissionHelper verwenden, der Caching beinhaltet
      final permissionsSet = await PermissionHelper.getUserPermissions(
        session,
        authUserId,
      );

      session.log(
          '🔒 Fetched ${permissionsSet.length} permissions for user $authUserId');
      return permissionsSet.toList();
    } catch (e) {
      session.log('❌ getCurrentUserPermissions Error: $e',
          level: LogLevel.error);
      return [];
    }
  }
}
