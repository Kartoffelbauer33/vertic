import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'rbac_data_service.dart';

/// **🎯 RBAC State Provider**
/// 
/// Zentrales State Management für RBAC-Daten
/// Verwendet ChangeNotifier für effiziente UI-Updates
class RbacStateProvider extends ChangeNotifier {
  final RbacDataService _dataService;

  RbacStateProvider(this._dataService);

  // ═══════════════════════════════════════════════════════════════
  // 📊 STATE VARIABLES (exakt aus RBAC-Management-Page extrahiert)
  // ═══════════════════════════════════════════════════════════════

  // Loading states
  bool _isLoading = true;
  String? _errorMessage;

  // Data stores
  List<Permission> _allPermissions = [];
  List<Role> _allRoles = [];
  List<StaffUser> _staffUsers = [];
  final Map<String, List<Permission>> _permissionsByCategory = {};

  // Search & Filter (exakt aus RBAC-Management-Page)
  String _searchQuery = '';
  String _selectedCategory = 'all';
  Set<String> _availableCategories = {'all'};

  // ═══════════════════════════════════════════════════════════════
  // 📖 GETTERS (exakt aus RBAC-Management-Page extrahiert)
  // ═══════════════════════════════════════════════════════════════

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Permission> get allPermissions => _allPermissions;
  List<Role> get allRoles => _allRoles;
  List<StaffUser> get staffUsers => _staffUsers;
  Map<String, List<Permission>> get permissionsByCategory => _permissionsByCategory;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  Set<String> get availableCategories => _availableCategories;

  /// **🔍 Gefilterte Permissions basierend auf Suche und Kategorie**
  /// (Exakt aus RBAC-Management-Page extrahiert)
  List<Permission> get filteredPermissions {
    var permissions = _selectedCategory == 'all'
        ? _allPermissions
        : _permissionsByCategory[_selectedCategory] ?? [];

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      permissions = permissions
          .where((p) =>
              p.displayName.toLowerCase().contains(query) ||
              p.name.toLowerCase().contains(query) ||
              (p.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return permissions;
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔄 DATA LOADING (exakt aus RBAC-Management-Page extrahiert)
  // ═══════════════════════════════════════════════════════════════

  /// **🔍 Suchquery aktualisieren**
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// **📂 Kategorie-Filter aktualisieren**
  void updateSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// **🔄 Lädt alle RBAC-Daten**
  /// (Exakt aus _loadInitialData in RBAC-Management-Page extrahiert)
  Future<void> loadInitialData() async {
    _setLoading(true);
    _setError(null);

    try {
      // Parallel laden für bessere Performance
      final bundle = await _dataService.loadAllRbacData();

      _allPermissions = bundle.permissions;
      _allRoles = bundle.roles;
      _staffUsers = bundle.staffUsers;

      // Permission-Kategorien extrahieren
      _buildPermissionCategories();

      _setLoading(false);
      debugPrint('✅ RbacStateProvider: RBAC-Daten geladen: ${_allPermissions.length} Permissions, ${_allRoles.length} Roles');
    } catch (e) {
      _setLoading(false);
      _setError('Fehler beim Laden der RBAC-Daten: $e');
      debugPrint('❌ RbacStateProvider: RBAC-Daten Fehler: $e');
    }
  }

  /// **📁 Organisiert Permissions nach Kategorien**
  /// (Exakt aus _buildPermissionCategories in RBAC-Management-Page extrahiert)
  void _buildPermissionCategories() {
    _permissionsByCategory.clear();
    _availableCategories = {'all'};

    for (final permission in _allPermissions) {
      final category = permission.category;
      _availableCategories.add(category);

      if (!_permissionsByCategory.containsKey(category)) {
        _permissionsByCategory[category] = [];
      }
      _permissionsByCategory[category]!.add(permission);
    }

    // Sortiere Kategorien
    for (final category in _permissionsByCategory.keys) {
      _permissionsByCategory[category]!
          .sort((a, b) => a.displayName.compareTo(b.displayName));
    }

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔍 SEARCH & FILTER (exakt aus RBAC-Management-Page extrahiert)
  // ═══════════════════════════════════════════════════════════════

  /// **🔍 Setzt Suchquery**
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// **📁 Setzt ausgewählte Kategorie**
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// **🔄 Setzt alle Filter zurück**
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'all';
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // 👤 STAFF USER OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// **👤 Löscht Staff User**
  /// (Exakt aus _deleteStaffUser in RBAC-Management-Page extrahiert)
  Future<bool> deleteStaffUser(StaffUser staffUser) async {
    try {
      await _dataService.deleteStaffUser(staffUser.id!);
      
      // Entferne aus lokaler Liste
      _staffUsers.removeWhere((user) => user.id == staffUser.id);
      notifyListeners();
      
      debugPrint('✅ RbacStateProvider: Staff-User ${staffUser.firstName} ${staffUser.lastName} wurde gelöscht');
      return true;
    } catch (e) {
      debugPrint('❌ RbacStateProvider: Fehler beim Löschen von Staff-User: $e');
      return false;
    }
  }

  /// **🔄 Lädt Staff Users neu**
  Future<void> refreshStaffUsers() async {
    try {
      _staffUsers = await _dataService.getAllStaffUsers(limit: 1000, offset: 0);
      notifyListeners();
      debugPrint('✅ RbacStateProvider: Staff Users neu geladen');
    } catch (e) {
      debugPrint('❌ RbacStateProvider: Fehler beim Neuladen der Staff Users: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔧 PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// **🔄 Vollständiger Reload aller Daten**
  Future<void> reload() async {
    await loadInitialData();
  }
}
