import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// **PermissionHelper - Zentrale RBAC-Logik**
///
/// Stellt alle Methoden für Permission-Checks bereit:
/// - hasPermission() - Einzelne Permission prüfen
/// - getUserPermissions() - Alle User-Permissions laden
/// - hasAnyPermission() - OR-Verknüpfung mehrerer Permissions
/// - hasAllPermissions() - AND-Verknüpfung mehrerer Permissions
/// - Caching für Performance-Optimierung
class PermissionHelper {
  /// **Cache für User-Permissions (Performance-Optimierung)**
  /// Key: staffUserId, Value: Set<String> permissionNames
  static final Map<int, Set<String>> _permissionCache = {};

  /// **Cache-Gültigkeitsdauer in Minuten**
  static const int _cacheValidityMinutes = 10;

  /// **Cache-Zeitstempel für Invalidierung**
  static final Map<int, DateTime> _cacheTimestamps = {};

  // ═══════════════════════════════════════════════════════════════
  // 🔍 HAUPT-PERMISSION-CHECK METHODEN
  // ═══════════════════════════════════════════════════════════════

  /// **Prüft ob ein StaffUser eine spezifische Permission hat**
  static Future<bool> hasPermission(
    Session session,
    int staffUserId,
    String permissionName, {
    bool useCache = true,
  }) async {
    try {
      // Cache-Check (Performance-Optimierung)
      if (useCache && _isCacheValid(staffUserId)) {
        final cachedPermissions = _permissionCache[staffUserId];
        if (cachedPermissions != null) {
          return cachedPermissions.contains(permissionName);
        }
      }

      final allPermissions =
          await _loadAllUserPermissions(session, staffUserId);

      // Cache aktualisieren
      if (useCache) {
        _updateCache(staffUserId, allPermissions);
      }

      return allPermissions.contains(permissionName);
    } catch (e) {
      session.log(
          'ERROR: PermissionHelper.hasPermission failed for staffUserId=$staffUserId, permission=$permissionName: $e');
      return false; // Fail-safe: Bei Fehler keine Permission gewähren
    }
  }

  /// **Lädt alle Permissions eines StaffUsers**
  ///
  /// **NEUE LOGIK (Phase 2.2):**
  /// 1. Prüft den ultra-schnellen Session-Cache (`session.caches.local`).
  /// 2. Wenn nichts gefunden, wird der globale, zeitgesteuerte Cache geprüft.
  /// 3. Wenn immer noch nichts, werden die Daten von der DB geladen.
  /// 4. Das Ergebnis wird im Session-Cache für die Dauer der Session gespeichert.
  static Future<Set<String>> getUserPermissions(
    Session session,
    int staffUserId, {
    bool useCache = true,
  }) async {
    const sessionCacheKey = 'user_permissions_cache_item';

    try {
      if (useCache) {
        // 1. Prüfe den schnellen Session-Cache
        final PermissionCacheItem? sessionCachedItem = await session
            .caches.local
            .get<PermissionCacheItem>(sessionCacheKey);
        if (sessionCachedItem != null) {
          return sessionCachedItem.permissionNames.toSet();
        }

        // 2. Prüfe den globalen, zeitgesteuerten Cache
        if (_isCacheValid(staffUserId)) {
          final cachedPermissions = _permissionCache[staffUserId];
          if (cachedPermissions != null) {
            // Fülle den Session-Cache für die nächste Abfrage
            final itemToCache = PermissionCacheItem(
                permissionNames: cachedPermissions.toList());
            await session.caches.local
                .put(sessionCacheKey, itemToCache, lifetime: null);
            return Set.from(cachedPermissions);
          }
        }
      }

      // 3. Lade von der Datenbank, wenn in keinem Cache gefunden
      final allPermissions =
          await _loadAllUserPermissions(session, staffUserId);

      // 4. Aktualisiere beide Caches
      if (useCache) {
        _updateCache(staffUserId, allPermissions);
        final itemToCache =
            PermissionCacheItem(permissionNames: allPermissions.toList());
        await session.caches.local
            .put(sessionCacheKey, itemToCache, lifetime: null);
      }

      return allPermissions;
    } catch (e) {
      session.log(
          'ERROR: PermissionHelper.getUserPermissions failed for staffUserId=$staffUserId: $e');
      return <String>{}; // Fail-safe: Leeres Set zurückgeben
    }
  }

  /// **Prüft ob StaffUser MINDESTENS EINE der angegebenen Permissions hat (OR)**
  static Future<bool> hasAnyPermission(
    Session session,
    int staffUserId,
    List<String> permissionNames, {
    bool useCache = true,
  }) async {
    if (permissionNames.isEmpty) return false;

    try {
      final userPermissions =
          await getUserPermissions(session, staffUserId, useCache: useCache);
      return permissionNames
          .any((permission) => userPermissions.contains(permission));
    } catch (e) {
      session.log(
          'ERROR: PermissionHelper.hasAnyPermission failed for staffUserId=$staffUserId: $e');
      return false;
    }
  }

  /// **Prüft ob StaffUser ALLE angegebenen Permissions hat (AND)**
  static Future<bool> hasAllPermissions(
    Session session,
    int staffUserId,
    List<String> permissionNames, {
    bool useCache = true,
  }) async {
    if (permissionNames.isEmpty) return true;

    try {
      final userPermissions =
          await getUserPermissions(session, staffUserId, useCache: useCache);
      return permissionNames
          .every((permission) => userPermissions.contains(permission));
    } catch (e) {
      session.log(
          'ERROR: PermissionHelper.hasAllPermissions failed for staffUserId=$staffUserId: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🗄️ CACHE-MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  static bool _isCacheValid(int staffUserId) {
    final timestamp = _cacheTimestamps[staffUserId];
    if (timestamp == null) return false;

    final now = DateTime.now();
    final difference = now.difference(timestamp).inMinutes;

    return difference < _cacheValidityMinutes;
  }

  static void _updateCache(int staffUserId, Set<String> permissions) {
    _permissionCache[staffUserId] = Set.from(permissions);
    _cacheTimestamps[staffUserId] = DateTime.now();
  }

  /// **Invalidiert den Cache für einen spezifischen User (BEIDE CACHES)**
  /// Wird aufgerufen, wenn sich die Rollen/Permissions eines Users ändern.
  static Future<void> invalidateUserCache(
      Session session, int staffUserId) async {
    _permissionCache.remove(staffUserId);
    _cacheTimestamps.remove(staffUserId);
    await session.caches.local.invalidateKey('user_permissions_cache_item');
    session.log('RBAC Cache invalidiert für User ID: $staffUserId',
        level: LogLevel.info);
  }

  /// **Invalidiert den gesamten globalen Permission-Cache**
  static void invalidateAllGlobalCache() {
    _permissionCache.clear();
    _cacheTimestamps.clear();
  }

  // ═══════════════════════════════════════════════════════════════
  // 🛡️ CONVENIENCE-METHODEN FÜR ENDPOINTS
  // ═══════════════════════════════════════════════════════════════

  /// **Extrahiert StaffUser ID aus AuthenticationInfo und prüft Permission**
  static Future<bool> checkStaffPermission(
    Session session,
    AuthenticationInfo? authInfo,
    String permissionName,
  ) async {
    if (authInfo?.userId == null) return false;

    try {
      return await hasPermission(session, authInfo!.userId!, permissionName);
    } catch (e) {
      session.log('ERROR: PermissionHelper.checkStaffPermission failed: $e');
      return false;
    }
  }

  /// **Wirft Exception wenn Permission fehlt**
  static Future<void> requirePermission(
    Session session,
    int staffUserId,
    String permissionName, {
    String? customMessage,
  }) async {
    final hasAccess = await hasPermission(session, staffUserId, permissionName);

    if (!hasAccess) {
      throw Exception(customMessage ??
          'Access denied: Permission "$permissionName" required for staffUserId=$staffUserId');
    }
  }

  /// **Require Permission mit AuthInfo - returns StaffUser ID**
  static Future<int> requireStaffPermission(
    Session session,
    AuthenticationInfo? authInfo,
    String permissionName, {
    String? customMessage,
  }) async {
    if (authInfo?.userId == null) {
      throw Exception('Authentication required');
    }

    await requirePermission(session, authInfo!.userId!, permissionName,
        customMessage: customMessage);

    return authInfo!.userId!;
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔧 PRIVATE HELPER METHODEN
  // ═══════════════════════════════════════════════════════════════

  /// **Lädt alle Permissions eines Users aus DB (ohne Cache)**
  static Future<Set<String>> _loadAllUserPermissions(
      Session session, int staffUserId) async {
    final now = DateTime.now();

    try {
      // 1. Direkte Permissions laden (StaffUserPermission) - VEREINFACHT
      final directPermissionAssignments = await StaffUserPermission.db.find(
        session,
        where: (t) => t.staffUserId.equals(staffUserId),
      );

      final directPermissionIds = <int>[];
      for (final sp in directPermissionAssignments) {
        // Prüfe Gültigkeit UND isActive Flag
        if (sp.isActive &&
            (sp.expiresAt == null || sp.expiresAt!.isAfter(now))) {
          directPermissionIds.add(sp.permissionId);
        }
      }

      // Lade Permission-Namen separat
      final directPermissionNames = <String>{};
      if (directPermissionIds.isNotEmpty) {
        final permissions = await Permission.db.find(
          session,
          where: (t) => t.id.inSet(directPermissionIds.toSet()),
        );
        directPermissionNames.addAll(permissions.map((p) => p.name));
      }

      // 2. Rollen-basierte Permissions laden - VEREINFACHT
      final staffRoleAssignments = await StaffUserRole.db.find(
        session,
        where: (t) => t.staffUserId.equals(staffUserId),
      );

      final activeRoleIds = <int>[];
      for (final sr in staffRoleAssignments) {
        // Prüfe Gültigkeit
        if (sr.isActive &&
            (sr.expiresAt == null || sr.expiresAt!.isAfter(now))) {
          activeRoleIds.add(sr.roleId);
        }
      }

      final rolePermissionNames = <String>{};
      if (activeRoleIds.isNotEmpty) {
        // Lade RolePermissions für aktive Rollen
        final rolePermissions = await RolePermission.db.find(
          session,
          where: (t) => t.roleId.inSet(activeRoleIds.toSet()),
        );

        final rolePermissionIds =
            rolePermissions.map((rp) => rp.permissionId).toSet();

        if (rolePermissionIds.isNotEmpty) {
          final permissions = await Permission.db.find(
            session,
            where: (t) => t.id.inSet(rolePermissionIds),
          );
          rolePermissionNames.addAll(permissions.map((p) => p.name));
        }
      }

      // Alle Permissions kombinieren
      final allPermissions = {...directPermissionNames, ...rolePermissionNames};

      session.log(
          '🔍 User $staffUserId permissions loaded: ${allPermissions.join(", ")}');
      return allPermissions;
    } catch (e) {
      session.log(
          'ERROR: _loadAllUserPermissions failed for staffUserId=$staffUserId: $e');
      return <String>{};
    }
  }
}
