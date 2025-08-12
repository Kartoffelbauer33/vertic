import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../services/rbac/role_state_provider.dart';
import '../../auth/permission_wrapper.dart';
import '../../pages/admin/role_permissions_manager.dart';
import 'role_creation_dialog.dart';

/// **Role Management Widget**
/// 
/// Sauberes, ausgelagertes Widget für die Rollen-Verwaltung.
/// Zeigt Rollen-Liste mit CRUD-Funktionen und System-Rollen-Schutz.
class RoleManagementWidget extends StatefulWidget {
  const RoleManagementWidget({super.key});

  @override
  State<RoleManagementWidget> createState() => _RoleManagementWidgetState();
}

class _RoleManagementWidgetState extends State<RoleManagementWidget> {
  @override
  void initState() {
    super.initState();
    // Rollen beim ersten Laden abrufen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoleStateProvider>(context, listen: false).loadRoles();
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Consumer<RoleStateProvider>(
      builder: (context, roleProvider, child) {
        
        // Zeige Loading-State
        if (roleProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Rollen werden geladen...'),
              ],
            ),
          );
        }
        
        // Zeige Error-State
        if (roleProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(roleProvider.error ?? 'Unbekannter Fehler'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => roleProvider.loadRoles(),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Aktionen
            _buildHeader(roleProvider),
            const SizedBox(height: 16),
            
            // Such- und Filter-Leiste
            _buildSearchAndFilters(roleProvider),
            const SizedBox(height: 16),
            
            // Rollen-Liste
            Expanded(
              child: _buildRolesList(roleProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(RoleStateProvider roleProvider) {
    return Row(
      children: [
        const Icon(Icons.admin_panel_settings, size: 24, color: Colors.indigo),
        const SizedBox(width: 8),
        const Text(
          'Rollen-Verwaltung',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        
        // Refresh Button
        IconButton(
          onPressed: roleProvider.isLoading ? null : () => roleProvider.refresh(),
          icon: roleProvider.isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          tooltip: 'Aktualisieren',
        ),
        
        // Neue Rolle erstellen (nur mit Permission)
        PermissionWrapper(
          requiredPermission: 'can_manage_roles',
          child: ElevatedButton.icon(
            onPressed: roleProvider.isLoading ? null : _showCreateRoleDialog,
            icon: const Icon(Icons.add),
            label: const Text('Neue Rolle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(RoleStateProvider roleProvider) {
    return Row(
      children: [
        // Suchfeld
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Rollen suchen...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: roleProvider.setSearchQuery,
          ),
        ),
        const SizedBox(width: 16),
        
        // Aktiv-Filter
        FilterChip(
          label: Text(roleProvider.showOnlyActive ? 'Nur Aktive' : 'Alle'),
          selected: roleProvider.showOnlyActive,
          onSelected: (_) => roleProvider.toggleShowOnlyActive(),
          avatar: Icon(
            roleProvider.showOnlyActive ? Icons.visibility : Icons.visibility_off,
            size: 16,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Anzahl-Anzeige
        Chip(
          label: Text('${roleProvider.filteredRoles.length} Rollen'),
          backgroundColor: Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildRolesList(RoleStateProvider roleProvider) {
    if (roleProvider.isLoading && roleProvider.allRoles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Rollen werden geladen...'),
          ],
        ),
      );
    }

    if (roleProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden der Rollen',
              style: TextStyle(fontSize: 18, color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              roleProvider.error!,
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => roleProvider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (roleProvider.filteredRoles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              roleProvider.searchQuery.isNotEmpty
                  ? 'Keine Rollen gefunden für "${roleProvider.searchQuery}"'
                  : 'Keine Rollen vorhanden',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (roleProvider.searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => roleProvider.setSearchQuery(''),
                child: const Text('Filter zurücksetzen'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roleProvider.filteredRoles.length,
      itemBuilder: (context, index) {
        final role = roleProvider.filteredRoles[index];
        return _buildRoleCard(role, roleProvider);
      },
    );
  }

  Widget _buildRoleCard(Role role, RoleStateProvider roleProvider) {
    final isSystemRole = role.isSystemRole;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSystemRole ? 4 : 2,
      color: isSystemRole ? Colors.amber[50] : null,
      child: ListTile(
        // Icon mit Farbe
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role),
          child: Icon(
            _getRoleIcon(role),
            color: Colors.white,
            size: 20,
          ),
        ),
        
        // Titel und Beschreibung
        title: Row(
          children: [
            Text(
              role.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSystemRole ? Colors.amber[800] : null,
              ),
            ),
            if (isSystemRole) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock, size: 16, color: Colors.amber),
              const Text(
                ' SYSTEM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
            if (!role.isActive) ...[
              const SizedBox(width: 8),
              const Chip(
                label: Text('INAKTIV', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.red,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
        
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Technischer Name: ${role.name}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            if (role.description != null && role.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(role.description!),
              ),
            const SizedBox(height: 4),
            Text(
              'Erstellt: ${_formatDate(role.createdAt)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        // Aktionen
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔐 Permissions anzeigen/verwalten (für ALLE Rollen)
            PermissionWrapper(
              requiredPermission: 'can_view_permissions',
              child: IconButton(
                onPressed: roleProvider.isLoading 
                    ? null 
                    : () {
                        debugPrint('🔐 Permission icon clicked for role: ${role.name}');
                        _showRolePermissions(role);
                      },
                icon: const Icon(Icons.security, color: Colors.indigo),
                tooltip: isSystemRole 
                    ? 'Permissions anzeigen (nicht bearbeitbar)' 
                    : 'Permissions verwalten',
              ),
            ),
            
            // Status Toggle (nur für normale Rollen)
            if (!isSystemRole)
              PermissionWrapper(
                requiredPermission: 'can_edit_roles',
                child: IconButton(
                  onPressed: roleProvider.isLoading 
                      ? null 
                      : () => _toggleRoleStatus(role, roleProvider),
                  icon: Icon(
                    role.isActive ? Icons.visibility : Icons.visibility_off,
                    color: role.isActive ? Colors.green : Colors.grey,
                  ),
                  tooltip: role.isActive ? 'Deaktivieren' : 'Aktivieren',
                ),
              ),
            
            // Bearbeiten (nur für normale Rollen)
            if (!isSystemRole)
              PermissionWrapper(
                requiredPermission: 'can_edit_roles',
                child: IconButton(
                  onPressed: roleProvider.isLoading 
                      ? null 
                      : () => _editRole(role),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Bearbeiten',
                ),
              ),
            
            // Löschen (nur für normale Rollen)
            if (!isSystemRole)
              PermissionWrapper(
                requiredPermission: 'can_delete_roles',
                child: IconButton(
                  onPressed: roleProvider.isLoading 
                      ? null 
                      : () => _deleteRole(role, roleProvider),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Löschen',
                ),
              ),
            
            // System-Rolle-Hinweis
            if (isSystemRole)
              const Tooltip(
                message: 'System-Rollen können nicht bearbeitet werden',
                child: Icon(Icons.info, color: Colors.amber),
              ),
          ],
        ),
        
        isThreeLine: role.description != null && role.description!.isNotEmpty,
      ),
    );
  }

  Color _getRoleColor(Role role) {
    if (role.color != null && role.color!.isNotEmpty) {
      try {
        return Color(int.parse(role.color!.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        // Fallback auf Standard-Farbe
      }
    }
    
    return role.isSystemRole ? Colors.amber : Colors.indigo;
  }

  IconData _getRoleIcon(Role role) {
    if (role.iconName != null && role.iconName!.isNotEmpty) {
      // Mapping der häufigsten Icon-Namen
      const iconMap = {
        'person': Icons.person,
        'admin_panel_settings': Icons.admin_panel_settings,
        'supervisor_account': Icons.supervisor_account,
        'business': Icons.business,
        'support_agent': Icons.support_agent,
        'engineering': Icons.engineering,
        'security': Icons.security,
        'verified_user': Icons.verified_user,
        'badge': Icons.badge,
        'account_circle': Icons.account_circle,
      };
      
      return iconMap[role.iconName] ?? Icons.person;
    }
    
    return role.isSystemRole ? Icons.admin_panel_settings : Icons.person;
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showCreateRoleDialog() {
    final roleProvider = Provider.of<RoleStateProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: roleProvider,
        child: const RoleCreationDialog(),
      ),
    );
  }

  /// 🔐 Permissions für eine Rolle anzeigen/verwalten
  void _showRolePermissions(Role role) async {
    debugPrint('🔐 Opening permission manager for role: ${role.name}');
    // Alle Permissions laden für den Dialog
    try {
      final client = Provider.of<Client>(context, listen: false);
      debugPrint('🔐 Loading all permissions...');
      final allPermissions = await client.permissionManagement.getAllPermissions();
      debugPrint('🔐 Loaded ${allPermissions.length} permissions');
      
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Permissions: ${role.displayName}'),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            body: RolePermissionsManager(
              role: role,
              allPermissions: allPermissions,
              onPermissionsChanged: () {
                // Rollen neu laden nach Permission-Änderungen
                final roleProvider = Provider.of<RoleStateProvider>(context, listen: false);
                roleProvider.loadRoles();
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editRole(Role role) {
    // TODO: Implementiere Rolle-Bearbeitung
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Rolle-Bearbeitung wird noch implementiert'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _toggleRoleStatus(Role role, RoleStateProvider roleProvider) async {
    final success = await roleProvider.toggleRoleStatus(role);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Rolle "${role.displayName}" ${role.isActive ? 'deaktiviert' : 'aktiviert'}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteRole(Role role, RoleStateProvider roleProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rolle löschen'),
        content: Text(
          'Möchten Sie die Rolle "${role.displayName}" wirklich löschen?\n\n'
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await roleProvider.deleteRole(role);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Rolle "${role.displayName}" erfolgreich gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
