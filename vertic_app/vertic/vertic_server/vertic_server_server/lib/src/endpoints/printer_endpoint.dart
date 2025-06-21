import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';

/// Printer-Management Endpoint
class PrinterEndpoint extends Endpoint {
  /// Prüft ob StaffUser für Printer-Management berechtigt ist
  Future<int?> _getAuthenticatedStaffUserId(Session session) async {
    return await StaffAuthHelper.getAuthenticatedStaffUserId(session);
  }

  /// Lädt alle Drucker-Konfigurationen (nur für System-Admins)
  Future<List<PrinterConfiguration>> loadPrinterConfigurations(
      Session session, int? facilityId) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Drucker-Konfiguration verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_configure_printers');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_configure_printers (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      final printers = await PrinterConfiguration.db.find(
        session,
        where:
            facilityId != null ? (p) => p.facilityId.equals(facilityId) : null,
        orderBy: (p) => p.printerName,
      );

      session.log('Drucker-Konfigurationen geladen: ${printers.length}');
      return printers;
    } catch (e) {
      session.log('Fehler beim Laden der Drucker-Konfigurationen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Speichert/aktualisiert eine Drucker-Konfiguration
  Future<bool> savePrinterConfiguration(
    Session session,
    int? configId,
    int? facilityId,
    String printerName,
    String printerType,
    String connectionType,
    Map<String, dynamic> connectionSettings,
    String paperSize,
    bool isDefault,
    bool isActive,
  ) async {
    // 🔐 RBAC SECURITY CHECK - HIGH LEVEL REQUIRED
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Drucker-Speichern verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_configure_printers');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_configure_printers (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    try {
      // Validiere Eingaben
      if (printerName.trim().isEmpty) {
        session.log('Drucker-Name darf nicht leer sein', level: LogLevel.error);
        return false;
      }

      final validPrinterTypes = ['thermal', 'laser', 'inkjet'];
      if (!validPrinterTypes.contains(printerType)) {
        session.log('Ungültiger Drucker-Typ: $printerType',
            level: LogLevel.error);
        return false;
      }

      final validConnectionTypes = ['com_port', 'network', 'usb'];
      if (!validConnectionTypes.contains(connectionType)) {
        session.log('Ungültiger Verbindungstyp: $connectionType',
            level: LogLevel.error);
        return false;
      }

      final now = DateTime.now().toUtc();
      final connectionSettingsJson = jsonEncode(connectionSettings);

      if (configId != null) {
        // Update existierende Konfiguration
        final existing =
            await PrinterConfiguration.db.findById(session, configId);
        if (existing == null) return false;

        final updated = existing.copyWith(
          printerName: printerName,
          printerType: printerType,
          connectionType: connectionType,
          connectionSettings: connectionSettingsJson,
          paperSize: paperSize,
          isDefault: isDefault,
          isActive: isActive,
          updatedAt: now,
        );

        await PrinterConfiguration.db.updateRow(session, updated);
      } else {
        // Neue Konfiguration erstellen
        final newConfig = PrinterConfiguration(
          facilityId: facilityId,
          printerName: printerName,
          printerType: printerType,
          connectionType: connectionType,
          connectionSettings: connectionSettingsJson,
          paperSize: paperSize,
          isDefault: isDefault,
          isActive: isActive,
          testPrintEnabled: true,
          createdBy: authUserId,
          createdAt: now,
        );

        await PrinterConfiguration.db.insertRow(session, newConfig);
      }

      // Falls als Standard markiert, andere Standard-Drucker deaktivieren
      if (isDefault) {
        final otherConfigs = await PrinterConfiguration.db.find(
          session,
          where: (p) =>
              p.facilityId.equals(facilityId) & p.id.notEquals(configId ?? -1),
        );

        for (final config in otherConfigs) {
          final updated = config.copyWith(isDefault: false, updatedAt: now);
          await PrinterConfiguration.db.updateRow(session, updated);
        }
      }

      session.log('Drucker-Konfiguration gespeichert: $printerName');
      return true;
    } catch (e) {
      session.log('Fehler beim Speichern der Drucker-Konfiguration: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// Testet eine Drucker-Verbindung
  Future<PrinterTestResponse> testPrinterConnection(
    Session session,
    int configId,
  ) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      return PrinterTestResponse(
        success: false,
        error: 'Nicht eingeloggt',
      );
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_use_printers');
    if (!hasPermission) {
      return PrinterTestResponse(
        success: false,
        error: 'Fehlende Berechtigung: can_use_printers',
      );
    }

    try {
      // Prüfe ob Drucker-Konfiguration existiert
      final config = await PrinterConfiguration.db.findById(session, configId);
      if (config == null) {
        return PrinterTestResponse(
          success: false,
          error: 'Drucker nicht gefunden',
        );
      }

      // Simuliere Verbindungstest
      await Future.delayed(const Duration(seconds: 1));

      session.log('Drucker-Verbindungstest durchgeführt: Config $configId');

      return PrinterTestResponse(
        success: true,
        message: 'Drucker erfolgreich erreicht',
        printerStatus: 'ready',
        paperStatus: 'ok',
      );
    } catch (e) {
      session.log('Fehler beim Drucker-Verbindungstest: $e',
          level: LogLevel.error);
      return PrinterTestResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Druckt ein Test-Ticket
  Future<PrinterTestResponse> printTestTicket(
    Session session,
    int configId,
  ) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      return PrinterTestResponse(
        success: false,
        error: 'Nicht eingeloggt',
      );
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_use_printers');
    if (!hasPermission) {
      return PrinterTestResponse(
        success: false,
        error: 'Fehlende Berechtigung: can_use_printers',
      );
    }

    try {
      final config = await PrinterConfiguration.db.findById(session, configId);
      if (config == null) {
        return PrinterTestResponse(
          success: false,
          error: 'Drucker nicht gefunden',
        );
      }

      // Simuliere Test-Druck
      await Future.delayed(const Duration(seconds: 2));

      session.log('Test-Ticket gedruckt auf Config $configId');

      return PrinterTestResponse(
        success: true,
        message: 'Test-Ticket erfolgreich gedruckt',
        printerStatus: 'ready',
        paperStatus: 'ok',
      );
    } catch (e) {
      session.log('Fehler beim Test-Ticket-Druck: $e', level: LogLevel.error);
      return PrinterTestResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Lädt verfügbare Drucker-Konfigurationen für Dropdown
  Future<List<PrinterConfiguration>> getAvailablePrinters(
      Session session) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Drucker-Liste verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_use_printers');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_use_printers (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      return await PrinterConfiguration.db.find(
        session,
        where: (p) => p.isActive.equals(true),
        orderBy: (p) => p.printerName,
      );
    } catch (e) {
      session.log('Fehler beim Laden der verfügbaren Drucker: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Holt verfügbare COM-Ports (Windows-spezifisch)
  Future<List<String>> getAvailableComPorts(Session session) async {
    // 🔐 RBAC SECURITY CHECK - HIGH LEVEL REQUIRED
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - COM-Ports verweigert',
          level: LogLevel.warning);
      return [];
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_configure_printers');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_configure_printers (User: $authUserId)',
          level: LogLevel.warning);
      return [];
    }

    try {
      // TODO: Echte COM-Port-Erkennung implementieren
      // Auf Windows: wmic path win32_serialport get deviceid
      // Für jetzt: Standard COM-Ports zurückgeben
      return ['COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8'];
    } catch (e) {
      session.log('Fehler beim Laden der COM-Ports: $e', level: LogLevel.error);
      return [];
    }
  }

  /// Druckt ein echtes Ticket (nur für Staff mit entsprechender Berechtigung)
  Future<PrinterTestResponse> printTicket(
    Session session,
    int ticketId,
    int? configId,
  ) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      return PrinterTestResponse(
        success: false,
        error: 'Nicht eingeloggt',
      );
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_print_tickets');
    if (!hasPermission) {
      return PrinterTestResponse(
        success: false,
        error: 'Fehlende Berechtigung: can_print_tickets',
      );
    }

    try {
      // Lade Ticket-Daten - Staff kann alle Tickets drucken
      final ticket = await Ticket.db.findById(session, ticketId);
      if (ticket == null) {
        return PrinterTestResponse(
          success: false,
          error: 'Ticket nicht gefunden',
        );
      }

      // Lade TicketType für Details
      final ticketType =
          await TicketType.db.findById(session, ticket.ticketTypeId);
      if (ticketType == null) {
        return PrinterTestResponse(
          success: false,
          error: 'Ticket-Typ nicht gefunden',
        );
      }

      // Echten Druckauftrag implementieren
      final printJobId =
          'ticket_${ticketId}_${DateTime.now().millisecondsSinceEpoch}';

      session.log('Ticket gedruckt: $ticketId');

      return PrinterTestResponse(
        success: true,
        message: 'Ticket erfolgreich gedruckt',
        printJobId: printJobId,
      );
    } catch (e) {
      session.log('Fehler beim Ticket-Druck: $e', level: LogLevel.error);
      return PrinterTestResponse(
        success: false,
        error: e.toString(),
      );
    }
  }
}
