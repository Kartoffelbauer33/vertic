import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as auth;
import '../generated/protocol.dart';

/// 🎯 **UNIFIED AUTHENTICATION HELPER (Phase 3.1)**
///
/// **ZIEL:** Ersetzt das komplizierte Hybrid-Authentication-System
/// **LÖSUNG:** Einheitliche Authentifizierung über Serverpod 2.8 native Auth
/// **VORTEILE:**
/// - Ein einziger `session.authenticated` Check für alle Endpoints
/// - Scope-basierte Berechtigungsunterscheidung ('staff' vs 'client')
/// - Getrennte Tabellen (StaffUser, AppUser) bleiben erhalten
/// - RBAC-System funktioniert weiterhin vollständig
///
/// **MIGRATION DER BESTEHENDEN ENDPOINTS:**
/// Bestehende Endpoints können stufenweise migriert werden:
/// 1. `_getAuthenticatedStaffUserId()` → `UnifiedAuthHelper.getAuthenticatedUserId()`
/// 2. Hybrid-Logic → `UnifiedAuthHelper.getAuthInfo()`
/// 3. Email-based lookups → `userInfoId`-based lookups
class UnifiedAuthHelper {
  /// **SCOPES für Berechtigungsunterscheidung**
  static const String STAFF_SCOPE = 'staff';
  static const String CLIENT_SCOPE = 'client';

  // ═══════════════════════════════════════════════════════════════
  // 🔍 AUTHENTICATION DETECTION & INFO
  // ═══════════════════════════════════════════════════════════════

  /// **Unified Authentication Info**
  ///
  /// Ersetzt die komplizierte Hybrid-Authentication-Logic in allen Endpoints
  /// Gibt einheitliche User-Info basierend auf Serverpod Auth zurück
  static Future<UnifiedAuthInfo?> getAuthInfo(Session session) async {
    try {
      final authInfo = await session.authenticated;

      if (authInfo == null) {
        return null;
      }

      // Scopes sind noch nicht implementiert in der aktuellen Version
      // TODO: Sobald Serverpod 2.8 Scopes unterstützt, hier prüfen
      // For now: Staff Detection über userIdentifier Pattern
      final userIdentifier = authInfo.userIdentifier;

      if (userIdentifier.endsWith('@staff.vertic.local')) {
        // Staff-User erkannt
        final staffUser = await StaffUser.db.findFirstRow(
          session,
          where: (t) => t.userInfoId.equals(authInfo.userId!),
        );

        if (staffUser != null) {
          return UnifiedAuthInfo(
            isAuthenticated: true,
            userType: UserType.staff,
            localUserId: staffUser.id!,
            serverpodUserId: authInfo.userId!,
            userIdentifier: authInfo.userIdentifier,
            email: staffUser.email,
            staffUser: staffUser,
            appUser: null,
          );
        }
      } else {
        // Client-User erkannt
        final appUser = await AppUser.db.findFirstRow(
          session,
          where: (t) => t.userInfoId.equals(authInfo.userId!),
        );

        if (appUser != null) {
          return UnifiedAuthInfo(
            isAuthenticated: true,
            userType: UserType.client,
            localUserId: appUser.id!,
            serverpodUserId: authInfo.userId!,
            userIdentifier: authInfo.userIdentifier,
            email: appUser.email ?? '',
            staffUser: null,
            appUser: appUser,
          );
        }
      }

      // User authenticated aber nicht in lokalen Tabellen gefunden
      session.log(
        'WARNING: Authenticated user ${authInfo.userId} not found in local tables',
        level: LogLevel.warning,
      );
      return null;
    } catch (e, stackTrace) {
      session.log('❌ Fehler in getAuthInfo: $e', level: LogLevel.error);
      session.log('Stack: $stackTrace', level: LogLevel.debug);
      return null;
    }
  }

  /// **Vereinfachter Authenticated User ID Check**
  ///
  /// Ersetzt die `_getAuthenticatedStaffUserId()` Methode in bestehenden Endpoints
  /// Gibt die lokale User-ID zurück (StaffUser.id oder AppUser.id)
  static Future<int?> getAuthenticatedUserId(Session session) async {
    final authInfo = await getAuthInfo(session);
    return authInfo?.localUserId;
  }

  /// **Staff-User Check**
  ///
  /// Prüft ob der authentifizierte User ein Staff-User ist
  static Future<bool> isStaffUser(Session session) async {
    final authInfo = await getAuthInfo(session);
    return authInfo?.userType == UserType.staff;
  }

  /// **Client-User Check**
  ///
  /// Prüft ob der authentifizierte User ein Client-User ist
  static Future<bool> isClientUser(Session session) async {
    final authInfo = await getAuthInfo(session);
    return authInfo?.userType == UserType.client;
  }

  /// **Staff-User Info**
  ///
  /// Gibt StaffUser-Objekt zurück (nur wenn Staff authenticated)
  static Future<StaffUser?> getAuthenticatedStaffUser(Session session) async {
    final authInfo = await getAuthInfo(session);
    return authInfo?.staffUser;
  }

  /// **Client-User Info**
  ///
  /// Gibt AppUser-Objekt zurück (nur wenn Client authenticated)
  static Future<AppUser?> getAuthenticatedAppUser(Session session) async {
    final authInfo = await getAuthInfo(session);
    return authInfo?.appUser;
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔄 MIGRATION HELPERS (Backward Compatibility)
  // ═══════════════════════════════════════════════════════════════

  /// **Legacy Staff Auth Helper (Deprecated)**
  ///
  /// Temporärer Compatibility-Helper für bestehende Endpoints
  /// TODO: Alle Endpoints auf `getAuthenticatedUserId()` migrieren
  @Deprecated('Use UnifiedAuthHelper.getAuthenticatedUserId() instead')
  static Future<int?> getAuthenticatedStaffUserId(Session session) async {
    final authInfo = await getAuthInfo(session);
    if (authInfo?.userType == UserType.staff) {
      return authInfo!.localUserId;
    }
    return null;
  }

  /// **Legacy Hybrid Auth Helper (Deprecated)**
  ///
  /// Temporärer Compatibility-Helper für komplexe bestehende Endpoints
  /// TODO: Alle Endpoints auf `getAuthInfo()` migrieren
  @Deprecated('Use UnifiedAuthHelper.getAuthInfo() instead')
  static Future<Map<String, dynamic>> getLegacyHybridAuthInfo(
      Session session) async {
    final authInfo = await getAuthInfo(session);

    if (authInfo == null) {
      return {
        'userId': null,
        'userEmail': null,
        'authSource': null,
        'userType': null,
      };
    }

    return {
      'userId': authInfo.localUserId,
      'userEmail': authInfo.email,
      'authSource':
          authInfo.userType == UserType.staff ? 'Staff-Auth' : 'Client-Auth',
      'userType': authInfo.userType.toString(),
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔍 UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  /// **Debug Auth Status**
  ///
  /// Zeigt aktuellen Authentication-Status für Debugging
  static Future<Map<String, dynamic>> debugAuthStatus(Session session) async {
    final serverpodAuth = await session.authenticated;
    final unifiedAuth = await getAuthInfo(session);

    return {
      'serverpod_auth': {
        'authenticated': serverpodAuth != null,
        'userId': serverpodAuth?.userId,
        'userIdentifier': serverpodAuth?.userIdentifier,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'unified_auth': unifiedAuth?.toJson(),
    };
  }

  /// **User Lookup by Email (Cross-App)**
  ///
  /// Findet User (Staff oder Client) basierend auf Email
  /// Nützlich für Cross-App-Funktionalitäten
  static Future<UnifiedUserLookup?> findUserByEmail(
      Session session, String email) async {
    try {
      // Suche in StaffUser-Tabelle
      final staffUser = await StaffUser.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );

      if (staffUser != null) {
        return UnifiedUserLookup(
          userType: UserType.staff,
          localUserId: staffUser.id!,
          email: staffUser.email,
          staffUser: staffUser,
          appUser: null,
        );
      }

      // Suche in AppUser-Tabelle
      final appUser = await AppUser.db.findFirstRow(
        session,
        where: (t) => t.email.equals(email),
      );

      if (appUser != null) {
        return UnifiedUserLookup(
          userType: UserType.client,
          localUserId: appUser.id!,
          email: appUser.email ?? email,
          staffUser: null,
          appUser: appUser,
        );
      }

      return null;
    } catch (e) {
      session.log('❌ Fehler in findUserByEmail: $e', level: LogLevel.error);
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 📋 DATA CLASSES
// ═══════════════════════════════════════════════════════════════

/// **Unified Authentication Info**
///
/// Einheitliche Authentication-Information für beide App-Typen
class UnifiedAuthInfo {
  final bool isAuthenticated;
  final UserType userType;
  final int localUserId; // StaffUser.id oder AppUser.id
  final int serverpodUserId; // UserInfo.id aus Serverpod Auth
  final String userIdentifier; // Username oder Email
  final String email;
  final StaffUser? staffUser; // Nur für Staff-User gefüllt
  final AppUser? appUser; // Nur für Client-User gefüllt

  UnifiedAuthInfo({
    required this.isAuthenticated,
    required this.userType,
    required this.localUserId,
    required this.serverpodUserId,
    required this.userIdentifier,
    required this.email,
    this.staffUser,
    this.appUser,
  });

  Map<String, dynamic> toJson() => {
        'isAuthenticated': isAuthenticated,
        'userType': userType.toString(),
        'localUserId': localUserId,
        'serverpodUserId': serverpodUserId,
        'userIdentifier': userIdentifier,
        'email': email,
        'staffUser': staffUser?.toJson(),
        'appUser': appUser?.toJson(),
      };
}

/// **User Type Enum**
enum UserType {
  staff,
  client,
}

/// **Unified User Lookup**
///
/// Für Cross-App User-Suchen (z.B. Email-basiert)
class UnifiedUserLookup {
  final UserType userType;
  final int localUserId;
  final String email;
  final StaffUser? staffUser;
  final AppUser? appUser;

  UnifiedUserLookup({
    required this.userType,
    required this.localUserId,
    required this.email,
    this.staffUser,
    this.appUser,
  });
}
