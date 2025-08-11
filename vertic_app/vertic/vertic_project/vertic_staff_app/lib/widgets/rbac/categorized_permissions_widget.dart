import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';

/// **Kategorisierte Permission-Anzeige Widget**
/// 
/// Zeigt Permissions in logischen Kategorien gruppiert für bessere Übersicht.
/// Jede Kategorie ist ein erweiterbarer Abschnitt mit spezifischen Icons und Farben.
class CategorizedPermissionsWidget extends StatefulWidget {
  final List<Permission> permissions;
  final String searchQuery;
  final VoidCallback? onRefresh;

  const CategorizedPermissionsWidget({
    super.key,
    required this.permissions,
    this.searchQuery = '',
    this.onRefresh,
  });

  @override
  State<CategorizedPermissionsWidget> createState() => _CategorizedPermissionsWidgetState();
}

class _CategorizedPermissionsWidgetState extends State<CategorizedPermissionsWidget> {
  final Map<String, bool> _expandedCategories = {};

  /// **Kategorien-Konfiguration mit Icons, Farben und Übersetzungen**
  static const Map<String, Map<String, dynamic>> _categoryConfig = {
    'user': {
      'displayName': 'Benutzerverwaltung',
      'icon': Icons.people,
      'color': Colors.blue,
      'description': 'Verwalten von App-Benutzern und deren Daten',
    },
    'staff': {
      'displayName': 'Mitarbeiterverwaltung',
      'icon': Icons.badge,
      'color': Colors.indigo,
      'description': 'Verwalten von Staff-Benutzern und deren Rollen',
    },
    'tickets': {
      'displayName': 'Ticket-Verwaltung',
      'icon': Icons.confirmation_number,
      'color': Colors.green,
      'description': 'Verwalten von Tickets, Typen und Preisen',
    },
    'facility': {
      'displayName': 'Anlagen-Management',
      'icon': Icons.business,
      'color': Colors.orange,
      'description': 'Verwalten von Hallen, Räumen und Ausstattung',
    },
    'system': {
      'displayName': 'System-Einstellungen',
      'icon': Icons.settings,
      'color': Colors.purple,
      'description': 'Grundlegende Systemkonfiguration und -einstellungen',
    },
    'reports': {
      'displayName': 'Berichte & Analytics',
      'icon': Icons.analytics,
      'color': Colors.teal,
      'description': 'Zugriff auf Berichte, Statistiken und Analytics',
    },
    'document': {
      'displayName': 'Dokumenten-Management',
      'icon': Icons.description,
      'color': Colors.brown,
      'description': 'Verwalten von Dokumenten und Vereinbarungen',
    },
    'billing': {
      'displayName': 'Abrechnungs-System',
      'icon': Icons.receipt_long,
      'color': Colors.red,
      'description': 'Rechnungsstellung, Zahlungen und Finanzen',
    },
    'printer': {
      'displayName': 'Drucker-Management',
      'icon': Icons.print,
      'color': Colors.grey,
      'description': 'Druckerkonfiguration und -verwaltung',
    },
    'audit': {
      'displayName': 'Audit & Protokollierung',
      'icon': Icons.history,
      'color': Colors.deepOrange,
      'description': 'Audit-Logs und Systemprotokollierung',
    },
  };

  @override
  void initState() {
    super.initState();
    // Alle Kategorien initial erweitern (bessere UX)
    for (String category in _getAvailableCategories()) {
      _expandedCategories[category] = true;
    }
  }

  /// **Ermittelt alle verfügbaren Kategorien aus den Permissions**
  List<String> _getAvailableCategories() {
    final categories = widget.permissions
        .map((p) => p.category.toLowerCase())
        .toSet()
        .toList();
    
    // Sortiere Kategorien nach Priorität
    categories.sort((a, b) {
      final priorityOrder = [
        'user', 'staff', 'tickets', 'facility', 
        'system', 'reports', 'document', 'billing', 
        'printer', 'audit'
      ];
      
      final aIndex = priorityOrder.indexOf(a);
      final bIndex = priorityOrder.indexOf(b);
      
      if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      
      return aIndex.compareTo(bIndex);
    });
    
    return categories;
  }

  /// **Filtert Permissions nach Suchbegriff**
  List<Permission> _getFilteredPermissions(String category) {
    return widget.permissions.where((permission) {
      final matchesCategory = permission.category.toLowerCase() == category;
      final matchesSearch = widget.searchQuery.isEmpty ||
          permission.name.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          permission.displayName.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          (permission.description?.toLowerCase().contains(widget.searchQuery.toLowerCase()) ?? false);
      
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// **Holt Kategorie-Konfiguration mit Fallback**
  Map<String, dynamic> _getCategoryConfig(String category) {
    return _categoryConfig[category] ?? {
      'displayName': category.toUpperCase(),
      'icon': Icons.security,
      'color': Colors.grey,
      'description': 'Nicht kategorisierte Berechtigungen',
    };
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getAvailableCategories();
    
    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Kategorien-Übersicht
            _buildCategoriesHeader(categories),
            const SizedBox(height: 16),
            
            // Kategorisierte Permission-Listen
            ...categories.map((category) => _buildCategorySection(category)),
          ],
        ),
      ),
    );
  }

  /// **Header mit Kategorien-Übersicht**
  Widget _buildCategoriesHeader(List<String> categories) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Permission-Kategorien',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const Spacer(),
              if (widget.onRefresh != null)
                IconButton(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Aktualisieren',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final config = _getCategoryConfig(category);
              final permissionCount = _getFilteredPermissions(category).length;
              
              return Chip(
                avatar: Icon(
                  config['icon'],
                  size: 16,
                  color: config['color'],
                ),
                label: Text('${config['displayName']} ($permissionCount)'),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
          if (widget.searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Gefiltert nach: "${widget.searchQuery}"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// **Kategorie-Abschnitt mit erweiterbaren Permissions**
  Widget _buildCategorySection(String category) {
    final config = _getCategoryConfig(category);
    final permissions = _getFilteredPermissions(category);
    final isExpanded = _expandedCategories[category] ?? false;
    
    if (permissions.isEmpty) {
      return const SizedBox.shrink(); // Verstecke leere Kategorien
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Kategorie-Header (klickbar zum Erweitern/Minimieren)
          InkWell(
            onTap: () {
              setState(() {
                _expandedCategories[category] = !isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (config['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    config['icon'],
                    color: config['color'],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config['displayName'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: config['color'],
                          ),
                        ),
                        Text(
                          config['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: config['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      permissions.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: config['color'],
                  ),
                ],
              ),
            ),
          ),
          
          // Permission-Liste (erweiterbar)
          if (isExpanded) ...permissions.map((permission) => _buildPermissionTile(permission)),
        ],
      ),
    );
  }

  /// **Einzelne Permission-Kachel**
  Widget _buildPermissionTile(Permission permission) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: permission.isSystemCritical ? Colors.red : Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          permission.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${permission.name}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.grey[700],
              ),
            ),
            if (permission.description != null) ...[
              const SizedBox(height: 2),
              Text(
                permission.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: permission.isSystemCritical
            ? Tooltip(
                message: 'System-kritische Berechtigung',
                child: Icon(
                  Icons.warning,
                  color: Colors.red[600],
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }

  /// **Empty State - keine Permissions gefunden**
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.searchQuery.isNotEmpty ? Icons.search_off : Icons.security,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.searchQuery.isNotEmpty
                  ? 'Keine Permissions gefunden für "${widget.searchQuery}"'
                  : 'Keine Permissions verfügbar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.searchQuery.isNotEmpty
                  ? 'Versuchen Sie einen anderen Suchbegriff.'
                  : 'Permissions müssen erst im System definiert werden.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}