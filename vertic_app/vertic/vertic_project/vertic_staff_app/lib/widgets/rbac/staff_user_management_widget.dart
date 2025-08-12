import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../services/rbac/staff_user_state_provider.dart';
import '../../auth/permission_wrapper.dart';
import 'staff_user_email_creation_dialog.dart';
import 'staff_user_edit_dialog.dart';
import 'role_assignment_dialog.dart';

/// **Staff User Management Widget**
/// 
/// Sauberes, ausgelagertes Widget für die Staff-User-Verwaltung.
/// Zeigt Staff-User-Liste mit CRUD-Funktionen und Role-Assignment.
class StaffUserManagementWidget extends StatefulWidget {
  const StaffUserManagementWidget({super.key});

  @override
  State<StaffUserManagementWidget> createState() => _StaffUserManagementWidgetState();
}

class _StaffUserManagementWidgetState extends State<StaffUserManagementWidget> {
  @override
  void initState() {
    super.initState();
    // Staff-User beim ersten Laden abrufen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StaffUserStateProvider>(context, listen: false).loadStaffUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffUserStateProvider>(
      builder: (context, staffProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Aktionen
            _buildHeader(staffProvider),
            const SizedBox(height: 16),
            
            // Such- und Filter-Leiste
            _buildSearchAndFilters(staffProvider),
            const SizedBox(height: 16),
            
            // Statistiken-Übersicht
            _buildStatistics(staffProvider),
            const SizedBox(height: 16),
            
            // Staff-User-Liste
            Expanded(
              child: _buildStaffUsersList(staffProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(StaffUserStateProvider staffProvider) {
    return Row(
      children: [
        const Icon(Icons.people, size: 24, color: Colors.indigo),
        const SizedBox(width: 8),
        const Text(
          'Staff-User-Verwaltung',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        
        // Refresh Button
        IconButton(
          onPressed: staffProvider.isLoading ? null : () => staffProvider.refresh(),
          icon: staffProvider.isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          tooltip: 'Aktualisieren',
        ),
        
        // Neuen Staff-User erstellen (nur mit Permission)
        PermissionWrapper(
          requiredPermission: 'can_create_staff',
          child: ElevatedButton.icon(
            onPressed: staffProvider.isLoading ? null : _showCreateStaffUserDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Neuer Staff-User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(StaffUserStateProvider staffProvider) {
    return Column(
      children: [
        Row(
          children: [
            // Suchfeld
            Expanded(
              flex: 2,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Staff-User suchen (Name, E-Mail, ID)...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: staffProvider.setSearchQuery,
              ),
            ),
            const SizedBox(width: 16),
            
            // Rollen Filter (ersetzt Staff-Level)
            Expanded(
              flex: 1,
              child: FutureBuilder<List<Role>>(
                future: _loadAvailableRoles(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return DropdownButtonFormField<String?>(
                      value: null,
                      decoration: const InputDecoration(
                        labelText: 'Rolle (lädt...)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Lädt...'),
                        ),
                      ],
                      onChanged: null,
                    );
                  }
                  
                  final roles = snapshot.data!;
                  return DropdownButtonFormField<String?>(
                    value: staffProvider.filterByRole,
                    decoration: const InputDecoration(
                      labelText: 'Nach Rolle filtern',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Alle Rollen'),
                      ),
                      const DropdownMenuItem<String?>(
                        value: 'superuser',
                        child: Text('Super-Administrator'),
                      ),
                      ...roles.map((role) {
                        return DropdownMenuItem<String?>(
                          value: role.name,
                          child: Text(role.displayName),
                        );
                      }),
                    ],
                    onChanged: staffProvider.setRoleFilter,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            // Aktiv-Filter
            FilterChip(
              label: Text(staffProvider.showOnlyActive ? 'Nur Aktive' : 'Alle'),
              selected: staffProvider.showOnlyActive,
              onSelected: (_) => staffProvider.toggleShowOnlyActive(),
              avatar: Icon(
                staffProvider.showOnlyActive ? Icons.visibility : Icons.visibility_off,
                size: 16,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Filter zurücksetzen
            if (staffProvider.searchQuery.isNotEmpty || 
                staffProvider.filterByRole != null ||
                !staffProvider.showOnlyActive)
              TextButton.icon(
                onPressed: staffProvider.clearAllFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Filter zurücksetzen'),
              ),
            
            const Spacer(),
            
            // Anzahl-Anzeige
            Chip(
              label: Text('${staffProvider.filteredStaffUsers.length} von ${staffProvider.allStaffUsers.length} Staff-User'),
              backgroundColor: Colors.grey[200],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatistics(StaffUserStateProvider staffProvider) {
    final stats = staffProvider.getStatistics();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          _buildStatItem('Gesamt', stats['total'] ?? 0, Icons.people, Colors.blue),
          _buildStatItem('Aktiv', stats['active'] ?? 0, Icons.check_circle, Colors.green),
          _buildStatItem('Inaktiv', stats['inactive'] ?? 0, Icons.cancel, Colors.red),
          _buildStatItem('Super Admin', stats['superUser'] ?? 0, Icons.admin_panel_settings, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStaffUsersList(StaffUserStateProvider staffProvider) {
    if (staffProvider.isLoading && staffProvider.allStaffUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Staff-User werden geladen...'),
          ],
        ),
      );
    }

    if (staffProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden der Staff-User',
              style: TextStyle(fontSize: 18, color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              staffProvider.error!,
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => staffProvider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (staffProvider.filteredStaffUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              staffProvider.searchQuery.isNotEmpty
                  ? 'Keine Staff-User gefunden für "${staffProvider.searchQuery}"'
                  : 'Keine Staff-User vorhanden',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (staffProvider.searchQuery.isNotEmpty ||
                staffProvider.filterByRole != null ||
                !staffProvider.showOnlyActive) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => staffProvider.clearAllFilters(),
                child: const Text('Filter zurücksetzen'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: staffProvider.filteredStaffUsers.length,
      itemBuilder: (context, index) {
        final staffUser = staffProvider.filteredStaffUsers[index];
        return _buildStaffUserCard(staffUser, staffProvider);
      },
    );
  }

  Widget _buildStaffUserCard(StaffUser staffUser, StaffUserStateProvider staffProvider) {
    final isActive = staffUser.employmentStatus == 'active';
    final isSuperUser = staffUser.staffLevel == StaffUserType.superUser;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSuperUser ? 4 : 2,
      color: isSuperUser ? Colors.purple[50] : (isActive ? null : Colors.grey[100]),
      child: ListTile(
        // Avatar mit Rollen-Icon
        leading: CircleAvatar(
          backgroundColor: isSuperUser ? Colors.purple : Colors.indigo,
          child: Icon(
            isSuperUser ? Icons.admin_panel_settings : Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
        
        // Name und Informationen
        title: Row(
          children: [
            Text(
              '${staffUser.firstName} ${staffUser.lastName}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSuperUser ? Colors.purple[800] : null,
              ),
            ),
            if (isSuperUser) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star, size: 16, color: Colors.purple),
              const Text(
                ' SUPER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
            if (!isActive) ...[
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
              staffUser.email,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            // Rollen-Anzeige anstatt Staff-Level
            FutureBuilder<List<Role>>(
              future: _loadUserRoles(staffUser.id!),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Rollen laden...');
                }
                
                String roleInfo;
                if (isSuperUser) {
                  roleInfo = 'Super-Administrator (alle Berechtigungen)';
                } else if (roleSnapshot.hasData && roleSnapshot.data!.isNotEmpty) {
                  final roleNames = roleSnapshot.data!.map((r) => r.displayName).take(3).join(', ');
                  final additionalCount = roleSnapshot.data!.length > 3 ? ' (+${roleSnapshot.data!.length - 3})' : '';
                  roleInfo = 'Rollen: $roleNames$additionalCount';
                } else {
                  roleInfo = 'Keine Rollen zugewiesen';
                }
                
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        roleInfo,
                        style: TextStyle(
                          color: isSuperUser ? Colors.purple[700] : null,
                          fontWeight: isSuperUser ? FontWeight.w500 : null,
                        ),
                      ),
                    ),
                    if (staffUser.employeeId != null) ...[
                      Text(' • ID: ${staffUser.employeeId}'),
                    ],
                    if (staffUser.phoneNumber != null) ...[
                      Text(' • Tel: ${staffUser.phoneNumber}'),
                    ],
                  ],
                );
              },
            ),
            if (staffUser.contractType != null) ...[
              const SizedBox(height: 2),
              Text(
                'Vertrag: ${_formatContractType(staffUser.contractType!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        
        // Aktionen
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔐 Rollen verwalten
            PermissionWrapper(
              requiredPermission: 'can_view_staff_roles',
              child: IconButton(
                onPressed: staffProvider.isLoading 
                    ? null 
                    : () => _showRoleAssignmentDialog(staffUser),
                icon: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
                tooltip: 'Rollen verwalten',
              ),
            ),
            
            // Status Toggle (nur für normale User)
            if (!isSuperUser)
              PermissionWrapper(
                requiredPermission: 'can_edit_staff',
                child: IconButton(
                  onPressed: staffProvider.isLoading 
                      ? null 
                      : () => _toggleStaffUserStatus(staffUser, staffProvider),
                  icon: Icon(
                    isActive ? Icons.visibility : Icons.visibility_off,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                  tooltip: isActive ? 'Deaktivieren' : 'Aktivieren',
                ),
              ),
            
            // Bearbeiten (nur für normale User)
            if (!isSuperUser)
              PermissionWrapper(
                requiredPermission: 'can_edit_staff',
                child: IconButton(
                  onPressed: staffProvider.isLoading 
                      ? null 
                      : () => _editStaffUser(staffUser),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Bearbeiten',
                ),
              ),
            
            // Löschen (für normale User)
            if (!isSuperUser)
              PermissionWrapper(
                requiredPermission: 'can_delete_staff',
                child: IconButton(
                  onPressed: staffProvider.isLoading 
                      ? null 
                      : () => _deleteStaffUser(staffUser, staffProvider),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Löschen',
                ),
              ),
            
            // Löschen für Super-User (mit spezieller Sicherheitsprüfung)
            if (isSuperUser)
              PermissionWrapper(
                requiredPermission: 'can_delete_staff',
                child: IconButton(
                  onPressed: staffProvider.isLoading 
                      ? null 
                      : () => _deleteSuperUser(staffUser, staffProvider),
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'Superuser löschen (Passwort erforderlich)',
                ),
              ),
          ],
        ),
        
        isThreeLine: true,
      ),
    );
  }

  // Staff-Level Methoden entfernt - durch Rollen-System ersetzt

  String _formatContractType(String contractType) {
    switch (contractType) {
      case 'full_time':
        return 'Vollzeit';
      case 'part_time':
        return 'Teilzeit';
      case 'contractor':
        return 'Auftragnehmer';
      case 'intern':
        return 'Praktikant';
      case 'freelance':
        return 'Freelancer';
      default:
        return contractType;
    }
  }

  /// **Lädt verfügbare Rollen für Filter-Dropdown**
  Future<List<Role>> _loadAvailableRoles() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final roles = await client.permissionManagement.getActiveRoles();
      return roles;
    } catch (e) {
      debugPrint('Error loading roles for filter: $e');
      return [];
    }
  }

  /// **Lädt die Rollen eines Staff-Users**
  Future<List<Role>> _loadUserRoles(int staffUserId) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final roles = await client.permissionManagement.getStaffRoles(staffUserId);
      return roles;
    } catch (e) {
      debugPrint('Error loading user roles for $staffUserId: $e');
      return [];
    }
  }

  void _showCreateStaffUserDialog() {
    final client = Provider.of<Client>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => StaffUserEmailCreationDialog(client: client),
    ).then((result) {
      if (result != null) {
        // Staff-User wurde erfolgreich erstellt, Provider aktualisieren
        final provider = Provider.of<StaffUserStateProvider>(context, listen: false);
        provider.refresh();
      }
    });
  }

  void _showRoleAssignmentDialog(StaffUser staffUser) {
    showDialog(
      context: context,
      builder: (context) => RoleAssignmentDialog(staffUser: staffUser),
    );
  }

  void _editStaffUser(StaffUser staffUser) {
    showDialog(
      context: context,
      builder: (context) => StaffUserEditDialog(staffUser: staffUser),
    ).then((result) {
      if (result != null) {
        // Staff-User wurde erfolgreich bearbeitet, Provider aktualisieren
        final provider = Provider.of<StaffUserStateProvider>(context, listen: false);
        provider.refresh();
      }
    });
  }

  Future<void> _toggleStaffUserStatus(StaffUser staffUser, StaffUserStateProvider staffProvider) async {
    final success = await staffProvider.toggleStaffUserStatus(staffUser);
    
    if (success && mounted) {
      final newStatus = staffUser.employmentStatus == 'active' ? 'inaktiv' : 'aktiv';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Staff-User "${staffUser.firstName} ${staffUser.lastName}" $newStatus gesetzt',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteStaffUser(StaffUser staffUser, StaffUserStateProvider staffProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Staff-User löschen'),
        content: Text(
          'Möchten Sie den Staff-User "${staffUser.firstName} ${staffUser.lastName}" wirklich löschen?\n\n'
          'Diese Aktion kann nicht rückgängig gemacht werden.\n\n'
          '⚠️ Alle Rollen-Zuweisungen und Permissions werden ebenfalls entfernt.',
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
      final success = await staffProvider.deleteStaffUser(staffUser);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Staff-User "${staffUser.firstName} ${staffUser.lastName}" erfolgreich gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// **Superuser löschen (mit Passwort-Bestätigung und Sicherheitsprüfungen)**
  Future<void> _deleteSuperUser(StaffUser staffUser, StaffUserStateProvider staffProvider) async {
    // 1. Prüfe ob mindestens 2 Superuser existieren
    final superUserCount = staffProvider.allStaffUsers
        .where((user) => user.staffLevel == StaffUserType.superUser && user.employmentStatus == 'active')
        .length;
    
    if (superUserCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Der letzte Superuser kann nicht gelöscht werden!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Zeige Passwort-Eingabe Dialog
    final password = await _showSuperUserPasswordDialog(staffUser);
    if (password == null || password.isEmpty) {
      return; // Benutzer hat abgebrochen
    }

    // 3. Bestätigungs-Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Superuser löschen'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchten Sie den Superuser "${staffUser.firstName} ${staffUser.lastName}" wirklich löschen?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('⚠️ ACHTUNG: Diese Aktion kann nicht rückgängig gemacht werden!'),
            const SizedBox(height: 8),
            const Text('• Alle Berechtigungen werden entfernt'),
            const Text('• Zugriff auf Administratorfunktionen wird gesperrt'),
            const Text('• Rollenzuweisungen werden gelöscht'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Superuser löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 4. Löschung durchführen
    try {
      final client = Provider.of<Client>(context, listen: false);
      final success = await client.user.deleteSuperUser(staffUser.id!, password);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Superuser "${staffUser.firstName} ${staffUser.lastName}" erfolgreich gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
        staffProvider.refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Fehler beim Löschen des Superusers (falsches Passwort?)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Fehler: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// **Passwort-Eingabe Dialog für Superuser-Aktionen**
  Future<String?> _showSuperUserPasswordDialog(StaffUser staffUser) async {
    final passwordController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            SizedBox(width: 8),
            Text('Sicherheitsbestätigung'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Um den Superuser "${staffUser.firstName} ${staffUser.lastName}" zu löschen, geben Sie Ihr aktuelles Passwort ein:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Ihr Passwort',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(passwordController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Bestätigen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}