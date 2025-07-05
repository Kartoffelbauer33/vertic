import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';
import '../../widgets/password_input_dialog.dart';

class StaffUserManagementPage extends StatefulWidget {
  final VoidCallback onBack;

  const StaffUserManagementPage({
    super.key,
    required this.onBack,
  });

  @override
  State<StaffUserManagementPage> createState() =>
      _StaffUserManagementPageState();
}

class _StaffUserManagementPageState extends State<StaffUserManagementPage> {
  bool _isLoading = false;
  String? _errorMessage;
  List<StaffUser> _staffUsers = [];

  @override
  void initState() {
    super.initState();
    _loadStaffUsers();
  }

  Future<void> _loadStaffUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final staffUsers = await client.unifiedAuth.getAllStaffUsers();
      setState(() {
        _staffUsers = staffUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Staff-Benutzer Verwaltung'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildStaffUsersList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateStaffUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Neuer Staff-User'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Fehler',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Unbekannter Fehler'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStaffUsers,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffUsersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_staffUsers.length} Staff-Benutzer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: _loadStaffUsers,
                icon: const Icon(Icons.refresh),
                tooltip: 'Aktualisieren',
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadStaffUsers,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _staffUsers.length,
              itemBuilder: (context, index) {
                final staffUser = _staffUsers[index];
                return _buildStaffUserCard(staffUser);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffUserCard(StaffUser staffUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStaffLevelColor(staffUser.staffLevel),
                  child: Icon(
                    _getStaffLevelIcon(staffUser.staffLevel),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${staffUser.firstName} ${staffUser.lastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        staffUser.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _getStaffLevelText(staffUser.staffLevel),
                        style: TextStyle(
                          color: _getStaffLevelColor(staffUser.staffLevel),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleStaffUserAction(value, staffUser),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Bearbeiten'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'roles',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings),
                          SizedBox(width: 8),
                          Text('Rollen verwalten'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset),
                          SizedBox(width: 8),
                          Text('Passwort zurücksetzen'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Löschen', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Zusätzliche Info-Chips
            Wrap(
              spacing: 6,
              children: [
                if (staffUser.employeeId != null)
                  Chip(
                    label: Text('ID: ${staffUser.employeeId}'),
                    backgroundColor: Colors.blue[100],
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (staffUser.departmentId != null)
                  Chip(
                    label: Text('Abteilung: ${staffUser.departmentId}'),
                    backgroundColor: Colors.purple[100],
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                Chip(
                  label: Text(staffUser.employmentStatus),
                  backgroundColor: staffUser.employmentStatus == 'active'
                      ? Colors.green[100]
                      : Colors.red[100],
                  labelStyle: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStaffLevelColor(StaffUserType staffLevel) {
    switch (staffLevel) {
      case StaffUserType.superUser:
        return Colors.red;
      case StaffUserType.facilityAdmin:
        return Colors.purple;
      case StaffUserType.hallAdmin:
        return Colors.orange;
      case StaffUserType.staff:
        return Colors.blue;
    }
  }

  IconData _getStaffLevelIcon(StaffUserType staffLevel) {
    switch (staffLevel) {
      case StaffUserType.superUser:
        return Icons.verified;
      case StaffUserType.facilityAdmin:
        return Icons.business;
      case StaffUserType.hallAdmin:
        return Icons.admin_panel_settings;
      case StaffUserType.staff:
        return Icons.person;
    }
  }

  String _getStaffLevelText(StaffUserType staffLevel) {
    switch (staffLevel) {
      case StaffUserType.superUser:
        return 'Super-Administrator';
      case StaffUserType.facilityAdmin:
        return 'Facility-Administrator';
      case StaffUserType.hallAdmin:
        return 'Hallen-Administrator';
      case StaffUserType.staff:
        return 'Mitarbeiter';
    }
  }

  void _handleStaffUserAction(String action, StaffUser staffUser) {
    switch (action) {
      case 'edit':
        _showEditStaffUserDialog(staffUser);
        break;
      case 'roles':
        _showRoleManagementDialog(staffUser);
        break;
      case 'password':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwort-Reset wird implementiert...')),
        );
        break;
      case 'delete':
        _showDeleteStaffUserDialog(staffUser);
        break;
    }
  }

  void _showCreateStaffUserDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateStaffUserDialog(
        onStaffUserCreated: _loadStaffUsers,
      ),
    );
  }

  void _showEditStaffUserDialog(StaffUser staffUser) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bearbeitung wird implementiert...')),
    );
  }

  void _showRoleManagementDialog(StaffUser staffUser) {
    showDialog(
      context: context,
      builder: (context) => RoleManagementDialog(
        staffUser: staffUser,
        onRolesUpdated: _loadStaffUsers,
      ),
    );
  }

  void _showDeleteStaffUserDialog(StaffUser staffUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Staff-User löschen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Möchten Sie den Staff-User wirklich löschen?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${staffUser.firstName} ${staffUser.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('E-Mail: ${staffUser.email}'),
                  Text('Level: ${_getStaffLevelText(staffUser.staffLevel)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Diese Aktion kann nicht rückgängig gemacht werden!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStaffUser(staffUser);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaffUser(StaffUser staffUser) async {
    try {
      await client.staffUserManagement.deleteStaffUser(staffUser.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Staff-User ${staffUser.firstName} ${staffUser.lastName} wurde gelöscht'),
          backgroundColor: Colors.green,
        ),
      );

      _loadStaffUsers(); // Liste aktualisieren
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class CreateStaffUserDialog extends StatefulWidget {
  final VoidCallback onStaffUserCreated;

  const CreateStaffUserDialog({
    super.key,
    required this.onStaffUserCreated,
  });

  @override
  State<CreateStaffUserDialog> createState() => _CreateStaffUserDialogState();
}

class _CreateStaffUserDialogState extends State<CreateStaffUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  StaffUserType _selectedStaffLevel = StaffUserType.staff;
  bool _isCreating = false;

  // RBAC Integration
  List<Role> _availableRoles = [];
  List<int> _selectedRoleIds = [];
  bool _rolesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableRoles();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableRoles() async {
    try {
      final roles = await client.permissionManagement.getAllRoles();
      setState(() {
        _availableRoles = roles.where((role) => role.isActive).toList();
        _rolesLoaded = true;
      });
    } catch (e) {
      setState(() {
        _rolesLoaded = true;
      });
      print('Fehler beim Laden der Rollen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🆕 Neuer Staff-Benutzer'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Vorname *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vorname ist erforderlich';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nachname *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nachname ist erforderlich';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'E-Mail ist erforderlich';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Bitte geben Sie eine gültige E-Mail ein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon (optional)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StaffUserType>(
                  value: _selectedStaffLevel,
                  decoration: const InputDecoration(
                    labelText: 'Staff-Level *',
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: StaffUserType.staff,
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Mitarbeiter'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: StaffUserType.hallAdmin,
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Hallen-Administrator'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: StaffUserType.facilityAdmin,
                      child: Row(
                        children: [
                          Icon(Icons.business, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Facility-Administrator'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: StaffUserType.superUser,
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Super-Administrator'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStaffLevel = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Rollen-Zuweisung Sektion
                const Divider(),
                const Row(
                  children: [
                    Icon(Icons.security, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'Rollen zuweisen (optional)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!_rolesLoaded)
                  const Center(child: CircularProgressIndicator())
                else if (_availableRoles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Keine aktiven Rollen verfügbar'),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableRoles.length,
                      itemBuilder: (context, index) {
                        final role = _availableRoles[index];
                        final isSelected = _selectedRoleIds.contains(role.id);

                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedRoleIds.add(role.id!);
                              } else {
                                _selectedRoleIds.remove(role.id);
                              }
                            });
                          },
                          title: Text(role.displayName),
                          subtitle: role.description != null
                              ? Text(role.description!)
                              : null,
                          secondary: Icon(
                            role.isSystemRole ? Icons.shield : Icons.group,
                            color:
                                role.isSystemRole ? Colors.red : Colors.indigo,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),

                if (_selectedRoleIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedRoleIds.length} Rolle(n) ausgewählt',
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createStaffUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Erstellen'),
        ),
      ],
    );
  }

  Future<void> _createStaffUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // 🔐 PHASE 3.3: Sichere Passwort-Eingabe
      final staffName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final username = _firstNameController.text.trim().toLowerCase();

      final password = await PasswordInputDialog.show(
        context: context,
        staffName: staffName,
        username: username,
      );

      if (password == null) {
        // User hat abgebrochen
        setState(() {
          _isCreating = false;
        });
        return;
      }

      // 🔄 UNIFIED AUTH: Neue E-Mail-basierte Staff-Erstellung
      final result = await client.unifiedAuth.createStaffUserWithEmail(
        _emailController.text.trim(), // email (echte E-Mail-Adresse)
        username, // username
        password, // Sicheres Passwort vom Dialog
        _firstNameController.text.trim(), // firstName
        _lastNameController.text.trim(), // lastName
        _selectedStaffLevel, // staffLevel
      );

      if (result.success != true) {
        throw Exception(result.message ?? 'Unbekannter Fehler');
      }

      // Extrahiere StaffUser aus dem Result
      final newStaffUser = result.staffUser!;

      // Rollen zuweisen, falls welche ausgewählt wurden
      if (_selectedRoleIds.isNotEmpty) {
        try {
          for (final roleId in _selectedRoleIds) {
            await client.staffUserManagement.assignRoleToStaffUser(
              newStaffUser.id!,
              roleId,
            );
          }
        } catch (e) {
          // Bei Fehlern bei der Rollenzuweisung trotzdem erfolgreich melden
          print('Fehler bei Rollenzuweisung: $e');
        }
      }

      Navigator.pop(context);
      widget.onStaffUserCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Staff-User ${_firstNameController.text.trim()} ${_lastNameController.text.trim()} wurde erfolgreich erstellt'
            '${_selectedRoleIds.isNotEmpty ? " und ${_selectedRoleIds.length} Rolle(n) zugewiesen" : ""}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Erstellen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ===== ROLLE MANAGEMENT DIALOG =====
class RoleManagementDialog extends StatefulWidget {
  final StaffUser staffUser;
  final VoidCallback onRolesUpdated;

  const RoleManagementDialog({
    super.key,
    required this.staffUser,
    required this.onRolesUpdated,
  });

  @override
  State<RoleManagementDialog> createState() => _RoleManagementDialogState();
}

class _RoleManagementDialogState extends State<RoleManagementDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Role> _allRoles = [];
  List<StaffUserRole> _userRoles = [];
  List<int> _selectedRoleIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        client.permissionManagement.getAllRoles(),
        client.staffUserManagement.getStaffUserRoles(widget.staffUser.id!),
      ]);

      _allRoles = futures[0] as List<Role>;
      _userRoles = futures[1] as List<StaffUserRole>;

      // Aktuelle Rollen als ausgewählt markieren
      _selectedRoleIds = _userRoles.map((ur) => ur.roleId).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.security, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rollen für ${widget.staffUser.firstName} ${widget.staffUser.lastName}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _buildRolesList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRoles,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text('Speichern', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Unbekannter Fehler'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verfügbare Rollen (${_allRoles.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _allRoles.length,
            itemBuilder: (context, index) {
              final role = _allRoles[index];
              final isSelected = _selectedRoleIds.contains(role.id);

              return Card(
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedRoleIds.add(role.id!);
                      } else {
                        _selectedRoleIds.remove(role.id);
                      }
                    });
                  },
                  title: Text(
                    role.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.name,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (role.description != null) Text(role.description!),
                    ],
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: _getRoleColor(role.name),
                    child: Icon(
                      _getRoleIcon(role.name),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_selectedRoleIds.length} von ${_allRoles.length} Rollen ausgewählt',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String technicalName) {
    switch (technicalName.toLowerCase()) {
      case 'super_admin':
        return Colors.red;
      case 'facility_admin':
        return Colors.purple;
      case 'hall_admin':
        return Colors.orange;
      case 'kassierer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String technicalName) {
    switch (technicalName.toLowerCase()) {
      case 'super_admin':
        return Icons.verified;
      case 'facility_admin':
        return Icons.business;
      case 'hall_admin':
        return Icons.admin_panel_settings;
      case 'kassierer':
        return Icons.point_of_sale;
      default:
        return Icons.person;
    }
  }

  Future<void> _saveRoles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Entferne alle alten Rollen
      for (final userRole in _userRoles) {
        await client.staffUserManagement.removeStaffUserRole(userRole.id!);
      }

      // Füge neue Rollen hinzu
      for (final roleId in _selectedRoleIds) {
        await client.staffUserManagement.assignRoleToStaffUser(
          widget.staffUser.id!,
          roleId,
        );
      }

      Navigator.pop(context);
      widget.onRolesUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rollen für ${widget.staffUser.firstName} ${widget.staffUser.lastName} wurden aktualisiert',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
