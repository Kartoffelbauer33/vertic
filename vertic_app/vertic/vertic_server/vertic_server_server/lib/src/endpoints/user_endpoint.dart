import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';

/// Admin-Endpoint für Benutzerverwaltung (nur für Staff/Admin-Zugriff)
class UserEndpoint extends Endpoint {
  /// Prüft ob StaffUser für User-Management berechtigt ist
  Future<bool> _isStaffUserAuthorized(Session session,
      {bool requireHighLevel = false}) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) return false;

    final staffUser = await StaffUser.db.findById(session, staffUserId);
    if (staffUser == null) return false;

    if (requireHighLevel) {
      return staffUser.staffLevel == StaffUserType.superUser ||
          staffUser.staffLevel == StaffUserType.facilityAdmin;
    }

    return true; // Alle StaffUser dürfen User-Daten lesen/verwalten
  }

  /// Administrative Methode: Holt alle Benutzer (mit Paginierung)
  Future<List<AppUser>> getAllUsers(Session session,
      {int limit = 50, int offset = 0}) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - User-Liste verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_users');
    if (!hasPermission) {
      session.log('❌ Fehlende Berechtigung: can_view_users (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      return await AppUser.db.find(
        session,
        limit: limit,
        offset: offset,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
    } catch (e) {
      session.log('Fehler beim Laden aller Benutzer: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Administrative Methode: Holt einen Benutzer anhand seiner ID
  Future<AppUser?> getUserById(Session session, int id) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - User-Details verweigert',
          level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_user_details');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_view_user_details (User: $authUserId)',
          level: LogLevel.warning);
      return null;
    }

    try {
      return await AppUser.db.findById(session, id);
    } catch (e) {
      session.log('Fehler beim Laden des Benutzers $id: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Administrative Methode: Aktualisiert Benutzerdaten (CRM-Feature)
  Future<AppUser?> updateUser(
      Session session, int userId, UserUpdateRequest updateRequest) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - User-Update verweigert',
          level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_edit_users');
    if (!hasPermission) {
      session.log('❌ Fehlende Berechtigung: can_edit_users (User: $authUserId)',
          level: LogLevel.warning);
      return null;
    }

    final staffUserId = authUserId;

    try {
      var user = await AppUser.db.findById(session, userId);
      if (user == null) {
        session.log('Benutzer $userId nicht gefunden für Update',
            level: LogLevel.warning);
        return null;
      }

      // Nur die Felder aktualisieren, die auch gesetzt sind
      var updatedUser = user.copyWith(
        firstName: updateRequest.firstName ?? user.firstName,
        lastName: updateRequest.lastName ?? user.lastName,
        email: updateRequest.email ?? user.email,
        parentEmail: updateRequest.parentEmail ?? user.parentEmail,
        phoneNumber: updateRequest.phoneNumber ?? user.phoneNumber,
        address: updateRequest.address ?? user.address,
        city: updateRequest.city ?? user.city,
        postalCode: updateRequest.postalCode ?? user.postalCode,
        birthDate: updateRequest.birthDate ?? user.birthDate,
        updatedAt: DateTime.now().toUtc(),
      );

      // Änderungen in der Datenbank speichern
      await AppUser.db.updateRow(session, updatedUser);

      // Automatische Notiz für Audit-Trail hinzufügen
      if (updateRequest.updateReason != null &&
          updateRequest.updateReason!.isNotEmpty) {
        await _addSystemNote(
          session,
          userId,
          'Benutzer-Update: ${updateRequest.updateReason}',
          staffUserId,
          'Staff-User',
        );
      }

      session.log(
          'Benutzer $userId erfolgreich aktualisiert von Staff $staffUserId',
          level: LogLevel.info);

      return updatedUser;
    } catch (e) {
      session.log('Fehler beim Aktualisieren des Benutzers $userId: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Administrative Methode: Löscht einen Benutzer (VORSICHT!)
  Future<bool> deleteUser(Session session, int id) async {
    // 🔐 RBAC SECURITY CHECK - HIGH LEVEL REQUIRED
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - User-Löschung verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_delete_users');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_delete_users (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    try {
      // Zuerst alle UserNotes für diesen User löschen (Cascade)
      await UserNote.db.deleteWhere(session, where: (n) => n.userId.equals(id));

      final deletedRows =
          await AppUser.db.deleteWhere(session, where: (u) => u.id.equals(id));

      if (deletedRows.isNotEmpty) {
        session.log('Benutzer $id gelöscht von Admin', level: LogLevel.warning);
        return true;
      }
      return false;
    } catch (e) {
      session.log('Fehler beim Löschen des Benutzers $id: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// Administrative Methode: Blockiert/Entsperrt einen Benutzer
  Future<bool> blockUser(
      Session session, int userId, bool isBlocked, String reason) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - User-Blockierung verweigert',
          level: LogLevel.warning);
      return false;
    }

    final permissionNeeded =
        isBlocked ? 'can_block_users' : 'can_unblock_users';
    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, permissionNeeded);
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: $permissionNeeded (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    final staffUserId = authUserId;

    try {
      var user = await AppUser.db.findById(session, userId);
      if (user == null) {
        return false;
      }

      user = user.copyWith(
        isBlocked: isBlocked,
        blockedReason: isBlocked ? reason : null,
        blockedAt: isBlocked ? DateTime.now().toUtc() : null,
        updatedAt: DateTime.now().toUtc(),
      );

      await AppUser.db.updateRow(session, user);

      // Automatische Notiz hinzufügen
      await _addSystemNote(
        session,
        userId,
        isBlocked ? 'Account gesperrt: $reason' : 'Account entsperrt',
        staffUserId,
        'Staff-User',
      );

      session.log(
          'Benutzer $userId ${isBlocked ? "blockiert" : "entsperrt"}: $reason',
          level: LogLevel.warning);
      return true;
    } catch (e) {
      session.log('Fehler beim Blockieren/Entsperren des Benutzers $userId: $e',
          level: LogLevel.error);
      return false;
    }
  }

  // PRIVATE HILFSMETHODEN

  /// Fügt eine automatische System-Notiz hinzu
  Future<void> _addSystemNote(
    Session session,
    int userId,
    String content,
    int? staffId,
    String? staffName,
  ) async {
    try {
      final note = UserNote(
        userId: userId,
        noteType: 'system',
        content: content,
        isInternal: true,
        priority: 'normal',
        status: 'active',
        createdByStaffId: staffId,
        createdByName: staffName ?? 'System',
        createdAt: DateTime.now().toUtc(),
      );

      await UserNote.db.insertRow(session, note);
    } catch (e) {
      session.log('Fehler beim Hinzufügen der System-Notiz: $e',
          level: LogLevel.error);
      // System-Notizen sollten keine kritischen Fehler verursachen
    }
  }
}
