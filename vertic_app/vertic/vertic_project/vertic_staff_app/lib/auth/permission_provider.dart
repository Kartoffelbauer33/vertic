import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';

/// **PermissionProvider - Zentrale State-Verwaltung für UI-Berechtigungen**
///
/// Nutzt das `ChangeNotifier`-Pattern, um die Benutzeroberfläche effizient
/// über Änderungen im Berechtigungsstatus zu informieren.
class PermissionProvider extends ChangeNotifier {
  final Client _client;
  Set<String> _permissions = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  PermissionProvider(this._client);

  /// Gibt das Set der aktuell geladenen Berechtigungen zurück.
  Set<String> get permissions => _permissions;

  /// Gibt an, ob gerade Berechtigungen vom Server geladen werden.
  bool get isLoading => _isLoading;

  /// Gibt `true` zurück, sobald die Berechtigungen initial geladen wurden.
  bool get isInitialized => _isInitialized;

  /// **Prüft, ob der Benutzer eine bestimmte Berechtigung besitzt.**
  ///
  /// Dies ist die Hauptmethode, die von UI-Widgets aufgerufen wird.
  /// Sie ist schnell, da sie nur auf das zwischengespeicherte Set zugreift.
  bool hasPermission(String permission) {
    // Admins haben implizit alle Berechtigungen
    if (_permissions.contains('is_super_admin')) {
      return true;
    }
    return _permissions.contains(permission);
  }

  /// **Lädt die Berechtigungen für einen bestimmten Staff-User vom Server.**
  ///
  /// Nutzt die neue Staff-Auth-Integration ohne Serverpod-Session-Abhängigkeit
  /// **PERFORMANCE-OPTIMIERT:** Verhindert Doppelaufrufe für gleiche User-ID
  int? _lastLoadedUserId;

  Future<void> fetchPermissionsForStaff(int staffUserId) async {
    // **PERFORMANCE-CHECK:** Gleiche User-ID bereits geladen?
    if (_isInitialized && _lastLoadedUserId == staffUserId) {
      debugPrint(
        '🔄 Permissions für User $staffUserId bereits geladen - überspringe',
      );
      return;
    }

    if (_isLoading) return;

    _isLoading = true;
    _isInitialized = false;
    notifyListeners();

    try {
      final userPermissions = await _client.permissionManagement
          .getStaffUserPermissions(staffUserId);

      _permissions = userPermissions.toSet();
      _isInitialized = true;
      _lastLoadedUserId = staffUserId;

      debugPrint(
        '✅ Staff-Berechtigungen geladen für User $staffUserId: ${_permissions.length}',
      );
      debugPrint('🔐 Permissions: ${_permissions.join(", ")}');
    } catch (e) {
      debugPrint(
        '❌ Fehler beim Laden der Staff-Berechtigungen für User $staffUserId: $e',
      );
      _permissions = {}; // Im Fehlerfall leeren
      _lastLoadedUserId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// **Lädt die Berechtigungen des aktuell eingeloggten Staff-Users vom Server.**
  ///
  /// Wird typischerweise nach dem Login oder beim App-Start aufgerufen.
  /// Informiert alle Listener (UI-Widgets) nach erfolgreichem Laden.
  Future<void> fetchPermissions() async {
    if (_isLoading) return;

    _isLoading = true;
    _isInitialized = false;
    notifyListeners();

    try {
      final userPermissions =
          await _client.permissionManagement.getCurrentUserPermissions();

      _permissions = userPermissions.toSet();
      _isInitialized = true;

      debugPrint('✅ Berechtigungen geladen: ${_permissions.length}');
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Berechtigungen: $e');
      _permissions = {}; // Im Fehlerfall leeren
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// **Setzt den Berechtigungsstatus zurück.**
  ///
  /// Wird beim Logout aufgerufen, um den Zustand für den nächsten Benutzer zu bereinigen.
  void clearPermissions() {
    _permissions = {};
    _isInitialized = false;
    _lastLoadedUserId = null; // Cache zurücksetzen
    notifyListeners();
    debugPrint('🧹 Berechtigungen zurückgesetzt (Logout).');
  }
}
