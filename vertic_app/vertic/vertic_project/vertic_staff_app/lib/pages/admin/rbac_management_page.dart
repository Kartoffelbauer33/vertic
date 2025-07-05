import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import 'email_verification_page.dart';
import '../../auth/permission_wrapper.dart';
import '../../widgets/password_input_dialog.dart';

/// **🎯 Phase 4.1: RBAC Management UI**
///
/// Moderne Admin-Oberfläche für Permission & Role Management
class RbacManagementPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(bool, [String?])? onUnsavedChanges;

  const RbacManagementPage({
    super.key,
    required this.onBack,
    this.onUnsavedChanges,
  });

  @override
  State<RbacManagementPage> createState() => _RbacManagementPageState();
}

class _RbacManagementPageState extends State<RbacManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Loading states
  bool _isLoading = true;
  String? _errorMessage;

  // Data stores
  List<Permission> _allPermissions = [];
  List<Role> _allRoles = [];
  List<StaffUser> _staffUsers = [];
  final Map<String, List<Permission>> _permissionsByCategory = {};

  // Search & Filter
  String _searchQuery = '';
  String _selectedCategory = 'all';
  Set<String> _availableCategories = {'all'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// **🔄 Lädt alle RBAC-Daten**
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);

      // Parallel laden für bessere Performance (ohne problematische getPermissionStats)
      final futures = await Future.wait([
        client.permissionManagement.getAllPermissions(),
        client.permissionManagement.getAllRoles(),
        client.staffUserManagement.getAllStaffUsers(limit: 1000, offset: 0),
      ]);

      _allPermissions = futures[0] as List<Permission>;
      _allRoles = futures[1] as List<Role>;
      _staffUsers = futures[2] as List<StaffUser>;

      // Permission-Kategorien extrahieren
      _buildPermissionCategories();

      setState(() {
        _isLoading = false;
      });

      debugPrint(
          '✅ RBAC-Daten geladen: ${_allPermissions.length} Permissions, ${_allRoles.length} Roles');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden der RBAC-Daten: $e';
      });
      debugPrint('❌ RBAC-Daten Fehler: $e');
    }
  }

  /// **📁 Organisiert Permissions nach Kategorien**
  void _buildPermissionCategories() {
    _permissionsByCategory.clear();
    _availableCategories = {'all'};

    for (final permission in _allPermissions) {
      final category = permission.category;
      _availableCategories.add(category);

      if (!_permissionsByCategory.containsKey(category)) {
        _permissionsByCategory[category] = [];
      }
      _permissionsByCategory[category]!.add(permission);
    }

    // Sortiere Kategorien
    for (final category in _permissionsByCategory.keys) {
      _permissionsByCategory[category]!
          .sort((a, b) => a.displayName.compareTo(b.displayName));
    }
  }

  /// **🔍 Gefilterte Permissions basierend auf Suche und Kategorie**
  List<Permission> get _filteredPermissions {
    var permissions = _selectedCategory == 'all'
        ? _allPermissions
        : _permissionsByCategory[_selectedCategory] ?? [];

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      permissions = permissions
          .where((p) =>
              p.displayName.toLowerCase().contains(query) ||
              p.name.toLowerCase().contains(query) ||
              (p.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return permissions;
  }

  /// **🎨 Hauptschmale UI**
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildMainView(),
    );
  }

  /// **📱 App Bar mit Tabs**
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        '🔐 RBAC Management',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBack,
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.security), text: 'Permissions'),
          Tab(icon: Icon(Icons.group), text: 'Rollen'),
          Tab(icon: Icon(Icons.people), text: 'Staff-User'),
          Tab(icon: Icon(Icons.analytics), text: 'Statistiken'),
        ],
      ),
    );
  }

  /// **⏳ Loading View**
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('RBAC-Daten werden geladen...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  /// **❌ Error View**
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  /// **📋 Main Content mit Tabs**
  Widget _buildMainView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPermissionsTab(),
        _buildRolesTab(),
        _buildStaffUserTab(),
        _buildStatisticsTab(),
      ],
    );
  }

  /// **📊 Permissions Tab**
  Widget _buildPermissionsTab() {
    return PermissionWrapper(
      requiredPermission: 'can_manage_permissions',
      placeholder: _buildAccessDenied('Permission Management'),
      child: Column(
        children: [
          _buildPermissionFilters(),
          Expanded(child: _buildPermissionsList()),
        ],
      ),
    );
  }

  /// **🔍 Permission Filters & Search**
  Widget _buildPermissionFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Permissions durchsuchen...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),

          // Category Filter
          Row(
            children: [
              const Text('Kategorie: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availableCategories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_formatCategoryName(category)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = category);
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.indigo[100],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// **📝 Permissions Liste**
  Widget _buildPermissionsList() {
    final permissions = _filteredPermissions;

    if (permissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Keine Permissions gefunden für "$_searchQuery"'
                  : 'Keine Permissions in dieser Kategorie',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: permissions.length,
      itemBuilder: (context, index) {
        final permission = permissions[index];
        return _buildPermissionCard(permission);
      },
    );
  }

  /// **🎴 Permission Card**
  Widget _buildPermissionCard(Permission permission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _getPermissionIconWidget(permission.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permission.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        permission.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPermissionActions(permission),
              ],
            ),

            if (permission.description != null) ...[
              const SizedBox(height: 8),
              Text(
                permission.description!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],

            const SizedBox(height: 12),

            // Tags
            Wrap(
              spacing: 8,
              children: [
                _buildPermissionTag(permission.category, Colors.indigo),
                if (permission.isSystemCritical)
                  _buildPermissionTag('System Critical', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// **🎯 Permission Actions Menu**
  Widget _buildPermissionActions(Permission permission) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _handlePermissionAction(action, permission),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view_roles',
          child: Row(
            children: [
              Icon(Icons.visibility),
              SizedBox(width: 8),
              Text('Zugewiesene Rollen'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'view_users',
          child: Row(
            children: [
              Icon(Icons.people),
              SizedBox(width: 8),
              Text('Zugewiesene Benutzer'),
            ],
          ),
        ),
        if (!permission.isSystemCritical) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 8),
                Text('Bearbeiten'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Löschen', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// **🎭 Tab 2: Roles Management**
  Widget _buildRolesTab() {
    return PermissionWrapper(
      requiredPermission: 'can_manage_roles',
      placeholder: _buildAccessDenied('Role Management'),
      child: _buildRolesContent(),
    );
  }

  Widget _buildRolesContent() {
    return Column(
      children: [
        // Role Actions Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'Rollen verwalten',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateRoleDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Neue Rolle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Roles List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _allRoles.length,
            itemBuilder: (context, index) {
              final role = _allRoles[index];
              return _buildRoleCard(role);
            },
          ),
        ),
      ],
    );
  }

  /// **🎴 Role Card**
  Widget _buildRoleCard(Role role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  role.isSystemRole ? Icons.shield : Icons.group,
                  color: role.isSystemRole ? Colors.red : Colors.indigo,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        role.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!role.isActive)
                  const Chip(
                    label: Text('Inaktiv'),
                    backgroundColor: Colors.grey,
                  ),
                _buildRoleActions(role),
              ],
            ),

            if (role.description != null) ...[
              const SizedBox(height: 8),
              Text(role.description!,
                  style: TextStyle(color: Colors.grey[700])),
            ],

            const SizedBox(height: 12),

            // Role Stats
            FutureBuilder<List<Permission>>(
              future: _getRolePermissions(role.id!),
              builder: (context, snapshot) {
                final permissionCount = snapshot.data?.length ?? 0;
                return Row(
                  children: [
                    _buildRoleTag('$permissionCount Permissions', Colors.blue),
                    const SizedBox(width: 8),
                    if (role.isSystemRole)
                      _buildRoleTag('System Role', Colors.red),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// **👥 Tab 3: Staff-User Management**
  Widget _buildStaffUserTab() {
    return PermissionWrapper(
      requiredPermission: 'can_view_staff_users',
      placeholder: _buildAccessDenied('Staff-User Management'),
      child: _buildStaffUserContent(),
    );
  }

  Widget _buildStaffUserContent() {
    return Column(
      children: [
        // Staff User Actions Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'Staff-User verwalten',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateStaffUserDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('Neuer Staff-User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Staff Users List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _staffUsers.length,
            itemBuilder: (context, index) {
              final user = _staffUsers[index];
              return _buildStaffUserCard(user);
            },
          ),
        ),
      ],
    );
  }

  /// **🎴 Staff User Card (integriert)**
  Widget _buildStaffUserCard(StaffUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStaffLevelColor(user.staffLevel),
                  child: Icon(
                    _getStaffLevelIcon(user.staffLevel),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        _getStaffLevelText(user.staffLevel),
                        style: TextStyle(
                          color: _getStaffLevelColor(user.staffLevel),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleStaffUserAction(action, user),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Bearbeiten'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'roles',
                      child: Row(
                        children: [
                          Icon(Icons.security),
                          SizedBox(width: 8),
                          Text('Rollen verwalten'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset),
                          SizedBox(width: 8),
                          Text('Passwort zurücksetzen'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Löschen', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Current Roles
            FutureBuilder<List<Role>>(
              future: _getUserRoles(user.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Lade Rollen...');
                }

                final roles = snapshot.data ?? [];
                if (roles.isEmpty) {
                  return Text(
                    'Keine Rollen zugewiesen',
                    style: TextStyle(color: Colors.grey[600]),
                  );
                }

                return Wrap(
                  spacing: 8,
                  children: roles
                      .map((role) =>
                          _buildRoleTag(role.displayName, Colors.green))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// **📊 Tab 4: Statistics**
  Widget _buildStatisticsTab() {
    return PermissionWrapper(
      requiredPermission: 'can_access_audit_logs',
      placeholder: _buildAccessDenied('System Statistics'),
      child: _buildStatisticsContent(),
    );
  }

  Widget _buildStatisticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 RBAC System Statistiken',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Stats Cards
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Permissions', _allPermissions.length,
                      Icons.security, Colors.indigo)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      'Rollen', _allRoles.length, Icons.group, Colors.green)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Staff Users', _staffUsers.length,
                      Icons.people, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      'Kategorien',
                      _availableCategories.length - 1,
                      Icons.category,
                      Colors.purple)),
            ],
          ),

          const SizedBox(height: 24),

          // Category Breakdown
          const Text(
            'Permission-Kategorien',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ..._permissionsByCategory.entries.where((e) => e.key != 'all').map(
                (entry) => Card(
                  child: ListTile(
                    leading: _getPermissionIconWidget(entry.key),
                    title: Text(_formatCategoryName(entry.key)),
                    trailing: Chip(
                      label: Text('${entry.value.length}'),
                      backgroundColor: Colors.indigo[100],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ... HELPER METHODS ...

  /// **🎨 Formats category names**
  String _formatCategoryName(String category) {
    switch (category) {
      case 'all':
        return 'Alle';
      case 'user':
        return 'Benutzer';
      case 'admin':
        return 'Administration';
      case 'system':
        return 'System';
      case 'facility':
        return 'Facility';
      case 'tickets':
        return 'Tickets';
      case 'reports':
        return 'Reports';
      default:
        return category.substring(0, 1).toUpperCase() + category.substring(1);
    }
  }

  /// **🎯 Gets icon widget for permission category**
  Widget _getPermissionIconWidget(String category) {
    return Icon(
      _getPermissionIconData(category),
      color: _getCategoryColor(category),
    );
  }

  /// **🎯 Gets icon data for permission category**
  IconData _getPermissionIconData(String category) {
    switch (category) {
      case 'user':
        return Icons.person;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'system':
        return Icons.settings;
      case 'facility':
        return Icons.business;
      case 'tickets':
        return Icons.confirmation_number;
      case 'reports':
        return Icons.analytics;
      default:
        return Icons.security;
    }
  }

  /// **🏷️ Builds colored tag**
  Widget _buildPermissionTag(String text, Color color) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  Widget _buildRoleTag(String text, Color color) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  /// **📊 Builds statistics card**
  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// **🚫 Access Denied View**
  Widget _buildAccessDenied(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_accounts, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Keine Berechtigung für $feature',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ... ASYNC HELPER METHODS ...

  Future<List<Permission>> _getRolePermissions(int roleId) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      return await client.permissionManagement.getRolePermissions(roleId);
    } catch (e) {
      debugPrint('❌ Error loading role permissions: $e');
      return [];
    }
  }

  Future<List<Role>> _getUserRoles(int userId) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      return await client.permissionManagement.getStaffRoles(userId);
    } catch (e) {
      debugPrint('❌ Error loading user roles: $e');
      return [];
    }
  }

  // ... ACTION HANDLERS ...

  void _handlePermissionAction(String action, Permission permission) {
    switch (action) {
      case 'view_roles':
        _showPermissionRolesDialog(permission);
        break;
      case 'view_users':
        _showPermissionUsersDialog(permission);
        break;
      case 'edit':
        _showEditPermissionDialog(permission);
        break;
      case 'delete':
        _showDeletePermissionDialog(permission);
        break;
    }
  }

  Widget _buildRoleActions(Role role) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _handleRoleAction(action, role),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view_permissions',
          child: Row(
            children: [
              Icon(Icons.security),
              SizedBox(width: 8),
              Text('Berechtigungen anzeigen'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 8),
              Text('Bearbeiten'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Löschen', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleRoleAction(String action, Role role) {
    switch (action) {
      case 'view_permissions':
        _showRolePermissionsDialog(role);
        break;
      case 'edit':
        _showEditRoleDialog(role);
        break;
      case 'delete':
        _showDeleteRoleDialog(role);
        break;
    }
  }

  // ... DIALOG METHODS (Placeholders for now) ...

  void _showPermissionRolesDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔐 Permissions für "${permission.displayName}"'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: FutureBuilder<List<Permission>>(
            future: _getRolePermissions(permission.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Fehler: ${snapshot.error}'),
                );
              }

              final permissions = snapshot.data ?? [];

              if (permissions.isEmpty) {
                return const Center(
                  child: Text('Keine Permissions zugewiesen'),
                );
              }

              return ListView.builder(
                itemCount: permissions.length,
                itemBuilder: (context, index) {
                  final permission = permissions[index];
                  return ListTile(
                    leading: Icon(
                      _getPermissionIconData(permission.category),
                      color: _getCategoryColor(permission.category),
                    ),
                    title: Text(permission.displayName),
                    subtitle: Text(permission.name),
                    trailing: permission.isSystemCritical
                        ? const Icon(Icons.warning, color: Colors.red)
                        : null,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showPermissionUsersDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Benutzer für "${permission.displayName}"'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: FutureBuilder<List<StaffUser>>(
            future: _getUsersWithPermission(permission.name),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Fehler: ${snapshot.error}'));
              }

              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return const Center(
                  child:
                      Text('Keine Benutzer mit dieser Berechtigung gefunden.'),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${users.length} Benutzer mit dieser Berechtigung:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          child: ListTile(
                            title: Text('${user.firstName} ${user.lastName}'),
                            subtitle: Text(user.email),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            trailing: Text(
                              user.staffLevel.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  /// Holt alle Staff-User die eine bestimmte Permission haben
  Future<List<StaffUser>> _getUsersWithPermission(String permissionName) async {
    try {
      // Hole alle Staff-User
      final allStaffUsers = await Provider.of<Client>(context, listen: false)
          .staffUserManagement
          .getAllStaffUsers(limit: 1000, offset: 0);

      // Für jeden Staff-User prüfe ob er die Permission hat
      final usersWithPermission = <StaffUser>[];

      for (final user in allStaffUsers) {
        // Hole die Permissions des Users (über Rollen)
        final userRoles = await Provider.of<Client>(context, listen: false)
            .staffUserManagement
            .getStaffUserRoles(user.id!);

        // Für jede Rolle hole die Permissions
        for (final userRole in userRoles) {
          final rolePermissions =
              await Provider.of<Client>(context, listen: false)
                  .permissionManagement
                  .getRolePermissions(userRole.roleId);

          // Prüfe ob die gewünschte Permission dabei ist
          if (rolePermissions
              .any((permission) => permission.name == permissionName)) {
            usersWithPermission.add(user);
            break; // User schon hinzugefügt, keine weiteren Rollen prüfen
          }
        }
      }

      return usersWithPermission;
    } catch (e) {
      print(
          'Fehler beim Laden der Benutzer mit Permission $permissionName: $e');
      return [];
    }
  }

  void _showEditPermissionDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission bearbeiten: "${permission.displayName}"'),
        content: const Text('TODO: Permission bearbeiten Form'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showDeletePermissionDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission löschen'),
        content: Text(
            'Möchten Sie die Permission "${permission.displayName}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePermission(permission);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showCreateRoleDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final displayNameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎭 Neue Rolle erstellen'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Role Name (technical identifier)
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Rolle Name (technisch)',
                    hintText: 'z.B. hall_manager',
                    prefixIcon: Icon(Icons.code),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name ist erforderlich';
                    }
                    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value.trim())) {
                      return 'Nur Kleinbuchstaben, Zahlen und Unterstriche';
                    }
                    if (_allRoles.any((r) => r.name == value.trim())) {
                      return 'Name bereits vergeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Display Name (user-friendly)
                TextFormField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Anzeigename',
                    hintText: 'z.B. Hallen-Manager',
                    prefixIcon: Icon(Icons.label),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Anzeigename ist erforderlich';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    hintText: 'Beschreibung der Rollenfunktionen...',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Active Status
                StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    title: const Text('Rolle aktiv'),
                    subtitle:
                        const Text('Aktive Rollen können zugewiesen werden'),
                    value: isActive,
                    onChanged: (value) =>
                        setState(() => isActive = value ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _createRole(
                  nameController.text.trim(),
                  displayNameController.text.trim(),
                  descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  isActive,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(Role role) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: role.name);
    final displayNameController = TextEditingController(text: role.displayName);
    final descriptionController =
        TextEditingController(text: role.description ?? '');
    bool isActive = role.isActive;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎭 Rolle bearbeiten: "${role.displayName}"'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // System Role Warning
                if (role.isSystemRole) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⚠️ System-Rolle: Name kann nicht geändert werden',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Role Name (technical identifier)
                TextFormField(
                  controller: nameController,
                  enabled: !role.isSystemRole, // System roles can't be renamed
                  decoration: const InputDecoration(
                    labelText: 'Rolle Name (technisch)',
                    prefixIcon: Icon(Icons.code),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name ist erforderlich';
                    }
                    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value.trim())) {
                      return 'Nur Kleinbuchstaben, Zahlen und Unterstriche';
                    }
                    // Check for duplicates (excluding current role)
                    if (value.trim() != role.name &&
                        _allRoles.any((r) => r.name == value.trim())) {
                      return 'Name bereits vergeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Display Name (user-friendly)
                TextFormField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Anzeigename',
                    prefixIcon: Icon(Icons.label),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Anzeigename ist erforderlich';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Active Status
                StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    title: const Text('Rolle aktiv'),
                    subtitle:
                        const Text('Aktive Rollen können zugewiesen werden'),
                    value: isActive,
                    onChanged: (value) =>
                        setState(() => isActive = value ?? true),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),

                // Current Permissions Count
                FutureBuilder<List<Permission>>(
                  future: _getRolePermissions(role.id!),
                  builder: (context, snapshot) {
                    final permissionCount = snapshot.data?.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.security, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text('$permissionCount Berechtigungen zugewiesen'),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showRolePermissionsDialog(role);
                            },
                            child: const Text('Verwalten'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _updateRole(
                  role,
                  nameController.text.trim(),
                  displayNameController.text.trim(),
                  descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  isActive,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRoleDialog(Role role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rolle löschen'),
        content: Text(
            'Möchten Sie die Rolle "${role.displayName}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRole(role);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showUserRoleAssignmentDialog(StaffUser user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 600,
          height: 500,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        '${user.firstName[0]}${user.lastName[0]}',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.firstName} ${user.lastName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user.email ?? 'Keine E-Mail',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rollen-Zuweisung verwalten',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Current Roles
                      const Text(
                        'Aktuelle Rollen:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      FutureBuilder<List<Role>>(
                        future: _getUserRoles(user.id!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final userRoles = snapshot.data ?? [];

                          if (userRoles.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Keine Rollen zugewiesen',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: userRoles
                                .map((role) => Chip(
                                      label: Text(role.displayName),
                                      backgroundColor: role.isSystemRole
                                          ? Colors.red[100]
                                          : Colors.indigo[100],
                                      deleteIcon:
                                          const Icon(Icons.close, size: 18),
                                      onDeleted: role.isSystemRole
                                          ? null // System roles can't be removed manually
                                          : () => _removeRoleFromUser(
                                              user.id!, role.id!),
                                    ))
                                .toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Available Roles
                      const Text(
                        'Verfügbare Rollen:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ListView.builder(
                          itemCount: _allRoles.where((r) => r.isActive).length,
                          itemBuilder: (context, index) {
                            final availableRoles =
                                _allRoles.where((r) => r.isActive).toList();
                            final role = availableRoles[index];

                            return FutureBuilder<List<Role>>(
                              future: _getUserRoles(user.id!),
                              builder: (context, userRoleSnapshot) {
                                final userRoles = userRoleSnapshot.data ?? [];
                                final isAssigned =
                                    userRoles.any((ur) => ur.id == role.id);

                                return ListTile(
                                  leading: Icon(
                                    role.isSystemRole
                                        ? Icons.shield
                                        : Icons.group,
                                    color: role.isSystemRole
                                        ? Colors.red
                                        : Colors.indigo,
                                  ),
                                  title: Text(role.displayName),
                                  subtitle: Text(role.description ?? role.name),
                                  trailing: isAssigned
                                      ? const Chip(
                                          label: Text('Zugewiesen'),
                                          backgroundColor: Colors.green,
                                        )
                                      : ElevatedButton(
                                          onPressed: () => _assignRoleToUser(
                                              user.id!, role.id!),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Zuweisen'),
                                        ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... BACKEND OPERATIONS ...

  Future<void> _deletePermission(Permission permission) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final success =
          await client.permissionManagement.deletePermission(permission.id!);

      if (success) {
        setState(() {
          _allPermissions.removeWhere((p) => p.id == permission.id);
          _buildPermissionCategories();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Permission "${permission.displayName}" wurde gelöscht'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  Future<void> _deleteRole(Role role) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final success = await client.permissionManagement.deleteRole(role.id!);

      if (success) {
        setState(() {
          _allRoles.removeWhere((r) => r.id == role.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rolle "${role.displayName}" wurde gelöscht'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  Future<void> _createRole(String name, String displayName, String? description,
      bool isActive) async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      // Role-Objekt erstellen
      final role = Role(
        name: name,
        displayName: displayName,
        description: description,
        isActive: isActive,
        isSystemRole: false, // User-created roles are never system roles
        sortOrder: _allRoles.length + 1, // Am Ende einfügen
        createdAt: DateTime.now(),
        createdBy: 1, // TODO: Aktuelle Staff-User-ID verwenden
      );

      final newRole = await client.permissionManagement.createRole(role);

      if (newRole != null) {
        setState(() {
          _allRoles.add(newRole);
          // Sort roles by displayName
          _allRoles.sort((a, b) => a.displayName.compareTo(b.displayName));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Rolle "${newRole.displayName}" wurde erfolgreich erstellt'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Permissions zuweisen',
                onPressed: () => _showRolePermissionsDialog(newRole),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen der Rolle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ Create Role Error: $e');
    }
  }

  Future<void> _updateRole(Role originalRole, String name, String displayName,
      String? description, bool isActive) async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      // Updated Role-Objekt erstellen
      final updatedRole = Role(
        id: originalRole.id,
        name: name,
        displayName: displayName,
        description: description,
        isActive: isActive,
        isSystemRole: originalRole.isSystemRole,
        sortOrder: originalRole.sortOrder,
        createdAt: originalRole.createdAt,
        createdBy: originalRole.createdBy,
        updatedAt: DateTime.now(),
        color: originalRole.color,
        iconName: originalRole.iconName,
      );

      final result = await client.permissionManagement.updateRole(updatedRole);

      if (result != null) {
        setState(() {
          final index = _allRoles.indexWhere((r) => r.id == originalRole.id);
          if (index != -1) {
            _allRoles[index] = result;
            // Sort roles by displayName
            _allRoles.sort((a, b) => a.displayName.compareTo(b.displayName));
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Rolle "${result.displayName}" wurde erfolgreich aktualisiert'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Aktualisieren der Rolle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ Update Role Error: $e');
    }
  }

  Future<void> _removeRoleFromUser(int userId, int roleId) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final success =
          await client.permissionManagement.removeRoleFromStaff(userId, roleId);

      if (success) {
        setState(() {
          // UI will refresh through FutureBuilder
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rolle wurde erfolgreich entfernt'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Entfernen der Rolle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignRoleToUser(int userId, int roleId) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final success =
          await client.permissionManagement.assignRoleToStaff(userId, roleId);

      if (success) {
        setState(() {
          // UI will refresh through FutureBuilder
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rolle wurde erfolgreich zugewiesen'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Zuweisen der Rolle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'user':
        return Colors.blue;
      case 'admin':
        return Colors.red;
      case 'system':
        return Colors.grey;
      case 'facility':
        return Colors.green;
      case 'tickets':
        return Colors.orange;
      case 'reports':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }

  void _showRolePermissionsDialog(Role role) {
    showDialog(
      context: context,
      builder: (context) => _RolePermissionManagementDialog(
        role: role,
        allPermissions: _allPermissions,
        onPermissionsChanged: _loadInitialData,
      ),
    );
  }

  void _showCreateStaffUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _RbacCreateStaffUserDialog(
        onStaffUserCreated: _loadInitialData,
      ),
    );
  }

  Color _getStaffLevelColor(StaffUserType staffLevel) {
    switch (staffLevel) {
      case StaffUserType.superUser:
        return Colors.red;
      case StaffUserType.facilityAdmin:
        return Colors.purple;
      case StaffUserType.hallAdmin:
        return Colors.orange;
      case StaffUserType.staff:
        return Colors.blue;
    }
  }

  IconData _getStaffLevelIcon(StaffUserType staffLevel) {
    switch (staffLevel) {
      case StaffUserType.superUser:
        return Icons.verified;
      case StaffUserType.facilityAdmin:
        return Icons.business;
      case StaffUserType.hallAdmin:
        return Icons.admin_panel_settings;
      case StaffUserType.staff:
        return Icons.person;
    }
  }

  String _getStaffLevelText(StaffUserType staffLevel) {
    switch (staffLevel) {
      case StaffUserType.superUser:
        return 'Super-Administrator';
      case StaffUserType.facilityAdmin:
        return 'Facility-Administrator';
      case StaffUserType.hallAdmin:
        return 'Hallen-Administrator';
      case StaffUserType.staff:
        return 'Mitarbeiter';
    }
  }

  void _handleStaffUserAction(String action, StaffUser staffUser) {
    switch (action) {
      case 'edit':
        _showEditStaffUserDialog(staffUser);
        break;
      case 'roles':
        _showRoleManagementDialog(staffUser);
        break;
      case 'password':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwort-Reset wird implementiert...')),
        );
        break;
      case 'delete':
        _showDeleteStaffUserDialog(staffUser);
        break;
    }
  }

  void _showEditStaffUserDialog(StaffUser staffUser) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bearbeitung wird implementiert...')),
    );
  }

  void _showRoleManagementDialog(StaffUser staffUser) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Rollen-Management für ${staffUser.firstName} ${staffUser.lastName} wird implementiert...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDeleteStaffUserDialog(StaffUser staffUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Staff-User löschen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Möchten Sie den Staff-User wirklich löschen?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${staffUser.firstName} ${staffUser.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('E-Mail: ${staffUser.email}'),
                  Text('Level: ${_getStaffLevelText(staffUser.staffLevel)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Diese Aktion kann nicht rückgängig gemacht werden!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStaffUser(staffUser);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaffUser(StaffUser staffUser) async {
    final client = Provider.of<Client>(context, listen: false);
    try {
      await client.staffUserManagement.deleteStaffUser(staffUser.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Staff-User ${staffUser.firstName} ${staffUser.lastName} wurde gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
      _loadInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 👤 RBAC STAFF USER CREATION DIALOG
// ═══════════════════════════════════════════════════════════════

class _RbacCreateStaffUserDialog extends StatefulWidget {
  final VoidCallback onStaffUserCreated;

  const _RbacCreateStaffUserDialog({
    required this.onStaffUserCreated,
  });

  @override
  State<_RbacCreateStaffUserDialog> createState() =>
      _RbacCreateStaffUserDialogState();
}

class _RbacCreateStaffUserDialogState
    extends State<_RbacCreateStaffUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  StaffUserType _selectedStaffLevel = StaffUserType.staff;
  bool _isCreating = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add, color: Colors.green),
          SizedBox(width: 8),
          Text('Neuer Staff-User'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Vorname *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vorname ist erforderlich';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nachname *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nachname ist erforderlich';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'E-Mail ist erforderlich';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Bitte geben Sie eine gültige E-Mail ein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StaffUserType>(
                  value: _selectedStaffLevel,
                  decoration: const InputDecoration(
                    labelText: 'Staff-Level *',
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: StaffUserType.staff,
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Mitarbeiter'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: StaffUserType.hallAdmin,
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Hallen-Administrator'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: StaffUserType.facilityAdmin,
                      child: Row(
                        children: [
                          Icon(Icons.business, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Facility-Administrator'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: StaffUserType.superUser,
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Super-Administrator'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStaffLevel = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createStaffUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isCreating
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

  Future<void> _createStaffUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);

      // 🔐 PHASE 3.3: Sichere Passwort-Eingabe
      final staffName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final username = _firstNameController.text.trim().toLowerCase();

      final password = await PasswordInputDialog.show(
        context: context,
        staffName: staffName,
        username: username,
      );

      if (password == null) {
        // User hat abgebrochen
        setState(() {
          _isCreating = false;
        });
        return;
      }

      // 🔄 UNIFIED AUTH: Neue E-Mail-basierte Staff-Erstellung
      final result = await client.unifiedAuth.createStaffUserWithEmail(
        _emailController.text.trim(), // email (echte E-Mail-Adresse)
        username, // username
        password, // Sicheres Passwort vom Dialog
        _firstNameController.text.trim(), // firstName
        _lastNameController.text.trim(), // lastName
        _selectedStaffLevel, // staffLevel
      );

      if (result.success != true) {
        throw Exception(result.message ?? 'Unbekannter Fehler');
      }

      Navigator.pop(context);

      // Wenn E-Mail-Bestätigung erforderlich ist, zeige Bestätigungsseite
      if (result.requiresEmailVerification == true &&
          result.verificationCode != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              email: _emailController.text.trim(),
              verificationCode: result.verificationCode!,
            ),
          ),
        ).then((verified) {
          if (verified == true) {
            widget.onStaffUserCreated();
          }
        });
      } else {
        widget.onStaffUserCreated();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Staff-User ${_firstNameController.text.trim()} ${_lastNameController.text.trim()} wurde erfolgreich erstellt'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Erstellen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 🔐 ROLE PERMISSION MANAGEMENT DIALOG
// ═══════════════════════════════════════════════════════════════

class _RolePermissionManagementDialog extends StatefulWidget {
  final Role role;
  final List<Permission> allPermissions;
  final VoidCallback onPermissionsChanged;

  const _RolePermissionManagementDialog({
    required this.role,
    required this.allPermissions,
    required this.onPermissionsChanged,
  });

  @override
  State<_RolePermissionManagementDialog> createState() =>
      _RolePermissionManagementDialogState();
}

class _RolePermissionManagementDialogState
    extends State<_RolePermissionManagementDialog> {
  List<Permission> _assignedPermissions = [];
  List<Permission> _availablePermissions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  Set<String> _availableCategories = {'all'};

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);

      // Lade die aktuell zugewiesenen Permissions der Rolle
      _assignedPermissions =
          await client.permissionManagement.getRolePermissions(widget.role.id!);

      // Erstelle Liste der verfügbaren (nicht zugewiesenen) Permissions
      final assignedIds = _assignedPermissions.map((p) => p.id).toSet();
      _availablePermissions = widget.allPermissions
          .where((p) => !assignedIds.contains(p.id))
          .toList();

      // Kategorien extrahieren
      _availableCategories = {'all'};
      for (final permission in widget.allPermissions) {
        _availableCategories.add(permission.category);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  List<Permission> get _filteredAvailablePermissions {
    var permissions = _selectedCategory == 'all'
        ? _availablePermissions
        : _availablePermissions
            .where((p) => p.category == _selectedCategory)
            .toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      permissions = permissions
          .where((p) =>
              p.displayName.toLowerCase().contains(query) ||
              p.name.toLowerCase().contains(query) ||
              (p.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return permissions;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.security, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Permissions für "${widget.role.displayName}"',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 16),

            if (_isLoading)
              Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: Row(
                  children: [
                    // Zugewiesene Permissions (Links)
                    Expanded(
                      child: _buildAssignedPermissionsPanel(),
                    ),
                    SizedBox(width: 16),
                    // Verfügbare Permissions (Rechts)
                    Expanded(
                      child: _buildAvailablePermissionsPanel(),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Schließen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedPermissionsPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Zugewiesene Permissions (${_assignedPermissions.length})',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: _assignedPermissions.isEmpty
                ? Center(child: Text('Keine Permissions zugewiesen'))
                : ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: _assignedPermissions.length,
                    itemBuilder: (context, index) {
                      final permission = _assignedPermissions[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            _getPermissionIcon(permission.category),
                            color: _getCategoryColor(permission.category),
                            size: 20,
                          ),
                          title: Text(
                            permission.displayName,
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            permission.name,
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle,
                                color: Colors.red, size: 20),
                            onPressed: () =>
                                _removePermissionFromRole(permission),
                            tooltip: 'Permission entfernen',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePermissionsPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Verfügbare Permissions (${_filteredAvailablePermissions.length})',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Suchfeld
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Permissions suchen...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 8),
                // Kategorie-Filter
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategorie',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: _availableCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                          category == 'all' ? 'Alle Kategorien' : category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredAvailablePermissions.isEmpty
                ? Center(child: Text('Keine verfügbaren Permissions'))
                : ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: _filteredAvailablePermissions.length,
                    itemBuilder: (context, index) {
                      final permission = _filteredAvailablePermissions[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            _getPermissionIcon(permission.category),
                            color: _getCategoryColor(permission.category),
                            size: 20,
                          ),
                          title: Text(
                            permission.displayName,
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            permission.name,
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.add_circle,
                                color: Colors.green, size: 20),
                            onPressed: () =>
                                _assignPermissionToRole(permission),
                            tooltip: 'Permission zuweisen',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _assignPermissionToRole(Permission permission) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final success = await client.permissionManagement.assignPermissionToRole(
        widget.role.id!,
        permission.id!,
      );

      if (success) {
        setState(() {
          _assignedPermissions.add(permission);
          _availablePermissions.remove(permission);
        });

        widget.onPermissionsChanged();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Permission "${permission.displayName}" wurde zugewiesen'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Zuweisung fehlgeschlagen');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Zuweisen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removePermissionFromRole(Permission permission) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final success =
          await client.permissionManagement.removePermissionFromRole(
        widget.role.id!,
        permission.id!,
      );

      if (success) {
        setState(() {
          _assignedPermissions.remove(permission);
          _availablePermissions.add(permission);
        });

        widget.onPermissionsChanged();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Permission "${permission.displayName}" wurde entfernt'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        throw Exception('Entfernung fehlgeschlagen');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Entfernen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getPermissionIcon(String category) {
    switch (category.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'user':
        return Icons.person;
      case 'system':
        return Icons.settings;
      case 'finance':
        return Icons.attach_money;
      case 'reports':
        return Icons.analytics;
      default:
        return Icons.security;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'user':
        return Colors.blue;
      case 'system':
        return Colors.purple;
      case 'finance':
        return Colors.green;
      case 'reports':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
