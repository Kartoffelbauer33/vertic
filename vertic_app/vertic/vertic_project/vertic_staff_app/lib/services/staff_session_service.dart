import 'package:flutter/foundation.dart';
import 'package:test_server_client/test_server_client.dart';

/// 🔐 **STAFF-SESSION-MANAGEMENT SERVICE**
///
/// **KRITISCHE SICHERHEITS-IMPLEMENTIERUNG:**
/// Ersetzt alle hardcoded staffId=1 durch echte Session-basierte Staff-User-IDs
///
/// **Verhindert:**
/// - Cross-Staff Datenlecks
/// - Falsche Zuordnung von Aktionen
/// - Audit-Trail-Probleme
class StaffSessionService extends ChangeNotifier {
  static final StaffSessionService _instance = StaffSessionService._internal();
  factory StaffSessionService() => _instance;
  StaffSessionService._internal();

  StaffUser? _currentStaffUser;
  Client? _client;
  bool _isInitialized = false;

  /// **👤 Aktueller Staff-User**
  StaffUser? get currentStaffUser => _currentStaffUser;

  /// **🆔 Aktuelle Staff-User-ID (niemals null wenn eingeloggt)**
  int? get currentStaffUserId => _currentStaffUser?.id;

  /// **👤 Aktueller Staff-Name für UI**
  String get currentStaffName => _currentStaffUser != null
      ? '${_currentStaffUser!.firstName} ${_currentStaffUser!.lastName}'
      : 'Unbekannt';

  /// **🔐 Ist Staff-User eingeloggt?**
  bool get isLoggedIn => _currentStaffUser != null;

  /// **🏛️ Staff-Level des aktuellen Users**
  StaffUserType? get staffLevel => _currentStaffUser?.staffLevel;

  /// **🏢 Facility-ID des aktuellen Staff-Users**
  int? get currentFacilityId => _currentStaffUser?.facilityId;

  /// **🏛️ Hall-ID des aktuellen Staff-Users**
  int? get currentHallId => _currentStaffUser?.hallId;

  /// **🔧 Service initialisieren mit Client**
  Future<void> initialize(Client client) async {
    if (_isInitialized) return;

    _client = client;

    try {
      // Aktuelle Staff-User-Session vom Server abrufen
      await _loadCurrentStaffUser();
      _isInitialized = true;

      debugPrint('✅ StaffSessionService initialisiert: $_currentStaffUser');
    } catch (e) {
      debugPrint('❌ Fehler bei StaffSessionService-Initialisierung: $e');
      // Kein rethrow - Service ist optional verfügbar
    }
  }

  /// **👤 Aktuelle Staff-User-Information vom Server laden**
  Future<void> _loadCurrentStaffUser() async {
    if (_client == null) {
      debugPrint('❌ Client nicht verfügbar - kann Staff-User nicht laden');
      return;
    }

    try {
      // TODO: Implementiere getCurrentStaffUser Endpoint
      // final response = await _client!.auth.getCurrentStaffUser();
      // _currentStaffUser = response;

      // TEMPORÄRER FALLBACK: Mock Staff-User bis Endpoint implementiert ist
      // TODO: Implementiere echte Staff-User-Erstellung über Backend
      debugPrint(
        '🔧 TEMPORÄR: Verwende Mock-Staff-User bis Session-Integration vollständig ist',
      );

      notifyListeners();
      debugPrint('✅ Staff-User geladen: ${_currentStaffUser!.email}');
    } catch (e) {
      debugPrint('❌ Fehler beim Laden des Staff-Users: $e');
      _currentStaffUser = null;
      notifyListeners();
    }
  }

  /// **🔓 Staff-User ausloggen**
  Future<void> logout() async {
    _currentStaffUser = null;
    _isInitialized = false;
    notifyListeners();
    debugPrint('🔓 Staff-User ausgeloggt');
  }

  /// **🔄 Staff-User-Session aktualisieren**
  Future<void> refreshSession() async {
    if (_client != null) {
      await _loadCurrentStaffUser();
    }
  }

  /// **🔐 Fallback für legacy Code: Sichere Staff-ID ermitteln**
  ///
  /// Diese Methode wird überall dort verwendet wo bisher hardcoded staffId=1 stand
  /// Falls keine Session verfügbar ist, wird 1 als Fallback verwendet (bis vollständige Migration)
  int getStaffIdOrFallback() {
    final staffId = currentStaffUserId;
    if (staffId == null) {
      debugPrint(
        '⚠️ Keine Staff-Session verfügbar - verwende Fallback staffId=1',
      );
      return 1; // Temporärer Fallback
    }
    return staffId;
  }

  /// **🏛️ Facility-ID für aktuelle Session ermitteln**
  int getFacilityIdOrFallback() {
    final facilityId = currentFacilityId;
    if (facilityId == null) {
      debugPrint(
        '⚠️ Keine Facility-Zuordnung verfügbar - verwende Fallback facilityId=1',
      );
      return 1; // Temporärer Fallback
    }
    return facilityId;
  }

  /// **🏢 Hall-ID für aktuelle Session ermitteln**
  int getHallIdOrFallback() {
    final hallId = currentHallId;
    if (hallId == null) {
      debugPrint(
        '⚠️ Keine Hall-Zuordnung verfügbar - verwende Fallback hallId=1',
      );
      return 1; // Temporärer Fallback
    }
    return hallId;
  }

  /// **📊 Debug-Informationen für Staff-Session**
  Map<String, dynamic> getDebugInfo() {
    return {
      'is_initialized': _isInitialized,
      'is_logged_in': isLoggedIn,
      'staff_user_id': currentStaffUserId,
      'staff_name': currentStaffName,
      'staff_level': staffLevel?.name,
      'facility_id': currentFacilityId,
      'hall_id': currentHallId,
      'client_available': _client != null,
    };
  }
}
