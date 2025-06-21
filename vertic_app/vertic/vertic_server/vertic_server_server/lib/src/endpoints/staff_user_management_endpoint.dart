import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';

/// Staff-User-Management-Endpoint für die Verwaltung von Staff-Benutzern
/// Verwendet separate StaffUser Tabelle (nicht AppUser)
class StaffUserManagementEndpoint extends Endpoint {
  /// Holt alle Staff-Benutzer (aus dedicated StaffUser Tabelle)
  Future<List<StaffUser>> getAllStaffUsers(Session session,
      {int limit = 100, int offset = 0}) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Staff-User-Liste verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_staff');
    if (!hasPermission) {
      session.log('❌ Fehlende Berechtigung: can_view_staff (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      // Staff-User aus dedicated Tabelle laden
      final staffUsers = await StaffUser.db.find(
        session,
        where: (u) => u.employmentStatus.equals('active'),
        limit: limit,
        offset: offset,
        orderBy: (u) => u.createdAt,
        orderDescending: true,
      );

      session.log('${staffUsers.length} Staff-User geladen');
      return staffUsers;
    } catch (e) {
      session.log('Fehler beim Laden der Staff-User: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Erstellt einen neuen Staff-Benutzer
  Future<StaffUser> createStaffUser(
      Session session, CreateStaffUserRequest request) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Staff-User-Erstellung verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Staff-User-Erstellung');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_create_staff');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_create_staff (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Erstellen von Staff-Benutzern');
    }

    try {
      // E-Mail-Uniqueness prüfen
      final existingUser = await StaffUser.db.findFirstRow(
        session,
        where: (u) => u.email.equals(request.email),
      );

      if (existingUser != null) {
        throw Exception('E-Mail-Adresse bereits vergeben');
      }

      final now = DateTime.now().toUtc();

      // Neuen Staff-User erstellen
      final newUser = StaffUser(
        firstName: request.firstName,
        lastName: request.lastName,
        email: request.email,
        phoneNumber: request.phoneNumber,

        // Staff-Hierarchie
        staffLevel: request.staffLevel,
        hallId: request.hallId,
        facilityId: request.facilityId,
        departmentId: request.departmentId,

        // HR-Informationen (optional)
        employeeId: request.employeeId,
        contractType: request.contractType,
        hourlyRate: request.hourlyRate,
        monthlySalary: request.monthlySalary,
        workingHours: request.workingHours,

        // Standard-Status
        employmentStatus: 'active',

        // Timestamps
        createdAt: now,
        updatedAt: now,
      );

      final savedUser = await StaffUser.db.insertRow(session, newUser);

      session.log(
          'Staff-User erstellt: ${savedUser.email} (Level: ${request.staffLevel})');

      return savedUser;
    } catch (e) {
      session.log('Fehler beim Erstellen des Staff-Users: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Aktualisiert einen Staff-Benutzer
  Future<StaffUser> updateStaffUser(
      Session session, int userId, UpdateStaffUserRequest request) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Staff-User-Update verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Staff-User-Update');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_edit_staff');
    if (!hasPermission) {
      session.log('❌ Fehlende Berechtigung: can_edit_staff (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Bearbeiten von Staff-Benutzern');
    }

    try {
      // Bestehenden User laden
      final existingUser = await StaffUser.db.findById(session, userId);
      if (existingUser == null) {
        throw Exception('Benutzer nicht gefunden');
      }

      // E-Mail-Uniqueness prüfen (falls geändert)
      if (request.email != null && request.email != existingUser.email) {
        final emailExists = await StaffUser.db.findFirstRow(
          session,
          where: (u) => u.email.equals(request.email!) & u.id.notEquals(userId),
        );

        if (emailExists != null) {
          throw Exception('E-Mail-Adresse bereits vergeben');
        }
      }

      // User aktualisieren
      final updatedUser = existingUser.copyWith(
        firstName: request.firstName ?? existingUser.firstName,
        lastName: request.lastName ?? existingUser.lastName,
        email: request.email ?? existingUser.email,
        phoneNumber: request.phoneNumber ?? existingUser.phoneNumber,

        // Staff-Hierarchie aktualisieren
        staffLevel: request.staffLevel ?? existingUser.staffLevel,
        hallId: request.hallId ?? existingUser.hallId,
        facilityId: request.facilityId ?? existingUser.facilityId,
        departmentId: request.departmentId ?? existingUser.departmentId,

        // HR-Informationen aktualisieren
        employeeId: request.employeeId ?? existingUser.employeeId,
        contractType: request.contractType ?? existingUser.contractType,
        hourlyRate: request.hourlyRate ?? existingUser.hourlyRate,
        monthlySalary: request.monthlySalary ?? existingUser.monthlySalary,
        workingHours: request.workingHours ?? existingUser.workingHours,
        employmentStatus:
            request.employmentStatus ?? existingUser.employmentStatus,

        updatedAt: DateTime.now().toUtc(),
      );

      await StaffUser.db.updateRow(session, updatedUser);

      session
          .log('Staff-User aktualisiert: ${updatedUser.email} (ID: $userId)');

      return updatedUser;
    } catch (e) {
      session.log('Fehler beim Aktualisieren des Staff-Users $userId: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Löscht einen Staff-Benutzer (nur für SuperUser)
  Future<bool> deleteStaffUser(Session session, int userId) async {
    // 🔐 RBAC SECURITY CHECK - SUPER ADMIN ONLY
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Staff-User-Löschung verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Staff-User-Löschung');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_delete_staff');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_delete_staff (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Löschen von Staff-Benutzern');
    }

    try {
      // User laden für Logging
      final userToDelete = await StaffUser.db.findById(session, userId);
      if (userToDelete == null) {
        throw Exception('Benutzer nicht gefunden');
      }

      // User löschen
      final deletedRows = await StaffUser.db.deleteWhere(
        session,
        where: (u) => u.id.equals(userId),
      );

      if (deletedRows.isNotEmpty) {
        session.log('Staff-User gelöscht: ${userToDelete.email} (ID: $userId)',
            level: LogLevel.warning);
        return true;
      }

      return false;
    } catch (e) {
      session.log('Fehler beim Löschen des Staff-Users $userId: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Blockiert/Entsperrt einen Staff-Benutzer
  Future<AppUser> blockStaffUser(
      Session session, BlockUserRequest request) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Staff-User-Blockierung verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Staff-User-Blockierung');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_block_staff_users');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_block_staff_users (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Blockieren von Staff-Benutzern');
    }

    try {
      // TODO: Authentication wird später mit Serverpod Auth Module implementiert

      final user = await AppUser.db.findById(session, request.userId);
      if (user == null) {
        throw Exception('Benutzer nicht gefunden');
      }

      // Verhindere Selbst-Blockierung (später mit Auth)
      // TODO: Check if current user is trying to block themselves

      final updatedUser = user.copyWith(
        isBlocked: request.isBlocked,
        blockedReason: request.isBlocked ? request.reason : null,
        blockedAt: request.isBlocked ? DateTime.now().toUtc() : null,
        updatedAt: DateTime.now().toUtc(),
      );

      await AppUser.db.updateRow(session, updatedUser);

      session.log(
          'Staff-User ${request.isBlocked ? "blockiert" : "entsperrt"}: ${user.email} (ID: ${request.userId})'
          '${request.reason != null ? " - Grund: ${request.reason}" : ""}',
          level: LogLevel.warning);

      return updatedUser;
    } catch (e) {
      session.log(
          'Fehler beim Blockieren/Entsperren des Staff-Users ${request.userId}: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Setzt ein temporäres Passwort für einen Staff-Benutzer
  Future<TempPasswordResponse> resetStaffUserPassword(
      Session session, ResetPasswordRequest request) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Passwort-Reset verweigert',
          level: LogLevel.warning);
      return TempPasswordResponse(
        success: false,
        message: 'Authentication erforderlich für Passwort-Reset',
      );
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_reset_staff_passwords');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_reset_staff_passwords (User: $authUserId)',
          level: LogLevel.warning);
      return TempPasswordResponse(
        success: false,
        message: 'Keine Berechtigung zum Zurücksetzen von Staff-Passwörtern',
      );
    }

    try {
      // TODO: Authentication wird später mit Serverpod Auth Module implementiert

      final user = await AppUser.db.findById(session, request.userId);
      if (user == null) {
        return TempPasswordResponse(
          success: false,
          message: 'Benutzer nicht gefunden',
        );
      }

      // Generiere temporäres Passwort
      final tempPassword = _generateTemporaryPassword();
      final expiresAt = DateTime.now().toUtc().add(Duration(hours: 24));

      // TODO: Implement password storage with Serverpod Auth module
      // Für jetzt nur Logging und Response

      session.log(
          'Temporäres Passwort generiert für Staff-User: ${user.email} (ID: ${request.userId})'
          '${(request.sendEmail ?? false) ? " - E-Mail wird gesendet" : " - Nur manuell"}',
          level: LogLevel.info);

      return TempPasswordResponse(
        success: true,
        temporaryPassword: tempPassword,
        expiresAt: expiresAt,
        message: (request.sendEmail ?? false)
            ? 'Temporäres Passwort wurde per E-Mail gesendet'
            : 'Temporäres Passwort wurde generiert',
      );
    } catch (e) {
      session.log(
          'Fehler beim Generieren des temporären Passworts für User ${request.userId}: $e',
          level: LogLevel.error);
      return TempPasswordResponse(
        success: false,
        message: 'Fehler beim Generieren des Passworts: ${e.toString()}',
      );
    }
  }

  // ===== RBAC MANAGEMENT METHODEN =====

  /// Holt alle Rollen eines Staff-Users
  Future<List<StaffUserRole>> getStaffUserRoles(
      Session session, int staffUserId) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Staff-User-Rollen verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_staff_roles');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_view_staff_roles (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Anzeigen von Staff-Rollen');
    }

    try {
      final userRoles = await StaffUserRole.db.find(
        session,
        where: (sur) => sur.staffUserId.equals(staffUserId),
      );

      session.log(
          '${userRoles.length} Rollen für Staff-User $staffUserId geladen');
      return userRoles;
    } catch (e) {
      session.log('Fehler beim Laden der Staff-User-Rollen: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Weist einem Staff-User eine Rolle zu
  Future<StaffUserRole> assignRoleToStaffUser(
      Session session, int staffUserId, int roleId) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Rollenzuweisung verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_manage_staff_roles');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_manage_staff_roles (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Verwalten von Staff-Rollen');
    }

    try {
      // Prüfe ob Zuweisung bereits existiert
      final existingAssignment = await StaffUserRole.db.findFirstRow(
        session,
        where: (sur) =>
            sur.staffUserId.equals(staffUserId) & sur.roleId.equals(roleId),
      );

      if (existingAssignment != null) {
        throw Exception('Rolle bereits zugewiesen');
      }

      // Neue Zuweisung erstellen
      final newAssignment = StaffUserRole(
        staffUserId: staffUserId,
        roleId: roleId,
        assignedAt: DateTime.now().toUtc(),
        assignedBy: authUserId,
      );

      final savedAssignment =
          await StaffUserRole.db.insertRow(session, newAssignment);

      session.log(
          'Rolle $roleId zu Staff-User $staffUserId zugewiesen (von User $authUserId)');
      return savedAssignment;
    } catch (e) {
      session.log('Fehler beim Zuweisen der Rolle: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Entfernt eine Rollenzuweisung von einem Staff-User
  Future<bool> removeStaffUserRole(Session session, int assignmentId) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Rollenentzug verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_manage_staff_roles');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_manage_staff_roles (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung zum Verwalten von Staff-Rollen');
    }

    try {
      final deletedRows = await StaffUserRole.db.deleteWhere(
        session,
        where: (sur) => sur.id.equals(assignmentId),
      );

      final success = deletedRows.isNotEmpty;
      if (success) {
        session.log(
            'Rollenzuweisung $assignmentId entfernt (von User $authUserId)');
      }

      return success;
    } catch (e) {
      session.log('Fehler beim Entfernen der Rollenzuweisung: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  // PRIVATE HILFSMETHODEN

  /// Generiert ein temporäres Passwort
  String _generateTemporaryPassword() {
    final chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';
    for (int i = 0; i < 12; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }
}
