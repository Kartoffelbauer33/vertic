import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:vertic_server_server/src/generated/protocol.dart';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';

/// Endpoint für User-Status-Management
class UserStatusEndpoint extends Endpoint {
  /// 🔐 HELPER: RBAC Permission-Check
  Future<bool> _checkPermission(Session session, String permission) async {
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - $permission verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission =
        await PermissionHelper.hasPermission(session, authUserId, permission);
    if (!hasPermission) {
      session.log('❌ Fehlende Berechtigung: $permission (User: $authUserId)',
          level: LogLevel.warning);
    }
    return hasPermission;
  }

  /// Prüft ob StaffUser für Status-Management berechtigt ist
  Future<bool> _isStaffUserAuthorized(Session session,
      {bool requireHighLevel = false}) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) return false;

    final staffUser = await StaffUser.db.findById(session, staffUserId);
    if (staffUser == null) return false;

    if (requireHighLevel) {
      return staffUser.staffLevel == StaffUserType.superUser ||
          staffUser.staffLevel == StaffUserType.facilityAdmin ||
          staffUser.staffLevel == StaffUserType.hallAdmin;
    }

    return true; // Alle StaffUser dürfen Status verwalten
  }

  // Alle Statustypen abrufen
  Future<List<UserStatusType>> getAllStatusTypes(Session session) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_view_user_status_types')) {
      session.log('❌ Nicht eingeloggt - Statustyp-Zugriff verweigert',
          level: LogLevel.warning);
      return [];
    }

    try {
      return await UserStatusType.db.find(
        session,
        orderBy: (t) => t.name,
      );
    } catch (e) {
      session.log('Fehler beim Abrufen der Statustypen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Statustyp nach ID abrufen
  Future<UserStatusType?> getStatusTypeById(Session session, int id) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_view_user_status_types')) {
      session.log('❌ Nicht eingeloggt - Statustyp-Zugriff verweigert',
          level: LogLevel.warning);
      return null;
    }

    try {
      return await UserStatusType.db.findById(session, id);
    } catch (e) {
      session.log('Fehler beim Abrufen des Statustyps: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Neuen Statustyp erstellen
  Future<UserStatusType?> createStatusType(
      Session session, UserStatusType statusType) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_create_user_status_types')) {
      session.log('❌ Nicht eingeloggt - Statustyp-Erstellung verweigert',
          level: LogLevel.warning);
      return null;
    }

    try {
      final now = DateTime.now().toUtc();
      statusType.createdAt = now;
      statusType.updatedAt = now;

      final savedType = await UserStatusType.db.insertRow(session, statusType);
      return savedType;
    } catch (e) {
      session.log('Fehler beim Erstellen des Statustyps: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Statustyp aktualisieren
  Future<UserStatusType?> updateStatusType(
      Session session, UserStatusType statusType) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_edit_user_status_types')) {
      session.log('❌ Nicht eingeloggt - Statustyp-Update verweigert',
          level: LogLevel.warning);
      return null;
    }

    try {
      statusType.updatedAt = DateTime.now().toUtc();
      return await UserStatusType.db.updateRow(session, statusType);
    } catch (e) {
      session.log('Fehler beim Aktualisieren des Statustyps: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Statustyp löschen
  Future<bool> deleteStatusType(Session session, int id) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_delete_user_status_types')) {
      session.log('❌ Nicht eingeloggt - Statustyp-Löschung verweigert',
          level: LogLevel.warning);
      return false;
    }

    try {
      await UserStatusType.db
          .deleteWhere(session, where: (t) => t.id.equals(id));
      return true;
    } catch (e) {
      session.log('Fehler beim Löschen des Statustyps: $e',
          level: LogLevel.error);
      return false;
    }
  }

  // Status eines Benutzers abrufen
  Future<List<UserStatus>> getUserStatuses(Session session, int userId) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_view_user_statuses')) {
      session.log('❌ Nicht eingeloggt - User-Status-Zugriff verweigert',
          level: LogLevel.warning);
      return [];
    }

    try {
      return await UserStatus.db
          .find(session, where: (s) => s.userId.equals(userId));
    } catch (e) {
      session.log('Fehler beim Abrufen der Benutzerstatus: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Verifizierte Status eines Benutzers abrufen
  Future<List<UserStatus>> getVerifiedUserStatuses(
      Session session, int userId) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_view_user_statuses')) {
      session.log('❌ Nicht eingeloggt - Verifizierte Status verweigert',
          level: LogLevel.warning);
      return [];
    }

    try {
      return await UserStatus.db.find(
        session,
        where: (s) => s.userId.equals(userId) & s.isVerified.equals(true),
      );
    } catch (e) {
      session.log('Fehler beim Abrufen der verifizierten Benutzerstatus: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Status beantragen (vom Benutzer)
  Future<UserStatus?> requestStatus(Session session, UserStatus status) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_request_user_status')) {
      session.log('❌ Nicht eingeloggt - Status-Antrag verweigert',
          level: LogLevel.warning);
      return null;
    }

    try {
      final now = DateTime.now().toUtc();
      status.createdAt = now;
      status.updatedAt = now;
      status.isVerified =
          false; // Muss von einem Staff-Mitglied verifiziert werden

      return await UserStatus.db.insertRow(session, status);
    } catch (e) {
      session.log('Fehler beim Beantragen des Status: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Status verifizieren (vom Staff-Mitglied)
  Future<UserStatus?> verifyStatus(Session session, int statusId, int staffId,
      String? notes, DateTime? expiryDate) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_verify_user_status')) {
      session.log('❌ Nicht eingeloggt - Status-Verifizierung verweigert',
          level: LogLevel.warning);
      return null;
    }

    try {
      final status = await UserStatus.db.findById(session, statusId);
      if (status == null) {
        session.log('Status nicht gefunden: $statusId',
            level: LogLevel.warning);
        return null;
      }

      final now = DateTime.now().toUtc();
      status.isVerified = true;
      status.verifiedById = staffId;
      status.verificationDate = now;
      status.updatedAt = now;
      status.notes = notes;
      status.expiryDate = expiryDate;

      return await UserStatus.db.updateRow(session, status);
    } catch (e) {
      session.log('Fehler beim Verifizieren des Status: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Status als primären Status für einen Benutzer setzen
  Future<bool> setPrimaryStatus(
      Session session, int userId, int statusId) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_set_primary_user_status')) {
      session.log('❌ Nicht eingeloggt - Primärer Status verweigert',
          level: LogLevel.warning);
      return false;
    }

    try {
      final status = await UserStatus.db.findById(session, statusId);
      if (status == null || status.userId != userId || !status.isVerified) {
        return false;
      }

      final user = await AppUser.db.findById(session, userId);
      if (user == null) {
        return false;
      }

      user.primaryStatusId = statusId;
      user.updatedAt = DateTime.now().toUtc();

      await AppUser.db.updateRow(session, user);
      return true;
    } catch (e) {
      session.log('Fehler beim Setzen des primären Status: $e',
          level: LogLevel.error);
      return false;
    }
  }

  // Status löschen
  Future<bool> deleteStatus(Session session, int statusId) async {
    // 🔐 RBAC SECURITY CHECK
    if (!await _checkPermission(session, 'can_delete_user_status')) {
      session.log('❌ Nicht eingeloggt - Status-Löschung verweigert',
          level: LogLevel.warning);
      return false;
    }

    try {
      // Prüfen, ob dieser Status als primärer Status verwendet wird
      final usersWithPrimaryStatus = await AppUser.db.find(
        session,
        where: (u) => u.primaryStatusId.equals(statusId),
      );

      // Wenn ja, setzen wir den primären Status auf null
      for (var user in usersWithPrimaryStatus) {
        user.primaryStatusId = null;
        user.updatedAt = DateTime.now().toUtc();
        await AppUser.db.updateRow(session, user);
      }

      // Dann den Status löschen
      await UserStatus.db
          .deleteWhere(session, where: (s) => s.id.equals(statusId));
      return true;
    } catch (e) {
      session.log('Fehler beim Löschen des Status: $e', level: LogLevel.error);
      return false;
    }
  }

  /// 🏢 HIERARCHISCHE STATUS-ANSICHT - SIMPLE VERSION (OHNE MAP-PROBLEME)
  Future<StatusHierarchyResponse> getStatusHierarchy(Session session) async {
    try {
      // 🔐 AUTHENTIFIZIERUNG
      final userId = await StaffAuthHelper.getAuthenticatedStaffUserId(session);
      if (userId == null) {
        session.log('Status-Hierarchie: Nicht eingeloggt!',
            level: LogLevel.error);
        return StatusHierarchyResponse(
          success: false,
          totalStatusTypes: 0,
          totalGyms: 0,
          totalFacilities: 0,
          universalStatusCount: 0,
          error: 'Nicht authentifiziert',
        );
      }

      // Lade echte DB-Daten
      final statusTypes =
          await UserStatusType.db.find(session, orderBy: (t) => t.name);
      final gyms = await Gym.db.find(session, orderBy: (g) => g.name);
      final facilities =
          await Facility.db.find(session, orderBy: (f) => f.name);

      final universalStatusCount = statusTypes
          .where((s) => s.isVerticUniversal == true || s.gymId == null)
          .length;

      // Simple JSON-Strings statt komplexer Maps
      final facilitiesJson = jsonEncode(facilities
          .map((f) => {
                'id': f.id,
                'name': f.name,
                'description': f.description,
                'isActive': f.isActive,
              })
          .toList());

      final statusTypesJson = jsonEncode(statusTypes
          .map((s) => {
                'id': s.id,
                'name': s.name,
                'description': s.description,
                'discountPercentage': s.discountPercentage,
                'gymId': s.gymId,
                'isVerticUniversal': s.isVerticUniversal,
              })
          .toList());

      final gymsJson = jsonEncode(gyms
          .map((g) => {
                'id': g.id,
                'name': g.name,
                'shortCode': g.shortCode,
                'city': g.city,
                'facilityId': g.facilityId,
                'isActive': g.isActive,
              })
          .toList());

      session.log(
          '✅ Status-Hierarchie erfolgreich: ${statusTypes.length} Status, ${gyms.length} Gyms, ${facilities.length} Facilities');

      return StatusHierarchyResponse(
        success: true,
        totalStatusTypes: statusTypes.length,
        totalGyms: gyms.length,
        totalFacilities: facilities.length,
        universalStatusCount: universalStatusCount,
        facilitiesJson: facilitiesJson,
        statusTypesJson: statusTypesJson,
        gymsJson: gymsJson,
      );
    } catch (e) {
      session.log('❌ Fehler in Status-Hierarchie: $e', level: LogLevel.error);
      return StatusHierarchyResponse(
        success: false,
        totalStatusTypes: 0,
        totalGyms: 0,
        totalFacilities: 0,
        universalStatusCount: 0,
        error: e.toString(),
      );
    }
  }

  /// 🏢 HIERARCHISCHE STATUS-ANSICHT (WIE GYM-VERWALTUNG, OHNE SERIALISIERUNGS-PROBLEME)
  Future<Map<String, dynamic>> getHierarchicalStatusTypes(
      Session session) async {
    try {
      // 🔐 AUTHENTIFIZIERUNG (WIE BEI ANDEREN ENDPOINTS)
      final userId = await StaffAuthHelper.getAuthenticatedStaffUserId(session);
      if (userId == null) {
        session.log('Status-Hierarchie: Nicht eingeloggt!',
            level: LogLevel.error);
        return {'success': false, 'error': 'Nicht authentifiziert'};
      }

      // Lade echte DB-Daten
      final statusTypes =
          await UserStatusType.db.find(session, orderBy: (t) => t.name);
      final gyms = await Gym.db.find(session, orderBy: (g) => g.name);
      final facilities =
          await Facility.db.find(session, orderBy: (f) => f.name);

      // 🌐 Vertic Universal Status (echte Daten)
      final universalStatusCount = statusTypes
          .where((s) => s.isVerticUniversal == true || s.gymId == null)
          .length;

      // 🏋️ Universal Gyms (ohne Facility)
      final universalGyms = gyms.where((g) => g.facilityId == null).toList();

      // 🏢 Facility-Gym-Mapping (VOLLSTÄNDIG MANUELL!)
      final facilityData = <Map<String, dynamic>>[];
      session.log(
          '🐛 DEBUG: Starte Facility-Verarbeitung für ${facilities.length} Facilities');

      for (final facility in facilities) {
        session.log('🐛 DEBUG: Verarbeite Facility: ${facility.name}');

        final facilityGyms =
            gyms.where((g) => g.facilityId == facility.id).toList();
        session.log(
            '🐛 DEBUG: Facility ${facility.name} hat ${facilityGyms.length} Gyms');

        final facilityStatusCount = statusTypes
            .where((s) =>
                facilityGyms.any((gym) => gym.id == s.gymId) &&
                !s.isVerticUniversal)
            .length;

        // Erstelle Gym-Liste komplett manuell
        final gymsList = <Map<String, dynamic>>[];
        for (final g in facilityGyms) {
          final gymStatusCount = statusTypes
              .where((s) => s.gymId == g.id && !s.isVerticUniversal)
              .length;

          gymsList.add({
            'id': g.id,
            'name': g.name,
            'shortCode': g.shortCode,
            'city': g.city,
            'isActive': g.isActive,
            'statusCount': gymStatusCount,
          });
        }
        session.log(
            '🐛 DEBUG: ${gymsList.length} Gyms für Facility ${facility.name} serialisiert');

        facilityData.add({
          'id': facility.id,
          'name': facility.name,
          'description': facility.description,
          'isActive': facility.isActive,
          'gymCount': facilityGyms.length,
          'statusCount': facilityStatusCount,
          'gyms': gymsList,
        });
        session
            .log('🐛 DEBUG: Facility ${facility.name} komplett serialisiert');
      }
      session
          .log('🐛 DEBUG: Alle ${facilityData.length} Facilities verarbeitet');

      session.log(
          '✅ Status-Hierarchie: ${statusTypes.length} Status, ${gyms.length} Gyms, ${facilities.length} Facilities');

      // 🐛 DEBUG: Erstelle Response-Map schrittweise und logge jeden Schritt
      session.log('🐛 DEBUG: Erstelle Response-Map...');

      final responseMap = <String, dynamic>{};

      // Schritt 1: Success flag
      responseMap['success'] = true;
      session.log('🐛 DEBUG: Success flag gesetzt');

      // Schritt 2: Summary
      responseMap['summary'] = {
        'totalStatusTypes': statusTypes.length,
        'totalGyms': gyms.length,
        'totalFacilities': facilities.length,
        'universalStatusCount': universalStatusCount,
      };
      session.log('🐛 DEBUG: Summary erstellt');

      // Schritt 3: Vertic Universal
      responseMap['vertic_universal'] = {
        'statusCount': universalStatusCount,
        'gymCount': universalGyms.length,
      };
      session.log('🐛 DEBUG: Vertic Universal erstellt');

      // Schritt 4: Facilities (das ist wahrscheinlich das Problem!)
      session.log('🐛 DEBUG: Verarbeite ${facilityData.length} Facilities...');
      responseMap['facilities'] = facilityData;
      session.log('🐛 DEBUG: Facilities hinzugefügt');

      // Schritt 5: Universal Gyms
      final universalGymsList = <Map<String, dynamic>>[];
      for (final g in universalGyms) {
        final gymMap = {
          'id': g.id,
          'name': g.name,
          'shortCode': g.shortCode,
          'city': g.city,
          'isActive': g.isActive,
          'statusCount': statusTypes
              .where((s) => s.gymId == g.id && !s.isVerticUniversal)
              .length,
        };
        universalGymsList.add(gymMap);
      }
      responseMap['universal_gyms'] = universalGymsList;
      session.log(
          '🐛 DEBUG: ${universalGymsList.length} Universal Gyms hinzugefügt');

      // Schritt 6: Alle Listen
      final allStatusTypesList = <Map<String, dynamic>>[];
      for (final s in statusTypes) {
        final statusMap = {
          'id': s.id,
          'name': s.name,
          'description': s.description,
          'discountPercentage': s.discountPercentage,
          'gymId': s.gymId,
          'isVerticUniversal': s.isVerticUniversal,
          'requiresVerification': s.requiresVerification,
        };
        allStatusTypesList.add(statusMap);
      }
      responseMap['all_status_types'] = allStatusTypesList;
      session.log(
          '🐛 DEBUG: ${allStatusTypesList.length} Status-Typen hinzugefügt');

      final allGymsList = <Map<String, dynamic>>[];
      for (final g in gyms) {
        final gymMap = {
          'id': g.id,
          'name': g.name,
          'shortCode': g.shortCode,
          'city': g.city,
          'facilityId': g.facilityId,
          'isActive': g.isActive,
        };
        allGymsList.add(gymMap);
      }
      responseMap['all_gyms'] = allGymsList;
      session.log('🐛 DEBUG: ${allGymsList.length} Gyms hinzugefügt');

      final allFacilitiesList = <Map<String, dynamic>>[];
      for (final f in facilities) {
        final facilityMap = {
          'id': f.id,
          'name': f.name,
          'description': f.description,
          'isActive': f.isActive,
        };
        allFacilitiesList.add(facilityMap);
      }
      responseMap['all_facilities'] = allFacilitiesList;
      session
          .log('🐛 DEBUG: ${allFacilitiesList.length} Facilities hinzugefügt');

      session.log(
          '🐛 DEBUG: Response-Map komplett erstellt! Größe: ${responseMap.length} Keys');
      session.log('🐛 DEBUG: Keys: ${responseMap.keys.join(", ")}');

      // 🏗️ VOLLSTÄNDIG MANUELLE SERIALISIERUNG (KEIN SERVERPOD toJson())
      return responseMap;
    } catch (e) {
      session.log('❌ Fehler in Status-Hierarchie: $e', level: LogLevel.error);
      return {
        'success': false,
        'error': e.toString(),
        'summary': {
          'totalStatusTypes': 0,
          'totalGyms': 0,
          'totalFacilities': 0
        },
        'vertic_universal': {'statusCount': 0, 'gymCount': 0},
        'facilities': <Map<String, dynamic>>[],
        'universal_gyms': <Map<String, dynamic>>[],
      };
    }
  }

  /// 🏢 STATUS-TYPEN FÜR BESTIMMTE FACILITY ABRUFEN
  Future<List<UserStatusType>> getStatusTypesForFacility(
      Session session, int facilityId) async {
    try {
      // Lade Gyms der Facility
      final facilityGyms = await Gym.db
          .find(session, where: (g) => g.facilityId.equals(facilityId));
      final gymIds =
          facilityGyms.map((gym) => gym.id!).toSet(); // ✅ Set statt List

      if (gymIds.isEmpty) return [];

      // Lade Status-Typen für diese Gyms
      return await UserStatusType.db.find(session,
          where: (s) => s.gymId.inSet(gymIds), orderBy: (s) => s.name);
    } catch (e) {
      session.log('Fehler beim Laden der Facility-Status-Typen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// 🏋️ STATUS-TYPEN FÜR BESTIMMTES GYM ABRUFEN
  Future<List<UserStatusType>> getStatusTypesForGym(
      Session session, int gymId) async {
    try {
      return await UserStatusType.db.find(session,
          where: (s) => s.gymId.equals(gymId), orderBy: (s) => s.name);
    } catch (e) {
      session.log('Fehler beim Laden der Gym-Status-Typen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Alle offenen Status-Anträge (noch nicht verifiziert)
  Future<List<UserStatus>> getPendingUserStatuses(Session session) async {
    return await UserStatus.db.find(
      session,
      where: (s) => s.isVerified.equals(false),
      orderBy: (s) => s.createdAt,
      orderDescending: false,
    );
  }

  // Status-Antrag bestätigen oder ablehnen
  Future<bool> verifyUserStatus(
      Session session, int userStatusId, bool accepted) async {
    final staffId = await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffId == null) return false;
    final status = await UserStatus.db.findById(session, userStatusId);
    if (status == null) return false;
    status.isVerified = accepted;
    status.verifiedById = staffId;
    status.verificationDate = DateTime.now().toUtc();
    if (accepted) {
      // Ablaufdatum ggf. setzen (z.B. 1 Jahr ab jetzt, kann angepasst werden)
      status.expiryDate = DateTime.now().toUtc().add(const Duration(days: 365));
    }
    await UserStatus.db.updateRow(session, status);
    return true;
  }

  // Standard Status-Typen erstellen
  Future<bool> createDefaultStatusTypes(Session session) async {
    try {
      // Prüfe ob bereits Status-Typen existieren
      final existingTypes = await UserStatusType.db.find(session);
      if (existingTypes.isNotEmpty) {
        session.log('Status-Typen bereits vorhanden, überspringe Erstellung');
        return true;
      }

      final now = DateTime.now().toUtc();

      // Standard Status-Typen erstellen
      final statusTypes = [
        UserStatusType(
          name: 'Standard',
          description: 'Standard-Status ohne Ermäßigung',
          discountPercentage: 0,
          fixedDiscountAmount: null,
          requiresVerification: false,
          requiresDocumentation: false,
          validityPeriod: 0,
          createdAt: now,
        ),
        UserStatusType(
          name: 'Student',
          description: 'Ermäßigter Status für Studenten',
          discountPercentage: 20,
          fixedDiscountAmount: null,
          requiresVerification: true,
          requiresDocumentation: true,
          validityPeriod: 365,
          createdAt: now,
        ),
        UserStatusType(
          name: 'Senior',
          description: 'Ermäßigter Status für Senioren ab 65',
          discountPercentage: 15,
          fixedDiscountAmount: null,
          requiresVerification: false,
          requiresDocumentation: false,
          validityPeriod: 0,
          createdAt: now,
        ),
        UserStatusType(
          name: 'VIP',
          description: 'Premium-Status mit maximaler Ermäßigung',
          discountPercentage: 25,
          fixedDiscountAmount: null,
          requiresVerification: true,
          requiresDocumentation: false,
          validityPeriod: 365,
          createdAt: now,
        ),
        UserStatusType(
          name: 'Mitarbeiter',
          description: 'Status für Fitnessstudio-Mitarbeiter',
          discountPercentage: 50,
          fixedDiscountAmount: null,
          requiresVerification: true,
          requiresDocumentation: true,
          validityPeriod: 0,
          createdAt: now,
        ),
      ];

      // Alle Status-Typen in die Datenbank einfügen
      for (final statusType in statusTypes) {
        await UserStatusType.db.insertRow(session, statusType);
      }

      session.log(
          '${statusTypes.length} Standard-Status-Typen erfolgreich erstellt');
      return true;
    } catch (e) {
      session.log('Fehler beim Erstellen der Standard-Status-Typen: $e',
          level: LogLevel.error);
      return false;
    }
  }
}
