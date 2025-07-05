import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../auth/permission_wrapper.dart';
import '../../auth/staff_auth_provider.dart';

class ReportsAnalyticsPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(bool, String?)? onUnsavedChanges;
  final bool isSuperUser;
  final int? hallId;

  const ReportsAnalyticsPage({
    super.key,
    this.onBack,
    this.onUnsavedChanges,
    this.isSuperUser = false,
    this.hallId,
  });

  @override
  State<ReportsAnalyticsPage> createState() => _ReportsAnalyticsPageState();
}

class _ReportsAnalyticsPageState extends State<ReportsAnalyticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Loading States
  bool _isLoading = true;
  String? _errorMessage;

  // Data Stores
  List<Ticket> _allTickets = [];
  List<AppUser> _allUsers = [];
  List<Gym> _allGyms = [];
  Map<String, double> _revenueByDay = {};
  Map<String, int> _ticketsByType = {};
  Map<String, int> _usersByStatus = {};

  // Filter States
  DateTimeRange? _dateRange;
  String _selectedPeriod = 'last_30_days';
  int? _selectedGymId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeDateRange();

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

      // Client über Provider holen um sicherzustellen dass Auth-Token gesetzt ist
      final client = Provider.of<Client>(context, listen: false);

      // Debug: Auth-Status prüfen
      debugPrint(
          '🔍 Loading Analytics Data - Auth Status: ${staffAuth.isAuthenticated}');
      debugPrint('🔍 Staff User: ${staffAuth.currentStaffUser?.id}');

      // Parallel laden für bessere Performance
      final futures = await Future.wait([
        client.ticket.getAllTickets(),
        client.user.getAllUsers(limit: 1000, offset: 0),
        client.gym.getAllGyms(),
      ]);

      _allTickets = futures[0] as List<Ticket>;
      _allUsers = futures[1] as List<AppUser>;
      _allGyms = futures[2] as List<Gym>;

      // Analytics berechnen
      _calculateAnalytics();

      setState(() {
        _isLoading = false;
      });

      debugPrint('✅ Analytics Data loaded successfully');
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Daten: $e';
        _isLoading = false;
      });
      debugPrint('❌ Analytics Data loading failed: $e');
    }
  }

  void _calculateAnalytics() {
    _revenueByDay.clear();
    _ticketsByType.clear();
    _usersByStatus.clear();

    // Filter Tickets nach Zeitraum
    final filteredTickets = _allTickets.where((ticket) {
      if (_dateRange == null) return true;
      return ticket.createdAt.isAfter(_dateRange!.start) &&
          ticket.createdAt
              .isBefore(_dateRange!.end.add(const Duration(days: 1)));
    }).toList();

    // Umsatz pro Tag berechnen
    for (final ticket in filteredTickets) {
      final dayKey = '${ticket.createdAt.day}.${ticket.createdAt.month}';
      _revenueByDay[dayKey] = (_revenueByDay[dayKey] ?? 0) + ticket.price;
    }

    // Tickets nach Typ gruppieren - Vereinfachte Gruppierung nach Preis
    for (final ticket in filteredTickets) {
      final type = 'Ticket ${ticket.price.toStringAsFixed(2)}€';
      _ticketsByType[type] = (_ticketsByType[type] ?? 0) + 1;
    }

    // Users nach Status gruppieren - Vereinfachte Gruppierung
    for (final user in _allUsers) {
      final status = user.primaryStatusId != null ? 'Premium' : 'Standard';
      _usersByStatus[status] = (_usersByStatus[status] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : Column(
                  children: [
                    _buildFilterSection(),
                    Expanded(child: _buildTabView()),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.isSuperUser ? '📊 Zentral-Analytics' : '📊 Hallen-Analytics',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBack,
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.trending_up), text: 'Umsatz'),
          Tab(icon: Icon(Icons.confirmation_number), text: 'Tickets'),
          Tab(icon: Icon(Icons.people), text: 'Benutzer'),
          Tab(icon: Icon(Icons.extension), text: 'External'),
          Tab(icon: Icon(Icons.download), text: 'Export'),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analytics werden berechnet...'),
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

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              // Zeitraum-Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Zeitraum',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
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
                      _updateDateRange();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Gym-Filter (nur für SuperUser)
              if (widget.isSuperUser) ...[
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedGymId,
                    decoration: const InputDecoration(
                      labelText: 'Standort',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Alle Standorte')),
                      ..._allGyms.map((gym) => DropdownMenuItem(
                            value: gym.id,
                            child: Text(gym.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGymId = value;
                        _calculateAnalytics();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Aktualisieren-Button
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Aktualisieren'),
              ),
            ],
          ),

          // Datum-Range (wenn custom ausgewählt)
          if (_selectedPeriod == 'custom') ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range),
                    const SizedBox(width: 8),
                    Text(_dateRange != null
                        ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                        : 'Zeitraum auswählen'),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildRevenueTab(),
        _buildTicketsTab(),
        _buildUsersTab(),
        _buildExternalProvidersTab(),
        _buildExportTab(),
      ],
    );
  }

  Widget _buildRevenueTab() {
    return PermissionWrapper(
      requiredPermission: 'can_view_financial_reports',
      placeholder: _buildAccessDenied('Finanzberichte'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards
            _buildKPICards(),
            const SizedBox(height: 24),

            // Umsatz-Chart
            _buildRevenueChart(),
            const SizedBox(height: 24),

            // Top-Performer Tabelle
            _buildTopPerformersTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    final totalRevenue = _revenueByDay.values.fold(0.0, (a, b) => a + b);
    final avgDailyRevenue =
        _revenueByDay.isNotEmpty ? totalRevenue / _revenueByDay.length : 0;
    final totalTickets = _ticketsByType.values.fold(0, (a, b) => a + b);
    final avgTicketPrice = totalTickets > 0 ? totalRevenue / totalTickets : 0;

    return Row(
      children: [
        Expanded(
            child: _buildKPICard(
                'Gesamtumsatz',
                '${totalRevenue.toStringAsFixed(2)}€',
                Colors.green,
                Icons.euro)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildKPICard(
                'Ø Tagesumsatz',
                '${avgDailyRevenue.toStringAsFixed(2)}€',
                Colors.blue,
                Icons.trending_up)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildKPICard('Tickets verkauft', '$totalTickets',
                Colors.orange, Icons.confirmation_number)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildKPICard(
                'Ø Ticketpreis',
                '${avgTicketPrice.toStringAsFixed(2)}€',
                Colors.purple,
                Icons.attach_money)),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_revenueByDay.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Keine Umsatzdaten für den gewählten Zeitraum'),
          ),
        ),
      );
    }

    final spots = _revenueByDay.entries.map((entry) {
      final dayIndex =
          _revenueByDay.keys.toList().indexOf(entry.key).toDouble();
      return FlSpot(dayIndex, entry.value);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Umsatzentwicklung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformersTable() {
    final sortedTickets = _ticketsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beliebteste Tickets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              children: [
                const TableRow(
                  children: [
                    Text('Ticket-Typ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Verkauft',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Anteil',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                ...sortedTickets.take(10).map((entry) {
                  final total = _ticketsByType.values.fold(0, (a, b) => a + b);
                  final percentage =
                      ((entry.value / total) * 100).toStringAsFixed(1);
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(entry.key),
                      ),
                      Text('${entry.value}'),
                      Text('$percentage%'),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsTab() {
    return PermissionWrapper(
      requiredPermission: 'can_view_ticket_analytics',
      placeholder: _buildAccessDenied('Ticket-Analytics'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTicketTypeChart(),
            const SizedBox(height: 24),
            _buildTicketTrendChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypeChart() {
    if (_ticketsByType.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Keine Ticket-Daten verfügbar'),
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
              'Ticket-Verteilung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: _ticketsByType.entries.map((entry) {
                    final total =
                        _ticketsByType.values.fold(0, (a, b) => a + b);
                    final percentage = (entry.value / total) * 100;
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: _getRandomColor(
                          _ticketsByType.keys.toList().indexOf(entry.key)),
                      radius: 100,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTrendChart() {
    // Vereinfachte Trend-Darstellung
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket-Verkaufs-Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Detaillierte Trend-Analyse wird implementiert...'),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return PermissionWrapper(
      requiredPermission: 'can_view_user_analytics',
      placeholder: _buildAccessDenied('Benutzer-Analytics'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserStatusChart(),
            const SizedBox(height: 24),
            _buildUserStatsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatusChart() {
    if (_usersByStatus.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Keine Benutzer-Daten verfügbar'),
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
              'Benutzer nach Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  barGroups: _usersByStatus.entries.map((entry) {
                    final index =
                        _usersByStatus.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: _getRandomColor(index),
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
                          final statusList = _usersByStatus.keys.toList();
                          if (value.toInt() < statusList.length) {
                            return Text(statusList[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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

  Widget _buildUserStatsTable() {
    final totalUsers = _allUsers.length;
    final activeUsers = _allUsers.where((u) => u.isBlocked == false).length;
    final blockedUsers = _allUsers.where((u) => u.isBlocked == true).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Benutzer-Statistiken',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              children: [
                TableRow(
                  children: [
                    const Text('Gesamte Benutzer:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('$totalUsers'),
                  ],
                ),
                TableRow(
                  children: [
                    const Text('Aktive Benutzer:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('$activeUsers'),
                  ],
                ),
                TableRow(
                  children: [
                    const Text('Blockierte Benutzer:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('$blockedUsers'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalProvidersTab() {
    return PermissionWrapper(
      requiredPermission: 'can_view_provider_stats',
      placeholder: _buildAccessDenied('External Provider Analytics'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'External Provider Analytics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'External Provider Analytics sind im separaten Management-Bereich verfügbar. '
                        'Wechseln Sie zu "External Provider Management" für detaillierte Statistiken.',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats Placeholder
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildQuickStatCard(
                  'Fitpass Check-ins',
                  '0', // TODO: Load real data
                  Icons.fitness_center,
                  Colors.orange,
                ),
                _buildQuickStatCard(
                  'Friction Check-ins',
                  '0', // TODO: Load real data
                  Icons.sports_gymnastics,
                  Colors.blue,
                ),
                _buildQuickStatCard(
                  'Erfolgsrate',
                  '0%', // TODO: Load real data
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildQuickStatCard(
                  'Aktive Provider',
                  '0', // TODO: Load real data
                  Icons.extension,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Navigation Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to External Provider Management
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Navigation zu External Provider Management...'),
                      backgroundColor: Colors.indigo,
                    ),
                  );
                },
                icon: const Icon(Icons.extension),
                label: const Text('Zum External Provider Management'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(
      String title, String value, IconData icon, Color color) {
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

  Widget _buildExportTab() {
    return PermissionWrapper(
      requiredPermission: 'can_export_reports',
      placeholder: _buildAccessDenied('Datenexport'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datenexport',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildExportCard(
              'Umsatzberichte',
              'Excel-Export der Umsatzdaten für den gewählten Zeitraum',
              Icons.trending_up,
              Colors.green,
              () => _exportRevenue(),
            ),
            _buildExportCard(
              'Ticket-Verkäufe',
              'Detaillierte Liste aller verkauften Tickets',
              Icons.confirmation_number,
              Colors.blue,
              () => _exportTickets(),
            ),
            _buildExportCard(
              'Benutzer-Daten',
              'Export der Benutzerdatenbank (DSGVO-konform)',
              Icons.people,
              Colors.orange,
              () => _exportUsers(),
            ),
            _buildExportCard(
              'External Provider Daten',
              'Check-in-Logs und Provider-Statistiken',
              Icons.extension,
              Colors.indigo,
              () => _exportExternalProviders(),
            ),
            _buildExportCard(
              'Vollständiger Bericht',
              'Kompletter Analytics-Report als PDF',
              Icons.picture_as_pdf,
              Colors.red,
              () => _exportComprehensiveReport(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard(String title, String description, IconData icon,
      Color color, VoidCallback onExport) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: onExport,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          child: const Text('Exportieren'),
        ),
      ),
    );
  }

  Widget _buildAccessDenied(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Zugriff verweigert',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Sie haben keine Berechtigung für $feature',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Helper Methods
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
    _calculateAnalytics();
  }

  void _selectDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (result != null) {
      setState(() {
        _dateRange = result;
        _calculateAnalytics();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Color _getRandomColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  // Export Functions
  void _exportRevenue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗄️ Umsatzberichte werden exportiert...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementiere Excel-Export
  }

  void _exportTickets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎫 Ticket-Daten werden exportiert...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementiere CSV-Export
  }

  void _exportUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('👥 Benutzer-Daten werden exportiert (DSGVO-konform)...'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Implementiere anonymisierten Export
  }

  void _exportExternalProviders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🌐 External Provider Daten werden exportiert...'),
        backgroundColor: Colors.indigo,
      ),
    );
    // TODO: Implementiere External Provider Export
  }

  void _exportComprehensiveReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Vollständiger Bericht wird als PDF erstellt...'),
        backgroundColor: Colors.red,
      ),
    );
    // TODO: Implementiere PDF-Export
  }
}
