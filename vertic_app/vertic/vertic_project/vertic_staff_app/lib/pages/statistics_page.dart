import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _isLoading = true;
  String _errorMessage = '';

  // Statistik-Daten
  List<Ticket> _allTickets = [];
  List<AppUser> _allUsers = [];

  // Filter-Optionen
  String _timeRangeFilter = 'Alle';
  final List<String> _timeRangeOptions = [
    'Heute',
    'Diese Woche',
    'Dieser Monat',
    'Dieses Jahr',
    'Alle'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final client = Provider.of<Client>(context, listen: false);

      // Server-Endpunkte aufrufen, um alle Tickets und Benutzer zu laden
      final tickets = await client.ticket.getAllTickets();
      final users = await client.user.getAllUsers(limit: 1000, offset: 0);

      setState(() {
        _allTickets = tickets;
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Daten: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Daten aktualisieren',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                )
              : _buildStatisticsContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showFilterDialog(context);
        },
        child: const Icon(Icons.filter_list),
        tooltip: 'Filter anwenden',
      ),
    );
  }

  Widget _buildStatisticsContent() {
    // Gefilterte Tickets basierend auf der Zeitraumauswahl
    List<Ticket> filteredTickets = _filterTicketsByTimeRange(_allTickets);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filteranzeige
          _buildFilterChip(),

          // Verkaufszahlen
          _buildSectionTitle('Verkaufszahlen'),
          _buildSalesSummary(filteredTickets),

          // Tickettypen-Verteilung
          _buildSectionTitle('Verteilung nach Tickettypen'),
          SizedBox(
            height: 300,
            child: _buildTicketTypeChart(filteredTickets),
          ),

          // Altersgruppen-Verteilung
          _buildSectionTitle('Verteilung nach Altersgruppen'),
          SizedBox(
            height: 300,
            child: _buildAgeDistributionChart(filteredTickets, _allUsers),
          ),

          // Besuchszeiten-Verteilung
          _buildSectionTitle('Besuchszeiten-Verteilung'),
          SizedBox(
            height: 300,
            child: _buildVisitTimesChart(filteredTickets),
          ),

          // Ticket-Nutzungsrate (verwendet vs. nicht verwendet)
          _buildSectionTitle('Ticket-Nutzungsrate'),
          SizedBox(
            height: 250,
            child: _buildTicketUsageChart(filteredTickets),
          ),

          // Tabelle mit den letzten verkauften Tickets
          _buildSectionTitle('Kürzlich verkaufte Tickets'),
          _buildRecentTicketsTable(filteredTickets),

          const SizedBox(height: 80), // Abstand für FloatingActionButton
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8.0,
        children: [
          Chip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: Text('Zeitraum: $_timeRangeFilter'),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              setState(() {
                _timeRangeFilter = 'Alle';
              });
            },
          ),
        ],
      ),
    );
  }

  List<Ticket> _filterTicketsByTimeRange(List<Ticket> tickets) {
    if (_timeRangeFilter == 'Alle') {
      return tickets;
    }

    final now = DateTime.now();
    DateTime startDate;

    switch (_timeRangeFilter) {
      case 'Heute':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Diese Woche':
        // Montag der aktuellen Woche
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'Dieser Monat':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Dieses Jahr':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        return tickets;
    }

    return tickets
        .where((ticket) => ticket.purchaseDate.isAfter(startDate))
        .toList();
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter anwenden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Zeitraum auswählen:'),
              const SizedBox(height: 8),
              ...List.generate(_timeRangeOptions.length, (index) {
                final option = _timeRangeOptions[index];
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _timeRangeFilter,
                  onChanged: (value) {
                    setState(() {
                      _timeRangeFilter = value!;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSalesSummary(List<Ticket> tickets) {
    // Berechnungen
    final int totalTickets = tickets.length;
    final double totalRevenue =
        tickets.fold(0, (sum, ticket) => sum + ticket.price);
    final int usedTickets = tickets.where((ticket) => ticket.isUsed).length;
    final int unusedTickets = totalTickets - usedTickets;

    // Heutige Tickets
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final int todayTickets = tickets
        .where((ticket) =>
            ticket.purchaseDate.year == today.year &&
            ticket.purchaseDate.month == today.month &&
            ticket.purchaseDate.day == today.day)
        .length;

    // Formatter für Währung
    final currencyFormatter =
        NumberFormat.currency(locale: 'de_DE', symbol: '€');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatCard(
                  'Gesamtanzahl Tickets',
                  totalTickets.toString(),
                  Icons.confirmation_number,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Gesamtumsatz',
                  currencyFormatter.format(totalRevenue),
                  Icons.euro,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  'Verwendete Tickets',
                  '$usedTickets (${totalTickets > 0 ? (usedTickets / totalTickets * 100).toStringAsFixed(1) : 0}%)',
                  Icons.check_circle,
                  Colors.teal,
                ),
                _buildStatCard(
                  'Tickets heute verkauft',
                  todayTickets.toString(),
                  Icons.today,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypeChart(List<Ticket> tickets) {
    // Zählen wie viele Tickets pro Typ
    final Map<int, int> ticketCounts = {};
    for (var ticket in tickets) {
      ticketCounts[ticket.ticketTypeId] =
          (ticketCounts[ticket.ticketTypeId] ?? 0) + 1;
    }

    // Farben für die verschiedenen Tickettypen
    final Map<int, Color> typeColors = {
      1: Colors.blue,
      2: Colors.green,
      3: Colors.purple,
      4: Colors.orange,
      5: Colors.red,
    };

    // Daten für PieChart
    final List<PieChartSectionData> sections =
        ticketCounts.entries.map((entry) {
      final int typeId = entry.key;
      final int count = entry.value;
      final double percentage =
          tickets.isEmpty ? 0 : count / tickets.length * 100;
      final String typeName = _ticketTypeName(typeId);
      return PieChartSectionData(
        color: typeColors[typeId] ?? Colors.grey,
        value: count.toDouble(),
        title: '$typeName\n${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return tickets.isEmpty
        ? const Center(child: Text('Keine Daten verfügbar'))
        : PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          );
  }

  String _ticketTypeName(int id) {
    switch (id) {
      case 1:
        return 'Kind';
      case 2:
        return 'Regulär';
      case 3:
        return 'Senior';
      case 4:
        return 'Familie';
      case 5:
        return 'Gruppe';
      default:
        return 'Unbekannt';
    }
  }

  Widget _buildAgeDistributionChart(List<Ticket> tickets, List<AppUser> users) {
    // Altersdaten extrahieren
    final Map<String, int> ageCounts = {
      '0-12': 0,
      '13-17': 0,
      '18-25': 0,
      '26-40': 0,
      '41-64': 0,
      '65+': 0,
    };

    // Für jedes Ticket den zugehörigen Benutzer finden und Alter berechnen
    for (var ticket in tickets) {
      final user = users.firstWhere(
        (u) => u.id == ticket.userId,
        orElse: () => AppUser(
          id: -1,
          firstName: 'Unbekannt',
          lastName: 'Unbekannt',
          email: 'unbekannt@example.com',
          createdAt: DateTime.now(),
        ),
      );

      if (user.id == -1 || user.birthDate == null) continue;

      final age = DateTime.now().difference(user.birthDate!).inDays ~/ 365;

      if (age <= 12) {
        ageCounts['0-12'] = (ageCounts['0-12'] ?? 0) + 1;
      } else if (age <= 17) {
        ageCounts['13-17'] = (ageCounts['13-17'] ?? 0) + 1;
      } else if (age <= 25) {
        ageCounts['18-25'] = (ageCounts['18-25'] ?? 0) + 1;
      } else if (age <= 40) {
        ageCounts['26-40'] = (ageCounts['26-40'] ?? 0) + 1;
      } else if (age <= 64) {
        ageCounts['41-64'] = (ageCounts['41-64'] ?? 0) + 1;
      } else {
        ageCounts['65+'] = (ageCounts['65+'] ?? 0) + 1;
      }
    }

    // Daten für BarChart
    final List<BarChartGroupData> barGroups = [];
    int index = 0;

    ageCounts.forEach((ageRange, count) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.blue.withValues(alpha: 0.7),
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
      index++;
    });

    return ageCounts.values.every((count) => count == 0)
        ? const Center(child: Text('Keine Altersgruppen-Daten verfügbar'))
        : BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY: ageCounts.values
                      .fold(0, (max, count) => count > max ? count : max) *
                  1.2,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final ageRanges = ageCounts.keys.toList();
                      if (value.toInt() >= 0 &&
                          value.toInt() < ageRanges.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            ageRanges[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true),
              barGroups: barGroups,
            ),
          );
  }

  Widget _buildVisitTimesChart(List<Ticket> tickets) {
    // Besuchszeiten nach Wochentagen
    final Map<int, int> weekdayCounts = {
      1: 0, // Montag
      2: 0, // Dienstag
      3: 0, // Mittwoch
      4: 0, // Donnerstag
      5: 0, // Freitag
      6: 0, // Samstag
      7: 0, // Sonntag
    };

    // Zähle Besuche nach Wochentag (expiryDate)
    for (var ticket in tickets) {
      final weekday = ticket.expiryDate.weekday;
      weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
    }

    // Daten für LineChart
    final List<FlSpot> spots = [];
    weekdayCounts.forEach((weekday, count) {
      spots.add(FlSpot(weekday.toDouble(), count.toDouble()));
    });

    final List<String> weekdayNames = [
      'Mo',
      'Di',
      'Mi',
      'Do',
      'Fr',
      'Sa',
      'So'
    ];

    return tickets.isEmpty
        ? const Center(child: Text('Keine Besuchszeiten-Daten verfügbar'))
        : LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt() - 1;
                      if (index >= 0 && index < weekdayNames.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            weekdayNames[index],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildTicketUsageChart(List<Ticket> tickets) {
    // Zählen wie viele Tickets verwendet wurden vs. nicht verwendet
    final int usedCount = tickets.where((ticket) => ticket.isUsed).length;
    final int unusedCount = tickets.length - usedCount;

    // Daten für PieChart
    final List<PieChartSectionData> sections = [
      PieChartSectionData(
        color: Colors.green,
        value: usedCount.toDouble(),
        title:
            'Verwendet\n${usedCount > 0 ? (usedCount / tickets.length * 100).toStringAsFixed(1) : 0}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: unusedCount.toDouble(),
        title:
            'Nicht verwendet\n${unusedCount > 0 ? (unusedCount / tickets.length * 100).toStringAsFixed(1) : 0}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return tickets.isEmpty
        ? const Center(child: Text('Keine Nutzungsdaten verfügbar'))
        : PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          );
  }

  Widget _buildRecentTicketsTable(List<Ticket> tickets) {
    // Sortiere Tickets nach Kaufdatum (neueste zuerst)
    final sortedTickets = List<Ticket>.from(tickets)
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    // Begrenzen auf die neuesten 10 Tickets
    final recentTickets = sortedTickets.take(10).toList();

    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Tickettyp')),
            DataColumn(label: Text('Kaufdatum')),
            DataColumn(label: Text('Gültig am')),
            DataColumn(label: Text('Preis')),
            DataColumn(label: Text('Status')),
          ],
          rows: recentTickets.map((ticket) {
            final DateFormat dateFormat = DateFormat('dd.MM.yyyy');
            final currencyFormatter =
                NumberFormat.currency(locale: 'de_DE', symbol: '€');

            return DataRow(
              cells: [
                DataCell(Text(ticket.id.toString())),
                DataCell(Text(_ticketTypeName(ticket.ticketTypeId))),
                DataCell(Text(dateFormat.format(ticket.purchaseDate))),
                DataCell(Text(dateFormat.format(ticket.expiryDate))),
                DataCell(Text(currencyFormatter.format(ticket.price))),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ticket.isUsed
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.isUsed ? 'Verwendet' : 'Nicht verwendet',
                      style: TextStyle(
                        color: ticket.isUsed
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
