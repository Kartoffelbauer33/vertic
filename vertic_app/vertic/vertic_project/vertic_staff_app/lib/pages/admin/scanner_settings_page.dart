import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/background_scanner_service.dart';

class ScannerSettingsPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(bool hasChanges, [String? context])? onUnsavedChanges;

  const ScannerSettingsPage({
    super.key,
    required this.onBack,
    this.onUnsavedChanges,
  });

  @override
  State<ScannerSettingsPage> createState() => _ScannerSettingsPageState();
}

class _ScannerSettingsPageState extends State<ScannerSettingsPage> {
  final TextEditingController _manualTestController = TextEditingController();
  bool _hasUnsavedChanges = false;

  Map<String, bool>? _localScanTypes;
  bool? _localShowToast;
  bool? _localPlaySound;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scannerService = Provider.of<BackgroundScannerService>(
        context,
        listen: false,
      );
      setState(() {
        _localScanTypes = Map.from(scannerService.enabledScanTypes);
        _localShowToast = scannerService.showToastNotifications;
        _localPlaySound = scannerService.playSuccessSound;
      });
    });
  }

  void _setUnsavedChanges(bool hasChanges) {
    _hasUnsavedChanges = hasChanges;
    widget.onUnsavedChanges?.call(hasChanges, 'Scanner-Einstellungen');
  }

  void _saveSettings() {
    final scannerService = Provider.of<BackgroundScannerService>(
      context,
      listen: false,
    );

    if (_localScanTypes != null) {
      scannerService.updateScanTypeSettings(_localScanTypes!);
    }

    scannerService.updateNotificationSettings(
      showToast: _localShowToast,
      playSound: _localPlaySound,
    );

    _setUnsavedChanges(false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Scanner-Einstellungen gespeichert'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BackgroundScannerService>(
      builder: (context, scannerService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('🔧 Scanner-Einstellungen'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (_hasUnsavedChanges) {
                  _showUnsavedChangesDialog();
                } else {
                  widget.onBack();
                }
              },
            ),
            actions: [
              if (_hasUnsavedChanges)
                TextButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Speichern',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(scannerService),
                const SizedBox(height: 16),
                _buildComPortSection(scannerService),
                const SizedBox(height: 16),
                _buildScanTypesSection(scannerService),
                const SizedBox(height: 16),
                _buildNotificationSection(scannerService),
                const SizedBox(height: 16),
                _buildStatisticsSection(scannerService),
                const SizedBox(height: 16),
                _buildTestSection(scannerService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BackgroundScannerService scannerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  scannerService.isConnected ? Icons.check_circle : Icons.error,
                  color: scannerService.isConnected ? Colors.green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanner Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        scannerService.isConnected
                            ? 'Verbunden mit ${scannerService.selectedPort}'
                            : 'Nicht verbunden',
                        style: TextStyle(
                          color:
                              scannerService.isConnected
                                  ? Colors.green
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (scannerService.lastResult.isNotEmpty) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Letztes Ergebnis: ${scannerService.lastResult}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComPortSection(BackgroundScannerService scannerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔌 COM-Port Einstellungen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: scannerService.selectedPort,
                    decoration: const InputDecoration(
                      labelText: 'COM-Port',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        scannerService.availablePorts.map((port) {
                          return DropdownMenuItem(
                            value: port,
                            child: Text(port),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        scannerService.connectToPort(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    scannerService.refreshPorts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ports aktualisiert')),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Ports aktualisieren',
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        scannerService.selectedPort != null &&
                                !scannerService.isConnected
                            ? () => scannerService.connectToPort(
                              scannerService.selectedPort!,
                            )
                            : null,
                    icon: const Icon(Icons.link),
                    label: const Text('Verbinden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        scannerService.isConnected
                            ? scannerService.disconnectFromPort
                            : null,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Trennen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              'Baudrate: ${scannerService.baudRate} (Auto-Detection)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanTypesSection(BackgroundScannerService scannerService) {
    if (_localScanTypes == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Scan-Typen Konfiguration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            ..._localScanTypes!.entries.map((entry) {
              final scanType = entry.key;
              final isEnabled = entry.value;
              final displayName = _getScanTypeDisplayName(scanType);
              final description = _getScanTypeDescription(scanType);

              return CheckboxListTile(
                title: Text(displayName),
                subtitle: Text(description),
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    _localScanTypes![scanType] = value ?? false;
                    _setUnsavedChanges(true);
                  });
                },
                secondary: Icon(_getScanTypeIcon(scanType)),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(BackgroundScannerService scannerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔔 Benachrichtigungen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Toast-Benachrichtigungen'),
              subtitle: const Text('Popup-Meldungen bei Scan-Ergebnissen'),
              value: _localShowToast ?? scannerService.showToastNotifications,
              onChanged: (value) {
                setState(() {
                  _localShowToast = value;
                  _setUnsavedChanges(true);
                });
              },
              secondary: const Icon(Icons.notifications),
            ),

            SwitchListTile(
              title: const Text('Erfolgs-Sound'),
              subtitle: const Text('Audio-Feedback bei erfolgreichen Scans'),
              value: _localPlaySound ?? scannerService.playSuccessSound,
              onChanged: (value) {
                setState(() {
                  _localPlaySound = value;
                  _setUnsavedChanges(true);
                });
              },
              secondary: const Icon(Icons.volume_up),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BackgroundScannerService scannerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Scanner-Statistiken (Heute)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Gesamt-Scans',
                    '${scannerService.totalScansToday}',
                    Icons.qr_code_scanner,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Erfolgreich',
                    '${scannerService.successfulScansToday}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(BackgroundScannerService scannerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 Scanner-Test',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _manualTestController,
              decoration: const InputDecoration(
                labelText: 'Test-Code eingeben',
                hintText: 'QR-Code oder Ticket-ID zum Testen',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    scannerService.isProcessing
                        ? null
                        : () {
                          final code = _manualTestController.text.trim();
                          if (code.isNotEmpty) {
                            scannerService.manualScanInput(code);
                            _manualTestController.clear();
                          }
                        },
                icon:
                    scannerService.isProcessing
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.play_arrow),
                label: Text(
                  scannerService.isProcessing
                      ? 'Verarbeite...'
                      : 'Test ausführen',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getScanTypeDisplayName(String scanType) {
    switch (scanType) {
      case 'vertic_tickets':
        return 'Vertic Tickets';
      case 'fitpass':
        return 'Fitpass';
      case 'friction':
        return 'Friction';
      case 'manual_entry':
        return 'Manuelle Eingabe';
      case 'external_qr':
        return 'Externe QR-Codes';
      default:
        return scanType;
    }
  }

  String _getScanTypeDescription(String scanType) {
    switch (scanType) {
      case 'vertic_tickets':
        return 'Vertic-eigene Tickets und QR-Codes';
      case 'fitpass':
        return 'Fitpass-Mitgliedschaften und Zugänge';
      case 'friction':
        return 'Friction-Kletterkarten und Partner-Zugänge';
      case 'manual_entry':
        return 'Codes manuell über Tastatur eingeben';
      case 'external_qr':
        return 'Allgemeine externe QR-Codes';
      default:
        return 'Unbekannter Scan-Typ';
    }
  }

  IconData _getScanTypeIcon(String scanType) {
    switch (scanType) {
      case 'vertic_tickets':
        return Icons.confirmation_number;
      case 'fitpass':
        return Icons.fitness_center;
      case 'friction':
        return Icons.terrain;
      case 'manual_entry':
        return Icons.keyboard;
      case 'external_qr':
        return Icons.qr_code;
      default:
        return Icons.help;
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ungespeicherte Änderungen'),
            content: const Text(
              'Sie haben ungespeicherte Scanner-Einstellungen. Möchten Sie diese verwerfen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onBack();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Verwerfen'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _manualTestController.dispose();
    super.dispose();
  }
}
