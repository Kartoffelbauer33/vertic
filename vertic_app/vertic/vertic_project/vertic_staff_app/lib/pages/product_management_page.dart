import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

import '../auth/permission_provider.dart';

/// **📦 VEREINTE ARTIKEL & KATEGORIEN-VERWALTUNG**
///
/// Thematisch zusammengehörige Verwaltung von:
/// - 🏷️ Artikeln (bestehend)
/// - 📦 Produktkategorien (neu integriert)
/// - 🎨 Einheitliches POS-Design
/// - 🔄 Schneller Tab-Wechsel
class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage>
    with SingleTickerProviderStateMixin {
  // **🎯 TAB-CONTROLLER**
  late TabController _tabController;

  // **🏷️ ARTIKEL-STATE**
  bool _isLoadingProducts = true;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _searchTextProducts = '';
  String _selectedCategory = 'Alle';

  // **📦 KATEGORIEN-STATE**
  bool _isLoadingCategories = true;
  List<ProductCategory> _allCategories = [];
  List<ProductCategory> _filteredCategories = [];
  String _searchTextCategories = '';
  String _selectedFilterCategories = 'Alle';

  // **🎨 GEMEINSAME STEUERUNG**
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Tab-Controller initialisieren
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Beide Bereiche laden
    _loadProducts();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Suche leeren beim Tab-Wechsel
      _searchController.clear();
      if (_tabController.index == 0) {
        _onSearchChangedProducts('');
      } else {
        _onSearchChangedCategories('');
      }
    }
  }

  // ==================== ARTIKEL-LOGIC ====================

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);

    try {
      final client = Provider.of<Client>(context, listen: false);
      final products = await client.productManagement.getProducts(
        onlyActive: true,
      );

      if (mounted) {
        setState(() {
          _allProducts = products;
          _filterProducts();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Artikel: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesSearch =
            _searchTextProducts.isEmpty ||
            product.name.toLowerCase().contains(
              _searchTextProducts.toLowerCase(),
            ) ||
            (product.barcode?.toLowerCase().contains(
                  _searchTextProducts.toLowerCase(),
                ) ??
                false);

        final matchesCategory =
            _selectedCategory == 'Alle' ||
            product.categoryId.toString() == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChangedProducts(String value) {
    setState(() => _searchTextProducts = value);
    _filterProducts();
  }

  // ==================== KATEGORIEN-LOGIC ====================

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final client = Provider.of<Client>(context, listen: false);
      final categories = await client.productManagement.getProductCategories(
        onlyActive: true,
      );

      if (mounted) {
        setState(() {
          _allCategories = categories;
          _filterCategories();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Kategorien: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  void _filterCategories() {
    setState(() {
      _filteredCategories = _allCategories.where((category) {
        final matchesSearch =
            _searchTextCategories.isEmpty ||
            category.name.toLowerCase().contains(
              _searchTextCategories.toLowerCase(),
            ) ||
            (category.description?.toLowerCase().contains(
                  _searchTextCategories.toLowerCase(),
                ) ??
                false);

        final matchesFilter =
            _selectedFilterCategories == 'Alle' ||
            (_selectedFilterCategories == 'Aktiv' && category.isActive) ||
            (_selectedFilterCategories == 'Inaktiv' && !category.isActive);

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _onSearchChangedCategories(String value) {
    setState(() => _searchTextCategories = value);
    _filterCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📦 Artikel & Kategorien',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Info Button
          IconButton(
            onPressed: _showInfoDialog,
            icon: const Icon(Icons.analytics),
            tooltip: 'Statistiken',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Artikel'),
            Tab(icon: Icon(Icons.category), text: 'Kategorien'),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: TabBarView(
        controller: _tabController,
        children: [_buildProductsTab(), _buildCategoriesTab()],
      ),
      floatingActionButton: Consumer<PermissionProvider>(
        builder: (context, permissions, _) {
          return _tabController.index == 0
              ? FloatingActionButton.extended(
                  onPressed: _showAddProductDialog,
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Neuer Artikel'),
                )
              : FloatingActionButton.extended(
                  onPressed: _showCreateCategoryDialog,
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.construction),
                  label: const Text('Coming Soon'),
                );
        },
      ),
    );
  }

  // ==================== ARTIKEL-TAB ====================

  Widget _buildProductsTab() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildProductsFilterSection(),
        Expanded(
          child: _filteredProducts.isEmpty
              ? _buildProductsEmptyState()
              : _buildProductsGrid(),
        ),
      ],
    );
  }

  Widget _buildProductsFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Suchfeld
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Artikel suchen (Name, Barcode)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchTextProducts.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChangedProducts('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _onSearchChangedProducts,
          ),
          const SizedBox(height: 16),

          // Kategorie-Filter
          Row(
            children: [
              const Text('Kategorie: '),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                    _filterProducts();
                  },
                  items: [
                    const DropdownMenuItem(
                      value: 'Alle',
                      child: Text('Alle Kategorien'),
                    ),
                    ..._allCategories.map((category) {
                      return DropdownMenuItem(
                        value: category.id.toString(),
                        child: Text(category.name),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text('${_filteredProducts.length} Artikel'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchTextProducts.isEmpty
                ? 'Noch keine Artikel vorhanden'
                : 'Keine Artikel gefunden',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchTextProducts.isEmpty
                ? 'Erstellen Sie Ihren ersten Artikel'
                : 'Versuchen Sie andere Suchbegriffe',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 Spalten wie im POS
        childAspectRatio: 0.85, // Höher für mehr Informationen
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildPOSStyleProductCard(product);
      },
    );
  }

  /// **🎨 POS-STYLE PRODUCT CARD** - Einheitliches Design mit POS-System
  Widget _buildPOSStyleProductCard(Product product) {
    final category = _allCategories
        .where((cat) => cat.id == product.categoryId)
        .firstOrNull;
    final categoryConfig = _getCategoryConfig(category);

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editProduct(product),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryConfig.color.withOpacity(0.1),
                categoryConfig.color.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: categoryConfig.color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Icon und Aktionen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    categoryConfig.icon,
                    color: categoryConfig.color,
                    size: 24,
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          _editProduct(product);
                          break;
                        case 'delete':
                          _deleteProduct(product);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Bearbeiten'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Löschen',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Produktname
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Barcode (falls vorhanden)
              if (product.barcode != null) ...[
                Text(
                  'Barcode: ${product.barcode}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],

              // Kategorie
              if (category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: categoryConfig.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: categoryConfig.color.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
              ] else
                const Spacer(),

              // Preis (prominent wie im POS)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: categoryConfig.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${product.price.toStringAsFixed(2)} €',
                  style: TextStyle(
                    color: categoryConfig.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== KATEGORIEN-TAB ====================

  Widget _buildCategoriesTab() {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildCategoriesFilterSection(),
        Expanded(
          child: _filteredCategories.isEmpty
              ? _buildCategoriesEmptyState()
              : _buildCategoriesGrid(),
        ),
      ],
    );
  }

  Widget _buildCategoriesFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Suchfeld
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Kategorien suchen (Name, Beschreibung)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchTextCategories.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChangedCategories('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _onSearchChangedCategories,
          ),
          const SizedBox(height: 16),

          // Filter-Row
          Row(
            children: [
              const Text('Filter: '),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedFilterCategories,
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() => _selectedFilterCategories = value!);
                    _filterCategories();
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Alle',
                      child: Text('Alle Kategorien'),
                    ),
                    DropdownMenuItem(value: 'Aktiv', child: Text('Nur aktive')),
                    DropdownMenuItem(
                      value: 'Inaktiv',
                      child: Text('Nur inaktive'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text('${_filteredCategories.length} Kategorien'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchTextCategories.isEmpty
                ? 'Noch keine Kategorien vorhanden'
                : 'Keine Kategorien gefunden',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchTextCategories.isEmpty
                ? 'Kategorien können über das System erstellt werden'
                : 'Versuchen Sie andere Suchbegriffe',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 Spalten für Kategorien
        childAspectRatio: 1.1, // Etwas breiter für mehr Informationen
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(ProductCategory category) {
    final categoryConfig = _getCategoryConfig(category);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCategoryDetails(category),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryConfig.color.withOpacity(0.15),
                categoryConfig.color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: categoryConfig.color.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Icon, Status und PopupMenu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    categoryConfig.icon,
                    color: categoryConfig.color,
                    size: 32,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: category.isActive ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category.isActive ? 'Aktiv' : 'Inaktiv',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: categoryConfig.color,
                          size: 18,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditCategoryDialog(category);
                              break;
                            case 'delete':
                              _showDeleteCategoryDialog(category);
                              break;
                            case 'details':
                              _showCategoryDetails(category);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Details anzeigen'),
                              ],
                            ),
                          ),
                          if (!category.isSystemCategory) ...[
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Bearbeiten'),
                                ],
                              ),
                            ),
                            if (!category
                                .isFavorites) // Favoriten-Kategorie nicht löschbar
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Löschen'),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Kategorie-Name
              Text(
                category.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: categoryConfig.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Beschreibung (falls vorhanden)
              if (category.description != null &&
                  category.description!.isNotEmpty) ...[
                Text(
                  category.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ] else
                const Spacer(),

              // Statistiken/Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: categoryConfig.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Produkte: ${_getProductCountForCategory(category.id!)}',
                      style: TextStyle(
                        color: categoryConfig.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Erstellt: ${_formatDate(category.createdAt)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SHARED METHODS ====================

  /// **🎨 KATEGORIE-KONFIGURATION** - Einheitlich mit POS-System
  CategoryConfig _getCategoryConfig(ProductCategory? category) {
    if (category == null) {
      return CategoryConfig(
        color: Colors.grey,
        icon: Icons.inventory_2,
        name: 'Unbekannt',
      );
    }

    // Verwende die Schema-Properties falls verfügbar
    final color = _parseColorFromHex(category.colorHex ?? '#607D8B');
    final icon = _parseIconFromName(category.iconName ?? 'category');

    return CategoryConfig(color: color, icon: icon, name: category.name);
  }

  Color _parseColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.indigo; // Fallback
    }
  }

  IconData _parseIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'local_drink':
        return Icons.local_drink;
      case 'fastfood':
        return Icons.fastfood;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'checkroom':
        return Icons.checkroom;
      case 'build':
        return Icons.build;
      case 'medication':
        return Icons.medication;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}.${date.month}.${date.year}';
  }

  int _getProductCountForCategory(int categoryId) {
    return _allProducts.where((p) => p.categoryId == categoryId).length;
  }

  // ==================== DIALOGS & ACTIONS ====================

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onProductCreated: (product) {
          _loadProducts(); // Reload nach Erstellung

          // 🔄 NEUES FEATURE: Signalisiere anderen Seiten (z.B. POS) dass sie refreshen sollen
          _notifyOtherSystemsOfProductChange();
        },
        availableCategories: _allCategories,
      ),
    );
  }

  /// **🔄 NEUE METHODE: Benachrichtigt andere Systeme über Artikel-Änderungen**
  void _notifyOtherSystemsOfProductChange() {
    // Für spätere Implementierung: Event-Bus oder ähnliches
    debugPrint('🔄 Artikel-Änderung: Andere Systeme sollten refreshen');
  }

  void _editProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => EditProductDialog(
        product: product,
        onProductUpdated: (updatedProduct) {
          _loadProducts(); // Reload nach Update
        },
      ),
    );
  }

  void _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Artikel löschen'),
        content: Text('Möchten Sie "${product.name}" wirklich löschen?'),
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

    if (confirmed == true) {
      try {
        final client = Provider.of<Client>(context, listen: false);
        await client.productManagement.deleteProduct(product.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Artikel "${product.name}" wurde gelöscht'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProducts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Löschen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCategoryDetails(ProductCategory category) {
    final productCount = _getProductCountForCategory(category.id!);
    final products = _allProducts
        .where((p) => p.categoryId == category.id)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📦 ${category.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description != null)
              Text('Beschreibung: ${category.description}'),
            const SizedBox(height: 8),
            Text('Status: ${category.isActive ? "Aktiv" : "Inaktiv"}'),
            Text('Anzahl Produkte: $productCount'),
            Text('Farbe: ${category.colorHex ?? "Standard"}'),
            Text('Icon: ${category.iconName ?? "Standard"}'),
            Text('Display Order: ${category.displayOrder ?? 0}'),
            if (category.createdAt != null)
              Text('Erstellt: ${_formatDate(category.createdAt)}'),

            if (products.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Produkte in dieser Kategorie:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...products.take(5).map((p) => Text('• ${p.name}')),
              if (products.length > 5)
                Text('... und ${products.length - 5} weitere'),
            ],
          ],
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

  void _showInfoDialog() {
    final activeCategories = _allCategories.where((c) => c.isActive).length;
    final totalProducts = _allProducts.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Artikel & Kategorien Statistiken'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem('Gesamt Artikel', totalProducts.toString()),
            _buildStatItem(
              'Gesamt Kategorien',
              _allCategories.length.toString(),
            ),
            _buildStatItem('Aktive Kategorien', activeCategories.toString()),
            const SizedBox(height: 16),
            const Text(
              '💡 Tab-System:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Artikel und Kategorien sind thematisch verbunden'),
            const Text('• Schneller Wechsel zwischen beiden Bereichen'),
            const Text('• Einheitliches POS-Design'),
            const Text('• Kategorie-basierte Produktzählung'),
          ],
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

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showComingSoonDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📦 Kategorie-Erstellung wird demnächst verfügbar sein'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ==================== KATEGORIEN-MANAGEMENT DIALOGS ====================

  /// **🆕 KATEGORIE ERSTELLEN DIALOG**
  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateCategoryDialog(
        onCategoryCreated: (category) {
          _loadCategories(); // Reload nach Erstellung
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Kategorie "${category.name}" erfolgreich erstellt',
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  /// **📝 KATEGORIE BEARBEITEN DIALOG**
  void _showEditCategoryDialog(ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => EditCategoryDialog(
        category: category,
        onCategoryUpdated: (updatedCategory) {
          _loadCategories(); // Reload nach Update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Kategorie "${updatedCategory.name}" aktualisiert',
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  /// **🗑️ KATEGORIE LÖSCHEN BESTÄTIGUNG**
  void _showDeleteCategoryDialog(ProductCategory category) async {
    final productCount = _getProductCountForCategory(category.id!);

    if (productCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Kategorie "${category.name}" kann nicht gelöscht werden - sie enthält $productCount Produkte',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Kategorie löschen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchten Sie die Kategorie "${category.name}" wirklich löschen?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Wichtiger Hinweis',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('• System-Kategorien können nicht gelöscht werden'),
                  Text('• Favoriten-Kategorie kann nicht gelöscht werden'),
                  Text(
                    '• Kategorien mit Produkten können nicht gelöscht werden',
                  ),
                ],
              ),
            ),
          ],
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

    if (confirmed == true) {
      try {
        final client = Provider.of<Client>(context, listen: false);
        // TODO: deleteProductCategory implementieren
        throw Exception('Delete-Funktion wird noch implementiert');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Kategorie "${category.name}" wurde gelöscht'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCategories();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Fehler beim Löschen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// ==================== EXISTING DIALOGS ====================

/// **🆕 ARTIKEL-HINZUFÜGEN DIALOG** - Vollständige Implementation
class AddProductDialog extends StatefulWidget {
  final Function(Product) onProductCreated;
  final List<ProductCategory> availableCategories;

  const AddProductDialog({
    super.key,
    required this.onProductCreated,
    required this.availableCategories,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _stockController = TextEditingController();

  ProductCategory? _selectedCategory;
  TaxClass? _selectedTaxClass;
  Country? _facilityCountry;
  List<TaxClass> _availableTaxClasses = [];
  bool _isLoading = false;
  bool _isTaxClassesLoading = true;
  bool _isFoodItem = false;

  @override
  void initState() {
    super.initState();
    _loadFacilityCountryAndTaxClasses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// **🏛️ DACH-Compliance: Facility-Land und Steuerklassen laden**
  Future<void> _loadFacilityCountryAndTaxClasses() async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      // 1. Aktuelles Facility und dessen Land ermitteln
      final currentFacility = await client.facility.getCurrentFacility();
      if (currentFacility != null && currentFacility.countryId != null) {
        final countries = await client.taxManagement.getAllCountries();
        _facilityCountry = countries.firstWhere(
          (country) => country.id == currentFacility.countryId,
          orElse: () => countries.first,
        );
        await _loadTaxClassesForFacilityCountry(currentFacility.countryId!);
        return;
      }

      // 2. Fallback: Deutschland als Standard
      await _loadDefaultGermanyTaxClasses();
    } catch (e) {
      debugPrint('⚠️ Fehler beim Laden der Länder/Steuerklassen: $e');
      await _loadDefaultGermanyTaxClasses();
    }
  }

  /// **🇩🇪 Standard-Deutschland-Setup für Steuerklassen**
  Future<void> _loadDefaultGermanyTaxClasses() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final countries = await client.taxManagement.getAllCountries();
      final germany = countries.firstWhere(
        (country) => country.code == 'DE',
        orElse: () => countries.first,
      );

      _facilityCountry = germany;
      await _loadTaxClassesForFacilityCountry(germany.id!);
    } catch (e) {
      debugPrint('⚠️ Fehler beim Deutschland-Setup: $e');
      setState(() => _isTaxClassesLoading = false);
    }
  }

  /// **📊 Steuerklassen für bestimmtes Land laden**
  Future<void> _loadTaxClassesForFacilityCountry(int countryId) async {
    try {
      setState(() => _isTaxClassesLoading = true);
      final client = Provider.of<Client>(context, listen: false);
      final taxClasses = await client.taxManagement.getTaxClassesForCountry(
        countryId,
      );

      setState(() {
        _availableTaxClasses = taxClasses;
        _isTaxClassesLoading = false;

        // Automatisch Standard-Steuerklasse auswählen
        if (taxClasses.isNotEmpty) {
          _selectedTaxClass = taxClasses.firstWhere(
            (taxClass) => taxClass.isDefault,
            orElse: () => taxClasses.first,
          );
        }
      });

      debugPrint(
        '🏛️ ${taxClasses.length} Steuerklassen für ${_facilityCountry?.displayName} geladen',
      );
    } catch (e) {
      debugPrint('⚠️ Fehler beim Laden der Steuerklassen: $e');
      setState(() => _isTaxClassesLoading = false);
    }
  }

  /// **🔧 Deutsche Dezimaltrennzeichen unterstützen**
  double? _parseGermanPrice(String priceText) {
    if (priceText.trim().isEmpty) return null;
    final normalizedPrice = priceText.trim().replaceAll(',', '.');
    try {
      final price = double.parse(normalizedPrice);
      return price > 0 ? price : null;
    } catch (e) {
      return null;
    }
  }

  /// **✅ Neues Produkt erstellen**
  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null || _selectedTaxClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Kategorie und Steuerklasse sind erforderlich'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = Provider.of<Client>(context, listen: false);

      final price = _parseGermanPrice(_priceController.text);
      if (price == null) {
        throw Exception(
          'Ungültiger Preis - verwenden Sie Format: 1,50 oder 1.50',
        );
      }

      final stockQuantity = _stockController.text.trim().isNotEmpty
          ? int.tryParse(_stockController.text.trim())
          : null;

      final newProduct = await client.productManagement.createProduct(
        _nameController.text.trim(),
        price,
        barcode: _barcodeController.text.trim().isNotEmpty
            ? _barcodeController.text.trim()
            : null,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        categoryId: _selectedCategory!.id,
        stockQuantity: stockQuantity,
        isFoodItem: _isFoodItem,
        // 🏛️ DACH-Compliance Parameter
        taxClassId: _selectedTaxClass!.id,
        defaultCountryId: _facilityCountry!.id,
        requiresTSESignature: _selectedTaxClass!.requiresTSESignature,
        requiresAgeVerification: false,
        isSubjectToSpecialTax: false,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onProductCreated(newProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Artikel "${newProduct.name}" erfolgreich erstellt',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Erstellen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_shopping_cart, color: Colors.blue),
          SizedBox(width: 8),
          Text('🆕 Neuer Artikel'),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Artikel-Name *',
                    hintText: 'z.B. Coca Cola 0,5L',
                    prefixIcon: Icon(Icons.shopping_cart),
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
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    hintText: 'Zusätzliche Informationen...',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Preis und Barcode in einer Reihe
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Preis (€) *',
                          hintText: '1,50',
                          prefixIcon: Icon(Icons.euro),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Preis erforderlich';
                          }
                          if (_parseGermanPrice(value) == null) {
                            return 'Ungültiger Preis';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode (optional)',
                          hintText: '1234567890123',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Kategorie
                DropdownButtonFormField<ProductCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: widget.availableCategories.map((category) {
                    return DropdownMenuItem<ProductCategory>(
                      value: category,
                      child: IntrinsicWidth(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    category.colorHex.replaceFirst('#', '0xFF'),
                                  ),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (category) {
                    setState(() => _selectedCategory = category);
                  },
                  validator: (value) {
                    if (value == null) return 'Kategorie erforderlich';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Steuerklasse
                _isTaxClassesLoading
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Steuerklassen werden geladen...'),
                        ],
                      )
                    : _availableTaxClasses.isEmpty
                    ? const Text(
                        '⚠️ Keine Steuerklassen verfügbar',
                        style: TextStyle(color: Colors.orange),
                      )
                    : DropdownButtonFormField<TaxClass>(
                        value: _selectedTaxClass,
                        decoration: InputDecoration(
                          labelText:
                              'Steuerklasse * (${_facilityCountry?.displayName ?? ""})',
                          prefixIcon: const Icon(Icons.account_balance),
                        ),
                        items: _availableTaxClasses.map((taxClass) {
                          return DropdownMenuItem<TaxClass>(
                            value: taxClass,
                            child: IntrinsicWidth(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(
                                          taxClass.colorHex.replaceFirst(
                                            '#',
                                            '0xFF',
                                          ),
                                        ),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${taxClass.name} (${taxClass.taxRate.toStringAsFixed(1)}%)',
                                  ),
                                  if (taxClass.isDefault) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (taxClass) {
                          setState(() => _selectedTaxClass = taxClass);
                        },
                        validator: (value) {
                          if (value == null) return 'Steuerklasse erforderlich';
                          return null;
                        },
                      ),
                const SizedBox(height: 16),

                // Bestand
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Bestand (optional)',
                    hintText: '100',
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Lebensmittel-Checkbox
                CheckboxListTile(
                  title: const Text('Ist Lebensmittel'),
                  subtitle: const Text('Für spezielle Compliance-Regeln'),
                  value: _isFoodItem,
                  onChanged: (value) {
                    setState(() => _isFoodItem = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Artikel erstellen'),
        ),
      ],
    );
  }
}

/// **📝 ARTIKEL BEARBEITEN DIALOG** - Vollständige Implementation
class EditProductDialog extends StatefulWidget {
  final Product product;
  final Function(Product) onProductUpdated;

  const EditProductDialog({
    super.key,
    required this.product,
    required this.onProductUpdated,
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _stockController;

  bool _isLoading = false;
  bool _isActive = true;
  bool _isFoodItem = false;

  // 📦 KATEGORIE- UND STEUERKLASSEN-AUSWAHL
  ProductCategory? _selectedCategory;
  TaxClass? _selectedTaxClass;
  Country? _facilityCountry;
  List<ProductCategory> _availableCategories = [];
  List<TaxClass> _availableTaxClasses = [];
  bool _isCategoriesLoading = true;
  bool _isTaxClassesLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(
      text: widget.product.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product.price.toString().replaceAll('.', ','),
    );
    _barcodeController = TextEditingController(
      text: widget.product.barcode ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product.stockQuantity?.toString() ?? '',
    );
    _isActive = widget.product.isActive;
    _isFoodItem = widget.product.isFoodItem;

    // 📦 Lade verfügbare Kategorien und Steuerklassen
    _loadAvailableOptionsForEdit();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// **📦 NEUE METHODE: Lädt Kategorien und Steuerklassen für Bearbeitung**
  Future<void> _loadAvailableOptionsForEdit() async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      // 1. Kategorien laden
      final categories = await client.productManagement.getProductCategories(
        onlyActive: true,
      );

      // 2. Facility-Land und Steuerklassen laden
      final currentFacility = await client.facility.getCurrentFacility();
      final countries = await client.taxManagement.getAllCountries();

      final facilityCountry = currentFacility?.countryId != null
          ? countries.firstWhere((c) => c.id == currentFacility!.countryId)
          : countries.firstWhere(
              (c) => c.code == 'DE',
              orElse: () => countries.first,
            );

      final taxClasses = await client.taxManagement.getTaxClassesForCountry(
        facilityCountry.id!,
      );

      setState(() {
        _availableCategories = categories;
        _facilityCountry = facilityCountry;
        _availableTaxClasses = taxClasses;

        // Aktuelle Auswahl setzen
        _selectedCategory = categories.isNotEmpty
            ? categories.firstWhere(
                (cat) => cat.id == widget.product.categoryId,
                orElse: () => categories.first,
              )
            : null;

        _selectedTaxClass = taxClasses.isNotEmpty
            ? taxClasses.firstWhere(
                (tax) => tax.id == widget.product.taxClassId,
                orElse: () => taxClasses.first,
              )
            : null;

        _isCategoriesLoading = false;
        _isTaxClassesLoading = false;
      });
    } catch (e) {
      setState(() {
        _isCategoriesLoading = false;
        _isTaxClassesLoading = false;
      });
      debugPrint('❌ Fehler beim Laden der Edit-Optionen: $e');
    }
  }

  /// **🔧 Deutsche Dezimaltrennzeichen unterstützen**
  double? _parseGermanPrice(String priceText) {
    if (priceText.trim().isEmpty) return null;
    final normalizedPrice = priceText.trim().replaceAll(',', '.');
    try {
      final price = double.parse(normalizedPrice);
      return price > 0 ? price : null;
    } catch (e) {
      return null;
    }
  }

  /// **✅ Artikel aktualisieren - ECHTE BACKEND-INTEGRATION**
  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null || _selectedTaxClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Kategorie und Steuerklasse sind erforderlich'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = Provider.of<Client>(context, listen: false);

      final price = _parseGermanPrice(_priceController.text);
      if (price == null) {
        throw Exception(
          'Ungültiger Preis - verwenden Sie Format: 1,50 oder 1.50',
        );
      }

      final stockQuantity = _stockController.text.trim().isNotEmpty
          ? int.tryParse(_stockController.text.trim())
          : null;

      // 🔧 ECHTE BACKEND-INTEGRATION mit expliziten Parametern
      final updatedProduct = await client.productManagement.updateProduct(
        widget.product.id!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        price: price,
        barcode: _barcodeController.text.trim().isNotEmpty
            ? _barcodeController.text.trim()
            : null,
        categoryId: _selectedCategory!.id!,
        stockQuantity: stockQuantity,
        isActive: _isActive,
        isFoodItem: _isFoodItem,
        taxClassId: _selectedTaxClass!.id!,
        defaultCountryId: _facilityCountry!.id!,
        requiresTSESignature: _selectedTaxClass!.requiresTSESignature,
        requiresAgeVerification: false,
        isSubjectToSpecialTax: false,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onProductUpdated(updatedProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Artikel "${updatedProduct.name}" erfolgreich aktualisiert',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Aktualisieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit, color: Colors.blue),
          const SizedBox(width: 8),
          Text('📝 "${widget.product.name}" bearbeiten'),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 650, // Erhöht für zusätzliche Felder
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info-Box
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vollständige Backend-Integration - Alle Änderungen werden direkt gespeichert',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Artikel-Name *',
                    prefixIcon: Icon(Icons.shopping_cart),
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
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Preis und Barcode
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Preis (€) *',
                          prefixIcon: Icon(Icons.euro),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Preis erforderlich';
                          }
                          if (_parseGermanPrice(value) == null) {
                            return 'Ungültiger Preis';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode (optional)',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Kategorie-Auswahl
                _isCategoriesLoading
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Kategorien werden geladen...'),
                        ],
                      )
                    : _availableCategories.isEmpty
                    ? const Text(
                        '⚠️ Keine Kategorien verfügbar',
                        style: TextStyle(color: Colors.orange),
                      )
                    : DropdownButtonFormField<ProductCategory>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategorie *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _availableCategories.map((category) {
                          return DropdownMenuItem<ProductCategory>(
                            value: category,
                            child: IntrinsicWidth(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(
                                          category.colorHex.replaceFirst(
                                            '#',
                                            '0xFF',
                                          ),
                                        ),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (category) {
                          setState(() => _selectedCategory = category);
                        },
                        validator: (value) {
                          if (value == null) return 'Kategorie erforderlich';
                          return null;
                        },
                      ),
                const SizedBox(height: 16),

                // Steuerklasse-Auswahl
                _isTaxClassesLoading
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Steuerklassen werden geladen...'),
                        ],
                      )
                    : _availableTaxClasses.isEmpty
                    ? const Text(
                        '⚠️ Keine Steuerklassen verfügbar',
                        style: TextStyle(color: Colors.orange),
                      )
                    : DropdownButtonFormField<TaxClass>(
                        value: _selectedTaxClass,
                        decoration: InputDecoration(
                          labelText:
                              'Steuerklasse * (${_facilityCountry?.displayName ?? ""})',
                          prefixIcon: const Icon(Icons.account_balance),
                        ),
                        items: _availableTaxClasses.map((taxClass) {
                          return DropdownMenuItem<TaxClass>(
                            value: taxClass,
                            child: IntrinsicWidth(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(
                                          taxClass.colorHex.replaceFirst(
                                            '#',
                                            '0xFF',
                                          ),
                                        ),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${taxClass.name} (${taxClass.taxRate.toStringAsFixed(1)}%)',
                                  ),
                                  if (taxClass.isDefault) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (taxClass) {
                          setState(() => _selectedTaxClass = taxClass);
                        },
                        validator: (value) {
                          if (value == null) return 'Steuerklasse erforderlich';
                          return null;
                        },
                      ),
                const SizedBox(height: 16),

                // Bestand
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Bestand (optional)',
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Lebensmittel-Checkbox
                CheckboxListTile(
                  title: const Text('Ist Lebensmittel'),
                  subtitle: const Text('Für spezielle Compliance-Regeln'),
                  value: _isFoodItem,
                  onChanged: (value) {
                    setState(() => _isFoodItem = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),

                // Aktiv-Status
                SwitchListTile(
                  title: const Text('Artikel ist aktiv'),
                  subtitle: const Text('Aktive Artikel sind im POS verfügbar'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Artikel aktualisieren'),
        ),
      ],
    );
  }
}

// ==================== KATEGORIEN-ERSTELLUNG DIALOG ====================

class CreateCategoryDialog extends StatefulWidget {
  final Function(ProductCategory) onCategoryCreated;

  const CreateCategoryDialog({super.key, required this.onCategoryCreated});

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedColor = '#607D8B';
  String _selectedIcon = 'category';
  bool _isFavorites = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availableColors = [
    {'name': 'Grau', 'hex': '#607D8B'},
    {'name': 'Blau', 'hex': '#2196F3'},
    {'name': 'Grün', 'hex': '#4CAF50'},
    {'name': 'Orange', 'hex': '#FF9800'},
    {'name': 'Rot', 'hex': '#F44336'},
    {'name': 'Lila', 'hex': '#9C27B0'},
    {'name': 'Braun', 'hex': '#795548'},
    {'name': 'Cyan', 'hex': '#00BCD4'},
  ];

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'Kategorie', 'icon': 'category'},
    {'name': 'Fastfood', 'icon': 'fastfood'},
    {'name': 'Getränke', 'icon': 'local_drink'},
    {'name': 'Snacks', 'icon': 'lunch_dining'},
    {'name': 'Sport', 'icon': 'sports'},
    {'name': 'Kleidung', 'icon': 'checkroom'},
    {'name': 'Zubehör', 'icon': 'build'},
    {'name': 'Favoriten', 'icon': 'favorite'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = Provider.of<Client>(context, listen: false);
      final newCategory = await client.productManagement.createProductCategory(
        _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        colorHex: _selectedColor,
        iconName: _selectedIcon,
        isFavorites: _isFavorites,
        displayOrder: 0,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCategoryCreated(newCategory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Erstellen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('🆕 Neue Kategorie erstellen'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie-Name *',
                    hintText: 'z.B. Getränke, Snacks, Sport...',
                    prefixIcon: Icon(Icons.label),
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
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    hintText: 'Kurze Beschreibung der Kategorie...',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Farbe
                const Text(
                  'Farbe:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableColors.map((colorData) {
                    final isSelected = _selectedColor == colorData['hex'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedColor = colorData['hex']),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                              colorData['hex'].replaceFirst('#', '0xFF'),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Icon
                const Text(
                  'Icon:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableIcons.map((iconData) {
                    final isSelected = _selectedIcon == iconData['icon'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedIcon = iconData['icon']),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          _getIconData(iconData['icon']),
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Favoriten-Kategorie Checkbox
                CheckboxListTile(
                  title: const Text('Als Favoriten-Kategorie markieren'),
                  subtitle: const Text('Nur eine Favoriten-Kategorie möglich'),
                  value: _isFavorites,
                  onChanged: (value) =>
                      setState(() => _isFavorites = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),

                // Hinweis
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Hinweis',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Steuerklassen werden für einzelne Produkte gesetzt',
                      ),
                      Text('• Kategorien dienen der thematischen Ordnung'),
                      Text('• System-Kategorien können nicht gelöscht werden'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCategory,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Erstellen'),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'local_drink':
        return Icons.local_drink;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'sports':
        return Icons.sports;
      case 'checkroom':
        return Icons.checkroom;
      case 'build':
        return Icons.build;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.category;
    }
  }
}
// ==================== KATEGORIEN-BEARBEITUNG DIALOG ====================

class EditCategoryDialog extends StatefulWidget {
  final ProductCategory category;
  final Function(ProductCategory) onCategoryUpdated;

  const EditCategoryDialog({
    super.key,
    required this.category,
    required this.onCategoryUpdated,
  });

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late String _selectedColor;
  late String _selectedIcon;
  late bool _isFavorites;
  late bool _isActive;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availableColors = [
    {'name': 'Grau', 'hex': '#607D8B'},
    {'name': 'Blau', 'hex': '#2196F3'},
    {'name': 'Grün', 'hex': '#4CAF50'},
    {'name': 'Orange', 'hex': '#FF9800'},
    {'name': 'Rot', 'hex': '#F44336'},
    {'name': 'Lila', 'hex': '#9C27B0'},
    {'name': 'Braun', 'hex': '#795548'},
    {'name': 'Cyan', 'hex': '#00BCD4'},
  ];

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'Kategorie', 'icon': 'category'},
    {'name': 'Fastfood', 'icon': 'fastfood'},
    {'name': 'Getränke', 'icon': 'local_drink'},
    {'name': 'Snacks', 'icon': 'lunch_dining'},
    {'name': 'Sport', 'icon': 'sports'},
    {'name': 'Kleidung', 'icon': 'checkroom'},
    {'name': 'Zubehör', 'icon': 'build'},
    {'name': 'Favoriten', 'icon': 'favorite'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _descriptionController = TextEditingController(
      text: widget.category.description ?? '',
    );
    _selectedColor = widget.category.colorHex;
    _selectedIcon = widget.category.iconName;
    _isFavorites = widget.category.isFavorites;
    _isActive = widget.category.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = Provider.of<Client>(context, listen: false);
      // TODO: updateProductCategory implementieren
      throw Exception('Update-Funktion wird noch implementiert');

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCategoryUpdated(widget.category);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Aktualisieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSystemCategory = widget.category.isSystemCategory;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit, color: Colors.blue),
          const SizedBox(width: 8),
          Text('📝 "${widget.category.name}" bearbeiten'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSystemCategory)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'System-Kategorie - nur eingeschränkte Bearbeitung möglich',
                          ),
                        ),
                      ],
                    ),
                  ),

                // Name
                TextFormField(
                  controller: _nameController,
                  enabled: !isSystemCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie-Name *',
                    prefixIcon: Icon(Icons.label),
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
                  enabled: !isSystemCategory,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Farbe
                const Text(
                  'Farbe:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableColors.map((colorData) {
                    final isSelected = _selectedColor == colorData['hex'];
                    return GestureDetector(
                      onTap: isSystemCategory
                          ? null
                          : () => setState(
                              () => _selectedColor = colorData['hex'],
                            ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(
                              colorData['hex'].replaceFirst('#', '0xFF'),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Status
                SwitchListTile(
                  title: const Text('Aktiv'),
                  subtitle: const Text('Kategorie ist verfügbar'),
                  value: _isActive,
                  onChanged: isSystemCategory
                      ? null
                      : (value) => setState(() => _isActive = value),
                ),

                // Favoriten nur wenn nicht System-Kategorie
                if (!isSystemCategory) ...[
                  CheckboxListTile(
                    title: const Text('Als Favoriten-Kategorie markieren'),
                    subtitle: const Text(
                      'Nur eine Favoriten-Kategorie möglich',
                    ),
                    value: _isFavorites,
                    onChanged: (value) =>
                        setState(() => _isFavorites = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateCategory,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}

/// **🎨 KATEGORIE-KONFIGURATION** - Helper-Klasse für einheitliches Design mit POS
class CategoryConfig {
  final Color color;
  final IconData icon;
  final String name;

  CategoryConfig({required this.color, required this.icon, required this.name});
}
