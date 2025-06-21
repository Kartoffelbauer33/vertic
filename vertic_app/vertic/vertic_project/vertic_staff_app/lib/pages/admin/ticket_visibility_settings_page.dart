import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

class TicketVisibilitySettingsPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(bool, String?)? onUnsavedChanges;

  const TicketVisibilitySettingsPage({
    super.key,
    required this.onBack,
    this.onUnsavedChanges,
  });

  @override
  State<TicketVisibilitySettingsPage> createState() =>
      _TicketVisibilitySettingsPageState();
}

class _TicketVisibilitySettingsPageState
    extends State<TicketVisibilitySettingsPage> {
  List<Gym> _gyms = [];
  List<Facility> _facilities = []; // 🏢 FACILITIES HINZUFÜGEN
  List<TicketType> _allTicketTypes = [];
  Map<String, TicketVisibilityData> _visibilityData = {};
  Map<String, FacilityVisibilityData> _facilityVisibilityData =
      {}; // 🏢 FACILITY-DATEN
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadGyms();
    await _loadFacilities(); // 🏢 FACILITIES LADEN
    await _loadTicketTypes();
    _organizeHierarchicalVisibilityData(); // 🏢 HIERARCHISCH ORGANISIEREN
  }

  Future<void> _loadGyms() async {
    try {
      debugPrint('🔍 Lade Gyms für Ticket-Sichtbarkeit...');
      final client = Provider.of<Client>(context, listen: false);
      final gyms = await client.gym.getAllGyms();
      debugPrint('✅ ${gyms.length} Gyms für Sichtbarkeit gefunden');
      setState(() {
        _gyms = gyms.where((g) => g.isActive).toList();
      });
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Gyms: $e');
      setState(() {
        _errorMessage = 'Fehler beim Laden der Gyms: $e';
      });
    }
  }

  Future<void> _loadTicketTypes() async {
    try {
      debugPrint('🔍 Lade TicketTypes für Sichtbarkeit...');
      final client = Provider.of<Client>(context, listen: false);
      final ticketTypes = await client.ticketType.getAllTicketTypes();
      debugPrint(
          '✅ ${ticketTypes.length} TicketTypes für Sichtbarkeit gefunden');
      setState(() {
        _allTicketTypes = ticketTypes;
      });
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der TicketTypes: $e');
      setState(() {
        _errorMessage = 'Fehler beim Laden der TicketTypes: $e';
      });
    }
  }

  /// 🏢 FACILITIES LADEN
  Future<void> _loadFacilities() async {
    try {
      debugPrint('🔍 Lade Facilities für Ticket-Sichtbarkeit...');
      final client = Provider.of<Client>(context, listen: false);
      final facilities = await client.facility.getAllFacilities();
      debugPrint('✅ ${facilities.length} Facilities für Sichtbarkeit gefunden');
      setState(() {
        _facilities = facilities.where((f) => f.isActive).toList();
      });
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Facilities: $e');
      setState(() {
        _errorMessage = 'Fehler beim Laden der Facilities: $e';
      });
    }
  }

  /// 🏢 HIERARCHISCHE SICHTBARKEITS-DATEN ORGANISIEREN
  void _organizeHierarchicalVisibilityData() {
    _visibilityData.clear();
    _facilityVisibilityData.clear();

    // 🌐 Vertic Universal Daten (bleibt gleich)
    final verticTickets = _allTicketTypes
        .where((t) => t.isVerticUniversal == true || t.gymId == null)
        .toList();

    _visibilityData['Vertic Universal'] = TicketVisibilityData(
      gymName: 'Vertic Universal',
      gymId: null,
      isVisible: true,
      einzeltickets: _filterTicketsByCategory(verticTickets, 'einzeltickets'),
      punktekarten: _filterTicketsByCategory(verticTickets, 'punktekarten'),
      zeitkarten: _filterTicketsByCategory(verticTickets, 'zeitkarten'),
    );

    // 🏢 Facility-basierte Hierarchie erstellen
    for (final facility in _facilities) {
      final facilityGyms =
          _gyms.where((gym) => gym.facilityId == facility.id).toList();
      final facilityGymData = <String, TicketVisibilityData>{};

      // Für jedes Gym in dieser Facility
      for (final gym in facilityGyms) {
        final gymTickets = _allTicketTypes
            .where((t) => t.gymId == gym.id && !t.isVerticUniversal)
            .toList();

        facilityGymData[gym.name] = TicketVisibilityData(
          gymName: gym.name,
          gymId: gym.id,
          isVisible: true,
          einzeltickets: _filterTicketsByCategory(gymTickets, 'einzeltickets'),
          punktekarten: _filterTicketsByCategory(gymTickets, 'punktekarten'),
          zeitkarten: _filterTicketsByCategory(gymTickets, 'zeitkarten'),
        );
      }

      _facilityVisibilityData[facility.name] = FacilityVisibilityData(
        facilityName: facility.name,
        facilityId: facility.id,
        isVisible: true,
        gyms: facilityGymData,
      );
    }

    // 🌐 Universal Gyms (ohne Facility-Zuordnung)
    final universalGyms = _gyms.where((gym) => gym.facilityId == null).toList();
    if (universalGyms.isNotEmpty) {
      final universalGymData = <String, TicketVisibilityData>{};

      for (final gym in universalGyms) {
        final gymTickets = _allTicketTypes
            .where((t) => t.gymId == gym.id && !t.isVerticUniversal)
            .toList();

        universalGymData[gym.name] = TicketVisibilityData(
          gymName: gym.name,
          gymId: gym.id,
          isVisible: true,
          einzeltickets: _filterTicketsByCategory(gymTickets, 'einzeltickets'),
          punktekarten: _filterTicketsByCategory(gymTickets, 'punktekarten'),
          zeitkarten: _filterTicketsByCategory(gymTickets, 'zeitkarten'),
        );
      }

      // Universal Gyms als eigene "Facility" behandeln
      _facilityVisibilityData['Universal Gyms'] = FacilityVisibilityData(
        facilityName: 'Universal Gyms',
        facilityId: null,
        isVisible: true,
        gyms: universalGymData,
      );
    }

    debugPrint('✅ Hierarchische Sichtbarkeits-Daten organisiert:');
    debugPrint(
        '   🌐 Vertic Universal: ${_visibilityData['Vertic Universal']?.einzeltickets.ticketCount} Tickets');
    debugPrint('   🏢 Facilities: ${_facilityVisibilityData.keys.join(', ')}');

    setState(() {
      _isLoading = false;
    });
  }

  CategoryVisibilityData _filterTicketsByCategory(
      List<TicketType> tickets, String category) {
    List<TicketType> categoryTickets;

    switch (category) {
      case 'einzeltickets':
        categoryTickets =
            tickets.where((t) => !t.isSubscription && !t.isPointBased).toList();
        break;
      case 'punktekarten':
        categoryTickets = tickets.where((t) => t.isPointBased).toList();
        break;
      case 'zeitkarten':
        categoryTickets = tickets.where((t) => t.isSubscription).toList();
        break;
      default:
        categoryTickets = [];
    }

    return CategoryVisibilityData(
      categoryName: category,
      isVisible: true,
      ticketCount: categoryTickets.length,
      tickets: categoryTickets,
    );
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
      widget.onUnsavedChanges?.call(true, 'Hierarchische Ticket-Sichtbarkeit');
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);
      // TODO: Nach Backend-Generierung echte Methode verwenden
      // final success = await client.ticket.saveHierarchicalVisibilitySettings(_hierarchicalData);

      // Temporär: Simuliere erfolgreiche Speicherung
      await Future.delayed(const Duration(seconds: 1));
      const success = true;

      if (success) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        widget.onUnsavedChanges?.call(false, null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Hierarchische Sichtbarkeits-Einstellungen gespeichert'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Fehler beim Speichern der Einstellungen';
        });
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

  /// 🏢 FACILITY-SICHTBARKEIT UMSCHALTEN
  void _toggleFacilityVisibility(String facilityName, bool value) {
    if (_facilityVisibilityData.isEmpty) return;

    setState(() {
      final facilityData = _facilityVisibilityData[facilityName];
      if (facilityData != null) {
        facilityData.isVisible = value;

        // Alle Gyms in dieser Facility auch umschalten
        facilityData.gyms.forEach((gymName, gymData) {
          gymData.isVisible = value;
        });

        _markAsChanged();
      }
    });
  }

  void _toggleHallVisibility(String hallName, bool value) {
    if (_visibilityData.isEmpty) return;

    setState(() {
      final hallData = _visibilityData[hallName];
      if (hallData != null) {
        hallData.isVisible = value;
      }
      _markAsChanged();
    });
  }

  void _toggleCategoryVisibility(
      String hallName, String categoryName, bool value) {
    if (_visibilityData.isEmpty) return;

    setState(() {
      final hallData = _visibilityData[hallName];
      if (hallData != null) {
        final categoryData = hallData.categories[categoryName];
        if (categoryData != null) {
          categoryData.isVisible = value;
        }
      }
      _markAsChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hierarchische Ticket-Sichtbarkeit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              _hasUnsavedChanges ? _showUnsavedChangesDialog : widget.onBack,
        ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveSettings,
              tooltip: 'Einstellungen speichern',
            ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _showAllVisible,
                child: const Row(
                  children: [
                    Icon(Icons.visibility),
                    SizedBox(width: 8),
                    Text('Alle Kategorien aktivieren'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: _hideAllVisible,
                child: const Row(
                  children: [
                    Icon(Icons.visibility_off),
                    SizedBox(width: 8),
                    Text('Alle Kategorien deaktivieren'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
              onPressed: _loadInitialData,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_visibilityData.isEmpty) {
      return const Center(
        child: Text('Keine Daten verfügbar'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVerticSection(),
          const SizedBox(height: 24),
          _buildHallsSection(),
        ],
      ),
    );
  }

  Widget _buildVerticSection() {
    final verticData = _visibilityData['Vertic Universal'];
    if (verticData == null) return const SizedBox.shrink();

    final isVisible = verticData.isVisible;

    // Berechne Gesamtanzahl der Tickets in allen Kategorien
    int totalTickets = verticData.einzeltickets.ticketCount +
        verticData.punktekarten.ticketCount +
        verticData.zeitkarten.ticketCount;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(
          Icons.verified,
          color: isVisible ? Colors.teal : Colors.grey,
        ),
        title: Text(
          'Vertic Universal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isVisible ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          '$totalTickets Tickets insgesamt',
          style: TextStyle(
            color: isVisible ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        ),
        trailing: Switch(
          value: isVisible,
          onChanged: (value) =>
              _toggleHallVisibility('Vertic Universal', value),
          activeColor: Colors.teal,
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nur Kategorien mit Tickets anzeigen
                if (verticData.einzeltickets.ticketCount > 0)
                  _buildCategoryRow('Einzeltickets', verticData.einzeltickets,
                      Icons.confirmation_number, Colors.green),

                if (verticData.einzeltickets.ticketCount > 0 &&
                    verticData.punktekarten.ticketCount > 0)
                  const SizedBox(height: 12),

                if (verticData.punktekarten.ticketCount > 0)
                  _buildCategoryRow('Punktekarten', verticData.punktekarten,
                      Icons.credit_card, Colors.orange),

                if ((verticData.punktekarten.ticketCount > 0 ||
                        verticData.einzeltickets.ticketCount > 0) &&
                    verticData.zeitkarten.ticketCount > 0)
                  const SizedBox(height: 12),

                if (verticData.zeitkarten.ticketCount > 0)
                  _buildCategoryRow('Zeitkarten/Abos', verticData.zeitkarten,
                      Icons.schedule, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facility-spezifische Tickets', // 🏢 TITEL GEÄNDERT
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        // 🏢 HIERARCHISCHE FACILITY-CARDS ANSTATT FLACHER HALL-CARDS
        ..._buildHierarchicalFacilityCards(),
      ],
    );
  }

  /// 🏢 HIERARCHISCHE FACILITY-CARDS ERSTELLEN
  List<Widget> _buildHierarchicalFacilityCards() {
    return _facilityVisibilityData.entries.map((facilityEntry) {
      final facilityName = facilityEntry.key;
      final facilityData = facilityEntry.value;

      return _buildFacilityCard(facilityName, facilityData);
    }).toList();
  }

  /// 🏢 FACILITY-CARD MIT EINGERÜCKTEN GYMS
  Widget _buildFacilityCard(
      String facilityName, FacilityVisibilityData facilityData) {
    final isVisible = facilityData.isVisible;
    final gyms = facilityData.gyms;

    // Gesamtanzahl Tickets in dieser Facility
    int totalTickets = 0;
    int activeCategoriesCount = 0;

    for (final gymData in gyms.values) {
      totalTickets += gymData.einzeltickets.ticketCount +
          gymData.punktekarten.ticketCount +
          gymData.zeitkarten.ticketCount;

      if (gymData.einzeltickets.ticketCount > 0) activeCategoriesCount++;
      if (gymData.punktekarten.ticketCount > 0) activeCategoriesCount++;
      if (gymData.zeitkarten.ticketCount > 0) activeCategoriesCount++;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(
          facilityData.facilityId == null ? Icons.public : Icons.corporate_fare,
          color: isVisible
              ? (facilityData.facilityId == null ? Colors.blue : Colors.orange)
              : Colors.grey,
        ),
        title: Text(
          facilityName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isVisible ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${gyms.length} Gym${gyms.length != 1 ? 's' : ''} • $totalTickets Tickets',
          style: TextStyle(
            color: isVisible ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        ),
        trailing: Switch(
          value: isVisible,
          onChanged: (value) => _toggleFacilityVisibility(facilityName, value),
          activeColor:
              facilityData.facilityId == null ? Colors.blue : Colors.orange,
        ),
        children: [
          // 🏋️ GYMS IN DIESER FACILITY (EINGERÜCKT)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: gyms.entries.map((gymEntry) {
                final gymName = gymEntry.key;
                final gymData = gymEntry.value;

                return Container(
                  margin: const EdgeInsets.only(left: 16, bottom: 8),
                  child: _buildHallCard(gymName, gymData),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallCard(String hallName, TicketVisibilityData hallData) {
    final isVisible = hallData.isVisible;
    final totalTickets = hallData.einzeltickets.ticketCount +
        hallData.punktekarten.ticketCount +
        hallData.zeitkarten.ticketCount;

    // Zähle aktive Kategorien (die Tickets haben)
    int activeCategoriesCount = 0;
    if (hallData.einzeltickets.ticketCount > 0) activeCategoriesCount++;
    if (hallData.punktekarten.ticketCount > 0) activeCategoriesCount++;
    if (hallData.zeitkarten.ticketCount > 0) activeCategoriesCount++;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(
          Icons.location_on,
          color: isVisible ? Colors.blue : Colors.grey,
        ),
        title: Text(
          hallName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isVisible ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          '$totalTickets Tickets in $activeCategoriesCount Kategorien',
          style: TextStyle(
            color: isVisible ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        ),
        trailing: Switch(
          value: isVisible,
          onChanged: (value) => _toggleHallVisibility(hallName, value),
          activeColor: Colors.blue,
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: hallData.categories.entries.map((entry) {
                final categoryName = entry.key;
                final categoryData = entry.value;

                return _buildCategoryRow(categoryName, categoryData,
                    Icons.confirmation_number, Colors.green);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String categoryName,
      CategoryVisibilityData categoryData, IconData icon, Color color) {
    final isVisible = categoryData.isVisible;
    final tickets = categoryData.tickets;

    // Wenn keine Tickets vorhanden, zeige nur die Kategorie
    if (tickets.isEmpty) {
      return Card(
        color: isVisible ? Colors.white : Colors.grey.shade50,
        child: ListTile(
          leading: Icon(
            icon,
            color: isVisible ? color : Colors.grey.shade400,
          ),
          title: Text(
            categoryName,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isVisible ? Colors.black : Colors.grey.shade600,
            ),
          ),
          subtitle: Text(
            '${categoryData.ticketCount} Tickets',
            style: TextStyle(
              color: isVisible
                  ? color.withValues(alpha: 0.7)
                  : Colors.grey.shade500,
            ),
          ),
          trailing: Switch.adaptive(
            value: isVisible,
            onChanged: (value) =>
                _toggleCategoryVisibility(categoryName, categoryName, value),
            activeColor: color,
          ),
        ),
      );
    }

    // Mit Tickets: ExpansionTile für Dropdown
    return Card(
      color: isVisible ? Colors.white : Colors.grey.shade50,
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: isVisible ? color : Colors.grey.shade400,
        ),
        title: Text(
          categoryName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isVisible ? Colors.black : Colors.grey.shade600,
          ),
        ),
        subtitle: Text(
          '${categoryData.ticketCount} Tickets',
          style: TextStyle(
            color:
                isVisible ? color.withValues(alpha: 0.7) : Colors.grey.shade500,
          ),
        ),
        trailing: Switch.adaptive(
          value: isVisible,
          onChanged: (value) =>
              _toggleCategoryVisibility(categoryName, categoryName, value),
          activeColor: color,
        ),
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Column(
              children: tickets.map((ticket) {
                return Card(
                  color: Colors.grey.shade50,
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.confirmation_number,
                      color: Colors.blue.shade300,
                      size: 20,
                    ),
                    title: Text(
                      ticket.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${ticket.defaultPrice.toStringAsFixed(2)} €',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value:
                          true, // Temporär alle auf true, da TicketType kein isVisible hat
                      onChanged: (value) {
                        // TODO: Implementiere individuelle Ticket-Sichtbarkeit
                        debugPrint(
                            'Ticket-Sichtbarkeit für ${ticket.name}: $value');
                        _markAsChanged();
                      },
                      activeColor: color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllVisible() {
    if (_visibilityData.isEmpty) return;

    setState(() {
      _visibilityData.forEach((hallName, hallData) {
        hallData.isVisible = true;
      });
      _markAsChanged();
    });
  }

  void _hideAllVisible() {
    if (_visibilityData.isEmpty) return;

    setState(() {
      _visibilityData.forEach((hallName, hallData) {
        hallData.isVisible = false;
      });
      _markAsChanged();
    });
  }

  String _getHallDisplayName(String hallName) {
    return hallName.toUpperCase();
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text(
          'Sie haben ungespeicherte Änderungen an der hierarchischen Ticket-Sichtbarkeit. '
          'Möchten Sie diese speichern bevor Sie fortfahren?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onUnsavedChanges?.call(false, null);
              widget.onBack();
            },
            child: const Text('Verwerfen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveSettings();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

// Helper-Klassen für die neue Struktur
class TicketVisibilityData {
  final String gymName;
  final int? gymId;
  bool isVisible;
  final CategoryVisibilityData einzeltickets;
  final CategoryVisibilityData punktekarten;
  final CategoryVisibilityData zeitkarten;

  TicketVisibilityData({
    required this.gymName,
    required this.gymId,
    required this.isVisible,
    required this.einzeltickets,
    required this.punktekarten,
    required this.zeitkarten,
  });

  Map<String, CategoryVisibilityData> get categories => {
        'Einzeltickets': einzeltickets,
        'Punktekarten': punktekarten,
        'Zeitkarten': zeitkarten,
      };
}

class CategoryVisibilityData {
  final String categoryName;
  bool isVisible;
  final int ticketCount;
  final List<TicketType> tickets;

  CategoryVisibilityData({
    required this.categoryName,
    required this.isVisible,
    required this.ticketCount,
    required this.tickets,
  });
}

/// 🏢 FACILITY-VISIBILITY-DATEN
class FacilityVisibilityData {
  final String facilityName;
  final int? facilityId;
  bool isVisible;
  final Map<String, TicketVisibilityData> gyms; // Gyms in dieser Facility

  FacilityVisibilityData({
    required this.facilityName,
    required this.facilityId,
    required this.isVisible,
    required this.gyms,
  });
}
