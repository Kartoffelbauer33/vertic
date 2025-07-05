import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_server_client/test_server_client.dart';
import '../pages/serial_scanner.dart';

/// **🔄 BACKGROUND SCANNER SERVICE**
///
/// Zentraler Scanner-Service der permanent im Hintergrund läuft:
/// - Kombiniert COM-Port und manuelle Eingabe
/// - Automatische QR-Code-Erkennung (Vertic, Fitpass, Friction)
/// - Persistente Scanner-Einstellungen
/// - Toast-Notifications bei erfolgreichen Scans
/// - Funktioniert in allen App-Tabs
class BackgroundScannerService extends ChangeNotifier {
  // **CORE DEPENDENCIES**
  final Client _client;
  BuildContext? _context;

  // **SCANNER HARDWARE**
  SerialScanner? _serialScanner;
  bool _isConnected = false;
  String? _selectedPort;
  List<String> _availablePorts = [];
  int _baudRate = 9600;

  // **SCANNER STATE**
  bool _isScanning = true; // Background Scanner läuft permanent
  bool _isProcessing = false;
  String _lastResult = '';
  DateTime? _lastScanTime;

  // **SCAN TYPES CONFIGURATION**
  Map<String, bool> _enabledScanTypes = {
    'vertic_tickets': true,
    'fitpass': true,
    'friction': true,
    'manual_entry': true,
    'external_qr': true,
  };

  // **SCANNER STATISTICS**
  int _totalScansToday = 0;
  int _successfulScansToday = 0;
  DateTime? _lastResetDate;

  // **NOTIFICATION SETTINGS**
  bool _showToastNotifications = true;
  bool _playSuccessSound = true;

  BackgroundScannerService(this._client) {
    _initializeScanner();
    _loadSettings();
  }

  // **GETTERS**
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  bool get isProcessing => _isProcessing;
  String get lastResult => _lastResult;
  String? get selectedPort => _selectedPort;
  List<String> get availablePorts => _availablePorts;
  int get baudRate => _baudRate;
  Map<String, bool> get enabledScanTypes => Map.from(_enabledScanTypes);
  int get totalScansToday => _totalScansToday;
  int get successfulScansToday => _successfulScansToday;
  bool get showToastNotifications => _showToastNotifications;
  bool get playSuccessSound => _playSuccessSound;

  /// **🔧 SCANNER INITIALIZATION**
  void _initializeScanner() {
    debugPrint('🔄 Background Scanner Service wird initialisiert...');

    // Serial Scanner mit Data Callback erstellen
    _serialScanner = SerialScanner(onDataReceived: _handleScanData);

    // Verfügbare Ports laden
    refreshPorts();

    // Statistiken zurücksetzen falls neuer Tag
    _resetDailyStatsIfNeeded();

    debugPrint('✅ Background Scanner Service initialisiert');
  }

  /// **📱 CONTEXT REGISTRATION (für Toast-Notifications)**
  void registerContext(BuildContext context) {
    _context = context;
    debugPrint('📱 Background Scanner Context registriert');
  }

  /// **🔍 PORT MANAGEMENT**
  void refreshPorts() {
    if (_serialScanner != null) {
      final ports = _serialScanner!.getAvailablePorts();
      _availablePorts = ports;

      // Auto-Select ersten Port falls keiner gewählt
      if (_availablePorts.isNotEmpty && _selectedPort == null) {
        _selectedPort = _availablePorts.first;
      }

      debugPrint('🔌 Verfügbare Ports: $_availablePorts');
      notifyListeners();
    }
  }

  /// **🔗 COM-PORT CONNECTION**
  Future<bool> connectToPort(String portName, {int? customBaudRate}) async {
    if (_serialScanner == null) return false;

    _selectedPort = portName;
    if (customBaudRate != null) _baudRate = customBaudRate;

    debugPrint('🔗 Verbinde mit Port: $portName, Baudrate: $_baudRate');

    // Auto-Connect mit Baudrate Detection
    final success = await _serialScanner!.autoConnectWithBaudRateDetection(
      portName,
    );

    _isConnected = success;

    if (success) {
      debugPrint('✅ COM-Port Verbindung erfolgreich: $portName');
      _showToastMessage('Scanner verbunden: $portName', isSuccess: true);
      await _saveSettings();
    } else {
      debugPrint('❌ COM-Port Verbindung fehlgeschlagen: $portName');
      _showToastMessage('Scanner Verbindung fehlgeschlagen', isSuccess: false);
    }

    notifyListeners();
    return success;
  }

  /// **🔌 DISCONNECT COM-PORT**
  void disconnectFromPort() {
    if (_serialScanner != null) {
      _serialScanner!.disconnect();
      _isConnected = false;
      debugPrint('🔌 COM-Port getrennt');
      _showToastMessage('Scanner getrennt', isSuccess: false);
      notifyListeners();
    }
  }

  /// **⚙️ SCANNER SETTINGS**
  void updateScanTypeSettings(Map<String, bool> newSettings) {
    _enabledScanTypes = Map.from(newSettings);
    _saveSettings();
    notifyListeners();
    debugPrint('⚙️ Scan-Type Settings aktualisiert: $_enabledScanTypes');
  }

  void updateNotificationSettings({bool? showToast, bool? playSound}) {
    if (showToast != null) _showToastNotifications = showToast;
    if (playSound != null) _playSuccessSound = playSound;
    _saveSettings();
    notifyListeners();
    debugPrint('🔔 Notification Settings aktualisiert');
  }

  /// **📊 STATISTICS**
  void _resetDailyStatsIfNeeded() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      _totalScansToday = 0;
      _successfulScansToday = 0;
      _lastResetDate = today;
      debugPrint('📊 Tagesstatistiken zurückgesetzt');
    }
  }

  /// **🔄 SCAN DATA PROCESSING**
  void _handleScanData(String rawData) {
    if (_isProcessing) return;

    final cleanedData = rawData.trim();
    if (cleanedData.isEmpty) return;

    debugPrint('🔍 Scanner-Daten empfangen: $cleanedData');
    _processScannedCode(cleanedData);
  }

  /// **✋ MANUAL SCAN INPUT**
  Future<void> manualScanInput(String code) async {
    if (!_enabledScanTypes['manual_entry']!) {
      _showToastMessage('Manuelle Eingabe ist deaktiviert', isSuccess: false);
      return;
    }

    debugPrint('✋ Manuelle Eingabe: $code');
    await _processScannedCode(code);
  }

  /// **🎯 CORE SCAN PROCESSING**
  Future<void> _processScannedCode(String code) async {
    if (_isProcessing) return;

    _isProcessing = true;
    _totalScansToday++;
    notifyListeners();

    try {
      debugPrint('🎯 Verarbeite gescannten Code: $code');

      // Code-Typ erkennen
      final scanType = _detectScanType(code);

      if (!_enabledScanTypes[scanType]!) {
        _showToastMessage('$scanType ist deaktiviert', isSuccess: false);
        return;
      }

      // An entsprechenden Endpoint weiterleiten
      final result = await _processScanByType(code, scanType);

      if (result.success) {
        _successfulScansToday++;
        _lastResult = 'Erfolg: ${result.message}';
        _lastScanTime = DateTime.now();

        if (_showToastNotifications) {
          _showToastMessage('✅ ${result.message}', isSuccess: true);
        }

        debugPrint('✅ Scan erfolgreich: ${result.message}');
      } else {
        _lastResult = 'Fehler: ${result.message}';
        _showToastMessage('❌ ${result.message}', isSuccess: false);
        debugPrint('❌ Scan fehlgeschlagen: ${result.message}');
      }
    } catch (e) {
      _lastResult = 'Fehler: $e';
      _showToastMessage('❌ Scanner-Fehler: $e', isSuccess: false);
      debugPrint('❌ Scanner-Fehler: $e');
    } finally {
      _isProcessing = false;
      await _saveSettings();
      notifyListeners();
    }
  }

  /// **🔍 SCAN TYPE DETECTION**
  String _detectScanType(String code) {
    try {
      // JSON QR-Code prüfen
      final json = jsonDecode(code);

      if (json.containsKey('vertic_ticket_id')) {
        return 'vertic_tickets';
      } else if (json.containsKey('fitpass_id')) {
        return 'fitpass';
      } else if (json.containsKey('friction_id')) {
        return 'friction';
      }
    } catch (_) {
      // Kein JSON - könnte externe QR-Code sein
    }

    // External QR-Codes oder IDs
    if (code.startsWith('VT-') || code.startsWith('vertic://')) {
      return 'vertic_tickets';
    } else if (code.startsWith('FP-') || code.contains('fitpass')) {
      return 'fitpass';
    } else if (code.startsWith('FR-') || code.contains('friction')) {
      return 'friction';
    }

    // Default: External QR
    return 'external_qr';
  }

  /// **📊 UPDATE DAILY STATISTICS**
  void _updateDailyStats({required bool success}) {
    _totalScansToday++;
    if (success) {
      _successfulScansToday++;
    }
    notifyListeners();
  }

  /// **🎯 SCAN PROCESSING BY TYPE**
  Future<ScanResult> _processScanByType(String code, String scanType) async {
    try {
      switch (scanType) {
        case 'vertic_tickets':
          return await _processVerticTicket(code);
        case 'fitpass':
          return await _processFitpassTicket(code);
        case 'friction':
          return await _processFrictionTicket(code);
        case 'external_qr':
        case 'manual_entry':
          return await _processGenericQR(code);
        default:
          return ScanResult(
            success: false,
            message: 'Unbekannter Scan-Typ: $scanType',
          );
      }
    } catch (e) {
      return ScanResult(success: false, message: 'Verarbeitungsfehler: $e');
    }
  }

  /// **🎫 VERTIC TICKET SCANNEN**
  Future<ScanResult> _processVerticTicket(String code) async {
    debugPrint('🎫 Scanne Vertic Ticket: $code');

    try {
      // ✅ KORREKT: identity.validateIdentityQrCode (nicht ticket.scanTicket)
      final response = await _client.identity.validateIdentityQrCode(
        code,
        1, // facilityId - TODO: Dynamisch aus Settings
      );

      if (response != null && response['success'] == true) {
        _updateDailyStats(success: true);
        return ScanResult(
          success: true,
          message: 'Vertic Ticket erfolgreich gescannt',
          scanType: 'Vertic Ticket',
          additionalData: response,
        );
      } else {
        _updateDailyStats(success: false);
        return ScanResult(
          success: false,
          message: response?['message'] ?? 'Vertic Ticket ungültig',
          scanType: 'Vertic Ticket',
          additionalData: response,
        );
      }
    } catch (e) {
      debugPrint('❌ Vertic Ticket Fehler: $e');
      _updateDailyStats(success: false);
      return ScanResult(
        success: false,
        message: 'Vertic Ticket Scanner-Fehler: $e',
        scanType: 'Vertic Ticket',
      );
    }
  }

  /// **🏋️ FITPASS TICKET SCANNEN**
  Future<ScanResult> _processFitpassTicket(String code) async {
    debugPrint('🏋️ Scanne Fitpass Code: $code');

    try {
      // ✅ KORREKT: externalProvider.processExternalCheckin (nicht processFitpassAccess)
      final response = await _client.externalProvider.processExternalCheckin(
        code,
        1, // hallId - TODO: Dynamisch aus Settings
      );

      if (response.success) {
        _updateDailyStats(success: true);
        return ScanResult(
          success: true,
          message: 'Fitpass-Check-in erfolgreich',
          scanType: 'Fitpass',
          additionalData: response,
        );
      } else {
        _updateDailyStats(success: false);
        return ScanResult(
          success: false,
          message: response.message ?? 'Fitpass Check-in fehlgeschlagen',
          scanType: 'Fitpass',
          additionalData: response,
        );
      }
    } catch (e) {
      debugPrint('❌ Fitpass Fehler: $e');
      _updateDailyStats(success: false);
      return ScanResult(
        success: false,
        message: 'Fitpass Scanner-Fehler: $e',
        scanType: 'Fitpass',
      );
    }
  }

  /// **🏃 FRICTION TICKET SCANNEN**
  Future<ScanResult> _processFrictionTicket(String code) async {
    debugPrint('🏃 Scanne Friction Code: $code');

    try {
      // ✅ KORREKT: externalProvider.processExternalCheckin (nicht processFrictionAccess)
      final response = await _client.externalProvider.processExternalCheckin(
        code,
        1, // hallId - TODO: Dynamisch aus Settings
      );

      if (response.success) {
        _updateDailyStats(success: true);
        return ScanResult(
          success: true,
          message: 'Friction-Check-in erfolgreich',
          scanType: 'Friction',
          additionalData: response,
        );
      } else {
        _updateDailyStats(success: false);
        return ScanResult(
          success: false,
          message: response.message ?? 'Friction Check-in fehlgeschlagen',
          scanType: 'Friction',
          additionalData: response,
        );
      }
    } catch (e) {
      debugPrint('❌ Friction Fehler: $e');
      _updateDailyStats(success: false);
      return ScanResult(
        success: false,
        message: 'Friction Scanner-Fehler: $e',
        scanType: 'Friction',
      );
    }
  }

  /// **🔧 UNIVERSAL CODE SCANNEN (FALLBACK)**
  Future<ScanResult> _processUniversalCode(String code) async {
    debugPrint('🔧 Versuche Universal-Scan: $code');

    try {
      // ❌ ENTFERNT: Es gibt keinen unified Endpoint!
      // Fallback zu identity.validateIdentityQrCode
      final response = await _client.identity.validateIdentityQrCode(
        code,
        1, // facilityId - TODO: Dynamisch aus Settings
      );

      if (response != null && response['success'] == true) {
        _updateDailyStats(success: true);
        return ScanResult(
          success: true,
          message: 'Universal-Code erfolgreich gescannt',
          scanType: 'Universal',
          additionalData: response,
        );
      } else {
        _updateDailyStats(success: false);
        return ScanResult(
          success: false,
          message: 'Unbekannter Code-Typ',
          scanType: 'Universal',
        );
      }
    } catch (e) {
      debugPrint('❌ Universal Scanner Fehler: $e');
      _updateDailyStats(success: false);
      return ScanResult(
        success: false,
        message: 'Universal Scanner-Fehler: $e',
        scanType: 'Universal',
      );
    }
  }

  /// **🔗 GENERIC QR PROCESSING**
  Future<ScanResult> _processGenericQR(String code) async {
    try {
      // ✅ FALLBACK: Verwende Universal-Scanner (identity.validateIdentityQrCode)
      return await _processUniversalCode(code);
    } catch (e) {
      return ScanResult(success: false, message: 'QR-Code Fehler: $e');
    }
  }

  /// **📱 TOAST NOTIFICATIONS**
  void _showToastMessage(String message, {required bool isSuccess}) {
    if (_context == null || !_showToastNotifications) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(_context!).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// **💾 SETTINGS PERSISTENCE**
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('scanner_selected_port', _selectedPort ?? '');
      await prefs.setInt('scanner_baud_rate', _baudRate);
      await prefs.setString(
        'scanner_enabled_types',
        jsonEncode(_enabledScanTypes),
      );
      await prefs.setBool('scanner_show_toast', _showToastNotifications);
      await prefs.setBool('scanner_play_sound', _playSuccessSound);
      await prefs.setInt('scanner_total_scans', _totalScansToday);
      await prefs.setInt('scanner_successful_scans', _successfulScansToday);

      if (_lastResetDate != null) {
        await prefs.setString(
          'scanner_last_reset',
          _lastResetDate!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Speichern der Scanner-Einstellungen: $e');
    }
  }

  /// **📂 LOAD SETTINGS**
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedPort = prefs.getString('scanner_selected_port');
      _baudRate = prefs.getInt('scanner_baud_rate') ?? 9600;

      final enabledTypesJson = prefs.getString('scanner_enabled_types');
      if (enabledTypesJson != null) {
        final decoded = jsonDecode(enabledTypesJson) as Map<String, dynamic>;
        _enabledScanTypes = decoded.map(
          (key, value) => MapEntry(key, value as bool),
        );
      }

      _showToastNotifications = prefs.getBool('scanner_show_toast') ?? true;
      _playSuccessSound = prefs.getBool('scanner_play_sound') ?? true;
      _totalScansToday = prefs.getInt('scanner_total_scans') ?? 0;
      _successfulScansToday = prefs.getInt('scanner_successful_scans') ?? 0;

      final lastResetString = prefs.getString('scanner_last_reset');
      if (lastResetString != null) {
        _lastResetDate = DateTime.parse(lastResetString);
      }

      debugPrint('📂 Scanner-Einstellungen geladen');

      // Auto-Connect falls Port gespeichert
      if (_selectedPort != null && _selectedPort!.isNotEmpty) {
        debugPrint('🔄 Auto-Connect zu gespeichertem Port: $_selectedPort');
        connectToPort(_selectedPort!);
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Scanner-Einstellungen: $e');
    }
  }

  /// **🗑️ DISPOSE**
  @override
  void dispose() {
    debugPrint('🗑️ Background Scanner Service wird disposed...');
    disconnectFromPort();
    _serialScanner = null;
    super.dispose();
  }
}

/// **📋 SCAN RESULT MODEL**
class ScanResult {
  final bool success;
  final String message;
  final String scanType;
  final dynamic additionalData;

  ScanResult({
    required this.success,
    required this.message,
    this.scanType = '',
    this.additionalData,
  });
}
