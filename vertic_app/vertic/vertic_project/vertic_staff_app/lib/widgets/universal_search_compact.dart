import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'package:provider/provider.dart';

/// **🔍 KOMPAKTE UNIVERSELLE SUCHFUNKTION**
///
/// Kompakte Version für Integration in bestehende UIs wie:
/// - POS-System-Kundensuche
/// - Schnellauswahl-Dialoge
/// - Dropdown-Ersatz
class UniversalSearchCompact extends StatefulWidget {
  final String hintText;
  final List<String>? entityTypes;
  final Function(SearchResult)? onResultSelected;
  final Function(String)? onQueryChanged;
  final bool autofocus;
  final double? width;
  final int maxResults;

  const UniversalSearchCompact({
    super.key,
    this.hintText = 'Suchen...',
    this.entityTypes,
    this.onResultSelected,
    this.onQueryChanged,
    this.autofocus = false,
    this.width,
    this.maxResults = 10,
  });

  @override
  State<UniversalSearchCompact> createState() => _UniversalSearchCompactState();
}

class _UniversalSearchCompactState extends State<UniversalSearchCompact> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchResult> _results = [];
  bool _isLoading = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// **🔍 KOMPAKTE SUCHFUNKTION**
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      // 🧹 UX-FIX: Callback auch bei leerer Suche aufrufen für Live-Filter-Reset
      widget.onQueryChanged?.call(query.trim());
      return;
    }

    setState(() {
      _isLoading = true;
      _showResults = true;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);

      final request = SearchRequest(
        query: query.trim(),
        entityTypes: widget.entityTypes ?? ['customer', 'product', 'category'],
        limit: widget.maxResults,
        offset: 0,
        minRelevance: 0.1,
        includeHighlights: false,
        searchHistory: false,
      );

      final response = await client.universalSearch.universalSearch(request);

      setState(() {
        _results = response.results;
        _isLoading = false;
      });

      // Callback für Query-Änderung
      widget.onQueryChanged?.call(query);
    } catch (e) {
      debugPrint('❌ Compact search error: $e');
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
  }

  /// **📱 SUCHERGEBNIS-ITEM (KOMPAKT)**
  Widget _buildResultItem(SearchResult result) {
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

    return ListTile(
      dense: true,
      leading: Icon(getIcon(), color: getColor(), size: 20),
      title: Text(
        result.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: result.subtitle != null
          ? Text(
              result.subtitle!,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: getColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          result.entityType.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: getColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () {
        _controller.text = result.title;
        setState(() {
          _showResults = false;
        });
        _focusNode.unfocus();
        widget.onResultSelected?.call(result);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // **SUCHFELD**
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (value) {
              // Debounced search - warte 300ms nach letzter Eingabe
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_controller.text == value) {
                  _performSearch(value);
                }
              });
            },
            onSubmitted: _performSearch,
            onTap: () {
              if (_controller.text.isNotEmpty && _results.isNotEmpty) {
                setState(() {
                  _showResults = true;
                });
              }
            },
          ),

          // **ERGEBNISSE (DROPDOWN-STYLE)**
          if (_showResults)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              child: _results.isEmpty && !_isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Keine Ergebnisse gefunden',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        return _buildResultItem(_results[index]);
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

/// **🎯 UNIVERSELLE SUCHFUNKTION SPEZIFISCH FÜR KUNDEN**
class CustomerSearchWidget extends StatelessWidget {
  final Function(AppUser)? onCustomerSelected;
  final String hintText;
  final bool autofocus;

  const CustomerSearchWidget({
    super.key,
    this.onCustomerSelected,
    this.hintText = 'Kunde suchen...',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalSearchCompact(
      hintText: hintText,
      entityTypes: const ['customer'],
      autofocus: autofocus,
      maxResults: 15,
      onResultSelected: (result) async {
        if (result.entityType == 'customer' && onCustomerSelected != null) {
          try {
            // Lade vollständige Kundendaten
            final client = Provider.of<Client>(context, listen: false);
            final users = await client.user.getAllUsers(limit: 1000, offset: 0);

            // Finde den User mit der entsprechenden ID
            final user = users.firstWhere(
              (u) => u.id == result.entityId,
              orElse: () => throw Exception('User not found'),
            );

            onCustomerSelected!(user);
          } catch (e) {
            debugPrint('❌ Error loading customer details: $e');
          }
        }
      },
    );
  }
}

/// **🛒 UNIVERSELLE SUCHFUNKTION SPEZIFISCH FÜR PRODUKTE**
class ProductSearchWidget extends StatelessWidget {
  final Function(Product)? onProductSelected;
  final String hintText;
  final bool autofocus;

  const ProductSearchWidget({
    super.key,
    this.onProductSelected,
    this.hintText = 'Produkt suchen...',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalSearchCompact(
      hintText: hintText,
      entityTypes: const ['product'],
      autofocus: autofocus,
      maxResults: 15,
      onResultSelected: (result) async {
        if (result.entityType == 'product' && onProductSelected != null) {
          try {
            // Lade vollständige Produktdaten
            final client = Provider.of<Client>(context, listen: false);
            final products = await client.productManagement.getProducts(
              categoryId: null,
              hallId: null,
              onlyActive: true,
            );

            // Finde das Produkt mit der entsprechenden ID
            final product = products.firstWhere(
              (p) => p.id == result.entityId,
              orElse: () => throw Exception('Product not found'),
            );

            onProductSelected!(product);
          } catch (e) {
            debugPrint('❌ Error loading product details: $e');
          }
        }
      },
    );
  }
}

/// **🏪 POS-SYSTEM UNIFIED SEARCH**
/// Einheitliche Suche für:
/// - 👥 Kunden (über UniversalSearch)
/// - 🛒 Produkte (über UniversalSearch) 
/// - 🔍 Live-Filter für Artikel/Kategorien (direkte Integration)
class PosSearchWidget extends StatelessWidget {
  final Function(AppUser)? onCustomerSelected;
  final Function(Product)? onProductSelected;
  final String hintText;
  final bool autofocus;
  
  // 🔍 LIVE-FILTER INTEGRATION
  final Function(String query)? onLiveFilterChanged;
  final String? liveFilterQuery;
  final bool? isLiveFilterActive;
  final VoidCallback? onLiveFilterReset;

  const PosSearchWidget({
    super.key,
    this.onCustomerSelected,
    this.onProductSelected,
    this.hintText = 'Kunde oder Produkt suchen...',
    this.autofocus = false,
    // Live-Filter Parameters
    this.onLiveFilterChanged,
    this.liveFilterQuery,
    this.isLiveFilterActive,
    this.onLiveFilterReset,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalSearchCompact(
      hintText: hintText,
      entityTypes: const ['customer', 'product'], // 🎯 BEIDE TYPEN!
      autofocus: autofocus,
      maxResults: 20,
      // 🔍 LIVE-FILTER INTEGRATION: Weiterleitung der Query-Änderungen
      onQueryChanged: onLiveFilterChanged,
      onResultSelected: (result) async {
        try {
          final client = Provider.of<Client>(context, listen: false);

          if (result.entityType == 'customer' && onCustomerSelected != null) {
            // Lade vollständige Kundendaten
            final users = await client.user.getAllUsers(limit: 1000, offset: 0);
            final user = users.firstWhere(
              (u) => u.id == result.entityId,
              orElse: () => throw Exception('User not found'),
            );
            onCustomerSelected!(user);
          } else if (result.entityType == 'product' &&
              onProductSelected != null) {
            // Lade vollständige Produktdaten
            final products = await client.productManagement.getProducts(
              categoryId: null,
              hallId: null,
              onlyActive: true,
            );
            final product = products.firstWhere(
              (p) => p.id == result.entityId,
              orElse: () => throw Exception('Product not found'),
            );
            onProductSelected!(product);
          }
        } catch (e) {
          debugPrint('❌ Error loading entity details: $e');
        }
      },
    );
  }
}
