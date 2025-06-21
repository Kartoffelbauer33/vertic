import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';

class VerticTicketManagementPage extends StatefulWidget {
  const VerticTicketManagementPage({super.key});

  @override
  State<VerticTicketManagementPage> createState() =>
      _VerticTicketManagementPageState();
}

class _VerticTicketManagementPageState
    extends State<VerticTicketManagementPage> {
  List<TicketType> _verticTickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVerticTickets();
  }

  Future<void> _loadVerticTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Lade alle Ticket-Typen und filtere die "universellen" heraus
      final allTypes = await client.ticketType.getAllTicketTypes();

      // TODO: Hier würden wir nach einem "isUniversal" oder "isVerticTicket" Feld filtern
      // Vorerst nehmen wir die drei Hauptkategorien für Vertic
      final verticTypes = allTypes.where((type) {
        // Einzeltickets, Monatsabos, Jahreskarten
        return (!type.isPointBased && !type.isSubscription) || // Einzeltickets
            (type.isSubscription && type.billingInterval == -1) || // Monatsabos
            (type.isSubscription &&
                type.billingInterval == -12); // Jahreskarten
      }).toList();

      setState(() {
        _verticTickets = verticTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Vertic-Tickets: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vertic Tickets'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateVerticTicketDialog(),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Neues Vertic Ticket'),
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
                        onPressed: _loadVerticTickets,
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Info-Header
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade600, Colors.teal.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified,
                                  color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'Vertic Universal-Tickets',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Diese Tickets gelten in allen Vertic-Hallen und werden in der Client-App prominent angezeigt.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Tickets-Liste
                    Expanded(
                      child: _verticTickets.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Keine Vertic-Tickets vorhanden',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Erstelle dein erstes Universal-Ticket',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadVerticTickets,
                              child: _buildCategorizedTicketList(),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildVerticTicketCard(TicketType ticket) {
    // Bestimme Typ und Farbe
    String ticketTypeText;
    Color typeColor;
    IconData typeIcon;

    if (ticket.isSubscription && ticket.billingInterval == -1) {
      ticketTypeText = 'Monatsabo';
      typeColor = Colors.orange;
      typeIcon = Icons.calendar_month;
    } else if (ticket.isSubscription && ticket.billingInterval == -12) {
      ticketTypeText = 'Jahreskarte';
      typeColor = Colors.purple;
      typeIcon = Icons.card_membership;
    } else {
      ticketTypeText = 'Einzelticket';
      typeColor = Colors.blue;
      typeIcon = Icons.confirmation_number;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Typ-Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),

                // Ticket-Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ticket.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ticketTypeText,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (ticket.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ticket.description,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.euro,
                              size: 16, color: Colors.green.shade600),
                          Text(
                            ' ${ticket.defaultPrice.toStringAsFixed(2)} €',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (ticket.validityPeriod > 0) ...[
                            Icon(Icons.schedule,
                                size: 16, color: Colors.blue.shade600),
                            Text(
                              ' ${ticket.validityPeriod} Tage',
                              style: TextStyle(color: Colors.blue.shade600),
                            ),
                          ] else ...[
                            Icon(Icons.all_inclusive,
                                size: 16, color: Colors.blue.shade600),
                            Text(
                              ' Unbegrenzt',
                              style: TextStyle(color: Colors.blue.shade600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Aktionen
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditVerticTicketDialog(ticket);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(ticket);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Bearbeiten'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Löschen'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateVerticTicketDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateVerticTicketDialog(
        onSaved: (ticketType) {
          setState(() {
            _verticTickets.add(ticketType);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${ticketType.name} erfolgreich erstellt')),
          );
        },
      ),
    );
  }

  void _showEditVerticTicketDialog(TicketType ticket) {
    showDialog(
      context: context,
      builder: (context) => CreateVerticTicketDialog(
        ticketType: ticket,
        onSaved: (updatedTicket) {
          setState(() {
            final index =
                _verticTickets.indexWhere((t) => t.id == updatedTicket.id);
            if (index != -1) {
              _verticTickets[index] = updatedTicket;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${updatedTicket.name} erfolgreich aktualisiert')),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(TicketType ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vertic-Ticket löschen'),
        content: Text(
            'Möchten Sie "${ticket.name}" wirklich löschen?\n\nDieses Ticket wird nicht mehr in der Client-App angezeigt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteVerticTicket(ticket);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVerticTicket(TicketType ticket) async {
    try {
      final success = await client.ticketType.deleteTicketType(ticket.id!);
      if (success) {
        setState(() {
          _verticTickets.removeWhere((t) => t.id == ticket.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ticket.name} erfolgreich gelöscht')),
        );
      } else {
        throw Exception('Löschen fehlgeschlagen');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCategorizedTicketList() {
    // Kategorisiere Tickets
    final einzeltickets = _verticTickets
        .where((t) => !t.isSubscription && !t.isPointBased)
        .toList();
    final punktekarten = _verticTickets.where((t) => t.isPointBased).toList();
    final abonnements = _verticTickets.where((t) => t.isSubscription).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Einzeltickets Sektion
        if (einzeltickets.isNotEmpty) ...[
          _buildCategoryHeader(
              'Einzeltickets', Icons.confirmation_number, Colors.blue),
          ...einzeltickets.map((ticket) => _buildVerticTicketCard(ticket)),
          const SizedBox(height: 16),
        ],

        // Punktekarten Sektion
        if (punktekarten.isNotEmpty) ...[
          _buildCategoryHeader('Punktekarten', Icons.stars, Colors.orange),
          ...punktekarten.map((ticket) => _buildVerticTicketCard(ticket)),
          const SizedBox(height: 16),
        ],

        // Abonnements Sektion
        if (abonnements.isNotEmpty) ...[
          _buildCategoryHeader(
              'Abonnements', Icons.card_membership, Colors.purple),
          ...abonnements.map((ticket) => _buildVerticTicketCard(ticket)),
        ],

        // Wenn keine Tickets vorhanden, zeige Platzhalter für Kategorien
        if (_verticTickets.isEmpty) ...[
          _buildCategoryHeader(
              'Einzeltickets', Icons.confirmation_number, Colors.blue),
          _buildEmptyPlaceholder('Keine Einzeltickets vorhanden'),
          const SizedBox(height: 16),
          _buildCategoryHeader('Punktekarten', Icons.stars, Colors.orange),
          _buildEmptyPlaceholder('Keine Punktekarten vorhanden'),
          const SizedBox(height: 16),
          _buildCategoryHeader(
              'Abonnements', Icons.card_membership, Colors.purple),
          _buildEmptyPlaceholder('Keine Abonnements vorhanden'),
        ],
      ],
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ),
    );
  }
}

// Dialog für Erstellen/Bearbeiten von Vertic-Tickets
class CreateVerticTicketDialog extends StatefulWidget {
  final TicketType? ticketType;
  final Function(TicketType) onSaved;

  const CreateVerticTicketDialog({
    super.key,
    this.ticketType,
    required this.onSaved,
  });

  @override
  State<CreateVerticTicketDialog> createState() =>
      _CreateVerticTicketDialogState();
}

class _CreateVerticTicketDialogState extends State<CreateVerticTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _validityPeriodController = TextEditingController();
  final _pointsController = TextEditingController();
  final _customDaysController = TextEditingController();

  final _validityFocusNode = FocusNode();

  String _selectedCategory = 'Einzeltickets'; // NEU: Kategorieauswahl
  bool _isPointBased = false;
  bool _isSubscription = false;
  String _billingMode = 'monthly'; // 'monthly', 'yearly', 'custom'
  bool _isLoading = false;

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

    // Standard-Gültigkeit für Einzeltickets ist 1 Tag
    _validityPeriodController.text = '1';

    _validityFocusNode.addListener(() {
      if (_validityFocusNode.hasFocus &&
          _validityPeriodController.text == '∞') {
        _validityPeriodController.clear();
      } else if (!_validityFocusNode.hasFocus &&
          _validityPeriodController.text.isEmpty) {
        // Für Einzeltickets: 1 Tag, für andere: ∞
        _validityPeriodController.text =
            (!_isSubscription && !_isPointBased) ? '1' : '∞';
      }
    });

    if (widget.ticketType != null) {
      _initializeWithExistingTicket();
    }
  }

  void _initializeWithExistingTicket() {
    final ticket = widget.ticketType!;
    _nameController.text = ticket.name;
    _descriptionController.text = ticket.description;
    _priceController.text = ticket.defaultPrice.toString();
    _validityPeriodController.text =
        ticket.validityPeriod == 0 ? '∞' : ticket.validityPeriod.toString();

    _isPointBased = ticket.isPointBased;
    _isSubscription = ticket.isSubscription;

    // Kategorie bestimmen
    if (ticket.isPointBased) {
      _selectedCategory = 'Punktekarten';
    } else if (ticket.isSubscription) {
      _selectedCategory = 'Zeitkarten';
    } else {
      _selectedCategory = 'Einzeltickets';
    }

    if (ticket.isPointBased && ticket.defaultPoints != null) {
      _pointsController.text = ticket.defaultPoints.toString();
    }

    // Billing-Modus bestimmen
    if (_isSubscription) {
      switch (ticket.billingInterval) {
        case -1:
          _billingMode = 'monthly';
          break;
        case -12:
          _billingMode = 'yearly';
          break;
        default:
          _billingMode = 'custom';
          if (ticket.billingInterval != null) {
            _customDaysController.text = ticket.billingInterval.toString();
          }
      }
    }
  }

  void _updateBasedOnCategory() {
    setState(() {
      switch (_selectedCategory) {
        case 'Einzeltickets':
          _isPointBased = false;
          _isSubscription = false;
          _validityPeriodController.text = '1';
          break;
        case 'Punktekarten':
          _isPointBased = true;
          _isSubscription = false;
          _validityPeriodController.text = '∞';
          break;
        case 'Zeitkarten':
          _isPointBased = false;
          _isSubscription = true;
          _validityPeriodController.text = '∞';
          break;
      }
    });
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

  Future<void> _saveVerticTicket() async {
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
        description: _descriptionController.text.trim(),
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

      // Backend-Call
      TicketType? savedTicket;
      if (widget.ticketType == null) {
        savedTicket = await client.ticketType.createTicketType(ticketType);
      } else {
        savedTicket = await client.ticketType.updateTicketType(ticketType);
      }

      if (savedTicket != null) {
        widget.onSaved(savedTicket);
        Navigator.of(context).pop();
      } else {
        throw Exception('Fehler beim Speichern des Vertic-Tickets');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Colors.red,
        ),
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
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticketType == null
                  ? 'Neues Vertic-Ticket erstellen'
                  : 'Vertic-Ticket bearbeiten',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategorie-Auswahl (NEU)
                      Text(
                        'Ticket-Kategorie *',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Wählen Sie eine Kategorie',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Einzeltickets',
                            child: Row(
                              children: [
                                Icon(Icons.confirmation_number,
                                    color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Einzeltickets'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Punktekarten',
                            child: Row(
                              children: [
                                Icon(Icons.stars, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Punktekarten'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Zeitkarten',
                            child: Row(
                              children: [
                                Icon(Icons.card_membership,
                                    color: Colors.purple),
                                SizedBox(width: 8),
                                Text('Zeitkarten (Abonnements)'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _selectedCategory = value;
                            _updateBasedOnCategory();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kategorie ist erforderlich';
                          }
                          return null;
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
                                labelText: 'Preis (€) *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Preis erforderlich';
                                }
                                if (_parseEuropeanDouble(value) == null) {
                                  return 'Ungültiger Preis';
                                }
                                return null;
                              },
                            ),
                          ),
                          // Gültigkeit nur für Einzeltickets und Punktekarten anzeigen
                          if (_selectedCategory != 'Zeitkarten') ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _validityPeriodController,
                                focusNode: _validityFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Gültigkeit (Tage)',
                                  border: OutlineInputBorder(),
                                  hintText: '1 = 1 Tag, ∞ = unendlich',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value == '∞') {
                                    return null;
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Ungültige Anzahl';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Kategorie-spezifische Felder
                      if (_selectedCategory == 'Punktekarten') ...[
                        Text(
                          'Punktekarten-Einstellungen',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pointsController,
                          decoration: const InputDecoration(
                            labelText: 'Anzahl Punkte *',
                            border: OutlineInputBorder(),
                            hintText: 'z.B. 10 für 10 Eintritte',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_selectedCategory == 'Punktekarten') {
                              if (value == null || value.isEmpty) {
                                return 'Punkte sind erforderlich';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Ungültige Anzahl';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_selectedCategory == 'Zeitkarten') ...[
                        Text(
                          'Abrechnungsintervall',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: [
                            RadioListTile<String>(
                              title: const Text('Monatlich'),
                              subtitle: const Text('Jeden Monat abrechnen'),
                              value: 'monthly',
                              groupValue: _billingMode,
                              onChanged: (value) =>
                                  setState(() => _billingMode = value!),
                            ),
                            RadioListTile<String>(
                              title: const Text('Jährlich'),
                              subtitle: const Text('Einmal pro Jahr abrechnen'),
                              value: 'yearly',
                              groupValue: _billingMode,
                              onChanged: (value) =>
                                  setState(() => _billingMode = value!),
                            ),
                            RadioListTile<String>(
                              title: const Text('Benutzerdefiniert'),
                              subtitle:
                                  const Text('Eigenes Intervall in Tagen'),
                              value: 'custom',
                              groupValue: _billingMode,
                              onChanged: (value) =>
                                  setState(() => _billingMode = value!),
                            ),
                          ],
                        ),

                        // Custom Days Input
                        if (_billingMode == 'custom') ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _customDaysController,
                            decoration: const InputDecoration(
                              labelText: 'Abrechnungsintervall (Tage) *',
                              border: OutlineInputBorder(),
                              hintText: 'z.B. 30 für alle 30 Tage',
                            ),
                            keyboardType: TextInputType.number,
                            validator: _billingMode == 'custom'
                                ? (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Intervall erforderlich';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Ungültige Anzahl';
                                    }
                                    return null;
                                  }
                                : null,
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // Info-Hinweise
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hinweise für $_selectedCategory:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getHintText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  onPressed: _isLoading ? null : _saveVerticTicket,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
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

  String _getHintText() {
    switch (_selectedCategory) {
      case 'Einzeltickets':
        return '• Einzeltickets: 1 Tag gültig, unendlich einlösbar';
      case 'Punktekarten':
        return '• Punktekarten: Unbegrenzt gültig, verbraucht Punkte';
      case 'Zeitkarten':
        return '• Abonnements: Automatische Verlängerung\n• Diese Tickets gelten in allen Vertic-Hallen';
      default:
        return '';
    }
  }
}
