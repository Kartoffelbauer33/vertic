import 'package:flutter/foundation.dart';
import 'package:test_server_client/test_server_client.dart';
import 'role_management_service.dart';

/// **Role State Provider**
/// 
/// Verwaltet den State für Rollen-Management mit sauberer Trennung von UI und Logik.
/// Verwendet das Provider-Pattern für reaktive UI-Updates.
class RoleStateProvider extends ChangeNotifier {
  final RoleManagementService _roleService;

  RoleStateProvider(Client client) : _roleService = RoleManagementService(client);

  // State Variables
  List<Role> _allRoles = [];
  List<Role> _filteredRoles = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  bool _showOnlyActive = true;

  // Getters
  List<Role> get allRoles => _allRoles;
  List<Role> get filteredRoles => _filteredRoles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get showOnlyActive => _showOnlyActive;

  /// **Lädt alle Rollen vom Backend**
  Future<void> loadRoles() async {
    _setLoading(true);
    _clearError();

    try {
      _allRoles = await _roleService.getAllRoles();
      _applyFilters();
      debugPrint('✅ Roles loaded: ${_allRoles.length} total');
    } catch (e) {
      _setError('Fehler beim Laden der Rollen: $e');
      debugPrint('❌ Error loading roles: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// **Erstellt eine neue Rolle**
  Future<bool> createRole({
    required String name,
    required String displayName,
    String? description,
    String? color,
    String? iconName,
    int sortOrder = 0,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Validierung
      final validationError = _roleService.validateRoleData(
        name: name,
        displayName: displayName,
        color: color,
      );
      
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      // Rolle erstellen
      final newRole = await _roleService.createRole(
        name: name,
        displayName: displayName,
        description: description,
        color: color,
        iconName: iconName,
        sortOrder: sortOrder,
      );

      if (newRole != null) {
        // Lokale Liste aktualisieren
        _allRoles.add(newRole);
        _applyFilters();
        debugPrint('✅ Role created and added to local state: ${newRole.displayName}');
        return true;
      } else {
        _setError('Rolle konnte nicht erstellt werden');
        return false;
      }
    } catch (e) {
      _setError('Fehler beim Erstellen der Rolle: $e');
      debugPrint('❌ Error creating role: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// **Aktualisiert eine bestehende Rolle**
  Future<bool> updateRole(Role role) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedRole = await _roleService.updateRole(role);

      if (updatedRole != null) {
        // Lokale Liste aktualisieren
        final index = _allRoles.indexWhere((r) => r.id == updatedRole.id);
        if (index != -1) {
          _allRoles[index] = updatedRole;
          _applyFilters();
          debugPrint('✅ Role updated in local state: ${updatedRole.displayName}');
        }
        return true;
      } else {
        _setError('Rolle konnte nicht aktualisiert werden');
        return false;
      }
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Rolle: $e');
      debugPrint('❌ Error updating role: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// **Löscht eine Rolle**
  Future<bool> deleteRole(Role role) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _roleService.deleteRole(role.id!, role.displayName);

      if (success) {
        // Lokale Liste aktualisieren
        _allRoles.removeWhere((r) => r.id == role.id);
        _applyFilters();
        debugPrint('✅ Role deleted from local state: ${role.displayName}');
        return true;
      } else {
        _setError('Rolle konnte nicht gelöscht werden');
        return false;
      }
    } catch (e) {
      _setError('Fehler beim Löschen der Rolle: $e');
      debugPrint('❌ Error deleting role: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// **Aktiviert/Deaktiviert eine Rolle**
  Future<bool> toggleRoleStatus(Role role) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedRole = await _roleService.toggleRoleStatus(role);

      if (updatedRole != null) {
        // Lokale Liste aktualisieren
        final index = _allRoles.indexWhere((r) => r.id == updatedRole.id);
        if (index != -1) {
          _allRoles[index] = updatedRole;
          _applyFilters();
          debugPrint('✅ Role status toggled: ${updatedRole.displayName} -> ${updatedRole.isActive}');
        }
        return true;
      } else {
        _setError('Rollen-Status konnte nicht geändert werden');
        return false;
      }
    } catch (e) {
      _setError('Fehler beim Ändern des Rollen-Status: $e');
      debugPrint('❌ Error toggling role status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// **Setzt den Suchfilter**
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
      debugPrint('🔍 Search query updated: "$query"');
    }
  }

  /// **Schaltet zwischen allen und nur aktiven Rollen um**
  void toggleShowOnlyActive() {
    _showOnlyActive = !_showOnlyActive;
    _applyFilters();
    debugPrint('🔄 Show only active toggled: $_showOnlyActive');
  }

  /// **Generiert einen eindeutigen Rollen-Namen**
  String generateRoleName(String displayName) {
    return _roleService.generateRoleName(displayName);
  }

  /// **Validiert Rollen-Daten**
  String? validateRoleData({
    required String name,
    required String displayName,
    String? color,
  }) {
    return _roleService.validateRoleData(
      name: name,
      displayName: displayName,
      color: color,
    );
  }

  // Private Helper Methods

  void _applyFilters() {
    List<Role> filtered = List.from(_allRoles);

    // Aktiv-Filter
    if (_showOnlyActive) {
      filtered = filtered.where((role) => role.isActive).toList();
    }

    // Such-Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((role) {
        return role.displayName.toLowerCase().contains(query) ||
               role.name.toLowerCase().contains(query) ||
               (role.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sortierung: System-Rollen zuerst, dann nach sortOrder
    filtered.sort((a, b) {
      if (a.isSystemRole && !b.isSystemRole) return -1;
      if (!a.isSystemRole && b.isSystemRole) return 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });

    _filteredRoles = filtered;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void _clearError() {
    _setError(null);
  }

  /// **Aktualisiert die Rollen-Liste (Refresh)**
  Future<void> refresh() async {
    await loadRoles();
  }
}
