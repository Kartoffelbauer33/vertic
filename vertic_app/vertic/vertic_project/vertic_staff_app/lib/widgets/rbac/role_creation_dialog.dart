import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/rbac/role_state_provider.dart';

/// **Role Creation Dialog**
/// 
/// Sauberes, ausgelagertes Widget für die Erstellung neuer Rollen.
/// Verwendet das Design System und validiert alle Eingaben.
class RoleCreationDialog extends StatefulWidget {
  const RoleCreationDialog({super.key});

  @override
  State<RoleCreationDialog> createState() => _RoleCreationDialogState();
}

class _RoleCreationDialogState extends State<RoleCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController();
  final _iconNameController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');

  bool _autoGenerateName = true;
  bool _isCreating = false;

  // Vordefinierte Farben für schnelle Auswahl
  final List<Color> _predefinedColors = [
    Colors.indigo,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.cyan,
  ];

  // Vordefinierte Icons für schnelle Auswahl
  final List<IconData> _predefinedIcons = [
    Icons.person,
    Icons.admin_panel_settings,
    Icons.supervisor_account,
    Icons.business,
    Icons.support_agent,
    Icons.engineering,
    Icons.security,
    Icons.verified_user,
    Icons.badge,
    Icons.account_circle,
  ];

  Color? _selectedColor;
  IconData? _selectedIcon;

  @override
  void initState() {
    super.initState();
    
    // Auto-Generate Name basierend auf Display Name
    _displayNameController.addListener(() {
      if (_autoGenerateName) {
        final roleProvider = Provider.of<RoleStateProvider>(context, listen: false);
        _nameController.text = roleProvider.generateRoleName(_displayNameController.text);
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _iconNameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleStateProvider>(
      builder: (context, roleProvider, child) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Neue Rolle erstellen'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display Name (Pflichtfeld)
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Anzeige-Name *',
                        hintText: 'z.B. "Manager" oder "Kassier"',
                        prefixIcon: Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Anzeige-Name ist erforderlich';
                        }
                        if (value.length < 2) {
                          return 'Mindestens 2 Zeichen erforderlich';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Technischer Name
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            enabled: !_autoGenerateName,
                            decoration: const InputDecoration(
                              labelText: 'Technischer Name *',
                              hintText: 'z.B. "manager" oder "cashier"',
                              prefixIcon: Icon(Icons.code),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Technischer Name ist erforderlich';
                              }
                              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                                return 'Nur Buchstaben, Zahlen und Unterstriche erlaubt';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: _autoGenerateName,
                          onChanged: (value) {
                            setState(() {
                              _autoGenerateName = value ?? true;
                              if (_autoGenerateName) {
                                _nameController.text = roleProvider.generateRoleName(_displayNameController.text);
                              }
                            });
                          },
                        ),
                        const Text('Auto'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Beschreibung (optional)
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Beschreibung',
                        hintText: 'Kurze Beschreibung der Rolle...',
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Farb-Auswahl
                    const Text('Farbe (optional)', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _predefinedColors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                              _colorController.text = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: 'Hex-Farbe',
                        hintText: '#FF5722',
                        prefixIcon: Icon(Icons.palette),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
                            return 'Format: #RRGGBB (z.B. #FF5722)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Icon-Auswahl
                    const Text('Icon (optional)', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _predefinedIcons.map((icon) {
                        final isSelected = _selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = icon;
                              _iconNameController.text = _getIconName(icon);
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: isSelected ? Colors.indigo : Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: isSelected ? Colors.indigo.withValues(alpha: 0.1) : null,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? Colors.indigo : Colors.grey[600],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _iconNameController,
                      decoration: const InputDecoration(
                        labelText: 'Icon-Name',
                        hintText: 'person, admin_panel_settings, etc.',
                        prefixIcon: Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sortier-Reihenfolge
                    TextFormField(
                      controller: _sortOrderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sortier-Reihenfolge',
                        hintText: '0',
                        prefixIcon: Icon(Icons.sort),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'Muss eine Zahl sein';
                          }
                        }
                        return null;
                      },
                    ),

                    // Fehler-Anzeige
                    if (roleProvider.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                roleProvider.error!,
                                style: const TextStyle(color: Colors.red),
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
          ),
          actions: [
            TextButton(
              onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: _isCreating ? null : _createRole,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Erstellen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createRole() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final roleProvider = Provider.of<RoleStateProvider>(context, listen: false);
      
      final success = await roleProvider.createRole(
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        color: _colorController.text.trim().isEmpty 
            ? null 
            : _colorController.text.trim(),
        iconName: _iconNameController.text.trim().isEmpty 
            ? null 
            : _iconNameController.text.trim(),
        sortOrder: int.tryParse(_sortOrderController.text) ?? 0,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Rolle "${_displayNameController.text}" erfolgreich erstellt'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _createRole: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  String _getIconName(IconData icon) {
    // Mapping der häufigsten Icons zu ihren Namen
    final iconMap = {
      Icons.person: 'person',
      Icons.admin_panel_settings: 'admin_panel_settings',
      Icons.supervisor_account: 'supervisor_account',
      Icons.business: 'business',
      Icons.support_agent: 'support_agent',
      Icons.engineering: 'engineering',
      Icons.security: 'security',
      Icons.verified_user: 'verified_user',
      Icons.badge: 'badge',
      Icons.account_circle: 'account_circle',
    };
    
    return iconMap[icon] ?? 'person';
  }
}
