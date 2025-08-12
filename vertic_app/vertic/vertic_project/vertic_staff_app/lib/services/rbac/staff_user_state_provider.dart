import 'package:flutter/foundation.dart';
import 'package:test_server_client/test_server_client.dart';
import 'staff_user_management_service.dart';

/// **Staff User State Provider**
/// 
/// Verwaltet den State für Staff-User-Management mit sauberer Trennung von UI und Logik.
/// Verwendet das Provider-Pattern für reaktive UI-Updates.
class StaffUserStateProvider extends ChangeNotifier {
  final StaffUserManagementService _staffService;

  StaffUserStateProvider(Client client) : _staffService = StaffUserManagementService(client);

  // State Variables
  List<StaffUser> _allStaffUsers = [];
  List<StaffUser> _filteredStaffUsers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  bool _showOnlyActive = true;
  String? _filterByRole;

  // Getters
  List<StaffUser> get allStaffUsers => _allStaffUsers;
  List<StaffUser> get filteredStaffUsers => _filteredStaffUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get showOnlyActive => _showOnlyActive;
  String? get filterByRole => _filterByRole;

  /// **Lädt alle Staff-User vom Backend**
  Future<void> loadStaffUsers() async {
    _setLoading(true);
    _clearError();

    try {
      _allStaffUsers = await _staffService.getAllStaffUsers();
      _applyFilters();
      debugPrint('✅ Staff users loaded: ${_allStaffUsers.length} total');
    } catch (e) {
      _setError('Fehler beim Laden der Staff-User: $e');
      debugPrint('❌ Error loading staff users: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// **Erstellt einen neuen Staff-User**
  Future<bool> createStaffUser({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    String? employeeId,
    required StaffUserType staffLevel,
    int? hallId,
    int? facilityId,
    int? departmentId,
    String? contractType,
    double? hourlyRate,
    double? monthlySalary,
    int? workingHours,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Validierung
      final validationError = _staffService.validateStaffUserData(
        firstName: firstName,
        lastName: lastName,
        email: email,
        employeeId: employeeId,
      );
      
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      // Staff-User erstellen
      final newStaffUser = await _staffService.createStaffUser(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        employeeId: employeeId,
        staffLevel: staffLevel,
        hallId: hallId,
        facilityId: facilityId,
        departmentId: departmentId,
        contractType: contractType,
        hourlyRate: hourlyRate,
        monthlySalary: monthlySalary,
        workingHours: workingHours,
      );

      if (newStaffUser != null) {
        // Lokale Liste aktualisieren
        _allStaffUsers.add(newStaffUser);
        _applyFilters();
        debugPrint('✅ Staff user created and added to local state: ${newStaffUser.email}');
        return true;
      } else {
        _setError('Staff-User konnte nicht erstellt werden');
        return false;
      }
    } catch (e) {
      _setError('Fehler beim Erstellen des Staff-Users: $e');
      debugPrint('❌ Error creating staff user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// **Aktualisiert einen bestehenden Staff-User**
  Future<bool> updateStaffUser({
    required int staffUserId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? employeeId,
    StaffUserType? staffLevel,
    int? hallId,
    int? facilityId,
    int? departmentId,
    String? contractType,
    double? hourlyRate,
    double? monthlySalary,
    int? workingHours,
    String? employmentStatus,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedStaffUser = await _staffService.updateStaffUser(
        staffUserId: staffUserId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        employeeId: employeeId,
        staffLevel: staffLevel,
        hallId: hallId,
        facilityId: facilityId,
        departmentId: departmentId,
        contractType: contractType,
        hourlyRate: hourlyRate,
        monthlySalary: monthlySalary,
        workingHours: workingHours,
        employmentStatus: employmentStatus,
      );

      if (updatedStaffUser != null) {
        // Lokale Liste aktualisieren
        final index = _allStaffUsers.indexWhere((u) => u.id == updatedStaffUser.id);
        if (index != -1) {
          _allStaffUsers[index] = updatedStaffUser;
          _applyFilters();
          debugPrint('✅ Staff user updated in local state: ${updatedStaffUser.email}');
        }
        return true;
      } else {
        _setError('Staff-User konnte nicht aktualisiert werden');
        return false;
      }
    } catch (e) {
      _setError('Fehler beim Aktualisieren des Staff-Users: $e');
      debugPrint('❌ Error updating staff user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// **Löscht einen Staff-User**
  Future<bool> deleteStaffUser(StaffUser staffUser) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _staffService.deleteStaffUser(staffUser.id!);

      if (success) {
        // Lokale Liste aktualisieren
        _allStaffUsers.removeWhere((u) => u.id == staffUser.id);
        _applyFilters();
        debugPrint('✅ Staff user deleted from local state: ${staffUser.email}');
        return true;
      } else {
        _setError('Staff-User konnte nicht gelöscht werden');
        return false;
      }
    } catch (e) {
      _setError('Fehler beim Löschen des Staff-Users: $e');
      debugPrint('❌ Error deleting staff user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// **Aktiviert/Deaktiviert einen Staff-User**
  Future<bool> toggleStaffUserStatus(StaffUser staffUser) async {
    final newStatus = staffUser.employmentStatus == 'active' ? 'inactive' : 'active';
    
    return await updateStaffUser(
      staffUserId: staffUser.id!,
      employmentStatus: newStatus,
    );
  }

  /// **Fügt einen neuen Staff-User zur lokalen Liste hinzu (nach Erstellung)**
  void addStaffUser(StaffUser staffUser) {
    _allStaffUsers.add(staffUser);
    _applyFilters();
    debugPrint('➕ Staff user added to local state: ${staffUser.email}');
  }

  /// **Aktualisiert einen Staff-User in der lokalen Liste**
  void updateStaffUserInList(StaffUser updatedStaffUser) {
    final index = _allStaffUsers.indexWhere((u) => u.id == updatedStaffUser.id);
    if (index != -1) {
      _allStaffUsers[index] = updatedStaffUser;
      _applyFilters();
      debugPrint('🔄 Staff user updated in local state: ${updatedStaffUser.email}');
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

  /// **Schaltet zwischen allen und nur aktiven Staff-Usern um**
  void toggleShowOnlyActive() {
    _showOnlyActive = !_showOnlyActive;
    _applyFilters();
    debugPrint('🔄 Show only active toggled: $_showOnlyActive');
  }

  /// **Setzt Rollen-Filter**
  void setRoleFilter(String? role) {
    if (_filterByRole != role) {
      _filterByRole = role;
      _applyFilters();
      debugPrint('🔄 Role filter updated: $role');
    }
  }

  /// **Entfernt alle Filter**
  void clearAllFilters() {
    _searchQuery = '';
    _showOnlyActive = true;
    _filterByRole = null;
    _applyFilters();
    debugPrint('🧹 All filters cleared');
  }

  /// **Validiert Staff-User-Daten**
  String? validateStaffUserData({
    required String firstName,
    required String lastName,
    required String email,
    String? employeeId,
  }) {
    return _staffService.validateStaffUserData(
      firstName: firstName,
      lastName: lastName,
      email: email,
      employeeId: employeeId,
    );
  }

  /// **Generiert eine Employee-ID**
  String generateEmployeeId(String firstName, String lastName) {
    return _staffService.generateEmployeeId(firstName, lastName);
  }

  /// **Formatiert Staff-User für Anzeige**
  String formatStaffUserDisplay(StaffUser staffUser) {
    return _staffService.formatStaffUserDisplay(staffUser);
  }

  /// **Überprüft Email-Verfügbarkeit**
  Future<bool> isEmailAvailable(String email, {int? excludeUserId}) {
    return _staffService.isEmailAvailable(email, excludeUserId: excludeUserId);
  }

  /// **Überprüft Employee-ID-Verfügbarkeit**
  Future<bool> isEmployeeIdAvailable(String employeeId, {int? excludeUserId}) {
    return _staffService.isEmployeeIdAvailable(employeeId, excludeUserId: excludeUserId);
  }

  // Private Helper Methods

  void _applyFilters() {
    List<StaffUser> filtered = List.from(_allStaffUsers);

    // Aktiv-Filter
    if (_showOnlyActive) {
      filtered = filtered.where((user) => user.employmentStatus == 'active').toList();
    }

    // Role-Filter (TODO: Implement role-based filtering)
    if (_filterByRole != null) {
      // This would require loading roles for each user, for now skip
      // filtered = filtered.where((user) => hasRole(user, _filterByRole)).toList();
    }

    // Such-Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
        final email = user.email.toLowerCase();
        final employeeId = user.employeeId?.toLowerCase() ?? '';
        
        return fullName.contains(query) ||
               email.contains(query) ||
               employeeId.contains(query);
      }).toList();
    }

    // Sortierung: SuperUser zuerst, dann nach Namen
    filtered.sort((a, b) {
      // SuperUser zuerst
      if (a.staffLevel == StaffUserType.superUser && b.staffLevel != StaffUserType.superUser) return -1;
      if (a.staffLevel != StaffUserType.superUser && b.staffLevel == StaffUserType.superUser) return 1;
      
      // Dann nach Staff-Level (höher zuerst)
      final levelComparison = b.staffLevel.index.compareTo(a.staffLevel.index);
      if (levelComparison != 0) return levelComparison;
      
      // Zuletzt nach Nachname
      return a.lastName.compareTo(b.lastName);
    });

    _filteredStaffUsers = filtered;
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

  /// **Aktualisiert die Staff-User-Liste (Refresh)**
  Future<void> refresh() async {
    await loadStaffUsers();
  }

  /// **Statistiken für Dashboard**
  Map<String, int> getStatistics() {
    final stats = <String, int>{};
    
    // Gesamt-Counts
    stats['total'] = _allStaffUsers.length;
    stats['active'] = _allStaffUsers.where((u) => u.employmentStatus == 'active').length;
    stats['inactive'] = _allStaffUsers.where((u) => u.employmentStatus != 'active').length;
    
    // Nur SuperUser-Count (andere StaffLevel sind deprecated)
    stats['superUser'] = _allStaffUsers.where((u) => u.staffLevel == StaffUserType.superUser).length;
    
    return stats;
  }

  /// **Gibt Staff-User nach ID zurück**
  StaffUser? getStaffUserById(int id) {
    try {
      return _allStaffUsers.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  /// **Gibt aktive Staff-User nach Staff-Level zurück**
  List<StaffUser> getActiveStaffUsersByLevel(StaffUserType level) {
    return _allStaffUsers
        .where((u) => u.staffLevel == level && u.employmentStatus == 'active')
        .toList();
  }
}