import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';

class PricingManagementPage extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isSuperUser;
  final int? hallId;
  final Function(bool, String?)? onUnsavedChanges;

  const PricingManagementPage({
    super.key,
    this.onBack,
    this.isSuperUser = false,
    this.hallId,
    this.onUnsavedChanges,
  });

  @override
  State<PricingManagementPage> createState() => _PricingManagementPageState();
}

class _PricingManagementPageState extends State<PricingManagementPage> {
  List<TicketType> _ticketTypes = [];
  List<UserStatusType> _statusTypes = [];
  final Map<String, double> _pricingMatrix = {}; // Key: "ticketTypeId_statusTypeId"
  bool _isLoading = true;
  String? _errorMessage;

  // Filter-Variablen
  String _selectedTicketFilter = 'Alle';
  String _selectedStatusFilter = 'Alle';
  String _selectedGymFilter = 'Alle'; // Neu für SuperUser
  List<TicketType> _filteredTicketTypes = [];
  List<UserStatusType> _filteredStatusTypes = [];

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
      final ticketTypes = await client.ticketType.getAllTicketTypes();
      final statusTypes = await client.userStatus.getAllStatusTypes();

      setState(() {
        _ticketTypes = ticketTypes;
        _statusTypes = statusTypes;
        _buildPricingMatrix();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Daten: $e';
        _isLoading = false;
      });
    }
  }

  void _buildPricingMatrix() {
    _pricingMatrix.clear();
    for (final ticketType in _ticketTypes) {
      for (final statusType in _statusTypes) {
        final key = '${ticketType.id}_${statusType.id}';
        // Berechne Preis basierend auf Ermäßigung
        double price = ticketType.defaultPrice;
        if (statusType.discountPercentage > 0) {
          // Prozentuale Ermäßigung
          price = price * (1 - statusType.discountPercentage / 100);
        } else if (statusType.fixedDiscountAmount != null &&
            statusType.fixedDiscountAmount! > 0) {
          // Fixer Rabatt in Euro
          price = price - statusType.fixedDiscountAmount!;
          if (price < 0) price = 0; // Mindestpreis 0€
        }
        _pricingMatrix[key] = price;
      }
    }
  }

  void _applyFilters() {
    // Ticket-Filter anwenden
    List<TicketType> tempTicketTypes = List.from(_ticketTypes);

    // Gym-Filter (nur für SuperUser)
    if (widget.isSuperUser) {
      switch (_selectedGymFilter) {
        case 'Vertic Universal':
          tempTicketTypes =
              tempTicketTypes.where((t) => t.isVerticUniversal).toList();
          break;
        case 'Greifbar Bregenz':
          tempTicketTypes = tempTicketTypes
              .where((t) => t.gymId == 1 && !t.isVerticUniversal)
              .toList();
          break;
        case 'Greifbar Friedrichshafen':
          tempTicketTypes = tempTicketTypes
              .where((t) => t.gymId == 2 && !t.isVerticUniversal)
              .toList();
          break;
        default: // 'Alle'
          // Alle Tickets anzeigen
          break;
      }
    } else {
      // Für Hall-Admins: Filter basierend auf hallId
      if (widget.hallId != null) {
        tempTicketTypes = tempTicketTypes
            .where((t) => t.gymId == widget.hallId && !t.isVerticUniversal)
            .toList();
      }
    }

    // Ticket-Typ Filter
    switch (_selectedTicketFilter) {
      case 'Einzeltickets':
        tempTicketTypes = tempTicketTypes
            .where((t) => !t.isSubscription && !t.isPointBased)
            .toList();
        break;
      case 'Punktekarten':
        tempTicketTypes = tempTicketTypes.where((t) => t.isPointBased).toList();
        break;
      case 'Abonnements':
        tempTicketTypes =
            tempTicketTypes.where((t) => t.isSubscription).toList();
        break;
      default: // 'Alle'
        // Keine weitere Filterung
        break;
    }

    _filteredTicketTypes = tempTicketTypes;

    // Status-Filter anwenden
    List<UserStatusType> tempStatusTypes = List.from(_statusTypes);

    // Gym-Filter für Status (nur für SuperUser)
    if (widget.isSuperUser) {
      switch (_selectedGymFilter) {
        case 'Vertic Universal':
          tempStatusTypes =
              tempStatusTypes.where((s) => s.isVerticUniversal).toList();
          break;
        case 'Greifbar Bregenz':
          tempStatusTypes = tempStatusTypes
              .where((s) => s.gymId == 1 && !s.isVerticUniversal)
              .toList();
          break;
        case 'Greifbar Friedrichshafen':
          tempStatusTypes = tempStatusTypes
              .where((s) => s.gymId == 2 && !s.isVerticUniversal)
              .toList();
          break;
        default: // 'Alle'
          // Alle Status anzeigen
          break;
      }
    } else {
      // Für Hall-Admins: Filter basierend auf hallId
      if (widget.hallId != null) {
        tempStatusTypes = tempStatusTypes
            .where((s) => s.gymId == widget.hallId && !s.isVerticUniversal)
            .toList();
      }
    }

    // Status-Typ Filter
    switch (_selectedStatusFilter) {
      case 'Mit Rabatt':
        tempStatusTypes = tempStatusTypes
            .where((s) =>
                s.discountPercentage > 0 ||
                (s.fixedDiscountAmount != null && s.fixedDiscountAmount! > 0))
            .toList();
        break;
      case 'Standard':
        tempStatusTypes = tempStatusTypes
            .where((s) =>
                s.discountPercentage == 0 &&
                (s.fixedDiscountAmount == null || s.fixedDiscountAmount! == 0))
            .toList();
        break;
      default: // 'Alle'
        // Keine weitere Filterung
        break;
    }

    _filteredStatusTypes = tempStatusTypes;
  }

  Future<void> _updatePrice(
      TicketType ticketType, UserStatusType statusType, double newPrice) async {
    final key = '${ticketType.id}_${statusType.id}';
    setState(() {
      _pricingMatrix[key] = newPrice;
    });

    // TODO: Backend-Call um spezielle Preise zu speichern
    // await client.pricing.setSpecialPrice(ticketType.id, statusType.id, newPrice);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preis für ${ticketType.name} / ${statusType.name} auf ${newPrice.toStringAsFixed(2)}€ gesetzt',
        ),
      ),
    );
  }

  void _showEditPriceDialog(TicketType ticketType, UserStatusType statusType) {
    final key = '${ticketType.id}_${statusType.id}';
    final currentPrice = _pricingMatrix[key] ?? ticketType.defaultPrice;
    final controller = TextEditingController(
        text: currentPrice.toStringAsFixed(2).replaceAll('.', ','));

    // Benachrichtige über ungespeicherte Änderungen
    widget.onUnsavedChanges?.call(true, 'Preis bearbeiten');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preis bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket: ${ticketType.name}'),
            Text('Status: ${statusType.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Preis (€)',
                border: OutlineInputBorder(),
                hintText: 'z.B. 14,50 oder 14.50',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Dialog abgebrochen
              widget.onUnsavedChanges?.call(false, null);
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final normalizedText = controller.text.replaceAll(',', '.');
              final newPrice = double.tryParse(normalizedText);
              if (newPrice != null && newPrice >= 0) {
                _updatePrice(ticketType, statusType, newPrice);
                // Änderungen gespeichert
                widget.onUnsavedChanges?.call(false, null);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Ungültiger Preis. Nutzen Sie Punkt oder Komma als Dezimaltrennzeichen.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Color _getPriceColor(double price, double defaultPrice) {
    if (price < defaultPrice) {
      return Colors.green; // Ermäßigt
    } else if (price > defaultPrice) {
      return Colors.orange; // Aufpreis
    } else {
      return Colors.grey[700]!; // Standard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom AppBar
        Container(
          color: Theme.of(context).primaryColor,
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
                    'Preisgestaltung',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
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
                            onPressed: _loadData,
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    )
                  : _ticketTypes.isEmpty || _statusTypes.isEmpty
                      ? const Center(
                          child: Text(
                              'Keine Ticket-Typen oder Status-Typen vorhanden'),
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
                                  colors: [
                                    Colors.orange.shade600,
                                    Colors.orange.shade400
                                  ],
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
                                      const Icon(Icons.euro,
                                          color: Colors.white, size: 28),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Preisgestaltung',
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
                                    'Verwalten Sie Preise für verschiedene Ticket-Typen und Benutzer-Status.',
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

                            // Filter-Sektion
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.filter_list,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Filter',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Gym-Filter für SuperUser
                                  if (widget.isSuperUser) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Gym:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              DropdownButtonFormField<String>(
                                                value: _selectedGymFilter,
                                                decoration:
                                                    const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                ),
                                                items: const [
                                                  DropdownMenuItem(
                                                      value: 'Alle',
                                                      child: Text('Alle Gyms')),
                                                  DropdownMenuItem(
                                                      value: 'Vertic Universal',
                                                      child: Text(
                                                          'Vertic Universal')),
                                                  DropdownMenuItem(
                                                      value: 'Greifbar Bregenz',
                                                      child: Text(
                                                          'Greifbar Bregenz')),
                                                  DropdownMenuItem(
                                                      value:
                                                          'Greifbar Friedrichshafen',
                                                      child: Text(
                                                          'Greifbar Friedrichshafen')),
                                                ],
                                                onChanged: (value) {
                                                  if (value != null) {
                                                    setState(() {
                                                      _selectedGymFilter =
                                                          value;
                                                      _applyFilters();
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ticket-Typ:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            DropdownButtonFormField<String>(
                                              value: _selectedTicketFilter,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: 'Alle',
                                                    child: Text(
                                                        'Alle Ticket-Typen')),
                                                DropdownMenuItem(
                                                    value: 'Einzeltickets',
                                                    child:
                                                        Text('Einzeltickets')),
                                                DropdownMenuItem(
                                                    value: 'Punktekarten',
                                                    child:
                                                        Text('Punktekarten')),
                                                DropdownMenuItem(
                                                    value: 'Abonnements',
                                                    child: Text('Abonnements')),
                                              ],
                                              onChanged: (value) {
                                                if (value != null) {
                                                  setState(() {
                                                    _selectedTicketFilter =
                                                        value;
                                                    _applyFilters();
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Benutzer-Status:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            DropdownButtonFormField<String>(
                                              value: _selectedStatusFilter,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: 'Alle',
                                                    child: Text('Alle Status')),
                                                DropdownMenuItem(
                                                    value: 'Standard',
                                                    child: Text(
                                                        'Standard (ohne Rabatt)')),
                                                DropdownMenuItem(
                                                    value: 'Mit Rabatt',
                                                    child: Text('Mit Rabatt')),
                                              ],
                                              onChanged: (value) {
                                                if (value != null) {
                                                  setState(() {
                                                    _selectedStatusFilter =
                                                        value;
                                                    _applyFilters();
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: 16,
                                          color: Colors.blue.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Zeige ${_filteredTicketTypes.length} Ticket-Typen × ${_filteredStatusTypes.length} Status = ${_filteredTicketTypes.length * _filteredStatusTypes.length} Kombinationen',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Preismatrix-Tabelle
                            Expanded(
                              child: _buildPricingTable(),
                            ),
                          ],
                        ),
        ),
      ],
    );
  }

  Widget _buildPricingTable() {
    if (_filteredTicketTypes.isEmpty || _filteredStatusTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Keine Daten für gewählte Filter',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Passen Sie die Filter an oder fügen Sie Ticket-Typen/Status hinzu',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: {
                0: const FixedColumnWidth(180),
                for (int i = 0; i < _filteredStatusTypes.length; i++)
                  i + 1: const FixedColumnWidth(120),
              },
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        'Ticket-Typ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    for (final statusType in _filteredStatusTypes)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusType.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (statusType.discountPercentage > 0)
                              Text(
                                '${statusType.discountPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[600],
                                ),
                              ),
                            if (statusType.fixedDiscountAmount != null &&
                                statusType.fixedDiscountAmount! > 0)
                              Text(
                                '-${statusType.fixedDiscountAmount!.toStringAsFixed(2)}€',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Data Rows
                for (final ticketType in _filteredTicketTypes)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticketType.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Standard: ${ticketType.defaultPrice.toStringAsFixed(2)}€',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final statusType in _filteredStatusTypes)
                        _buildPriceCell(ticketType, statusType),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCell(TicketType ticketType, UserStatusType statusType) {
    final key = '${ticketType.id}_${statusType.id}';
    final price = _pricingMatrix[key] ?? ticketType.defaultPrice;
    final color = _getPriceColor(price, ticketType.defaultPrice);

    return GestureDetector(
      onTap: () => _showEditPriceDialog(ticketType, statusType),
      child: Container(
        margin: const EdgeInsets.all(4.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              '${price.toStringAsFixed(2)}€',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (price != ticketType.defaultPrice)
              Text(
                price < ticketType.defaultPrice ? 'Ermäßigt' : 'Aufpreis',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
