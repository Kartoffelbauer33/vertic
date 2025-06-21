// Neue StaffUser Seite

import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';
import '../../widgets/password_input_dialog.dart';

class StaffNewPage extends StatefulWidget {
  final VoidCallback onBack;

  const StaffNewPage({
    super.key,
    required this.onBack,
  });

  @override
  State<StaffNewPage> createState() => _StaffNewPageState();
}

class _StaffNewPageState extends State<StaffNewPage> {
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
        title: const Text('?? StaffUser Verwaltung (Neue Tabelle)'),
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
              : _buildStaffList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Neuer Staff'),
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
              Text('Fehler', style: Theme.of(context).textTheme.headlineSmall),
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

  Widget _buildStaffList() {
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
                  '? Neue StaffUser Tabelle - getrennt von Kunden! ${_staffUsers.length} Staff-Benutzer mit HR-Daten',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadStaffUsers,
                icon: const Icon(Icons.refresh, color: Colors.green),
              ),
            ],
          ),
        ),
        // Staff List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadStaffUsers,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _staffUsers.length,
              itemBuilder: (context, index) {
                final staffUser = _staffUsers[index];
                return _buildStaffCard(staffUser);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffCard(StaffUser staffUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Avatar und Grundinfo
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _getStaffLevelColor(staffUser.staffLevel),
                  child: Icon(
                    _getStaffLevelIcon(staffUser.staffLevel),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${staffUser.firstName} ${staffUser.lastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        staffUser.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStaffLevelColor(staffUser.staffLevel)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStaffLevelColor(staffUser.staffLevel)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _getStaffLevelText(staffUser.staffLevel),
                          style: TextStyle(
                            color: _getStaffLevelColor(staffUser.staffLevel),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // StaffUser Badge
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                    const SizedBox(height: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleAction(value, staffUser),
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
                          value: 'roles',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings, size: 18),
                              SizedBox(width: 8),
                              Text('Rollen'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // HR-Informationen
            Wrap(
              spacing: 8,
              runSpacing: 6,
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
                    '${staffUser.hourlyRate}�/h',
                    Colors.orange,
                    Icons.schedule,
                  ),
                if (staffUser.monthlySalary != null)
                  _buildInfoChip(
                    '${staffUser.monthlySalary}�/Monat',
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
                if (staffUser.phoneNumber != null)
                  _buildInfoChip(
                    staffUser.phoneNumber!,
                    Colors.indigo,
                    Icons.phone,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
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

  void _handleAction(String action, StaffUser staffUser) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Bearbeitung f�r ${staffUser.firstName} ${staffUser.lastName} wird implementiert...'),
            backgroundColor: Colors.blue,
          ),
        );
        break;
      case 'hr':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'HR-Daten f�r ${staffUser.firstName} ${staffUser.lastName} werden implementiert...'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'roles':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Rollen-Management f�r ${staffUser.firstName} ${staffUser.lastName} wird implementiert...'),
            backgroundColor: Colors.purple,
          ),
        );
        break;
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateStaffDialog(
        onStaffCreated: _loadStaffUsers,
      ),
    );
  }
}

// Create Staff Dialog
class CreateStaffDialog extends StatefulWidget {
  final VoidCallback onStaffCreated;

  const CreateStaffDialog({
    super.key,
    required this.onStaffCreated,
  });

  @override
  State<CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends State<CreateStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _salaryController = TextEditingController();

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
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_add, color: Colors.green),
          const SizedBox(width: 8),
          const Text('?? Neuer Staff-Benutzer'),
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
                // Pers�nliche Daten
                Text('?? Pers�nliche Daten',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 12),
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
                        validator: (value) => value?.trim().isEmpty == true
                            ? 'Vorname erforderlich'
                            : null,
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
                        validator: (value) => value?.trim().isEmpty == true
                            ? 'Nachname erforderlich'
                            : null,
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
                    if (value?.trim().isEmpty == true)
                      return 'E-Mail erforderlich';
                    if (!value!.contains('@')) return 'G�ltige E-Mail eingeben';
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

                // System Level
                Text('?? System-Zugang',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 12),
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
                  onChanged: (value) =>
                      setState(() => _selectedStaffLevel = value!),
                ),
                const SizedBox(height: 24),

                // HR-Daten
                Text('?? HR-Daten',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 12),
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
                  onChanged: (value) =>
                      setState(() => _selectedContractType = value!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Stundenlohn (�)',
                          prefixIcon: Icon(Icons.schedule),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _salaryController,
                        decoration: const InputDecoration(
                          labelText: 'Monatsgehalt (�)',
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Staff erstellen'),
        ),
      ],
    );
  }

  Future<void> _createStaffUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

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
        setState(() => _isCreating = false);
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
      widget.onStaffCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ ${_firstNameController.text.trim()} ${_lastNameController.text.trim()} wurde erfolgreich erstellt!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isCreating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('? Fehler beim Erstellen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
