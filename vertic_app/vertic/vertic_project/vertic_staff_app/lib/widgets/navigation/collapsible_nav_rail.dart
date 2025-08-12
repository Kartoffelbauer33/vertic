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
    with WidgetsBindingObserver {
  final Map<String, bool> _expandedItems = {};
  bool _isAccountMenuExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<NavItem> _filteredNavItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateFilteredItems();
    _initializeExpandedState();
  }

  void _initializeExpandedState() {
    // Initialisiere den erweiterten Zustand immer, wenn das Menü geöffnet wird
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

    // Find if current route belongs to any parent menu
    for (final item in allItems) {
      if (item.children.isNotEmpty) {
        final hasSelectedChild = item.children.any(
          (child) => child.route == widget.selectedRoute,
        );

        if (hasSelectedChild || item.route == widget.selectedRoute) {
          setState(() {
            _expandedItems.clear(); // Only one menu open at a time
            if (item.route != null) {
              _expandedItems[item.route!] = true;
            }
          });
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Auto-close menu on small screen sizes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        if (size.width < 768 && widget.isExpanded) {
          widget.onExpansionChanged();
        }
      }
    });
  }

  void _updateFilteredItems() {
    if (_searchQuery.isEmpty) {
      _filteredNavItems = [];
      return;
    }

    final allItems = [
      ...mainNavItems,
      ...planningNavItems,
      ...reportsNavItems,
      ...settingsNavItems,
      ...administrationNavItems,
      ...designNavItems,
      ...adminNavItems,
    ];

    _filteredNavItems = [];
    for (final item in allItems) {
      if (item.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        _filteredNavItems.add(item);
      }
      // Also search in children and create enhanced nav items with parent context
      for (final child in item.children) {
        if (child.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
          // Create a new NavItem with parent context for display
          final enhancedChild = NavItem(
            title: child.title,
            icon: child.icon,
            route: child.route,
            children: child.children,
            parentTitle: item.title, // Add parent context
          );
          _filteredNavItems.add(enhancedChild);
        }
      }
    }
  }

  @override
  void didUpdateWidget(CollapsibleNavRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Aktualisiere den erweiterten Zustand immer, wenn das Menü geöffnet wird
    if (oldWidget.isExpanded != widget.isExpanded && widget.isExpanded) {
      _updateExpandedStateForCurrentRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () {}, // Prevent clicks from propagating through
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: widget.isExpanded ? 300 : 72,
        color: colors.surface,
        child: ClipRect(
          child: Column(
            children: [
              _buildLeading(context),
              if (widget.isExpanded) _buildSearchBar(context),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: _searchQuery.isNotEmpty
                      ? _buildSearchResults(context)
                      : [
                          ..._buildNavItems(mainNavItems, context),
                          const SizedBox(height: 8),
                          ..._buildNavItems(planningNavItems, context),
                          const SizedBox(height: 8),
                          ..._buildNavItems(reportsNavItems, context),
                          const SizedBox(height: 8),
                          ..._buildNavItems(settingsNavItems, context),
                          const SizedBox(height: 8),
                          ..._buildNavItems(administrationNavItems, context),
                          const SizedBox(height: 8),
                          ..._buildNavItems(designNavItems, context),
                          const SizedBox(height: 8),
                          ..._buildNavItems(adminNavItems, context),
                        ],
                ),
              ),
              const Divider(height: 1),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        height: 64, // Increased height for better centering
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: widget.isExpanded
            ? Stack(
                alignment: Alignment.center,
                children: [
                  // Centered logo with slight downward adjustment
                  Positioned(
                    top: 16, // Position logo slightly lower for better visual balance
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/svg/vertic_logo.svg',
                        height: 32,
                        colorFilter: ColorFilter.mode(
                          context.colors.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  // Close button positioned at top right
                  Positioned(
                    top: 0,
                    right: 8,
                    child: Tooltip(
                      message: 'Menü schließen',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onExpansionChanged,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.x,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                // Centered burger menu in collapsed state
                child: Tooltip(
                  message: 'Menü öffnen',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onExpansionChanged,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(
                          LucideIcons.menu,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _buildNavItems(List<NavItem> items, BuildContext context) {
    return items.map((item) {
      if (item.children.isEmpty) {
        return _buildNavItem(item, context);
      } else {
        return _buildExpansionNavItem(item, context);
      }
    }).toList();
  }

  Widget _buildNavItem(
    NavItem item,
    BuildContext context, {
    bool isSubItem = false,
  }) {
    final bool isSelected = widget.selectedRoute == item.route;
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;

    // Responsive Werte basierend auf Design-System
    final double iconSize = widget.isExpanded ? spacing.iconSm : spacing.iconXs;
    final double itemHeight = widget.isExpanded
        ? spacing.listItemHeight *
              0.75 // Kompakter als Standard-ListItem
        : spacing.buttonHeightSmall;

    // Fixed Padding: Only left indent for subitems, no right padding reduction
    final EdgeInsets itemPadding = EdgeInsets.only(
      left: widget.isExpanded
          ? (isSubItem ? spacing.md : spacing.sm)
          : spacing.xs,
      right: widget.isExpanded ? spacing.sm : spacing.xs,
      top: spacing.xs * 0.5,
      bottom: spacing.xs * 0.5,
    );

    final EdgeInsets contentPadding = EdgeInsets.symmetric(
      horizontal: widget.isExpanded ? spacing.sm : spacing.xs,
      vertical: spacing.xs,
    );

    return Padding(
      padding: itemPadding,
      child: Tooltip(
        message: widget.isExpanded ? '' : item.title,
        child: Material(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(spacing.radiusSm),
          child: InkWell(
            onTap: () {
              if (item.route != null) {
                widget.onRouteSelected(item.route!);
              }
            },
            borderRadius: BorderRadius.circular(spacing.radiusSm),
            child: Container(
              height: itemHeight,
              width: double.infinity,
              padding: contentPadding,
              child: Row(
                mainAxisAlignment: widget.isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected
                        ? colors.primary
                        : colors.onSurfaceVariant,
                    size: iconSize,
                    weight: 400,
                  ),
                  if (widget.isExpanded) ...[
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Text(
                        item.title,
                        style: typography.bodyMedium.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? colors.primary : colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionNavItem(NavItem item, BuildContext context) {
    final isParentOfSelected = item.children.any(
      (child) => child.route == widget.selectedRoute,
    );
    final bool isActive =
        isParentOfSelected || widget.selectedRoute == item.route;

    // Entferne die automatische Expansion hier, da sie bereits in _updateExpandedStateForCurrentRoute behandelt wird
    // Das verhindert Konflikte beim manuellen Öffnen anderer Menüs

    final bool isExpanded = _expandedItems[item.route!] ?? false;
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;
    final Color activeColor = colors.primary;
    final Color inactiveColor = colors.onSurfaceVariant;
    final Color itemColor = isActive ? activeColor : inactiveColor;

    // Responsive Werte basierend auf Design-System
    final double iconSize = widget.isExpanded ? spacing.iconSm : spacing.iconXs;
    final double chevronSize = spacing.iconXs;
    final double itemHeight = widget.isExpanded
        ? spacing.listItemHeight * 0.75
        : spacing.buttonHeightSmall;

    // Fixed Padding: Consistent with nav items
    final EdgeInsets itemPadding = EdgeInsets.only(
      left: widget.isExpanded ? spacing.sm : spacing.xs,
      right: widget.isExpanded ? spacing.sm : spacing.xs,
      top: spacing.xs * 0.5,
      bottom: spacing.xs * 0.5,
    );

    final EdgeInsets contentPadding = EdgeInsets.symmetric(
      horizontal: widget.isExpanded ? spacing.sm : spacing.xs,
      vertical: spacing.xs,
    );

    return Padding(
      padding: itemPadding,
      child: Column(
        children: [
          Material(
            color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(spacing.radiusSm),
            child: InkWell(
              onTap: () {
                if (item.route != null) {
                  // Wenn wir bereits auf einer Unterseite dieses Menüs sind,
                  // dann zur Hauptseite zurückkehren
                  if (isParentOfSelected) {
                    widget.onRouteSelected(item.route!);
                  } else {
                    // Ansonsten normale Navigation
                    widget.onRouteSelected(item.route!);
                  }
                }
              },
              borderRadius: BorderRadius.circular(spacing.radiusSm),
              child: Container(
                height: itemHeight,
                width: double.infinity,
                padding: contentPadding,
                child: Row(
                  mainAxisAlignment: widget.isExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: itemColor,
                      size: iconSize,
                      weight: 400,
                    ),
                    if (widget.isExpanded) SizedBox(width: spacing.sm),
                    if (widget.isExpanded)
                      Expanded(
                        child: Text(
                          item.title,
                          style: typography.bodyMedium.copyWith(
                            color: itemColor,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (widget.isExpanded)
                      GestureDetector(
                        onTap: () {
                          if (item.route != null) {
                            setState(() {
                              final clickedRoute = item.route!;
                              bool isOpening =
                                  !(_expandedItems[clickedRoute] ?? false);
                              _expandedItems.clear();
                              if (isOpening) {
                                _expandedItems[clickedRoute] = true;
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(spacing.xs * 0.75),
                          color: Colors.transparent,
                          child: Icon(
                            isExpanded
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            color: itemColor,
                            size: chevronSize,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded && widget.isExpanded)
            Column(
              children: item.children
                  .map(
                    (child) => _buildNavItem(child, context, isSubItem: true),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final spacing = context.spacing;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.xs,
          vertical: spacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeFooterItem(context),
            SizedBox(height: spacing.xs * 0.5),
            _buildAccountFooterItem(context),
            SizedBox(height: spacing.xs * 0.5),
            _buildFooterItem(
              icon: LucideIcons.logOut,
              title: 'Logout',
              onTap: () => widget.onRouteSelected('/logout'),
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeFooterItem(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final currentMode = themeProvider.themeMode;
        final icon = _getThemeIcon(currentMode);
        final themeName = _getThemeModeName(currentMode);

        return _buildFooterItem(
          icon: icon,
          title: 'Theme',
          subtitle: widget.isExpanded ? themeName : null,
          onTap: () {
            final nextMode = ThemeMode
                .values[(currentMode.index + 1) % ThemeMode.values.length];
            themeProvider.setThemeMode(nextMode);
          },
          context: context,
        );
      },
    );
  }

  Widget _buildAccountFooterItem(BuildContext context) {
    // --- Placeholder User Data ---
    const userName = 'Leon Stadler';
    const userRole = 'Administrator';
    const userInitials = 'LS';
    // ---------------------------

    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;

    // Responsive Avatar-Größe basierend auf verfügbarem Platz
    final double avatarRadius = widget.isExpanded
        ? spacing.iconSm *
              0.8 // Etwas kleiner als Standard-Icon
        : spacing.iconXs * 0.9;

    // Responsive Item-Höhe
    final double itemHeight = widget.isExpanded
        ? spacing.listItemHeight * 0.7
        : spacing.buttonHeightSmall;

    final accountHeader = Material(
      color: _isAccountMenuExpanded
          ? colors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(spacing.radiusSm),
      child: InkWell(
        onTap: () {
          setState(() {
            _isAccountMenuExpanded = !_isAccountMenuExpanded;
          });
        },
        borderRadius: BorderRadius.circular(spacing.radiusSm),
        hoverColor: colors.primary.withValues(alpha: 0.1),
        child: Container(
          height: itemHeight,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? spacing.sm * 1.5 : spacing.xs,
            vertical: spacing.xs,
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  userInitials,
                  style: typography.labelSmall.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.isExpanded) ...[
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: typography.bodySmall.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userRole,
                        style: typography.labelSmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isAccountMenuExpanded
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  size: spacing.iconXs,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        accountHeader,
        if (_isAccountMenuExpanded && widget.isExpanded)
          Padding(
            padding: EdgeInsets.only(top: spacing.xs * 0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavItem(
                  NavItem(
                    title: 'Profil',
                    icon: LucideIcons.user,
                    route: '/profile',
                  ),
                  context,
                  isSubItem: true,
                ),
                _buildNavItem(
                  NavItem(
                    title: 'Einstellungen',
                    icon: LucideIcons.settings,
                    route: '/settings',
                  ),
                  context,
                  isSubItem: true,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback? onTap,
    required BuildContext context,
  }) {
    final spacing = context.spacing;
    final typography = context.typography;
    final colors = context.colors;

    // Responsive Werte basierend auf Design-System
    final double iconSize = widget.isExpanded ? spacing.iconSm : spacing.iconXs;
    final double itemHeight = widget.isExpanded
        ? spacing.listItemHeight *
              0.65 // Noch kompakter für Footer
        : spacing.buttonHeightSmall * 0.9;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(spacing.radiusSm),
        hoverColor: colors.primary.withValues(alpha: 0.1),
        child: Container(
          height: itemHeight,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? spacing.sm * 1.5 : spacing.xs,
            vertical: spacing.xs * 0.75,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Wichtig: Verhindert Overflow
            mainAxisAlignment: widget.isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: colors.onSurfaceVariant,
                size: iconSize,
                weight: 400,
              ),
              if (widget.isExpanded) ...[
                SizedBox(width: spacing.sm),
                Expanded(
                  // Flex-basiert, verhindert Overflow
                  child: subtitle != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: typography.bodySmall.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                subtitle,
                                style: typography.labelSmall.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          title,
                          style: typography.bodySmall.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: spacing.xs),
                  trailing,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return LucideIcons.sun;
      case ThemeMode.dark:
        return LucideIcons.moon;
      case ThemeMode.system:
        return LucideIcons.laptop;
    }
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.colors;
    final typography = context.typography;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(spacing.radiusSm),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _updateFilteredItems();
            });
          },
          style: typography.bodySmall.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Menü durchsuchen...',
            hintStyle: typography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              LucideIcons.search,
              size: spacing.iconXs,
              color: colors.onSurfaceVariant,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _updateFilteredItems();
                      });
                    },
                    child: Icon(
                      LucideIcons.x,
                      size: spacing.iconXs,
                      color: colors.onSurfaceVariant,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacing.xs,
              vertical: spacing.xs,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSearchResults(BuildContext context) {
    if (_filteredNavItems.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Center(
            child: Text(
              'Keine Ergebnisse gefunden',
              style: context.typography.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }

    return _filteredNavItems.map((item) {
      final widgets = <Widget>[];

      // Show parent context for submenu items
      if (item.parentTitle != null) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              left: context.spacing.md,
              right: context.spacing.sm,
              top: context.spacing.xs,
              bottom: context.spacing.xs * 0.5,
            ),
            child: Text(
              item.parentTitle!,
              style: context.typography.labelSmall.copyWith(
                color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }

      widgets.add(_buildNavItem(item, context));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    }).toList();
  }
}
