import 'package:flutter/material.dart';
import 'package:serverpod_auth_email_flutter/serverpod_auth_email_flutter.dart';
import 'package:test_server_client/test_server_client.dart';

/// **Staff-User Email-Erstellung Dialog (Serverpod-Style)**
/// 
/// Nutzt EmailAuthController genau wie die Client-App:
/// 1. Staff-Metadaten speichern
/// 2. Email-Verifizierung mit EmailAuthController starten
/// 3. Nach Verifizierung Staff-User mit Auth-User verknüpfen
class StaffUserEmailCreationDialog extends StatefulWidget {
  final Client client;

  const StaffUserEmailCreationDialog({
    super.key,
    required this.client,
  });

  @override
  State<StaffUserEmailCreationDialog> createState() =>
      _StaffUserEmailCreationDialogState();
}

class _StaffUserEmailCreationDialogState
    extends State<StaffUserEmailCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers für Eingabefelder
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _superuserPasswordController = TextEditingController();

  // EmailAuthController (genau wie Client-App)
  late final EmailAuthController _emailAuthController;

  // Status
  bool _isLoading = false;
  bool _showVerificationStep = false;
  String? _errorMessage;
  String? _verificationError;
  
  // Rollen-Auswahl
  List<Role> _availableRoles = [];
  final List<int> _selectedRoleIds = [];

  // Hilfsmethode: Prüft ob eine Superuser-Rolle ausgewählt ist
  bool get _isSuperuserRoleSelected {
    if (_selectedRoleIds.isEmpty) return false;
    final selectedRole = _availableRoles.firstWhere((role) => _selectedRoleIds.contains(role.id), orElse: () => Role(id: 0, name: '', displayName: '', description: '', isSystemRole: false, isActive: true, sortOrder: 0, createdBy: 0, createdAt: DateTime.now()));
    return selectedRole.name.toLowerCase().contains('super') || selectedRole.name.toLowerCase().contains('admin');
  }

  @override
  void initState() {
    super.initState();
    // EmailAuthController initialisieren (genau wie Client-App)
    _emailAuthController = EmailAuthController(widget.client.modules.auth);
    _loadAvailableRoles();
  }

  /// Lade verfügbare Rollen für die Auswahl
  Future<void> _loadAvailableRoles() async {
    try {
      final roles = await widget.client.permissionManagement.getAllRoles();
      setState(() {
        _availableRoles = roles;
      });
    } catch (e) {
      debugPrint('Error loading roles: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _superuserPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _showVerificationStep
                    ? 'E-Mail-Bestätigung'
                    : 'Neuen Staff-User erstellen',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              if (_showVerificationStep) ...[
                _buildVerificationStep(),
              ] else ...[
                _buildUserDataStep(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDataStep() {
    return Column(
      children: [
        // Basis-Informationen
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
        
        // E-Mail & Passwort
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'E-Mail-Adresse',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'E-Mail ist erforderlich';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
              return 'Ungültige E-Mail-Adresse';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passwort',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Passwort muss mindestens 8 Zeichen haben';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passwort bestätigen',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwörter stimmen nicht überein';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Rollen-Auswahl (Dropdown)
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
        const SizedBox(height: 16),

        // Superuser-Passwort (nur bei Superuser-Rollen)
        if (_isSuperuserRoleSelected) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Sicherheitsabfrage',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Für die Erstellung eines Superusers ist das aktuelle Superuser-Passwort erforderlich.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _superuserPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Aktuelles Superuser-Passwort',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (_isSuperuserRoleSelected && (value == null || value.isEmpty)) {
                      return 'Superuser-Passwort ist erforderlich';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Optionale Felder
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _employeeIdController,
                decoration: const InputDecoration(
                  labelText: 'Mitarbeiter-ID (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),

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

        const SizedBox(height: 24),
        
        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isLoading ? null : () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _startEmailVerification,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('E-Mail-Verifizierung starten'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      children: [
        const Icon(
          Icons.email,
          size: 48,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        
        Text(
          'Wir haben einen Bestätigungscode an',
          textAlign: TextAlign.center,
        ),
        Text(
          _emailController.text,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const Text(
          'gesendet.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          controller: _verificationCodeController,
          decoration: const InputDecoration(
            labelText: 'Bestätigungscode',
            border: OutlineInputBorder(),
            hintText: 'z.B. 12345678',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Code ist erforderlich';
            }
            return null;
          },
        ),

        if (_verificationError != null) ...[
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
                    _verificationError!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _isLoading ? null : () {
                setState(() {
                  _showVerificationStep = false;
                  _verificationError = null;
                });
              },
              child: const Text('← Zurück'),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _resendVerificationCode,
                  child: const Text('Code erneut senden'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _completeStaffCreation,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Bestätigen'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// **E-Mail-Verifizierung starten (Serverpod-Standard)**
  void _startEmailVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Staff-Metadaten speichern für spätere Verknüpfung
      final request = CreateStaffUserWithEmailRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text, // For Serverpod auth
        employeeId: _employeeIdController.text.trim().isEmpty ? null : _employeeIdController.text.trim(),
        staffLevel: _isSuperuserRoleSelected ? StaffUserType.superUser : StaffUserType.staff,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        hallId: null,
        facilityId: null,
        departmentId: null,
        contractType: null,
        hourlyRate: null,
        monthlySalary: null,
        workingHours: null,
        roleIds: _selectedRoleIds.isNotEmpty ? _selectedRoleIds : null,
        superuserPasswordConfirmation: _isSuperuserRoleSelected ? _superuserPasswordController.text.trim() : null,
      );

      final metadataStored = await widget.client.unifiedAuth.storeStaffMetadata(request);

      if (!metadataStored) {
        throw Exception('Fehler beim Speichern der Staff-Daten');
      }

      // 2. Standard Serverpod Email-Verifizierung starten (genau wie Client-App)
      final userName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final accountCreated = await _emailAuthController.createAccountRequest(
        userName,
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!accountCreated) {
        throw Exception('E-Mail-Verifizierung konnte nicht gestartet werden');
      }

      // 3. Zur Verifizierung wechseln
      setState(() {
        _showVerificationStep = true;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// **E-Mail-Verifizierung abschließen (Serverpod-Standard)**
  void _completeStaffCreation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _verificationError = null;
    });

    try {
      // 1. Standard Serverpod E-Mail-Validierung (genau wie Client-App)
      final userInfo = await _emailAuthController.validateAccount(
        _emailController.text.trim(),
        _verificationCodeController.text.trim(),
      );

      if (userInfo == null) {
        throw Exception('Ungültiger oder abgelaufener Code');
      }

      // 2. Staff-User mit verifiziertem Auth-User verknüpfen
      final staffUser = await widget.client.unifiedAuth.linkAuthUserToStaff(
        _emailController.text.trim(),
      );

      // 3. Erfolgsmeldung und Dialog schließen
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Staff-User "${staffUser.firstName} ${staffUser.lastName}" erfolgreich erstellt'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(staffUser);

    } catch (e) {
      setState(() {
        _verificationError = 'Fehler: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// **Verifizierungscode erneut senden**
  void _resendVerificationCode() async {
    setState(() {
      _isLoading = true;
      _verificationError = null;
    });

    try {
      // Standard Serverpod Resend-Methode verwenden
      final userName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final success = await _emailAuthController.createAccountRequest(
        userName,
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Neuer Bestätigungscode wurde gesendet'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _verificationError = 'Fehler beim Senden: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

}