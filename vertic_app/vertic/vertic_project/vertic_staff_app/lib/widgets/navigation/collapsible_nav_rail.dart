//vertic_staff_app/lib/widgets/navigation/collapsible_nav_rail.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:vertic_staff/design_system/design_system.dart';
import 'package:vertic_staff/main.dart';
import 'package:vertic_staff/widgets/navigation/nav_items.dart';
import 'package:vertic_staff/widgets/navigation/nav_models.dart';

class CollapsibleNavRail extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onExpansionChanged;
  final Function(String) onRouteSelected;
  final String selectedRoute;

  const CollapsibleNavRail({
    super.key,
    required this.onRouteSelected,
    required this.selectedRoute,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  @override
  State<CollapsibleNavRail> createState() => _CollapsibleNavRailState();
}

class _CollapsibleNavRailState extends State<CollapsibleNavRail>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final Map<String, bool> _expandedItems = {};
  bool _isAccountMenuExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<NavItem> _filteredNavItems = [];
  OverlayEntry? _mobileOverlay;
  late AnimationController _burgerController;
  late Animation<double> _burgerAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateFilteredItems();
    _initializeExpandedState();
    
    _burgerController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _burgerAnimation = CurvedAnimation(
      parent: _burgerController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _burgerController.dispose();
    _removeMobileOverlay();
    super.dispose();
  }

  @override
  void didUpdateWidget(CollapsibleNavRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoute != widget.selectedRoute) {
      _updateExpandedStateForCurrentRoute();
    }
  }

  void _initializeExpandedState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isExpanded) {
        _updateExpandedStateForCurrentRoute();
      }
    });
  }

  void _updateExpandedStateForCurrentRoute() {
    final allItems = [
      ...mainNavItems,
      ...planningNavItems,
      ...reportsNavItems,
      ...settingsNavItems,
      ...administrationNavItems,
      ...designNavItems,
      ...adminNavItems,
    ];

    for (final item in allItems) {
      if (item.children.isNotEmpty) {
        final hasSelectedChild = item.children.any(
          (child) => child.route == widget.selectedRoute,
        );

        if (hasSelectedChild || item.route == widget.selectedRoute) {
          setState(() {
            _expandedItems.clear();
            if (item.route != null) {
              _expandedItems[item.route!] = true;
            }
          });
          break;
        }
      }
    }
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  void _handleNavigation(String route) {
    widget.onRouteSelected(route);
    
    // Auto-collapse on mobile after navigation
    if (_isMobile && _mobileOverlay != null) {
      _removeMobileOverlay();
      _burgerController.reverse();
    }
  }

  void _toggleMobileMenu() {
    if (_mobileOverlay != null) {
      _removeMobileOverlay();
    } else {
      _showMobileOverlay();
    }
    _burgerController.isCompleted
        ? _burgerController.reverse()
        : _burgerController.forward();
  }

  void _showMobileOverlay() {
    _mobileOverlay = OverlayEntry(
      builder: (context) => _MobileNavOverlay(
        selectedRoute: widget.selectedRoute,
        onRouteSelected: _handleNavigation,
        onClose: () {
          _removeMobileOverlay();
          _burgerController.reverse();
        },
        expandedItems: _expandedItems,
        onToggleExpanded: _toggleMenuExpansion,
        isAccountMenuExpanded: _isAccountMenuExpanded,
        onToggleAccountMenu: () {
          setState(() {
            _isAccountMenuExpanded = !_isAccountMenuExpanded;
          });
        },
      ),
    );
    Overlay.of(context).insert(_mobileOverlay!);
  }

  void _removeMobileOverlay() {
    _mobileOverlay?.remove();
    _mobileOverlay = null;
  }

  void _toggleMenuExpansion(String? route) {
    if (route == null) return;
    setState(() {
      final wasExpanded = _expandedItems[route] ?? false;
      _expandedItems.clear();
      if (!wasExpanded) {
        _expandedItems[route] = true;
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        if (size.width < 768 && widget.isExpanded) {
          // Auto-close menu on small screen sizes
        }
      }
    });
  }

  void _updateFilteredItems() {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) {
      _filteredNavItems = [];
    } else {
      _filteredNavItems = [];
    final allItems = [
      ...mainNavItems,
      ...planningNavItems,
      ...reportsNavItems,
      ...settingsNavItems,
      ...administrationNavItems,
      ...designNavItems,
      ...adminNavItems,
    ];

    for (final item in allItems) {
        if (item.title.toLowerCase().contains(query)) {
        _filteredNavItems.add(item);
      }
      for (final child in item.children) {
          if (child.title.toLowerCase().contains(query)) {
            _filteredNavItems.add(child);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    // Mobile Burger Button
    if (_isMobile) {
      return Positioned(
        top: spacing.md,
        left: spacing.md,
        child: Material(
        color: colors.surface,
          elevation: 4,
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          child: InkWell(
            onTap: _toggleMobileMenu,
            borderRadius: BorderRadius.circular(spacing.radiusMd),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(spacing.radiusMd),
                border: Border.all(
                  color: colors.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: AnimatedBuilder(
                animation: _burgerAnimation,
                builder: (context, child) {
                  return Icon(
                    _burgerAnimation.value > 0.5 ? LucideIcons.x : LucideIcons.menu,
                    color: colors.onSurface,
                    size: 24,
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    // Desktop Navigation Rail
    return Container(
      width: widget.isExpanded ? 280 : 64,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(
            color: colors.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
          child: Column(
            children: [
          _buildHeader(colors, spacing),
          if (widget.isExpanded) _buildSearchField(colors, spacing),
              const Divider(height: 1),
              Expanded(
            child: _buildNavigationItems(colors, spacing),
              ),
              const Divider(height: 1),
          _buildFooter(colors, spacing),
            ],
      ),
    );
  }

  Widget _buildHeader(dynamic colors, dynamic spacing) {
    return Container(
      padding: EdgeInsets.all(spacing.md),
      child: Row(
                children: [
          Container(
            width: 32,
            height: 32,
                      child: SvgPicture.asset(
                        'assets/svg/vertic_logo.svg',
              colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
            ),
          ),
          if (widget.isExpanded) ...[
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                'Vertic',
                style: context.typography.titleMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          IconButton(
            onPressed: widget.onExpansionChanged,
            icon: Icon(
              widget.isExpanded ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
            tooltip: widget.isExpanded ? 'Menü schließen' : 'Menü öffnen',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(dynamic colors, dynamic spacing) {
    if (!widget.isExpanded) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.md),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _updateFilteredItems();
          });
        },
        decoration: InputDecoration(
          hintText: 'Suchen...',
          prefixIcon: Icon(LucideIcons.search, size: spacing.iconXs),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, size: spacing.iconXs),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _updateFilteredItems();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.radiusSm),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing.sm,
            vertical: spacing.xs,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItems(dynamic colors, dynamic spacing) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      child: Column(
        children: [
          if (_searchQuery.isNotEmpty && _filteredNavItems.isNotEmpty) ...[
            ..._filteredNavItems.map((item) => _buildNavItem(item, colors, spacing)),
          ] else if (_searchQuery.isNotEmpty) ...[
            Center(
              child: Padding(
                padding: EdgeInsets.all(spacing.lg),
                child: Text(
                  'Keine Ergebnisse gefunden',
                  style: context.typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ] else ...[
            ...mainNavItems.map((item) => _buildNavItem(item, colors, spacing)),
            _buildSectionDivider(colors, spacing, 'Planung'),
            ...planningNavItems.map((item) => _buildNavItem(item, colors, spacing)),
            _buildSectionDivider(colors, spacing, 'Lagerbestand'),
            ...reportsNavItems.map((item) => _buildNavItem(item, colors, spacing)),
            _buildSectionDivider(colors, spacing, 'Statistiken'),
            ...settingsNavItems.map((item) => _buildNavItem(item, colors, spacing)),
            _buildSectionDivider(colors, spacing, 'Verwaltung'),
            ...administrationNavItems.map((item) => _buildNavItem(item, colors, spacing)),
            ...designNavItems.map((item) => _buildNavItem(item, colors, spacing)),
            ...adminNavItems.map((item) => _buildNavItem(item, colors, spacing)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionDivider(dynamic colors, dynamic spacing, String label) {
    if (!widget.isExpanded) return SizedBox(height: spacing.sm);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: spacing.sm,
        horizontal: spacing.xs,
      ),
              child: Row(
                children: [
                    Expanded(
            child: Divider(
              color: colors.outline.withOpacity(0.3),
              height: 1,
            ),
          ),
          SizedBox(width: spacing.xs),
          Text(
            label,
            style: context.typography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: spacing.xs),
          Expanded(
            child: Divider(
              color: colors.outline.withOpacity(0.3),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(NavItem item, dynamic colors, dynamic spacing, {bool isSubItem = false}) {
    final isSelected = widget.selectedRoute == item.route;
    final hasSelectedChild = item.children.any(
      (child) => child.route == widget.selectedRoute,
    );
    final isExpanded = _expandedItems[item.route] ?? false;
    final hasChildren = item.children.isNotEmpty;

    return Column(
        children: [
          Material(
          color: Colors.transparent,
            borderRadius: BorderRadius.circular(spacing.radiusSm),
            child: InkWell(
              onTap: () {
              if (hasChildren && widget.isExpanded) {
                _toggleMenuExpansion(item.route);
              } else if (item.route != null) {
                _handleNavigation(item.route!);
                }
              },
              borderRadius: BorderRadius.circular(spacing.radiusSm),
              child: Container(
                width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isExpanded ? spacing.sm : spacing.xs,
                vertical: spacing.sm,
              ),
              decoration: BoxDecoration(
                color: (isSelected || hasSelectedChild)
                    ? colors.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(spacing.radiusSm),
              ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                    size: spacing.iconSm,
                    color: (isSelected || hasSelectedChild)
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                  if (widget.isExpanded) ...[
                    SizedBox(width: spacing.sm),
                      Expanded(
                        child: Text(
                          item.title,
                        style: context.typography.bodyMedium.copyWith(
                          color: (isSelected || hasSelectedChild)
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                          fontWeight: (isSelected || hasSelectedChild)
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                      ),
                    ),
                    if (hasChildren)
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                          child: Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                  ],
                ),
              ),
            ),
          ),
        if (hasChildren && isExpanded && widget.isExpanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: EdgeInsets.only(left: spacing.lg, top: spacing.xs),
              child: Column(
              children: item.children
                    .map((child) => _buildNavItem(child, colors, spacing, isSubItem: true))
                  .toList(),
            ),
            ),
          ),
        SizedBox(height: spacing.xs / 2),
      ],
    );
  }

  Widget _buildFooter(dynamic colors, dynamic spacing) {
    return Column(
      children: [
        _buildThemeSwitcher(colors, spacing),
        _buildAccountFooterItem(colors, spacing),
        _buildLogoutButton(colors, spacing),
      ],
    );
  }

  Widget _buildThemeSwitcher(dynamic colors, dynamic spacing) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (!widget.isExpanded) {
          return IconButton(
            onPressed: () => _showThemeMenu(context, themeProvider),
            icon: Icon(
              themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
              color: colors.onSurfaceVariant,
              size: spacing.iconSm,
            ),
            tooltip: 'Theme wechseln',
          );
        }

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(spacing.radiusSm),
          child: InkWell(
            onTap: () => _showThemeMenu(context, themeProvider),
            borderRadius: BorderRadius.circular(spacing.radiusSm),
            child: Container(
              width: double.infinity,
        padding: EdgeInsets.symmetric(
                horizontal: spacing.md,
          vertical: spacing.sm,
        ),
              child: Row(
          children: [
                  Icon(
                    themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                    size: spacing.iconSm,
                    color: colors.onSurfaceVariant,
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      'Theme',
                      style: context.typography.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildAccountFooterItem(dynamic colors, dynamic spacing) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
      borderRadius: BorderRadius.circular(spacing.radiusSm),
      child: InkWell(
        onTap: () {
              if (widget.isExpanded) {
          setState(() {
            _isAccountMenuExpanded = !_isAccountMenuExpanded;
          });
              } else {
                _handleNavigation('/account');
              }
        },
        borderRadius: BorderRadius.circular(spacing.radiusSm),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
                horizontal: spacing.md,
                vertical: spacing.sm,
          ),
          child: Row(
            children: [
                  Icon(
                    LucideIcons.user,
                    size: spacing.iconSm,
                    color: colors.onSurfaceVariant,
              ),
              if (widget.isExpanded) ...[
                SizedBox(width: spacing.sm),
                Expanded(
                      child: Text(
                        'Mein Account',
                        style: context.typography.bodyMedium.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isAccountMenuExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
        ),
        if (_isAccountMenuExpanded && widget.isExpanded)
          Padding(
            padding: EdgeInsets.only(top: spacing.xs * 0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: accountNavItems[0].children
                  .map((child) => _buildNavItem(child, colors, spacing, isSubItem: true))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLogoutButton(dynamic colors, dynamic spacing) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(spacing.radiusSm),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(spacing.radiusSm),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.logOut,
                size: spacing.iconSm,
                color: colors.error,
              ),
              if (widget.isExpanded) ...[
                SizedBox(width: spacing.sm),
                Expanded(
                              child: Text(
                    'Abmelden',
                    style: context.typography.bodyMedium.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeMenu(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ThemeBottomSheet(themeProvider: themeProvider),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden'),
        content: const Text('Möchten Sie sich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement logout logic
            },
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
  }
}

// Mobile Navigation Overlay (simplified version)
class _MobileNavOverlay extends StatelessWidget {
  final String selectedRoute;
  final Function(String) onRouteSelected;
  final VoidCallback onClose;
  final Map<String, bool> expandedItems;
  final Function(String?) onToggleExpanded;
  final bool isAccountMenuExpanded;
  final VoidCallback onToggleAccountMenu;

  const _MobileNavOverlay({
    required this.selectedRoute,
    required this.onRouteSelected,
    required this.onClose,
    required this.expandedItems,
    required this.onToggleExpanded,
    required this.isAccountMenuExpanded,
    required this.onToggleAccountMenu,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Material(
      color: colors.surface.withOpacity(0.95),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colors.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/svg/vertic_logo.svg',
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
                  ),
                  SizedBox(width: spacing.sm),
                  Text(
                    'Vertic',
                    style: context.typography.titleLarge.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      LucideIcons.x,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(spacing.md),
                child: Column(
                  children: [
                    Text('Mobile Navigation Menu - Coming Soon'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Theme Bottom Sheet
class _ThemeBottomSheet extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _ThemeBottomSheet({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Theme auswählen',
            style: context.typography.titleMedium.copyWith(
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: spacing.lg),
          _buildThemeOption(
            context,
            'Hell',
            LucideIcons.sun,
            ThemeMode.light,
            themeProvider.themeMode == ThemeMode.light,
          ),
          _buildThemeOption(
            context,
            'Dunkel',
            LucideIcons.moon,
            ThemeMode.dark,
            themeProvider.themeMode == ThemeMode.dark,
          ),
          _buildThemeOption(
            context,
            'System',
            LucideIcons.smartphone,
            ThemeMode.system,
            themeProvider.themeMode == ThemeMode.system,
          ),
          SizedBox(height: spacing.md),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    ThemeMode mode,
    bool isSelected,
  ) {
    final colors = context.colors;
    final spacing = context.spacing;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(spacing.radiusMd),
      child: InkWell(
        onTap: () {
          themeProvider.setThemeMode(mode);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
              SizedBox(width: spacing.md),
              Expanded(
            child: Text(
                  title,
                  style: context.typography.bodyLarge.copyWith(
                    color: isSelected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  LucideIcons.check,
                  size: 20,
                  color: colors.onPrimaryContainer,
                ),
            ],
              ),
            ),
          ),
        );
  }
}
