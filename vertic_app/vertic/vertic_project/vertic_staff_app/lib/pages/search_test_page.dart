import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:provider/provider.dart';

/// **🔍 UNIVERSELLE SUCHFUNKTION - TESTSEITE**
///
/// Diese Seite testet die neue universelle Suchfunktion für:
/// - 👥 Kunden
/// - 🛒 Produkte
/// - 🏷️ Kategorien
///
/// Features:
/// - ⚡ Live-Suche mit Debouncing
/// - 📊 Ergebnisse nach Relevanz sortiert
/// - 🎯 Multi-Entity-Filter
class SearchTestPage extends StatefulWidget {
  const SearchTestPage({super.key});

  @override
  State<SearchTestPage> createState() => _SearchTestPageState();
}

class _SearchTestPageState extends State<SearchTestPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  String _lastQuery = '';
  List<String> _selectedEntityTypes = ['customer', 'product', 'category'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// **🔍 HAUPTSUCHFUNKTION**
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _lastQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _lastQuery = query;
    });

    try {
      debugPrint('🔍 Starte Suche: "$query" mit Typen: $_selectedEntityTypes');

      final request = SearchRequest(
        query: query.trim(),
        entityTypes: _selectedEntityTypes,
        limit: 20,
        offset: 0,
        minRelevance: 0.1,
        includeHighlights: true,
        searchHistory: true,
      );

      final client = Provider.of<Client>(context, listen: false);
      final response = await client.universalSearch.universalSearch(request);

      debugPrint(
        '✅ Suchergebnis: ${response.results.length} Ergebnisse in ${response.queryTime}ms',
      );

      setState(() {
        _searchResults = response.results;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Suchfehler: $e');
      debugPrint('📍 Stack: $stackTrace');

      setState(() {
        _searchResults = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Suchfehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// **🎯 ENTITY-TYPE-FILTER WIDGET**
  Widget _buildEntityTypeFilter() {
    final entityTypes = [
      {'value': 'customer', 'label': '👥 Kunden', 'icon': Icons.person},
      {'value': 'product', 'label': '🛒 Produkte', 'icon': Icons.shopping_bag},
      {'value': 'category', 'label': '🏷️ Kategorien', 'icon': Icons.category},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Suchbereiche',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: entityTypes.map((type) {
                final isSelected = _selectedEntityTypes.contains(type['value']);
                return FilterChip(
                  avatar: Icon(type['icon'] as IconData, size: 18),
                  label: Text(type['label'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedEntityTypes.add(type['value'] as String);
                      } else {
                        _selectedEntityTypes.remove(type['value']);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// **📱 SUCHERGEBNIS-KARTE**
  Widget _buildSearchResultCard(SearchResult result) {
    IconData getIcon() {
      switch (result.entityType) {
        case 'customer':
          return Icons.person;
        case 'product':
          return Icons.shopping_bag;
        case 'category':
          return Icons.category;
        default:
          return Icons.search;
      }
    }

    Color getColor() {
      switch (result.entityType) {
        case 'customer':
          return Colors.blue;
        case 'product':
          return Colors.green;
        case 'category':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: getColor(),
          child: Icon(getIcon(), color: Colors.white),
        ),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.subtitle != null) Text(result.subtitle!),
            if (result.description != null)
              Text(
                result.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: getColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.category ?? result.entityType,
                    style: TextStyle(
                      fontSize: 12,
                      color: getColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${result.entityId}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigation zu Detail-Seite basierend auf entityType
          debugPrint('🔍 Ausgewählt: ${result.entityType} #${result.entityId}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ausgewählt: ${result.title} (${result.entityType})',
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Universelle Suche'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // **SUCHFELD**
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.withOpacity(0.1),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Suche nach Kunden, Produkten oder Kategorien...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    // Debounced search - warte 500ms nach letzter Eingabe
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _performSearch(value);
                      }
                    });
                  },
                  onSubmitted: _performSearch,
                ),
                const SizedBox(height: 12),
                _buildEntityTypeFilter(),
              ],
            ),
          ),

          // **ERGEBNISSE**
          Expanded(
            child:
                _searchResults.isEmpty && _lastQuery.isNotEmpty && !_isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Keine Ergebnisse gefunden',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Versuche einen anderen Suchbegriff',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _searchResults.isEmpty && _lastQuery.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Gib einen Suchbegriff ein',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Suche nach Kunden, Produkten oder Kategorien',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildSearchResultCard(_searchResults[index]);
                    },
                  ),
          ),

          // **STATUS-BAR**
          if (_searchResults.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Text(
                    '${_searchResults.length} Ergebnisse gefunden',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    'für "$_lastQuery"',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
