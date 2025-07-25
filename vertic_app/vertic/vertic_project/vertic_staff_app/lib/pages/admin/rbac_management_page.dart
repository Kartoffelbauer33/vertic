import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

import '../../services/rbac/rbac_data_service.dart';
import '../../services/rbac/rbac_state_provider.dart';
import '../../services/rbac/role_state_provider.dart';
import '../../widgets/rbac/role_management_widget.dart';
import '../../auth/permission_wrapper.dart';
import 'role_permissions_manager.dart';

/// **🔐 RBAC Management Page - Refactored Version**
/// 
/// Vollständig refactorierte Version der RBAC-Management-Page mit:
/// - Service Layer für Backend-Aufrufe
/// - State Provider für Zustandsverwaltung  
/// - Helper Service für UI-Utilities
/// - Saubere Trennung der Verantwortlichkeiten
class RbacManagementPage extends StatefulWidget {
  final bool isSuperUser;
  final int? hallId;

  const RbacManagementPage({
    super.key,
    required this.isSuperUser,
    this.hallId,
  });

  @override
  State<RbacManagementPage> createState() => _RbacManagementPageState();
}

class _RbacManagementPageState extends State<RbacManagementPage>
    with SingleTickerProviderStateMixin {
  
  // Tab Controller
  late TabController _tabController;
  
  // Services
  late RbacDataService _dataService;
  late RbacStateProvider _rbacProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Services initialisieren
    final client = Provider.of<Client>(context, listen: false);
    _dataService = RbacDataService(client);
    _rbacProvider = RbacStateProvider(_dataService);
    
    // Daten laden
    _rbacProvider.loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// **🎨 Hauptschmale UI**
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RbacStateProvider>(
      create: (_) => _rbacProvider,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Consumer<RbacStateProvider>(
          builder: (context, rbacProvider, child) {
            if (rbacProvider.isLoading) {
              return _buildLoadingView();
            }
            if (rbacProvider.errorMessage != null) {
              return _buildErrorView(rbacProvider.errorMessage!);
            }
            return _buildMainView(rbacProvider);
          },
        ),
      ),
    );
  }

  /// **📱 App Bar mit Tabs**
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'RBAC Management',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.indigo[700],
      foregroundColor: Colors.white,
      elevation: 0,
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
  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(errorMessage, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _rbacProvider.loadInitialData(),
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  /// **📋 Main Content mit Tabs**
  Widget _buildMainView(RbacStateProvider rbacProvider) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPermissionsTab(rbacProvider),
        _buildRolesTab(rbacProvider),
        _buildStaffUserTab(rbacProvider),
        _buildStatisticsTab(rbacProvider),
      ],
    );
  }

  /// **📊 Permissions Tab**
  Widget _buildPermissionsTab(RbacStateProvider rbacProvider) {
    return PermissionWrapper(
      requiredPermission: 'can_manage_permissions',
      placeholder: _buildAccessDenied('Permission Management'),
      child: Column(
        children: [
          _buildPermissionFilters(rbacProvider),
          Expanded(child: _buildPermissionsList(rbacProvider)),
        ],
      ),
    );
  }

  /// **🔍 Permission Filters**
  Widget _buildPermissionFilters(RbacStateProvider rbacProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: const InputDecoration(
              labelText: 'Permissions durchsuchen',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => rbacProvider.updateSearchQuery(value),
          ),
          const SizedBox(height: 16),
          // Category Filter
          Row(
            children: [
              const Text('Kategorie: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: DropdownButton<String>(
                  value: rbacProvider.selectedCategory,
                  isExpanded: true,
                  items: rbacProvider.availableCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category == 'all' ? 'Alle Kategorien' : category),
                    );
                  }).toList(),
                  onChanged: (value) => rbacProvider.updateSelectedCategory(value ?? 'all'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// **📋 Permissions List**
  Widget _buildPermissionsList(RbacStateProvider rbacProvider) {
    final filteredPermissions = rbacProvider.filteredPermissions;
    
    if (filteredPermissions.isEmpty) {
      return const Center(
        child: Text('Keine Permissions gefunden', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      itemCount: filteredPermissions.length,
      itemBuilder: (context, index) {
        final permission = filteredPermissions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(
              Icons.security,
              color: Colors.blue,
            ),
            title: Text(
              permission.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${permission.name}'),
                if (permission.description != null)
                  Text('Beschreibung: ${permission.description}'),
                Text('Kategorie: ${permission.category}'),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  /// **👥 Roles Tab - Vollständig refactoriert mit sauberer Auslagerung**
  Widget _buildRolesTab(RbacStateProvider rbacProvider) {
    return PermissionWrapper(
      requiredPermission: 'can_manage_roles',
      placeholder: _buildAccessDenied('Role Management'),
      child: ChangeNotifierProvider(
        create: (context) => RoleStateProvider(Provider.of<Client>(context, listen: false)),
        child: const RoleManagementWidget(),
      ),
    );
  }

  /// **👤 Staff User Tab**
  Widget _buildStaffUserTab(RbacStateProvider rbacProvider) {
    return PermissionWrapper(
      requiredPermission: 'can_manage_staff_users',
      placeholder: _buildAccessDenied('Staff User Management'),
      child: ListView.builder(
        itemCount: rbacProvider.staffUsers.length,
        itemBuilder: (context, index) {
          final staffUser = rbacProvider.staffUsers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  staffUser.firstName.isNotEmpty ? staffUser.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                '${staffUser.firstName} ${staffUser.lastName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${staffUser.email}'),
                  Text('ID: ${staffUser.id}'),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  /// **📈 Statistics Tab**
  Widget _buildStatisticsTab(RbacStateProvider rbacProvider) {
    return PermissionWrapper(
      requiredPermission: 'can_view_statistics',
      placeholder: _buildAccessDenied('Statistics'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard(
              'Permissions',
              rbacProvider.allPermissions.length.toString(),
              Icons.security,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Rollen',
              rbacProvider.allRoles.length.toString(),
              Icons.group,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Staff Users',
              rbacProvider.staffUsers.length.toString(),
              Icons.people,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Kategorien',
              (rbacProvider.availableCategories.length - 1).toString(), // -1 für 'all'
              Icons.category,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  /// **📊 Statistics Card**
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// **🚫 Access Denied Widget**
  Widget _buildAccessDenied(String feature) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.block,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Zugriff verweigert',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sie haben keine Berechtigung für $feature',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }



  /// **🔐 Role Permissions Dialog**
  void _showRolePermissionsDialog(Role role, RbacStateProvider rbacProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: RolePermissionsManager(
            role: role,
            allPermissions: rbacProvider.allPermissions,
            onPermissionsChanged: () {
              // Refresh data after permission changes
              rbacProvider.loadInitialData();
            },
          ),
        ),
      ),
    );
  }


}
