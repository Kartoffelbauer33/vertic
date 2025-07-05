import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../auth/permission_wrapper.dart';
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
      builder:
          (context) => AlertDialog(
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

  String _getHallName(int? hallId) {
    switch (hallId) {
      case 1:
        return 'Greifbar Bregenz';
      case 2:
        return 'Greifbar Friedrichshafen';
      default:
        return 'Alle Hallen';
    }
  }

  Widget _getCurrentPageWidget() {
    switch (_currentPage) {
      case 'rbac_management':
        return RbacManagementPage(
          onBack: () => setState(() => _currentPage = null),
          onUnsavedChanges: _setUnsavedChanges,
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
                  icon:
                      widget.isSuperUser
                          ? Icons.verified
                          : Icons.confirmation_number,
                  title:
                      widget.isSuperUser
                          ? 'Unified Ticket Management'
                          : 'Hallen-Tickets',
                  subtitle:
                      widget.isSuperUser
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
                    onTap:
                        () => setState(() => _currentPage = 'gym_management'),
                  ),
                  const Divider(),

                  // ✅ NEUE RBAC Management UI (Phase 4.1)
                  _buildAdminListTile(
                    context,
                    icon: Icons.security,
                    title: '🔐 RBAC Management',
                    subtitle: 'Permissions, Rollen und Zuweisungen verwalten',
                    color: Colors.indigo,
                    onTap:
                        () => setState(() => _currentPage = 'rbac_management'),
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
                    onTap:
                        () => setState(
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
                  subtitle:
                      widget.isSuperUser
                          ? 'Bondrucker für alle Hallen konfigurieren'
                          : 'Bondrucker für ${_getHallName(widget.hallId)} konfigurieren',
                  color: Colors.brown,
                  onTap:
                      () => setState(() => _currentPage = 'printer_settings'),
                ),
                const Divider(),

                // 🔧 Scanner-Einstellungen (für alle Admins)
                _buildAdminListTile(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: '🔧 Scanner-Einstellungen',
                  subtitle: 'COM-Port, Scan-Typen und Hardware-Konfiguration',
                  color: Colors.purple,
                  onTap:
                      () => setState(() => _currentPage = 'scanner_settings'),
                ),
                const Divider(),

                // Dokumentenverwaltung
                _buildAdminListTile(
                  context,
                  icon: Icons.description,
                  title: 'Dokumentenverwaltung',
                  subtitle: 'Registrierungs-Dokumente verwalten und hochladen',
                  color: Colors.blueGrey,
                  onTap:
                      () =>
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
                    onTap:
                        () => setState(
                          () => _currentPage = 'system_configuration',
                        ),
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
                    onTap:
                        () => setState(
                          () => _currentPage = 'qr_rotation_settings',
                        ),
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
                  onTap:
                      () => setState(
                        () => _currentPage = 'external_provider_management',
                      ),
                ),
                const Divider(),

                // Berichte & Analytics - ✅ VOLLSTÄNDIG IMPLEMENTIERT
                _buildAdminListTile(
                  context,
                  icon: Icons.analytics,
                  title: 'Berichte & Analytics',
                  subtitle: 'Umsatzberichte, Statistiken und Datenexport',
                  color: Colors.teal,
                  onTap:
                      () => setState(() => _currentPage = 'reports_analytics'),
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
}
