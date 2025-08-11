import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../services/rbac/staff_user_management_service.dart';

/// **Role Assignment Dialog**
/// 
/// Dialog zum Verwalten der Rollen-Zuweisungen für einen Staff-User.
/// Zeigt aktuelle Rollen und ermöglicht hinzufügen/entfernen von Rollen.
class RoleAssignmentDialog extends StatefulWidget {
  final StaffUser staffUser;

  const RoleAssignmentDialog({
    super.key,
    required this.staffUser,
  });

  @override
  State<RoleAssignmentDialog> createState() => _RoleAssignmentDialogState();
}

class _RoleAssignmentDialogState extends State<RoleAssignmentDialog> {
  late StaffUserManagementService _staffService;
  
  List<Role> _allRoles = [];
  List<StaffUserRole> _currentAssignments = [];
  List<Role> _availableRoles = [];
  
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = Provider.of<Client>(context, listen: false);
    _staffService = StaffUserManagementService(client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Lade alle verfügbaren Rollen und aktuelle Zuweisungen parallel
      final futures = await Future.wait([
        client.permissionManagement.getAllRoles(),
        _staffService.getStaffUserRoles(widget.staffUser.id!),
      ]);

      _allRoles = futures[0] as List<Role>;
      _currentAssignments = futures[1] as List<StaffUserRole>;

      // Berechne verfügbare Rollen (nicht bereits zugewiesene)
      final assignedRoleIds = _currentAssignments.map((a) => a.roleId).toSet();
      _availableRoles = _allRoles.where((role) => !assignedRoleIds.contains(role.id)).toList();

      // Sortiere Rollen: System-Rollen zuerst, dann alphabetisch
      _availableRoles.sort((a, b) {
        if (a.isSystemRole && !b.isSystemRole) return -1;
        if (!a.isSystemRole && b.isSystemRole) return 1;
        return a.displayName.compareTo(b.displayName);
      });

    } catch (e) {
      _error = 'Fehler beim Laden der Daten: $e';
      debugPrint('❌ Error loading role assignment data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Client get client => Provider.of<Client>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getStaffLevelColor(widget.staffUser.staffLevel),
            child: Icon(
              _getStaffLevelIcon(widget.staffUser.staffLevel),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.staffUser.firstName} ${widget.staffUser.lastName}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Rollen verwalten',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      content: Container(
        width: 600,
        height: 500,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildRoleManagement(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Fehler beim Laden',
            style: TextStyle(fontSize: 18, color: Colors.red[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User-Informationen
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.staffUser.email,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Staff-Level: ${_formatStaffLevel(widget.staffUser.staffLevel)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Aktuelle Rollen
        Text(
          'Zugewiesene Rollen (${_currentAssignments.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _currentAssignments.isEmpty
              ? Center(
                  child: Text(
                    'Keine Rollen zugewiesen',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: _currentAssignments.length,
                  itemBuilder: (context, index) {
                    final assignment = _currentAssignments[index];
                    final role = _allRoles.firstWhere((r) => r.id == assignment.roleId);
                    return _buildAssignedRoleItem(assignment, role);
                  },
                ),
        ),
        
        const SizedBox(height: 16),

        // Verfügbare Rollen
        Row(
          children: [
            Text(
              'Verfügbare Rollen (${_availableRoles.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_availableRoles.isEmpty)
              Text(
                'Alle Rollen sind bereits zugewiesen',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _availableRoles.isEmpty
                ? Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green[300],
                    ),
                  )
                : ListView.builder(
                    itemCount: _availableRoles.length,
                    itemBuilder: (context, index) {
                      final role = _availableRoles[index];
                      return _buildAvailableRoleItem(role);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedRoleItem(StaffUserRole assignment, Role role) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Card(
        color: role.isSystemRole ? Colors.amber[50] : null,
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: _getRoleColor(role),
            radius: 16,
            child: Icon(
              _getRoleIcon(role),
              color: Colors.white,
              size: 16,
            ),
          ),
          title: Text(
            role.displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: role.isSystemRole ? Colors.amber[800] : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Technischer Name: ${role.name}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
              Text(
                'Zugewiesen: ${_formatDate(assignment.assignedAt)}',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
          trailing: role.isSystemRole
              ? Tooltip(
                  message: 'System-Rollen können nicht entfernt werden',
                  child: Icon(Icons.lock, color: Colors.amber[700], size: 20),
                )
              : IconButton(
                  onPressed: () => _removeRole(assignment, role),
                  icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                  tooltip: 'Rolle entfernen',
                ),
        ),
      ),
    );
  }

  Widget _buildAvailableRoleItem(Role role) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Card(
        color: role.isSystemRole ? Colors.amber[50] : null,
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: _getRoleColor(role),
            radius: 16,
            child: Icon(
              _getRoleIcon(role),
              color: Colors.white,
              size: 16,
            ),
          ),
          title: Text(
            role.displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: role.isSystemRole ? Colors.amber[800] : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Technischer Name: ${role.name}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
              if (role.description != null && role.description!.isNotEmpty)
                Text(
                  role.description!,
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: IconButton(
            onPressed: role.isActive 
                ? () => _assignRole(role)
                : null,
            icon: Icon(
              Icons.add_circle,
              color: role.isActive ? Colors.green : Colors.grey,
              size: 20,
            ),
            tooltip: role.isActive ? 'Rolle zuweisen' : 'Rolle ist inaktiv',
          ),
        ),
      ),
    );
  }

  Future<void> _assignRole(Role role) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final assignment = await _staffService.assignRoleToStaffUser(
        widget.staffUser.id!,
        role.id!,
      );

      if (assignment != null) {
        // Update local state
        setState(() {
          _currentAssignments.add(assignment);
          _availableRoles.removeWhere((r) => r.id == role.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Rolle "${role.displayName}" erfolgreich zugewiesen'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Zuweisen der Rolle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeRole(StaffUserRole assignment, Role role) async {
    // Bestätigung für System-Rollen
    if (role.isSystemRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ System-Rollen können nicht entfernt werden'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rolle entfernen'),
        content: Text(
          'Möchten Sie die Rolle "${role.displayName}" von diesem Staff-User entfernen?\n\n'
          'Alle damit verbundenen Permissions gehen verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Entfernen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _staffService.removeStaffUserRole(assignment.id!);

      if (success) {
        // Update local state
        setState(() {
          _currentAssignments.removeWhere((a) => a.id == assignment.id);
          _availableRoles.add(role);
          _availableRoles.sort((a, b) {
            if (a.isSystemRole && !b.isSystemRole) return -1;
            if (!a.isSystemRole && b.isSystemRole) return 1;
            return a.displayName.compareTo(b.displayName);
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Rolle "${role.displayName}" erfolgreich entfernt'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Entfernen der Rolle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStaffLevelColor(StaffUserType level) {
    switch (level) {
      case StaffUserType.superUser:
        return Colors.purple;
      case StaffUserType.staff:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getStaffLevelIcon(StaffUserType level) {
    switch (level) {
      case StaffUserType.superUser:
        return Icons.star;
      case StaffUserType.staff:
        return Icons.person;
      default:
        return Icons.person;
    }
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

  String _formatStaffLevel(StaffUserType level) {
    switch (level) {
      case StaffUserType.superUser:
        return 'Super Administrator';
      case StaffUserType.staff:
        return 'Mitarbeiter';
      default:
        return level.name;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}