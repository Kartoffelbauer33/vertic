import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import 'package:bcrypt/bcrypt.dart';

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
      // SuperUser hat alle Rechte, für andere staff members prüfe permissions
      if (staffUser.staffLevel == StaffUserType.superUser) {
        return true;
      }
      // Für normale staff members: prüfe ob sie die entsprechende Permission haben
      return await PermissionHelper.hasPermission(session, staffUserId, 'can_manage_users');
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

  /// **Aktualisiert Staff-User-Daten**
  Future<StaffUser?> updateStaffUser(Session session, StaffUser staffUser) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Staff-User-Update verweigert', level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_edit_staff');
    if (!hasPermission) {
      session.log('❌ Fehlende Berechtigung: can_edit_staff (User: $authUserId)', level: LogLevel.warning);
      return null;
    }

    try {
      // Prüfe ob Staff-User existiert
      final existingStaffUser = await StaffUser.db.findById(session, staffUser.id!);
      if (existingStaffUser == null) {
        throw Exception('Staff-User nicht gefunden');
      }

      // SuperUser kann nicht bearbeitet werden (außer von SuperUser selbst)
      if (existingStaffUser.staffLevel == StaffUserType.superUser && authUserId != staffUser.id) {
        final currentStaffUser = await StaffUser.db.findById(session, authUserId);
        if (currentStaffUser?.staffLevel != StaffUserType.superUser) {
          throw Exception('SuperUser können nur von anderen SuperUsern bearbeitet werden');
        }
      }

      // Staff-User aktualisieren
      final updatedStaffUser = await StaffUser.db.updateRow(session, staffUser);

      session.log('✅ Staff-User ${updatedStaffUser.firstName} ${updatedStaffUser.lastName} aktualisiert');
      return updatedStaffUser;
    } catch (e) {
      session.log('❌ updateStaffUser Error: $e', level: LogLevel.error);
      return null;
    }
  }

  /// **Löscht einen Superuser (mit Sicherheitsprüfungen)**
  Future<bool> deleteSuperUser(Session session, int superUserId, String password) async {
    // 1. 🔐 RBAC SECURITY CHECK
    final authUserId = await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Superuser-Löschung verweigert', level: LogLevel.warning);
      return false;
    }

    final currentStaffUser = await StaffUser.db.findById(session, authUserId);
    if (currentStaffUser == null || currentStaffUser.staffLevel != StaffUserType.superUser) {
      session.log('❌ Nur Superuser können andere Superuser löschen', level: LogLevel.warning);
      return false;
    }

    try {
      // 2. Prüfe Passwort des aktuellen Superusers
      final currentEmailAuth = await EmailAuth.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(currentStaffUser.userInfoId!),
      );

      if (currentEmailAuth == null) {
        session.log('❌ Authentifizierung nicht gefunden', level: LogLevel.error);
        return false;
      }

      if (!_verifyPassword(password, currentEmailAuth.hash)) {
        session.log('❌ Ungültiges Passwort für Superuser-Löschung', level: LogLevel.warning);
        return false;
      }

      // 3. Prüfe ob genug Superuser vorhanden sind (mindestens 2 aktive)
      final activeSuperUsers = await StaffUser.db.count(
        session,
        where: (t) => t.staffLevel.equals(StaffUserType.superUser) & 
                     t.employmentStatus.equals('active'),
      );

      if (activeSuperUsers <= 1) {
        session.log('❌ Letzter Superuser kann nicht gelöscht werden', level: LogLevel.warning);
        return false;
      }

      // 4. Prüfe ob zu löschender User ein Superuser ist
      final targetStaffUser = await StaffUser.db.findById(session, superUserId);
      if (targetStaffUser == null) {
        session.log('❌ Zu löschender Staff-User nicht gefunden', level: LogLevel.error);
        return false;
      }

      if (targetStaffUser.staffLevel != StaffUserType.superUser) {
        session.log('❌ Nur Superuser können mit dieser Methode gelöscht werden', level: LogLevel.warning);
        return false;
      }

      // 5. Lösche alle Rollen-Zuweisungen
      await StaffUserRole.db.deleteWhere(
        session,
        where: (t) => t.staffUserId.equals(superUserId),
      );

      // 6. Lösche alle Permission-Zuweisungen
      await StaffUserPermission.db.deleteWhere(
        session,
        where: (t) => t.staffUserId.equals(superUserId),
      );

      // 7. Lösche den Staff-User
      final deleted = await StaffUser.db.deleteWhere(
        session, 
        where: (t) => t.id.equals(superUserId)
      );

      if (deleted.isNotEmpty) {
        session.log('✅ Superuser ${targetStaffUser.firstName} ${targetStaffUser.lastName} erfolgreich gelöscht von ${currentStaffUser.firstName}', level: LogLevel.warning);
        return true;
      }
      return false;
    } catch (e) {
      session.log('❌ deleteSuperUser Error: $e', level: LogLevel.error);
      return false;
    }
  }

  // PRIVATE HILFSMETHODEN

  /// **Password-Verifikation (aus unified_auth_endpoint kopiert)**
  bool _verifyPassword(String password, String hash) {
    try {
      // 1. Echter bcrypt Hash - verwende BCrypt.checkpw()
      if (hash.startsWith('\$2b\$') || hash.startsWith('\$2a\$')) {
        return BCrypt.checkpw(password, hash);
      }
      // 2. Legacy MD5 (falls noch vorhanden)
      return hash == password; // Unsicher, nur für Migration
    } catch (e) {
      return false;
    }
  }

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
