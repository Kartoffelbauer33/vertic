import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
// 🔐 RBAC SECURITY INTEGRATION
import '../helpers/permission_helper.dart';
import '../helpers/staff_auth_helper.dart';

class IdentityEndpoint extends Endpoint {
  // Wiederverwendung des sicheren Schlüssels
  static const String _secretKey = 'YVPn4aX8biYLe0C2drFzhK7Jq1sW9m';

  /// QR-Rotation Modi
  static const String ROTATION_IMMEDIATE = 'immediate';
  static const String ROTATION_DAILY_USAGE = 'daily_usage';
  static const String ROTATION_TIME_BASED = 'time_based';
  static const String ROTATION_MANUAL = 'manual';

  /// Generiert einen sicheren, kryptographischen QR-Code
  Future<String> _generateSecureQrCode(int userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure();
    final nonce = List.generate(16, (i) => random.nextInt(256));

    // Erstelle Payload mit strukturierten Daten
    final payload = {
      'uid': userId,
      'ts': timestamp,
      'nonce': base64Encode(nonce),
      'version': '2.0',
      'type': 'vertic_identity'
    };

    final payloadJson = json.encode(payload);
    final payloadBytes = utf8.encode(payloadJson);

    // Erstelle HMAC-Signatur
    final hmacSha256 = Hmac(sha256, utf8.encode(_secretKey));
    final signature = hmacSha256.convert(payloadBytes);

    // Kombiniere Payload und Signatur
    final qrData = {
      'data': base64Encode(payloadBytes),
      'sig': signature.toString()
    };

    return base64Encode(utf8.encode(json.encode(qrData)));
  }

  /// Prüft ob StaffUser für Identity-Management berechtigt ist
  Future<int?> _getAuthenticatedStaffUserId(Session session) async {
    return await StaffAuthHelper.getAuthenticatedStaffUserId(session);
  }

  Future<bool> _isStaffUserAuthorized(Session session,
      {bool requireHighLevelAccess = false}) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) return false;

    final staffUser = await StaffUser.db.findById(session, staffUserId);
    if (staffUser == null) return false;

    if (requireHighLevelAccess) {
      // SuperUser hat alle Rechte, für andere staff members prüfe permissions
      if (staffUser.staffLevel == StaffUserType.superUser) {
        return true;
      }
      // Für normale staff members: prüfe ob sie die entsprechende Permission haben
      return await PermissionHelper.hasPermission(session, staffUserId, 'can_manage_user_identity');
    }

    return true; // Alle StaffUser sind für grundlegende Identity-Funktionen berechtigt
  }

  /// Holt die aktuelle Identität für einen Benutzer (erstellt bei Bedarf)
  Future<UserIdentity?> getCurrentUserIdentity(Session session) async {
    // 🔑 UNIFIED AUTHENTICATION SYSTEM (Phase 3.1)
    int? userId;
    String? userEmail;
    String authSource = '';

    // 1. ZUERST: Staff-Authentication prüfen (für Staff-App)
    final staffUserId = await _getAuthenticatedStaffUserId(session);
    if (staffUserId != null) {
      // Staff-User gefunden - lade den zugehörigen AppUser
      final staffUser = await StaffUser.db.findById(session, staffUserId);
      if (staffUser != null) {
        // Finde den entsprechenden AppUser basierend auf Email
        final appUser = await AppUser.db.findFirstRow(
          session,
          where: (u) => u.email.equals(staffUser.email),
        );
        if (appUser != null) {
          userId = appUser.id;
          userEmail = appUser.email;
          authSource = 'Staff-Auth';
          session.log(
              '🔑 $authSource: Staff-User ${staffUser.email} → AppUser-ID $userId');
        }
      }
    }

    // 2. FALLBACK: Client-App Authentication prüfen (für Client-App)
    if (userId == null) {
      final authInfo = await session.authenticated;
      if (authInfo != null) {
        // NEUE METHODE: Finde AppUser basierend auf userInfoId (nicht mehr Email!)
        final appUser = await AppUser.db.findFirstRow(
          session,
          where: (u) => u.userInfoId.equals(authInfo.userId),
        );
        if (appUser != null) {
          userId = appUser.id;
          userEmail = appUser.email;
          authSource = 'Client-Auth';
          session.log(
              '🔑 $authSource: UserInfo.id=${authInfo.userId} → AppUser-ID $userId ($userEmail)');
        } else {
          session.log(
              '🔑 Client-Auth FEHLER: Kein AppUser für UserInfo.id=${authInfo.userId} gefunden!',
              level: LogLevel.error);
        }
      }
    }

    // 3. VALIDIERUNG: Keine Authentication gefunden
    if (userId == null) {
      session.log(
          '🔑 Keine gültige Authentication gefunden (weder Staff noch Client)',
          level: LogLevel.error);
      return null;
    }

    try {
      // Suche nach bestehender aktiver Identität
      final existingIdentity = await UserIdentity.db.findFirstRow(
        session,
        where: (i) => i.userId.equals(userId!) & i.isActive.equals(true),
      );

      if (existingIdentity != null) {
        session.log(
            '🔑 $authSource: Bestehende Identität gefunden für User $userId ($userEmail)');
        return existingIdentity;
      }

      // Erstelle neue Identität mit kryptographischem QR-Code
      final qrCodeData = await _generateSecureQrCode(userId!);
      final newIdentity = UserIdentity(
        userId: userId!,
        qrCodeData: qrCodeData,
        qrCodeGenerated: DateTime.now().toUtc(),
        usageCount: 0,
        isActive: true,
        forceRotationAfterUsage: false,
        requiresUnlock: false,
        createdAt: DateTime.now().toUtc(),
      );

      try {
        final savedIdentity =
            await UserIdentity.db.insertRow(session, newIdentity);
        session.log(
            '🔑 $authSource: Neue Identität erstellt für User $userId ($userEmail)');
        return savedIdentity;
      } catch (e) {
        // Wenn Constraint-Fehler: Lade bestehende Identität
        if (e.toString().contains('user_identity_user_idx')) {
          session.log(
              '🔑 $authSource: Identität existiert bereits für User $userId - lade bestehende');
          return await UserIdentity.db.findFirstRow(
            session,
            where: (i) => i.userId.equals(userId!) & i.isActive.equals(true),
          );
        } else {
          rethrow;
        }
      }
    } catch (e) {
      session.log('Fehler beim Abrufen/Erstellen der Identität: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Rotiert den QR-Code nach einem erfolgreichen Check-in
  Future<UserIdentity?> rotateQrCodeAfterCheckIn(
      Session session, String qrCodeData, int facilityId) async {
    try {
      // Validiere den QR-Code
      final identityData = _validateAndParseQrCode(qrCodeData);
      if (identityData == null) {
        session.log('Ungültiger QR-Code für Check-in', level: LogLevel.warning);
        return null;
      }

      final userId = identityData['userId'] as int;

      // Finde die entsprechende Identität
      final identity = await UserIdentity.db.findFirstRow(
        session,
        where: (i) =>
            i.userId.equals(userId) &
            i.qrCodeData.equals(qrCodeData) &
            i.isActive.equals(true),
      );

      if (identity == null) {
        session.log('Aktive Identität für QR-Code nicht gefunden',
            level: LogLevel.error);
        return null;
      }

      // Markiere als verwendet
      final now = DateTime.now().toUtc();
      identity.lastUsed = now;
      identity.usageCount = identity.usageCount + 1;
      identity.updatedAt = now;
      await UserIdentity.db.updateRow(session, identity);

      // Protokolliere Check-in
      await _logCheckIn(session, identity.id!, facilityId);

      // Prüfe QR-Rotation Policy
      final rotationPolicy = await _getRotationPolicy(session, identity);
      final shouldRotate =
          await _shouldRotateAfterUsage(session, identity, rotationPolicy);

      if (shouldRotate) {
        session.log(
            'QR-Code wird nach Check-in rotiert (Policy: ${rotationPolicy['mode']})');
        return await _generateNewIdentity(session, userId);
      } else {
        session.log(
            'QR-Code-Rotation übersprungen (Policy: ${rotationPolicy['mode']})');
        return identity;
      }
    } catch (e) {
      session.log('Fehler bei QR-Code-Rotation nach Check-in: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Bestimmt ob ein QR-Code rotiert werden soll
  Future<bool> _shouldRotateQrCode(
      Session session, UserIdentity identity) async {
    final policy = await _getRotationPolicy(session, identity);
    final mode = policy['mode'] as String;

    switch (mode) {
      case ROTATION_IMMEDIATE:
        // Immer rotieren nach Nutzung
        return identity.lastUsed != null;

      case ROTATION_DAILY_USAGE:
        // Rotieren alle 24h aber nur bei Nutzung
        if (identity.lastUsed == null) return false;
        final hoursSinceGeneration =
            DateTime.now().toUtc().difference(identity.qrCodeGenerated).inHours;
        return hoursSinceGeneration >= 24;

      case ROTATION_TIME_BASED:
        // Rotieren nach bestimmter Zeit
        final intervalHours = policy['intervalHours'] as int? ?? 24;
        final hoursSinceGeneration =
            DateTime.now().toUtc().difference(identity.qrCodeGenerated).inHours;
        return hoursSinceGeneration >= intervalHours;

      case ROTATION_MANUAL:
        // Nur bei manueller Anforderung
        return identity.forceRotationAfterUsage;

      default:
        return false;
    }
  }

  /// Bestimmt ob nach Nutzung rotiert werden soll
  Future<bool> _shouldRotateAfterUsage(Session session, UserIdentity identity,
      Map<String, dynamic> policy) async {
    final mode = policy['mode'] as String;

    switch (mode) {
      case ROTATION_IMMEDIATE:
        return true; // Immer rotieren

      case ROTATION_DAILY_USAGE:
        // Nur rotieren wenn > 24h alt UND benutzt
        final hoursSinceGeneration =
            DateTime.now().toUtc().difference(identity.qrCodeGenerated).inHours;
        return hoursSinceGeneration >= 24;

      case ROTATION_TIME_BASED:
        // Nach Zeit rotieren
        final intervalHours = policy['intervalHours'] as int? ?? 24;
        final hoursSinceGeneration =
            DateTime.now().toUtc().difference(identity.qrCodeGenerated).inHours;
        return hoursSinceGeneration >= intervalHours;

      case ROTATION_MANUAL:
        return identity.forceRotationAfterUsage;

      default:
        return false;
    }
  }

  /// Holt die Rotation-Policy für eine Identität
  Future<Map<String, dynamic>> _getRotationPolicy(
      Session session, UserIdentity identity) async {
    try {
      // Versuche System-Einstellung zu laden
      // TODO: Nach SystemSetting-Model Integration

      // Fallback zu Standard-Policy
      return {
        'mode': ROTATION_DAILY_USAGE, // Standard: Täglich bei Nutzung
        'intervalHours': 24,
        'requiresUsageForRotation': true,
        'maxUsageBeforeRotation': null,
      };
    } catch (e) {
      session.log('Fehler beim Laden der Rotation-Policy: $e',
          level: LogLevel.warning);
      return {
        'mode': ROTATION_IMMEDIATE, // Sicherheits-Fallback
        'intervalHours': 1,
        'requiresUsageForRotation': false,
      };
    }
  }

  /// Setzt neue QR-Rotation-Policy (Super-Admin only)
  Future<bool> setQrRotationPolicy(
      Session session,
      String mode,
      int? intervalHours,
      bool requiresUsageForRotation,
      int? maxUsageBeforeRotation) async {
    // 🔐 RBAC SECURITY CHECK - HIGH LEVEL REQUIRED
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - QR-Policy-Änderung verweigert',
          level: LogLevel.warning);
      return false;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_manage_qr_rotation_policy');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_manage_qr_rotation_policy (User: $authUserId)',
          level: LogLevel.warning);
      return false;
    }

    final staffUserId = authUserId;

    try {
      final policy = {
        'mode': mode,
        'intervalHours': intervalHours,
        'requiresUsageForRotation': requiresUsageForRotation,
        'maxUsageBeforeRotation': maxUsageBeforeRotation,
        'lastModifiedBy': staffUserId,
        'lastModifiedAt': DateTime.now().toUtc().toIso8601String(),
      };

      session.log('QR-Rotation-Policy geändert: $mode (${intervalHours}h)');
      // TODO: In SystemSetting speichern nach Model-Generation
      return true;
    } catch (e) {
      session.log('Fehler beim Setzen der QR-Rotation-Policy: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// Holt aktuelle QR-Rotation-Policy (für Admin-UI)
  Future<Map<String, dynamic>?> getQrRotationPolicy(Session session) async {
    final userId = await _getAuthenticatedStaffUserId(session);
    if (userId == null) return null;

    final user = await AppUser.db.findById(session, userId);
    if (user == null) return null;

    try {
      // TODO: Nach SystemSetting-Integration aus DB laden
      return {
        'mode': ROTATION_DAILY_USAGE,
        'intervalHours': 24,
        'requiresUsageForRotation': true,
        'maxUsageBeforeRotation': null,
        'availableModes': [
          {
            'id': ROTATION_IMMEDIATE,
            'name': 'Nach jeder Nutzung',
            'description':
                'Höchste Sicherheit - QR-Code wird nach jedem Check-in neu generiert',
          },
          {
            'id': ROTATION_DAILY_USAGE,
            'name': 'Täglich bei Nutzung',
            'description':
                'Ausgewogen - QR-Code wird alle 24h rotiert, aber nur wenn benutzt',
          },
          {
            'id': ROTATION_TIME_BASED,
            'name': 'Zeitbasiert',
            'description':
                'Regelmäßig - QR-Code wird nach konfigurierbarer Zeit rotiert',
          },
          {
            'id': ROTATION_MANUAL,
            'name': 'Manuell',
            'description':
                'Niedrigste Sicherheit - QR-Code wird nur manuell rotiert',
          },
        ],
      };
    } catch (e) {
      session.log('Fehler beim Abrufen der QR-Rotation-Policy: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Erzwingt QR-Code-Rotation für einen User (Emergency)
  Future<UserIdentity?> forceQrRotation(
      Session session, int targetUserId) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - QR-Rotation verweigert',
          level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_force_qr_rotation');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_force_qr_rotation (User: $authUserId)',
          level: LogLevel.warning);
      return null;
    }

    try {
      session.log('Erzwungene QR-Code-Rotation für User $targetUserId');
      return await _generateNewIdentity(session, targetUserId);
    } catch (e) {
      session.log('Fehler bei erzwungener QR-Rotation: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Validiert einen QR-Code für Check-in (Staff-App)
  Future<Map<String, dynamic>?> validateIdentityQrCode(
      Session session, String qrCodeData, int facilityId) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId = await _getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - QR-Validierung verweigert',
          level: LogLevel.warning);
      return null;
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_validate_identity_qr');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_validate_identity_qr (User: $authUserId)',
          level: LogLevel.warning);
      return null;
    }

    try {
      // Parse und validiere QR-Code
      final identityData = _validateAndParseQrCode(qrCodeData);
      if (identityData == null) {
        session.log('QR-Code-Format ungültig', level: LogLevel.warning);
        return null;
      }

      final userId = identityData['userId'] as int;

      // Hole User-Informationen
      final user = await AppUser.db.findById(session, userId);
      if (user == null) {
        session.log('User mit ID $userId nicht gefunden',
            level: LogLevel.error);
        return null;
      }

      // Hole aktuelle User-Identität
      final identity = await UserIdentity.db.findFirstRow(
        session,
        where: (i) =>
            i.userId.equals(userId) &
            i.qrCodeData.equals(qrCodeData) &
            i.isActive.equals(true),
      );

      if (identity == null) {
        session.log('Identität für QR-Code nicht gefunden oder inaktiv',
            level: LogLevel.warning);
        return null;
      }

      session.log(
          'QR-Code für User ${user.firstName} ${user.lastName} erfolgreich validiert');

      return {
        'userId': userId,
        'userName': '${user.firstName} ${user.lastName}',
        'email': user.email,
        'identityId': identity.id,
        'isValid': true,
        'usageCount': identity.usageCount,
      };
    } catch (e) {
      session.log('Fehler bei QR-Code-Validierung: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Generiert eine neue Identität mit frischem QR-Code
  Future<UserIdentity> _generateNewIdentity(Session session, int userId) async {
    final now = DateTime.now().toUtc();

    // Deaktiviere alte Identitäten für diesen User
    final oldIdentities = await UserIdentity.db.find(
      session,
      where: (i) => i.userId.equals(userId) & i.isActive.equals(true),
    );

    for (final identity in oldIdentities) {
      identity.isActive = false;
      identity.updatedAt = now;
      await UserIdentity.db.updateRow(session, identity);
    }

    // Erstelle neue Identität
    final newIdentity = UserIdentity(
      userId: userId,
      qrCodeData: '', // Wird unten gesetzt
      qrCodeGenerated: now,
      lastUsed: null,
      usageCount: 0,
      isActive: true,
      // QR-Rotation Policy System
      rotationPolicyId: null,
      nextRotationDue: null,
      forceRotationAfterUsage: false,
      unlockExpiry: null, // Zunächst nicht verwendet
      requiresUnlock: false, // Für Entwicklung deaktiviert
      createdAt: now,
    );

    final savedIdentity = await UserIdentity.db.insertRow(session, newIdentity);

    // Generiere sicheren QR-Code
    final qrCodeData = _generateSecureIdentityQrCode(savedIdentity);
    savedIdentity.qrCodeData = qrCodeData;

    final updatedIdentity =
        await UserIdentity.db.updateRow(session, savedIdentity);

    session.log('Neue Identität für User $userId generiert');
    return updatedIdentity;
  }

  /// Generiert sicheren QR-Code für Identität
  String _generateSecureIdentityQrCode(UserIdentity identity) {
    final payload = {
      'type': 'user_identity',
      'id': identity.id,
      'userId': identity.userId,
      'generated': identity.qrCodeGenerated.toIso8601String(),
      'nonce': _generateNonce(),
    };

    final jsonData = jsonEncode(payload);
    final hmacSha256 = Hmac(sha256, utf8.encode(_secretKey));
    final digest = hmacSha256.convert(utf8.encode(jsonData));
    final signature = base64Url.encode(digest.bytes);
    final encodedPayload = base64Url.encode(utf8.encode(jsonData));

    return '$encodedPayload.$signature';
  }

  /// Validiert und parsed QR-Code-Daten
  Map<String, dynamic>? _validateAndParseQrCode(String qrCodeData) {
    try {
      final parts = qrCodeData.split('.');
      if (parts.length != 2) return null;

      final encodedPayload = parts[0];
      final signature = parts[1];
      final jsonData = utf8.decode(base64Url.decode(encodedPayload));

      // Signatur überprüfen
      final hmacSha256 = Hmac(sha256, utf8.encode(_secretKey));
      final digest = hmacSha256.convert(utf8.encode(jsonData));
      final expectedSignature = base64Url.encode(digest.bytes);

      if (signature != expectedSignature) {
        return null;
      }

      final payload = jsonDecode(jsonData) as Map<String, dynamic>;

      // Typ prüfen
      if (payload['type'] != 'user_identity') return null;

      return payload;
    } catch (e) {
      return null;
    }
  }

  /// Protokolliert Check-in
  Future<void> _logCheckIn(
      Session session, int identityId, int facilityId) async {
    session.log(
        'Check-in erfolgreich: Identity $identityId, Facility $facilityId',
        level: LogLevel.info);
    // Hier können Sie später DetailLogs in eine separate Tabelle schreiben
  }

  /// Generiert Nonce für zusätzliche Sicherheit
  String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Alle User-Identitäten abrufen (für Admin/Debug)
  Future<List<UserIdentity>> getAllIdentities(Session session) async {
    try {
      return await UserIdentity.db
          .find(session, orderBy: (i) => i.createdAt, orderDescending: true);
    } catch (e) {
      session.log('Fehler beim Abrufen aller Identitäten: $e',
          level: LogLevel.error);
      return [];
    }
  }
}
