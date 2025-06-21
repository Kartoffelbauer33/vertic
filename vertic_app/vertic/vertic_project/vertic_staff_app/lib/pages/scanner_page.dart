import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import 'dart:convert';
import 'serial_scanner.dart';

enum ScannerType {
  comPort,
  manualEntry,
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isProcessing = false;
  String _lastResult = '';
  bool _success = false;
  String _scannerMessage = 'Bereit für COM-Port Eingabe';

  // Aktuell aktiver Scanner-Typ
  ScannerType _currentScannerType = ScannerType.manualEntry;

  // COM-Port Scanner
  SerialScanner? _serialScanner;
  List<String> _availablePorts = [];
  String? _selectedPort;

  @override
  void initState() {
    super.initState();

    // Initialisiere Serial Scanner
    _serialScanner = SerialScanner(onDataReceived: _handleSerialData);
    _refreshPorts();
  }

  void _refreshPorts() {
    if (_serialScanner != null) {
      final ports = _serialScanner!.getAvailablePorts();
      setState(() {
        _availablePorts = ports;
        if (_availablePorts.isNotEmpty && _selectedPort == null) {
          _selectedPort = _availablePorts.first;
        }
      });
    }
  }

  void _connectToComPort() {
    if (_serialScanner != null && _selectedPort != null) {
      setState(() {
        _scannerMessage = 'Verbinde mit Scanner...';
        _isProcessing = true;
      });

      // Auto-Verbindung mit verschiedenen Baudraten versuchen
      _serialScanner!
          .autoConnectWithBaudRateDetection(_selectedPort!)
          .then((success) {
        setState(() {
          _isProcessing = false;
          if (success) {
            _currentScannerType = ScannerType.comPort;
            _scannerMessage = 'Bereit für COM-Port Eingabe';
            _lastResult = '';
            _success = false;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Verbindung zum COM-Port fehlgeschlagen. Versuchen Sie es mit einem anderen Port.')),
            );
          }
        });
      });
    }
  }

  void _disconnectFromComPort() {
    if (_serialScanner != null) {
      _serialScanner!.disconnect();
      setState(() {
        _currentScannerType = ScannerType.manualEntry;
        _scannerMessage = 'Kein Scanner verbunden';
        _lastResult = '';
        _success = false;
      });
    }
  }

  // Callback für Daten vom seriellen Scanner
  void _handleSerialData(String data) {
    if (_isProcessing) return;
    _processScannedResult(data);
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Code manuell eingeben'),
          content: TextField(
            controller: _manualCodeController,
            decoration: const InputDecoration(
              hintText: 'Code eingeben',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_manualCodeController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  _processScannedResult(_manualCodeController.text);
                  _manualCodeController.clear();
                }
              },
              child: const Text('Bestätigen'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _serialScanner?.disconnect();
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Scanner'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Manuelle Eingabe
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: _showManualEntryDialog,
            tooltip: 'Code manuell eingeben',
          ),

          // COM-Port Konfiguration
          IconButton(
            icon: Icon(
              _currentScannerType == ScannerType.comPort
                  ? Icons.usb_off
                  : Icons.usb,
              color: _currentScannerType == ScannerType.comPort
                  ? Colors.green
                  : null,
            ),
            onPressed: () {
              if (_currentScannerType == ScannerType.comPort) {
                _disconnectFromComPort();
              } else {
                _showComPortDialog();
              }
            },
            tooltip: _currentScannerType == ScannerType.comPort
                ? 'COM-Port trennen'
                : 'COM-Port verbinden',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status-Bereich
          Expanded(
            flex: 5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Statusanzeige
                  Icon(
                    _currentScannerType == ScannerType.comPort
                        ? Icons.usb
                        : Icons.keyboard,
                    size: 64,
                    color: _currentScannerType == ScannerType.comPort
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _currentScannerType == ScannerType.comPort
                        ? 'COM-Port Scanner aktiv\nPort: ${_selectedPort ?? "unbekannt"}'
                        : 'Kein Scanner verbunden\nVerbinden Sie einen COM-Port Scanner oder nutzen Sie die manuelle Eingabe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: _currentScannerType == ScannerType.comPort
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _scannerMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ergebnis-Anzeige
          Container(
            color: _success
                ? Colors.green.shade100
                : (_lastResult.isNotEmpty
                    ? Colors.red.shade100
                    : Colors.grey.shade100),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              children: [
                Icon(
                  _success
                      ? Icons.check_circle
                      : (_lastResult.isNotEmpty
                          ? Icons.error
                          : Icons.info_outline),
                  color: _success
                      ? Colors.green
                      : (_lastResult.isNotEmpty ? Colors.red : Colors.grey),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _lastResult.isEmpty ? 'Warte auf Scan...' : _lastResult,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _success
                        ? Colors.green.shade800
                        : (_lastResult.isNotEmpty
                            ? Colors.red.shade800
                            : Colors.grey.shade800),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _resetScanner,
                  child: const Text('Neuer Scan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processScannedResult(String qrData) async {
    setState(() {
      _isProcessing = true;
      _scannerMessage = 'Verarbeite Ticket...';
    });

    try {
      // QR-Code-Daten analysieren und Ticket-ID extrahieren
      final ticketId = _extractTicketId(qrData);

      if (ticketId == null) {
        setState(() {
          _success = false;
          _lastResult =
              'Ungültiger QR-Code oder beschädigte Daten.\nBitte erneut scannen.';
        });
        return;
      }

      // Auf den Server-Client zugreifen
      final client = Provider.of<Client>(context, listen: false);

      // Server-Aufruf zur Ticket-Validierung
      // TODO: facilityId und staffId dynamisch setzen, sobald Login und Facility-Auswahl implementiert sind
      final bool validationResult =
          await client.ticket.validateTicket(ticketId, 1, 1); // <-- Dummy-IDs!

      // Ergebnis anzeigen
      setState(() {
        _success = validationResult;
        _lastResult = validationResult
            ? 'Ticket gültig!\nTicket-ID: $ticketId'
            : 'Ticket ungültig oder bereits verwendet!\nTicket-ID: $ticketId';
      });
    } catch (e) {
      setState(() {
        _success = false;
        _lastResult = 'Fehler: $e';
      });
    }

    setState(() {
      _isProcessing = false;
      _scannerMessage = _currentScannerType == ScannerType.comPort
          ? 'Bereit für COM-Port Eingabe'
          : 'Kein Scanner verbunden';
    });
  }

  void _resetScanner() {
    setState(() {
      _lastResult = '';
      _success = false;
    });
  }

  void _showComPortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('COM-Port Scanner verbinden'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wählen Sie einen COM-Port:'),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: _selectedPort,
                  isExpanded: true,
                  hint: const Text('COM-Port auswählen'),
                  items: _availablePorts.map((String port) {
                    return DropdownMenuItem<String>(
                      value: port,
                      child: Text(port),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPort = newValue;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _refreshPorts();
                    });
                  },
                  child: const Text('Ports aktualisieren'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: _selectedPort == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _connectToComPort();
                      },
                child: const Text('Verbinden'),
              ),
            ],
          );
        });
      },
    );
  }

  // Zeigt einen Dialog zur manuellen Eingabe der Ticket-ID an
  void _showManualTicketIdDialog() {
    final ticketIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR-Code konnte nicht gelesen werden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bitte geben Sie die Ticket-ID manuell ein:'),
              const SizedBox(height: 16),
              TextField(
                controller: ticketIdController,
                decoration: const InputDecoration(
                  labelText: 'Ticket-ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isProcessing = false;
                  _success = false;
                  _lastResult = 'Vorgang abgebrochen';
                });
              },
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ticketIdText = ticketIdController.text.trim();
                final ticketId = int.tryParse(ticketIdText);

                if (ticketId != null) {
                  Navigator.of(context).pop();

                  setState(() {
                    _isProcessing = true;
                    _scannerMessage = 'Verarbeite Ticket...';
                  });

                  try {
                    final client = Provider.of<Client>(context, listen: false);
                    // TODO: facilityId und staffId dynamisch setzen, sobald Login und Facility-Auswahl implementiert sind
                    final bool validationResult = await client.ticket
                        .validateTicket(ticketId, 1, 1); // <-- Dummy-IDs!

                    setState(() {
                      _success = validationResult;
                      _lastResult = validationResult
                          ? 'Ticket gültig!\nTicket-ID: $ticketId'
                          : 'Ticket ungültig oder bereits verwendet!\nTicket-ID: $ticketId';
                    });
                  } catch (e) {
                    setState(() {
                      _success = false;
                      _lastResult = 'Fehler: $e';
                    });
                  }

                  setState(() {
                    _isProcessing = false;
                    _scannerMessage = _currentScannerType == ScannerType.comPort
                        ? 'Bereit für COM-Port Eingabe'
                        : 'Kein Scanner verbunden';
                  });
                }
              },
              child: const Text('Bestätigen'),
            ),
          ],
        );
      },
    );
  }

  // Extrahiert die Ticket-ID aus dem QR-Code
  int? _extractTicketId(String qrData) {
    try {
      debugPrint('Gescannter QR-Code: $qrData'); // Debug-Ausgabe

      // Bei Base64-codierten QR-Codes mit JSON und Signatur
      if (qrData.contains('.')) {
        final parts = qrData.split('.');
        debugPrint('Aufgeteilte Teile: ${parts.length}'); // Debug-Ausgabe

        if (parts.length == 2) {
          try {
            // Base64-decodierte Payload-Daten parsen
            final jsonData = utf8.decode(base64Url.decode(parts[0]));
            debugPrint('Decodierte JSON-Daten: $jsonData'); // Debug-Ausgabe

            final Map<String, dynamic> payload = jsonDecode(jsonData);
            debugPrint('Payload: $payload'); // Debug-Ausgabe

            // ID aus dem Payload extrahieren
            if (payload.containsKey('id')) {
              return payload['id'] as int;
            }
          } catch (e) {
            debugPrint(
                'Fehler beim Decodieren: $e'); // Spezifische Fehlerausgabe
            return null;
          }
        }
      } else {
        // Wenn der QR-Code kein Punkt enthält, prüfen ob es sich um einen abgeschnittenen Base64-String handelt
        debugPrint(
            'QR-Code enthält keinen Punkt, versuche Base64 zu dekodieren');
        try {
          // Versuchen, den String als Base64 zu decodieren
          final decodedData = utf8.decode(base64Url.decode(qrData));
          debugPrint('Decodierte Daten (ohne Punkt): $decodedData');

          // Prüfen, ob es ein JSON-Objekt ist
          final Map<String, dynamic> payload = jsonDecode(decodedData);
          debugPrint('Payload (ohne Signatur): $payload');

          // WARNUNG: Dies ist unsicher, da die Signatur fehlt, aber besser als manuelle Eingabe
          debugPrint(
              'WARNUNG: Keine Signatur vorhanden - unsichere Validierung!');
          if (payload.containsKey('id')) {
            return payload['id'] as int;
          }
        } catch (e) {
          debugPrint('Fehler bei Base64-Dekodierung: $e');
        }
      }

      debugPrint('Keine ID konnte extrahiert werden');
      return null;
    } catch (e) {
      debugPrint('Fehler bei der QR-Code-Analyse: $e');
      return null;
    }
  }
}
