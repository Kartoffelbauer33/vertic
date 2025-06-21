import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../main.dart';
import '../../auth/permission_wrapper.dart';

class SystemConfigurationPage extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(bool, String?)? onUnsavedChanges;

  const SystemConfigurationPage({
    super.key,
    this.onBack,
    this.onUnsavedChanges,
  });

  @override
  State<SystemConfigurationPage> createState() =>
      _SystemConfigurationPageState();
}

class _SystemConfigurationPageState extends State<SystemConfigurationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Loading States
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Configuration Data
  Map<String, dynamic> _systemSettings = {};

  // Controllers für Einstellungen
  final _maxLoginAttemptsController = TextEditingController();
  final _sessionTimeoutController = TextEditingController();
  final _backupIntervalController = TextEditingController();
  final _maxFileSizeController = TextEditingController();

  // Checkbox States
  bool _enableAuditLogging = true;
  bool _enableEmailNotifications = false;
  bool _enableSMSNotifications = false;
  bool _enableMaintenanceMode = false;
  bool _enforcePasswordPolicy = true;
  bool _enableTwoFactorAuth = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSystemSettings();
  }

  @override
  void dispose() {
    _maxLoginAttemptsController.dispose();
    _sessionTimeoutController.dispose();
    _backupIntervalController.dispose();
    _maxFileSizeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSystemSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Lade echte System-Einstellungen vom Backend
      // final settings = await client.systemSettings.getAll();

      // Mock-Daten für jetzt
      _systemSettings = {
        'maxLoginAttempts': 5,
        'sessionTimeoutMinutes': 30,
        'backupIntervalHours': 24,
        'maxFileSizeMB': 10,
        'enableAuditLogging': true,
        'enableEmailNotifications': false,
        'enableSMSNotifications': false,
        'enableMaintenanceMode': false,
        'enforcePasswordPolicy': true,
        'enableTwoFactorAuth': false,
      };

      _applySettingsToControllers();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Einstellungen: $e';
        _isLoading = false;
      });
    }
  }

  void _applySettingsToControllers() {
    _maxLoginAttemptsController.text =
        _systemSettings['maxLoginAttempts']?.toString() ?? '5';
    _sessionTimeoutController.text =
        _systemSettings['sessionTimeoutMinutes']?.toString() ?? '30';
    _backupIntervalController.text =
        _systemSettings['backupIntervalHours']?.toString() ?? '24';
    _maxFileSizeController.text =
        _systemSettings['maxFileSizeMB']?.toString() ?? '10';

    _enableAuditLogging = _systemSettings['enableAuditLogging'] ?? true;
    _enableEmailNotifications =
        _systemSettings['enableEmailNotifications'] ?? false;
    _enableSMSNotifications =
        _systemSettings['enableSMSNotifications'] ?? false;
    _enableMaintenanceMode = _systemSettings['enableMaintenanceMode'] ?? false;
    _enforcePasswordPolicy = _systemSettings['enforcePasswordPolicy'] ?? true;
    _enableTwoFactorAuth = _systemSettings['enableTwoFactorAuth'] ?? false;
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Speichere Einstellungen im Backend
      // await client.systemSettings.updateAll(_collectSettings());

      setState(() {
        _hasUnsavedChanges = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ System-Einstellungen erfolgreich gespeichert'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onUnsavedChanges?.call(false, null);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Fehler beim Speichern: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _collectSettings() {
    return {
      'maxLoginAttempts': int.tryParse(_maxLoginAttemptsController.text) ?? 5,
      'sessionTimeoutMinutes':
          int.tryParse(_sessionTimeoutController.text) ?? 30,
      'backupIntervalHours': int.tryParse(_backupIntervalController.text) ?? 24,
      'maxFileSizeMB': int.tryParse(_maxFileSizeController.text) ?? 10,
      'enableAuditLogging': _enableAuditLogging,
      'enableEmailNotifications': _enableEmailNotifications,
      'enableSMSNotifications': _enableSMSNotifications,
      'enableMaintenanceMode': _enableMaintenanceMode,
      'enforcePasswordPolicy': _enforcePasswordPolicy,
      'enableTwoFactorAuth': _enableTwoFactorAuth,
    };
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
      widget.onUnsavedChanges?.call(true, 'System-Konfiguration');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionWrapper(
      requiredPermission: 'can_edit_system_settings',
      placeholder: _buildAccessDenied(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: _isLoading
            ? _buildLoadingView()
            : _errorMessage != null
                ? _buildErrorView()
                : _buildMainContent(),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        '⚙️ System-Konfiguration',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed:
            _hasUnsavedChanges ? _showUnsavedChangesDialog : widget.onBack,
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.security), text: 'Sicherheit'),
          Tab(icon: Icon(Icons.notifications), text: 'Benachrichtigung'),
          Tab(icon: Icon(Icons.backup), text: 'Backup'),
          Tab(icon: Icon(Icons.build), text: 'Wartung'),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('System-Einstellungen werden geladen...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSystemSettings,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildSecurityTab(),
        _buildNotificationTab(),
        _buildBackupTab(),
        _buildMaintenanceTab(),
      ],
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Anmelde-Sicherheit',
            [
              _buildNumberField(
                'Maximale Anmeldeversuche',
                'Anzahl der fehlgeschlagenen Anmeldeversuche bevor Account gesperrt wird',
                _maxLoginAttemptsController,
                Icons.lock_outline,
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                'Session-Timeout (Minuten)',
                'Automatische Abmeldung nach Inaktivität',
                _sessionTimeoutController,
                Icons.timer,
              ),
              const SizedBox(height: 16),
              _buildSwitchTile(
                'Password-Policy durchsetzen',
                'Starke Passwort-Anforderungen aktivieren',
                _enforcePasswordPolicy,
                (value) => setState(() {
                  _enforcePasswordPolicy = value;
                  _markAsChanged();
                }),
                Icons.password,
              ),
              _buildSwitchTile(
                'Zwei-Faktor-Authentifizierung',
                '2FA für alle Benutzer aktivieren (geplant)',
                _enableTwoFactorAuth,
                (value) => setState(() {
                  _enableTwoFactorAuth = value;
                  _markAsChanged();
                }),
                Icons.verified_user,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            'Audit & Logging',
            [
              _buildSwitchTile(
                'Audit-Logging aktivieren',
                'Alle System-Aktivitäten protokollieren',
                _enableAuditLogging,
                (value) => setState(() {
                  _enableAuditLogging = value;
                  _markAsChanged();
                }),
                Icons.history,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Benachrichtigungs-Kanäle',
            [
              _buildSwitchTile(
                'E-Mail-Benachrichtigungen',
                'System-E-Mails für wichtige Ereignisse',
                _enableEmailNotifications,
                (value) => setState(() {
                  _enableEmailNotifications = value;
                  _markAsChanged();
                }),
                Icons.email,
              ),
              _buildSwitchTile(
                'SMS-Benachrichtigungen',
                'SMS für kritische System-Warnungen (geplant)',
                _enableSMSNotifications,
                (value) => setState(() {
                  _enableSMSNotifications = value;
                  _markAsChanged();
                }),
                Icons.sms,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            'Benachrichtigungs-Einstellungen',
            [
              const ListTile(
                leading: Icon(Icons.info, color: Colors.blue),
                title: Text('E-Mail-Server konfigurieren'),
                subtitle: Text('SMTP-Einstellungen für ausgehende E-Mails'),
                trailing: Icon(Icons.chevron_right),
              ),
              const ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('SMS-Provider konfigurieren'),
                subtitle: Text('API-Einstellungen für SMS-Versand'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Automatische Backups',
            [
              _buildNumberField(
                'Backup-Intervall (Stunden)',
                'Automatische Datenbank-Backups alle X Stunden',
                _backupIntervalController,
                Icons.schedule,
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                'Maximale Dateigröße (MB)',
                'Maximale Größe für hochgeladene Dateien',
                _maxFileSizeController,
                Icons.file_upload,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            'Backup-Aktionen',
            [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.backup, color: Colors.blue),
                ),
                title: const Text('Sofortiges Backup erstellen'),
                subtitle:
                    const Text('Erstellt ein vollständiges System-Backup'),
                trailing: ElevatedButton(
                  onPressed: _createManualBackup,
                  child: const Text('Backup erstellen'),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restore, color: Colors.green),
                ),
                title: const Text('Backup wiederherstellen'),
                subtitle:
                    const Text('System aus vorherigem Backup wiederherstellen'),
                trailing: ElevatedButton(
                  onPressed: _showRestoreDialog,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Wiederherstellen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Wartungsmodus',
            [
              _buildSwitchTile(
                'Wartungsmodus aktivieren',
                'System für Wartungsarbeiten sperren',
                _enableMaintenanceMode,
                (value) => setState(() {
                  _enableMaintenanceMode = value;
                  _markAsChanged();
                }),
                Icons.build,
                isWarning: true,
              ),
              if (_enableMaintenanceMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Wartungsmodus ist aktiviert. Nur Administratoren können sich anmelden.',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            'System-Wartung',
            [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_sweep, color: Colors.red),
                ),
                title: const Text('Temp-Dateien löschen'),
                subtitle: const Text('Temporäre Dateien und Cache leeren'),
                trailing: ElevatedButton(
                  onPressed: _cleanTempFiles,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Bereinigen'),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.purple),
                ),
                title: const Text('System-Diagnose'),
                subtitle: const Text('Vollständige System-Überprüfung'),
                trailing: ElevatedButton(
                  onPressed: _runSystemDiagnostics,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text('Diagnose'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, String description,
      TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _markAsChanged(),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String description, bool value,
      ValueChanged<bool> onChanged, IconData icon,
      {bool isWarning = false}) {
    return ListTile(
      leading: Icon(icon, color: isWarning ? Colors.orange : Colors.blue),
      title: Text(title),
      subtitle: Text(description),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: isWarning ? Colors.orange : Colors.blue,
      ),
    );
  }

  Widget _buildBottomBar() {
    if (!_hasUnsavedChanges) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Sie haben ungespeicherte Änderungen',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: _loadSystemSettings,
            child: const Text('Verwerfen'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ System-Konfiguration'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Zugriff verweigert',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Sie haben keine Berechtigung für System-Einstellungen',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text(
          'Sie haben ungespeicherte Änderungen. Möchten Sie diese speichern?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onBack?.call();
            },
            child: const Text('Verwerfen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveSettings().then((_) => widget.onBack?.call());
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  // Action Methods
  void _createManualBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💾 Backup wird erstellt...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementiere manuelles Backup
  }

  void _showRestoreDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Backup-Wiederherstellung wird implementiert...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementiere Backup-Wiederherstellung
  }

  void _cleanTempFiles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧹 Temp-Dateien werden bereinigt...'),
        backgroundColor: Colors.red,
      ),
    );
    // TODO: Implementiere Temp-File-Cleanup
  }

  void _runSystemDiagnostics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔍 System-Diagnose wird gestartet...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementiere System-Diagnose
  }
}
