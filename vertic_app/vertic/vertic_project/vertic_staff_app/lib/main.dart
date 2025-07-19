import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'package:test_server_client/test_server_client.dart';
import 'auth/permission_provider.dart';
import 'auth/staff_auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/customer_management_page.dart';
import 'pages/pos_system_page.dart';
import 'pages/product_management_page.dart';
import 'pages/statistics_page.dart';
import 'pages/search_test_page.dart';
import 'auth/permission_wrapper.dart';
import 'config/environment.dart';
import 'services/background_scanner_service.dart';
import 'design_system/design_system.dart';

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
      void _handleAuthChange() {
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
      _handleAuthChange();

      // Listener für zukünftige Auth-Änderungen
      staffAuth.addListener(_handleAuthChange);
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

class _StaffHomePageState extends State<StaffHomePage> {
  int _selectedIndex = 0;

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

      // 🔐 PERMISSION-CACHE: Bei Permission-Änderung Navigation-Cache leeren
      final permissionProvider = Provider.of<PermissionProvider>(
        context,
        listen: false,
      );
      permissionProvider.addListener(_onPermissionsChanged);
    });
  }

  /// **Callback bei Permission-Änderungen**
  void _onPermissionsChanged() {
    if (mounted) {
      setState(() {
        // Navigation-Cache leeren für Neu-Berechnung
        _cachedNavigationItems = null;
        _lastKnownPermissions = null;
      });
    }
  }

  @override
  void dispose() {
    // Listener wieder entfernen
    final permissionProvider = Provider.of<PermissionProvider>(
      context,
      listen: false,
    );
    permissionProvider.removeListener(_onPermissionsChanged);
    super.dispose();
  }

  /// **⚠️ COM-PORT STARTUP WARNING**
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Später'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigiere zu Scanner-Einstellungen im Admin-Tab
                setState(() => _selectedIndex = 3); // Admin Tab
                // TODO: Automatisch Scanner-Einstellungen öffnen
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

    final pages = <Widget>[
      const PosSystemPage(),
      PermissionWrapper(
        requiredPermission: 'can_create_products',
        child: const ProductManagementPage(),
      ),
      const StatisticsPage(),
      const SearchTestPage(), // 🔍 Neue universelle Suchfunktion
      CustomerManagementPage(isSuperUser: isSuperUser),
      PermissionWrapper(
        requiredPermission: 'can_access_admin_dashboard',
        child: AdminDashboardPage(isSuperUser: isSuperUser),
      ),
      _buildSettingsPage(context),
    ];

    // Design System Showcase nur in Debug-Modus hinzufügen
    if (kDebugMode) {
      pages.insert(pages.length - 1, const DesignSystemShowcasePage());
    }

    return pages.where((widget) {
      if (widget is PermissionWrapper) {
        final permissionProvider = Provider.of<PermissionProvider>(
          context,
          listen: false,
        );
        return permissionProvider.hasPermission(widget.requiredPermission);
      }
      return true;
    }).toList();
  }

  /// **🔐 OPTIMIZED NAVIGATION ITEMS mit Permission-Cache**
  /// Cached Navigation-Items basierend auf Permissions
  List<BottomNavigationBarItem>? _cachedNavigationItems;
  Set<String>? _lastKnownPermissions;

  List<BottomNavigationBarItem> _buildNavigationItems(BuildContext context) {
    final permissionProvider = Provider.of<PermissionProvider>(
      context,
      listen: false,
    );

    // **PERFORMANCE-OPTIMIERUNG:** Nur bei Permission-Änderung neu berechnen
    if (_cachedNavigationItems != null &&
        _lastKnownPermissions != null &&
        _lastKnownPermissions == permissionProvider.permissions) {
      return _cachedNavigationItems!;
    }

    // Navigation Items neu berechnen
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.point_of_sale),
        label: 'Verkauf',
      ),
    ];

    // 🔐 RBAC: Artikelverwaltung nur mit Permission anzeigen
    final hasProductPermission = permissionProvider.hasPermission(
      'can_create_products',
    );

    if (hasProductPermission) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Artikel',
        ),
      );
    }

    items.addAll([
      const BottomNavigationBarItem(
        icon: Icon(Icons.insert_chart),
        label: 'Statistik',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Suche'),
      const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kunden'),
    ]);

    // 🔐 RBAC: Admin-Dashboard nur mit Permission anzeigen
    final hasAdminPermission = permissionProvider.hasPermission(
      'can_access_admin_dashboard',
    );

    if (hasAdminPermission) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    // Design System Showcase (nur in Debug-Modus)
    if (kDebugMode) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.palette),
          label: 'Design',
        ),
      );
    }

    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Einstellungen',
      ),
    );

    // Cache aktualisieren
    _cachedNavigationItems = items;
    _lastKnownPermissions = Set.from(permissionProvider.permissions);

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
