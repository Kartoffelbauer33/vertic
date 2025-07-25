import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import 'unified_ticket_management_page.dart';
import 'gym_management_page.dart';
// import 'user_management_page.dart'; // Temporär deaktiviert
import 'rbac_management_page.dart';

import 'ticket_visibility_settings_page.dart';
import 'printer_settings_page.dart';
import 'document_management_page.dart';
import 'user_status_management_page.dart';
import 'pricing_management_page.dart';
import 'billing_management_page.dart';
import 'system_messages_page.dart';
import 'qr_rotation_settings_page.dart';
import 'reports_analytics_page.dart';
import 'system_configuration_page.dart';
import 'external_provider_management_page.dart';
import 'scanner_settings_page.dart';
import 'tax_class_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final bool isSuperUser;
  final int? hallId;

  const AdminDashboardPage({super.key, this.isSuperUser = false, this.hallId});

  @override
  State<AdminDashboardPage> createState() => AdminDashboardPageState();
}

class AdminDashboardPageState extends State<AdminDashboardPage> {
  String? _currentPage; // null = Dashboard, sonst Page-Name
  bool _hasUnsavedChanges = false; // Track für ungespeicherte Änderungen
  String? _unsavedContext; // Kontext für die Warnung
  
  // Dynamic facility data from backend
  List<Facility> _facilities = [];
  bool _facilitiesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  /// **🏢 Lädt Facilities dynamisch vom Backend**
  Future<void> _loadFacilities() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final facilities = await client.facility.getAllFacilities();
      
      setState(() {
        _facilities = facilities;
        _facilitiesLoaded = true;
      });
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Facilities: $e');
      setState(() {
        _facilitiesLoaded = true; // Auch bei Fehler als geladen markieren
      });
    }
  }

  // Methode um das Dashboard von außen zurückzusetzen
  void resetToMainPage() {
    if (_hasUnsavedChanges && _unsavedContext != null) {
      // Zeige Warnung an
      _showUnsavedChangesDialog();
    } else {
      // Normaler Reset zur Hauptseite
      setState(() {
        _currentPage = null;
        _hasUnsavedChanges = false;
        _unsavedContext = null;
      });
    }
  }

  @override
  void didUpdateWidget(AdminDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to dashboard when properties change
    if (oldWidget.isSuperUser != widget.isSuperUser ||
        oldWidget.hallId != widget.hallId) {
      resetToMainPage();
    }
  }

  // Methoden für Unsaved-Changes Management
  void _setUnsavedChanges(bool hasChanges, [String? context]) {
    setState(() {
      _hasUnsavedChanges = hasChanges;
      _unsavedContext = context;
    });
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Ungespeicherte Änderungen'),
          ],
        ),
        content: Text(
          _unsavedContext != null
              ? 'Sie haben ungespeicherte Änderungen in "$_unsavedContext". Möchten Sie diese verwerfen und zur Hauptseite zurückkehren?'
              : 'Sie haben ungespeicherte Änderungen. Möchten Sie diese verwerfen und zur Hauptseite zurückkehren?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Bleibe auf der aktuellen Seite
            },
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Gehe zur Hauptseite und verwerfe Änderungen
              setState(() {
                _currentPage = null;
                _hasUnsavedChanges = false;
                _unsavedContext = null;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Änderungen verwerfen'),
          ),
        ],
      ),
    );
  }

  /// **🏢 Dynamische Hall-Namen aus Backend-Daten**
  /// Ersetzt hardcodierte Hall-Namen durch echte Facility-Daten
  String _getHallName(int? hallId) {
    if (!_facilitiesLoaded) {
      return 'Laden...';
    }
    
    if (hallId == null) {
      return 'Alle Hallen';
    }
    
    try {
      final facility = _facilities.firstWhere((f) => f.id == hallId);
      return facility.name;
    } catch (e) {
      debugPrint('⚠️ Facility mit ID $hallId nicht gefunden: $e');
      return 'Unbekannte Halle (ID: $hallId)';
    }
  }

  Widget _getCurrentPageWidget() {
    switch (_currentPage) {
      case 'rbac_management':
        return RbacManagementPage(
          isSuperUser: widget.isSuperUser,
          hallId: widget.hallId,
        );

      case 'unified_tickets':
        return UnifiedTicketManagementPage(
          isSuperUser: widget.isSuperUser,
          hallId: widget.hallId,
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'user_status':
        return UserStatusManagementPage(
          isSuperUser: widget.isSuperUser,
          hallId: widget.hallId,
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'pricing':
        return PricingManagementPage(
          isSuperUser: widget.isSuperUser,
          hallId: widget.hallId,
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'billing':
        return BillingManagementPage(
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'system_messages':
        return SystemMessagesPage(
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'qr_rotation_settings':
        return QrRotationSettingsPage(
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'ticket_visibility_settings':
        return TicketVisibilitySettingsPage(
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'printer_settings':
        return PrinterSettingsPage(
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'gym_management':
        return GymManagementPage(
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'document_management':
        return DocumentManagementPage(
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'reports_analytics':
        return ReportsAnalyticsPage(
          isSuperUser: widget.isSuperUser,
          hallId: widget.hallId,
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'system_configuration':
        return SystemConfigurationPage(
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );

      case 'external_provider_management':
        return ExternalProviderManagementPage(
          isSuperUser: widget.isSuperUser,
          hallId: widget.hallId,
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      case 'scanner_settings':
        return ScannerSettingsPage(
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
        );
      default:
        return _buildDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _getCurrentPageWidget();
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            widget.isSuperUser
                ? 'Vertic Zentral-Verwaltung'
                : '${_getHallName(widget.hallId)} - Verwaltung',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isSuperUser
                ? 'Universelle Ticket-Verwaltung für alle Vertic-Hallen'
                : 'Verwaltung für ${_getHallName(widget.hallId)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                // System-Meldungen (für alle Admins)
                _buildAdminListTile(
                  context,
                  icon: Icons.notifications_active,
                  title: 'System-Meldungen',
                  subtitle:
                      'Warnungen und Hinweise zu fehlenden Ticket-Kombinationen',
                  color: Colors.amber,
                  onTap: () => setState(() => _currentPage = 'system_messages'),
                ),
                const Divider(),

                // Unified Ticket Management
                _buildAdminListTile(
                  context,
                  icon: widget.isSuperUser
                      ? Icons.verified
                      : Icons.confirmation_number,
                  title: widget.isSuperUser
                      ? 'Unified Ticket Management'
                      : 'Hallen-Tickets',
                  subtitle: widget.isSuperUser
                      ? 'Vertic Universal-Tickets und Gym-spezifische Tickets'
                      : 'Tickets für ${_getHallName(widget.hallId)} verwalten',
                  color: widget.isSuperUser ? Colors.teal : Colors.blue,
                  onTap: () => setState(() => _currentPage = 'unified_tickets'),
                ),
                const Divider(),

                // Gym-Verwaltung (nur SuperUser)
                if (widget.isSuperUser) ...[
                  _buildAdminListTile(
                    context,
                    icon: Icons.fitness_center,
                    title: 'Gym-Verwaltung',
                    subtitle: 'Standorte erstellen und verwalten',
                    color: Colors.deepOrange,
                    onTap: () =>
                        setState(() => _currentPage = 'gym_management'),
                  ),
                  const Divider(),

                  // ✅ NEUE RBAC Management UI (Phase 4.1)
                  _buildAdminListTile(
                    context,
                    icon: Icons.security,
                    title: '🔐 RBAC Management',
                    subtitle: 'Permissions, Rollen und Zuweisungen verwalten',
                    color: Colors.indigo,
                    onTap: () =>
                        setState(() => _currentPage = 'rbac_management'),
                  ),
                  const Divider(),

                  // ✅ Staff User Management ist jetzt in RBAC Management integriert
                  // (Entfernt - Staff-Verwaltung erfolgt über RBAC Management Tab)

                  // User Management Page temporär deaktiviert - veraltete StaffUser Properties
                  // _buildAdminListTile(
                  //   context,
                  //   icon: Icons.supervised_user_circle,
                  //   title: 'Benutzerverwaltung',
                  //   subtitle: 'Staff, Admins und Berechtigungen verwalten',
                  //   color: Colors.indigo,
                  //   onTap: () =>
                  //       setState(() => _currentPage = 'user_management'),
                  // ),
                  // const Divider(),
                ],

                // Ticket-Sichtbarkeit verwalten (nur SuperUser)
                if (widget.isSuperUser) ...[
                  _buildAdminListTile(
                    context,
                    icon: Icons.visibility,
                    title: 'Ticket-Sichtbarkeit',
                    subtitle:
                        'Steuern Sie, welche Tickets für Clients sichtbar sind',
                    color: Colors.cyan,
                    onTap: () => setState(
                      () => _currentPage = 'ticket_visibility_settings',
                    ),
                  ),
                  const Divider(),
                ],

                // Drucker-Einstellungen (für Hall Admins und SuperUser)
                _buildAdminListTile(
                  context,
                  icon: Icons.print,
                  title: 'Drucker-Einstellungen',
                  subtitle: widget.isSuperUser
                      ? 'Bondrucker für alle Hallen konfigurieren'
                      : 'Bondrucker für ${_getHallName(widget.hallId)} konfigurieren',
                  color: Colors.brown,
                  onTap: () =>
                      setState(() => _currentPage = 'printer_settings'),
                ),
                const Divider(),

                // 🔧 Scanner-Einstellungen (für alle Admins)
                _buildAdminListTile(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: '🔧 Scanner-Einstellungen',
                  subtitle: 'COM-Port, Scan-Typen und Hardware-Konfiguration',
                  color: Colors.purple,
                  onTap: () =>
                      setState(() => _currentPage = 'scanner_settings'),
                ),
                const Divider(),

                // Dokumentenverwaltung
                _buildAdminListTile(
                  context,
                  icon: Icons.description,
                  title: 'Dokumentenverwaltung',
                  subtitle: 'Registrierungs-Dokumente verwalten und hochladen',
                  color: Colors.blueGrey,
                  onTap: () =>
                      setState(() => _currentPage = 'document_management'),
                ),
                const Divider(),

                // User-Status verwalten
                _buildAdminListTile(
                  context,
                  icon: Icons.people_alt,
                  title: 'Benutzer-Status verwalten',
                  subtitle:
                      'Ermäßigungen, Rabatte und spezielle Preise definieren',
                  color: Colors.green,
                  onTap: () => setState(() => _currentPage = 'user_status'),
                ),
                const Divider(),

                // Preisgestaltung
                _buildAdminListTile(
                  context,
                  icon: Icons.euro,
                  title: 'Preisgestaltung',
                  subtitle:
                      'Preise für verschiedene Status und Ticket-Kombinationen',
                  color: Colors.orange,
                  onTap: () => setState(() => _currentPage = 'pricing'),
                ),
                const Divider(),

                // Abrechnungsmanagement (nur SuperUser)
                if (widget.isSuperUser) ...[
                  _buildAdminListTile(
                    context,
                    icon: Icons.payment,
                    title: 'Abrechnungsmanagement',
                    subtitle:
                        'Zentrale Konfiguration von Abrechnungszyklen (nur SuperUser)',
                    color: Colors.indigo,
                    onTap: () => setState(() => _currentPage = 'billing'),
                  ),
                  const Divider(),
                ],

                // System-Einstellungen (nur SuperUser) - ✅ VOLLSTÄNDIG IMPLEMENTIERT
                if (widget.isSuperUser) ...[
                  _buildAdminListTile(
                    context,
                    icon: Icons.settings_applications,
                    title: 'System-Konfiguration',
                    subtitle:
                        'Allgemeine Einstellungen und Parameter (nur SuperUser)',
                    color: Colors.indigo,
                    onTap: () =>
                        setState(() => _currentPage = 'system_configuration'),
                  ),
                  const Divider(),

                  // QR-Code Rotation Policy (nur SuperUser)
                  _buildAdminListTile(
                    context,
                    icon: Icons.qr_code_2,
                    title: 'QR-Code Rotation',
                    subtitle:
                        'Sicherheitsrichtlinien für QR-Code-Rotation konfigurieren',
                    color: Colors.deepPurple,
                    onTap: () =>
                        setState(() => _currentPage = 'qr_rotation_settings'),
                  ),
                  const Divider(),
                ],

                // External Provider Management - ✅ PHASE 4 IMPLEMENTIERT
                _buildAdminListTile(
                  context,
                  icon: Icons.extension,
                  title: '🌐 External Provider Management',
                  subtitle: 'Fitpass, Friction und andere Provider verwalten',
                  color: Colors.indigo,
                  onTap: () => setState(
                    () => _currentPage = 'external_provider_management',
                  ),
                ),
                const Divider(),

                // 🏛️ DACH-Compliance Management - ✅ PHASE 1 IMPLEMENTIERT
                if (widget.isSuperUser) ...[
                  _buildAdminListTile(
                    context,
                    icon: Icons.account_balance,
                    title: '🏛️ DACH-Compliance',
                    subtitle:
                        'Deutschland & Österreich Steuerklassen, TSE, RKSV',
                    color: Colors.blue,
                    onTap: () => _showDACHComplianceDialog(context),
                  ),
                  const Divider(),
                ],

                // Berichte & Analytics - ✅ VOLLSTÄNDIG IMPLEMENTIERT
                _buildAdminListTile(
                  context,
                  icon: Icons.analytics,
                  title: 'Berichte & Analytics',
                  subtitle: 'Umsatzberichte, Statistiken und Datenexport',
                  color: Colors.teal,
                  onTap: () =>
                      setState(() => _currentPage = 'reports_analytics'),
                ),
                const Divider(),

                // Backup & Wartung (nur SuperUser)
                if (widget.isSuperUser) ...[
                  _buildAdminListTile(
                    context,
                    icon: Icons.backup,
                    title: 'Backup & Wartung',
                    subtitle:
                        'Datensicherung, Updates und Systempflege (nur SuperUser)',
                    color: Colors.red,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Wartung - In Entwicklung'),
                        ),
                      );
                    },
                  ),
                ],

                // Staff Management temporär deaktiviert - RBAC wird überarbeitet
                // _buildAdminListTile(
                //   context,
                //   icon: Icons.people_outline,
                //   title: 'Staff Management (Neue Tabelle)',
                //   subtitle: 'Mitarbeiter-Verwaltung mit HR-Funktionen',
                //   color: Colors.green,
                //   onTap: () => setState(() => _currentPage = 'staff_management'),
                // ),
                // const Divider(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  // Neue Methode für DACH-Compliance Management Card hinzufügen
  Widget _buildDACHComplianceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: Colors.blue, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DACH-Compliance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Steuerklassen & Länder-Einstellungen',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildComplianceButton(
                  context,
                  'Deutschland Setup',
                  Icons.flag,
                  Colors.red,
                  () => _setupGermany(context),
                ),
                _buildComplianceButton(
                  context,
                  'Österreich Setup',
                  Icons.flag_outlined,
                  Colors.red[800]!,
                  () => _setupAustria(context),
                ),
                _buildComplianceButton(
                  context,
                  'Länder verwalten',
                  Icons.public,
                  Colors.green,
                  () => _manageCountries(context),
                ),
                _buildComplianceButton(
                  context,
                  'Steuerklassen',
                  Icons.receipt_long,
                  Colors.orange,
                  () => _manageTaxClasses(context),
                ),
                _buildComplianceButton(
                  context,
                  'Facility-Länder',
                  Icons.business,
                  Colors.purple,
                  () => _manageFacilityCountries(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // Dialog für DACH-Compliance Management
  void _showDACHComplianceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.account_balance, color: Colors.blue),
              const SizedBox(width: 8),
              Text('DACH-Compliance Management'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _buildDACHComplianceCard(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  // Setup-Methoden für DACH-Compliance
  Future<void> _setupGermany(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Deutschland wird eingerichtet...');

      final client = Provider.of<Client>(context, listen: false);
      final result = await client.taxManagement.setupGermanyDefaults();

      Navigator.of(context).pop(); // Dialog schließen

      _showSuccessDialog(context, 'Deutschland Setup', result);
    } catch (e) {
      Navigator.of(context).pop(); // Dialog schließen
      _showErrorDialog(context, 'Deutschland Setup Fehler', e.toString());
    }
  }

  Future<void> _setupAustria(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Österreich wird eingerichtet...');

      final client = Provider.of<Client>(context, listen: false);
      final result = await client.taxManagement.setupAustriaDefaults();

      Navigator.of(context).pop(); // Dialog schließen

      _showSuccessDialog(context, 'Österreich Setup', result);
    } catch (e) {
      Navigator.of(context).pop(); // Dialog schließen
      _showErrorDialog(context, 'Österreich Setup Fehler', e.toString());
    }
  }

  Future<void> _manageCountries(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Länder werden geladen...');

      final client = Provider.of<Client>(context, listen: false);
      final countries = await client.taxManagement.getAllCountries();

      Navigator.of(context).pop(); // Dialog schließen

      _showCountriesDialog(context, countries);
    } catch (e) {
      Navigator.of(context).pop(); // Dialog schließen
      _showErrorDialog(context, 'Länder-Fehler', e.toString());
    }
  }

  Future<void> _manageTaxClasses(BuildContext context) async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TaxClassManagementPage()),
    );
  }

  /// **🏛️ SuperUser-only: Facility-Länder-Zuordnung verwalten**
  Future<void> _manageFacilityCountries(BuildContext context) async {
    try {
      _showLoadingDialog(context, 'Facilities und Länder werden geladen...');

      final client = Provider.of<Client>(context, listen: false);
      final facilities = await client.facility.getAllFacilities();
      final countries = await client.taxManagement.getAllCountries();

      Navigator.of(context).pop(); // Loading dialog schließen

      _showFacilityCountryManagementDialog(context, facilities, countries);
    } catch (e) {
      Navigator.of(context).pop(); // Loading dialog schließen
      _showErrorDialog(context, 'Facility-Länder Fehler', e.toString());
    }
  }

  // Dialog-Hilfsmethoden
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showCountriesDialog(BuildContext context, List<Country> countries) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Verfügbare Länder (${countries.length})'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: countries.length,
              itemBuilder: (context, index) {
                final country = countries[index];
                return ListTile(
                  leading: Icon(
                    country.isDefault ? Icons.star : Icons.flag,
                    color: country.isDefault ? Colors.amber : Colors.grey,
                  ),
                  title: Text(country.displayName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${country.code} | ${country.currency}'),
                      Row(
                        children: [
                          if (country.requiresTSE)
                            Chip(
                              label: Text('TSE'),
                              backgroundColor: Colors.red[100],
                            ),
                          if (country.requiresRKSV)
                            Chip(
                              label: Text('RKSV'),
                              backgroundColor: Colors.orange[100],
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: country.isActive,
                    onChanged: null, // TODO: Implementierung für Toggle
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  /// **🏛️ SuperUser-only: Facility-Country-Assignment Dialog**
  void _showFacilityCountryManagementDialog(
    BuildContext context,
    List<Facility> facilities,
    List<Country> countries,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.business, color: Colors.purple),
              const SizedBox(width: 8),
              Text('Facility-Länder-Zuordnung'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ WICHTIG: Länder-Zuordnung ist permanent und kann nur von SuperUsern geändert werden.',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Facilities (${facilities.length}):',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: facilities.length,
                    itemBuilder: (context, index) {
                      final facility = facilities[index];
                      final assignedCountry = facility.countryId != null
                          ? countries.firstWhere(
                              (c) => c.id == facility.countryId,
                              orElse: () => countries.first,
                            )
                          : null;

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            facility.isCountryLocked
                                ? Icons.lock
                                : Icons.business,
                            color: facility.isCountryLocked
                                ? Colors.red
                                : Colors.grey,
                          ),
                          title: Text(facility.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (facility.city != null)
                                Text('📍 ${facility.city}'),
                              Row(
                                children: [
                                  Text(
                                    assignedCountry != null
                                        ? '🌍 ${assignedCountry.displayName}'
                                        : '❌ Kein Land zugewiesen',
                                    style: TextStyle(
                                      color: assignedCountry != null
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (facility.isCountryLocked)
                                    Chip(
                                      label: Text('LOCKED'),
                                      backgroundColor: Colors.red[100],
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () =>
                                _showFacilityCountryAssignmentDialog(
                                  context,
                                  facility,
                                  countries,
                                ),
                            child: Text(
                              assignedCountry != null ? 'Ändern' : 'Zuweisen',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  /// **🏛️ Individual Facility-Country Assignment Dialog**
  void _showFacilityCountryAssignmentDialog(
    BuildContext context,
    Facility facility,
    List<Country> countries,
  ) {
    Country? selectedCountry = facility.countryId != null
        ? countries.firstWhere(
            (c) => c.id == facility.countryId,
            orElse: () => countries.first,
          )
        : null;
    bool lockCountry = facility.isCountryLocked;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Land zuweisen: ${facility.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktuell: ${facility.countryId != null ? "Land zugewiesen" : "Kein Land"}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<Country>(
                    value: selectedCountry,
                    decoration: const InputDecoration(
                      labelText: 'Land auswählen',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: countries.map((country) {
                      return DropdownMenuItem<Country>(
                        value: country,
                        child: Row(
                          children: [
                            Text(
                              country.code,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text(country.displayName),
                            const SizedBox(width: 8),
                            if (country.requiresTSE)
                              Chip(
                                label: Text('TSE'),
                                backgroundColor: Colors.red[100],
                              ),
                            if (country.requiresRKSV)
                              Chip(
                                label: Text('RKSV'),
                                backgroundColor: Colors.orange[100],
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (country) {
                      setState(() {
                        selectedCountry = country;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: Text('Land sperren'),
                    subtitle: Text(
                      'Verhindert weitere Änderungen durch Facility-Admins',
                    ),
                    value: lockCountry,
                    onChanged: (value) {
                      setState(() {
                        lockCountry = value ?? false;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ WARNUNG:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                        Text(
                          '• Länder-Zuordnung bestimmt Steuerklassen und Compliance\n' +
                              '• Einmal gesperrt, kann nur SuperUser ändern\n' +
                              '• Beeinflusst alle Artikel in dieser Facility',
                          style: TextStyle(color: Colors.amber[800]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: selectedCountry != null
                      ? () async {
                          try {
                            _showLoadingDialog(
                              context,
                              'Land wird zugewiesen...',
                            );

                            final client = Provider.of<Client>(
                              context,
                              listen: false,
                            );
                            final success = await client.facility
                                .assignCountryToFacility(
                                  facility.id!,
                                  selectedCountry!.id!,
                                  lockCountry: lockCountry,
                                );

                            Navigator.of(context).pop(); // Loading dialog

                            if (success) {
                              _showSuccessDialog(
                                context,
                                'Land zugewiesen',
                                'Land ${selectedCountry!.displayName} erfolgreich zu ${facility.name} zugewiesen.\n${lockCountry ? "🔒 Land ist gesperrt." : "🔓 Land kann geändert werden."}',
                              );
                              Navigator.of(context).pop(); // Assignment dialog
                              Navigator.of(context).pop(); // Management dialog
                              // Refresh facility list
                              _manageFacilityCountries(context);
                            } else {
                              _showErrorDialog(
                                context,
                                'Fehler',
                                'Land-Zuordnung fehlgeschlagen. Prüfen Sie Ihre Berechtigung.',
                              );
                            }
                          } catch (e) {
                            Navigator.of(context).pop(); // Loading dialog
                            _showErrorDialog(context, 'Fehler', e.toString());
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Zuweisen'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
