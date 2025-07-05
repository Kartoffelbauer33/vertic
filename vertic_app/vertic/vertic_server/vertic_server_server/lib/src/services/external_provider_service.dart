import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'fitpass_service.dart';
import 'friction_service.dart';

/// Zentrale Service-Klasse für alle Fremdanbieter-Integrationen
class ExternalProviderService {
  /// Verarbeitet Check-in mit externem QR-Code
  static Future<ExternalCheckinResult> processExternalCheckin(
    Session session,
    String qrCodeData,
    int hallId,
    int staffId,
  ) async {
    final startTime = DateTime.now();

    try {
      // 1. Provider anhand QR-Code erkennen
      final providerType = _detectProviderFromQrCode(qrCodeData);
      if (providerType == null) {
        return ExternalCheckinResult(
          success: false,
          accessGranted: false,
          message: 'Unbekannter QR-Code Format',
          providerName: 'unknown',
          statusCode: 400,
          processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
          isReEntry: false,
        );
      }

      // 2. Provider-Konfiguration laden
      final provider = await _getProviderConfig(session, providerType, hallId);
      if (provider == null || !provider.isActive) {
        return ExternalCheckinResult(
          success: false,
          accessGranted: false,
          message: 'Provider $providerType ist nicht verfügbar',
          providerName: providerType,
          statusCode: 503,
          processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
          isReEntry: false,
        );
      }

      // 3. Bestehende Mitgliedschaft finden
      final membership =
          await _findMembershipByQrCode(session, qrCodeData, provider.id!);

      // 4. Re-Entry prüfen
      final isReEntry =
          await _checkReEntry(session, membership?.id, hallId, provider);

      // 5. Provider-spezifische Validierung
      final result = await _validateWithProvider(
          session, provider, qrCodeData, membership);

      // 6. Check-in protokollieren
      if (membership != null) {
        await _logCheckin(session, membership.id!, hallId, staffId, result,
            qrCodeData, isReEntry);

        // 7. Statistiken aktualisieren
        await _updateMembershipStats(session, membership, result.accessGranted);
      }

      return ExternalCheckinResult(
        success: result.success,
        accessGranted: result.accessGranted,
        message: result.message,
        userName: result.userName,
        userCity: result.userCity,
        userAvatar: result.userAvatar,
        providerName: provider.providerName,
        membershipType: result.membershipType,
        statusCode: result.statusCode,
        externalStatusCode: result.externalStatusCode,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        isReEntry: isReEntry,
        lastCheckinAt: membership?.lastCheckinAt,
        errorDetails: result.errorDetails,
      );
    } catch (e) {
      session.log('Fehler beim externen Check-in: $e', level: LogLevel.error);
      return ExternalCheckinResult(
        success: false,
        accessGranted: false,
        message: 'Technischer Fehler beim Check-in',
        providerName: 'unknown',
        statusCode: 500,
        processingTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        isReEntry: false,
        errorDetails: e.toString(),
      );
    }
  }

  /// Verknüpft eine neue externe Mitgliedschaft mit einem User
  static Future<ExternalMembershipResponse> linkExternalMembership(
    Session session,
    int userId,
    int hallId,
    ExternalMembershipRequest request,
  ) async {
    try {
      // 1. Provider-Typ erkennen
      final providerType = _detectProviderFromQrCode(request.qrCodeData);
      if (providerType == null) {
        return ExternalMembershipResponse(
          success: false,
          message: 'Unbekanntes QR-Code Format',
          errorCode: 'INVALID_QR',
        );
      }

      // 2. Provider für User's Hall finden
      final user = await AppUser.db.findById(session, userId);
      if (user == null) {
        return ExternalMembershipResponse(
          success: false,
          message: 'Benutzer nicht gefunden',
          errorCode: 'USER_NOT_FOUND',
        );
      }

      // 3. Provider-Konfiguration laden
      final provider = await _getProviderConfig(session, providerType, hallId);
      if (provider == null) {
        return ExternalMembershipResponse(
          success: false,
          message: 'Provider $providerType ist in Ihrer Halle nicht verfügbar',
          errorCode: 'PROVIDER_NOT_AVAILABLE',
        );
      }

      // 4. Externe User-ID extrahieren
      final externalUserId =
          await _extractExternalUserId(request.qrCodeData, providerType);
      if (externalUserId == null) {
        return ExternalMembershipResponse(
          success: false,
          message: 'Ungültige Mitgliedsdaten im QR-Code',
          errorCode: 'INVALID_QR',
        );
      }

      // 5. Prüfen ob bereits verknüpft
      final existingMembership = await UserExternalMembership.db.findFirstRow(
        session,
        where: (m) =>
            m.providerId.equals(provider.id!) &
            m.externalUserId.equals(externalUserId),
      );

      if (existingMembership != null) {
        return ExternalMembershipResponse(
          success: false,
          message:
              'Diese Mitgliedschaft ist bereits einem anderen Benutzer zugeordnet',
          errorCode: 'ALREADY_LINKED',
        );
      }

      // 6. Test-Validierung beim Provider
      final testResult = await _validateWithProvider(
          session, provider, request.qrCodeData, null);
      if (!testResult.success) {
        return ExternalMembershipResponse(
          success: false,
          message:
              'Mitgliedschaft konnte nicht validiert werden: ${testResult.message}',
          errorCode: 'PROVIDER_ERROR',
          errorDetails: testResult.errorDetails,
        );
      }

      // 7. Neue Mitgliedschaft erstellen
      final membership = UserExternalMembership(
        userId: userId,
        providerId: provider.id!,
        externalUserId: externalUserId,
        membershipEmail: testResult.userName, // Falls verfügbar
        membershipData: jsonEncode(testResult.toJson()),
        verificationMethod: 'qr_scan',
        verifiedAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
        notes: request.notes,
      );

      final savedMembership =
          await UserExternalMembership.db.insertRow(session, membership);

      return ExternalMembershipResponse(
        success: true,
        message: 'Mitgliedschaft erfolgreich verknüpft',
        membershipId: savedMembership.id,
        providerName: provider.providerName,
        externalUserId: externalUserId,
        displayName: provider.displayName,
      );
    } catch (e) {
      session.log('Fehler beim Verknüpfen der Mitgliedschaft: $e',
          level: LogLevel.error);
      return ExternalMembershipResponse(
        success: false,
        message: 'Technischer Fehler beim Verknüpfen',
        errorCode: 'SYSTEM_ERROR',
        errorDetails: e.toString(),
      );
    }
  }

  // Private Helper-Methoden

  static String? _detectProviderFromQrCode(String qrCodeData) {
    if (qrCodeData.startsWith('FP-')) {
      return 'fitpass';
    }

    // Friction verwendet vCard Format
    if (qrCodeData.contains('BEGIN:VCARD') && qrCodeData.contains('ORG:')) {
      return 'friction';
    }

    return null;
  }

  static Future<ExternalProvider?> _getProviderConfig(
    Session session,
    String providerType,
    int hallId,
  ) async {
    return await ExternalProvider.db.findFirstRow(
      session,
      where: (p) =>
          p.providerName.equals(providerType) & p.hallId.equals(hallId),
    );
  }

  static Future<UserExternalMembership?> _findMembershipByQrCode(
    Session session,
    String qrCodeData,
    int providerId,
  ) async {
    final externalUserId = await _extractExternalUserId(
        qrCodeData, _detectProviderFromQrCode(qrCodeData)!);
    if (externalUserId == null) return null;

    return await UserExternalMembership.db.findFirstRow(
      session,
      where: (m) =>
          m.providerId.equals(providerId) &
          m.externalUserId.equals(externalUserId),
    );
  }

  static Future<String?> _extractExternalUserId(
      String qrCodeData, String providerType) async {
    switch (providerType) {
      case 'fitpass':
        return FitpassService.extractCheckinCode(qrCodeData);
      case 'friction':
        return FrictionService.extractUserId(qrCodeData);
      default:
        return null;
    }
  }

  static Future<bool> _checkReEntry(Session session, int? membershipId,
      int hallId, ExternalProvider provider) async {
    if (membershipId == null) return false;

    // Re-Entry-Zeitfenster basierend auf Provider-Konfiguration
    final DateTime cutoffTime;
    if (provider.reEntryWindowType == 'days') {
      cutoffTime = DateTime.now()
          .toUtc()
          .subtract(Duration(days: provider.reEntryWindowDays));
    } else {
      // Default: hours
      cutoffTime = DateTime.now()
          .toUtc()
          .subtract(Duration(hours: provider.reEntryWindowHours));
    }

    final recentCheckins = await ExternalCheckinLog.db.find(
      session,
      where: (log) =>
          log.membershipId.equals(membershipId) &
          log.hallId.equals(hallId) &
          log.accessGranted.equals(true),
      orderBy: (log) => log.checkinAt,
      orderDescending: true,
      limit: 5, // Letzte Check-ins holen
    );

    // Filter manuell auf cutoffTime (wegen Serverpod Limitierungen)
    final filteredCheckins = recentCheckins
        .where(
          (checkin) => checkin.checkinAt.isAfter(cutoffTime),
        )
        .toList();

    return filteredCheckins.isNotEmpty;
  }

  static Future<ExternalCheckinResult> _validateWithProvider(
    Session session,
    ExternalProvider provider,
    String qrCodeData,
    UserExternalMembership? membership,
  ) async {
    switch (provider.providerName) {
      case 'fitpass':
        return await FitpassService.validateCheckin(
            session, provider, qrCodeData);
      case 'friction':
        return await FrictionService.validateCheckin(
            session, provider, qrCodeData);
      default:
        throw Exception('Unbekannter Provider: ${provider.providerName}');
    }
  }

  static Future<void> _logCheckin(
    Session session,
    int membershipId,
    int hallId,
    int staffId,
    ExternalCheckinResult result,
    String qrCodeData,
    bool isReEntry,
  ) async {
    final log = ExternalCheckinLog(
      membershipId: membershipId,
      hallId: hallId,
      checkinType: 'external_qr',
      qrCodeData: qrCodeData,
      externalResponse: jsonEncode(result.toJson()),
      externalStatusCode: result.externalStatusCode,
      accessGranted: result.accessGranted,
      failureReason: result.accessGranted ? null : result.message,
      staffId: staffId,
      processingTimeMs: result.processingTimeMs,
      checkinAt: DateTime.now().toUtc(),
      isReEntry: isReEntry,
    );

    await ExternalCheckinLog.db.insertRow(session, log);
  }

  static Future<void> _updateMembershipStats(
    Session session,
    UserExternalMembership membership,
    bool success,
  ) async {
    if (success) {
      membership.totalCheckins = membership.totalCheckins + 1;
      membership.lastSuccessfulCheckin = DateTime.now().toUtc();
      membership.lastCheckinAt = DateTime.now().toUtc();
    } else {
      membership.failureCount = membership.failureCount + 1;
      membership.lastFailedCheckin = DateTime.now().toUtc();
    }

    membership.updatedAt = DateTime.now().toUtc();
    await UserExternalMembership.db.updateRow(session, membership);
  }
}
