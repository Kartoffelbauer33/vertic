import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';

/// Endpoint für User-Notizen und CRM-Dokumentation
class UserNoteEndpoint extends Endpoint {
  /// Prüft ob StaffUser für Notizen-Management berechtigt ist
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
      return await PermissionHelper.hasPermission(session, staffUserId, 'can_manage_user_notes');
    }

    return true; // Alle StaffUser dürfen Notizen lesen/erstellen
  }

  /// Erstellt eine neue Notiz für einen Benutzer
  Future<UserNote?> createUserNote(Session session, UserNote note) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Notiz-Erstellung verweigert',
          level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_create_user_notes');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_create_user_notes (User: $authUserId)',
          level: LogLevel.warning);
      return null;
    }

    final staffUserId = authUserId;

    try {
      // Validierung
      if (note.content.length > 2000) {
        session.log('Notiz-Inhalt zu lang: ${note.content.length} Zeichen',
            level: LogLevel.warning);
        return null;
      }

      final validNoteTypes = [
        'general',
        'important',
        'warning',
        'positive',
        'complaint',
        'system'
      ];
      if (!validNoteTypes.contains(note.noteType)) {
        session.log('Ungültiger Notiz-Typ: ${note.noteType}',
            level: LogLevel.warning);
        return null;
      }

      // Prüfe ob User existiert
      final user = await AppUser.db.findById(session, note.userId);
      if (user == null) {
        session.log('Benutzer ${note.userId} nicht gefunden für Notiz',
            level: LogLevel.warning);
        return null;
      }

      final savedNote = await UserNote.db.insertRow(session, note);

      session.log(
          'Neue Notiz erstellt für User ${note.userId} von Staff $staffUserId',
          level: LogLevel.info);
      return savedNote;
    } catch (e) {
      session.log('Fehler beim Erstellen der Notiz: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Holt alle Notizen für einen Benutzer (mit Paginierung)
  Future<List<UserNote>> getUserNotes(Session session, int userId,
      {int limit = 50, int offset = 0, bool includeInternal = false}) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - User-Notizen verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_user_notes');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_view_user_notes (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      var query = UserNote.db.find(
        session,
        where: (n) => n.userId.equals(userId),
        limit: limit,
        offset: offset,
        orderBy: (n) => n.createdAt,
        orderDescending: true,
      );

      // Optional filter by type
      if (includeInternal) {
        query = UserNote.db.find(
          session,
          where: (n) => n.userId.equals(userId) & n.isInternal.equals(true),
          limit: limit,
          offset: offset,
          orderBy: (n) => n.createdAt,
          orderDescending: true,
        );
      }

      return await query;
    } catch (e) {
      session.log('Fehler beim Laden der Notizen für User $userId: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Aktualisiert eine bestehende Notiz
  Future<UserNote?> updateUserNote(Session session, UserNote note) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Notiz-Update verweigert',
          level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_edit_user_notes');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_edit_user_notes (User: $authUserId)',
          level: LogLevel.warning);
      return null;
    }

    try {
      note.updatedAt = DateTime.now().toUtc();
      final updatedNote = await UserNote.db.updateRow(session, note);

      session.log('Notiz ${note.id} aktualisiert von Staff $authUserId',
          level: LogLevel.info);
      return updatedNote;
    } catch (e) {
      session.log('Fehler beim Aktualisieren der Notiz: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Löscht eine Notiz (nur für Admin/Super-Admin)
  Future<bool> deleteUserNote(Session session, int noteId) async {
    // 🔐 RBAC SECURITY CHECK - HIGH LEVEL REQUIRED
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Notiz-Löschung verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_delete_user_notes');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_delete_user_notes (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    try {
      final note = await UserNote.db.findById(session, noteId);
      if (note == null) {
        session.log('Notiz $noteId nicht gefunden für Löschung',
            level: LogLevel.warning);
        return false;
      }

      await UserNote.db.deleteWhere(session, where: (n) => n.id.equals(noteId));

      session.log('Notiz $noteId gelöscht von Admin $authUserId',
          level: LogLevel.warning);
      return true;
    } catch (e) {
      session.log('Fehler beim Löschen der Notiz $noteId: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// Holt Notizen nach Priorität (für Dashboard)
  Future<List<UserNote>> getHighPriorityNotes(
    Session session, {
    int limit = 20,
    String priority = 'high',
  }) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Priority-Notizen verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_user_notes');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_view_user_notes (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      return await UserNote.db.find(
        session,
        where: (n) => n.priority.equals(priority) & n.status.equals('active'),
        limit: limit,
        orderBy: (n) => n.createdAt,
        orderDescending: true,
      );
    } catch (e) {
      session.log('Fehler beim Laden der High-Priority Notizen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Holt Statistiken zu Notizen (für Analytics)
  Future<Map<String, int>> getNoteStatistics(
      Session session, int userId) async {
    try {
      final notes = await UserNote.db.find(
        session,
        where: (n) => n.userId.equals(userId),
      );

      final stats = <String, int>{};

      // Count by type
      for (final note in notes) {
        stats[note.noteType] = (stats[note.noteType] ?? 0) + 1;
      }

      // Total count
      stats['total'] = notes.length;

      // Active vs resolved
      stats['active'] = notes.where((n) => n.status == 'active').length;
      stats['resolved'] = notes.where((n) => n.status == 'resolved').length;

      return stats;
    } catch (e) {
      session.log(
          'Fehler beim Laden der Notiz-Statistiken für User $userId: $e',
          level: LogLevel.error);
      return <String, int>{};
    }
  }
}
