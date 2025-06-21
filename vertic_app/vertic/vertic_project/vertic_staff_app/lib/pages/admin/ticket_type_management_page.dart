import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';

class TicketTypeManagementPage extends StatefulWidget {
  const TicketTypeManagementPage({super.key});

  @override
  State<TicketTypeManagementPage> createState() =>
      _TicketTypeManagementPageState();
}

class _TicketTypeManagementPageState extends State<TicketTypeManagementPage> {
  List<TicketType> _ticketTypes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTicketTypes();
  }

  Future<void> _loadTicketTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final types = await client.ticketType.getAllTicketTypes();
      setState(() {
        _ticketTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Ticket-Typen: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTicketType(TicketType ticketType) async {
    try {
      final success = await client.ticketType.deleteTicketType(ticketType.id!);
      if (success) {
        setState(() {
          _ticketTypes.removeWhere((t) => t.id == ticketType.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ticketType.name} erfolgreich gelöscht')),
        );
      } else {
        throw Exception('Löschen fehlgeschlagen');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Fehler beim Löschen: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket-Typen verwalten'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTicketTypeDialog(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Neuer Typ'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTicketTypes,
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTicketTypes,
                  child: _ticketTypes.isEmpty
                      ? const Center(
                          child: Text('Keine Ticket-Typen vorhanden'),
                        )
                      : ListView.builder(
                          itemCount: _ticketTypes.length,
                          itemBuilder: (context, index) {
                            final ticketType = _ticketTypes[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getTypeColor(ticketType),
                                  child: Icon(
                                    _getTypeIcon(ticketType),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  ticketType.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (ticketType.description.isNotEmpty)
                                      Text(ticketType.description),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Preis: ${ticketType.defaultPrice.toStringAsFixed(2)} €',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
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
                                    if (value == 'edit') {
                                      _showEditTicketTypeDialog(ticketType);
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmation(ticketType);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  Color _getTypeColor(TicketType ticketType) {
    if (ticketType.isPointBased) return Colors.orange;
    if (ticketType.isSubscription) return Colors.purple;
    return Colors.blue;
  }

  IconData _getTypeIcon(TicketType ticketType) {
    if (ticketType.isPointBased) return Icons.stars;
    if (ticketType.isSubscription) return Icons.card_membership;
    return Icons.confirmation_number;
  }

  void _showAddTicketTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditTicketTypeDialog(
        onSaved: (ticketType) {
          setState(() {
            _ticketTypes.add(ticketType);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${ticketType.name} erfolgreich erstellt')),
          );
        },
      ),
    );
  }

  void _showEditTicketTypeDialog(TicketType ticketType) {
    showDialog(
      context: context,
      builder: (context) => AddEditTicketTypeDialog(
        ticketType: ticketType,
        onSaved: (updatedTicketType) {
          setState(() {
            final index =
                _ticketTypes.indexWhere((t) => t.id == updatedTicketType.id);
            if (index != -1) {
              _ticketTypes[index] = updatedTicketType;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${updatedTicketType.name} erfolgreich aktualisiert')),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(TicketType ticketType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ticket-Typ löschen'),
        content: Text('Möchten Sie "${ticketType.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTicketType(ticketType);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

// Dialog für Erstellen/Bearbeiten von Ticket-Typen
class AddEditTicketTypeDialog extends StatefulWidget {
  final TicketType? ticketType;
  final Function(TicketType) onSaved;

  const AddEditTicketTypeDialog({
    super.key,
    this.ticketType,
    required this.onSaved,
  });

  @override
  State<AddEditTicketTypeDialog> createState() =>
      _AddEditTicketTypeDialogState();
}

class _AddEditTicketTypeDialogState extends State<AddEditTicketTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _validityPeriodController = TextEditingController();
  final _pointsController = TextEditingController();
  final _customDaysController = TextEditingController();

  final _validityFocusNode = FocusNode();

  // Kategorien für Ticket-Typen
  final List<String> _categories = [
    'Einzeltickets',
    'Zeitkarten',
    'Punktekarten',
    'Sonderangebote',
    'Gruppentickets',
  ];

  String _selectedCategory = 'Einzeltickets';
  bool _isPointBased = false;
  bool _isSubscription = false;
  bool _isLoading = false;

  // Abrechnungsintervall-System
  String _billingMode = 'monthly'; // 'monthly', 'yearly', 'custom'

  // Hilfsfunktion für europäische Dezimalzeichen
  String _normalizeDecimal(String input) {
    return input.replaceAll(',', '.');
  }

  double? _parseEuropeanDouble(String input) {
    if (input.isEmpty) return null;
    final normalized = _normalizeDecimal(input);
    return double.tryParse(normalized);
  }

  @override
  void initState() {
    super.initState();
    // Standardmäßig Unendlich-Symbol setzen
    _validityPeriodController.text = '∞';

    _validityFocusNode.addListener(() {
      if (_validityFocusNode.hasFocus &&
          _validityPeriodController.text == '∞') {
        _validityPeriodController.clear();
      } else if (!_validityFocusNode.hasFocus &&
          _validityPeriodController.text.isEmpty) {
        _validityPeriodController.text = '∞';
      }
    });

    if (widget.ticketType != null) {
      _initializeWithExistingType();
    }
  }

  void _initializeWithExistingType() {
    final type = widget.ticketType!;
    _nameController.text = type.name;
    _descriptionController.text = type.description;
    _priceController.text = type.defaultPrice.toString();
    _validityPeriodController.text =
        type.validityPeriod == 0 ? '∞' : type.validityPeriod.toString();
    _isPointBased = type.isPointBased;
    _isSubscription = type.isSubscription;

    if (type.defaultPoints != null) {
      _pointsController.text = type.defaultPoints.toString();
    }

    // Abrechnungsintervall analysieren
    if (type.billingInterval != null) {
      switch (type.billingInterval) {
        case -1: // Monatlich
          _billingMode = 'monthly';
          break;
        case -12: // Jährlich
          _billingMode = 'yearly';
          break;
        default: // Benutzerdefiniert (Tage)
          _billingMode = 'custom';
          _customDaysController.text = type.billingInterval.toString();
      }
    }

    // Kategorie basierend auf Eigenschaften bestimmen
    if (type.isPointBased) {
      _selectedCategory = 'Punktekarten';
    } else if (type.isSubscription) {
      _selectedCategory = 'Zeitkarten';
    } else if (type.name.toLowerCase().contains('gruppe') ||
        type.name.toLowerCase().contains('familie')) {
      _selectedCategory = 'Gruppentickets';
    } else {
      _selectedCategory = 'Einzeltickets';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _validityPeriodController.dispose();
    _pointsController.dispose();
    _customDaysController.dispose();
    _validityFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTicketType() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now().toUtc();

      // Abrechnungsintervall bestimmen
      int? billingInterval;
      if (_isSubscription) {
        switch (_billingMode) {
          case 'monthly':
            billingInterval = -1; // Spezialwert für monatlich
            break;
          case 'yearly':
            billingInterval = -12; // Spezialwert für jährlich
            break;
          case 'custom':
            billingInterval = int.tryParse(_customDaysController.text);
            break;
        }
      }

      final ticketType = TicketType(
        id: widget.ticketType?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? ''
            : _descriptionController.text.trim(),
        validityPeriod: _validityPeriodController.text.isEmpty ||
                _validityPeriodController.text == '∞'
            ? 0
            : int.parse(_validityPeriodController.text),
        defaultPrice: _parseEuropeanDouble(_priceController.text)!,
        isPointBased: _isPointBased,
        defaultPoints:
            _isPointBased ? int.tryParse(_pointsController.text) : null,
        isSubscription: _isSubscription,
        billingInterval: billingInterval,
        createdAt: widget.ticketType?.createdAt ?? now,
        updatedAt: now,
      );

      // Backend-Calls für Save/Update
      TicketType? savedTicketType;
      if (widget.ticketType == null) {
        savedTicketType = await client.ticketType.createTicketType(ticketType);
      } else {
        savedTicketType = await client.ticketType.updateTicketType(ticketType);
      }

      if (savedTicketType != null) {
        widget.onSaved(savedTicketType);
        Navigator.of(context).pop();
      } else {
        throw Exception('Fehler beim Speichern des Ticket-Typs');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticketType == null
                  ? 'Neuen Ticket-Typ erstellen'
                  : 'Ticket-Typ bearbeiten',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategorie-Auswahl
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategorie',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                            // Automatische Einstellungen basierend auf Kategorie
                            _updateSettingsBasedOnCategory();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          border: OutlineInputBorder(),
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

                      // Preis und Gültigkeit
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Standardpreis (€) *',
                                border: OutlineInputBorder(),
                                hintText: 'z.B. 14,50 oder 14.50',
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Preis erforderlich';
                                }
                                if (_parseEuropeanDouble(value) == null) {
                                  return 'Ungültiger Preis (nutzen Sie . oder ,)';
                                }
                                final price = _parseEuropeanDouble(value)!;
                                if (price < 0) {
                                  return 'Preis muss positiv sein';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _validityPeriodController,
                              focusNode: _validityFocusNode,
                              decoration: const InputDecoration(
                                labelText: 'Gültigkeit (Tage)',
                                border: OutlineInputBorder(),
                                hintText: '∞ = unendlich gültig',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value == '∞') {
                                  return null; // ∞ oder leer ist gültig (= unendlich)
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Ungültige Anzahl';
                                }
                                final days = int.parse(value);
                                if (days < 0) {
                                  return 'Muss positiv oder ∞ sein';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      // Checkboxes für Ticket-Eigenschaften - nur bei relevanten Kategorien anzeigen
                      if (_selectedCategory == 'Sonderangebote' ||
                          _selectedCategory == 'Gruppentickets') ...[
                        CheckboxListTile(
                          title: const Text('Punktebasiert'),
                          subtitle: const Text(
                              'Ticket hat eine bestimmte Anzahl von Punkten'),
                          value: _isPointBased,
                          onChanged: (value) {
                            setState(() {
                              _isPointBased = value ?? false;
                              if (_isPointBased) _isSubscription = false;
                            });
                          },
                        ),
                        CheckboxListTile(
                          title: const Text('Abonnement/Zeitkarte'),
                          subtitle: const Text('Wiederkehrende Zahlungen'),
                          value: _isSubscription,
                          onChanged: (value) {
                            setState(() {
                              _isSubscription = value ?? false;
                              if (_isSubscription) _isPointBased = false;
                            });
                          },
                        ),
                      ],

                      // Punktefeld nur bei Punktekarten anzeigen
                      if (_selectedCategory == 'Punktekarten' ||
                          _isPointBased) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pointsController,
                          decoration: const InputDecoration(
                            labelText: 'Anzahl Punkte *',
                            border: OutlineInputBorder(),
                            hintText: 'z.B. 10, 20, 50',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if ((_selectedCategory == 'Punktekarten' ||
                                    _isPointBased) &&
                                (value == null || value.isEmpty)) {
                              return 'Anzahl Punkte erforderlich';
                            }
                            if (value != null && value.isNotEmpty) {
                              final points = int.tryParse(value);
                              if (points == null || points <= 0) {
                                return 'Muss eine positive Zahl sein';
                              }
                            }
                            return null;
                          },
                        ),
                      ],

                      // Abrechnungsintervall nur bei Zeitkarten oder manuell aktivierten Abonnements anzeigen
                      if (_selectedCategory == 'Zeitkarten' ||
                          _isSubscription) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Abrechnungsintervall',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),

                        // Monatlich
                        RadioListTile<String>(
                          title: const Text('Monatlich'),
                          subtitle: const Text(
                              'Jeden Monat am gleichen Tag (12x/Jahr)'),
                          value: 'monthly',
                          groupValue: _billingMode,
                          onChanged: (value) {
                            setState(() {
                              _billingMode = value!;
                            });
                          },
                        ),

                        // Jährlich
                        RadioListTile<String>(
                          title: const Text('Jährlich'),
                          subtitle: const Text('Einmal pro Jahr'),
                          value: 'yearly',
                          groupValue: _billingMode,
                          onChanged: (value) {
                            setState(() {
                              _billingMode = value!;
                            });
                          },
                        ),

                        // Benutzerdefiniert
                        RadioListTile<String>(
                          title: const Text('Benutzerdefiniert (Tage)'),
                          subtitle: const Text('Individuelle Anzahl Tage'),
                          value: 'custom',
                          groupValue: _billingMode,
                          onChanged: (value) {
                            setState(() {
                              _billingMode = value!;
                            });
                          },
                        ),

                        // Textfeld nur bei benutzerdefiniert
                        if (_billingMode == 'custom') ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 32, right: 16),
                            child: TextFormField(
                              controller: _customDaysController,
                              decoration: const InputDecoration(
                                labelText: 'Abrechnungsintervall (Tage)',
                                border: OutlineInputBorder(),
                                hintText: 'z.B. 30, 60, 90',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_billingMode == 'custom' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Anzahl Tage erforderlich';
                                }
                                if (_billingMode == 'custom' &&
                                    value != null &&
                                    value.isNotEmpty) {
                                  final days = int.tryParse(value);
                                  if (days == null || days <= 0) {
                                    return 'Muss eine positive Zahl sein';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
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
                  onPressed: _isLoading ? null : _saveTicketType,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.ticketType == null ? 'Erstellen' : 'Speichern',
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

  void _updateSettingsBasedOnCategory() {
    switch (_selectedCategory) {
      case 'Punktekarten':
        _isPointBased = true;
        _isSubscription = false;
        break;
      case 'Zeitkarten':
        _isSubscription = true;
        _isPointBased = false;
        break;
      default:
        _isPointBased = false;
        _isSubscription = false;
        break;
    }
  }
}
