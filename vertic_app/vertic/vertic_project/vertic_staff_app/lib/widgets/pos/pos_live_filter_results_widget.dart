import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';

/// **🔍 POS LIVE-FILTER RESULTS WIDGET**
/// 
/// Standalone UI-Komponente für Live-Filter-Suchergebnisse im POS-System.
/// Zeigt gefilterte Produkte mit Statistiken und Header-Informationen an.
/// 
/// **Features:**
/// - Live-Filter Header mit Statistiken
/// - Gefilterte Artikel-Grid
/// - Empty-State bei keinen Ergebnissen
/// - Reset-Funktionalität
/// 
/// **Reine UI-Komponente:** Alle Callbacks werden an Parent-Widget weitergegeben.
class PosLiveFilterResultsWidget extends StatelessWidget {
  final List<Product> filteredProducts;
  final String liveSearchQuery;
  final Map<String, int> categoryArticleCounts;
  final VoidCallback onResetLiveFilter;
  final Widget Function(Product) buildProductCard;

  const PosLiveFilterResultsWidget({
    super.key,
    required this.filteredProducts,
    required this.liveSearchQuery,
    required this.categoryArticleCounts,
    required this.onResetLiveFilter,
    required this.buildProductCard,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredProducts.isEmpty) {
      return Expanded(
        child: Center(
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
                'Keine Artikel gefunden für "$liveSearchQuery"',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onResetLiveFilter,
                icon: const Icon(Icons.clear),
                label: const Text('Filter zurücksetzen'),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
              ),
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
            // LIVE-FILTER HEADER
            _buildLiveFilterHeader(),
            
            const SizedBox(height: 16),

            // GEFILTERTE ARTIKEL-GRID
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.9,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return buildProductCard(product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **📊 LIVE-FILTER HEADER: Zeigt Statistiken und Filter-Info**
  Widget _buildLiveFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live-Filter Ergebnisse',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
              // Reset-Button
              IconButton(
                onPressed: onResetLiveFilter,
                icon: Icon(
                  Icons.clear,
                  color: Colors.orange.shade600,
                ),
                tooltip: 'Filter zurücksetzen',
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Statistiken
          Row(
            children: [
              Expanded(
                child: _buildFilterStat(
                  'Artikel gefunden',
                  '${filteredProducts.length}',
                  Icons.shopping_bag,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterStat(
                  'Suchbegriff',
                  '"$liveSearchQuery"',
                  Icons.search,
                  Colors.blue,
                ),
              ),
              if (categoryArticleCounts.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterStat(
                    'Kategorien',
                    '${categoryArticleCounts.length}',
                    Icons.category,
                    Colors.purple,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// **📈 FILTER-STATISTIK: Einzelne Statistik-Karte**
  Widget _buildFilterStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
