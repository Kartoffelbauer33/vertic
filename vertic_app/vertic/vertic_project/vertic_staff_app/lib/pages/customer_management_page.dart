import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:intl/intl.dart';
import '../widgets/customer_management_section.dart';

/// Aktivitäts-Log-Eintrag für die Historie
class ActivityLogEntry {
  final String type; // 'ticket', 'status', 'note', 'system'
  final String title;
  final String description;
  final DateTime timestamp;
  final String? staffName;
  final IconData icon;
  final Color color;
  final Map<String, dynamic>? metadata;

  ActivityLogEntry({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.staffName,
    required this.icon,
    required this.color,
    this.metadata,
  });
}

class CustomerManagementPage extends StatefulWidget {
  final int? hallId; // Hallen-ID des aktuellen Staff-Members
  final bool isSuperUser; // Ist der aktuelle Benutzer ein SuperUser?

  const CustomerManagementPage({
    super.key,
    this.hallId,
    this.isSuperUser = false,
  });

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage>
    with TickerProviderStateMixin {
  // Data Management
  List<AppUser> _allUsers = [];
  List<AppUser> _filteredUsers = [];
  AppUser? _selectedUser;
  List<UserStatus> _userStatuses = [];
  List<Ticket> _userTickets = [];
  List<UserStatusType> _availableStatusTypes = [];
  String? _userNote; // Einzelne Notiz pro Benutzer
  List<Gym> _availableGyms = [];
  Gym? _currentUserGym;

  // Search & Filter - Vereinfacht durch universelle Suche
  // 🗑️ DEPRECATED: Nur noch für Kompatibilität - neue Suche verwendet CustomerManagementSection
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String _selectedSearchType = 'all';

  // Loading States
  bool _isLoading = true;
  bool _isLoadingUserDetails = false;
  String? _errorMessage;

  // Tab Controller for user details
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Initialisiert alle notwendigen Daten
  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([_loadUsers(), _loadGyms(), _loadStatusTypes()]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Daten: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Lädt alle Benutzer
  Future<void> _loadUsers() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final users = await client.user.getAllUsers(limit: 2000, offset: 0);

      // Sortiere Benutzer nach Nachname, dann Vorname
      users.sort((a, b) {
        final lastNameComparison = a.lastName.compareTo(b.lastName);
        if (lastNameComparison != 0) return lastNameComparison;
        return a.firstName.compareTo(b.firstName);
      });

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
      });

      debugPrint('✅ ${users.length} Benutzer geladen');
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Benutzer: $e');
      rethrow;
    }
  }

  /// Lädt verfügbare Gyms aus der Datenbank
  Future<void> _loadGyms() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final gyms = await client.gym.getAllGyms();

      setState(() {
        _availableGyms = gyms;

        // Finde das aktuelle Gym des Staff-Members
        if (widget.hallId != null) {
          _currentUserGym = gyms.firstWhere(
            (gym) => gym.id == widget.hallId,
            orElse: () => Gym(
              id: widget.hallId!,
              name: 'Unbekanntes Gym',
              shortCode: 'UNK',
              city: 'Unbekannt',
              createdAt: DateTime.now(),
            ),
          );
        }
      });

      debugPrint('✅ ${gyms.length} Gyms geladen');
      if (_currentUserGym != null) {
        debugPrint(
          '✅ Aktuelles Gym: ${_currentUserGym!.name} (${_currentUserGym!.city})',
        );
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Gyms: $e');
      setState(() {
        _availableGyms = [];
        _currentUserGym = null;
      });
    }
  }

  /// Lädt verfügbare Status-Typen (mit Hallen-Berechtigung)
  Future<void> _loadStatusTypes() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final allStatusTypes = await client.userStatus.getAllStatusTypes();

      // Filtere Status-Typen basierend auf Berechtigung
      List<UserStatusType> filteredStatusTypes;

      if (widget.isSuperUser) {
        // SuperUser sehen alle Status-Typen
        filteredStatusTypes = allStatusTypes;
        debugPrint(
          '✅ SuperUser: Alle ${allStatusTypes.length} Status-Typen geladen',
        );
      } else if (widget.hallId != null) {
        // Hall-Admin sieht nur eigene Halle + Vertic Universal
        filteredStatusTypes = allStatusTypes.where((status) {
          return status.gymId == widget.hallId || status.isVerticUniversal;
        }).toList();
        debugPrint(
          '✅ Hall-Admin (Halle ${widget.hallId}): ${filteredStatusTypes.length} von ${allStatusTypes.length} Status-Typen geladen',
        );
      } else {
        // Fallback: Nur Vertic Universal Status
        filteredStatusTypes = allStatusTypes.where((status) {
          return status.isVerticUniversal;
        }).toList();
        debugPrint(
          '✅ Standard: ${filteredStatusTypes.length} Vertic Universal Status-Typen geladen',
        );
      }

      setState(() {
        _availableStatusTypes = filteredStatusTypes;
      });

      debugPrint(
        '✅ ${filteredStatusTypes.length} Status-Typen für Anzeige verfügbar',
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Status-Typen: $e');
      setState(() {
        _availableStatusTypes = [];
      });
    }
  }

  /// Lädt Details für einen ausgewählten Benutzer
  Future<void> _loadUserDetails(AppUser user) async {
    setState(() {
      _selectedUser = user;
      _isLoadingUserDetails = true;
      _userStatuses = [];
      _userTickets = [];
      _userNote = null;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);

      // Debug-Print: User-ID und E-Mail
      debugPrint(
        'Staff-App: Lade Details für User-ID: \\${user.id}, Email: \\${user.email}',
      );

      // Parallel laden für bessere Performance
      final results = await Future.wait([
        client.userStatus.getUserStatuses(user.id!),
        client.ticket.getValidUserTickets(user.id!),
        _loadUserNote(user.id!),
      ]);

      setState(() {
        _userStatuses = results[0] as List<UserStatus>;
        _userTickets = results[1] as List<Ticket>;
        _userNote = results[2] as String?;
        _isLoadingUserDetails = false;
      });

      // Debug-Print: Anzahl Tickets
      debugPrint(
        'Staff-App: Für User-ID: \\${user.id}, Email: \\${user.email} wurden \\${_userTickets.length} Tickets geladen',
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der User Details: $e');
      setState(() {
        _isLoadingUserDetails = false;
      });
    }
  }

  /// 🗑️ DEPRECATED: Kundensuche erfolgt jetzt über CustomerManagementSection Widget
  @deprecated
  void _performSearch(String searchText) {
    // Leere Implementierung - neue Suche verwendet UniversalSearchEndpoint
  }

  /// Formatiert Datum für Anzeige
  String _formatDate(DateTime? date) {
    if (date == null) return 'Nicht verfügbar';
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  /// Formatiert Alter
  String _formatAge(DateTime? birthDate) {
    if (birthDate == null) return 'Unbekannt';
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return '$age Jahre';
  }

  /// Status-Name anhand ID finden
  String _getStatusName(int statusTypeId) {
    final statusType = _availableStatusTypes.firstWhere(
      (type) => type.id == statusTypeId,
      orElse: () => UserStatusType(
        id: statusTypeId,
        name: 'Unbekannt',
        description: '',
        discountPercentage: 0,
        requiresVerification: false,
        requiresDocumentation: false,
        validityPeriod: 0,
        createdAt: DateTime.now(),
      ),
    );
    return statusType.name;
  }

  /// Gym-Name anhand ID finden
  String _getGymName(int? gymId) {
    if (gymId == null) return 'Vertic Universal';

    final gym = _availableGyms.firstWhere(
      (g) => g.id == gymId,
      orElse: () => Gym(
        id: gymId,
        name: 'Unbekanntes Gym',
        shortCode: 'UNK',
        city: 'Unbekannt',
        createdAt: DateTime.now(),
      ),
    );

    return '${gym.name} - ${gym.city}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Kundendaten werden geladen...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeData,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kundenverwaltung'),
            if (!widget.isSuperUser && _currentUserGym != null)
              Text(
                '${_currentUserGym!.name} - ${_currentUserGym!.city}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeData,
            tooltip: 'Daten aktualisieren',
          ),
        ],
      ),
      body: Row(
        children: [
          // Linke Spalte: Suche + Kundenliste
          _buildCustomerList(),

          // Rechte Spalte: Kundendetails
          _buildCustomerDetails(),
        ],
      ),
    );
  }

  /// Erstellt die Kundenliste mit Suchfunktion
  Widget _buildCustomerList() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Suchbereich
          _buildSearchSection(),

          // Kundenliste
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Wählen Sie einen Kunden aus der Suche aus',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildCustomerListItem(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Erstellt den Suchbereich - NEUE UNIVERSELLE SUCHE
  Widget _buildSearchSection() {
    return CustomerManagementSection(
      onCustomerSelected: (customer) {
        setState(() {
          _selectedUser = customer;
        });
        _loadUserDetails(customer);
      },
    );
  }

  /// Erstellt ein Kundenlisten-Element
  Widget _buildCustomerListItem(AppUser user) {
    final isSelected = _selectedUser?.id == user.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[400],
          radius: 20,
          child: Text(
            '${user.firstName[0]}${user.lastName[0]}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          '${user.firstName} ${user.lastName}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email ?? user.parentEmail ?? 'Keine E-Mail',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.badge, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'ID: ${user.id}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const Spacer(),
                Text(
                  _formatDate(user.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
        ),
        onTap: () => _loadUserDetails(user),
      ),
    );
  }

  /// Erstellt den Kundendetails-Bereich
  Widget _buildCustomerDetails() {
    return Expanded(
      child: _selectedUser == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bitte wählen Sie einen Kunden aus',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nutzen Sie die Suchfunktion links, um Kunden zu finden',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : _buildUserDetailsContent(),
    );
  }

  /// Erstellt den Inhalt der Kundendetails
  Widget _buildUserDetailsContent() {
    return Column(
      children: [
        // Header mit Kundeninfo
        _buildUserHeader(),

        // Tab Bar
        TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profil'),
            Tab(icon: Icon(Icons.confirmation_number), text: 'Tickets'),
            Tab(icon: Icon(Icons.verified_user), text: 'Status'),
            Tab(icon: Icon(Icons.history), text: 'Historie'),
          ],
        ),

        // Tab Content
        Expanded(
          child: _isLoadingUserDetails
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Kundendetails werden geladen...'),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildTicketsTab(),
                    _buildStatusTab(),
                    _buildHistoryTab(),
                  ],
                ),
        ),
      ],
    );
  }

  /// Erstellt den Benutzer-Header
  Widget _buildUserHeader() {
    final user = _selectedUser!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            radius: 30,
            child: Text(
              '${user.firstName[0]}${user.lastName[0]}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Benutzer-Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? user.parentEmail ?? 'Keine E-Mail',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip('ID: ${user.id}', Icons.badge),
                    const SizedBox(width: 8),
                    _buildInfoChip(_formatAge(user.birthDate), Icons.cake),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      user.isBlocked == true ? 'Gesperrt' : 'Aktiv',
                      user.isBlocked == true ? Icons.block : Icons.check_circle,
                      color: user.isBlocked == true ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Aktionen
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showEditUserDialog(),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Bearbeiten'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showUserActionsDialog(),
                icon: const Icon(Icons.more_horiz, size: 18),
                label: const Text('Aktionen'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Erstellt ein Info-Chip
  Widget _buildInfoChip(String text, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Erstellt den Profil-Tab
  Widget _buildProfileTab() {
    final user = _selectedUser!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Persönliche Daten', Icons.person),
          _buildProfileSection([
            _buildProfileItem('Vorname', user.firstName),
            _buildProfileItem('Nachname', user.lastName),
            _buildProfileItem(
              'Geburtsdatum',
              user.birthDate != null
                  ? DateFormat('dd.MM.yyyy').format(
                      DateTime(
                        user.birthDate!.year,
                        user.birthDate!.month,
                        user.birthDate!.day,
                      ),
                    )
                  : 'Nicht angegeben',
            ),
            _buildProfileItem('Alter', _formatAge(user.birthDate)),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Kontaktdaten', Icons.contact_mail),
          _buildProfileSection([
            _buildProfileItem('E-Mail', user.email ?? 'Nicht angegeben'),
            _buildProfileItem('Telefon', user.phoneNumber ?? 'Nicht angegeben'),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Adresse', Icons.location_on),
          _buildProfileSection([
            _buildProfileItem('Straße', user.address ?? 'Nicht angegeben'),
            _buildProfileItem('Stadt', user.city ?? 'Nicht angegeben'),
            _buildProfileItem('PLZ', user.postalCode ?? 'Nicht angegeben'),
          ]),

          // Notiz-Sektion (falls vorhanden)
          if (_userNote != null) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Interne Notiz', Icons.note),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userNote!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showEditNoteDialog(),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Notiz bearbeiten'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.note_add, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keine Notiz vorhanden',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditNoteDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Notiz hinzufügen'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionHeader('Account-Details', Icons.account_circle),
          _buildProfileSection([
            _buildProfileItem('Registriert', _formatDate(user.createdAt)),
            _buildProfileItem(
              'Letzte Aktualisierung',
              _formatDate(user.updatedAt),
            ),
            _buildProfileItem(
              'E-Mail verifiziert',
              user.isEmailVerified == true ? 'Ja' : 'Nein',
            ),
            _buildProfileItem(
              'Account Status',
              user.isBlocked == true ? 'Gesperrt' : 'Aktiv',
            ),
            if (user.blockedReason != null)
              _buildProfileItem('Sperrgrund', user.blockedReason!),
          ]),
        ],
      ),
    );
  }

  /// Erstellt den Tickets-Tab
  Widget _buildTicketsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionHeader(
                'Gekaufte Tickets',
                Icons.confirmation_number,
              ),
              const Spacer(),
              Text(
                '${_userTickets.length} Tickets',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (_userTickets.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keine Tickets vorhanden',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ..._userTickets.map((ticket) => _buildTicketCard(ticket)).toList(),
        ],
      ),
    );
  }

  /// Erstellt eine Ticket-Karte
  Widget _buildTicketCard(Ticket ticket) {
    final isValid = _isTicketValid(ticket);
    final statusColor = isValid ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getTicketIcon(ticket), color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket #${ticket.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ticket-Typ ID: ${ticket.ticketTypeId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isValid ? 'GÜLTIG' : 'UNGÜLTIG',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTicketInfo(
                    'Preis',
                    '${ticket.price.toStringAsFixed(2)} €',
                  ),
                ),
                Expanded(
                  child: _buildTicketInfo(
                    'Gekauft',
                    DateFormat('dd.MM.yyyy').format(ticket.purchaseDate),
                  ),
                ),
                Expanded(
                  child: _buildTicketInfo(
                    'Gültig bis',
                    DateFormat('dd.MM.yyyy').format(ticket.expiryDate),
                  ),
                ),
              ],
            ),
            if (ticket.remainingPoints != null) ...[
              const SizedBox(height: 8),
              _buildTicketInfo(
                'Verbleibende Punkte',
                '${ticket.remainingPoints}/${ticket.initialPoints ?? 'N/A'}',
              ),
            ],
            if (ticket.activatedDate != null) ...[
              const SizedBox(height: 8),
              _buildTicketInfo(
                'Aktiviert',
                DateFormat('dd.MM.yyyy HH:mm').format(ticket.activatedDate!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Erstellt den Status-Tab
  Widget _buildStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionHeader('Benutzer-Status', Icons.verified_user),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddStatusDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Status hinzufügen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_userStatuses.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.verified_user_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keine Status-Einträge vorhanden',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ..._userStatuses.map((status) => _buildStatusCard(status)).toList(),
        ],
      ),
    );
  }

  /// Erstellt eine Status-Karte
  Widget _buildStatusCard(UserStatus status) {
    final statusName = _getStatusName(status.statusTypeId);
    final isActive = status.expiryDate?.isAfter(DateTime.now()) ?? false;
    final statusColor = status.isVerified
        ? (isActive ? Colors.green : Colors.orange)
        : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.isVerified ? Icons.verified : Icons.pending,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status ID: ${status.statusTypeId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (!status.isVerified) ...[
                  ElevatedButton(
                    onPressed: () => _verifyStatus(status, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Verifizieren'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _verifyStatus(status, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Ablehnen'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusInfo(
                    'Beantragt',
                    DateFormat('dd.MM.yyyy').format(status.createdAt),
                  ),
                ),
                Expanded(
                  child: _buildStatusInfo(
                    'Gültig bis',
                    status.expiryDate != null
                        ? DateFormat('dd.MM.yyyy').format(status.expiryDate!)
                        : 'Nicht verfügbar',
                  ),
                ),
                Expanded(
                  child: _buildStatusInfo(
                    'Status',
                    status.isVerified
                        ? (isActive ? 'Aktiv' : 'Abgelaufen')
                        : 'Ungeprüft',
                  ),
                ),
              ],
            ),
            if (status.notes != null && status.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status.notes!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Erstellt den Historie-Tab
  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Aktivitäts-Historie', Icons.history),
          const SizedBox(height: 16),
          if (_selectedUser == null)
            const Center(child: Text('Kein Benutzer ausgewählt'))
          else
            FutureBuilder<List<ActivityLogEntry>>(
              future: _loadUserHistory(_selectedUser!.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Fehler beim Laden der Historie: ${snapshot.error}',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ],
                    ),
                  );
                }

                final historyEntries = snapshot.data ?? [];

                if (historyEntries.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Keine Aktivitäten gefunden',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: historyEntries
                      .map((entry) => _buildHistoryEntry(entry))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildStatusInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  // Helper Methods
  IconData _getTicketIcon(Ticket ticket) {
    if (ticket.remainingPoints != null) {
      return Icons.credit_card;
    } else if (ticket.subscriptionStatus != null) {
      return Icons.card_membership;
    } else {
      return Icons.confirmation_number;
    }
  }

  bool _isTicketValid(Ticket ticket) {
    final now = DateTime.now();

    // Punktebasierte Tickets: gültig wenn Punkte übrig
    if (ticket.remainingPoints != null) {
      return ticket.remainingPoints! > 0;
    }

    // Abonnements: gültig wenn aktiv und nicht abgelaufen
    if (ticket.subscriptionStatus == 'ACTIVE') {
      return ticket.nextBillingDate == null ||
          ticket.nextBillingDate!.isAfter(now);
    }

    // Einzeltickets: Spezielle Logik für tägliche Aktivierung
    if (ticket.activatedForDate == null) {
      // Noch nie aktiviert - gültig (kann aktiviert werden)
      return true;
    } else {
      // Aktiviert - gültig wenn für heute aktiviert
      return ticket.activatedForDate!.year == now.year &&
          ticket.activatedForDate!.month == now.month &&
          ticket.activatedForDate!.day == now.day;
    }
  }

  // Dialog Methods
  Future<void> _showEditUserDialog() async {
    final user = _selectedUser!;
    final formKey = GlobalKey<FormState>();

    // Initialisiere Controller mit aktuellen Werten
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final emailController = TextEditingController(text: user.email ?? '');
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    final addressController = TextEditingController(text: user.address ?? '');
    final cityController = TextEditingController(text: user.city ?? '');
    final postalCodeController = TextEditingController(
      text: user.postalCode ?? '',
    );
    final notesController = TextEditingController();

    // Verwende lokales Datum ohne UTC conversion um Zeitzone-Probleme zu vermeiden
    // Das verhindert das "einen Tag verschieben" Problem
    DateTime? selectedBirthDate = user.birthDate != null
        ? DateTime(
            user.birthDate!.year,
            user.birthDate!.month,
            user.birthDate!.day,
          )
        : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit, color: Colors.blue),
              const SizedBox(width: 8),
              Text('${user.firstName} ${user.lastName} bearbeiten'),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Persönliche Daten
                    const Text(
                      'Persönliche Daten',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'Vorname *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty == true ? 'Pflichtfeld' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nachname *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty == true ? 'Pflichtfeld' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Geburtsdatum
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedBirthDate ??
                              DateTime.now().subtract(
                                const Duration(days: 18 * 365),
                              ),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          // Verwende das lokale Datum ohne Zeitzone-Conversion
                          // um das "einen Tag verschieben" Problem zu vermeiden
                          setDialogState(
                            () => selectedBirthDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            ),
                          );
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Geburtsdatum',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          selectedBirthDate != null
                              ? DateFormat(
                                  'dd.MM.yyyy',
                                ).format(selectedBirthDate!)
                              : 'Nicht ausgewählt',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kontaktdaten
                    const Text(
                      'Kontaktdaten',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value?.isNotEmpty == true &&
                            !RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value!)) {
                          return 'Ungültige E-Mail-Adresse';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Adresse
                    const Text(
                      'Adresse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Straße & Hausnummer',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'PLZ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'Stadt',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Notizen
                    const Text(
                      'Interne Notizen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notizen zu den Änderungen...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _updateUser(
                    user,
                    firstNameController.text,
                    lastNameController.text,
                    emailController.text.isEmpty ? null : emailController.text,
                    null,
                    phoneController.text.isEmpty ? null : phoneController.text,
                    addressController.text.isEmpty
                        ? null
                        : addressController.text,
                    cityController.text.isEmpty ? null : cityController.text,
                    postalCodeController.text.isEmpty
                        ? null
                        : postalCodeController.text,
                    selectedBirthDate,
                    notesController.text.isEmpty ? null : notesController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUserActionsDialog() async {
    final user = _selectedUser!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 20,
              child: Text(
                '${user.firstName[0]}${user.lastName[0]}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user.firstName} ${user.lastName}'),
                  Text(
                    'ID: ${user.id}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Account-Verwaltung
              ListTile(
                leading: Icon(
                  user.isBlocked == true ? Icons.lock_open : Icons.lock,
                  color: user.isBlocked == true ? Colors.green : Colors.red,
                ),
                title: Text(
                  user.isBlocked == true
                      ? 'Account entsperren'
                      : 'Account sperren',
                ),
                subtitle: Text(
                  user.isBlocked == true
                      ? 'Zugang wiederherstellen'
                      : 'Zugang blockieren',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showBlockUserDialog(user);
                },
              ),
              const Divider(),

              // E-Mail senden
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('E-Mail senden'),
                subtitle: const Text('Nachricht an Kunden senden'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSendEmailDialog(user);
                },
              ),

              // Notiz hinzufügen
              ListTile(
                leading: const Icon(Icons.note_add, color: Colors.green),
                title: const Text('Notiz hinzufügen'),
                subtitle: const Text('Interne Notiz erstellen'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddNoteDialog(user);
                },
              ),
              const Divider(),

              // Gefährliche Aktionen
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Account löschen'),
                subtitle: const Text('ACHTUNG: Irreversibel!'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteUserDialog(user);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddStatusDialog() async {
    if (_availableStatusTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Keine Status-Typen verfügbar. Bitte laden Sie zuerst die Status-Typen.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = _selectedUser!;
    final formKey = GlobalKey<FormState>();

    UserStatusType? selectedStatusType;
    final notesController = TextEditingController();
    DateTime? expiryDate;
    bool requiresVerification = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Status hinzufügen'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Für: ${user.firstName} ${user.lastName}'),
                  const SizedBox(height: 16),

                  // Status-Typ auswählen
                  DropdownButtonFormField<UserStatusType>(
                    value: selectedStatusType,
                    decoration: const InputDecoration(
                      labelText: 'Status-Typ *',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableStatusTypes
                        .map(
                          (statusType) => DropdownMenuItem(
                            value: statusType,
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          statusType.name,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        if (statusType.description.isNotEmpty)
                                          Text(
                                            statusType.description,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    isDense: false,
                    isExpanded: true,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatusType = value;
                        requiresVerification =
                            value?.requiresVerification ?? false;

                        // Automatisches Ablaufdatum basierend auf Gültigkeitsdauer
                        if (value?.validityPeriod != null &&
                            value!.validityPeriod > 0) {
                          expiryDate = DateTime.now().add(
                            Duration(days: value.validityPeriod),
                          );
                        }
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Bitte Status-Typ auswählen' : null,
                  ),
                  const SizedBox(height: 16),

                  // Ablaufdatum
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            expiryDate ??
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (date != null) {
                        setDialogState(() => expiryDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Gültig bis',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        expiryDate != null
                            ? DateFormat('dd.MM.yyyy').format(expiryDate!)
                            : 'Kein Ablaufdatum (unbegrenzt)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notizen
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notizen',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Info über Verifikation
                  if (requiresVerification)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dieser Status erfordert eine manuelle Verifikation.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _addUserStatus(
                    user,
                    selectedStatusType!,
                    expiryDate,
                    notesController.text.isEmpty ? null : notesController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  // Weitere CRM Dialog-Methoden
  Future<void> _showBlockUserDialog(AppUser user) async {
    final reasonController = TextEditingController();
    final isCurrentlyBlocked = user.isBlocked == true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCurrentlyBlocked ? Icons.lock_open : Icons.lock,
              color: isCurrentlyBlocked ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isCurrentlyBlocked ? 'Account entsperren' : 'Account sperren'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user.firstName} ${user.lastName} (ID: ${user.id})'),
              const SizedBox(height: 16),
              if (isCurrentlyBlocked) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aktueller Sperrgrund:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(user.blockedReason ?? 'Kein Grund angegeben'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Der Account wird sofort entsperrt und der Kunde kann sich wieder anmelden.',
                ),
              ] else ...[
                const Text(
                  'ACHTUNG: Der Account wird sofort gesperrt und der Kunde kann sich nicht mehr anmelden.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Sperrgrund *',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty == true
                      ? 'Sperrgrund ist erforderlich'
                      : null,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!isCurrentlyBlocked && reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sperrgrund ist erforderlich')),
                );
                return;
              }

              await _toggleUserBlockStatus(
                user,
                !isCurrentlyBlocked,
                isCurrentlyBlocked ? null : reasonController.text.trim(),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyBlocked ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isCurrentlyBlocked ? 'Entsperren' : 'Sperren'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSendEmailDialog(AppUser user) async {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String emailType = 'info';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.email, color: Colors.blue),
              SizedBox(width: 8),
              Text('E-Mail senden'),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('An: ${user.firstName} ${user.lastName}'),
                Text(
                  'E-Mail: ${user.email ?? user.parentEmail ?? 'Keine E-Mail verfügbar'}',
                ),
                const SizedBox(height: 16),

                // E-Mail-Typ
                DropdownButtonFormField<String>(
                  value: emailType,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail-Typ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'info',
                      child: Text('ℹ️ Information'),
                    ),
                    DropdownMenuItem(
                      value: 'reminder',
                      child: Text('⏰ Erinnerung'),
                    ),
                    DropdownMenuItem(
                      value: 'warning',
                      child: Text('⚠️ Warnung'),
                    ),
                    DropdownMenuItem(
                      value: 'welcome',
                      child: Text('👋 Willkommen'),
                    ),
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text('✏️ Benutzerdefiniert'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      emailType = value!;
                      // Automatische Betreff-Vorschläge
                      switch (emailType) {
                        case 'reminder':
                          subjectController.text =
                              'Erinnerung - Ihr Ticket läuft bald ab';
                          break;
                        case 'warning':
                          subjectController.text =
                              'Wichtige Information zu Ihrem Account';
                          break;
                        case 'welcome':
                          subjectController.text =
                              'Willkommen in unserer Boulderhalle!';
                          break;
                        default:
                          subjectController.text = '';
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Betreff
                TextFormField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Betreff *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Nachricht
                Expanded(
                  child: TextFormField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Nachricht *',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    expands: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (subjectController.text.trim().isEmpty ||
                    messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Betreff und Nachricht sind erforderlich'),
                    ),
                  );
                  return;
                }

                await _sendEmailToUser(
                  user,
                  subjectController.text.trim(),
                  messageController.text.trim(),
                  emailType,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Senden'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddNoteDialog(AppUser user) async {
    final noteController = TextEditingController();
    String noteType = 'general';
    String priority = 'normal';
    String? tags;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.note_add, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Notiz hinzufügen für ${user.firstName} ${user.lastName}'),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notiz-Typ
                  DropdownButtonFormField<String>(
                    value: noteType,
                    decoration: const InputDecoration(
                      labelText: 'Notiz-Typ',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'general',
                        child: Text('📝 Allgemein'),
                      ),
                      DropdownMenuItem(
                        value: 'important',
                        child: Text('⚠️ Wichtig'),
                      ),
                      DropdownMenuItem(
                        value: 'warning',
                        child: Text('🚨 Warnung'),
                      ),
                      DropdownMenuItem(
                        value: 'positive',
                        child: Text('✅ Positiv'),
                      ),
                      DropdownMenuItem(
                        value: 'complaint',
                        child: Text('😠 Beschwerde'),
                      ),
                      DropdownMenuItem(
                        value: 'system',
                        child: Text('🔧 System'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => noteType = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Priorität
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priorität',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('🟢 Niedrig')),
                      DropdownMenuItem(
                        value: 'normal',
                        child: Text('🔵 Normal'),
                      ),
                      DropdownMenuItem(value: 'high', child: Text('🟠 Hoch')),
                      DropdownMenuItem(
                        value: 'urgent',
                        child: Text('🔴 Dringend'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => priority = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notiz-Inhalt
                  Expanded(
                    child: TextFormField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Notiz-Inhalt *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      validator: (value) => value?.isEmpty == true
                          ? 'Notiz-Inhalt ist erforderlich'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags (optional)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tags (komma-getrennt)',
                      border: OutlineInputBorder(),
                      hintText: 'z.B. klanung, vertrag, zahlung',
                    ),
                    onChanged: (value) => tags = value.isEmpty ? null : value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (noteController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notiz-Inhalt ist erforderlich'),
                    ),
                  );
                  return;
                }

                await _addUserNote(
                  user,
                  noteController.text.trim(),
                  noteType,
                  priority: priority,
                  tags: tags,
                );
                Navigator.of(context).pop();

                // Reload notes
                await _loadUserDetails(user);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Notiz speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteUserDialog(AppUser user) async {
    final confirmController = TextEditingController();
    final confirmText = 'LÖSCHEN BESTÄTIGEN';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Account dauerhaft löschen'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ ACHTUNG: IRREVERSIBLE AKTION!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Das Löschen des Accounts kann NICHT rückgängig gemacht werden!',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Account: ${user.firstName} ${user.lastName} (ID: ${user.id})',
              ),
              const SizedBox(height: 16),
              const Text('Was wird gelöscht:'),
              const Text('• Alle persönlichen Daten'),
              const Text('• Alle Tickets und deren Historie'),
              const Text('• Alle Status-Einträge'),
              const Text('• Alle internen Notizen'),
              const SizedBox(height: 16),
              Text('Geben Sie "$confirmText" ein, um zu bestätigen:'),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'LÖSCHEN BESTÄTIGEN',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (confirmController.text.trim() != confirmText) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bestätigung stimmt nicht überein'),
                  ),
                );
                return;
              }

              await _deleteUser(user);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DAUERHAFT LÖSCHEN'),
          ),
        ],
      ),
    );
  }

  // Backend CRM-Methoden
  Future<void> _updateUser(
    AppUser user,
    String firstName,
    String lastName,
    String? email,
    String? parentEmail,
    String? phoneNumber,
    String? address,
    String? city,
    String? postalCode,
    DateTime? birthDate,
    String? notes,
  ) async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      // Erstelle UserUpdateRequest
      // Für birthDate: Explizit als UTC setzen um Zeitzone-Verschiebung zu vermeiden
      DateTime? utcBirthDate;
      if (birthDate != null) {
        utcBirthDate = DateTime.utc(
          birthDate.year,
          birthDate.month,
          birthDate.day,
          12, // Mittag UTC um sicher zu gehen dass es nicht in vorherigen Tag rutscht
        );
      }

      final updateRequest = UserUpdateRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        parentEmail: parentEmail,
        phoneNumber: phoneNumber,
        address: address,
        city: city,
        postalCode: postalCode,
        birthDate: utcBirthDate,
        updateReason: notes,
        staffId: 1, // TODO: Echte Staff-ID aus Session
        staffName: 'Staff User', // TODO: Echter Staff-Name aus Session
      );

      final updatedUser = await client.user.updateUser(user.id!, updateRequest);

      if (updatedUser != null) {
        // Reload data
        await _loadUsers();
        await _loadUserDetails(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Benutzer erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Update fehlgeschlagen');
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Aktualisieren des Benutzers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Aktualisieren: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleUserBlockStatus(
    AppUser user,
    bool blocked,
    String? reason,
  ) async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      await client.user.blockUser(user.id!, blocked, reason ?? '');

      // Notiz hinzufügen
      await _addUserNote(
        user,
        blocked
            ? 'Account gesperrt: ${reason ?? 'Kein Grund angegeben'}'
            : 'Account entsperrt',
        blocked ? 'warning' : 'positive',
      );

      // Reload data
      await _loadUsers();
      if (_selectedUser?.id == user.id) {
        await _loadUserDetails(user);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blocked ? 'Benutzer gesperrt' : 'Benutzer entsperrt'),
          backgroundColor: blocked ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Sperren/Entsperren: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendEmailToUser(
    AppUser user,
    String subject,
    String message,
    String emailType,
  ) async {
    try {
      // TODO: Implementiere E-Mail-Versand Endpoint
      // final client = Provider.of<Client>(context, listen: false);
      // await client.email.sendToUser(user.id!, subject, message, emailType);

      // Temporäre Notiz hinzufügen
      await _addUserNote(user, 'E-Mail gesendet: $subject', 'general');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-Mail gesendet (Demo-Modus)'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint('❌ Fehler beim E-Mail-Versand: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim E-Mail-Versand: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addUserNote(
    AppUser user,
    String note,
    String noteType, {
    String priority = 'normal',
    String? tags,
  }) async {
    try {
      // Temporär deaktiviert - createNote Methode wird überarbeitet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notiz-Funktion wird gerade überarbeitet...'),
          backgroundColor: Colors.orange,
        ),
      );

      // TODO: Re-aktivieren nach Backend-Update
      // final client = Provider.of<Client>(context, listen: false);
      // final createdNote = await client.userNote.createNote(
      //   user.id!,
      //   noteType,
      //   note,
      //   staffId: 1,
      //   staffName: 'Staff User',
      //   priority: priority,
      //   tags: tags,
      // );
    } catch (e) {
      debugPrint('❌ Fehler beim Hinzufügen der Notiz: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Hinzufügen der Notiz: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addUserStatus(
    AppUser user,
    UserStatusType statusType,
    DateTime? expiryDate,
    String? notes,
  ) async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      // Erstelle UserStatus-Anfrage (wird als unverified erstellt)
      final userStatus = UserStatus(
        userId: user.id!,
        statusTypeId: statusType.id!,
        isVerified:
            false, // Wird durch requestStatus automatisch auf false gesetzt
        notes: notes,
        createdAt: DateTime.now().toUtc(),
      );

      // 1. Status-Anfrage erstellen
      final createdStatus = await client.userStatus.requestStatus(userStatus);
      debugPrint(
        '✅ Status-Anfrage erstellt: ID ${createdStatus?.id}, isVerified: ${createdStatus?.isVerified}',
      );

      if (createdStatus != null) {
        // 2. Status sofort verifizieren (da Staff-Mitglied)
        final verifiedStatus = await client.userStatus.verifyStatus(
          createdStatus.id!,
          1, // TODO: Echte Staff-ID aus Session
          notes,
          expiryDate?.toUtc(),
        );
        debugPrint(
          '✅ Status verifiziert: ID ${verifiedStatus?.id}, isVerified: ${verifiedStatus?.isVerified}',
        );

        if (verifiedStatus != null) {
          // Zusätzlich eine Notiz hinzufügen für die Historie
          await _addUserNote(
            user,
            'Status "${statusType.name}" hinzugefügt${notes != null ? ': $notes' : ''}',
            'important',
          );

          // User Details neu laden um die neue Status-Liste zu zeigen
          await _loadUserDetails(user);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Status "${statusType.name}" erfolgreich hinzugefügt',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Status-Verifizierung fehlgeschlagen');
        }
      } else {
        throw Exception('Status-Erstellung fehlgeschlagen');
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Hinzufügen des Status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Hinzufügen des Status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      await client.user.deleteUser(user.id!);

      // Reload data und Auswahl aufheben
      await _loadUsers();
      setState(() {
        _selectedUser = null;
        _userStatuses = [];
        _userTickets = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Benutzer ${user.firstName} ${user.lastName} wurde gelöscht',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Löschen des Benutzers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyStatus(UserStatus status, bool verify) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      // TODO: staffId dynamisch setzen, sobald Login vorhanden
      await client.userStatus.verifyStatus(
        status.id!,
        1, // <-- Dummy staffId
        verify ? null : 'Abgelehnt durch Staff', // Notiz bei Ablehnung
        null, // Optional: Ablaufdatum
      );

      // Reload user statuses
      await _loadUserDetails(_selectedUser!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(verify ? 'Status verifiziert' : 'Status abgelehnt'),
          backgroundColor: verify ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Aktualisieren: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Lädt die vollständige Historie eines Benutzers
  Future<List<ActivityLogEntry>> _loadUserHistory(int userId) async {
    final List<ActivityLogEntry> historyEntries = [];

    try {
      final client = Provider.of<Client>(context, listen: false);

      // 1. Tickets laden
      final tickets = await client.ticket.getUserTickets(userId);
      for (final ticket in tickets) {
        historyEntries.add(
          ActivityLogEntry(
            type: 'ticket',
            title: 'Ticket gekauft',
            description:
                'Ticket-ID: ${ticket.id} für ${ticket.price.toStringAsFixed(2)}€',
            timestamp: ticket.purchaseDate,
            icon: Icons.confirmation_number,
            color: Colors.blue,
            metadata: {'ticketId': ticket.id, 'price': ticket.price},
          ),
        );

        if (ticket.activatedDate != null) {
          historyEntries.add(
            ActivityLogEntry(
              type: 'ticket',
              title: 'Ticket aktiviert',
              description:
                  'Ticket-ID: ${ticket.id} aktiviert${ticket.activatedForDate != null ? ' für ${DateFormat('dd.MM.yyyy').format(ticket.activatedForDate!)}' : ''}',
              timestamp: ticket.activatedDate!,
              icon: Icons.verified,
              color: Colors.green,
              metadata: {'ticketId': ticket.id},
            ),
          );
        }
      }

      // 2. Status-Änderungen und Notizen werden nicht mehr in der Historie angezeigt
      // Diese Informationen sind in den separaten Tabs verfügbar

      // 4. Account-Erstellung (falls verfügbar)
      if (_selectedUser != null) {
        historyEntries.add(
          ActivityLogEntry(
            type: 'system',
            title: 'Account erstellt',
            description: 'Benutzeraccount wurde registriert',
            timestamp: _selectedUser!.createdAt,
            icon: Icons.person_add,
            color: Colors.purple,
          ),
        );
      }

      // Nach Datum sortieren (neueste zuerst)
      historyEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der User-Historie: $e');
      throw Exception('Fehler beim Laden der Historie: $e');
    }

    return historyEntries;
  }

  /// Erstellt einen Historie-Eintrag
  Widget _buildHistoryEntry(ActivityLogEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry.color.withValues(alpha: 0.2),
          child: Icon(entry.icon, color: entry.color, size: 18),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(entry.description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(entry.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                if (entry.staffName != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.person, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    entry.staffName!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  /// Lädt eine einzelne Notiz für einen Benutzer
  Future<String?> _loadUserNote(int userId) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final notes = await client.userNote.getUserNotes(
        userId,
        limit: 1,
        offset: 0,
        includeInternal: true,
      );

      if (notes.isNotEmpty) {
        return notes.first.content;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Notiz: $e');
      return null;
    }
  }

  /// Zeigt Dialog zum Bearbeiten der Notiz
  void _showEditNoteDialog() {
    final TextEditingController noteController = TextEditingController(
      text: _userNote ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _userNote != null ? 'Notiz bearbeiten' : 'Notiz hinzufügen',
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: noteController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Notiz',
              hintText: 'Interne Notiz für diesen Kunden...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          if (_userNote != null)
            TextButton(
              onPressed: () async {
                await _deleteUserNote();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Löschen'),
            ),
          ElevatedButton(
            onPressed: () async {
              final newNote = noteController.text.trim();
              if (newNote.isNotEmpty) {
                await _saveUserNote(newNote);
              } else {
                await _deleteUserNote();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  /// Speichert oder aktualisiert die Benutzer-Notiz
  Future<void> _saveUserNote(String noteContent) async {
    if (_selectedUser == null) return;

    // Temporär deaktiviert - Note-System wird überarbeitet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notiz-System wird gerade überarbeitet...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Löscht die Benutzer-Notiz
  Future<void> _deleteUserNote() async {
    if (_selectedUser == null) return;

    // Temporär deaktiviert - Note-System wird überarbeitet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notiz-System wird gerade überarbeitet...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
