import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

class PrinterSettingsPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(bool, String?) onUnsavedChanges;

  const PrinterSettingsPage({
    super.key,
    required this.onBack,
    required this.onUnsavedChanges,
  });

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  List<PrinterConfiguration> _printerConfigs = [];
  List<String> _availableComPorts = [];
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  String? _errorMessage;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadPrinterConfigurations();
    _loadAvailableComPorts();
  }

  Future<void> _loadPrinterConfigurations() async {
    try {
      // Temporär deaktiviert - Methode existiert noch nicht im Backend
      setState(() {
        _isLoading = false;
      });
      // TODO: Implementiere getPrinterConfigurations im Backend
      // final configs = await client.printer.getPrinterConfigurations();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Fehler beim Laden der Drucker-Konfigurationen: $e')),
        );
      }
    }
  }

  Future<void> _loadAvailableComPorts() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final ports = await client.printer.getAvailableComPorts();

      setState(() {
        _availableComPorts = ports;
      });
    } catch (e) {
      debugPrint('Fehler beim Laden der COM-Ports: $e');
      setState(() {
        _availableComPorts = [
          'COM1',
          'COM2',
          'COM3',
          'COM4',
          'COM5',
          'COM6',
          'COM7',
          'COM8'
        ];
      });
    }
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
      widget.onUnsavedChanges(true, 'Drucker-Einstellungen');
    }
  }

  String _getConnectionSettingValue(String connectionSettingsJson, String key) {
    try {
      final Map<String, dynamic> settings = jsonDecode(connectionSettingsJson);
      final value = settings[key];
      return value?.toString() ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _testPrinterConnection(int configId) async {
    setState(() {
      _testResult = null;
      _isLoading = true;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);
      final result = await client.printer.testPrinterConnection(configId);

      setState(() {
        if (result.success) {
          _testResult = 'Verbindung erfolgreich: ${result.message}';
        } else {
          _testResult = 'Verbindungsfehler: ${result.error}';
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_testResult!),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _testResult = 'Fehler beim Test: $e';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_testResult!),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _printTestTicket(int configId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = Provider.of<Client>(context, listen: false);
      final result = await client.printer.printTestTicket(configId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? 'Test-Ticket gedruckt!'
              : 'Druckfehler: ${result.error}'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Drucken: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddPrinterDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddPrinterDialog(
        availableComPorts: _availableComPorts,
        onSave: (configMap) async {
          final client = Provider.of<Client>(context, listen: false);

          // Die savePrinterConfiguration Methode erwartet einzelne Parameter
          final success = await client.printer.savePrinterConfiguration(
            null, // configId (null für neue Konfiguration)
            configMap['facilityId'] as int?,
            configMap['printerName'] as String,
            configMap['printerType'] as String,
            configMap['connectionType'] as String,
            configMap['connectionSettings'] as Map<String, dynamic>,
            configMap['paperSize'] as String,
            configMap['isDefault'] as bool,
            configMap['isActive'] as bool,
          );

          if (success) {
            await _loadPrinterConfigurations();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Drucker-Konfiguration gespeichert'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fehler beim Speichern der Konfiguration'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drucker-Einstellungen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              _hasUnsavedChanges ? _showUnsavedChangesDialog : widget.onBack,
        ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPrinterConfigurations();
              _loadAvailableComPorts();
            },
            tooltip: 'Aktualisieren',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPrinterDialog,
            tooltip: 'Drucker hinzufügen',
          ),
        ],
      ),
      body: _isLoading && _printerConfigs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null && _printerConfigs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade600),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPrinterConfigurations,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Info-Header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.print, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drucker-Konfiguration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Konfigurieren Sie Bondrucker für das Ausdrucken von Tickets. '
                      'Unterstützt werden COM-Port, USB und Netzwerk-Verbindungen.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Drucker-Liste
        Expanded(
          child: _printerConfigs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.print_disabled,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Keine Drucker konfiguriert',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fügen Sie Ihren ersten Drucker hinzu',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddPrinterDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Drucker hinzufügen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _printerConfigs.length,
                  itemBuilder: (context, index) {
                    final config = _printerConfigs[index];
                    return _buildPrinterCard(config);
                  },
                ),
        ),

        // Test-Ergebnis anzeigen
        if (_testResult != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _testResult!.contains('erfolgreich')
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _testResult!.contains('erfolgreich')
                    ? Colors.green.shade200
                    : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _testResult!.contains('erfolgreich')
                      ? Icons.check_circle
                      : Icons.error,
                  color: _testResult!.contains('erfolgreich')
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_testResult!)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _testResult = null),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPrinterCard(PrinterConfiguration config) {
    final isDefault = config.isDefault;
    final isActive = config.isActive;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              isActive ? const Color(0xFF00897B) : Colors.grey.shade400,
          child: const Icon(Icons.print, color: Colors.white),
        ),
        title: Text(
          config.printerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${config.printerType} - ${config.connectionType}',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (isDefault)
              const Chip(
                label: Text('Standard'),
                backgroundColor: Colors.blue,
                labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                padding: EdgeInsets.zero,
              ),
            Icon(
              isActive ? Icons.check_circle : Icons.cancel,
              color: isActive ? Colors.green : Colors.red,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfigDetail('Drucker-Typ', config.printerType),
                _buildConfigDetail('Verbindungstyp', config.connectionType),
                _buildConfigDetail(
                    'COM-Port',
                    _getConnectionSettingValue(
                        config.connectionSettings, 'comPort')),
                _buildConfigDetail(
                    'Baud-Rate',
                    _getConnectionSettingValue(
                        config.connectionSettings, 'baudRate')),
                _buildConfigDetail('Papierformat', config.paperSize),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isActive
                          ? () => _testPrinterConnection(config.id!)
                          : null,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cable),
                      label: const Text('Test'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed:
                          isActive ? () => _printTestTicket(config.id!) : null,
                      icon: const Icon(Icons.print),
                      label: const Text('Testdruck'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text(
          'Sie haben ungespeicherte Änderungen an den Drucker-Einstellungen. '
          'Möchten Sie diese speichern bevor Sie fortfahren?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onUnsavedChanges(false, null);
              widget.onBack();
            },
            child: const Text('Verwerfen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Hier würde das Speichern stattfinden
              widget.onBack();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

class _AddPrinterDialog extends StatefulWidget {
  final List<String> availableComPorts;
  final Function(Map<String, dynamic>) onSave;

  const _AddPrinterDialog({
    required this.availableComPorts,
    required this.onSave,
  });

  @override
  State<_AddPrinterDialog> createState() => _AddPrinterDialogState();
}

class _AddPrinterDialogState extends State<_AddPrinterDialog> {
  final _formKey = GlobalKey<FormState>();

  String _printerName = '';
  String _printerType = 'thermal'; // ✅ Gültiger Wert
  String _connectionType = 'usb';
  String _ipAddress = '';
  int? _port = 9600; // ✅ Gültiger Baud-Rate Wert (statt 9100)
  String? _comPort;
  String? _usbPort;
  String _paperSize = 'thermal_80mm'; // ✅ Gültiger Wert
  bool _isDefault = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.availableComPorts.isNotEmpty) {
      _comPort = widget.availableComPorts.first;
    }
    // ✅ Sicherstellen, dass _port einen gültigen Wert hat
    _port ??= 9600; // Standard-Baud-Rate für COM-Port
  }

  Map<String, dynamic> _buildConnectionSettings() {
    switch (_connectionType) {
      case 'network':
        return {'ipAddress': _ipAddress, 'port': _port};
      case 'usb':
        return {'usbPort': _usbPort};
      case 'com_port': // ✅ Korrekt 'com_port' statt 'serial'
        return {'comPort': _comPort, 'baudRate': _port};
      default:
        return {};
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final config = {
        'printerName': _printerName,
        'printerType': _printerType,
        'connectionType': _connectionType,
        'connectionSettings': _buildConnectionSettings(),
        'paperSize': _paperSize,
        'isDefault': _isDefault,
        'isActive': _isActive,
        'facilityId': 1, //TODO:
      };

      widget.onSave(config);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Drucker hinzufügen'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _printerName,
                  decoration: const InputDecoration(
                    labelText: 'Druckername',
                    hintText: 'Z.B. Bondrucker Theke',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte geben Sie einen Namen ein';
                    }
                    return null;
                  },
                  onSaved: (value) => _printerName = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _printerType,
                  decoration: const InputDecoration(
                    labelText: 'Drucker-Typ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'thermal', child: Text('Bondrucker (Thermal)')),
                    DropdownMenuItem(
                        value: 'laser', child: Text('Laserdrucker')),
                    DropdownMenuItem(
                        value: 'inkjet', child: Text('Tintenstrahldrucker')),
                  ],
                  onChanged: (value) => setState(() => _printerType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _connectionType,
                  decoration: const InputDecoration(
                    labelText: 'Verbindungstyp',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'com_port', child: Text('COM-Port (Seriell)')),
                    DropdownMenuItem(value: 'usb', child: Text('USB')),
                    DropdownMenuItem(
                        value: 'network', child: Text('Netzwerk (IP)')),
                  ],
                  onChanged: (value) => setState(() {
                    _connectionType = value!;
                    // ✅ Port-Wert je nach Verbindungstyp anpassen
                    if (_connectionType == 'network') {
                      _port = 9100; // Standard für Netzwerk-Drucker
                    } else if (_connectionType == 'com_port') {
                      _port = 9600; // Standard für COM-Port/Baud-Rate
                    }
                  }),
                ),
                const SizedBox(height: 16),
                if (_connectionType == 'com_port') ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _comPort,
                          decoration: const InputDecoration(
                            labelText: 'COM-Port',
                            border: OutlineInputBorder(),
                          ),
                          items: widget.availableComPorts
                              .map((port) => DropdownMenuItem(
                                    value: port,
                                    child: Text(port),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _comPort = value!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _port,
                          decoration: const InputDecoration(
                            labelText: 'Baud-Rate',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 9600, child: Text('9600')),
                            DropdownMenuItem(
                                value: 19200, child: Text('19200')),
                            DropdownMenuItem(
                                value: 38400, child: Text('38400')),
                            DropdownMenuItem(
                                value: 57600, child: Text('57600')),
                            DropdownMenuItem(
                                value: 115200, child: Text('115200')),
                          ],
                          onChanged: (value) => setState(() => _port = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (_connectionType == 'network') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _ipAddress,
                          decoration: const InputDecoration(
                            labelText: 'IP-Adresse',
                            hintText: '192.168.1.100',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'IP-Adresse ist erforderlich';
                            }
                            return null;
                          },
                          onSaved: (value) => _ipAddress = value!,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _port?.toString() ?? '9100',
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '9100',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Port ist erforderlich';
                            }
                            final port = int.tryParse(value);
                            if (port == null || port < 1 || port > 65535) {
                              return 'Ungültiger Port (1-65535)';
                            }
                            return null;
                          },
                          onSaved: (value) => _port = int.parse(value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (_connectionType == 'usb') ...[
                  TextFormField(
                    initialValue: _usbPort,
                    decoration: const InputDecoration(
                      labelText: 'USB-Port',
                      hintText: 'Automatisch erkannt',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => _usbPort = value,
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<String>(
                  value: _paperSize,
                  decoration: const InputDecoration(
                    labelText: 'Papierformat',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'thermal_58mm', child: Text('58mm Thermorolle')),
                    DropdownMenuItem(
                        value: 'thermal_80mm', child: Text('80mm Thermorolle')),
                    DropdownMenuItem(value: 'a4', child: Text('A4')),
                  ],
                  onChanged: (value) => setState(() => _paperSize = value!),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Als Standard-Drucker festlegen'),
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                ),
                SwitchListTile(
                  title: const Text('Drucker aktivieren'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
