import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialScanner {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _subscription;
  final Function(String) onDataReceived;
  bool _isConnected = false;
  String _currentPortName = '';

  // Puffer für eingehende Daten
  StringBuffer _dataBuffer = StringBuffer();
  Timer? _bufferTimer;

  // Cooldown nach erfolgreicher Verarbeitung
  bool _isInCooldown = false;
  Timer? _cooldownTimer;
  String? _lastProcessedCode;

  // Zeitstempel der letzten Verarbeitung
  DateTime? _lastProcessingTime;

  // Konstanten für die Pufferung
  static const Duration _bufferTimeout = Duration(milliseconds: 100);
  static const Duration _cooldownDuration = Duration(seconds: 1);

  // Mögliche Baudraten für Auto-Detect
  static const List<int> _possibleBaudRates = [
    9600,
    115200,
    38400,
    57600,
    19200,
  ];

  SerialScanner({required this.onDataReceived});

  /// Listet alle verfügbaren seriellen Ports auf
  List<String> getAvailablePorts() {
    try {
      // Stellt sicher, dass alle bestehenden Verbindungen geschlossen sind
      disconnect();

      final ports = SerialPort.availablePorts;
      debugPrint('Verfügbare Ports: $ports');
      return ports;
    } catch (e) {
      debugPrint('Fehler beim Auflisten der seriellen Ports: $e');
      return [];
    }
  }

  /// Verbindet mit dem angegebenen COM-Port
  bool connect(String portName, {int baudRate = 9600}) {
    try {
      debugPrint('Verbinde mit Port: $portName, Baudrate: $baudRate');

      // Wenn bereits verbunden, erst trennen
      if (_isConnected && _port != null) {
        debugPrint('Bestehende Verbindung wird getrennt...');
        disconnect();
      }

      // Kurze Pause, um sicherzustellen, dass der Port freigegeben ist
      Future.delayed(const Duration(milliseconds: 500), () {});

      // Neuer Versuch, den Port zu öffnen
      _port = SerialPort(portName);

      debugPrint('Port-Instanz erstellt, versuche zu öffnen...');
      if (!_port!.openReadWrite()) {
        final error = SerialPort.lastError;
        debugPrint('Fehler beim Öffnen des Ports: $error');

        // Versuchen, den Port zu schließen und freizugeben
        _cleanupPort();

        return false;
      }

      debugPrint('Port erfolgreich geöffnet, konfiguriere...');
      try {
        _port!.config = SerialPortConfig()
          ..baudRate = baudRate
          ..bits = 8
          ..stopBits = 1
          ..parity = SerialPortParity.none
          ..setFlowControl(SerialPortFlowControl.none);
        debugPrint('Port konfiguriert.');
      } catch (e) {
        debugPrint('Fehler bei der Portkonfiguration: $e');
        _cleanupPort();
        return false;
      }

      try {
        debugPrint('Reader wird initialisiert...');
        _reader = SerialPortReader(_port!);
        _subscription = _reader!.stream.listen(_onData);
        debugPrint('Reader initialisiert und Listener eingerichtet.');
      } catch (e) {
        debugPrint('Fehler beim Einrichten des Readers: $e');
        _cleanupPort();
        return false;
      }

      _isConnected = true;
      _currentPortName = portName;

      // Puffer zurücksetzen
      _resetBuffer();
      _isInCooldown = false;
      _lastProcessedCode = null;

      debugPrint('Verbunden mit COM-Port: $portName');
      return true;
    } catch (e) {
      debugPrint('Fehler beim Verbinden mit dem seriellen Port: $e');
      _cleanupPort();
      return false;
    }
  }

  /// Versucht, mit dem Scanner mit verschiedenen Baudraten zu verbinden
  Future<bool> autoConnectWithBaudRateDetection(String portName) async {
    debugPrint('Versuche Auto-Connect mit verschiedenen Baudraten...');

    for (final baudRate in _possibleBaudRates) {
      debugPrint('Versuche Baudrate: $baudRate');
      if (connect(portName, baudRate: baudRate)) {
        debugPrint('Verbindung erfolgreich mit Baudrate: $baudRate');
        return true;
      }

      // Kurze Pause zwischen den Versuchen
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('Konnte mit keiner Baudrate verbinden.');
    return false;
  }

  /// Säubert Port-Ressourcen bei Fehlern
  void _cleanupPort() {
    try {
      _subscription?.cancel();
      _subscription = null;
      _reader = null;

      if (_port != null) {
        try {
          if (_port!.isOpen) {
            _port!.close();
          }
        } catch (e) {
          debugPrint('Fehler beim Schließen des Ports: $e');
        }

        try {
          _port!.dispose();
        } catch (e) {
          debugPrint('Fehler beim Dispose des Ports: $e');
        }

        _port = null;
      }

      _isConnected = false;
    } catch (e) {
      debugPrint('Fehler beim Cleanup: $e');
    }
  }

  /// Trennt die Verbindung zum aktuellen COM-Port
  void disconnect() {
    debugPrint('Trenne Verbindung...');
    try {
      if (_subscription != null) {
        _subscription!.cancel();
        _subscription = null;
      }

      _reader = null;

      if (_port != null) {
        try {
          if (_port!.isOpen) {
            _port!.close();
          }
          _port!.dispose();
        } catch (e) {
          debugPrint('Fehler beim Schließen/Dispose des Ports: $e');
        }
        _port = null;
      }

      _isConnected = false;
      _resetBuffer();
      _bufferTimer?.cancel();
      _bufferTimer = null;
      _cooldownTimer?.cancel();
      _cooldownTimer = null;
      _isInCooldown = false;

      debugPrint('Verbindung zu COM-Port getrennt');
    } catch (e) {
      debugPrint('Fehler beim Trennen der seriellen Verbindung: $e');
    }
  }

  /// Handhabt eingehende Daten vom seriellen Port
  void _onData(Uint8List data) {
    try {
      // Wenn wir im Cooldown sind, ignorieren wir die Daten
      if (_isInCooldown) {
        return;
      }

      // Konvertiere Byte-Array in String (bei einem Barcode-Scanner meist ASCII)
      String scannedData = String.fromCharCodes(data);

      // Zum Puffer hinzufügen
      _dataBuffer.write(scannedData);

      // Timer zurücksetzen - wir warten nach jedem eingehenden Datenpaket
      _resetBufferTimer();

      // Debug-Ausgabe
      debugPrint('Daten empfangen: $scannedData');
      debugPrint('Aktueller Puffer: ${_dataBuffer.toString()}');

      // Prüfen, ob der Scan möglicherweise abgeschlossen ist - einige Scanner senden CR oder LF am Ende
      if (scannedData.contains('\r') || scannedData.contains('\n')) {
        _processBufferedData();
      }
    } catch (e) {
      debugPrint('Fehler beim Verarbeiten der seriellen Daten: $e');
    }
  }

  /// Verarbeitet die gepufferten Daten, wenn sie vollständig sind
  void _processBufferedData() {
    // Timer anhalten
    _bufferTimer?.cancel();

    // Daten bereinigen
    String completeData = _dataBuffer.toString().trim();

    if (completeData.isNotEmpty) {
      // Prüfen ob es der zuletzt verarbeitete Code ist, um Duplikate zu vermeiden
      if (_lastProcessedCode == completeData) {
        debugPrint('Ignoriere doppelten Scan des letzten QR-Codes');
        _resetBuffer();
        return;
      }

      // 🔧 FIX: Nur bei LANGEN Base64-Strings (>100 Zeichen) ohne Punkt warten
      // Normale Barcodes/QR-Codes (kurz) sofort verarbeiten
      if (!completeData.contains('.') && completeData.length > 100) {
        // Nur bei langen Codes prüfen, ob es ein abgeschnittener Base64-String ist
        if (_isBase64String(completeData)) {
          // Prüfen, ob genug Zeit seit der letzten Verarbeitung vergangen ist
          final now = DateTime.now();
          if (_lastProcessingTime != null) {
            final timeSinceLastProcessing = now.difference(
              _lastProcessingTime!,
            );
            if (timeSinceLastProcessing < const Duration(milliseconds: 300)) {
              debugPrint(
                'Zu kurze Zeit seit letzter Verarbeitung, warte auf vollständige Daten...',
              );
              // Nicht verarbeiten, sondern auf weitere Daten warten
              _resetBufferTimer();
              return;
            }
          }

          debugPrint(
            'Möglicher abgeschnittener Base64-String erkannt. Warte auf weitere Daten...',
          );
          // Nicht verarbeiten, sondern auf weitere Daten warten
          _resetBufferTimer();
          return;
        }
      }

      debugPrint('Verarbeite vollständigen Scan: $completeData');

      // Cooldown aktivieren, um wiederholte Scans zu vermeiden
      _activateCooldown();

      // Zeitstempel aktualisieren
      _lastProcessingTime = DateTime.now();

      // Code speichern, um Duplikate zu erkennen
      _lastProcessedCode = completeData;

      onDataReceived(completeData);
      _resetBuffer();
    }
  }

  /// Aktiviert einen Cooldown nach erfolgreicher Verarbeitung
  void _activateCooldown() {
    _isInCooldown = true;
    debugPrint('Cooldown aktiviert für ${_cooldownDuration.inMilliseconds}ms');
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(_cooldownDuration, () {
      _isInCooldown = false;
      debugPrint('Cooldown beendet, Scanner bereit');
    });
  }

  /// Prüft, ob ein String Base64-kodiert aussieht
  bool _isBase64String(String str) {
    // 🔧 FIX: Strengere Base64-Erkennung
    // - Muss mindestens 20 Zeichen lang sein
    // - Muss eine Mischung aus Groß-/Kleinbuchstaben enthalten
    // - Normale Barcodes (nur Zahlen) werden nicht als Base64 erkannt

    if (str.length < 20) return false;

    // Prüfe ob nur Zahlen (normale Barcodes) → KEIN Base64
    if (RegExp(r'^\d+$').hasMatch(str)) return false;

    // Prüfe ob Base64-Pattern UND mindestens ein Buchstabe
    final hasBase64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,3}$').hasMatch(str);
    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(str);

    return hasBase64Pattern && hasLetters;
  }

  /// Setzt den Puffer zurück
  void _resetBuffer() {
    _dataBuffer.clear();
  }

  /// Setzt den Timer für die Pufferung zurück
  void _resetBufferTimer() {
    _bufferTimer?.cancel();
    _bufferTimer = Timer(_bufferTimeout, () {
      // Wenn der Timer abläuft, nehmen wir an, dass der Scan abgeschlossen ist
      if (_dataBuffer.isNotEmpty) {
        _processBufferedData();
      }
    });
  }

  /// Überprüft, ob aktuell eine Verbindung besteht
  bool get isConnected => _isConnected;

  /// Gibt den Namen des aktuell verbundenen Ports zurück
  String get currentPort => _currentPortName;
}



