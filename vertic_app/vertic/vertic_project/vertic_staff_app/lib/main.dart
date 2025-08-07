//vertic_staff_app/lib/main.dart
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:test_server_client/test_server_client.dart';

import 'auth/permission_provider.dart';
import 'auth/staff_auth_provider.dart';
import 'config/environment.dart';
import 'design_system/design_system.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/customer_management_page.dart';
import 'pages/login_page.dart';
import 'pages/pos_system_page.dart';
import 'pages/product_management_page.dart';
import 'pages/statistics_page.dart';
import 'services/background_scanner_service.dart';
import 'widgets/navigation/collapsible_nav_rail.dart';

// Globale Client-Instanz (SessionManager entfernt!)
late Client client;

// Theme Provider für manuelles Theme-Switching
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔗 **CLIENT-KONFIGURATION mit Staff-spezifischem AuthenticationKeyManager**
  //
  // STAFF-SICHERHEITSKONZEPT:
  // - StaffAuthenticationKeyManager für Staff-Token-Verwaltung
  // - Getrennt von Client-App-Authentifizierung
  // - Direkte HTTP-Header-Übertragung an StaffAuthHelper
  client = Client(
    Environment.serverUrl,
    authenticationKeyManager: StaffAuthenticationKeyManager(),
  )..connectivityMonitor = FlutterConnectivityMonitor();

  // Debug-Info ausgeben
  // print('🚀 Vertic Staff startet...');
  // print('📡 Server: ${Environment.environmentInfo}');
  // print('🔗 URL: ${Environment.serverUrl}');

  // 🚀 NEUES STAFF-AUTH-SYSTEM: Kein SessionManager mehr!
  // Der StaffAuthProvider übernimmt die komplette Authentication

  runApp(
    MultiProvider(
      providers: [
        Provider<Client>.value(value: client),
        ChangeNotifierProvider(create: (_) => StaffAuthProvider(client)),
        ChangeNotifierProvider(create: (_) => PermissionProvider(client)),
        ChangeNotifierProvider(create: (_) => BackgroundScannerService(client)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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

    // 🔐 RBAC-Integration: Permissions nur EINMAL bei Login laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final staffAuth = Provider.of<StaffAuthProvider>(context, listen: false);
      final permissionProvider = Provider.of<PermissionProvider>(
        context,
        listen: false,
      );

      // **PERFORMANCE-FIX:** Permissions nur bei Auth-Status-Änderung laden
      void handleAuthChange() {
        if (staffAuth.isAuthenticated &&
            staffAuth.currentStaffUser != null &&
            !permissionProvider.isInitialized) {
          // Staff-User ist eingeloggt UND Permissions noch nicht geladen
          debugPrint(
            '🔐 Staff-User angemeldet → Lade RBAC Permissions EINMALIG...',
          );
          permissionProvider.fetchPermissionsForStaff(
            staffAuth.currentStaffUser!.id!,
          );
        } else if (!staffAuth.isAuthenticated) {
          // Staff-User ist ausgeloggt → Permissions löschen
          debugPrint('🔓 Staff-User abgemeldet → Lösche Permissions');
          permissionProvider.clearPermissions();
        }
      }

      // Initial check für bereits eingeloggte User
      handleAuthChange();

      // Listener für zukünftige Auth-Änderungen
      staffAuth.addListener(handleAuthChange);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffAuthProvider>(
      builder: (context, staffAuth, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: 'Vertic Staff',
              theme: VerticTheme.light(context),
              darkTheme: VerticTheme.dark(context),
              themeMode: themeProvider.themeMode,
              // 🎯 Routing basiert auf Staff-Auth-Status
              home: staffAuth.isAuthenticated
                  ? const StaffHomePage()
                  : const LoginPage(),
              debugShowCheckedModeBanner: false,
            );
          },
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

class _AppPage {
  final String route;
  final Widget page;
  final String? requiredPermission;

  const _AppPage({
    required this.route,
    required this.page,
    this.requiredPermission,
  });
}

class _StaffHomePageState extends State<StaffHomePage> {
  int _selectedIndex = 0;
  bool _isNavExpanded = false;
  String _selectedRoute = '/pos';

  @override
  void initState() {
    super.initState();

    // 🔧 BACKGROUND SCANNER: Context registrieren für Toast-Notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final backgroundScanner = Provider.of<BackgroundScannerService>(
        context,
        listen: false,
      );
      backgroundScanner.registerContext(context);
      debugPrint('🔧 Background Scanner Context registriert');

      // ⚠️ COM-PORT STARTUP WARNING
      _checkComPortConnectionAndWarn(backgroundScanner);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleNavigation(String route) {
    final visiblePages = _getVisiblePages(context);
    final newIndex = visiblePages.indexWhere((p) => p.route == route);

    if (newIndex != -1) {
      setState(() {
        _selectedRoute = route;
        _selectedIndex = newIndex;
        // Automatisch Sidebar kollabieren bei Navigation
        _isNavExpanded = false;
      });
    }
  }

  List<_AppPage> _getVisiblePages(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(
      context,
      listen: false,
    );
    final staffAuth = Provider.of<StaffAuthProvider>(context, listen: false);
    final isSuperUser =
        staffAuth.currentStaffUser?.staffLevel == StaffUserType.superUser;

    final allPages = <_AppPage>[
      const _AppPage(route: '/pos', page: PosSystemPage()),
      const _AppPage(
        route: '/products',
        page: ProductManagementPage(),
        requiredPermission: 'can_create_products',
      ),
      const _AppPage(route: '/statistics', page: StatisticsPage()),
      const _AppPage(route: '/analytics', page: StatisticsPage()),
      _AppPage(
        route: '/customers',
        page: CustomerManagementPage(isSuperUser: isSuperUser),
      ),
      _AppPage(
        route: '/admin',
        page: AdminDashboardPage(
          isSuperUser: isSuperUser,
          hallId: staffAuth.currentStaffUser?.hallId,
        ),
      ),
      if (kDebugMode)
        const _AppPage(route: '/design', page: DesignSystemShowcasePage()),
      _AppPage(route: '/settings', page: _buildSettingsPage(context)),
    ];

    return allPages.where((page) {
      if (page.requiredPermission == null) return true;
      return permissionProvider.hasPermission(page.requiredPermission!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, permissionProvider, child) {
        final visiblePages = _getVisiblePages(context);
        if (_selectedIndex >= visiblePages.length) {
          _selectedIndex = 0;
          _selectedRoute = visiblePages.isNotEmpty
              ? visiblePages[0].route
              : '/';
        }

        return Scaffold(
          body: Listener(
            onPointerDown: (event) {
              // Close menu when clicking outside of it
              if (_isNavExpanded) {
                final RenderBox? navRailBox = context.findRenderObject() as RenderBox?;
                if (navRailBox != null) {
                  final navRailBounds = Offset.zero & Size(300, navRailBox.size.height);
                  final clickPosition = event.localPosition;
                  
                  // If click is outside the nav rail area, close the menu
                  if (!navRailBounds.contains(clickPosition)) {
                    setState(() {
                      _isNavExpanded = false;
                    });
                  }
                }
              }
            },
            child: Row(
              children: [
                CollapsibleNavRail(
                  isExpanded: _isNavExpanded,
                  selectedRoute: _selectedRoute,
                  onRouteSelected: _handleNavigation,
                  onExpansionChanged: () {
                    setState(() {
                      _isNavExpanded = !_isNavExpanded;
                    });
                  },
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: visiblePages.map((p) => p.page).toList(),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: visiblePages.map((page) {
              IconData icon;
              String label;
              
              switch (page.route) {
                case '/pos':
                  icon = LucideIcons.shoppingCart;
                  label = 'POS';
                  break;
                case '/products':
                  icon = LucideIcons.package;
                  label = 'Produkte';
                  break;
                case '/statistics':
                  icon = LucideIcons.chartLine;
                  label = 'Statistik';
                  break;
                case '/analytics':
                  icon = LucideIcons.chartLine;
                  label = 'Auswertungen';
                  break;
                case '/customers':
                  icon = LucideIcons.users;
                  label = 'Kunden';
                  break;
                case '/admin':
                  icon = LucideIcons.lockKeyhole;
                  label = 'Admin';
                  break;
                case '/design':
                  icon = LucideIcons.paintBucket;
                  label = 'Design';
                  break;
                case '/settings':
                  icon = LucideIcons.settings;
                  label = 'Settings';
                  break;
                default:
                  icon = LucideIcons.circle;
                  label = 'Unbekannt';
              }
              
              return BottomNavigationBarItem(
                icon: Icon(icon),
                label: label,
              );
            }).toList(),
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (index < visiblePages.length) {
                final route = visiblePages[index].route;
                _handleNavigation(route);
              }
            },
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }

  void _checkComPortConnectionAndWarn(BackgroundScannerService scanner) {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Prüfe ob gespeicherter COM-Port nicht mehr erreichbar ist
      if (scanner.selectedPort?.isNotEmpty == true && !scanner.isConnected) {
        _showComPortWarningDialog(scanner);
      }
    });
  }

  /// **📡 COM-PORT WARNING DIALOG**
  void _showComPortWarningDialog(BackgroundScannerService scanner) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Text('Scanner nicht verbunden'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Der gespeicherte COM-Port "${scanner.selectedPort}" ist nicht erreichbar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Möchten Sie einen anderen COM-Port auswählen?',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Später'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _handleNavigation('/admin'); // Navigiert zum Admin-Bereich
              },
              icon: const Icon(Icons.settings),
              label: const Text('Scanner-Einstellungen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    Text(
                                      staffAuth.currentStaffEmail,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStaffLevelDisplayName(
                                          currentUser.staffLevel,
                                        ),
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
                    staffAuth.isLoading ? 'Wird abgemeldet...' : 'Abmelden',
                  ),
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
