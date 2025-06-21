import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';
import 'package:test_server_client/test_server_client.dart';
import 'auth/permission_provider.dart';
import 'auth/staff_auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/customer_management_page.dart';
import 'pages/scanner_page.dart';
import 'pages/statistics_page.dart';
import 'auth/permission_wrapper.dart';
import 'config/environment.dart';

// Globale Client-Instanz (SessionManager entfernt!)
late Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔗 **CLIENT-KONFIGURATION mit AuthenticationKeyManager für SESSION-FIX**
  //
  // SICHERHEITSKONZEPT:
  // - FlutterAuthenticationKeyManager für sichere Token-Speicherung
  // - Serverpod 2.8 konforme Session-Verwaltung
  // - Automatische Token-Übertragung bei API-Calls
  client = Client(
    Environment.serverUrl,
    authenticationKeyManager: FlutterAuthenticationKeyManager(),
  )..connectivityMonitor = FlutterConnectivityMonitor();

  // Debug-Info ausgeben
  print('🚀 Vertic Staff startet...');
  print('📡 Server: ${Environment.environmentInfo}');
  print('🔗 URL: ${Environment.serverUrl}');

  // 🚀 NEUES STAFF-AUTH-SYSTEM: Kein SessionManager mehr!
  // Der StaffAuthProvider übernimmt die komplette Authentication

  runApp(
    MultiProvider(
      providers: [
        Provider<Client>.value(value: client),
        ChangeNotifierProvider(create: (_) => StaffAuthProvider(client)),
        ChangeNotifierProvider(create: (_) => PermissionProvider(client)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 🔐 RBAC-Integration: Permissions laden wenn Staff-User sich anmeldet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final staffAuth = Provider.of<StaffAuthProvider>(context, listen: false);
      final permissionProvider =
          Provider.of<PermissionProvider>(context, listen: false);

      // Listener für Staff-Auth-Änderungen
      staffAuth.addListener(() {
        if (staffAuth.isAuthenticated && staffAuth.currentStaffUser != null) {
          // Staff-User ist eingeloggt → Permissions laden
          debugPrint('🔐 Staff-User angemeldet → Lade RBAC Permissions...');
          permissionProvider
              .fetchPermissionsForStaff(staffAuth.currentStaffUser!.id!);
        } else {
          // Staff-User ist ausgeloggt → Permissions löschen
          debugPrint('🔓 Staff-User abgemeldet → Lösche Permissions');
          permissionProvider.clearPermissions();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffAuthProvider>(
      builder: (context, staffAuth, child) {
        return MaterialApp(
          title: 'Vertic Staff',
          theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF00897B)),
            useMaterial3: true,
          ),
          // 🎯 Routing basiert auf Staff-Auth-Status
          home: staffAuth.isAuthenticated
              ? const StaffHomePage()
              : const LoginPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class StaffHomePage extends StatefulWidget {
  const StaffHomePage({super.key});

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, permissionProvider, _) {
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _buildPages(context),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: _buildNavigationItems(context),
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
          ),
        );
      },
    );
  }

  List<Widget> _buildPages(BuildContext context) {
    // Dynamisch prüfen ob aktueller User SuperUser ist
    final staffAuth = Provider.of<StaffAuthProvider>(context, listen: false);
    final isSuperUser =
        staffAuth.currentStaffUser?.staffLevel == StaffUserType.superUser;

    return <Widget>[
      const ScannerPage(),
      const Center(child: Text('Verkauf')),
      const StatisticsPage(),
      CustomerManagementPage(isSuperUser: isSuperUser),
      PermissionWrapper(
        requiredPermission: 'can_access_admin_dashboard',
        child: AdminDashboardPage(isSuperUser: isSuperUser),
      ),
      _buildSettingsPage(context),
    ].where((widget) {
      if (widget is PermissionWrapper) {
        final permissionProvider =
            Provider.of<PermissionProvider>(context, listen: false);
        return permissionProvider.hasPermission(widget.requiredPermission);
      }
      return true;
    }).toList();
  }

  List<BottomNavigationBarItem> _buildNavigationItems(BuildContext context) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale), label: 'Verkauf'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.insert_chart), label: 'Statistik'),
      const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kunden'),
    ];

    final permissionProvider =
        Provider.of<PermissionProvider>(context, listen: false);

    // 🔐 RBAC: Admin-Dashboard nur mit Permission anzeigen
    final hasAdminPermission =
        permissionProvider.hasPermission('can_access_admin_dashboard');
    debugPrint('🔐 Admin-Permission Check: $hasAdminPermission');
    debugPrint('🔐 Alle Permissions: ${permissionProvider.permissions}');

    if (hasAdminPermission) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ));
      debugPrint('✅ Admin Tab hinzugefügt');
    } else {
      debugPrint('❌ Admin Tab nicht hinzugefügt - Permission fehlt');
    }

    items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.settings), label: 'Einstellungen'));
    return items;
  }

  Widget _buildSettingsPage(BuildContext context) {
    return Consumer<StaffAuthProvider>(
      builder: (context, staffAuth, child) {
        final currentUser = staffAuth.currentStaffUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Einstellungen'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 👤 Staff-User-Info Card
                if (currentUser != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.badge, size: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staffAuth.currentStaffDisplayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    Text(
                                      staffAuth.currentStaffEmail,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStaffLevelDisplayName(
                                            currentUser.staffLevel),
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (currentUser.employeeId != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Mitarbeiter-ID: ${currentUser.employeeId}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // 🔓 Logout-Button
                ElevatedButton.icon(
                  onPressed: staffAuth.isLoading
                      ? null
                      : () async {
                          try {
                            await staffAuth.signOut();
                            if (mounted) {
                              // Navigation erfolgt automatisch über Consumer
                              debugPrint('✅ Staff-Logout erfolgreich');
                            }
                          } catch (e) {
                            debugPrint('❌ Staff-Logout Fehler: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Logout-Fehler: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: staffAuth.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: Text(
                      staffAuth.isLoading ? 'Wird abgemeldet...' : 'Abmelden'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// **Hilfsfunktion: Staff-Level zu benutzerfreundlichem Namen**
  String _getStaffLevelDisplayName(StaffUserType level) {
    switch (level) {
      case StaffUserType.superUser:
        return 'Super Administrator';
      case StaffUserType.facilityAdmin:
        return 'Standort-Administrator';
      case StaffUserType.hallAdmin:
        return 'Hallen-Administrator';
      case StaffUserType.staff:
        return 'Mitarbeiter';
    }
  }
}
