import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class BillingConfigurationEndpoint extends Endpoint {
  // Alle Abrechnungskonfigurationen abrufen
  Future<List<BillingConfiguration>> getAllConfigurations(
      Session session) async {
    try {
      return await BillingConfiguration.db.find(
        session,
        orderBy: (c) => c.name,
      );
    } catch (e) {
      session.log('Fehler beim Abrufen der Abrechnungskonfigurationen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Aktive Konfiguration für einen Typ abrufen
  Future<BillingConfiguration?> getActiveConfiguration(
      Session session, String billingType) async {
    try {
      return await BillingConfiguration.db.findFirstRow(
        session,
        where: (c) =>
            c.billingType.equals(billingType) & c.isActive.equals(true),
      );
    } catch (e) {
      session.log('Fehler beim Abrufen der aktiven Konfiguration: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Neue Konfiguration erstellen
  Future<BillingConfiguration?> createConfiguration(
      Session session, BillingConfiguration config) async {
    try {
      final now = DateTime.now().toUtc();
      config.createdAt = now;
      config.updatedAt = now;

      // Wenn neue Konfiguration aktiv ist, andere des gleichen Typs deaktivieren
      if (config.isActive) {
        await _deactivateOtherConfigurations(session, config.billingType);
      }

      return await BillingConfiguration.db.insertRow(session, config);
    } catch (e) {
      session.log('Fehler beim Erstellen der Abrechnungskonfiguration: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Konfiguration aktualisieren
  Future<BillingConfiguration?> updateConfiguration(
      Session session, BillingConfiguration config) async {
    try {
      config.updatedAt = DateTime.now().toUtc();

      // Wenn Konfiguration aktiviert wird, andere des gleichen Typs deaktivieren
      if (config.isActive) {
        await _deactivateOtherConfigurations(
            session, config.billingType, config.id);
      }

      return await BillingConfiguration.db.updateRow(session, config);
    } catch (e) {
      session.log('Fehler beim Aktualisieren der Abrechnungskonfiguration: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Konfiguration löschen
  Future<bool> deleteConfiguration(Session session, int id) async {
    try {
      await BillingConfiguration.db
          .deleteWhere(session, where: (c) => c.id.equals(id));
      return true;
    } catch (e) {
      session.log('Fehler beim Löschen der Abrechnungskonfiguration: $e',
          level: LogLevel.error);
      return false;
    }
  }

  // Standard-Konfigurationen erstellen
  Future<bool> createDefaultConfigurations(Session session) async {
    try {
      // Prüfe ob bereits Konfigurationen existieren
      final existing = await BillingConfiguration.db.find(session);
      if (existing.isNotEmpty) {
        session.log('Abrechnungskonfigurationen bereits vorhanden');
        return true;
      }

      final now = DateTime.now().toUtc();

      final configs = [
        BillingConfiguration(
          name: 'Monatlich am 1.',
          description:
              'Alle monatlichen Abos werden am 1. des Monats abgerechnet',
          billingType: 'monthly',
          billingDay: 1,
          billingDayOfYear: null,
          customIntervalDays: null,
          isActive: true,
          createdAt: now,
        ),
        BillingConfiguration(
          name: 'Monatlich am 15.',
          description:
              'Alle monatlichen Abos werden am 15. des Monats abgerechnet',
          billingType: 'monthly',
          billingDay: 15,
          billingDayOfYear: null,
          customIntervalDays: null,
          isActive: false,
          createdAt: now,
        ),
        BillingConfiguration(
          name: 'Jährlich am 1. Januar',
          description: 'Alle jährlichen Abos werden am 1. Januar abgerechnet',
          billingType: 'yearly',
          billingDay: 1,
          billingDayOfYear: 1,
          customIntervalDays: null,
          isActive: true,
          createdAt: now,
        ),
      ];

      for (final config in configs) {
        await BillingConfiguration.db.insertRow(session, config);
      }

      session.log(
          '${configs.length} Standard-Abrechnungskonfigurationen erstellt');
      return true;
    } catch (e) {
      session.log('Fehler beim Erstellen der Standard-Konfigurationen: $e',
          level: LogLevel.error);
      return false;
    }
  }

  // Hilfsfunktion: Andere Konfigurationen des gleichen Typs deaktivieren
  Future<void> _deactivateOtherConfigurations(
      Session session, String billingType,
      [int? excludeId]) async {
    // Alle Konfigurationen des gleichen Typs finden
    final allOfType = await BillingConfiguration.db.find(
      session,
      where: (c) => c.billingType.equals(billingType),
    );

    // Filtere die aktuelle Konfiguration aus (falls vorhanden)
    final others = excludeId != null
        ? allOfType.where((config) => config.id != excludeId).toList()
        : allOfType;

    for (final config in others) {
      config.isActive = false;
      config.updatedAt = DateTime.now().toUtc();
      await BillingConfiguration.db.updateRow(session, config);
    }
  }

  // Nächstes Abrechnungsdatum für eine Konfiguration berechnen
  Future<DateTime?> calculateNextBillingDate(
      Session session, String billingType, DateTime fromDate) async {
    final config = await getActiveConfiguration(session, billingType);
    if (config == null) return null;

    try {
      switch (config.billingType) {
        case 'monthly':
          final nextMonth =
              DateTime(fromDate.year, fromDate.month + 1, config.billingDay);
          // Wenn der Tag im nächsten Monat nicht existiert (z.B. 31. Februar), nehme letzten Tag
          if (nextMonth.month != fromDate.month + 1) {
            return DateTime(
                fromDate.year, fromDate.month + 2, 0); // Letzter Tag des Monats
          }
          return nextMonth;

        case 'yearly':
          return DateTime(fromDate.year + 1, 1, config.billingDay);

        case 'custom':
          if (config.customIntervalDays != null) {
            return fromDate.add(Duration(days: config.customIntervalDays!));
          }
          break;
      }
    } catch (e) {
      session.log('Fehler beim Berechnen des nächsten Abrechnungsdatums: $e',
          level: LogLevel.error);
    }

    return null;
  }
}
