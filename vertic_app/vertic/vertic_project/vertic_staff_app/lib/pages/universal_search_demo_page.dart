import 'package:flutter/material.dart';
import '../widgets/universal_search_widget.dart';

/// **🔍 UNIVERSELLE SUCHE - DEMO-SEITE**
///
/// Diese Seite demonstriert die umfassende Suchfunktion für:
/// - 👥 Kunden
/// - 🛒 Produkte
/// - 🏷️ Kategorien
///
/// Features:
/// - ⚡ Debounced Live-Suche
/// - 💡 Auto-Complete & Suggestions
/// - 📊 Relevanz-Ranking
/// - 🎯 Multi-Entity-Suche
class UniversalSearchDemoPage extends StatefulWidget {
  const UniversalSearchDemoPage({super.key});

  @override
  State<UniversalSearchDemoPage> createState() =>
      _UniversalSearchDemoPageState();
}

class _UniversalSearchDemoPageState extends State<UniversalSearchDemoPage> {
  String _currentQuery = '';
  SearchResult? _selectedResult;
  List<String> _searchHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Universelle Suche',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          // **🔍 SUCH-HEADER**
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suche nach Kunden, Produkten & Kategorien',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nutze die intelligente Suche um schnell alles zu finden',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // **🔍 UNIVERSELLES SUCHWIDGET**
                UniversalSearchWidget(
                  hintText: 'Kunden, Produkte, Kategorien suchen...',
                  autofocus: true,
                  onQueryChanged: (query) {
                    setState(() => _currentQuery = query);
                  },
                  onResultSelected: (result) {
                    setState(() => _selectedResult = result);

                    // Füge zur Suchhistorie hinzu
                    if (!_searchHistory.contains(result.title)) {
                      _searchHistory.insert(0, result.title);
                      if (_searchHistory.length > 5) {
                        _searchHistory.removeLast();
                      }
                    }

                    // Zeige Auswahl-Dialog
                    _showResultSelectedDialog(result);
                  },
                ),
              ],
            ),
          ),

          // **📊 SUCH-STATISTIKEN**
          if (_currentQuery.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Suche nach: "$_currentQuery"',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // **📚 SUCHHISTORIE**
          if (_searchHistory.isNotEmpty)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kürzliche Suchen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchHistory.length,
                        itemBuilder: (context, index) {
                          final historyItem = _searchHistory[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.history,
                                  color: Colors.grey.shade600,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                historyItem,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Kürzlich gesucht',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey.shade400,
                                size: 16,
                              ),
                              onTap: () {
                                // TODO: Neue Suche mit diesem Begriff starten
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Suche nach "$historyItem" gestartet',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // **💡 FEATURES-ÜBERSICHT**
          if (_searchHistory.isEmpty && _currentQuery.isEmpty)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.search, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 20),
                    Text(
                      'Leistungsstarke Suche',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Durchsuche alle Bereiche deines POS-Systems gleichzeitig',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildFeaturesList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// **✨ FEATURES-LISTE**
  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.people,
        'title': 'Kundensuche',
        'description': 'Namen, E-Mails, Telefonnummern',
        'color': Colors.blue,
      },
      {
        'icon': Icons.inventory_2,
        'title': 'Produktsuche',
        'description': 'Artikel, Barcodes, Beschreibungen',
        'color': Colors.green,
      },
      {
        'icon': Icons.category,
        'title': 'Kategorien',
        'description': 'Produktkategorien und Gruppen',
        'color': Colors.purple,
      },
    ];

    return Column(
      children: features
          .map(
            (feature) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (feature['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: feature['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['description'] as String,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  /// **🎯 ERGEBNIS-AUSWAHL-DIALOG**
  void _showResultSelectedDialog(SearchResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getEntityColor(result.entityType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getEntityIcon(result.entityType),
                color: _getEntityColor(result.entityType),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(result.title, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.subtitle != null)
              Text(
                result.subtitle!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            if (result.description != null) ...[
              const SizedBox(height: 8),
              Text(
                result.description!,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Typ: ${result.entityType}'),
                  Text('ID: ${result.entityId}'),
                  Text('Relevanz: ${(result.relevanceScore * 100).toInt()}%'),
                  if (result.category != null)
                    Text('Kategorie: ${result.category}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${result.title} ausgewählt'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Auswählen'),
          ),
        ],
      ),
    );
  }

  /// **🎨 ENTITY STYLING**
  IconData _getEntityIcon(String entityType) {
    switch (entityType) {
      case 'customer':
        return Icons.person;
      case 'product':
        return Icons.inventory_2;
      case 'category':
        return Icons.category;
      default:
        return Icons.search;
    }
  }

  Color _getEntityColor(String entityType) {
    switch (entityType) {
      case 'customer':
        return Colors.blue;
      case 'product':
        return Colors.green;
      case 'category':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
