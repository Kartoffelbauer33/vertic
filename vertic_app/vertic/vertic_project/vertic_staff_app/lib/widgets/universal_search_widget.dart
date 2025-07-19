import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

/// **🔍 UNIVERSELLES SUCHWIDGET - MODERNE IMPLEMENTATION**
///
/// Features:
/// - ⚡ Debounced Search (500ms)
/// - 💡 Auto-Complete mit Suggestions
/// - 🎯 Multi-Entity-Suche (Kunden, Produkte, Kategorien)
/// - 📱 Responsive UI
/// - 🔤 Highlighting von Suchbegriffen
/// - 📊 Relevanz-Ranking
class UniversalSearchWidget extends StatefulWidget {
  final String hintText;
  final List<String>? entityTypes;
  final Function(SearchResult)? onResultSelected;
  final Function(String)? onQueryChanged;
  final bool autofocus;
  final double? width;

  const UniversalSearchWidget({
    super.key,
    this.hintText = 'Kunden, Produkte, Kategorien suchen...',
    this.entityTypes,
    this.onResultSelected,
    this.onQueryChanged,
    this.autofocus = false,
    this.width,
  });

  @override
  State<UniversalSearchWidget> createState() => _UniversalSearchWidgetState();
}

class _UniversalSearchWidgetState extends State<UniversalSearchWidget>
    with TickerProviderStateMixin {
  // **🎛️ CONTROLLER & STATE**
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _debouncer = Debouncer(milliseconds: 500);

  List<SearchResult> _searchResults = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _hasResults = false;
  String _currentQuery = '';

  // **🎨 ANIMATION CONTROLLER**
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation Setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Search Logic Setup
    _searchController.addListener(_onSearchChanged);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// **🔍 SUCH-LOGIC mit Debouncing**
  void _onSearchChanged() {
    final query = _searchController.text;
    widget.onQueryChanged?.call(query);

    if (query != _currentQuery) {
      _currentQuery = query;

      // Debounced Search
      _debouncer.run(() => _performSearch(query));
    }
  }

  /// **🚀 HAUPT-SUCHFUNKTION**
  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasResults = false;
    });

    try {
      if (query.trim().isEmpty) {
        // Lade recent searches wenn leer
        await _loadRecentSearches();
        return;
      }

      final client = Provider.of<Client>(context, listen: false);

      // **MOCK IMPLEMENTATION**
      // TODO: Ersetze durch echten API-Call wenn Backend fertig ist
      await _mockUniversalSearch(query);

      // **ECHTER API-CALL (wenn Backend bereit):**
      // final request = SearchRequest(
      //   query: query,
      //   entityTypes: widget.entityTypes,
      //   limit: 20,
      //   includeHighlights: true,
      // );
      // final response = await client.universalSearch.universalSearch(request);
      // setState(() {
      //   _searchResults = response.results;
      //   _suggestions = response.suggestions ?? [];
      //   _hasResults = response.results.isNotEmpty;
      // });
    } catch (e) {
      debugPrint('🔍 Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Suche fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (_hasResults || _suggestions.isNotEmpty) {
          _animationController.forward();
        }
      }
    }
  }

  /// **🎭 MOCK SEARCH für Demo-Zwecke**
  Future<void> _mockUniversalSearch(String query) async {
    // Simuliere API-Delay
    await Future.delayed(const Duration(milliseconds: 200));

    final mockResults =
        <SearchResult>[
              // Mock Customer
              SearchResult(
                entityType: 'customer',
                entityId: 1,
                title: 'Max Mustermann',
                subtitle: 'max.mustermann@email.com',
                description: '+49 123 456789',
                relevanceScore: 0.9,
                matchedFields: ['name', 'email'],
                highlightedText: '<mark>Max</mark> Mustermann',
                category: 'Kunde',
                imageUrl: null,
              ),
              // Mock Product
              SearchResult(
                entityType: 'product',
                entityId: 2,
                title: 'Coca Cola 0,5L',
                subtitle: '€1,50',
                description: 'Erfrischungsgetränk mit Kohlensäure',
                relevanceScore: 0.8,
                matchedFields: ['name'],
                highlightedText: '<mark>Cola</mark> 0,5L',
                category: 'Getränke',
                tags: ['Barcode: 12345'],
              ),
              // Mock Category
              SearchResult(
                entityType: 'category',
                entityId: 3,
                title: 'Getränke',
                subtitle: 'Kategorie',
                description: 'Alle Arten von Getränken',
                relevanceScore: 0.7,
                matchedFields: ['name'],
                highlightedText: '<mark>Getränke</mark>',
                category: 'Kategorie',
              ),
            ]
            .where(
              (result) =>
                  result.title.toLowerCase().contains(query.toLowerCase()) ||
                  (result.description?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();

    setState(() {
      _searchResults = mockResults;
      _suggestions = [
        'Cola',
        'Getränke',
        'Max Mustermann',
      ].where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();
      _hasResults = mockResults.isNotEmpty;
    });
  }

  /// **📚 LADE RECENT SEARCHES**
  Future<void> _loadRecentSearches() async {
    // Mock recent searches
    setState(() {
      _suggestions = ['Cola', 'Max Mustermann', 'Getränke', 'Bier'];
      _searchResults = [];
      _hasResults = false;
    });
  }

  /// **📱 BUILD UI**
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchBar(),
          if (_hasResults || _suggestions.isNotEmpty || _isLoading)
            _buildSearchResults(),
        ],
      ),
    );
  }

  /// **🔍 SEARCH BAR UI**
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          suffixIcon: _currentQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _suggestions = [];
                      _hasResults = false;
                      _currentQuery = '';
                    });
                    _animationController.reverse();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  /// **📋 SEARCH RESULTS UI**
  Widget _buildSearchResults() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) _buildLoadingIndicator(),
            if (_hasResults) _buildResultsList(),
            if (_suggestions.isNotEmpty && !_hasResults)
              _buildSuggestionsList(),
          ],
        ),
      ),
    );
  }

  /// **⏳ LOADING INDICATOR**
  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Suche läuft...'),
        ],
      ),
    );
  }

  /// **📄 RESULTS LIST**
  Widget _buildResultsList() {
    return Flexible(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return _buildResultTile(result);
        },
      ),
    );
  }

  /// **🔍 RESULT TILE**
  Widget _buildResultTile(SearchResult result) {
    final entityIcon = _getEntityIcon(result.entityType);
    final entityColor = _getEntityColor(result.entityType);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: entityColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(entityIcon, color: entityColor, size: 20),
      ),
      title: Text(
        result.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.subtitle != null)
            Text(
              result.subtitle!,
              style: TextStyle(color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (result.category != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: entityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                result.category!,
                style: TextStyle(
                  color: entityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      trailing: Text(
        '${(result.relevanceScore * 100).toInt()}%',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      onTap: () {
        widget.onResultSelected?.call(result);
        _focusNode.unfocus();
      },
    );
  }

  /// **💡 SUGGESTIONS LIST**
  Widget _buildSuggestionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            _currentQuery.isEmpty ? 'Kürzliche Suchen' : 'Vorschläge',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = _suggestions[index];
            return ListTile(
              leading: Icon(
                _currentQuery.isEmpty ? Icons.history : Icons.search,
                color: Colors.grey.shade500,
                size: 18,
              ),
              title: Text(suggestion),
              onTap: () {
                _searchController.text = suggestion;
                _performSearch(suggestion);
              },
            );
          },
        ),
      ],
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

/// **⏱️ DEBOUNCER HELPER-KLASSE**
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// **🔍 MOCK SEARCH RESULT KLASSE**
/// (Temporär bis Backend-Integration)
class SearchResult {
  final String entityType;
  final int entityId;
  final String title;
  final String? subtitle;
  final String? description;
  final double relevanceScore;
  final List<String> matchedFields;
  final String? highlightedText;
  final String? category;
  final String? imageUrl;
  final List<String>? tags;
  final DateTime? createdAt;

  SearchResult({
    required this.entityType,
    required this.entityId,
    required this.title,
    this.subtitle,
    this.description,
    required this.relevanceScore,
    required this.matchedFields,
    this.highlightedText,
    this.category,
    this.imageUrl,
    this.tags,
    this.createdAt,
  });
}
