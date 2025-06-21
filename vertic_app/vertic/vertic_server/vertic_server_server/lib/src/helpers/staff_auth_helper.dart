import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'dart:convert';

/// 🔐 Zentraler Staff Authentication Helper
/// 🔥 **SESSION-FIX: HTTP-Header-basierte Authentication für Staff-Tokens**
///
/// **KRITISCHE ÄNDERUNG:**
/// - Verwendet DIREKTE HTTP-Header-Extraktion für Staff-Tokens
/// - Umgeht den globalen Client-Authentication-Handler komplett
/// - Staff-App und Client-App haben getrennte Token-Systeme
/// - Serverpod 2.8 konforme Implementation ohne Konflikte
class StaffAuthHelper {
  /// **⏰ TOKEN-GÜLTIGKEIT: 7 Tage**
  static const Duration _tokenValidityDuration = Duration(days: 7);

  /// **🔐 Staff-Session mit Auth-Token setzen (DB-basiert)**
  static Future<void> setStaffSession(
      Session session, int staffUserId, String authToken) async {
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(_tokenValidityDuration);

    // Alten Token für diesen User invalidieren
    final oldTokens = await StaffToken.db.find(
      session,
      where: (t) => t.staffUserId.equals(staffUserId) & t.valid.equals(true),
    );

    for (final oldToken in oldTokens) {
      await StaffToken.db.updateRow(
        session,
        oldToken.copyWith(valid: false),
      );
    }

    // Neuen Token speichern
    final token = StaffToken(
      staffUserId: staffUserId,
      token: authToken,
      createdAt: now,
      expiresAt: expiresAt,
      valid: true,
    );
    await StaffToken.db.insertRow(session, token);
    session.log(
        '🔐 Staff-Auth-Token für User $staffUserId in DB gespeichert: ${authToken.length > 8 ? authToken.substring(0, 8) + '...' : authToken}');
  }

  /// **🔥 SESSION-FIX: Aktuell authentifizierten Staff-User ermitteln (DB-basiert)**
  static Future<int?> getAuthenticatedStaffUserId(Session session) async {
    try {
      if (session is! MethodCallSession) {
        session.log(
            '❌ Session ist nicht MethodCallSession - kein HTTP-Request verfügbar',
            level: LogLevel.warning);
        return null;
      }
      final methodCallSession = session as MethodCallSession;
      final authHeader = methodCallSession.httpRequest.headers['authorization'];
      session.log('DEBUG STAFF-AUTH: Authorization-Header: $authHeader');
      if (authHeader == null || authHeader.isEmpty) {
        session.log('❌ Kein Authorization-Header im Request gefunden',
            level: LogLevel.warning);
        return null;
      }
      String authKey;
      if (authHeader.first.startsWith('Basic ')) {
        final base64Token = authHeader.first.substring(6);
        try {
          final decodedBytes = base64Decode(base64Token);
          final decodedString = utf8.decode(decodedBytes);
          session
              .log('DEBUG STAFF-AUTH: Decoded Base64-String: $decodedString');
          if (decodedString.contains(':')) {
            final parts = decodedString.split(':');
            authKey = parts[0];
          } else {
            session.log(
                '⚠️ Kein ":" im Base64-String, verwende gesamten String als Token!');
            authKey = decodedString;
          }
        } catch (e) {
          session.log(
              '❌ Fehler beim Base64-Dekodieren des Auth-Headers: $e. Header: $authHeader',
              level: LogLevel.error);
          return null;
        }
      } else if (authHeader.first.startsWith('Bearer ')) {
        authKey = authHeader.first.substring(7);
      } else {
        authKey = authHeader.first;
      }
      // DB-Token-Validierung
      final now = DateTime.now().toUtc();
      final token = await StaffToken.db.findFirstRow(
        session,
        where: (t) =>
            t.token.equals(authKey) &
            t.valid.equals(true) &
            (t.expiresAt > now),
      );
      if (token != null) {
        // Staff-User existiert und Token ist gültig
        final staffUser =
            await StaffUser.db.findById(session, token.staffUserId);
        if (staffUser != null && staffUser.employmentStatus == 'active') {
          session.log(
              '✅ Staff-User ${token.staffUserId} authentifiziert via DB-Token');
          return token.staffUserId;
        } else {
          // Staff-User wurde gelöscht oder deaktiviert - Token invalidieren
          await StaffToken.db.updateRow(
            session,
            token.copyWith(valid: false),
          );
          session.log(
              '⚠️  Staff-User ${token.staffUserId} nicht mehr aktiv - Token invalidiert',
              level: LogLevel.warning);
          return null;
        }
      }
      session.log(
          '❌ Ungültiger oder abgelaufener Staff-Token: ${authKey.length > 8 ? authKey.substring(0, 8) + '...' : authKey}',
          level: LogLevel.warning);
      return null;
    } catch (e) {
      session.log('❌ Fehler bei Staff-Authentication: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// **🧹 Staff-User abmelden und Token invalidieren (DB-basiert)**
  static Future<void> logoutStaffUser(Session session, String authToken) async {
    final token = await StaffToken.db.findFirstRow(
      session,
      where: (t) => t.token.equals(authToken),
    );

    if (token != null) {
      await StaffToken.db.updateRow(
        session,
        token.copyWith(valid: false),
      );
      session.log('🔓 Staff-User ausgeloggt - Token invalidiert');
    }
  }

  /// **📊 Debug-Informationen**
  static Future<Map<String, dynamic>> getDebugInfo(Session session) async {
    final activeTokens = await StaffToken.db.find(
      session,
      where: (t) => t.valid.equals(true),
    );

    final timestamps = activeTokens.map((t) => t.createdAt).toList();

    return {
      'active_tokens': activeTokens.length,
      'token_timestamps': timestamps.length,
      'oldest_token': timestamps.isEmpty
          ? null
          : timestamps.reduce((a, b) => a.isBefore(b) ? a : b),
      'newest_token': timestamps.isEmpty
          ? null
          : timestamps.reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }
}
