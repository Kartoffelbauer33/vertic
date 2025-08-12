import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔐 **StaffAuthProvider - Zentrale Staff-Authentication-Verwaltung**
///
/// Diese Klasse ersetzt den normalen Serverpod SessionManager komplett
/// und ist speziell für Staff-User und das RBAC-System entwickelt.
///
/// Features:
/// - Persistente Staff-Sessions mit SharedPreferences
/// - Integration mit RBAC PermissionProvider
/// - Einfache Staff-User-Verwaltung (Email/Username + Passwort)
/// - Getrennt von Client-App-Authentication
/// - Automatische Session-Wiederherstellung beim App-Start
class StaffAuthProvider extends ChangeNotifier {
  static const String _staffUserKey = 'staff_user_id';
  static const String _staffTokenKey = 'staff_auth_token';
  static const String _staffUserDataKey = 'staff_user_data';

  final Client _client;

  StaffUser? _currentStaffUser;
  String? _authToken;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _lastError;

  StaffAuthProvider(this._client) {
    // Session-Wiederherstellung beim App-Start
    _initializeFromStorage();
  }

  /// **🔧 TEMPORÄRER FIX: Session beim App-Start zurücksetzen**
  Future<void> _resetSessionOnStart() async {
    debugPrint(
      '🔧 TEMP-FIX: Setze Session beim App-Start zurück (wegen Auth-Problemen)',
    );
    await resetSessionForDebug();
    // Nach dem Reset normale Initialisierung
    // await _initializeFromStorage(); // Deaktiviert bis Auth-Problem gelöst ist
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔍 GETTERS
  // ═══════════════════════════════════════════════════════════════

  /// Ist der Staff-User aktuell authentifiziert?
  bool get isAuthenticated => _isAuthenticated;

  /// Aktueller Staff-User (null wenn nicht eingeloggt)
  StaffUser? get currentStaffUser => _currentStaffUser;

  /// Auth-Token für API-Calls (optional, für erweiterte Features)
  String? get authToken => _authToken;

  /// Wird gerade ein Login/Logout durchgeführt?
  bool get isLoading => _isLoading;

  /// Letzter Fehler (null wenn kein Fehler)
  String? get lastError => _lastError;

  /// Staff-Level des aktuellen Users
  StaffUserType? get currentStaffLevel => _currentStaffUser?.staffLevel;

  /// Vollständiger Name des aktuellen Staff-Users
  String get currentStaffDisplayName {
    if (_currentStaffUser == null) return 'Nicht angemeldet';
    return '${_currentStaffUser!.firstName} ${_currentStaffUser!.lastName}';
  }

  /// Email des aktuellen Staff-Users
  String get currentStaffEmail => _currentStaffUser?.email ?? 'Keine E-Mail';

  // ═══════════════════════════════════════════════════════════════
  // 🔑 AUTHENTICATION METHODS
  // ═══════════════════════════════════════════════════════════════

  /// **Staff-Login mit Email/Username + Passwort**
  ///
  /// **🔐 SESSION-FIX: Konsistente Session-ID-Übertragung**
  ///
  /// **SICHERHEITS-IMPLEMENTATION:**
  /// 1. Credentials werden an Server gesendet
  /// 2. Server validiert gegen staff_users Tabelle mit RBAC
  /// 3. AuthToken wird für alle nachfolgenden API-Calls gesetzt
  /// 4. Keine Umgehung von Permission-Checks - RBAC bleibt vollständig aktiv
  Future<bool> signIn(String emailOrUsername, String password) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔐 Staff-Login-Versuch: $emailOrUsername');

      // 🔐 ECHTE Backend-Authentifizierung
      final result = await _client.unifiedAuth.staffLogin(emailOrUsername, password);

      if (result.success == true && result.staffUser != null) {
        // StaffUser direkt aus Response verwenden
        _currentStaffUser = result.staffUser!;
        _authToken = result.staffToken;
        _isAuthenticated = true;

        // 🔐 **STAFF-AUTH-FIX: Authorization Header für Staff-Token setzen**
        //
        // STAFF-AUTHENTIFIZIERUNG (Phase 3.3):
        // - Staff-Token wird über benutzerdefinierten StaffAuthenticationKeyManager gesetzt
        // - Token wird als Base64-codierter Authorization-Header übertragen
        // - Backend StaffAuthHelper erkennt den Token korrekt
        if (_authToken != null) {
          // Staff-Token über benutzerdefinierten Manager setzen
          await _client.authenticationKeyManager?.put(_authToken!);

          debugPrint(
            '🔐 Staff-Token über StaffAuthenticationKeyManager gesetzt: ${_authToken!.length > 16 ? _authToken!.substring(0, 16) + '...' : _authToken!}',
          );
          debugPrint('✅ Staff-Auth für HTTP-Header-Übertragung konfiguriert');
        }

        // Session persistent speichern
        await _saveToStorage();

        debugPrint(
          '✅ Staff-Login erfolgreich: ${_currentStaffUser!.employeeId}',
        );
        debugPrint('👤 Staff-Level: ${_currentStaffUser!.staffLevel}');

        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Login fehlgeschlagen');
        debugPrint('❌ Staff-Login fehlgeschlagen: ${result.message}');
        return false;
      }
    } catch (e) {
      _setError('Verbindungsfehler: $e');
      debugPrint('❌ Staff-Login Exception: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// **Staff-Logout**
  ///
  /// **🔐 SESSION-CLEANUP: Auth-Token vom Client entfernen**
  ///
  /// **SICHERHEITS-IMPLEMENTATION:**
  /// 1. Auth-Token wird vom Client entfernt
  /// 2. Lokale Session-Daten werden gelöscht
  /// 3. Server-Session bleibt gültig bis Timeout (Serverpod-Standard)
  Future<void> signOut() async {
    if (_isLoading) return;

    _setLoading(true);

    try {
      debugPrint('🔓 Staff-Logout...');

      // 🔐 **SESSION-CLEANUP: Auth-Token vom Client entfernen**
      if (_client.authenticationKeyManager != null) {
        await _client.authenticationKeyManager!.remove();
        debugPrint('✅ Auth-Token vom Client entfernt');
      }

      // Session lokal löschen
      await _clearStorage();

      _currentStaffUser = null;
      _authToken = null;
      _isAuthenticated = false;

      debugPrint('✅ Staff-Logout erfolgreich');
    } catch (e) {
      debugPrint('⚠️ Fehler beim Staff-Logout: $e');
      // Logout immer durchführen, auch bei Fehlern
      await _clearStorage();
      if (_client.authenticationKeyManager != null) {
        await _client.authenticationKeyManager!.remove();
      }
      _currentStaffUser = null;
      _authToken = null;
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// **Prüft ob aktueller Staff-User mindestens das erforderliche Level hat**
  bool hasMinimumStaffLevel(StaffUserType requiredLevel) {
    if (_currentStaffUser == null) return false;

    // Super User kann alles
    if (_currentStaffUser!.staffLevel == StaffUserType.superUser) return true;

    // Level-Hierarchie prüfen
    final userLevelValue = _getStaffLevelValue(_currentStaffUser!.staffLevel);
    final requiredLevelValue = _getStaffLevelValue(requiredLevel);

    return userLevelValue >= requiredLevelValue;
  }

  /// **Prüft ob aktueller Staff-User ein bestimmtes Level hat**
  bool hasStaffLevel(StaffUserType level) {
    return _currentStaffUser?.staffLevel == level;
  }

  /// **🔐 NEUE METHODE: Automatische Session-Validierung**
  ///
  /// Prüft bei kritischen API-Calls, ob die Session noch gültig ist
  /// Falls nicht, wird automatisch ein Logout durchgeführt
  Future<bool> validateSession() async {
    if (!_isAuthenticated || _authToken == null) {
      return false;
    }

    try {
      // Test-API-Call um Session-Gültigkeit zu prüfen
      final permissions = await _client.permissionManagement
          .getCurrentUserPermissions();

      if (permissions.isEmpty) {
        debugPrint('⚠️ Session-Validation fehlgeschlagen: Keine Permissions');
        await _forceLogout();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Session-Validation fehlgeschlagen: $e');
      await _forceLogout();
      return false;
    }
  }

  /// **🔓 HILFSMETHODE: Erzwungener Logout bei Session-Problemen**
  Future<void> _forceLogout() async {
    debugPrint('🔄 Erzwinge Logout wegen Session-Validation-Fehler');

    _isAuthenticated = false;
    _currentStaffUser = null;
    _authToken = null;

    await _clearStorage();

    if (_client.authenticationKeyManager != null) {
      await _client.authenticationKeyManager!.remove();
    }

    notifyListeners();
  }

  /// **🔧 DEBUG-METHODE: Session komplett zurücksetzen (für Entwicklung)**
  ///
  /// Setzt alle Session-Daten zurück und erzwingt den Login-Screen
  /// Sollte nur für Debugging und Entwicklung verwendet werden
  Future<void> resetSessionForDebug() async {
    debugPrint('🔧 DEBUG: Session wird komplett zurückgesetzt');

    _isAuthenticated = false;
    _currentStaffUser = null;
    _authToken = null;
    _lastError = null;

    await _clearStorage();

    if (_client.authenticationKeyManager != null) {
      await _client.authenticationKeyManager!.remove();
    }

    notifyListeners();
    debugPrint(
      '✅ DEBUG: Session zurückgesetzt - Login-Screen sollte erscheinen',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 💾 PERSISTENCE METHODS
  // ═══════════════════════════════════════════════════════════════

  /// **Initialisiert Auth-Status aus SharedPreferences**
  ///
  /// **🔐 SESSION-WIEDERHERSTELLUNG: Auth-Token wird auch wiederhergestellt**
  ///
  /// - Auth-Token wird auch für wiederhergestellte Sessions gesetzt
  /// - Konsistente API-Call-Funktionalität nach App-Neustart
  Future<void> _initializeFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final staffUserId = prefs.getInt(_staffUserKey);
      final authToken = prefs.getString(_staffTokenKey);
      final staffUserJson = prefs.getString(_staffUserDataKey);

      if (staffUserId != null && authToken != null && staffUserJson != null) {
        debugPrint(
          '🔄 Staff-Session aus Storage wiederhergestellt: User-ID $staffUserId',
        );

        // 🔐 **SESSION-WIEDERHERSTELLUNG: Auth-Token am Client setzen**
        if (_client.authenticationKeyManager != null) {
          await _client.authenticationKeyManager!.put(authToken);
          debugPrint(
            '✅ Auth-Token wiederhergestellt: ${authToken.length > 8 ? authToken.substring(0, 8) + '...' : authToken}',
          );
        }

        // Temporär Token setzen (wird nur gültig, wenn Server-Check erfolgreich)
        _authToken = authToken;

        // SERVER-CHECK: Prüfe ob der Token noch gültig ist
        try {
          debugPrint('🔍 Prüfe Token-Gültigkeit beim Server...');

          // Wir verwenden den PermissionProvider als Validierung
          // Wenn der Token ungültig ist, schlägt dieser API-Call fehl
          final permissions = await _client.permissionManagement
              .getCurrentUserPermissions();

          if (permissions.isNotEmpty) {
            // Token ist gültig, User-Daten setzen
            debugPrint(
              '✅ Token gültig! ${permissions.length} Permissions geladen',
            );
            _isAuthenticated = true;

            // Versuche Staff-User-Daten zu laden
            try {
              final staffUsers = await _client.staffUserManagement
                  .getAllStaffUsers(limit: 100, offset: 0);

              // 🔧 FIX: Verwende firstWhereOrNull statt firstWhere
              final currentUser = staffUsers.cast<StaffUser?>().firstWhere(
                (user) => user?.id == staffUserId,
                orElse: () => null,
              );

              if (currentUser != null) {
                _currentStaffUser = currentUser;
                debugPrint(
                  '✅ Staff-User-Daten geladen: ${currentUser.firstName} ${currentUser.lastName}',
                );
              } else {
                debugPrint(
                  '⚠️ Staff-User mit ID $staffUserId nicht in Liste gefunden',
                );
                // Trotzdem authentifiziert lassen, da Token gültig ist
              }
            } catch (e) {
              debugPrint('⚠️ Konnte Staff-User-Daten nicht laden: $e');
              // Trotzdem authentifiziert lassen, da Token gültig ist
            }
          } else {
            // Token ungültig oder abgelaufen
            debugPrint('❌ Token ungültig oder abgelaufen (keine Permissions)');
            _isAuthenticated = false;
            await _clearStorage();
          }
        } catch (e) {
          // Bei Server-Fehler: Session als ungültig betrachten
          debugPrint('❌ Server-Check fehlgeschlagen: $e');
          debugPrint('🔄 Erzwinge Logout wegen Authentication-Fehler');
          _isAuthenticated = false;
          _currentStaffUser = null;
          _authToken = null;
          await _clearStorage();

          // 🔐 KRITISCH: Auth-Token auch vom Client entfernen
          if (_client.authenticationKeyManager != null) {
            await _client.authenticationKeyManager!.remove();
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Laden der Staff-Session: $e');
      _isAuthenticated = false;
      await _clearStorage();
      notifyListeners();
    }
  }

  /// **Speichert Auth-Status in SharedPreferences**
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_currentStaffUser?.id != null && _authToken != null) {
        await prefs.setInt(_staffUserKey, _currentStaffUser!.id!);
        await prefs.setString(_staffTokenKey, _authToken!);

        // StaffUser-Daten als einfachen String speichern (vereinfacht)
        final userData =
            '${_currentStaffUser!.firstName}|${_currentStaffUser!.lastName}|${_currentStaffUser!.email}|${_currentStaffUser!.staffLevel}';
        await prefs.setString(_staffUserDataKey, userData);

        debugPrint('💾 Staff-Session gespeichert');
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Speichern der Staff-Session: $e');
    }
  }

  /// **Löscht Auth-Status aus SharedPreferences**
  Future<void> _clearStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_staffUserKey);
      await prefs.remove(_staffTokenKey);
      await prefs.remove(_staffUserDataKey);
      debugPrint('🧹 Staff-Session-Storage geleert');
    } catch (e) {
      debugPrint('⚠️ Fehler beim Löschen der Staff-Session: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🛠️ HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_lastError != error) {
      _lastError = error;
      notifyListeners();
    }
  }

  void _clearError() {
    _setError(null);
  }

  /// **Hilfsfunktion: Staff-Level zu numerischen Werten**
  int _getStaffLevelValue(StaffUserType level) {
    switch (level) {
      case StaffUserType.superUser:
        return 100;
      case StaffUserType.staff:
        return 40;
      default:
        return 0;
    }
  }
}

/// 🔐 **Benutzerdefinierter AuthenticationKeyManager für Staff-Tokens**
///
/// Dieser Manager formatiert Staff-Tokens korrekt als Base64-codierte
/// Authorization-Header, damit sie vom StaffAuthHelper erkannt werden.
class StaffAuthenticationKeyManager extends AuthenticationKeyManager {
  String? _staffToken;

  @override
  Future<String?> get() async {
    return _staffToken;
  }

  @override
  Future<void> put(String key) async {
    _staffToken = key;
    debugPrint(
      '🔐 Staff-Token gesetzt: ${key.length > 16 ? key.substring(0, 16) + '...' : key}',
    );
  }

  @override
  Future<void> remove() async {
    _staffToken = null;
    debugPrint('🔓 Staff-Token entfernt');
  }
}
