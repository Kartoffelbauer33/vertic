import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';

class UserStatusManagementPage extends StatefulWidget {
  final bool isSuperUser;
  final int? hallId;
  final VoidCallback? onBack;
  final Function(bool, String?)? onUnsavedChanges;

  const UserStatusManagementPage({
    super.key,
    this.isSuperUser = false,
    this.hallId,
    this.onBack,
    this.onUnsavedChanges,
  });

  @override
  State<UserStatusManagementPage> createState() =>
      _UserStatusManagementPageState();
}

class _UserStatusManagementPageState extends State<UserStatusManagementPage> {
  List<UserStatusType> _statusTypes = [];
  List<UserStatusType> _filteredStatusTypes = [];
  List<Gym> _gyms = []; // 🏋️ GYM-LISTE
  List<Facility> _facilities = []; // 🏢 FACILITY-LISTE
  Map<String, dynamic> _hierarchicalData = {}; // 🏢 HIERARCHISCHE DATEN
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'Vertic Universal';

  @override
  void initState() {
    super.initState();
    _loadHierarchicalData(); // 🏢 HIERARCHISCHE DATEN LADEN
  }

  Future<void> _loadStatusTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statusTypes = await client.userStatus.getAllStatusTypes();
      setState(() {
        _statusTypes = statusTypes;
        _filterStatusTypes();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Status-Typen: $e';
        _isLoading = false;
      });
    }
  }

  /// 🏢 HIERARCHISCHE DATEN LADEN - SIMPLE VERSION
  Future<void> _loadHierarchicalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🐛 DEBUG Frontend: Starte Datenladung mit neuem Endpoint...');

      final hierarchyResponse = await client.userStatus.getStatusHierarchy();
      debugPrint('🐛 DEBUG Frontend: Success: ${hierarchyResponse.success}');

      if (!hierarchyResponse.success) {
        throw Exception(hierarchyResponse.error ?? 'Backend-Fehler');
      }

      // Parse JSON-Strings zu Listen
      final statusTypesList = hierarchyResponse.statusTypesJson != null
          ? (jsonDecode(hierarchyResponse.statusTypesJson!) as List)
          : [];
      final gymsList = hierarchyResponse.gymsJson != null
          ? (jsonDecode(hierarchyResponse.gymsJson!) as List)
          : [];
      final facilitiesList = hierarchyResponse.facilitiesJson != null
          ? (jsonDecode(hierarchyResponse.facilitiesJson!) as List)
          : [];

      debugPrint(
          '🐛 DEBUG Frontend: ${statusTypesList.length} Status, ${gymsList.length} Gyms, ${facilitiesList.length} Facilities geladen');

      // Lade auch die originalen Objekte für Kompatibilität
      final statusTypes = await client.userStatus.getAllStatusTypes();
      final gyms = await client.gym.getAllGyms();
      final facilities = await client.facility.getAllFacilities();

      setState(() {
        _hierarchicalData = {
          'success': hierarchyResponse.success,
          'summary': {
            'totalStatusTypes': hierarchyResponse.totalStatusTypes,
            'totalGyms': hierarchyResponse.totalGyms,
            'totalFacilities': hierarchyResponse.totalFacilities,
          },
          'all_status_types': statusTypesList,
          'all_gyms': gymsList,
          'all_facilities': facilitiesList,
        };
        _statusTypes = statusTypes;
        _gyms = gyms;
        _facilities = facilities;
        _isLoading = false;
      });

      debugPrint(
          '✅ Status-Hierarchie geladen: ${hierarchyResponse.totalStatusTypes} Status, ${hierarchyResponse.totalGyms} Gyms, ${hierarchyResponse.totalFacilities} Facilities');
    } catch (e) {
      debugPrint('❌ Frontend Fehler: $e');
      debugPrint('❌ Stack Trace: ${StackTrace.current}');
      setState(() {
        _errorMessage = 'Fehler beim Laden der Status-Daten: $e';
        _isLoading = false;
      });
    }
  }

  /// 🔄 VERFÜGBARE KATEGORIEN BASIEREND AUF DATEN AKTUALISIEREN
  void _updateAvailableCategories() {
    if (!widget.isSuperUser && widget.hallId != null) {
      // 🔒 Für normale User: Finde das richtige Gym basierend auf hallId
      final userGym = _gyms.firstWhere(
        (gym) => gym.id == widget.hallId,
        orElse: () => _gyms.isNotEmpty
            ? _gyms.first
            : Gym(
                name: 'Unbekanntes Gym',
                shortCode: 'UNK',
                city: 'Unbekannt',
                isActive: true,
                isVerticLocation: true,
                createdAt: DateTime.now(),
              ),
      );
      _selectedCategory = userGym.name;
    } else {
      // 🔓 Für SuperUser: Vertic Universal als Standard
      _selectedCategory = 'Vertic Universal';
    }
  }

  /// 🔄 STATUS-TYPEN BASIEREND AUF DYNAMISCHER KATEGORIE FILTERN
  void _filterStatusTypes() {
    if (_selectedCategory == 'Vertic Universal') {
      // 🌐 Vertic Universal Status
      _filteredStatusTypes = _statusTypes
          .where((status) =>
              status.isVerticUniversal == true || status.gymId == null)
          .toList();
    } else {
      // 🏋️ Gym-spezifische Status - dynamisch basierend auf Gym-Name
      final selectedGym = _gyms.firstWhere(
        (gym) => gym.name == _selectedCategory,
        orElse: () => Gym(
          name: 'Unbekanntes Gym',
          shortCode: 'UNK',
          city: 'Unbekannt',
          isActive: true,
          isVerticLocation: true,
          createdAt: DateTime.now(),
        ),
      );

      if (selectedGym.id != null) {
        _filteredStatusTypes = _statusTypes
            .where((status) =>
                status.gymId == selectedGym.id && !status.isVerticUniversal)
            .toList();
      } else {
        _filteredStatusTypes = [];
      }
    }

    debugPrint(
        '🔍 Gefilterte Status für "$_selectedCategory": ${_filteredStatusTypes.length} Status');
  }

  /// 🏋️ GYM-NAME BASIEREND AUF ID ERMITTELN (DYNAMISCH)
  String _getHallName(int? hallId) {
    if (hallId == null) return 'Alle Hallen';

    final gym = _gyms.firstWhere(
      (g) => g.id == hallId,
      orElse: () => Gym(
        name: 'Unbekanntes Gym',
        shortCode: 'UNK',
        city: 'Unbekannt',
        isActive: true,
        isVerticLocation: true,
        createdAt: DateTime.now(),
      ),
    );

    return gym.name;
  }

  Future<void> _deleteStatusType(UserStatusType statusType) async {
    try {
      final success = await client.userStatus.deleteStatusType(statusType.id!);
      if (success) {
        await _loadHierarchicalData(); // 🔄 DATEN NACH LÖSCHUNG NEULADEN
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${statusType.name} erfolgreich gelöscht')),
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

  /// 🏗️ STANDARD-STATUS-TYPEN ERSTELLEN (DYNAMISCH BASIEREND AUF DATEN)
  Future<void> _createDefaultStatusTypes() async {
    try {
      List<UserStatusType> defaultStatuses = [];

      if (_selectedCategory == 'Vertic Universal') {
        // 🌐 Vertic Universal Standard-Status
        defaultStatuses = [
          UserStatusType(
            id: null,
            name: 'Vertic Mitarbeiter',
            description: 'Vertic Team - 100% Rabatt',
            discountPercentage: 100.0,
            fixedDiscountAmount: null,
            requiresVerification: true,
            requiresDocumentation: false,
            validityPeriod: 0,
            gymId: null,
            isVerticUniversal: true,
            createdAt: DateTime.now().toUtc(),
          ),
          UserStatusType(
            id: null,
            name: 'Student',
            description: 'Vergünstigter Studentenpreis - 30% Rabatt',
            discountPercentage: 30.0,
            fixedDiscountAmount: null,
            requiresVerification: true,
            requiresDocumentation: true,
            validityPeriod: 365,
            gymId: null,
            isVerticUniversal: true,
            createdAt: DateTime.now().toUtc(),
          ),
        ];
      } else {
        // 🏋️ Gym-spezifische Standard-Status (dynamisch basierend auf gewähltem Gym)
        final selectedGym = _gyms.firstWhere(
          (gym) => gym.name == _selectedCategory,
          orElse: () => Gym(
            id: null,
            name: 'Unbekanntes Gym',
            shortCode: 'UNK',
            city: 'Unbekannt',
            isActive: true,
            isVerticLocation: true,
            createdAt: DateTime.now(),
          ),
        );

        if (selectedGym.id != null) {
          defaultStatuses = [
            UserStatusType(
              id: null,
              name: 'Mitarbeiter ${selectedGym.name}',
              description: '${selectedGym.name} Team - 100% Rabatt',
              discountPercentage: 100.0,
              fixedDiscountAmount: null,
              requiresVerification: true,
              requiresDocumentation: false,
              validityPeriod: 0,
              gymId: selectedGym.id,
              isVerticUniversal: false,
              createdAt: DateTime.now().toUtc(),
            ),
            UserStatusType(
              id: null,
              name: 'Student ${selectedGym.name}',
              description:
                  'Studenten-Rabatt für ${selectedGym.name} - 20% Rabatt',
              discountPercentage: 20.0,
              fixedDiscountAmount: null,
              requiresVerification: true,
              requiresDocumentation: true,
              validityPeriod: 365,
              gymId: selectedGym.id,
              isVerticUniversal: false,
              createdAt: DateTime.now().toUtc(),
            ),
          ];
        }
      }

      int successCount = 0;
      for (final status in defaultStatuses) {
        try {
          await client.userStatus.createStatusType(status);
          successCount++;
        } catch (e) {
          // Überspringe bereits existierende Status
          if (!e.toString().contains('duplicate key value')) {
            // Nur echte Fehler anzeigen, nicht Duplikate
            debugPrint('Fehler beim Erstellen von ${status.name}: $e');
          }
        }
      }

      await _loadHierarchicalData(); // 🔄 HIERARCHISCHE DATEN NACH ERSTELLUNG NEULADEN

      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount neue Standard-Status erstellt'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alle Standard-Status existieren bereits'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Erstellen der Status: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                    widget.isSuperUser
                        ? 'Benutzer-Status verwalten'
                        : '${_getHallName(widget.hallId)} - Status',
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
                            onPressed:
                                _loadHierarchicalData, // 🔄 HIERARCHISCHE DATEN LADEN
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    )
                  : _buildHierarchicalStatusView(),
        ),

        // Floating Action Button als Fixed Button
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddStatusDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Neuer Status'),
            ),
          ),
        ),
      ],
    );
  }

  /// 🏗️ HIERARCHISCHE STATUS-ANSICHT (WIE GYM-VERWALTUNG)
  Widget _buildHierarchicalStatusView() {
    // Wenn keine Daten vorhanden sind
    if (_hierarchicalData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _hierarchicalData['summary'] ?? {};
    final totalStatusTypes = summary['totalStatusTypes'] ?? 0;

    if (totalStatusTypes == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Keine Status-Typen vorhanden',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Erstellen Sie einen neuen Status-Typ mit dem + Button.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 🌐 VERTIC UNIVERSAL SECTION
        _buildVerticUniversalSection(),

        // 🏢 FACILITIES SECTIONS
        ..._buildFacilitiesSections(),
      ],
    );
  }

  /// 🌐 VERTIC UNIVERSAL SECTION
  Widget _buildVerticUniversalSection() {
    final verticData = _hierarchicalData['vertic_universal'] ?? {};
    final statusCount = verticData['statusCount'] ?? 0;
    final gymCount = verticData['gymCount'] ?? 0;

    // Universal Status aus der echten Liste
    final universalStatusTypes = _statusTypes
        .where((s) => s.isVerticUniversal == true || s.gymId == null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.public, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vertic Universal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      '$statusCount Status-Typ${statusCount != 1 ? 'en' : ''} • $gymCount Universal Gym${gymCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Universal Status-Typen
        if (universalStatusTypes.isNotEmpty)
          ...universalStatusTypes
              .map((status) => _buildStatusCard(status, isIndented: true))
        else
          Container(
            margin: const EdgeInsets.only(left: 16, bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Keine Universal-Status vorhanden',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  /// 🏢 FACILITY SECTIONS
  List<Widget> _buildFacilitiesSections() {
    final facilitiesData = _hierarchicalData['facilities'] as List? ?? [];

    return facilitiesData.map<Widget>((facilityData) {
      final facilityId = facilityData['id'];
      final facilityName = facilityData['name'] ?? 'Unbekannte Facility';
      final facilityDescription = facilityData['description'];
      final isActive = facilityData['isActive'] ?? true;
      final gymCount = facilityData['gymCount'] ?? 0;
      final statusCount = facilityData['statusCount'] ?? 0;
      final gymsList = facilityData['gyms'] as List? ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facility Header
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.corporate_fare,
                    color: Colors.orange.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facilityName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      if (facilityDescription != null &&
                          facilityDescription.isNotEmpty)
                        Text(
                          facilityDescription,
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        '$gymCount Gym${gymCount != 1 ? 's' : ''} • $statusCount Status-Typ${statusCount != 1 ? 'en' : ''}',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Facility Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'AKTIV' : 'INAKTIV',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Facility Gyms mit ihren Status-Typen
          if (gymsList.isNotEmpty)
            ...gymsList
                .map<Widget>((gymData) => _buildGymStatusSection(gymData))
          else
            Container(
              margin: const EdgeInsets.only(left: 16, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Keine Gyms in dieser Facility vorhanden',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      );
    }).toList();
  }

  /// 🏋️ GYM STATUS SECTION
  Widget _buildGymStatusSection(Map<String, dynamic> gymData) {
    final gymId = gymData['id'];
    final gymName = gymData['name'] ?? 'Unbekanntes Gym';
    final shortCode = gymData['shortCode'] ?? '';
    final city = gymData['city'] ?? '';
    final isActive = gymData['isActive'] ?? true;
    final statusCount = gymData['statusCount'] ?? 0;

    // Finde Status-Typen für dieses Gym
    final gymStatusTypes = _statusTypes
        .where((s) => s.gymId == gymId && !s.isVerticUniversal)
        .toList();

    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 12),
      child: Column(
        children: [
          // Gym Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.fitness_center,
                    color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gymName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        '$shortCode • $city',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$statusCount Status-Typ${statusCount != 1 ? 'en' : ''}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'AKTIV' : 'INAKTIV',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status-Typen für dieses Gym
          if (gymStatusTypes.isNotEmpty)
            ...gymStatusTypes
                .map((status) => _buildStatusCard(status, isIndented: true))
          else
            Container(
              margin: const EdgeInsets.only(left: 16, top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Keine Status-Typen für dieses Gym',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 📋 STATUS CARD (WIE TICKET CARD)
  Widget _buildStatusCard(UserStatusType status, {bool isIndented = false}) {
    return Container(
      margin: EdgeInsets.only(
        left: isIndented ? 32 : 16,
        right: 16,
        bottom: 8,
      ),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: status.isVerticUniversal
                ? Colors.blue.shade100
                : Colors.green.shade100,
            child: Icon(
              Icons.verified_user,
              color: status.isVerticUniversal
                  ? Colors.blue.shade700
                  : Colors.green.shade700,
              size: 20,
            ),
          ),
          title: Text(
            status.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status.description?.isNotEmpty == true)
                Text(status.description!),
              const SizedBox(height: 4),
              Text(
                '${status.discountPercentage?.toStringAsFixed(0) ?? 0}% Rabatt' +
                    (status.requiresVerification
                        ? ' • Verifizierung erforderlich'
                        : ''),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Bearbeiten'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Löschen', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _showEditStatusDialog(status);
              } else if (value == 'delete') {
                _showDeleteConfirmation(status);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    // 🏗️ DYNAMISCHE KATEGORIEN BASIEREND AUF VERFÜGBAREN DATEN
    List<String> categories = ['Vertic Universal'];

    // 🏢 Füge alle Facilities hinzu
    for (final facility in _facilities) {
      final facilityGyms =
          _gyms.where((gym) => gym.facilityId == facility.id).toList();
      if (facilityGyms.isNotEmpty) {
        // Füge alle Gyms der Facility hinzu
        categories.addAll(facilityGyms.map((gym) => gym.name));
      }
    }

    // 🌐 Füge Universal Gyms (ohne Facility) hinzu
    final universalGyms = _gyms.where((gym) => gym.facilityId == null).toList();
    categories.addAll(universalGyms.map((gym) => gym.name));

    // 🔒 Für normale User: Nur ihr Gym anzeigen
    if (!widget.isSuperUser) {
      final userGymName = _getHallName(widget.hallId);
      categories = categories
          .where((cat) => cat == userGymName || cat == 'Vertic Universal')
          .toList();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status-Verwaltung',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
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
                    // 🎨 DYNAMISCHE ICONS BASIEREND AUF KATEGORIE-TYP
                    IconData icon;
                    Color color;

                    if (category == 'Vertic Universal') {
                      icon = Icons.public;
                      color = Colors.blue;
                    } else {
                      // 🏋️ Prüfe ob es ein Gym ist
                      final gym = _gyms.firstWhere(
                        (g) => g.name == category,
                        orElse: () => Gym(
                          name: '',
                          shortCode: '',
                          city: '',
                          isActive: true,
                          isVerticLocation: true,
                          createdAt: DateTime.now(),
                        ),
                      );

                      if (gym.facilityId != null) {
                        // 🏢 Gym gehört zu einer Facility
                        icon = Icons.corporate_fare;
                        color = Colors.orange;
                      } else {
                        // 🌐 Universal Gym
                        icon = Icons.location_on;
                        color = Colors.green;
                      }
                    }

                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                        _filterStatusTypes();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusList() {
    if (_filteredStatusTypes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_alt, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Keine Status-Typen in $_selectedCategory',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Erstelle deinen ersten Status für diese Kategorie',
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createDefaultStatusTypes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Standard-Status erstellen'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHierarchicalData, // 🔄 HIERARCHISCHE DATEN LADEN
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStatusTypes.length,
        itemBuilder: (context, index) {
          final statusType = _filteredStatusTypes[index];
          return _buildStatusCard(statusType);
        },
      ),
    );
  }

  Color _getStatusColor(UserStatusType statusType) {
    if (statusType.discountPercentage > 0) return Colors.green;
    if (statusType.requiresVerification) return Colors.orange;
    return Colors.blue;
  }

  IconData _getStatusIcon(UserStatusType statusType) {
    if (statusType.discountPercentage > 0) return Icons.discount;
    if (statusType.requiresVerification) return Icons.verified_user;
    return Icons.person;
  }

  String _getDiscountDisplayText(UserStatusType statusType) {
    if (statusType.fixedDiscountAmount != null &&
        statusType.fixedDiscountAmount! > 0) {
      return 'Rabatt: ${statusType.fixedDiscountAmount!.toStringAsFixed(2)}€';
    } else if (statusType.discountPercentage > 0) {
      return 'Rabatt: ${statusType.discountPercentage.toStringAsFixed(1)}%';
    }
    return 'Kein Rabatt';
  }

  void _showAddStatusDialog() {
    // Benachrichtige über ungespeicherte Änderungen
    widget.onUnsavedChanges?.call(true, 'Neuer Status');

    showDialog(
      context: context,
      builder: (context) => AddEditUserStatusDialog(
        selectedCategory: _selectedCategory,
        isSuperUser: widget.isSuperUser,
        hallId: widget.hallId,
        gyms: _gyms, // 🏋️ DYNAMISCHE GYM-LISTE ÜBERGEBEN
        facilities: _facilities, // 🏢 DYNAMISCHE FACILITY-LISTE ÜBERGEBEN
        onSaved: (statusType) async {
          // Änderungen gespeichert
          widget.onUnsavedChanges?.call(false, null);
          await _loadHierarchicalData(); // 🔄 DATEN NEULADEN
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${statusType.name} erfolgreich erstellt')),
          );
        },
        onCancelled: () {
          // Dialog abgebrochen
          widget.onUnsavedChanges?.call(false, null);
        },
      ),
    );
  }

  void _showEditStatusDialog(UserStatusType statusType) {
    showDialog(
      context: context,
      builder: (context) => AddEditUserStatusDialog(
        statusType: statusType,
        selectedCategory: _selectedCategory,
        isSuperUser: widget.isSuperUser,
        hallId: widget.hallId,
        gyms: _gyms, // 🏋️ DYNAMISCHE GYM-LISTE ÜBERGEBEN
        facilities: _facilities, // 🏢 DYNAMISCHE FACILITY-LISTE ÜBERGEBEN
        onSaved: (updatedStatusType) async {
          await _loadHierarchicalData(); // 🔄 DATEN NACH UPDATE NEULADEN
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${updatedStatusType.name} erfolgreich aktualisiert')),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(UserStatusType statusType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status löschen'),
        content: Text('Möchten Sie "${statusType.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteStatusType(statusType);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

// Dialog für Erstellen/Bearbeiten von Benutzer-Status mit komplexer Preisgestaltung
class AddEditUserStatusDialog extends StatefulWidget {
  final UserStatusType? statusType;
  final Function(UserStatusType) onSaved;
  final String selectedCategory;
  final bool isSuperUser;
  final int? hallId;
  final List<Gym> gyms; // 🏋️ DYNAMISCHE GYM-LISTE
  final List<Facility> facilities; // 🏢 DYNAMISCHE FACILITY-LISTE
  final Function()? onCancelled;

  const AddEditUserStatusDialog({
    super.key,
    this.statusType,
    required this.onSaved,
    required this.selectedCategory,
    required this.isSuperUser,
    required this.hallId,
    required this.gyms, // 🏋️ REQUIRED
    required this.facilities, // 🏢 REQUIRED
    this.onCancelled,
  });

  @override
  State<AddEditUserStatusDialog> createState() =>
      _AddEditUserStatusDialogState();
}

class _AddEditUserStatusDialogState extends State<AddEditUserStatusDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _validityPeriodController = TextEditingController();

  final _validityFocusNode = FocusNode();

  // Preisgestaltung-Controllers
  final _percentageDiscountController = TextEditingController();
  final _fixedDiscountController = TextEditingController();
  final _fixedPriceController = TextEditingController();

  bool _requiresVerification = false;
  bool _requiresDocumentation = false;
  bool _isLoading = false;

  // 🏋️ GYM/FACILITY-AUSWAHL
  int? _selectedGymId;
  bool _isVerticUniversal = false;

  // Preisgestaltungs-Modus
  String _pricingMode =
      'percentage'; // 'percentage', 'fixed_discount', 'fixed_price'

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

    if (widget.statusType != null) {
      _initializeWithExistingStatus();
    } else {
      // 🏗️ INITIAL-WERTE FÜR NEUEN STATUS BASIEREND AUF AKTUELLER KATEGORIE
      _initializeWithCategory();
    }
  }

  void _initializeWithExistingStatus() {
    final status = widget.statusType!;
    _nameController.text = status.name;
    _descriptionController.text = status.description;
    _validityPeriodController.text =
        status.validityPeriod == 0 ? '∞' : status.validityPeriod.toString();
    _requiresVerification = status.requiresVerification;
    _requiresDocumentation = status.requiresDocumentation;

    // 🏋️ GYM-ZUORDNUNG FÜR BEARBEITUNG
    _selectedGymId = status.gymId;
    _isVerticUniversal = status.isVerticUniversal;

    // Preisgestaltung bestimmen
    if (status.fixedDiscountAmount != null && status.fixedDiscountAmount! > 0) {
      _pricingMode = 'fixed_discount';
      _fixedDiscountController.text = status.fixedDiscountAmount.toString();
    } else if (status.discountPercentage > 0) {
      _pricingMode = 'percentage';
      _percentageDiscountController.text = status.discountPercentage.toString();
    } else {
      _pricingMode = 'percentage';
      _percentageDiscountController.text = '0';
    }
  }

  /// 🏗️ INITIALISIERUNG FÜR NEUEN STATUS BASIEREND AUF AKTUELLER KATEGORIE
  void _initializeWithCategory() {
    if (widget.selectedCategory == 'Vertic Universal') {
      _selectedGymId = null;
      _isVerticUniversal = true;
    } else {
      // 🏋️ Finde Gym basierend auf Namen
      final selectedGym = widget.gyms.firstWhere(
        (gym) => gym.name == widget.selectedCategory,
        orElse: () => widget.gyms.isNotEmpty
            ? widget.gyms.first
            : Gym(
                name: 'Unbekanntes Gym',
                shortCode: 'UNK',
                city: 'Unbekannt',
                isActive: true,
                isVerticLocation: true,
                createdAt: DateTime.now(),
              ),
      );
      _selectedGymId = selectedGym.id;
      _isVerticUniversal = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _validityPeriodController.dispose();
    _percentageDiscountController.dispose();
    _fixedDiscountController.dispose();
    _fixedPriceController.dispose();
    _validityFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveStatus() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now().toUtc();

      double discountPercentage = 0;
      double? fixedDiscountAmount = null;

      // Preisgestaltung verarbeiten
      switch (_pricingMode) {
        case 'percentage':
          discountPercentage =
              _parseEuropeanDouble(_percentageDiscountController.text) ?? 0;
          break;
        case 'fixed_discount':
          fixedDiscountAmount =
              _parseEuropeanDouble(_fixedDiscountController.text);
          break;
        case 'fixed_price':
          // TODO: Später implementieren wenn Backend erweitert wird
          break;
      }

      // 🏋️ DYNAMISCHE NAMENSGENERIERUNG UND GYM-ZUORDNUNG
      String finalName = _nameController.text.trim();

      // 🎯 Verwende die gewählten Werte aus der UI
      final gymId = _selectedGymId;
      final isVerticUniversal = _isVerticUniversal;

      // 📝 Automatische Namenserweiterung für Gym-spezifische Status
      if (!isVerticUniversal && gymId != null) {
        final selectedGym = widget.gyms.firstWhere(
          (gym) => gym.id == gymId,
          orElse: () => Gym(
            name: 'Unbekanntes Gym',
            shortCode: 'UNK',
            city: 'Unbekannt',
            isActive: true,
            isVerticLocation: true,
            createdAt: DateTime.now(),
          ),
        );

        // Füge Gym-Namen hinzu wenn nicht bereits vorhanden
        if (!finalName.toLowerCase().contains(selectedGym.name.toLowerCase())) {
          finalName = '$finalName ${selectedGym.name}';
        }
      }

      final statusType = UserStatusType(
        id: widget.statusType?.id,
        name: finalName,
        description: _descriptionController.text.trim(),
        discountPercentage: discountPercentage,
        fixedDiscountAmount: fixedDiscountAmount,
        requiresVerification: _requiresVerification,
        requiresDocumentation: _requiresDocumentation,
        validityPeriod: _validityPeriodController.text.isEmpty ||
                _validityPeriodController.text == '∞'
            ? 0
            : int.parse(_validityPeriodController.text),
        gymId: gymId,
        isVerticUniversal: isVerticUniversal,
        createdAt: widget.statusType?.createdAt ?? now,
        updatedAt: now,
      );

      // Backend-Calls für Save/Update
      UserStatusType? savedStatusType;
      if (widget.statusType == null) {
        savedStatusType = await client.userStatus.createStatusType(statusType);
      } else {
        savedStatusType = await client.userStatus.updateStatusType(statusType);
      }

      if (savedStatusType != null) {
        widget.onSaved(savedStatusType);
        Navigator.of(context).pop();
      } else {
        throw Exception('Fehler beim Speichern des Status-Typs');
      }
    } catch (e) {
      String errorMessage = 'Fehler beim Speichern: $e';

      // Spezielle Behandlung für Duplicate-Key Fehler
      if (e.toString().contains('duplicate key value') &&
          e.toString().contains('user_status_type_name_unique_idx')) {
        errorMessage = 'Ein Status mit diesem Namen existiert bereits. '
            'Bitte wählen Sie einen anderen Namen.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 🏋️ GYM-AUSWAHL SEKTION FÜR SUPERUSER
  Widget _buildGymSelectionSection() {
    // 🏗️ Erstelle Kategorien: Vertic Universal + alle Gyms gruppiert nach Facility
    final List<DropdownMenuItem<String>> categoryItems = [];

    // 🌐 Vertic Universal Option
    categoryItems.add(
      const DropdownMenuItem(
        value: 'vertic_universal',
        child: Row(
          children: [
            Icon(Icons.public, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text('Vertic Universal'),
          ],
        ),
      ),
    );

    // 🏢 Facilities und ihre Gyms
    for (final facility in widget.facilities) {
      final facilityGyms =
          widget.gyms.where((gym) => gym.facilityId == facility.id).toList();
      for (final gym in facilityGyms) {
        categoryItems.add(
          DropdownMenuItem(
            value: 'gym_${gym.id}',
            child: Row(
              children: [
                const Icon(Icons.corporate_fare,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('${gym.name} (${facility.name})'),
              ],
            ),
          ),
        );
      }
    }

    // 🌐 Universal Gyms (ohne Facility)
    final universalGyms =
        widget.gyms.where((gym) => gym.facilityId == null).toList();
    for (final gym in universalGyms) {
      categoryItems.add(
        DropdownMenuItem(
          value: 'gym_${gym.id}',
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(gym.name),
            ],
          ),
        ),
      );
    }

    // 🎯 Bestimme aktuellen Wert
    String currentValue = 'vertic_universal';
    if (!_isVerticUniversal && _selectedGymId != null) {
      currentValue = 'gym_$_selectedGymId';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gültigkeitsbereich',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Wo ist dieser Status gültig?',
            hintText: 'Wählen Sie den Gültigkeitsbereich',
          ),
          items: categoryItems,
          onChanged: (value) {
            setState(() {
              if (value == 'vertic_universal') {
                _isVerticUniversal = true;
                _selectedGymId = null;
              } else if (value?.startsWith('gym_') == true) {
                _isVerticUniversal = false;
                _selectedGymId = int.tryParse(value!.substring(4));
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte wählen Sie einen Gültigkeitsbereich';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
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
              widget.statusType == null
                  ? 'Neuen Benutzer-Status erstellen'
                  : 'Benutzer-Status bearbeiten',
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
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Status-Name *',
                          border: OutlineInputBorder(),
                          hintText: 'z.B. Student, Senior, VIP',
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
                          hintText:
                              'Beschreibung der Zielgruppe und Voraussetzungen',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🏋️ GYM-ZUORDNUNG SEKTION (nur für SuperUser)
                      if (widget.isSuperUser) _buildGymSelectionSection(),

                      // Gültigkeit
                      TextFormField(
                        controller: _validityPeriodController,
                        focusNode: _validityFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Gültigkeit (Tage)',
                          border: OutlineInputBorder(),
                          hintText: '∞ = unbegrenzt gültig',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value != '∞') {
                            final days = int.tryParse(value);
                            if (days == null || days < 0) {
                              return 'Muss positiv oder ∞ sein';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Preisgestaltung Section
                      Text(
                        'Preisgestaltung',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),

                      // Preisgestaltungs-Modus Radio Buttons
                      Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Prozentualer Rabatt'),
                            subtitle:
                                const Text('z.B. 20% Rabatt auf alle Tickets'),
                            value: 'percentage',
                            groupValue: _pricingMode,
                            onChanged: (value) {
                              setState(() {
                                _pricingMode = value!;
                              });
                            },
                          ),
                          if (_pricingMode == 'percentage') ...[
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 32, right: 16),
                              child: TextFormField(
                                controller: _percentageDiscountController,
                                decoration: const InputDecoration(
                                  labelText: 'Rabatt in %',
                                  border: OutlineInputBorder(),
                                  suffixText: '%',
                                  hintText: 'z.B. 20,5 oder 20.5',
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (value) {
                                  if (_pricingMode == 'percentage' &&
                                      (value == null || value.isEmpty)) {
                                    return 'Rabatt-Prozentsatz erforderlich';
                                  }
                                  if (value != null && value.isNotEmpty) {
                                    final percentage =
                                        _parseEuropeanDouble(value);
                                    if (percentage == null) {
                                      return 'Ungültiger Wert (nutzen Sie . oder ,)';
                                    }
                                    if (percentage < 0 || percentage > 100) {
                                      return 'Gültiger Wert zwischen 0-100';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          RadioListTile<String>(
                            title: const Text('Fixer Rabatt'),
                            subtitle:
                                const Text('z.B. -1,50€ auf alle Tickets'),
                            value: 'fixed_discount',
                            groupValue: _pricingMode,
                            onChanged: (value) {
                              setState(() {
                                _pricingMode = value!;
                              });
                            },
                          ),
                          if (_pricingMode == 'fixed_discount') ...[
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 32, right: 16),
                              child: TextFormField(
                                controller: _fixedDiscountController,
                                decoration: const InputDecoration(
                                  labelText: 'Rabatt in €',
                                  border: OutlineInputBorder(),
                                  suffixText: '€',
                                  hintText: 'z.B. 1,50 oder 1.50',
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (value) {
                                  if (_pricingMode == 'fixed_discount' &&
                                      (value == null || value.isEmpty)) {
                                    return 'Rabatt-Betrag erforderlich';
                                  }
                                  if (_pricingMode == 'fixed_discount' &&
                                      value != null &&
                                      value.isNotEmpty) {
                                    final amount = _parseEuropeanDouble(value);
                                    if (amount == null) {
                                      return 'Ungültiger Betrag (nutzen Sie . oder ,)';
                                    }
                                    if (amount < 0) {
                                      return 'Rabatt muss positiv sein';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          RadioListTile<String>(
                            title: const Text('Spezielle Preise'),
                            subtitle: const Text(
                                'Individuelle Preise pro Ticket-Typ'),
                            value: 'fixed_price',
                            groupValue: _pricingMode,
                            onChanged: (value) {
                              setState(() {
                                _pricingMode = value!;
                              });
                            },
                          ),
                          if (_pricingMode == 'fixed_price') ...[
                            Container(
                              margin:
                                  const EdgeInsets.only(left: 32, right: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                border: Border.all(color: Colors.blue.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.info, color: Colors.blue),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Spezielle Preise werden später über eine erweiterte Preismatrix konfiguriert.',
                                    style: TextStyle(color: Colors.blue),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Verifikation Section
                      Text(
                        'Verifikation & Dokumentation',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),

                      CheckboxListTile(
                        title: const Text('Verifikation erforderlich'),
                        subtitle: const Text(
                            'Status muss vom Personal bestätigt werden'),
                        value: _requiresVerification,
                        onChanged: (value) {
                          setState(() {
                            _requiresVerification = value ?? false;
                          });
                        },
                      ),

                      CheckboxListTile(
                        title: const Text('Dokumentation erforderlich'),
                        subtitle: const Text(
                            'Nachweis-Dokumente müssen vorgelegt werden'),
                        value: _requiresDocumentation,
                        onChanged: (value) {
                          setState(() {
                            _requiresDocumentation = value ?? false;
                          });
                        },
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
                  onPressed:
                      widget.onCancelled ?? () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveStatus,
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
                          widget.statusType == null ? 'Erstellen' : 'Speichern',
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
