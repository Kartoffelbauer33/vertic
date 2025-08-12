import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../auth/permission_provider.dart';

/// **🗂️ POS CATEGORY NAVIGATION WIDGET - Reine UI-Komponente für Kategorie-Navigation**
/// 
/// Diese Komponente ist eine 1:1-Extraktion der ursprünglichen _buildCategoryTabs() Methode
/// und ihrer Hilfsmethoden. KEINE LOGIK-ÄNDERUNGEN - nur UI-Code ausgelagert für bessere Wartbarkeit.
/// 
/// Alle State-Änderungen erfolgen weiterhin über Callbacks in der Haupt-Page.
class PosCategoryNavigationWidget extends StatelessWidget {
  final List<String> categoryBreadcrumb;
  final bool showingSubCategories;
  final String? currentTopLevelCategory;
  final String? selectedCategory;
  final Map<String, Map<String, dynamic>> categoryHierarchy;
  final VoidCallback onNavigateToTopLevel;
  final Function(int index) onNavigateToBreadcrumb;
  final Function(String categoryName) onSelectTopLevelCategory;
  final Function(String topLevelCategory) onNavigateToSubCategories;
  final Function(String subCategoryName) onSelectSubCategory;

  const PosCategoryNavigationWidget({
    super.key,
    required this.categoryBreadcrumb,
    required this.showingSubCategories,
    this.currentTopLevelCategory,
    this.selectedCategory,
    required this.categoryHierarchy,
    required this.onNavigateToTopLevel,
    required this.onNavigateToBreadcrumb,
    required this.onSelectTopLevelCategory,
    required this.onNavigateToSubCategories,
    required this.onSelectSubCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, permissionProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🆕 BREADCRUMB-NAVIGATION
              if (categoryBreadcrumb.isNotEmpty) _buildBreadcrumbNavigation(context),

              // Titel mit hierarchie-Info
              Row(
                children: [
                  Text(
                    showingSubCategories
                        ? 'Unterkategorien'
                        : 'Artikel-Katalog',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  if (showingSubCategories && currentTopLevelCategory != null) ...[
                    TextButton.icon(
                      onPressed: onNavigateToTopLevel,
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      label: const Text('Zurück zur Übersicht'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // 🆕 HIERARCHISCHE KATEGORIE-ANZEIGE
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Immer zuerst Top-Level anzeigen
                  _buildTopLevelCategoryTabs(context),

                  // Dann Sub-Kategorien wenn verfügbar
                  if (showingSubCategories) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.subdirectory_arrow_right,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Unterkategorien:',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSubCategoryTabs(context),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// **🍞 BREADCRUMB-NAVIGATION**
  Widget _buildBreadcrumbNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              children: categoryBreadcrumb.asMap().entries.map((entry) {
                final index = entry.key;
                final categoryName = entry.value;
                final isLast = index == categoryBreadcrumb.length - 1;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isLast ? null : () => onNavigateToBreadcrumb(index),
                      child: Text(
                        categoryName.length > 15
                            ? '${categoryName.substring(0, 15)}...'
                            : categoryName,
                        style: TextStyle(
                          color: isLast ? Colors.blue[800] : Colors.blue[600],
                          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                          decoration: isLast ? null : TextDecoration.underline,
                        ),
                      ),
                    ),
                    if (!isLast) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: Colors.blue[400],
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// **🏗️ TOP-LEVEL-KATEGORIEN ANZEIGEN**
  Widget _buildTopLevelCategoryTabs(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoryHierarchy.length,
        itemBuilder: (context, index) {
          final topLevelCategory = categoryHierarchy.keys.elementAt(index);
          final hierarchyData = categoryHierarchy[topLevelCategory]!;
          final isSelected = currentTopLevelCategory == topLevelCategory;
          final color = (hierarchyData['color'] as Color?) ?? Colors.blue;
          final icon = (hierarchyData['icon'] as IconData?) ?? Icons.category;
          final totalItems = (hierarchyData['totalItems'] as int?) ?? 0;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              elevation: isSelected ? 8 : 3,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (isSelected) {
                    // Bereits ausgewählt: Zu Sub-Kategorien navigieren
                    onNavigateToSubCategories(topLevelCategory);
                  } else {
                    // Neue Auswahl: Top-Level-Kategorie auswählen
                    onSelectTopLevelCategory(topLevelCategory);
                  }
                },
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected ? color : Colors.white,
                    border: Border.all(
                      color: color.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top-Level Icon
                      Icon(
                        icon,
                        color: isSelected ? Colors.white : color,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      // Top-Level Name
                      Flexible(
                        child: Text(
                          topLevelCategory.replaceAll(RegExp(r'^[^\s]+ '), ''),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Artikel-Anzahl
                      Text(
                        '$totalItems Artikel',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// **📁 SUB-KATEGORIEN ANZEIGEN**
  Widget _buildSubCategoryTabs(BuildContext context) {
    if (currentTopLevelCategory == null) return const SizedBox();

    final hierarchyData = categoryHierarchy[currentTopLevelCategory!];
    final subCategories =
        (hierarchyData?['subCategories'] as Map<String, List<dynamic>>?) ?? <String, List<dynamic>>{};

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: subCategories.length,
        itemBuilder: (context, index) {
          final subCategoryName = subCategories.keys.elementAt(index);
          final subCategoryItems = subCategories[subCategoryName] ?? <dynamic>[];
          final isSelected = selectedCategory == subCategoryName;

          // Farbe vom Parent übernehmen
          final parentColor = (hierarchyData?['color'] as Color?) ?? Colors.blue;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              elevation: isSelected ? 6 : 2,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelectSubCategory(subCategoryName),
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected ? parentColor : Colors.white,
                    border: Border.all(
                      color: parentColor.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sub-Kategorie Icon
                      Icon(
                        Icons.subdirectory_arrow_right,
                        color: isSelected ? Colors.white : parentColor,
                        size: 16,
                      ),
                      const SizedBox(height: 3),
                      // Sub-Kategorie Name
                      Flexible(
                        child: Text(
                          subCategoryName.replaceAll(RegExp(r'^[^\s]+ '), ''),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Artikel-Anzahl
                      const SizedBox(height: 1),
                      Text(
                        '${subCategoryItems.length}',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                          fontSize: 7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
