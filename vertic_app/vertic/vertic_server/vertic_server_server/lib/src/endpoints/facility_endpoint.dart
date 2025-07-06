import 'package:serverpod/serverpod.dart';
import 'package:vertic_server_server/src/generated/protocol.dart';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';

/// Facility-Management Endpoint
class FacilityEndpoint extends Endpoint {
  /// Prüft ob StaffUser für Facility-Management berechtigt ist
  Future<int?> _getAuthenticatedStaffUserId(Session session) async {
    return await StaffAuthHelper.getAuthenticatedStaffUserId(session);
  }

  // Alle Einrichtungen abrufen
  Future<List<Facility>> getAllFacilities(Session session) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Facility-Liste verweigert',
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
      return await Facility.db.find(session, orderBy: (f) => f.name);
    } catch (e) {
      session.log('Fehler beim Abrufen der Einrichtungen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Nur aktive Einrichtungen abrufen
  Future<List<Facility>> getActiveFacilities(Session session) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Aktive Facilities verweigert',
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
      return await Facility.db.find(session,
          where: (f) => f.isActive.equals(true), orderBy: (f) => f.name);
    } catch (e) {
      session.log('Fehler beim Abrufen der aktiven Einrichtungen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Einrichtung nach ID abrufen
  Future<Facility?> getFacilityById(Session session, int id) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Facility-Details verweigert',
          level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_facilities');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_view_facilities (User: $authUserId)',
          level: LogLevel.warning);
      return null;
    }

    try {
      return await Facility.db.findById(session, id);
    } catch (e) {
      session.log('Fehler beim Abrufen der Einrichtung: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Einrichtung erstellen
  Future<Facility?> createFacility(Session session, Facility facility) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Facility-Erstellung verweigert',
          level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_create_facilities');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_create_facilities (User: $authUserId)',
          level: LogLevel.warning);
      return null;
    }

    try {
      // 🔍 UNIQUE-CONSTRAINT PRÜFUNG
      final existingFacility = await Facility.db.findFirstRow(
        session,
        where: (f) => f.name.equals(facility.name),
      );

      if (existingFacility != null) {
        throw Exception(
            'Eine Facility mit dem Namen "${facility.name}" existiert bereits');
      }

      final now = DateTime.now().toUtc();
      facility.createdAt = now;
      facility.updatedAt = now;

      final savedFacility = await Facility.db.insertRow(session, facility);
      session.log(
          '✅ Facility "${facility.name}" erstellt von ${await _getAuthenticatedStaffUserId(session)}');

      return savedFacility;
    } catch (e) {
      session.log('Fehler beim Erstellen der Einrichtung: $e',
          level: LogLevel.error);
      rethrow; // Werfe originalen Fehler weiter
    }
  }

  // Einrichtung aktualisieren
  Future<Facility?> updateFacility(Session session, Facility facility) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Facility-Update verweigert',
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
      facility.updatedAt = DateTime.now().toUtc();
      final updated = await Facility.db.updateRow(session, facility);
      session.log(
          '✅ Facility "${facility.name}" aktualisiert von User $authUserId');
      return updated;
    } catch (e) {
      session.log('Fehler beim Aktualisieren der Einrichtung: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Einrichtung löschen
  Future<bool> deleteFacility(Session session, int id) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Facility-Löschung verweigert',
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
      final facility = await Facility.db.findById(session, id);
      if (facility == null) return false;

      await Facility.db.deleteWhere(session, where: (f) => f.id.equals(id));
      session
          .log('✅ Facility "${facility.name}" gelöscht von User $authUserId');
      return true;
    } catch (e) {
      session.log('Fehler beim Löschen der Einrichtung: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// 🔐 PRIVATE: Authenticated StaffUser ermitteln (RICHTIGE IMPLEMENTATION)
  Future<StaffUser?> _getAuthenticatedStaffUser(Session session) async {
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) return null;

    // Hole StaffUser mit der authentifizierten ID
    try {
      return await StaffUser.db.findById(session, authUserId);
    } catch (e) {
      session.log('Fehler beim Laden des StaffUser: $e', level: LogLevel.error);
      return null;
    }
  }

  // ==================== DACH-COMPLIANCE: COUNTRY ASSIGNMENT ====================

  /// **🏛️ SuperUser-only: Facility einem Land zuweisen**
  Future<bool> assignCountryToFacility(
    Session session,
    int facilityId,
    int countryId, {
    bool lockCountry = false,
  }) async {
    // 🔐 RBAC SECURITY CHECK - SuperUser required
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Country-Assignment verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session,
        authUserId,
        'can_manage_country_assignments' // SuperUser-only permission
        );
    if (!hasPermission) {
      session.log(
          '❌ Fehlende SuperUser-Berechtigung für Country-Assignment (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    try {
      // Prüfe ob Facility existiert
      final facility = await Facility.db.findById(session, facilityId);
      if (facility == null) {
        throw Exception('Facility mit ID $facilityId nicht gefunden');
      }

      // Prüfe ob Country existiert und aktiv ist
      final country = await Country.db.findById(session, countryId);
      if (country == null) {
        throw Exception('Land mit ID $countryId nicht gefunden');
      }
      if (!country.isActive) {
        throw Exception('Land ${country.displayName} ist nicht aktiv');
      }

      // Facility aktualisieren mit Country-Zuordnung
      final updatedFacility = facility.copyWith(
        countryId: countryId,
        isCountryLocked: lockCountry,
        countryAssignedByStaffId: authUserId,
        countryAssignedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await Facility.db.updateRow(session, updatedFacility);

      session.log(
        '🏛️ Country-Assignment: Facility "${facility.name}" → Land "${country.displayName}" (${lockCountry ? "LOCKED" : "unlocked"}) by Staff $authUserId',
        level: LogLevel.info,
      );

      return true;
    } catch (e) {
      session.log('❌ Fehler bei Country-Assignment: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **🏛️ SuperUser-only: Country-Lock für Facility ändern**
  Future<bool> toggleFacilityCountryLock(
    Session session,
    int facilityId,
    bool isLocked,
  ) async {
    // 🔐 RBAC SECURITY CHECK - SuperUser required
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Country-Lock-Toggle verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session,
        authUserId,
        'can_manage_country_assignments' // SuperUser-only permission
        );
    if (!hasPermission) {
      session.log(
          '❌ Fehlende SuperUser-Berechtigung für Country-Lock-Toggle (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    try {
      final facility = await Facility.db.findById(session, facilityId);
      if (facility == null) {
        throw Exception('Facility mit ID $facilityId nicht gefunden');
      }

      final updatedFacility = facility.copyWith(
        isCountryLocked: isLocked,
        updatedAt: DateTime.now(),
      );

      await Facility.db.updateRow(session, updatedFacility);

      session.log(
        '🔒 Country-Lock-Toggle: Facility "${facility.name}" → ${isLocked ? "LOCKED" : "UNLOCKED"} by Staff $authUserId',
        level: LogLevel.info,
      );

      return true;
    } catch (e) {
      session.log('❌ Fehler bei Country-Lock-Toggle: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// **🏛️ Facilities nach Land filtern**
  Future<List<Facility>> getFacilitiesByCountry(
      Session session, int countryId) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Facilities-by-Country verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_facilities');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung für Facilities-by-Country (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      return await Facility.db.find(
        session,
        where: (f) => f.countryId.equals(countryId) & f.isActive.equals(true),
        orderBy: (f) => f.name,
      );
    } catch (e) {
      session.log(
          '❌ Fehler beim Abrufen der Facilities für Country $countryId: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// **🏛️ Facilities ohne Land-Zuordnung abrufen**
  Future<List<Facility>> getFacilitiesWithoutCountry(Session session) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Facilities-without-Country verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_facilities');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung für Facilities-without-Country (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      // TODO: Korrekte Serverpod-Syntax für NULL-Checks implementieren
      final allFacilities = await Facility.db.find(
        session,
        where: (f) => f.isActive.equals(true),
        orderBy: (f) => f.name,
      );

      // Filter in Dart - nicht optimal, aber funktional
      return allFacilities.where((f) => f.countryId == null).toList();
    } catch (e) {
      session.log('❌ Fehler beim Abrufen der Facilities ohne Country: $e',
          level: LogLevel.error);
      return [];
    }
  }
}
