import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';
import '../../widgets/password_input_dialog.dart';

class StaffManagementPage extends StatefulWidget {
  final VoidCallback onBack;

  const StaffManagementPage({
    super.key,
    required this.onBack,
  });

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  List<StaffUser> _staffUsers = [];
  List<Role> _roles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Parallel laden für bessere Performance
      final results = await Future.wait([
        client.unifiedAuth.getAllStaffUsers(),
        // client.rbac.getAllRoles(), // Temporär deaktiviert - RBAC wird überarbeitet
        Future.value(<Role>[]), // Leere Liste als Platzhalter
      ]);

      setState(() {
        _staffUsers = results[0] as List<StaffUser>;
        _roles = results[1] as List<Role>;
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
        title: const Text('👥 Staff-Verwaltung (Neue Tabelle)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: Icon(Icons.people),
              text: 'Staff (${_staffUsers.length})',
            ),
            Tab(
              icon: Icon(Icons.admin_panel_settings),
              text: 'Rollen (${_roles.length})',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'HR-Analytics',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStaffUsersTab(),
                    _buildRolesTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showCreateStaffUserDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Neuer Staff'),
              backgroundColor: Colors.green,
            )
          : _tabController.index == 1
              ? FloatingActionButton.extended(
                  onPressed: _showCreateRoleDialog,
                  icon: const Icon(Icons.add_moderator),
                  label: const Text('Neue Rolle'),
                  backgroundColor: Colors.purple,
                )
              : null,
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
                onPressed: _loadInitialData,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== TAB 1: STAFF USERS =====
  Widget _buildStaffUsersTab() {
    return Column(
      children: [
        // Info Banner
        Container(
          width: double.infinity,
          color: Colors.green[50],
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Neue StaffUser Tabelle - getrennt von Kunden! HR-Daten, Gehälter, Verträge...',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh, color: Colors.green),
                tooltip: 'Aktualisieren',
              ),
            ],
          ),
        ),
        // Staff List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitialData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Avatar und Grundinfo
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getStaffLevelColor(staffUser.staffLevel),
                  child: Icon(
                    _getStaffLevelIcon(staffUser.staffLevel),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStaffLevelColor(staffUser.staffLevel)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStaffLevelText(staffUser.staffLevel),
                          style: TextStyle(
                            color: _getStaffLevelColor(staffUser.staffLevel),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Bearbeiten'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'roles',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, size: 18),
                          SizedBox(width: 8),
                          Text('Rollen verwalten'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'hr',
                      child: Row(
                        children: [
                          Icon(Icons.work, size: 18),
                          SizedBox(width: 8),
                          Text('HR-Daten'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset, size: 18),
                          SizedBox(width: 8),
                          Text('Passwort zurücksetzen'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // HR-Info Chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (staffUser.employeeId != null)
                  _buildInfoChip(
                    'MA-Nr: ${staffUser.employeeId}',
                    Colors.blue,
                    Icons.badge,
                  ),
                if (staffUser.contractType != null)
                  _buildInfoChip(
                    staffUser.contractType!,
                    Colors.purple,
                    Icons.description,
                  ),
                if (staffUser.hourlyRate != null)
                  _buildInfoChip(
                    '${staffUser.hourlyRate}€/h',
                    Colors.orange,
                    Icons.schedule,
                  ),
                if (staffUser.monthlySalary != null)
                  _buildInfoChip(
                    '${staffUser.monthlySalary}€/Monat',
                    Colors.green,
                    Icons.attach_money,
                  ),
                _buildInfoChip(
                  staffUser.employmentStatus,
                  staffUser.employmentStatus == 'active'
                      ? Colors.green
                      : Colors.red,
                  staffUser.employmentStatus == 'active'
                      ? Icons.check_circle
                      : Icons.cancel,
                ),
                if (staffUser.departmentId != null)
                  _buildInfoChip(
                    'Abt: ${staffUser.departmentId}',
                    Colors.teal,
                    Icons.group_work,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ===== TAB 2: ROLLEN =====
  Widget _buildRolesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _roles.length,
      itemBuilder: (context, index) {
        final role = _roles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.admin_panel_settings, color: Colors.white),
            ),
            title: Text(role.name),
            subtitle: Text(role.description ?? 'Keine Beschreibung'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleRoleAction(value, role),
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
                  value: 'permissions',
                  child: Row(
                    children: [
                      Icon(Icons.security),
                      SizedBox(width: 8),
                      Text('Berechtigungen'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Löschen'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== TAB 3: ANALYTICS =====
  Widget _buildAnalyticsTab() {
    final totalStaff = _staffUsers.length;
    final activeStaff =
        _staffUsers.where((s) => s.employmentStatus == 'active').length;
    final superUsers = _staffUsers
        .where((s) => s.staffLevel == StaffUserType.superUser)
        .length;
    final admins = _staffUsers
        .where((s) =>
            s.staffLevel == StaffUserType.facilityAdmin ||
            s.staffLevel == StaffUserType.hallAdmin)
        .length;
    final regularStaff =
        _staffUsers.where((s) => s.staffLevel == StaffUserType.staff).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HR-Analytics Übersicht',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          // Statistik Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard('Gesamt Staff', totalStaff.toString(), Colors.blue,
                  Icons.people),
              _buildStatCard('Aktiv', activeStaff.toString(), Colors.green,
                  Icons.check_circle),
              _buildStatCard('Super-Admins', superUsers.toString(), Colors.red,
                  Icons.verified),
              _buildStatCard('Admins', admins.toString(), Colors.orange,
                  Icons.admin_panel_settings),
              _buildStatCard('Mitarbeiter', regularStaff.toString(),
                  Colors.purple, Icons.person),
              _buildStatCard('Rollen', _roles.length.toString(), Colors.teal,
                  Icons.security),
            ],
          ),
          const SizedBox(height: 24),
          // Verteilungsübersicht
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Staff-Level Verteilung',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildDistributionBar(
                      'Super-Admin', superUsers, totalStaff, Colors.red),
                  _buildDistributionBar(
                      'Facility-Admin',
                      _staffUsers
                          .where((s) =>
                              s.staffLevel == StaffUserType.facilityAdmin)
                          .length,
                      totalStaff,
                      Colors.purple),
                  _buildDistributionBar(
                      'Hallen-Admin',
                      _staffUsers
                          .where((s) => s.staffLevel == StaffUserType.hallAdmin)
                          .length,
                      totalStaff,
                      Colors.orange),
                  _buildDistributionBar(
                      'Mitarbeiter', regularStaff, totalStaff, Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(
      String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ===== HELPER METHODS =====
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

  // ===== ACTION HANDLERS =====
  void _handleStaffUserAction(String action, StaffUser staffUser) {
    switch (action) {
      case 'edit':
        _showEditStaffUserDialog(staffUser);
        break;
      case 'roles':
        _showRoleAssignmentDialog(staffUser);
        break;
      case 'hr':
        _showHRDataDialog(staffUser);
        break;
      case 'password':
        _showPasswordResetDialog(staffUser);
        break;
    }
  }

  void _handleRoleAction(String action, Role role) {
    switch (action) {
      case 'edit':
        _showEditRoleDialog(role);
        break;
      case 'permissions':
        _showPermissionsDialog(role);
        break;
      case 'delete':
        _showDeleteRoleDialog(role);
        break;
    }
  }

  // ===== DIALOGE =====
  void _showCreateStaffUserDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateStaffUserDialog(
        onStaffUserCreated: _loadInitialData,
      ),
    );
  }

  void _showEditStaffUserDialog(StaffUser staffUser) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Bearbeitung für ${staffUser.firstName} ${staffUser.lastName} wird implementiert...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showRoleAssignmentDialog(StaffUser staffUser) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Rollen-Zuordnung für ${staffUser.firstName} ${staffUser.lastName} wird implementiert...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _showHRDataDialog(StaffUser staffUser) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'HR-Daten für ${staffUser.firstName} ${staffUser.lastName} werden implementiert...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showPasswordResetDialog(StaffUser staffUser) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Passwort-Reset für ${staffUser.firstName} ${staffUser.lastName} wird implementiert...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showCreateRoleDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Neue Rolle erstellen wird implementiert...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _showEditRoleDialog(Role role) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rolle "${role.name}" bearbeiten wird implementiert...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showPermissionsDialog(Role role) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Berechtigungen für "${role.name}" werden implementiert...'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showDeleteRoleDialog(Role role) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Löschen von "${role.name}" wird implementiert...'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ===== CREATE STAFF USER DIALOG =====
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
  final _employeeIdController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _monthlySalaryController = TextEditingController();

  StaffUserType _selectedStaffLevel = StaffUserType.staff;
  String _selectedContractType = 'unbefristet';
  bool _isCreating = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _hourlyRateController.dispose();
    _monthlySalaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_add, color: Colors.green),
          const SizedBox(width: 8),
          const Text('🆕 Neuer Staff-Benutzer'),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Persönliche Daten
                _buildSectionHeader('Persönliche Daten', Icons.person),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Vorname *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vorname ist erforderlich';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nachname *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nachname ist erforderlich';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail *',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
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
                    labelText: 'Telefon',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),

                // System-Level
                _buildSectionHeader(
                    'System-Zugang', Icons.admin_panel_settings),
                const SizedBox(height: 8),
                DropdownButtonFormField<StaffUserType>(
                  value: _selectedStaffLevel,
                  decoration: const InputDecoration(
                    labelText: 'Staff-Level *',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: StaffUserType.staff,
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue, size: 18),
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
                              color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text('Hallen-Administrator'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: StaffUserType.facilityAdmin,
                      child: Row(
                        children: [
                          Icon(Icons.business, color: Colors.purple, size: 18),
                          SizedBox(width: 8),
                          Text('Facility-Administrator'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: StaffUserType.superUser,
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: Colors.red, size: 18),
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

                // HR-Daten
                _buildSectionHeader('HR-Daten', Icons.work),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Mitarbeiter-Nummer',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedContractType,
                  decoration: const InputDecoration(
                    labelText: 'Vertrag-Typ',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'unbefristet', child: Text('Unbefristet')),
                    DropdownMenuItem(
                        value: 'befristet', child: Text('Befristet')),
                    DropdownMenuItem(value: 'minijob', child: Text('Minijob')),
                    DropdownMenuItem(
                        value: 'praktikum', child: Text('Praktikum')),
                    DropdownMenuItem(
                        value: 'aushilfe', child: Text('Aushilfe')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedContractType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Stundenlohn (€)',
                          prefixIcon: Icon(Icons.schedule),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _monthlySalaryController,
                        decoration: const InputDecoration(
                          labelText: 'Monatsgehalt (€)',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
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
              : const Text('Staff erstellen'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
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
      final username = _employeeIdController.text.trim().isEmpty
          ? _firstNameController.text.trim().toLowerCase()
          : _employeeIdController.text.trim();

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

      // 🔄 UNIFIED AUTH: Direkte Parameter mit sicherem Passwort
      final result = await client.unifiedAuth.createStaffUser(
        username, // username (employeeId oder firstName)
        password, // Sicheres Passwort vom Dialog
        _firstNameController.text.trim(), // firstName
        _lastNameController.text.trim(), // lastName
        _emailController.text.trim(), // realEmail
        _selectedStaffLevel, // staffLevel
      );

      if (result.success != true) {
        throw Exception(result.message ?? 'Unbekannter Fehler');
      }

      Navigator.pop(context);
      widget.onStaffUserCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Staff-User ${_firstNameController.text.trim()} ${_lastNameController.text.trim()} wurde erfolgreich erstellt!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Fehler beim Erstellen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
