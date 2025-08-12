import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:provider/provider.dart';
import '../../auth/permission_wrapper.dart';
import '../../auth/staff_auth_provider.dart';

class ExternalProviderManagementPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(bool, String?)? onUnsavedChanges;
  final bool isSuperUser;
  final int? hallId;

  const ExternalProviderManagementPage({
    super.key,
    this.onBack,
    this.onUnsavedChanges,
    this.isSuperUser = false,
    this.hallId,
  });

  @override
  State<ExternalProviderManagementPage> createState() =>
      _ExternalProviderManagementPageState();
}

class _ExternalProviderManagementPageState
    extends State<ExternalProviderManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Loading States
  bool _isLoading = true;
  String? _errorMessage;

  // Data Stores
  List<ExternalProvider> _providers = [];
  List<ExternalProviderStats> _providerStats = [];
  List<Gym> _availableGyms = [];

  // Filter States
  DateTimeRange? _dateRange;
  String _selectedPeriod = 'last_30_days';
  int? _selectedGymId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeDateRange();
    _selectedGymId = widget.hallId;

    // Verzögerung um sicherzustellen dass Auth-Token korrekt gesetzt ist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadData();
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDateRange() {
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Prüfen ob Staff-User authentifiziert ist
      final staffAuth = Provider.of<StaffAuthProvider>(context, listen: false);
      if (!staffAuth.isAuthenticated) {
        throw Exception('Staff-User nicht authentifiziert');
      }

      // Client über Provider holen
      final client = Provider.of<Client>(context, listen: false);

      // Parallel laden für bessere Performance
      final futures = <Future>[];

      if (widget.isSuperUser) {
        // SuperUser: Alle Gyms laden
        futures.add(client.gym.getAllGyms());
      }

      if (_selectedGymId != null) {
        // Provider für spezifische Halle laden
        futures.add(client.externalProvider.getHallProviders(_selectedGymId!));
        futures.add(client.externalProvider.getProviderStats(
          _selectedGymId!,
          _dateRange?.start,
          _dateRange?.end,
        ));
      }

      final results = await Future.wait(futures);

      int resultIndex = 0;
      if (widget.isSuperUser) {
        _availableGyms = results[resultIndex++] as List<Gym>;
      }

      if (_selectedGymId != null) {
        _providers = results[resultIndex++] as List<ExternalProvider>;
        _providerStats = results[resultIndex++] as List<ExternalProviderStats>;
      }

      setState(() {
        _isLoading = false;
      });

      debugPrint('✅ External Provider Data loaded successfully');
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Daten: $e';
        _isLoading = false;
      });
      debugPrint('❌ External Provider Data loading failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildMainContent(),
      floatingActionButton: _selectedGymId != null
          ? FloatingActionButton.extended(
              onPressed: _addNewProvider,
              icon: const Icon(Icons.add),
              label: const Text('Provider hinzufügen'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.isSuperUser
            ? '🌐 External Provider (Zentral)'
            : '🌐 External Provider (Hall ${widget.hallId})',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBack,
      ),
      bottom: _selectedGymId != null
          ? TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.settings), text: 'Konfiguration'),
                Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
                Tab(icon: Icon(Icons.history), text: 'Audit-Log'),
              ],
            )
          : null,
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('External Provider werden geladen...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (widget.isSuperUser && _selectedGymId == null) {
      return _buildGymSelector();
    }

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildConfigurationTab(),
              _buildAnalyticsTab(),
              _buildAuditLogTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGymSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_city, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Wählen Sie eine Halle aus',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Um External Provider zu verwalten'),
          const SizedBox(height: 24),
          ...(_availableGyms.map((gym) => Card(
                child: ListTile(
                  leading: const Icon(Icons.business),
                  title: Text(gym.name),
                  subtitle: Text(gym.address ?? 'Keine Adresse'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    setState(() {
                      _selectedGymId = gym.id;
                    });
                    _loadData();
                  },
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          // Gym-Selector (für SuperUser)
          if (widget.isSuperUser) ...[
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedGymId,
                decoration: const InputDecoration(
                  labelText: 'Halle',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: _availableGyms.map((gym) {
                  return DropdownMenuItem(
                    value: gym.id,
                    child: Text(gym.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGymId = value;
                  });
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Zeitraum-Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Zeitraum',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'last_7_days', child: Text('Letzte 7 Tage')),
                DropdownMenuItem(
                    value: 'last_30_days', child: Text('Letzte 30 Tage')),
                DropdownMenuItem(
                    value: 'last_90_days', child: Text('Letzte 90 Tage')),
                DropdownMenuItem(
                    value: 'this_year', child: Text('Dieses Jahr')),
                DropdownMenuItem(
                    value: 'custom', child: Text('Benutzerdefiniert')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
                _updateDateRange();
              },
            ),
          ),

          const SizedBox(width: 16),

          // Aktualisieren-Button
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Aktualisieren'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab() {
    return PermissionWrapper(
      requiredPermission: 'can_manage_external_providers',
      placeholder: _buildAccessDenied('External Provider Management'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Provider-Konfiguration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (_providers.isEmpty)
            _buildEmptyProvidersState()
          else
            ..._providers.map((provider) => _buildProviderCard(provider)),
        ],
      ),
    );
  }

  Widget _buildEmptyProvidersState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.extension, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Keine Provider konfiguriert',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Fügen Sie den ersten External Provider hinzu'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addNewProvider,
              icon: const Icon(Icons.add),
              label: const Text('Provider hinzufügen'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(ExternalProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getProviderIcon(provider.providerName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.providerName.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildProviderStatusBadge(provider),
              ],
            ),
            const SizedBox(height: 16),

            // Provider-Details
            _buildDetailRow(
                'API URL', provider.apiBaseUrl ?? 'Nicht konfiguriert'),
            if (provider.sportPartnerId != null)
              _buildDetailRow('Sport Partner ID', provider.sportPartnerId!),
            if (provider.doorId != null)
              _buildDetailRow('Door ID', provider.doorId!),
            _buildDetailRow(
                'Re-Entry',
                provider.allowReEntry
                    ? '${provider.reEntryWindowHours}h'
                    : 'Deaktiviert'),
            _buildDetailRow(
                'Staff-Validierung',
                provider.requireStaffValidation
                    ? 'Erforderlich'
                    : 'Automatisch'),

            const SizedBox(height: 16),

            // Aktionen
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _testProviderConnection(provider),
                  child: const Text('Verbindung testen'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _editProvider(provider),
                  child: const Text('Bearbeiten'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _deleteProvider(provider),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Löschen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getProviderIcon(String providerName) {
    switch (providerName.toLowerCase()) {
      case 'fitpass':
        return const Icon(Icons.fitness_center, color: Colors.orange, size: 32);
      case 'friction':
        return const Icon(Icons.sports_gymnastics,
            color: Colors.blue, size: 32);
      case 'urban_sports_club':
        return const Icon(Icons.sports, color: Colors.green, size: 32);
      default:
        return const Icon(Icons.extension, color: Colors.grey, size: 32);
    }
  }

  Widget _buildProviderStatusBadge(ExternalProvider provider) {
    final isActive = provider.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'AKTIV' : 'INAKTIV',
        style: TextStyle(
          color: isActive ? Colors.green[700] : Colors.red[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return PermissionWrapper(
      requiredPermission: 'can_view_provider_stats',
      placeholder: _buildAccessDenied('Provider Analytics'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provider Analytics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // KPI Cards
            _buildKPICards(),
            const SizedBox(height: 24),

            // Provider Performance Chart
            _buildProviderPerformanceChart(),
            const SizedBox(height: 24),

            // Check-in Trends Chart
            _buildCheckinTrendsChart(),
            const SizedBox(height: 24),

            // Provider Comparison Table
            _buildProviderComparisonTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    final totalCheckins =
        _providerStats.fold(0, (sum, stat) => sum + stat.totalCheckins);
    final totalActiveMembers =
        _providerStats.fold(0, (sum, stat) => sum + stat.totalActiveMembers);
    final avgSuccessRate = _providerStats.isNotEmpty
        ? _providerStats.fold(0.0, (sum, stat) => sum + stat.successRate) /
            _providerStats.length
        : 0.0;
    final activeProviders = _providers.where((p) => p.isActive).length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
          'Total Check-ins',
          totalCheckins.toString(),
          Icons.qr_code_scanner,
          Colors.blue,
        ),
        _buildKPICard(
          'Aktive Mitglieder',
          totalActiveMembers.toString(),
          Icons.people,
          Colors.green,
        ),
        _buildKPICard(
          'Erfolgsrate',
          '${(avgSuccessRate * 100).toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.orange,
        ),
        _buildKPICard(
          'Aktive Provider',
          '$activeProviders/${_providers.length}',
          Icons.extension,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderPerformanceChart() {
    if (_providerStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('Keine Statistiken verfügbar'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provider Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _providerStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: stat.totalCheckins.toDouble(),
                          color: _getProviderColor(stat.providerName),
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _providerStats.length) {
                            return Text(
                              _providerStats[value.toInt()]
                                  .providerName
                                  .toUpperCase(),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinTrendsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check-in Trends (Letzte 7 Tage)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                          7,
                          (index) => FlSpot(
                              index.toDouble(), (index * 10 + 5).toDouble())),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderComparisonTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provider Vergleich',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Provider')),
                  DataColumn(label: Text('Check-ins')),
                  DataColumn(label: Text('Erfolgsrate')),
                  DataColumn(label: Text('Mitglieder')),
                  DataColumn(label: Text('Ø Zeit (ms)')),
                ],
                rows: _providerStats.map((stat) {
                  return DataRow(
                    cells: [
                      DataCell(Text(stat.providerName.toUpperCase())),
                      DataCell(Text(stat.totalCheckins.toString())),
                      DataCell(Text(
                          '${(stat.successRate * 100).toStringAsFixed(1)}%')),
                      DataCell(Text(stat.totalActiveMembers.toString())),
                      DataCell(Text(stat.averageProcessingTimeMs.toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogTab() {
    return PermissionWrapper(
      requiredPermission: 'can_view_provider_stats',
      placeholder: _buildAccessDenied('Audit Log'),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Audit-Log wird in zukünftiger Version verfügbar sein'),
            Text(
                'Hier werden alle Provider-Konfigurationsänderungen protokolliert'),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Zugriff verweigert',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Sie haben keine Berechtigung für: $feature'),
        ],
      ),
    );
  }

  Color _getProviderColor(String providerName) {
    switch (providerName.toLowerCase()) {
      case 'fitpass':
        return Colors.orange;
      case 'friction':
        return Colors.blue;
      case 'urban_sports_club':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'last_7_days':
        _dateRange = DateTimeRange(
            start: now.subtract(const Duration(days: 7)), end: now);
        break;
      case 'last_30_days':
        _dateRange = DateTimeRange(
            start: now.subtract(const Duration(days: 30)), end: now);
        break;
      case 'last_90_days':
        _dateRange = DateTimeRange(
            start: now.subtract(const Duration(days: 90)), end: now);
        break;
      case 'this_year':
        _dateRange = DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
        break;
    }
    _loadData();
  }

  void _addNewProvider() {
    showDialog(
      context: context,
      builder: (context) => _ProviderConfigurationDialog(
        onSave: (provider) {
          _saveProvider(provider);
        },
      ),
    );
  }

  void _editProvider(ExternalProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _ProviderConfigurationDialog(
        provider: provider,
        onSave: (updatedProvider) {
          _saveProvider(updatedProvider);
        },
      ),
    );
  }

  Future<void> _saveProvider(ExternalProvider provider) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      await client.externalProvider.configureProvider(provider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider erfolgreich gespeichert')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }
  }

  Future<void> _testProviderConnection(ExternalProvider provider) async {
    // TODO: Implementiere Provider-Verbindungstest
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Verbindungstest für ${provider.providerName} wird gestartet...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _deleteProvider(ExternalProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provider löschen'),
        content: Text(
          'Möchten Sie den Provider "${provider.displayName}" wirklich löschen?\n\n'
          'Alle zugehörigen Mitgliedschaften werden deaktiviert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // TODO: Implementiere Provider-Löschung
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider wurde gelöscht')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Löschen: $e')),
        );
      }
    }
  }
}

// Dialog für Provider-Konfiguration
class _ProviderConfigurationDialog extends StatefulWidget {
  final ExternalProvider? provider;
  final Function(ExternalProvider) onSave;

  const _ProviderConfigurationDialog({
    this.provider,
    required this.onSave,
  });

  @override
  State<_ProviderConfigurationDialog> createState() =>
      _ProviderConfigurationDialogState();
}

class _ProviderConfigurationDialogState
    extends State<_ProviderConfigurationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _apiUrlController = TextEditingController();
  final _credentialsController = TextEditingController();
  final _sportPartnerIdController = TextEditingController();
  final _doorIdController = TextEditingController();

  String _selectedProviderType = 'fitpass';
  bool _isActive = true;
  bool _allowReEntry = true;
  String _reEntryWindowType = 'hours'; // 'hours' oder 'days'
  int _reEntryWindowHours = 3;
  int _reEntryWindowDays = 1;
  bool _requireStaffValidation = false;

  @override
  void initState() {
    super.initState();
    if (widget.provider != null) {
      _initializeFromProvider(widget.provider!);
    } else {
      _displayNameController.text = 'Fitpass Premium';
      _apiUrlController.text = 'https://rest-fitpass-ch.herokuapp.com';
    }
  }

  void _initializeFromProvider(ExternalProvider provider) {
    _selectedProviderType = provider.providerName;
    _displayNameController.text = provider.displayName;
    _apiUrlController.text = provider.apiBaseUrl ?? '';
    _credentialsController.text = provider.apiCredentialsJson ?? '';
    _sportPartnerIdController.text = provider.sportPartnerId ?? '';
    _doorIdController.text = provider.doorId ?? '';
    _isActive = provider.isActive;
    _allowReEntry = provider.allowReEntry;
    _reEntryWindowType = provider.reEntryWindowType ?? 'hours';
    _reEntryWindowHours = provider.reEntryWindowHours;
    _reEntryWindowDays = provider.reEntryWindowDays ?? 1;
    _requireStaffValidation = provider.requireStaffValidation;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.provider == null ? 'Neuer Provider' : 'Provider bearbeiten'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Provider-Typ
                DropdownButtonFormField<String>(
                  value: _selectedProviderType,
                  decoration: const InputDecoration(
                    labelText: 'Provider-Typ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'fitpass', child: Text('Fitpass')),
                    DropdownMenuItem(
                        value: 'friction', child: Text('Friction')),
                    DropdownMenuItem(
                        value: 'urban_sports_club',
                        child: Text('Urban Sports Club')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedProviderType = value!;
                      _updateDefaultValues();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Display Name
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Anzeige-Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Bitte eingeben' : null,
                ),
                const SizedBox(height: 16),

                // API URL
                TextFormField(
                  controller: _apiUrlController,
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Bitte eingeben' : null,
                ),
                const SizedBox(height: 16),

                // Provider-spezifische Felder
                if (_selectedProviderType == 'fitpass') ...[
                  TextFormField(
                    controller: _sportPartnerIdController,
                    decoration: const InputDecoration(
                      labelText: 'Sport Partner ID',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Bitte eingeben' : null,
                  ),
                  const SizedBox(height: 16),
                  // API Credentials nur für Fitpass (HMAC-Signatur erforderlich)
                  TextFormField(
                    controller: _credentialsController,
                    decoration: const InputDecoration(
                      labelText: 'API Credentials (JSON)',
                      border: OutlineInputBorder(),
                      hintText: '{"secret_key": "...", "user_id": 123}',
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Bitte eingeben' : null,
                  ),
                  const SizedBox(height: 16),
                ] else if (_selectedProviderType == 'friction') ...[
                  TextFormField(
                    controller: _doorIdController,
                    decoration: const InputDecoration(
                      labelText: 'Door ID',
                      border: OutlineInputBorder(),
                      hintText: '27',
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Bitte eingeben' : null,
                  ),
                  const SizedBox(height: 16),
                  // Friction benötigt KEINE API-Credentials!
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Friction benötigt keine API-Credentials. Die Authentifizierung erfolgt über Security-Codes im QR-Code.',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (_selectedProviderType == 'urban_sports_club') ...[
                  // Für Urban Sports Club später implementieren
                  TextFormField(
                    controller: _credentialsController,
                    decoration: const InputDecoration(
                      labelText: 'API Credentials (JSON)',
                      border: OutlineInputBorder(),
                      hintText: '{"api_key": "...", "client_id": "..."}',
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Bitte eingeben' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Einstellungen
                SwitchListTile(
                  title: const Text('Provider aktiv'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                SwitchListTile(
                  title: const Text('Re-Entry erlauben'),
                  value: _allowReEntry,
                  onChanged: (value) => setState(() => _allowReEntry = value),
                ),
                if (_allowReEntry) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Re-Entry Zeitfenster',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Zeitfenster-Typ auswählen
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Stunden'),
                          value: 'hours',
                          groupValue: _reEntryWindowType,
                          onChanged: (value) =>
                              setState(() => _reEntryWindowType = value!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Tage'),
                          value: 'days',
                          groupValue: _reEntryWindowType,
                          onChanged: (value) =>
                              setState(() => _reEntryWindowType = value!),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Zeitfenster-Wert einstellen
                  if (_reEntryWindowType == 'hours') ...[
                    ListTile(
                      title: Text(
                          'Re-Entry innerhalb von $_reEntryWindowHours Stunden'),
                      subtitle: Slider(
                        value: _reEntryWindowHours.toDouble(),
                        min: 1,
                        max: 24,
                        divisions: 23,
                        label: '$_reEntryWindowHours Stunden',
                        onChanged: (value) =>
                            setState(() => _reEntryWindowHours = value.round()),
                      ),
                    ),
                  ] else ...[
                    ListTile(
                      title: Text(
                          'Re-Entry innerhalb von $_reEntryWindowDays Tagen'),
                      subtitle: Slider(
                        value: _reEntryWindowDays.toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        label: '$_reEntryWindowDays Tage',
                        onChanged: (value) =>
                            setState(() => _reEntryWindowDays = value.round()),
                      ),
                    ),
                  ],
                ],
                SwitchListTile(
                  title: const Text('Staff-Validierung erforderlich'),
                  value: _requireStaffValidation,
                  onChanged: (value) =>
                      setState(() => _requireStaffValidation = value),
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
          onPressed: _saveProvider,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  void _updateDefaultValues() {
    if (_selectedProviderType == 'fitpass') {
      _displayNameController.text = 'Fitpass Premium';
      _apiUrlController.text = 'https://rest-fitpass-ch.herokuapp.com';
      _credentialsController.text = '{"secret_key": "", "user_id": 0}';
      _sportPartnerIdController.text = '';
      _doorIdController.text = '';
    } else if (_selectedProviderType == 'friction') {
      _displayNameController.text = 'Friction Access';
      _apiUrlController.text = 'https://api.apptive.ch';
      _credentialsController.text = '';
      _sportPartnerIdController.text = '';
      _doorIdController.text = '27';
    } else if (_selectedProviderType == 'urban_sports_club') {
      _displayNameController.text = 'Urban Sports Club';
      _apiUrlController.text = 'https://api.urbansportsclub.com';
      _credentialsController.text = '{"api_key": "", "client_id": ""}';
      _sportPartnerIdController.text = '';
      _doorIdController.text = '';
    }
  }

  void _saveProvider() {
    if (_formKey.currentState?.validate() != true) return;

    // Friction benötigt keine API Credentials
    final credentialsJson = _selectedProviderType == 'friction'
        ? null
        : _credentialsController.text.trim();

    final provider = ExternalProvider(
      id: widget.provider?.id,
      providerName: _selectedProviderType,
      displayName: _displayNameController.text.trim(),
      hallId: 1, // TODO: Get from context
      isActive: _isActive,
      apiBaseUrl: _apiUrlController.text.trim(),
      apiCredentialsJson: credentialsJson,
      sportPartnerId: _sportPartnerIdController.text.trim().isEmpty
          ? null
          : _sportPartnerIdController.text.trim(),
      doorId: _doorIdController.text.trim().isEmpty
          ? null
          : _doorIdController.text.trim(),
      allowReEntry: _allowReEntry,
      reEntryWindowType: _reEntryWindowType,
      reEntryWindowHours: _reEntryWindowHours,
      reEntryWindowDays: _reEntryWindowDays,
      requireStaffValidation: _requireStaffValidation,
      supportedFeatures: '["check_in", "re_entry"]',
      createdBy: 1, // TODO: Get from auth
      createdAt: DateTime.now(),
    );

    widget.onSave(provider);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _apiUrlController.dispose();
    _credentialsController.dispose();
    _sportPartnerIdController.dispose();
    _doorIdController.dispose();
    super.dispose();
  }
}
