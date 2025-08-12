import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

/// **🔐 Role Permissions Manager**
///
/// Erweiterte Permission-Verwaltung für Rollen mit:
/// - Live Permission Assignment/Removal
/// - Category-basierte Bulk Operations
/// - Real-time Search & Filter
/// - Visual Permission Status
class RolePermissionsManager extends StatefulWidget {
  final Role role;
  final List<Permission> allPermissions;
  final VoidCallback onPermissionsChanged;

  const RolePermissionsManager({
    super.key,
    required this.role,
    required this.allPermissions,
    required this.onPermissionsChanged,
  });

  @override
  State<RolePermissionsManager> createState() => _RolePermissionsManagerState();
}

class _RolePermissionsManagerState extends State<RolePermissionsManager> {
  List<Permission> _assignedPermissions = [];
  final Map<String, List<Permission>> _permissionsByCategory = {};
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _isLoading = true;
  bool _isBulkOperation = false;

  @override
  void initState() {
    super.initState();
    _loadRolePermissions();
    _organizePermissionsByCategory();
  }

  Future<void> _loadRolePermissions() async {
    setState(() => _isLoading = true);

    try {
      final client = Provider.of<Client>(context, listen: false);
      
      // 🔍 ECHTE PERMISSIONS LADEN: Immer aus der Datenbank laden, niemals vortäuschen!
      final permissions =
          await client.permissionManagement.getRolePermissions(widget.role.id!);

      setState(() {
        _assignedPermissions = permissions;
        _isLoading = false;
      });
      
      debugPrint('✅ Permissions für Rolle ${widget.role.displayName} geladen: ${permissions.length} Permissions');
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Error loading role permissions: $e');
    }
  }

  void _organizePermissionsByCategory() {
    _permissionsByCategory.clear();

    for (final permission in widget.allPermissions) {
      final category = permission.category;
      if (!_permissionsByCategory.containsKey(category)) {
        _permissionsByCategory[category] = [];
      }
      _permissionsByCategory[category]!.add(permission);
    }

    // Sort permissions within categories
    for (final category in _permissionsByCategory.keys) {
      _permissionsByCategory[category]!
          .sort((a, b) => a.displayName.compareTo(b.displayName));
    }
  }

  List<Permission> get _filteredPermissions {
    var permissions = _selectedCategory == 'all'
        ? widget.allPermissions
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

  bool _isPermissionAssigned(Permission permission) {
    return _assignedPermissions.any((p) => p.id == permission.id);
  }

  Future<void> _togglePermission(Permission permission) async {
    // 🔒 SYSTEM-ROLLEN-SCHUTZ: Superuser-Rolle ist nicht bearbeitbar
    if (widget.role.isSystemRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ System-Rollen können nicht bearbeitet werden!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final isAssigned = _isPermissionAssigned(permission);

    try {
      final client = Provider.of<Client>(context, listen: false);
      bool success;

      if (isAssigned) {
        success = await client.permissionManagement
            .removePermissionFromRole(widget.role.id!, permission.id!);
      } else {
        success = await client.permissionManagement
            .assignPermissionToRole(widget.role.id!, permission.id!);
      }

      if (success) {
        setState(() {
          if (isAssigned) {
            _assignedPermissions.removeWhere((p) => p.id == permission.id);
          } else {
            _assignedPermissions.add(permission);
          }
        });

        widget.onPermissionsChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Ändern der Permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.indigo,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Icon(
                widget.role.isSystemRole ? Icons.shield : Icons.group,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berechtigungen: ${widget.role.displayName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_assignedPermissions.length} von ${widget.allPermissions.length} zugewiesen',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.role.isSystemRole)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'SYSTEM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),

        // Search & Filter Controls
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Permissions durchsuchen...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 12),

              // Category Filter + Stats
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip(
                              'all', 'Alle (${widget.allPermissions.length})'),
                          ..._permissionsByCategory.entries.map((entry) =>
                              _buildCategoryChip(entry.key,
                                  '${_formatCategoryName(entry.key)} (${entry.value.length})')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Bulk Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      // 🔒 SYSTEM-ROLLEN-SCHUTZ: Buttons für System-Rollen deaktivieren
                      onPressed: (widget.role.isSystemRole || _isBulkOperation) ? null : _bulkAssignCategory,
                      icon: _isBulkOperation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              widget.role.isSystemRole ? Icons.lock : Icons.add, 
                              size: 16
                            ),
                      label: Text(
                        widget.role.isSystemRole 
                          ? 'System-Rolle (geschützt)'
                          : (_selectedCategory == 'all'
                              ? 'Alle zuweisen'
                              : 'Kategorie zuweisen')
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.role.isSystemRole ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      // 🔒 SYSTEM-ROLLEN-SCHUTZ: Buttons für System-Rollen deaktivieren
                      onPressed: (widget.role.isSystemRole || _isBulkOperation) ? null : _bulkRemoveCategory,
                      icon: _isBulkOperation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              widget.role.isSystemRole ? Icons.lock : Icons.remove, 
                              size: 16
                            ),
                      label: Text(
                        widget.role.isSystemRole 
                          ? 'System-Rolle (geschützt)'
                          : (_selectedCategory == 'all'
                              ? 'Alle entfernen'
                              : 'Kategorie entfernen')
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.role.isSystemRole ? Colors.grey : Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Permissions List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPermissionsList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.indigo[100],
      ),
    );
  }

  Widget _buildPermissionsList() {
    final permissions = _filteredPermissions;

    if (permissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Keine Permissions gefunden für "$_searchQuery"'
                  : 'Keine Permissions in dieser Kategorie',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: permissions.length,
      itemBuilder: (context, index) {
        final permission = permissions[index];
        final isAssigned = _isPermissionAssigned(permission);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isAssigned ? 4 : 1,
          color: isAssigned ? Colors.indigo[50] : Colors.white,
          child: CheckboxListTile(
            value: isAssigned,
            // 🔒 SYSTEM-ROLLEN-SCHUTZ: Checkboxes für System-Rollen deaktivieren
            onChanged: widget.role.isSystemRole ? null : (value) => _togglePermission(permission),
            title: Row(
              children: [
                if (widget.role.isSystemRole)
                  const Icon(Icons.lock, size: 16, color: Colors.grey),
                if (widget.role.isSystemRole)
                  const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    permission.displayName,
                    style: TextStyle(
                      fontWeight: isAssigned ? FontWeight.bold : FontWeight.normal,
                      color: widget.role.isSystemRole ? Colors.grey : null,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
                if (permission.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      permission.description!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
              ],
            ),
            secondary: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(permission.category),
                  color: _getCategoryColor(permission.category),
                  size: 20,
                ),
                const SizedBox(height: 4),
                if (permission.isSystemCritical) ...[
                  const Icon(Icons.warning, color: Colors.red, size: 16),
                  const Text(
                    'CRITICAL',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _bulkAssignCategory() async {
    // 🔒 SYSTEM-ROLLEN-SCHUTZ: Superuser-Rolle ist nicht bearbeitbar
    if (widget.role.isSystemRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ System-Rollen können nicht bearbeitet werden!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isBulkOperation = true);

    final categoryPermissions = _selectedCategory == 'all'
        ? widget.allPermissions
        : _permissionsByCategory[_selectedCategory] ?? [];

    // 🚀 PERFORMANCE-OPTIMIERUNG: Sammle alle Permissions die zugewiesen werden müssen
    final permissionsToAssign = categoryPermissions
        .where((permission) => !_isPermissionAssigned(permission))
        .toList();

    if (permissionsToAssign.isEmpty) {
      setState(() => _isBulkOperation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alle Permissions sind bereits zugewiesen'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    int successCount = 0;
    final client = Provider.of<Client>(context, listen: false);
    
    // 🚀 BATCH-VERARBEITUNG: Verarbeite in kleineren Batches für bessere Performance
    const batchSize = 5;
    for (int i = 0; i < permissionsToAssign.length; i += batchSize) {
      final batch = permissionsToAssign.skip(i).take(batchSize).toList();
      
      // Parallel processing für bessere Performance
      final futures = batch.map((permission) async {
        try {
          final success = await client.permissionManagement
              .assignPermissionToRole(widget.role.id!, permission.id!);
          return success ? permission : null;
        } catch (e) {
          debugPrint('❌ Bulk assign error for ${permission.name}: $e');
          return null;
        }
      });
      
      final results = await Future.wait(futures);
      
      // Update UI nach jedem Batch
      setState(() {
        for (final permission in results) {
          if (permission != null) {
            _assignedPermissions.add(permission);
            successCount++;
          }
        }
      });
      
      // Kurze Pause zwischen Batches um UI responsive zu halten
      if (i + batchSize < permissionsToAssign.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    setState(() => _isBulkOperation = false);
    widget.onPermissionsChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $successCount von ${permissionsToAssign.length} Permissions zugewiesen'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _bulkRemoveCategory() async {
    // 🔒 SYSTEM-ROLLEN-SCHUTZ: Superuser-Rolle ist nicht bearbeitbar
    if (widget.role.isSystemRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ System-Rollen können nicht bearbeitet werden!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isBulkOperation = true);

    final categoryPermissions = _selectedCategory == 'all'
        ? widget.allPermissions
        : _permissionsByCategory[_selectedCategory] ?? [];

    // 🚀 PERFORMANCE-OPTIMIERUNG: Sammle alle Permissions die entfernt werden müssen
    final permissionsToRemove = categoryPermissions
        .where((permission) => _isPermissionAssigned(permission))
        .toList();

    if (permissionsToRemove.isEmpty) {
      setState(() => _isBulkOperation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Permissions zum Entfernen vorhanden'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    int successCount = 0;
    final client = Provider.of<Client>(context, listen: false);
    
    // 🚀 BATCH-VERARBEITUNG: Verarbeite in kleineren Batches für bessere Performance
    const batchSize = 5;
    for (int i = 0; i < permissionsToRemove.length; i += batchSize) {
      final batch = permissionsToRemove.skip(i).take(batchSize).toList();
      
      // Parallel processing für bessere Performance
      final futures = batch.map((permission) async {
        try {
          final success = await client.permissionManagement
              .removePermissionFromRole(widget.role.id!, permission.id!);
          return success ? permission : null;
        } catch (e) {
          debugPrint('❌ Bulk remove error for ${permission.name}: $e');
          return null;
        }
      });
      
      final results = await Future.wait(futures);
      
      // Update UI nach jedem Batch
      setState(() {
        for (final permission in results) {
          if (permission != null) {
            _assignedPermissions.removeWhere((p) => p.id == permission.id);
            successCount++;
          }
        }
      });
      
      // Kurze Pause zwischen Batches um UI responsive zu halten
      if (i + batchSize < permissionsToRemove.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    setState(() => _isBulkOperation = false);
    widget.onPermissionsChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $successCount von ${permissionsToRemove.length} Permissions entfernt'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatCategoryName(String category) {
    switch (category) {
      case 'user':
        return 'Benutzer';
      case 'admin':
        return 'Administration';
      case 'system':
        return 'System';
      case 'facility':
        return 'Facility';
      case 'tickets':
        return 'Tickets';
      case 'reports':
        return 'Reports';
      default:
        return category.substring(0, 1).toUpperCase() + category.substring(1);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'user':
        return Icons.person;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'system':
        return Icons.settings;
      case 'facility':
        return Icons.business;
      case 'tickets':
        return Icons.confirmation_number;
      case 'reports':
        return Icons.analytics;
      default:
        return Icons.lock;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'user':
        return Colors.blue;
      case 'admin':
        return Colors.red;
      case 'system':
        return Colors.grey;
      case 'facility':
        return Colors.green;
      case 'tickets':
        return Colors.orange;
      case 'reports':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }
}
