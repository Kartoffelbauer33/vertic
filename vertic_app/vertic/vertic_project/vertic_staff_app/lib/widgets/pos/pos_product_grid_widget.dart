import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';

/// **🛒 POS PRODUCT GRID WIDGET - Reine UI-Komponente für Produkt-Grid**
/// 
/// Diese Komponente ist eine 1:1-Extraktion der ursprünglichen _buildProductGrid() Methode
/// und ihrer Hilfsmethoden. KEINE LOGIK-ÄNDERUNGEN - nur UI-Code ausgelagert für bessere Wartbarkeit.
/// 
/// Alle State-Änderungen erfolgen weiterhin über Callbacks in der Haupt-Page.
class PosProductGridWidget extends StatelessWidget {
  final bool isLiveSearchActive;
  final List<dynamic> filteredProducts;
  final bool showingSubCategories;
  final String? currentTopLevelCategory;
  final String? selectedCategory;
  final Map<String, List<dynamic>> categorizedItems;
  final Map<String, Map<String, dynamic>> categoryHierarchy;
  final VoidCallback onNavigateToTopLevel;
  final Function(String subCategory) onSelectSubCategory;
  final Widget Function() buildLiveFilterResults;
  final Widget Function(TicketType ticketType) buildTicketCard;
  final Widget Function(Product product) buildProductCard;

  const PosProductGridWidget({
    super.key,
    required this.isLiveSearchActive,
    required this.filteredProducts,
    required this.showingSubCategories,
    this.currentTopLevelCategory,
    this.selectedCategory,
    required this.categorizedItems,
    required this.categoryHierarchy,
    required this.onNavigateToTopLevel,
    required this.onSelectSubCategory,
    required this.buildLiveFilterResults,
    required this.buildTicketCard,
    required this.buildProductCard,
  });

  @override
  Widget build(BuildContext context) {
    // 🔍 LIVE-FILTER: Prüfe ob Live-Filter aktiv ist
    if (isLiveSearchActive && filteredProducts.isNotEmpty) {
      return buildLiveFilterResults();
    }

    // 🆕 HIERARCHISCHE ITEM-AUSWAHL (Standard-Verhalten)
    List<dynamic> items = [];

    debugPrint('🛒 UI-DEBUG: PosProductGridWidget.build()');
    debugPrint('   📂 showingSubCategories: $showingSubCategories');
    debugPrint('   📂 currentTopLevelCategory: $currentTopLevelCategory');
    debugPrint('   📂 selectedCategory: $selectedCategory');
    debugPrint('   🔍 isLiveSearchActive: $isLiveSearchActive');

    if (showingSubCategories && currentTopLevelCategory != null) {
      // Sub-Kategorie-Items anzeigen
      final hierarchyData = categoryHierarchy[currentTopLevelCategory!];
      final subCategories =
          (hierarchyData?['subCategories'] as Map<String, List<dynamic>>?) ?? <String, List<dynamic>>{};
      items = subCategories[selectedCategory] ?? <dynamic>[];
      debugPrint('   📦 Sub-Kategorie-Items: ${items.length}');
    } else {
      // Top-Level-Items anzeigen
      items = categorizedItems[selectedCategory] ?? <dynamic>[];
      debugPrint('   📦 Top-Level-Items: ${items.length}');
    }

    debugPrint('   🛒 Finale Items zum Anzeigen: ${items.length}');

    if (items.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                showingSubCategories
                    ? Icons.subdirectory_arrow_right
                    : Icons.category,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                showingSubCategories
                    ? 'Keine Artikel in dieser Unterkategorie verfügbar'
                    : 'Keine Artikel in $selectedCategory verfügbar',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (showingSubCategories) ...[
                TextButton.icon(
                  onPressed: onNavigateToTopLevel,
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Zurück zur Übersicht'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🆕 HIERARCHIE-INFO-HEADER
            if (showingSubCategories) _buildSubCategoryHeader(context),

            // ARTIKEL-GRID
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, // Erhöht von 4 auf 6 für kleinere Buttons
                  crossAxisSpacing: 6, // Reduziert von 8 auf 6
                  mainAxisSpacing: 6, // Reduziert von 8 auf 6
                  childAspectRatio: 0.9, // Leicht angepasst von 1.0 auf 0.9
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is TicketType) {
                    return buildTicketCard(item);
                  } else if (item is Product) {
                    return buildProductCard(item);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **📁 SUB-KATEGORIE HEADER mit Statistiken**
  Widget _buildSubCategoryHeader(BuildContext context) {
    if (currentTopLevelCategory == null || selectedCategory == null) {
      return const SizedBox();
    }

    final hierarchyData = categoryHierarchy[currentTopLevelCategory!];
    final subCategories =
        (hierarchyData?['subCategories'] as Map<String, List<dynamic>>?) ?? <String, List<dynamic>>{};
    final currentItems = subCategories[selectedCategory] ?? <dynamic>[];
    final parentColor = (hierarchyData?['color'] as Color?) ?? Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: parentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: parentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right, color: parentColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedCategory!.replaceAll(RegExp(r'^[^\s]+ '), ''),
                  style: TextStyle(
                    color: parentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${currentItems.length} Artikel in dieser Unterkategorie',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          // Schnell-Navigation zu anderen Sub-Kategorien
          if (subCategories.length > 1) ...[
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: parentColor),
              tooltip: 'Andere Unterkategorien',
              onSelected: (subCategory) => onSelectSubCategory(subCategory),
              itemBuilder: (context) {
                return subCategories.keys
                    .where((key) => key != selectedCategory)
                    .map((subCategory) {
                      final itemCount = subCategories[subCategory]?.length ?? 0;
                      return PopupMenuItem<String>(
                        value: subCategory,
                        child: Row(
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right,
                              size: 16,
                              color: parentColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subCategory.replaceAll(RegExp(r'^[^\s]+ '), ''),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: parentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$itemCount',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: parentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList();
              },
            ),
          ],
        ],
      ),
    );
  }
}
