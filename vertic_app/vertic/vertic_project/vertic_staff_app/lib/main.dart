import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:test_server_client/test_server_client.dart';

import 'auth/permission_provider.dart';
import 'auth/staff_auth_provider.dart';
import 'config/environment.dart';
import 'design_system/design_system.dart';

// Import all pages
import 'pages/account/account_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/admin/system_messages_page.dart';
import 'pages/admin/system_configuration_page.dart';
import 'pages/admin/unified_ticket_management_page.dart';

import 'pages/admin/pricing_management_page.dart';
import 'pages/admin/billing_management_page.dart';
import 'pages/admin/tax_class_management_page.dart';
import 'pages/admin/ticket_type_management_page.dart';
import 'pages/admin/vertic_ticket_management_page.dart';

import 'pages/admin/external_provider_management_page.dart';
import 'pages/admin/reports_analytics_page.dart';

import 'pages/administration/administration_dashboard_page.dart';
import 'pages/administration/administration_courses_page.dart';
import 'pages/administration/administration_tickets_page.dart';
import 'pages/administration/administration_roles_page.dart';
import 'pages/administration/administration_organisation_page.dart';
import 'pages/administration/administration_gmy_page.dart';
import 'pages/administration/administration_automation_page.dart';
import 'pages/administration/administration_settings_page.dart';

import 'pages/analytics/analytics_sales_page.dart';
import 'pages/analytics/analytics_returns_page.dart';
import 'pages/analytics/analytics_expenses_page.dart';
import 'pages/analytics/analytics_users_behavior_page.dart';
import 'pages/analytics/analytics_staff_page.dart';

import 'pages/customer_management_page.dart';
import 'pages/dashboard/dashbaord_page.dart';

import 'pages/fastlane/fastlane_dashboard_page.dart';
import 'pages/login_page.dart';
import 'pages/planning/planning_calendar_page.dart';
import 'pages/planning/planning_dashboard_page.dart';
import 'pages/pos_system_page.dart';
import 'pages/product_management_page.dart';
import 'pages/statistics_page.dart';

import 'services/background_scanner_service.dart';
import 'widgets/navigation/bottom_nav_bar.dart';
import 'widgets/navigation/collapsible_nav_rail.dart';
import 'router/routes.dart';

// Import für Coming Soon Widget
import 'widgets/common/coming_soon_page.dart';

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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Client-Initialisierung mit Environment-Konfiguration
  client = Client(Environment.serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StaffAuthProvider(client)),
        ChangeNotifierProvider(create: (_) => PermissionProvider(client)),
        ChangeNotifierProvider(
          create: (_) => BackgroundScannerService(client),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: 'Vertic Staff',
              theme: VerticTheme.light(context),
              darkTheme: VerticTheme.dark(context),
              themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: kDebugMode,
          home: const LoginPage(),
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
  String _selectedRoute = Routes.dashboard;
  bool _isNavExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkComPortConnectionAndWarn(
        Provider.of<BackgroundScannerService>(context, listen: false),
      );
    });
  }

  void _handleNavigation(String route) {
      setState(() {
        _selectedRoute = route;
      // Auto-collapse nav on mobile after navigation
      if (MediaQuery.of(context).size.width < 768) {
        _isNavExpanded = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
      body: Row(
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
            child: _getCurrentPage(),
                ),
              ],
            ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 768
          ? ResponsiveBottomNavBar(
              selectedRoute: _selectedRoute,
              onRouteSelected: _handleNavigation,
            )
          : null,
    );
  }

  Widget _getCurrentPage() {
    // Zeige die aktuelle Seite basierend auf der Route - STATELESS NAVIGATION
    switch (_selectedRoute) {
      // Main Navigation
      case Routes.dashboard:
        return const DashboardPage();
      case Routes.pos:
        return const PosSystemPage();
      case Routes.fastlane:
        return const FastlaneDashboardPage();
      
      // Customer Management
      case Routes.customers:
        return CustomerManagementPage(isSuperUser: false);
      case Routes.customerAdd:
        return const ComingSoonPage(title: 'Kunde anlegen');
      case Routes.customerFamilies:
        return const ComingSoonPage(title: 'Familien');
      
      // Planning
      case Routes.planning:
        return const PlanningDashboardPage();
      case Routes.planningCalendar:
        return const PlanningCalendarPage();
      case Routes.planningTimeClock:
        return const ComingSoonPage(title: 'Stempeluhr');
      case Routes.planningExchangeMarket:
        return const ComingSoonPage(title: 'Tauschbörse');
      case Routes.planningReports:
        return const ComingSoonPage(title: 'Planungsauswertung');
      case Routes.planningTodos:
        return const ComingSoonPage(title: 'To-Dos');
      
      // Stock Management
      case Routes.stock:
        return const ComingSoonPage(title: 'Lagerbestand Dashboard');
      case Routes.stockProducts:
        return const ComingSoonPage(title: 'Artikel');
      case Routes.stockOrders:
        return const ComingSoonPage(title: 'Bestellungen');
      case Routes.stockReturns:
        return const ComingSoonPage(title: 'Stornierungen');
      case Routes.stockOrderList:
        return const ComingSoonPage(title: 'Bestellliste');
      
      // Analytics & Statistics
      case Routes.statistics:
        return const StatisticsPage();
      case Routes.analyticsSales:
        return const AnalyticsSalesPage();
      case Routes.analyticsReturns:
        return const AnalyticsReturnsPage();
      case Routes.analyticsExpenses:
        return const AnalyticsExpensesPage();
      case Routes.analyticsUserBehavior:
        return const AnalyticsUsersBehaviorPage();
      case Routes.analyticsStaff:
        return const AnalyticsStaffPage();
      
      // Administration
      case Routes.administration:
        return const AdministrationDashboardPage();
      case Routes.adminProducts:
        return const ProductManagementPage();
      case Routes.adminTickets:
        return const AdministrationTicketsPage();
      case Routes.adminCourses:
        return const AdministrationCoursesPage();
      case Routes.adminStaff:
        return const ComingSoonPage(title: 'Mitarbeiterverwaltung');
      case Routes.adminRoles:
        return const AdministrationRolesPage();
      case Routes.adminOrganization:
        return const AdministrationOrganisationPage();
      case Routes.adminGym:
        return const AdministrationGmyPage();
      case Routes.adminAutomation:
        return const AdministrationAutomationPage();
      case Routes.adminSettings:
        return const AdministrationSettingsPage();
      
      // Superuser Admin
      case Routes.adminDashboard:
        return const AdminDashboardPage();
      case Routes.adminSystemMessages:
        return const SystemMessagesPage();
      case Routes.adminSystemConfiguration:
        return const SystemConfigurationPage();
      case Routes.adminUnifiedTicketManagement:
        return const UnifiedTicketManagementPage();
      case Routes.adminEmailVerification:
        return const ComingSoonPage(title: 'Email Verification');
      case Routes.adminGymManagement:
        return const ComingSoonPage(title: 'Gym Verwaltung');
      case Routes.adminRbacManagement:
        return const ComingSoonPage(title: 'RBAC Management');
      case Routes.adminPrinterSettings:
        return const ComingSoonPage(title: 'Drucker Einstellungen');
      case Routes.adminScannerSettings:
        return const ComingSoonPage(title: 'Scanner Einstellungen');
      case Routes.adminDocumentManagement:
        return const ComingSoonPage(title: 'Dokumentenverwaltung');
      case Routes.adminRolePermissions:
        return const ComingSoonPage(title: 'Rollen & Permissions');
      case Routes.adminUserStatusManagement:
        return const ComingSoonPage(title: 'Benutzer-Status Management');
      case Routes.adminNewStaffManagement:
        return const ComingSoonPage(title: 'New Staff Management');
      case Routes.adminStaffManagement:
        return const ComingSoonPage(title: 'Staff Management');
      case Routes.adminNewStaff:
        return const ComingSoonPage(title: 'New Staff');
      case Routes.adminPricingManagement:
        return const PricingManagementPage();
      case Routes.adminBillingManagement:
        return const BillingManagementPage();
      case Routes.adminTaxClassManagement:
        return const TaxClassManagementPage();
      case Routes.adminTicketTypeManagement:
        return const TicketTypeManagementPage();
      case Routes.adminVerticTicketManagement:
        return const VerticTicketManagementPage();
      case Routes.adminTicketVisibility:
        return const ComingSoonPage(title: 'Ticket Sichtbarkeit');
      case Routes.adminQrCodeRotation:
        return const ComingSoonPage(title: 'QR-Code Einstellungen');
      case Routes.adminExternalProviderManagement:
        return const ExternalProviderManagementPage();
      case Routes.adminDachCompliance:
        return const ComingSoonPage(title: 'DACH-Compliance');
      case Routes.adminReportsAnalytics:
        return const ReportsAnalyticsPage();
      case Routes.adminBackup:
        return const ComingSoonPage(title: 'Backup & Wartung');
      
      // Design System
      case Routes.design:
        return const DesignSystemShowcasePage();
      
      // Account
      case Routes.account:
      case Routes.accountTabProfile:
        return const AccountPage(initialTab: 0);
      case Routes.accountTabShifts:
        return const AccountPage(initialTab: 1);
      case Routes.accountTabPermissions:
        return const AccountPage(initialTab: 2);
      case Routes.accountTabNotifications:
        return const AccountPage(initialTab: 3);
      case Routes.accountTabSecurity:
        return const AccountPage(initialTab: 4);
      case Routes.accountTabSettings:
        return const AccountPage(initialTab: 5);
      
      default:
        return const DashboardPage();
    }
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
              const SizedBox(height: 12),
              Text(
                'Mögliche Ursachen:',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '• Scanner ist nicht eingeschaltet\n'
                '• USB-Kabel ist nicht angeschlossen\n'
                '• COM-Port wird von anderer Software verwendet\n'
                '• Scanner-Treiber fehlt',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Verstanden'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to scanner settings page
              },
              child: Text('Einstellungen öffnen'),
            ),
          ],
        );
      },
    );
  }
}
