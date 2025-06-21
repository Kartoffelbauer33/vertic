import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';
import 'package:provider/provider.dart';

class UnifiedTicketManagementPage extends StatefulWidget {
  final bool isSuperUser;
  final int? hallId;
  final VoidCallback? onBack;
  final Function(bool, String?)? onUnsavedChanges;

  const UnifiedTicketManagementPage({
    super.key,
    this.isSuperUser = false,
    this.hallId,
    this.onBack,
    this.onUnsavedChanges,
  });

  @override
  State<UnifiedTicketManagementPage> createState() =>
      _UnifiedTicketManagementPageState();
}

class _UnifiedTicketManagementPageState
    extends State<UnifiedTicketManagementPage> {
  List<TicketType> _allTickets = [];
  List<Gym> _gyms = [];
  final Map<String, List<TicketType>> _gymTickets = {};
  String _selectedCategory = 'Vertic Universal';
  bool _isLoading = true;
  String? _errorMessage;

  late Client client;

  @override
  void initState() {
    super.initState();
    client = Provider.of<Client>(context, listen: false);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadGyms();
    await _loadTickets();
  }

  Future<void> _loadGyms() async {
    try {
      debugPrint('🔍 Lade Gyms aus der Datenbank...');
      final gyms = await client.gym.getAllGyms();
      debugPrint(
          '✅ ${gyms.length} Gyms gefunden: ${gyms.map((g) => '${g.name}(ID:${g.id})').join(', ')}');
      setState(() {
        _gyms = gyms.where((g) => g.isActive).toList();
      });
      debugPrint('✅ ${_gyms.length} aktive Gyms gefiltert');
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Gyms: $e');
      setState(() {
        _errorMessage = 'Fehler beim Laden der Gyms: $e';
      });
    }
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 Lade Tickets aus der Datenbank...');
      final tickets = await client.ticketType.getAllTicketTypes();
      debugPrint('✅ ${tickets.length} Tickets gefunden');
      setState(() {
        _allTickets = tickets;
        _organizeTicketsByGym();
        _isLoading = false;
      });
      debugPrint(
          '✅ Tickets nach Gyms organisiert: ${_gymTickets.keys.join(', ')}');
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Tickets: $e');
      setState(() {
        _errorMessage = 'Fehler beim Laden der Tickets: $e';
        _isLoading = false;
      });
    }
  }

  void _organizeTicketsByGym() {
    _gymTickets.clear();

    // Vertic Universal Tickets (alle ohne spezifische Gym-Zuordnung)
    _gymTickets['Vertic Universal'] = _allTickets
        .where((ticket) =>
            ticket.isVerticUniversal == true || ticket.gymId == null)
        .toList();

    // Dynamische Gym-Tickets basierend auf echten Gyms aus der Datenbank
    for (final gym in _gyms) {
      _gymTickets[gym.name] = _allTickets
          .where(
              (ticket) => ticket.gymId == gym.id && !ticket.isVerticUniversal)
          .toList();
    }
  }

  List<TicketType> _getTicketsForCategory() {
    return _gymTickets[_selectedCategory] ?? [];
  }

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
                    widget.isSuperUser
                        ? 'Unified Ticket Management'
                        : 'Hallen-Tickets',
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

        // Header
        _buildHeader(),

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
                            onPressed: _loadTickets,
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(child: _buildTicketList()),
                      ],
                    ),
        ),

        // Floating Action Button als Fixed Button
        Container(
          decoration: const BoxDecoration(),
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateTicketDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Neues Ticket'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    List<String> categories = [];

    if (widget.isSuperUser) {
      // Für SuperUser: Vertic Universal + alle aktiven Gyms
      categories = [
        'Vertic Universal',
        ..._gyms.map((gym) => gym.name),
      ];
    } else {
      // Für Hall-Admins: Finde ihr spezifisches Gym
      final userGym = _gyms.firstWhere(
        (gym) => gym.id == widget.hallId,
        orElse: () => Gym(
          name: 'Unbekanntes Gym',
          shortCode: 'UNK',
          city: 'Unbekannt',
          isActive: false,
          createdAt: DateTime.now(),
        ),
      );
      categories = [userGym.name];
      _selectedCategory = userGym.name;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isSuperUser
                    ? 'Vertic Ticket-Management'
                    : 'Hallen-Tickets',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (widget.isSuperUser) ...[
                Material(
                  color: Colors.transparent,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      labelText: 'Kategorie auswählen',
                    ),
                    items: categories.map((category) {
                      IconData icon;
                      Color color;
                      int ticketCount = _gymTickets[category]?.length ?? 0;

                      if (category == 'Vertic Universal') {
                        icon = Icons.verified;
                        color = Colors.teal;
                      } else {
                        // Für echte Gyms
                        icon = Icons.location_on;
                        color = Colors.blue;
                      }

                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: color, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '$category ($ticketCount)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),
              ] else ...[
                // Für Hall-Admins: Zeige ihre spezifische Kategorie
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedCategory,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '(${_gymTickets[_selectedCategory]?.length ?? 0})',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketList() {
    final tickets = _getTicketsForCategory();

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Keine Tickets in $_selectedCategory',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Erstelle dein erstes Ticket für diese Kategorie',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(TicketType ticket) {
    // Bestimme Kategorie-Badge basierend auf echten Gym-Daten
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (ticket.isVerticUniversal) {
      badgeColor = Colors.teal;
      badgeText = 'VERTIC';
      badgeIcon = Icons.verified;
    } else if (ticket.gymId != null) {
      // Finde das Gym anhand der ID
      final gym = _gyms.firstWhere(
        (g) => g.id == ticket.gymId,
        orElse: () => Gym(
          name: 'Unbekanntes Gym',
          shortCode: 'UNK',
          city: 'Unbekannt',
          isActive: false,
          createdAt: DateTime.now(),
        ),
      );
      badgeColor = Colors.blue;
      badgeText = gym.shortCode.toUpperCase();
      badgeIcon = Icons.location_on;
    } else {
      badgeColor = Colors.grey;
      badgeText = 'UNBEKANNT';
      badgeIcon = Icons.help;
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
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, color: badgeColor, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditTicketDialog(ticket);
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

  void _showCreateTicketDialog() {
    // Benachrichtige über ungespeicherte Änderungen
    widget.onUnsavedChanges?.call(true, 'Neues Ticket');

    showDialog(
      context: context,
      builder: (context) => CreateUnifiedTicketDialog(
        category: _selectedCategory,
        isSuperUser: widget.isSuperUser,
        hallId: widget.hallId,
        onSaved: (ticketType) {
          // Änderungen gespeichert
          widget.onUnsavedChanges?.call(false, null);
          _loadTickets(); // Reload data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${ticketType.name} erfolgreich erstellt')),
          );
        },
        onCancelled: () {
          // Dialog abgebrochen
          widget.onUnsavedChanges?.call(false, null);
        },
      ),
    );
  }

  void _showEditTicketDialog(TicketType ticket) {
    showDialog(
      context: context,
      builder: (context) => CreateUnifiedTicketDialog(
        category: _selectedCategory,
        isSuperUser: widget.isSuperUser,
        hallId: widget.hallId,
        ticketType: ticket,
        onSaved: (updatedTicket) {
          _loadTickets(); // Reload data
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
        title: const Text('Ticket löschen'),
        content: Text(
            'Möchten Sie "${ticket.name}" wirklich löschen?\n\nDieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteTicket(ticket);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTicket(TicketType ticket) async {
    try {
      final success = await client.ticketType.deleteTicketType(ticket.id!);
      if (success) {
        _loadTickets(); // Reload data
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
}

// Vollständiger Dialog für Ticket-Erstellung
class CreateUnifiedTicketDialog extends StatefulWidget {
  final String category;
  final bool isSuperUser;
  final int? hallId;
  final TicketType? ticketType;
  final Function(TicketType) onSaved;
  final VoidCallback? onCancelled;

  const CreateUnifiedTicketDialog({
    super.key,
    required this.category,
    required this.isSuperUser,
    required this.hallId,
    this.ticketType,
    required this.onSaved,
    this.onCancelled,
  });

  @override
  State<CreateUnifiedTicketDialog> createState() =>
      _CreateUnifiedTicketDialogState();
}

class _CreateUnifiedTicketDialogState extends State<CreateUnifiedTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _validityPeriodController = TextEditingController();
  final _pointsController = TextEditingController();
  final _customDaysController = TextEditingController();

  final _validityFocusNode = FocusNode();

  String _selectedTicketCategory = 'Einzeltickets';
  bool _isPointBased = false;
  bool _isSubscription = false;
  String _billingMode = 'monthly';
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

    // Standard-Gültigkeit
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

    if (ticket.isPointBased && ticket.defaultPoints != null) {
      _pointsController.text = ticket.defaultPoints.toString();
    }

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
      switch (_selectedTicketCategory) {
        case 'Einzeltickets':
          _isPointBased = false;
          _isSubscription = false;
          // Einzeltickets sind immer Tagestickets
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
          // Zeitkarten haben keine klassische Gültigkeit, sondern Abrechnungszyklen
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

  Future<void> _saveTicket() async {
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
            billingInterval = -1;
            break;
          case 'yearly':
            billingInterval = -12;
            break;
          case 'custom':
            billingInterval = int.tryParse(_customDaysController.text);
            break;
        }
      }

      // Bestimme Gym-Zuordnung basierend auf Kategorie
      int? gymId;
      bool isVerticUniversal = false;

      if (widget.ticketType?.id != null) {
        // Bearbeitung - behalte bestehende Werte
        gymId = widget.ticketType!.gymId;
        isVerticUniversal = widget.ticketType!.isVerticUniversal;
      } else {
        // Neue Tickets - setze basierend auf Kategorie
        if (widget.category == 'Vertic Universal') {
          gymId = null;
          isVerticUniversal = true;
        } else {
          // Finde das Gym basierend auf dem Namen
          final client = Provider.of<Client>(context, listen: false);
          try {
            final gyms = await client.gym.getAllGyms();
            final selectedGym = gyms.firstWhere(
              (gym) => gym.name == widget.category,
              orElse: () =>
                  throw Exception('Gym nicht gefunden: ${widget.category}'),
            );
            gymId = selectedGym.id;
            isVerticUniversal = false;
          } catch (e) {
            throw Exception('Fehler beim Bestimmen der Gym-Zuordnung: $e');
          }
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
        gymId: gymId,
        isVerticUniversal: isVerticUniversal,
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
        throw Exception('Fehler beim Speichern des Tickets');
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
                  ? 'Neues Ticket für ${widget.category}'
                  : 'Ticket bearbeiten',
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
                      // Ticket-Kategorie (nur bei neuen Tickets)
                      if (widget.ticketType == null) ...[
                        Text(
                          'Ticket-Art:',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedTicketCategory,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Einzeltickets',
                              child: Row(
                                children: [
                                  Icon(Icons.confirmation_number,
                                      color: Colors.blue, size: 20),
                                  SizedBox(width: 8),
                                  Text('Einzeltickets'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Punktekarten',
                              child: Row(
                                children: [
                                  Icon(Icons.stars,
                                      color: Colors.orange, size: 20),
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
                                      color: Colors.purple, size: 20),
                                  SizedBox(width: 8),
                                  Text('Zeitkarten (Abonnements)'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _selectedTicketCategory = value;
                              _updateBasedOnCategory();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

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

                      // Preis und optional Gültigkeit
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
                          // Gültigkeit nur für Punktekarten, nicht für Einzeltickets oder Zeitkarten
                          if (_selectedTicketCategory == 'Punktekarten') ...[
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
                      if (_selectedTicketCategory == 'Punktekarten') ...[
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
                            if (_selectedTicketCategory == 'Punktekarten') {
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
                      ],

                      if (_selectedTicketCategory == 'Zeitkarten') ...[
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
                  onPressed: () {
                    widget.onCancelled?.call();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTicket,
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
}
