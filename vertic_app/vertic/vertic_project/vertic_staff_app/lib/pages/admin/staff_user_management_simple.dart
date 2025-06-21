import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';
import '../../widgets/password_input_dialog.dart';

class StaffUserManagementSimplePage extends StatefulWidget {
  final VoidCallback onBack;

  const StaffUserManagementSimplePage({
    super.key,
    required this.onBack,
  });

  @override
  State<StaffUserManagementSimplePage> createState() =>
      _StaffUserManagementSimplePageState();
}

class _StaffUserManagementSimplePageState
    extends State<StaffUserManagementSimplePage> {
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
        title: const Text('👥 Staff-Benutzer (Neu)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.green,
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
        Container(
          color: Colors.green[50],
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Neue StaffUser Tabelle - getrennt von normalen Kunden! ${_staffUsers.length} Staff-Benutzer',
                  style: const TextStyle(fontWeight: FontWeight.w500),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'StaffUser',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
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
                  Chip(
                    label: Text('MA-Nr: ${staffUser.employeeId}'),
                    backgroundColor: Colors.blue[100],
                    labelStyle: const TextStyle(fontSize: 11),
                  ),
                if (staffUser.contractType != null)
                  Chip(
                    label: Text('${staffUser.contractType}'),
                    backgroundColor: Colors.purple[100],
                    labelStyle: const TextStyle(fontSize: 11),
                  ),
                if (staffUser.hourlyRate != null)
                  Chip(
                    label: Text('${staffUser.hourlyRate}€/h'),
                    backgroundColor: Colors.orange[100],
                    labelStyle: const TextStyle(fontSize: 11),
                  ),
                Chip(
                  label: Text(staffUser.employmentStatus),
                  backgroundColor: staffUser.employmentStatus == 'active'
                      ? Colors.green[100]
                      : Colors.red[100],
                  labelStyle: const TextStyle(fontSize: 11),
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

  void _showCreateStaffUserDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateStaffUserDialog(
        onStaffUserCreated: _loadStaffUsers,
      ),
    );
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🆕 Neuer Staff-Benutzer'),
      content: SizedBox(
        width: 400,
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

      // 🔄 UNIFIED AUTH: Direkte Parameter mit sicherem Passwort
      final result = await client.unifiedAuth.createStaffUser(
        username, // username
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
              'Staff-User ${_firstNameController.text.trim()} ${_lastNameController.text.trim()} wurde erfolgreich erstellt'),
          backgroundColor: Colors.green,
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
