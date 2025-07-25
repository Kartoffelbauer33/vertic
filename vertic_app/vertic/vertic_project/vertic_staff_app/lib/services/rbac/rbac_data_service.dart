import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';

/// **🎯 RBAC Data Service**
/// 
/// Kapselt alle Backend-API-Calls für RBAC-Management
/// Verwendet exakt die bestehenden Backend-Endpoints ohne Erfindungen
class RbacDataService {
  final Client _client;

  RbacDataService(this._client);

  // ═══════════════════════════════════════════════════════════════
  // 🔐 PERMISSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// **🔐 Lädt alle Permissions**
  Future<List<Permission>> getAllPermissions() async {
    try {
      debugPrint('🔄 RbacDataService: Loading all permissions...');
      final permissions = await _client.permissionManagement.getAllPermissions();
      debugPrint('✅ RbacDataService: Loaded ${permissions.length} permissions');
      return permissions;
    } catch (e) {
      debugPrint('❌ RbacDataService: Error loading permissions: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 👥 ROLE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// **👥 Lädt alle Roles**
  Future<List<Role>> getAllRoles() async {
    try {
      debugPrint('🔄 RbacDataService: Loading all roles...');
      final roles = await _client.permissionManagement.getAllRoles();
      debugPrint('✅ RbacDataService: Loaded ${roles.length} roles');
      return roles;
    } catch (e) {
      debugPrint('❌ RbacDataService: Error loading roles: $e');
      rethrow;
    }
  }

  /// **👥 Lädt Permissions für Role**
  Future<List<Permission>> getRolePermissions(int roleId) async {
    try {
      debugPrint('🔄 RbacDataService: Loading permissions for role ID: $roleId');
      final permissions = await _client.permissionManagement.getRolePermissions(roleId);
      debugPrint('✅ RbacDataService: Loaded ${permissions.length} permissions for role ID: $roleId');
      return permissions;
    } catch (e) {
      debugPrint('❌ RbacDataService: Error loading role permissions: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 👤 STAFF USER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// **👤 Lädt alle Staff Users**
  Future<List<StaffUser>> getAllStaffUsers({int limit = 1000, int offset = 0}) async {
    try {
      debugPrint('🔄 RbacDataService: Loading all staff users (limit: $limit, offset: $offset)...');
      final staffUsers = await _client.staffUserManagement.getAllStaffUsers(limit: limit, offset: offset);
      debugPrint('✅ RbacDataService: Loaded ${staffUsers.length} staff users');
      return staffUsers;
    } catch (e) {
      debugPrint('❌ RbacDataService: Error loading staff users: $e');
      rethrow;
    }
  }

  /// **👤 Löscht Staff User**
  Future<void> deleteStaffUser(int staffUserId) async {
    try {
      debugPrint('🔄 RbacDataService: Deleting staff user ID: $staffUserId');
      await _client.staffUserManagement.deleteStaffUser(staffUserId);
      debugPrint('✅ RbacDataService: Deleted staff user ID: $staffUserId');
    } catch (e) {
      debugPrint('❌ RbacDataService: Error deleting staff user: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔗 COMPLEX OPERATIONS (aus bestehender RBAC-Page extrahiert)
  // ═══════════════════════════════════════════════════════════════

  /// **🔍 Holt alle Staff-User die eine bestimmte Permission haben**
  /// (Extrahiert aus _getUsersWithPermission in RBAC-Management-Page)
  Future<List<StaffUser>> getUsersWithPermission(String permissionName) async {
    try {
      debugPrint('🔄 RbacDataService: Finding users with permission: $permissionName');
      
      // Hole alle Staff-User
      final allStaffUsers = await getAllStaffUsers(limit: 1000, offset: 0);
      
      // Für jeden Staff-User prüfe ob er die Permission hat
      final usersWithPermission = <StaffUser>[];

      for (final user in allStaffUsers) {
        // Hole die Permissions des Users (über Rollen)
        // TODO: Implementierung abhängig von UserRole-Struktur
        // Dies muss basierend auf der tatsächlichen UserRole-API implementiert werden
      }

      debugPrint('✅ RbacDataService: Found ${usersWithPermission.length} users with permission: $permissionName');
      return usersWithPermission;
    } catch (e) {
      debugPrint('❌ RbacDataService: Error finding users with permission $permissionName: $e');
      return [];
    }
  }

  /// **📊 Lädt RBAC-Daten parallel (Performance-Optimierung)**
  /// (Extrahiert aus _loadInitialData in RBAC-Management-Page)
  Future<RbacDataBundle> loadAllRbacData() async {
    try {
      debugPrint('🔄 RbacDataService: Loading all RBAC data in parallel...');
      
      // Parallel laden für bessere Performance
      final futures = await Future.wait([
        getAllPermissions(),
        getAllRoles(),
        getAllStaffUsers(limit: 1000, offset: 0),
      ]);

      final permissions = futures[0] as List<Permission>;
      final roles = futures[1] as List<Role>;
      final staffUsers = futures[2] as List<StaffUser>;

      final bundle = RbacDataBundle(
        permissions: permissions,
        roles: roles,
        staffUsers: staffUsers,
      );

      debugPrint('✅ RbacDataService: Loaded complete RBAC data bundle');
      return bundle;
    } catch (e) {
      debugPrint('❌ RbacDataService: Error loading RBAC data bundle: $e');
      rethrow;
    }
  }
}

/// **📦 RBAC Data Bundle**
/// Container für alle RBAC-Daten
class RbacDataBundle {
  final List<Permission> permissions;
  final List<Role> roles;
  final List<StaffUser> staffUsers;

  RbacDataBundle({
    required this.permissions,
    required this.roles,
    required this.staffUsers,
  });
}
