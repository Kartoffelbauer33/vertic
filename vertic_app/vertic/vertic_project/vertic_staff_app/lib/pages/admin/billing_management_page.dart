import 'package:flutter/material.dart';

class BillingManagementPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(bool, String?)? onUnsavedChanges;

  const BillingManagementPage({
    super.key,
    this.onBack,
    this.onUnsavedChanges,
  });

  @override
  State<BillingManagementPage> createState() => _BillingManagementPageState();
}

class _BillingManagementPageState extends State<BillingManagementPage> {
  final List<Map<String, dynamic>> _billingConfigs = [];
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom AppBar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    'Abrechnungsmanagement',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header mit Erklärung
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Zentrale Abrechnungskonfiguration',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Legen Sie hier fest, wann Ihre Kunden für monatliche Abonnements abgerechnet werden. '
                                'Alle monatlichen Abos werden zum gleichen Tag abgerechnet - unabhängig vom Kaufdatum. '
                                'Jahrestickets werden automatisch zum Kaufzeitpunkt abgerechnet.',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              // Status-Indikatoren
                              Row(
                                children: [
                                  _buildStatusIndicator(
                                      'Monatlich', _getActiveConfig('monthly')),
                                  const SizedBox(width: 24),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.green, size: 16),
                                        const SizedBox(width: 4),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Jährlich',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12),
                                            ),
                                            Text(
                                              'Zum Kaufzeitpunkt',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Konfigurationsliste
                      Expanded(
                        child: ListView.builder(
                          itemCount: _billingConfigs.length,
                          itemBuilder: (context, index) {
                            final config = _billingConfigs[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: config['isActive'] == true
                                      ? Colors.green
                                      : Colors.grey[400],
                                  child: Icon(
                                    _getConfigIcon(config['billingType'] ?? ''),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  config['name'] ?? '',
                                  style: TextStyle(
                                    fontWeight: config['isActive'] == true
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(config['description'] ?? ''),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          config['isActive'] == true
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          size: 16,
                                          color: config['isActive'] == true
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          config['isActive'] == true
                                              ? 'Aktiv'
                                              : 'Inaktiv',
                                          style: TextStyle(
                                            color: config['isActive'] == true
                                                ? Colors.green
                                                : Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    if (config['isActive'] != true)
                                      const PopupMenuItem(
                                        value: 'activate',
                                        child: ListTile(
                                          leading: Icon(Icons.play_circle,
                                              color: Colors.green),
                                          title: Text('Aktivieren'),
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit),
                                        title: Text('Bearbeiten'),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete,
                                            color: Colors.red),
                                        title: Text('Löschen'),
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'activate') {
                                      _activateConfig(config);
                                    } else if (value == 'edit') {
                                      _showEditConfigDialog(config);
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmation(config);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        // Floating Action Button als Fixed Button
        Container(
          decoration: const BoxDecoration(),
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddConfigDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Neue Konfiguration'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String type, Map<String, dynamic>? config) {
    final isConfigured = config != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isConfigured ? Icons.check_circle : Icons.warning,
          color: isConfigured ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            Text(
              isConfigured ? _getBillingDayText(config) : 'Nicht konfiguriert',
              style: TextStyle(
                fontSize: 10,
                color: isConfigured ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getBillingDayText(Map<String, dynamic> config) {
    if (config['billingType'] == 'monthly') {
      return 'Am ${config['billingDay']}.';
    } else if (config['billingType'] == 'yearly') {
      return 'Am 1. Januar';
    }
    return 'Konfiguriert';
  }

  Map<String, dynamic>? _getActiveConfig(String type) {
    try {
      return _billingConfigs.firstWhere(
        (c) => c['billingType'] == type && c['isActive'] == true,
      );
    } catch (e) {
      return null;
    }
  }

  IconData _getConfigIcon(String billingType) {
    switch (billingType) {
      case 'monthly':
        return Icons.calendar_month;
      case 'yearly':
        return Icons.calendar_today;
      default:
        return Icons.schedule;
    }
  }

  void _activateConfig(Map<String, dynamic> config) {
    setState(() {
      // Deaktiviere andere Konfigurationen des gleichen Typs
      for (var c in _billingConfigs) {
        if (c['billingType'] == config['billingType']) {
          c['isActive'] = false;
        }
      }
      // Aktiviere die gewählte Konfiguration
      config['isActive'] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${config['name']} wurde aktiviert'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditBillingConfigDialog(
        onSaved: (newConfig) {
          setState(() {
            newConfig['id'] = _billingConfigs.length + 1;
            _billingConfigs.add(newConfig);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${newConfig['name']} erfolgreich erstellt')),
          );
        },
      ),
    );
  }

  void _showEditConfigDialog(Map<String, dynamic> config) {
    showDialog(
      context: context,
      builder: (context) => AddEditBillingConfigDialog(
        config: config,
        onSaved: (updatedConfig) {
          setState(() {
            final index = _billingConfigs
                .indexWhere((c) => c['id'] == updatedConfig['id']);
            if (index != -1) {
              _billingConfigs[index] = updatedConfig;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${updatedConfig['name']} erfolgreich aktualisiert')),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfiguration löschen'),
        content: Text('Möchten Sie "${config['name']}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _billingConfigs.removeWhere((c) => c['id'] == config['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${config['name']} wurde gelöscht')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

// Dialog für Erstellen/Bearbeiten von Abrechnungskonfigurationen
class AddEditBillingConfigDialog extends StatefulWidget {
  final Map<String, dynamic>? config;
  final Function(Map<String, dynamic>) onSaved;

  const AddEditBillingConfigDialog({
    super.key,
    this.config,
    required this.onSaved,
  });

  @override
  State<AddEditBillingConfigDialog> createState() =>
      _AddEditBillingConfigDialogState();
}

class _AddEditBillingConfigDialogState
    extends State<AddEditBillingConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _billingDayController = TextEditingController();

  String _billingType = 'monthly';
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.config != null) {
      _initializeWithExisting();
    }
  }

  void _initializeWithExisting() {
    final config = widget.config!;
    _nameController.text = config['name'] ?? '';
    _descriptionController.text = config['description'] ?? '';
    _billingType = config['billingType'] ?? 'monthly';
    _billingDayController.text = (config['billingDay'] ?? 1).toString();
    _isActive = config['isActive'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _billingDayController.dispose();
    super.dispose();
  }

  void _saveConfig() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final config = <String, dynamic>{
      if (widget.config != null) 'id': widget.config!['id'],
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'billingType': _billingType,
      'billingDay': int.parse(_billingDayController.text),
      'isActive': _isActive,
    };

    widget.onSaved(config);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.config == null
                  ? 'Neue Abrechnungskonfiguration'
                  : 'Konfiguration bearbeiten',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                      hintText: 'z.B. Monatlich am 1.',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name ist erforderlich';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Beschreibung
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Beschreibung',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Abrechnungstyp
                  DropdownButtonFormField<String>(
                    value: _billingType,
                    decoration: const InputDecoration(
                      labelText: 'Abrechnungstyp',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Monatlich'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _billingType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Abrechnungstag
                  TextFormField(
                    controller: _billingDayController,
                    decoration: const InputDecoration(
                      labelText: 'Tag im Monat (1-31)',
                      border: OutlineInputBorder(),
                      hintText: 'z.B. 1, 15, 31',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Abrechnungstag erforderlich';
                      }
                      final day = int.tryParse(value);
                      if (day == null) {
                        return 'Muss eine Zahl sein';
                      }
                      if (day < 1 || day > 31) {
                        return 'Muss zwischen 1 und 31 sein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Aktiv-Checkbox
                  CheckboxListTile(
                    title: const Text('Als aktive Konfiguration setzen'),
                    subtitle: const Text(
                      'Alle anderen monatlichen Konfigurationen werden deaktiviert',
                    ),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    widget.config == null ? 'Erstellen' : 'Speichern',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
