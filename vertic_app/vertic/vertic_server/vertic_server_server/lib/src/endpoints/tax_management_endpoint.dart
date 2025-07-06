import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../helpers/staff_auth_helper.dart';
import '../helpers/permission_helper.dart';

/// **🏛️ DACH-COMPLIANCE: Tax Management Endpoint**
///
/// Verwaltet Länder-Einstellungen und Steuerklassen für:
/// - Deutschland (TSE-Integration)
/// - Österreich (RKSV-Compliance)
/// - Schweiz (Mehrwertsteuer)
///
/// Bietet dynamische, konfigurierbare Steuerklassen statt hart kodierter Werte.
///
/// TODO: Vollständige Implementierung nach Model-Generierung
class TaxManagementEndpoint extends Endpoint {
  /// Placeholder-Methode bis Models generiert sind
  Future<String> placeholder(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    return 'Tax Management Endpoint - Models werden generiert...';
  }

  // ==================== COUNTRY MANAGEMENT ====================

  /// Alle verfügbaren Länder abrufen
  Future<List<Country>> getAllCountries(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      return await Country.db.find(
        session,
        where: (t) => t.isActive.equals(true),
        orderBy: (t) => t.displayName,
      );
    } catch (e) {
      session.log('Fehler beim Abrufen der Länder: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Standard-Land für neue Standorte abrufen
  Future<Country?> getDefaultCountry(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      final defaultCountries = await Country.db.find(
        session,
        where: (t) => t.isDefault.equals(true) & t.isActive.equals(true),
        limit: 1,
      );

      return defaultCountries.isNotEmpty ? defaultCountries.first : null;
    } catch (e) {
      session.log('Fehler beim Abrufen des Standard-Landes: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  // ==================== TAX CLASS MANAGEMENT ====================

  /// Alle Steuerklassen für ein Land abrufen
  Future<List<TaxClass>> getTaxClassesForCountry(
      Session session, int countryId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      return await TaxClass.db.find(
        session,
        where: (t) => t.countryId.equals(countryId) & t.isActive.equals(true),
        orderBy: (t) => t.displayOrder,
      );
    } catch (e) {
      session.log('Fehler beim Abrufen der Steuerklassen: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Standard-Steuerklasse für ein Land abrufen
  Future<TaxClass?> getDefaultTaxClass(Session session, int countryId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      final defaultTaxClasses = await TaxClass.db.find(
        session,
        where: (t) =>
            t.countryId.equals(countryId) &
            t.isDefault.equals(true) &
            t.isActive.equals(true),
        limit: 1,
      );

      return defaultTaxClasses.isNotEmpty ? defaultTaxClasses.first : null;
    } catch (e) {
      session.log('Fehler beim Abrufen der Standard-Steuerklasse: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  // ==================== SETUP METHODS ====================

  /// Standard-Setup für Deutschland erstellen
  Future<String> setupGermanyDefaults(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_setup_country_defaults',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung für System-Setup');
    }

    try {
      // Deutschland finden oder erstellen
      var germany = await Country.db.find(
        session,
        where: (t) => t.code.equals('DE'),
        limit: 1,
      );

      if (germany.isEmpty) {
        final newGermany = Country(
          code: 'DE',
          name: 'Deutschland',
          displayName: 'Deutschland',
          currency: 'EUR',
          locale: 'de-DE',
          requiresTSE: true,
          requiresRKSV: false,
          taxSystemType: 'vat',
          isDefault: true,
          createdAt: DateTime.now(),
          createdByStaffId: staffUserId,
        );
        germany = [await Country.db.insertRow(session, newGermany)];
      }

      final germanyId = germany.first.id!;

      // Standard-Steuerklassen für Deutschland erstellen
      final taxClasses = <TaxClass>[];

      // 1. Klettereintritt - 19% (Standard)
      final climbingClass = TaxClass(
        name: 'Klettereintritt & Sport',
        description: 'Kletter- und Sportdienstleistungen (19% MwSt)',
        internalCode: 'CLIMBING_ENTRY_DE',
        countryId: germanyId,
        taxRate: 19.0,
        taxType: 'VAT',
        productCategory: 'SERVICES',
        requiresTSESignature: true,
        isDefault: true,
        appliesToMemberships: true,
        appliesToOneTimeEntries: true,
        appliesToProducts: false,
        colorHex: '#4CAF50',
        iconName: 'sports_handball',
        createdAt: DateTime.now(),
        createdByStaffId: staffUserId,
      );
      taxClasses.add(await TaxClass.db.insertRow(session, climbingClass));

      // 2. Grundnahrungsmittel - 7%
      final foodClass = TaxClass(
        name: 'Grundnahrungsmittel',
        description: 'Grundnahrungsmittel (7% MwSt)',
        internalCode: 'FOOD_BASIC_DE',
        countryId: germanyId,
        taxRate: 7.0,
        taxType: 'VAT',
        productCategory: 'FOOD',
        requiresTSESignature: true,
        isDefault: false,
        appliesToMemberships: false,
        appliesToOneTimeEntries: false,
        appliesToProducts: true,
        colorHex: '#FF9800',
        iconName: 'restaurant',
        createdAt: DateTime.now(),
        createdByStaffId: staffUserId,
      );
      taxClasses.add(await TaxClass.db.insertRow(session, foodClass));

      // 3. Getränke & Gastronomie - 19%
      final beverageClass = TaxClass(
        name: 'Getränke & Gastronomie',
        description: 'Getränke und Restaurantservice (19% MwSt)',
        internalCode: 'BEVERAGES_DE',
        countryId: germanyId,
        taxRate: 19.0,
        taxType: 'VAT',
        productCategory: 'BEVERAGES',
        requiresTSESignature: true,
        isDefault: false,
        appliesToMemberships: false,
        appliesToOneTimeEntries: false,
        appliesToProducts: true,
        colorHex: '#2196F3',
        iconName: 'local_drink',
        createdAt: DateTime.now(),
        createdByStaffId: staffUserId,
      );
      taxClasses.add(await TaxClass.db.insertRow(session, beverageClass));

      // 4. Ausrüstung & Merchandise - 19%
      final equipmentClass = TaxClass(
        name: 'Ausrüstung & Merchandise',
        description: 'Kletterausrüstung und Merchandise (19% MwSt)',
        internalCode: 'EQUIPMENT_DE',
        countryId: germanyId,
        taxRate: 19.0,
        taxType: 'VAT',
        productCategory: 'GOODS',
        requiresTSESignature: true,
        isDefault: false,
        appliesToMemberships: false,
        appliesToOneTimeEntries: false,
        appliesToProducts: true,
        colorHex: '#9C27B0',
        iconName: 'shopping_bag',
        createdAt: DateTime.now(),
        createdByStaffId: staffUserId,
      );
      taxClasses.add(await TaxClass.db.insertRow(session, equipmentClass));

      session.log(
          'Deutschland Standard-Setup abgeschlossen: ${taxClasses.length} Steuerklassen');
      return 'Deutschland erfolgreich eingerichtet mit ${taxClasses.length} Steuerklassen';
    } catch (e) {
      session.log('Fehler beim Deutschland-Setup: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Standard-Setup für Österreich erstellen
  Future<String> setupAustriaDefaults(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final hasPermission = await PermissionHelper.hasPermission(
      session,
      staffUserId,
      'can_setup_country_defaults',
    );
    if (!hasPermission) {
      throw Exception('Keine Berechtigung für System-Setup');
    }

    try {
      // Österreich finden oder erstellen
      var austria = await Country.db.find(
        session,
        where: (t) => t.code.equals('AT'),
        limit: 1,
      );

      if (austria.isEmpty) {
        final newAustria = Country(
          code: 'AT',
          name: 'Österreich',
          displayName: 'Österreich',
          currency: 'EUR',
          locale: 'de-AT',
          requiresTSE: false,
          requiresRKSV: true,
          vatRegistrationThreshold: 15000.0,
          taxSystemType: 'vat',
          isDefault: false,
          createdAt: DateTime.now(),
          createdByStaffId: staffUserId,
        );
        austria = [await Country.db.insertRow(session, newAustria)];
      }

      final austriaId = austria.first.id!;

      // Standard-Steuerklassen für Österreich erstellen
      final taxClasses = <TaxClass>[];

      // 1. Mitgliedschaften & Sport - 13%
      final membershipClass = TaxClass(
        name: 'Mitgliedschaften & Sport',
        description: 'Sporttätigkeiten und Mitgliedschaften (13% USt)',
        internalCode: 'MEMBERSHIPS_AT',
        countryId: austriaId,
        taxRate: 13.0,
        taxType: 'VAT',
        productCategory: 'SERVICES',
        requiresRKSVChain: true,
        isDefault: true,
        appliesToMemberships: true,
        appliesToOneTimeEntries: true,
        appliesToProducts: false,
        colorHex: '#4CAF50',
        iconName: 'sports_handball',
        createdAt: DateTime.now(),
        createdByStaffId: staffUserId,
      );
      taxClasses.add(await TaxClass.db.insertRow(session, membershipClass));

      // 2. Gastronomie - 10%
      final gastronomyClass = TaxClass(
        name: 'Gastronomie',
        description: 'Speisen und Getränke (10% USt)',
        internalCode: 'GASTRONOMY_AT',
        countryId: austriaId,
        taxRate: 10.0,
        taxType: 'VAT',
        productCategory: 'FOOD',
        requiresRKSVChain: true,
        isDefault: false,
        appliesToMemberships: false,
        appliesToOneTimeEntries: false,
        appliesToProducts: true,
        colorHex: '#FF9800',
        iconName: 'restaurant',
        createdAt: DateTime.now(),
        createdByStaffId: staffUserId,
      );
      taxClasses.add(await TaxClass.db.insertRow(session, gastronomyClass));

      // 3. Einzelhandel - 20%
      final retailClass = TaxClass(
        name: 'Einzelhandel',
        description: 'Kletterausrüstung und Merchandise (20% USt)',
        internalCode: 'RETAIL_AT',
        countryId: austriaId,
        taxRate: 20.0,
        taxType: 'VAT',
        productCategory: 'GOODS',
        requiresRKSVChain: true,
        isDefault: false,
        appliesToMemberships: false,
        appliesToOneTimeEntries: false,
        appliesToProducts: true,
        colorHex: '#9C27B0',
        iconName: 'shopping_bag',
        createdAt: DateTime.now(),
        createdByStaffId: staffUserId,
      );
      taxClasses.add(await TaxClass.db.insertRow(session, retailClass));

      session.log(
          'Österreich Standard-Setup abgeschlossen: ${taxClasses.length} Steuerklassen');
      return 'Österreich erfolgreich eingerichtet mit ${taxClasses.length} Steuerklassen';
    } catch (e) {
      session.log('Fehler beim Österreich-Setup: $e', level: LogLevel.error);
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Berechne Steuer für einen Betrag
  Future<Map<String, double>> calculateTax(
    Session session,
    double netAmount,
    int taxClassId,
  ) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      final taxClass = await TaxClass.db.findById(session, taxClassId);
      if (taxClass == null) {
        throw Exception('Steuerklasse nicht gefunden');
      }

      final taxRate = taxClass.taxRate / 100;
      final taxAmount = netAmount * taxRate;
      final grossAmount = netAmount + taxAmount;

      return {
        'netAmount': netAmount,
        'taxRate': taxClass.taxRate,
        'taxAmount': taxAmount,
        'grossAmount': grossAmount,
      };
    } catch (e) {
      session.log('Fehler bei Steuerberechnung: $e', level: LogLevel.error);
      rethrow;
    }
  }
}
