import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

class StaffUserEditDialog extends StatefulWidget {
  final StaffUser staffUser;

  const StaffUserEditDialog({
    super.key,
    required this.staffUser,
  });

  @override
  State<StaffUserEditDialog> createState() => _StaffUserEditDialogState();
}

class _StaffUserEditDialogState extends State<StaffUserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers für Eingabefelder
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _phoneController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _monthlySalaryController;
  late final TextEditingController _workingHoursController;

  // Status und Auswahlen
  bool _isLoading = false;
  String? _errorMessage;
  String _employmentStatus = 'active';
  String? _contractType;
  List<Role> _availableRoles = [];
  List<int> _selectedRoleIds = [];

  @override
  void initState() {
    super.initState();
    // Controllers mit aktuellen Werten initialisieren
    _firstNameController = TextEditingController(text: widget.staffUser.firstName);
    _lastNameController = TextEditingController(text: widget.staffUser.lastName);
    _emailController = TextEditingController(text: widget.staffUser.email);
    _employeeIdController = TextEditingController(text: widget.staffUser.employeeId ?? '');
    _phoneController = TextEditingController(text: widget.staffUser.phoneNumber ?? '');
    _hourlyRateController = TextEditingController(text: widget.staffUser.hourlyRate?.toString() ?? '');
    _monthlySalaryController = TextEditingController(text: widget.staffUser.monthlySalary?.toString() ?? '');
    _workingHoursController = TextEditingController(text: widget.staffUser.workingHours?.toString() ?? '');

    _employmentStatus = widget.staffUser.employmentStatus ?? 'active';
    _contractType = widget.staffUser.contractType;
    
    _loadAvailableRoles();
    _loadCurrentUserRoles();
  }

  Future<void> _loadAvailableRoles() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final roles = await client.permissionManagement.getAllRoles();
      setState(() {
        _availableRoles = roles;
      });
    } catch (e) {
      debugPrint('Error loading roles: $e');
    }
  }

  Future<void> _loadCurrentUserRoles() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final roles = await client.permissionManagement.getStaffRoles(widget.staffUser.id!);
      setState(() {
        _selectedRoleIds = roles.map((r) => r.id!).toList();
      });
    } catch (e) {
      debugPrint('Error loading current user roles: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _hourlyRateController.dispose();
    _monthlySalaryController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.edit, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    'Staff-User bearbeiten',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Scrollbarer Inhalt
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 16),
                      _buildContactSection(),
                      const SizedBox(height: 16),
                      _buildEmploymentSection(),
                      const SizedBox(height: 16),
                      _buildRolesSection(),
                      
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Änderungen speichern'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Persönliche Daten',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Vorname',
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
                  labelText: 'Nachname',
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
            labelText: 'E-Mail-Adresse',
            border: OutlineInputBorder(),
          ),
          enabled: false, // E-Mail sollte nicht geändert werden
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kontaktdaten',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _employeeIdController,
                decoration: const InputDecoration(
                  labelText: 'Mitarbeiter-ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefonnummer',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmploymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Arbeitsverhältnis',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _employmentStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Aktiv')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inaktiv')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspendiert')),
                ],
                onChanged: (value) => setState(() => _employmentStatus = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _contractType,
                decoration: const InputDecoration(
                  labelText: 'Vertragsart',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Nicht angegeben')),
                  DropdownMenuItem(value: 'full_time', child: Text('Vollzeit')),
                  DropdownMenuItem(value: 'part_time', child: Text('Teilzeit')),
                  DropdownMenuItem(value: 'contractor', child: Text('Auftragnehmer')),
                  DropdownMenuItem(value: 'intern', child: Text('Praktikant')),
                  DropdownMenuItem(value: 'freelance', child: Text('Freelancer')),
                ],
                onChanged: (value) => setState(() => _contractType = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Stundenlohn (€)',
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
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _workingHoursController,
                decoration: const InputDecoration(
                  labelText: 'Wochenstunden',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRolesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rollen und Berechtigungen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          decoration: const InputDecoration(
            labelText: 'Rolle zuweisen',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.admin_panel_settings),
          ),
          value: _selectedRoleIds.isNotEmpty ? _selectedRoleIds.first : null,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Keine Rolle zuweisen'),
            ),
            ..._availableRoles.map((role) {
              return DropdownMenuItem<int?>(
                value: role.id,
                child: Text(role.displayName),
              );
            }),
          ],
          onChanged: (roleId) {
            setState(() {
              _selectedRoleIds.clear();
              if (roleId != null) {
                _selectedRoleIds.add(roleId);
              }
            });
          },
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);
      
      // 1. Staff-User-Daten aktualisieren
      final updatedStaffUser = widget.staffUser.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        employeeId: _employeeIdController.text.trim().isEmpty ? null : _employeeIdController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        employmentStatus: _employmentStatus,
        contractType: _contractType,
        hourlyRate: _hourlyRateController.text.trim().isEmpty ? null : double.tryParse(_hourlyRateController.text.trim()),
        monthlySalary: _monthlySalaryController.text.trim().isEmpty ? null : double.tryParse(_monthlySalaryController.text.trim()),
        workingHours: _workingHoursController.text.trim().isEmpty ? null : int.tryParse(_workingHoursController.text.trim()),
        updatedAt: DateTime.now(),
      );

      // 2. Staff-User in Datenbank aktualisieren
      await client.user.updateStaffUser(updatedStaffUser);

      // 3. Rollen-Zuweisungen aktualisieren
      await client.permissionManagement.updateStaffRoles(widget.staffUser.id!, _selectedRoleIds);

      // 4. Erfolg melden
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Staff-User "${updatedStaffUser.firstName} ${updatedStaffUser.lastName}" erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(updatedStaffUser);
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Speichern: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}