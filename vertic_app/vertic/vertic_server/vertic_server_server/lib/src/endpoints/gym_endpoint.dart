import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';

class GymEndpoint extends Endpoint {
  /// Alle Gyms abrufen (nur für StaffUser)
  Future<List<Gym>> getAllGyms(Session session) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Gym-Liste verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_facilities');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_view_facilities (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      final gyms = await Gym.db.find(
        session,
        orderBy: (g) => g.name,
      );

      session.log('${gyms.length} Gyms abgerufen für User $authUserId');
      return gyms;
    } catch (e) {
      session.log('Fehler beim Laden der Gyms: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Gym erstellen (nur SuperUser und FacilityAdmin)
  Future<Gym?> createGym(Session session, Gym gym) async {
    // 🔐 RBAC SECURITY CHECK - HIGH LEVEL REQUIRED
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Gym-Erstellung verweigert',
          level: LogLevel.warning);
      throw Exception('Sie müssen eingeloggt sein um Gyms zu erstellen');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_create_facilities');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_create_facilities (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Fehlende Berechtigung für Gym-Erstellung');
    }

    // Eingabe-Validierung
    if (gym.name.trim().isEmpty) {
      throw Exception('Gym-Name darf nicht leer sein');
    }

    if (gym.shortCode.trim().isEmpty) {
      throw Exception('Kurzkürzel darf nicht leer sein');
    }

    if (gym.city.trim().isEmpty) {
      throw Exception('Stadt darf nicht leer sein');
    }

    // Kurzkürzel normalisieren
    final normalizedShortCode =
        gym.shortCode.trim().toUpperCase().replaceAll(' ', '');
    if (normalizedShortCode.length < 2 || normalizedShortCode.length > 5) {
      throw Exception('Kurzkürzel muss zwischen 2 und 5 Zeichen lang sein');
    }

    try {
      // Prüfe Name-Duplikate
      final existingByName = await Gym.db.findFirstRow(
        session,
        where: (g) => g.name.ilike('%${gym.name.trim()}%'),
      );

      if (existingByName != null) {
        throw Exception(
            'Ein Gym mit diesem oder ähnlichem Namen existiert bereits: "${existingByName.name}"');
      }

      // Prüfe ShortCode-Duplikate
      final existingByCode = await Gym.db.findFirstRow(
        session,
        where: (g) => g.shortCode.equals(normalizedShortCode),
      );

      if (existingByCode != null) {
        throw Exception(
            'Ein Gym mit diesem Kurzkürzel existiert bereits: "${existingByCode.shortCode}" (${existingByCode.name})');
      }

      // Gym erstellen
      final now = DateTime.now().toUtc();
      final newGym = Gym(
        name: gym.name.trim(),
        shortCode: normalizedShortCode,
        city: gym.city.trim(),
        address: gym.address?.trim(),
        description: gym.description?.trim(),
        facilityId: gym.facilityId,
        isActive: gym.isActive ?? true,
        isVerticLocation: gym.isVerticLocation ?? true,
        createdAt: now,
        updatedAt: now,
      );

      final savedGym = await Gym.db.insertRow(session, newGym);
      session.log(
          'Gym "${savedGym.name}" (${savedGym.shortCode}) erfolgreich erstellt von User $authUserId (ID: ${savedGym.id})');

      return savedGym;
    } catch (e) {
      session.log('Fehler beim Erstellen des Gyms: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Gym aktualisieren (nur SuperUser und FacilityAdmin)
  Future<Gym?> updateGym(Session session, Gym gym) async {
    // 🔐 RBAC SECURITY CHECK - HIGH LEVEL REQUIRED
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Gym-Update verweigert',
          level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_edit_facilities');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_edit_facilities (User: $authUserId)',
          level: LogLevel.warning);
      return null;
    }

    try {
      if (gym.id == null) {
        session.log('Gym ID fehlt für Update', level: LogLevel.error);
        return null;
      }

      // Prüfe ob Gym existiert
      final existingGym = await Gym.db.findById(session, gym.id!);
      if (existingGym == null) {
        session.log('Gym mit ID ${gym.id} nicht gefunden',
            level: LogLevel.error);
        return null;
      }

      // Update mit Timestamp
      gym.updatedAt = DateTime.now().toUtc();
      final updatedGym = await Gym.db.updateRow(session, gym);

      session.log('Gym "${gym.name}" aktualisiert von User $authUserId');
      return updatedGym;
    } catch (e) {
      session.log('Fehler beim Aktualisieren des Gyms: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Gym löschen (nur SuperUser)
  Future<bool> deleteGym(Session session, int gymId) async {
    // 🔐 RBAC SECURITY CHECK - HIGHEST LEVEL REQUIRED
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Gym-Löschung verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_delete_facilities');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_delete_facilities (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    try {
      final gym = await Gym.db.findById(session, gymId);
      if (gym == null) {
        session.log('Gym mit ID $gymId nicht gefunden', level: LogLevel.error);
        return false;
      }

      await Gym.db.deleteWhere(session, where: (g) => g.id.equals(gymId));
      session.log('Gym "${gym.name}" gelöscht von User $authUserId');
      return true;
    } catch (e) {
      session.log('Fehler beim Löschen des Gyms: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Gym nach ID abrufen
  Future<Gym?> getGymById(Session session, int id) async {
    try {
      return await Gym.db.findById(session, id);
    } catch (e) {
      session.log('Fehler beim Abrufen des Gyms: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Aktive Gyms abrufen
  Future<List<Gym>> getActiveGyms(Session session) async {
    try {
      return await Gym.db.find(
        session,
        where: (g) => g.isActive.equals(true),
        orderBy: (g) => g.name,
      );
    } catch (e) {
      session.log('Fehler beim Abrufen der aktiven Gyms: $e',
          level: LogLevel.error);
      return [];
    }
  }
}
