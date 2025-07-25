import 'package:flutter/foundation.dart';
import 'package:test_server_client/test_server_client.dart';

/// **Role Management Service**
/// 
/// Saubere Auslagerung der Rollen-CRUD-Logik aus der UI.
/// Verwendet nur die tatsächlich vorhandenen Backend-Endpunkte.
class RoleManagementService {
  final Client _client;

  RoleManagementService(this._client);

  /// **Lädt alle verfügbaren Rollen**
  Future<List<Role>> getAllRoles() async {
    try {
      debugPrint('🔄 Loading all roles...');
      final roles = await _client.permissionManagement.getAllRoles();
      debugPrint('✅ Loaded ${roles.length} roles');
      return roles;
    } catch (e) {
      debugPrint('❌ Error loading roles: $e');
      rethrow;
    }
  }

  /// **Lädt nur aktive Rollen**
  Future<List<Role>> getActiveRoles() async {
    try {
      debugPrint('🔄 Loading active roles...');
      final roles = await _client.permissionManagement.getActiveRoles();
      debugPrint('✅ Loaded ${roles.length} active roles');
      return roles;
    } catch (e) {
      debugPrint('❌ Error loading active roles: $e');
      rethrow;
    }
  }

  /// **Erstellt eine neue Rolle**
  Future<Role?> createRole({
    required String name,
    required String displayName,
    String? description,
    String? color,
    String? iconName,
    int sortOrder = 0,
  }) async {
    try {
      debugPrint('🔄 Creating new role: $displayName');
      
      // Rolle-Objekt erstellen (nur mit existierenden Feldern aus .spy)
      final role = Role(
        name: name,
        displayName: displayName,
        description: description,
        color: color,
        iconName: iconName,
        isSystemRole: false, // Neue Rollen sind niemals System-Rollen
        isActive: true,
        sortOrder: sortOrder,
        createdAt: DateTime.now(),
        createdBy: 0, // Wird im Backend durch echte Staff-User-ID ersetzt
      );

      final newRole = await _client.permissionManagement.createRole(role);
      
      if (newRole != null) {
        debugPrint('✅ Role created successfully: ${newRole.displayName}');
      } else {
        debugPrint('❌ Role creation failed');
      }
      
      return newRole;
    } catch (e) {
      debugPrint('❌ Error creating role: $e');
      rethrow;
    }
  }

  /// **Aktualisiert eine bestehende Rolle**
  Future<Role?> updateRole(Role role) async {
    try {
      debugPrint('🔄 Updating role: ${role.displayName}');
      
      // System-Rollen-Schutz auf Client-Seite
      if (role.isSystemRole) {
        throw Exception('System-Rollen können nicht bearbeitet werden');
      }

      // Timestamp für Update setzen
      final updatedRole = role.copyWith(
        updatedAt: DateTime.now(),
      );

      final result = await _client.permissionManagement.updateRole(updatedRole);
      
      if (result != null) {
        debugPrint('✅ Role updated successfully: ${result.displayName}');
      } else {
        debugPrint('❌ Role update failed');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ Error updating role: $e');
      rethrow;
    }
  }

  /// **Löscht eine Rolle**
  Future<bool> deleteRole(int roleId, String roleName) async {
    try {
      debugPrint('🔄 Deleting role: $roleName (ID: $roleId)');
      
      final success = await _client.permissionManagement.deleteRole(roleId);
      
      if (success) {
        debugPrint('✅ Role deleted successfully: $roleName');
      } else {
        debugPrint('❌ Role deletion failed: $roleName');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting role: $e');
      rethrow;
    }
  }

  /// **Aktiviert/Deaktiviert eine Rolle**
  Future<Role?> toggleRoleStatus(Role role) async {
    try {
      debugPrint('🔄 Toggling role status: ${role.displayName} -> ${!role.isActive}');
      
      // System-Rollen-Schutz
      if (role.isSystemRole) {
        throw Exception('System-Rollen können nicht deaktiviert werden');
      }

      final updatedRole = role.copyWith(
        isActive: !role.isActive,
        updatedAt: DateTime.now(),
      );

      return await updateRole(updatedRole);
    } catch (e) {
      debugPrint('❌ Error toggling role status: $e');
      rethrow;
    }
  }

  /// **Validiert Rollen-Daten vor dem Speichern**
  String? validateRoleData({
    required String name,
    required String displayName,
    String? color,
  }) {
    // Name-Validierung
    if (name.trim().isEmpty) {
      return 'Rollen-Name darf nicht leer sein';
    }
    
    if (name.length < 3) {
      return 'Rollen-Name muss mindestens 3 Zeichen lang sein';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(name)) {
      return 'Rollen-Name darf nur Buchstaben, Zahlen und Unterstriche enthalten';
    }

    // DisplayName-Validierung
    if (displayName.trim().isEmpty) {
      return 'Anzeige-Name darf nicht leer sein';
    }
    
    if (displayName.length < 2) {
      return 'Anzeige-Name muss mindestens 2 Zeichen lang sein';
    }

    // Farb-Validierung (optional)
    if (color != null && color.isNotEmpty) {
      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
        return 'Farbe muss im Format #RRGGBB angegeben werden (z.B. #FF5722)';
      }
    }

    return null; // Alles valid
  }

  /// **Generiert einen eindeutigen Rollen-Namen basierend auf dem Display-Namen**
  String generateRoleName(String displayName) {
    return displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
