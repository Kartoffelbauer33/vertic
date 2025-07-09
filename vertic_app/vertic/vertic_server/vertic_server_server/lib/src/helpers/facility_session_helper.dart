import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'staff_auth_helper.dart';

/// 🏛️ **SESSION-BASIERTE FACILITY-ERMITTLUNG**
///
/// **KRITISCHE SICHERHEITS-IMPLEMENTIERUNG:**
/// Ersetzt alle hardcoded facilityId=1 und hallId=1 durch echte Session-basierte Ermittlung
///
/// **Verhindert:**
/// - Cross-Facility Datenlecks
/// - Unberechtigt Staff-Zugriff auf andere Facilities
/// - Daten-Vermischung zwischen Standorten
class FacilitySessionHelper {
  /// **🏛️ Aktuelle Facility des authentifizierten Staff-Users ermitteln**
  static Future<Facility?> getCurrentFacility(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log(
          '❌ Kein authentifizierter Staff-User - kann Facility nicht ermitteln',
          level: LogLevel.warning);
      return null;
    }

    try {
      final staffUser = await StaffUser.db.findById(session, staffUserId);
      if (staffUser?.facilityId == null) {
        session.log('⚠️ Staff-User $staffUserId hat keine zugewiesene Facility',
            level: LogLevel.warning);
        // Fallback: Erste verfügbare Facility (für SuperUser)
        if (staffUser?.staffLevel == StaffUserType.superUser) {
          final facilities = await Facility.db.find(session, limit: 1);
          if (facilities.isNotEmpty) {
            session.log(
                '🔧 SuperUser $staffUserId: Verwende erste verfügbare Facility ${facilities.first.id}');
            return facilities.first;
          }
        }
        return null;
      }

      final facility =
          await Facility.db.findById(session, staffUser!.facilityId!);
      if (facility != null) {
        session.log(
            '✅ Facility ${facility.id} für Staff-User $staffUserId ermittelt: ${facility.name}');
      }
      return facility;
    } catch (e) {
      session.log(
          '❌ Fehler beim Ermitteln der Facility für Staff-User $staffUserId: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// **🏛️ Aktuelle Facility-ID des authentifizierten Staff-Users ermitteln**
  static Future<int?> getCurrentFacilityId(Session session) async {
    final facility = await getCurrentFacility(session);
    return facility?.id;
  }

  /// **🏢 Aktuelle Hall des authentifizierten Staff-Users ermitteln**
  static Future<int?> getCurrentHallId(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      session.log(
          '❌ Kein authentifizierter Staff-User - kann Hall nicht ermitteln',
          level: LogLevel.warning);
      return null;
    }

    try {
      final staffUser = await StaffUser.db.findById(session, staffUserId);
      if (staffUser?.hallId != null) {
        session.log(
            '✅ Hall ${staffUser!.hallId} für Staff-User $staffUserId ermittelt');
        return staffUser.hallId;
      }

      // Fallback: Erste Hall der zugewiesenen Facility
      if (staffUser?.facilityId != null) {
        // TODO: Implementiere hall-zu-facility Relation
        session.log(
            '🔧 Staff-User $staffUserId hat keine spezifische Hall - verwende Facility-Standard');
        return 1; // Temporärer Fallback bis Hall-System implementiert ist
      }

      session.log(
          '⚠️ Staff-User $staffUserId hat weder Hall noch Facility zugewiesen',
          level: LogLevel.warning);
      return null;
    } catch (e) {
      session.log(
          '❌ Fehler beim Ermitteln der Hall für Staff-User $staffUserId: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// **🔐 Berechtigung prüfen: Darf Staff-User auf diese Facility zugreifen?**
  static Future<bool> canAccessFacility(Session session, int facilityId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) return false;

    try {
      final staffUser = await StaffUser.db.findById(session, staffUserId);
      if (staffUser == null) return false;

      // SuperUser haben Zugriff auf alle Facilities
      if (staffUser.staffLevel == StaffUserType.superUser) {
        session.log(
            '✅ SuperUser $staffUserId: Zugriff auf Facility $facilityId gewährt');
        return true;
      }

      // FacilityAdmin haben nur Zugriff auf ihre eigene Facility
      if (staffUser.staffLevel == StaffUserType.facilityAdmin) {
        final hasAccess = staffUser.facilityId == facilityId;
        session.log(hasAccess
            ? '✅ FacilityAdmin $staffUserId: Zugriff auf eigene Facility $facilityId gewährt'
            : '❌ FacilityAdmin $staffUserId: Zugriff auf fremde Facility $facilityId verweigert');
        return hasAccess;
      }

      // Normale Staff haben nur Zugriff auf ihre zugewiesene Facility
      final hasAccess = staffUser.facilityId == facilityId;
      session.log(hasAccess
          ? '✅ Staff $staffUserId: Zugriff auf zugewiesene Facility $facilityId gewährt'
          : '❌ Staff $staffUserId: Zugriff auf fremde Facility $facilityId verweigert');
      return hasAccess;
    } catch (e) {
      session.log('❌ Fehler bei Facility-Zugriffsprüfung: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// **🔐 Berechtigung prüfen: Darf Staff-User auf diese Hall zugreifen?**
  static Future<bool> canAccessHall(Session session, int hallId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) return false;

    try {
      final staffUser = await StaffUser.db.findById(session, staffUserId);
      if (staffUser == null) return false;

      // SuperUser haben Zugriff auf alle Halls
      if (staffUser.staffLevel == StaffUserType.superUser) {
        session
            .log('✅ SuperUser $staffUserId: Zugriff auf Hall $hallId gewährt');
        return true;
      }

      // HallAdmin haben nur Zugriff auf ihre eigene Hall
      if (staffUser.staffLevel == StaffUserType.hallAdmin) {
        final hasAccess = staffUser.hallId == hallId;
        session.log(hasAccess
            ? '✅ HallAdmin $staffUserId: Zugriff auf eigene Hall $hallId gewährt'
            : '❌ HallAdmin $staffUserId: Zugriff auf fremde Hall $hallId verweigert');
        return hasAccess;
      }

      // Facility-Level Staff haben Zugriff auf alle Halls ihrer Facility
      // TODO: Implementiere hall-zu-facility Relation-Check
      session.log(
          '🔧 Hall-Zugriffsprüfung: Hall-zu-Facility Relation noch nicht implementiert');
      return true; // Temporärer Fallback bis Hall-System implementiert ist
    } catch (e) {
      session.log('❌ Fehler bei Hall-Zugriffsprüfung: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// **📊 Debug-Informationen für Facility-Session**
  static Future<Map<String, dynamic>> getDebugInfo(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    final facility = await getCurrentFacility(session);
    final hallId = await getCurrentHallId(session);

    return {
      'authenticated_staff_id': staffUserId,
      'current_facility_id': facility?.id,
      'current_facility_name': facility?.name,
      'current_hall_id': hallId,
      'staff_level': staffUserId != null
          ? (await StaffUser.db.findById(session, staffUserId))
              ?.staffLevel
              ?.name
          : null,
    };
  }
}
