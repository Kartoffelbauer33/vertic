import 'dart:math' as math;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/external_provider_service.dart';
import '../helpers/staff_auth_helper.dart';
import '../helpers/permission_helper.dart';
import '../helpers/unified_auth_helper.dart';
import '../helpers/hall_detection_helper.dart';

/// Endpoint für Fremdanbieter-Integration (Fitpass, Friction, etc.)
class ExternalProviderEndpoint extends Endpoint {
  /// Verarbeitet Check-in mit externem QR-Code (Staff-App)
  Future<ExternalCheckinResult> processExternalCheckin(
    Session session,
    String qrCodeData,
    int hallId,
  ) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Externer Check-in verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für externen Check-in');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_validate_external_providers');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_validate_external_providers (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung für externe Provider-Validierung');
    }

    try {
      session.log(
          '🔗 Externer Check-in: Hall $hallId, Staff $authUserId, QR: ${qrCodeData.substring(0, 10)}...');

      return await ExternalProviderService.processExternalCheckin(
        session,
        qrCodeData,
        hallId,
        authUserId,
      );
    } catch (e) {
      session.log('Fehler beim externen Check-in: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Verknüpft eine externe Mitgliedschaft mit einem User (Client-App)
  Future<ExternalMembershipResponse> linkExternalMembership(
    Session session,
    ExternalMembershipRequest request,
  ) async {
    // 🔐 USER AUTHENTICATION mit UnifiedAuthHelper
    final authInfo = await UnifiedAuthHelper.getAuthInfo(session);
    if (authInfo == null || authInfo.userType != UserType.client) {
      session.log(
          '❌ Client-User Authentication erforderlich für External Membership',
          level: LogLevel.warning);
      throw Exception('User-Authentication erforderlich');
    }

    final userId = authInfo.localUserId;

    try {
      session.log(
          '🔗 Verknüpfe externe Mitgliedschaft: User $userId, Provider ${request.providerName}');

      // 🎯 SMART HALL DETECTION (vereinfacht bis AppUser-Migration verfügbar)
      final hallId = await _detectHallForUser(session, userId);

      return await ExternalProviderService.linkExternalMembership(
        session,
        userId,
        hallId,
        request,
      );
    } catch (e) {
      session.log('Fehler beim Verknüpfen der Mitgliedschaft: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Holt alle verfügbaren Provider für eine Halle
  Future<List<ExternalProvider>> getHallProviders(
    Session session,
    int hallId,
  ) async {
    try {
      return await ExternalProvider.db.find(
        session,
        where: (p) => p.hallId.equals(hallId) & p.isActive.equals(true),
        orderBy: (p) => p.displayName,
      );
    } catch (e) {
      session.log('Fehler beim Laden der Hall-Provider: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Holt alle externen Mitgliedschaften eines Users
  Future<List<UserExternalMembership>> getUserMemberships(
    Session session,
    int userId,
  ) async {
    try {
      return await UserExternalMembership.db.find(
        session,
        where: (m) => m.userId.equals(userId) & m.isActive.equals(true),
        orderBy: (m) => m.createdAt,
        orderDescending: true,
      );
    } catch (e) {
      session.log('Fehler beim Laden der User-Mitgliedschaften: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Admin: Erstellt oder aktualisiert Provider-Konfiguration
  Future<ExternalProvider> configureProvider(
    Session session,
    ExternalProvider providerConfig,
  ) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Provider-Konfiguration verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Provider-Konfiguration');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_manage_external_providers');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_manage_external_providers (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung für Provider-Management');
    }

    try {
      // Audit-Informationen setzen
      final now = DateTime.now().toUtc();
      if (providerConfig.id == null) {
        // Neue Konfiguration
        providerConfig.createdBy = authUserId;
        providerConfig.createdAt = now;
      } else {
        // Update
        providerConfig.updatedBy = authUserId;
        providerConfig.updatedAt = now;
      }

      // TODO Phase 3: API-Credentials verschlüsseln vor dem Speichern (AES-256)

      if (providerConfig.id == null) {
        session.log(
            '📝 Erstelle neue Provider-Konfiguration: ${providerConfig.providerName} für Hall ${providerConfig.hallId}');
        return await ExternalProvider.db.insertRow(session, providerConfig);
      } else {
        session.log(
            '📝 Aktualisiere Provider-Konfiguration: ${providerConfig.providerName} (ID: ${providerConfig.id})');
        return await ExternalProvider.db.updateRow(session, providerConfig);
      }
    } catch (e) {
      session.log('Fehler bei Provider-Konfiguration: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Admin: Holt Check-in-Statistiken für externe Provider
  Future<List<ExternalProviderStats>> getProviderStats(
    Session session,
    int hallId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // 🔐 RBAC SECURITY CHECK
    final authUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (authUserId == null) {
      session.log('❌ Nicht eingeloggt - Provider-Statistiken verweigert',
          level: LogLevel.warning);
      throw Exception('Authentication erforderlich für Provider-Statistiken');
    }

    final hasPermission = await PermissionHelper.hasPermission(
        session, authUserId, 'can_view_provider_stats');
    if (!hasPermission) {
      session.log(
          '❌ Fehlende Berechtigung: can_view_provider_stats (User: $authUserId)',
          level: LogLevel.warning);
      throw Exception('Keine Berechtigung für Provider-Statistiken');
    }

    try {
      session.log('📊 Generiere Provider-Statistiken für Hall $hallId');

      // Einfache Statistik-Generierung aus ExternalCheckinLog
      final stats = <ExternalProviderStats>[];
      final providers = await ExternalProvider.db.find(
        session,
        where: (p) => p.hallId.equals(hallId),
      );

      for (final provider in providers) {
        // Basis-Statistiken für jeden Provider generieren
        final totalCheckins = await ExternalCheckinLog.db.count(
          session,
          where: (log) => log.hallId.equals(hallId),
        );

        final successfulCheckins = await ExternalCheckinLog.db.count(
          session,
          where: (log) =>
              log.hallId.equals(hallId) & log.accessGranted.equals(true),
        );

        final stat = ExternalProviderStats(
          providerId: provider.id!,
          providerName: provider.providerName,
          hallId: hallId,
          hallName: 'Hall $hallId', // TODO: Echten Hall-Namen laden
          totalActiveMembers: 0, // TODO: Implementiere Member-Count
          newMembersThisMonth: 0, // TODO: Implementiere neue Member
          totalCheckins: totalCheckins,
          checkinsToday: 0, // TODO: Heute's Check-ins
          checkinsThisWeek: 0, // TODO: Diese Woche's Check-ins
          checkinsThisMonth:
              totalCheckins, // Vereinfacht: alle als "diesen Monat"
          successRate:
              totalCheckins > 0 ? successfulCheckins / totalCheckins : 0.0,
          averageProcessingTimeMs:
              500, // TODO: Echte Durchschnittszeit berechnen
          peakHour: null, // TODO: Peak-Zeit analysieren
          peakDay: null, // TODO: Peak-Tag analysieren
          lastCheckinAt: null, // TODO: Letzten Check-in laden
          periodStart:
              startDate ?? DateTime.now().toUtc().subtract(Duration(days: 30)),
          periodEnd: endDate ?? DateTime.now().toUtc(),
          generatedAt: DateTime.now().toUtc(),
        );

        stats.add(stat);
      }

      return stats;
    } catch (e) {
      session.log('Fehler beim Generieren der Provider-Statistiken: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Entfernt eine externe Mitgliedschaft
  Future<bool> removeMembership(
    Session session,
    int membershipId,
  ) async {
    // 🔐 USER AUTHENTICATION
    final authInfo = await UnifiedAuthHelper.getAuthInfo(session);
    if (authInfo == null || authInfo.userType != UserType.client) {
      session.log(
          '❌ Client-User Authentication erforderlich für Membership-Entfernung',
          level: LogLevel.warning);
      throw Exception('User-Authentication erforderlich');
    }

    final userId = authInfo.localUserId;

    try {
      final membership =
          await UserExternalMembership.db.findById(session, membershipId);
      if (membership == null) {
        session.log('Mitgliedschaft $membershipId nicht gefunden',
            level: LogLevel.warning);
        return false;
      }

      // 🔒 SECURITY: Prüfe ob Mitgliedschaft dem authentifizierten User gehört
      if (membership.userId != userId) {
        session.log(
            '❌ User $userId versucht fremde Mitgliedschaft $membershipId zu entfernen',
            level: LogLevel.warning);
        throw Exception('Berechtigung verweigert');
      }

      // Soft delete: Deaktivieren statt löschen
      membership.isActive = false;
      membership.updatedAt = DateTime.now().toUtc();
      await UserExternalMembership.db.updateRow(session, membership);

      session.log('🗑️ Externe Mitgliedschaft $membershipId deaktiviert');
      return true;
    } catch (e) {
      session.log('Fehler beim Entfernen der Mitgliedschaft: $e',
          level: LogLevel.error);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎯 PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Ermittelt die beste Hall-ID für einen User
  /// Vereinfachte Implementierung bis AppUser-Migration verfügbar ist
  Future<int> _detectHallForUser(Session session, int userId) async {
    try {
      // Für jetzt: Einfache Logik basierend auf letzten Aktivitäten
      // TODO: Erweitern mit GPS, User-Präferenzen, etc. nach AppUser-Migration

      // TODO Phase 2.5: Implementiere intelligente Hall-Detection basierend auf:
      // - GPS-Koordinaten (Client-App sendet Location)
      // - User-Präferenzen (AppUser.preferredHallId nach Migration)
      // - Letzte Aktivität (Tickets, Check-ins, etc.)
      // - Registrierungs-Ort (AppUser.registrationHallId nach Migration)

      // Fallback: Default Hall (Basel)
      session.log('🏢 Default Hall (Basel) für User $userId');
      return 1; // Basel als Default
    } catch (e) {
      session.log('❌ Fehler bei Hall-Detection für User $userId: $e',
          level: LogLevel.error);
      return 1; // Fallback zu Basel
    }
  }

  /// Holt verfügbare Gyms für User-Auswahl (Client-App)
  Future<List<Gym>> getAvailableGyms(Session session) async {
    // 🔐 CLIENT USER AUTHENTICATION (optional - können auch Gäste sehen)
    try {
      session.log('🏢 Lade verfügbare Gyms für User-Auswahl');
      return await HallDetectionHelper.getAvailableGyms(session);
    } catch (e) {
      session.log('Fehler beim Laden der verfügbaren Gyms: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Holt Details zu einem spezifischen Gym (Client-App)
  Future<Gym?> getGymDetails(Session session, int gymId) async {
    try {
      session.log('🏢 Lade Details für Gym $gymId');
      return await HallDetectionHelper.getGymDetails(session, gymId);
    } catch (e) {
      session.log('Fehler beim Laden der Gym-Details: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Holt Check-in Historie für einen User (Client-App)
  Future<List<ExternalCheckinLog>> getUserCheckinHistory(
    Session session,
    int userId,
    int limit,
  ) async {
    // 🔐 USER AUTHENTICATION
    final authInfo = await UnifiedAuthHelper.getAuthInfo(session);
    if (authInfo == null || authInfo.userType != UserType.client) {
      session.log(
          '❌ Client-User Authentication erforderlich für Check-in Historie',
          level: LogLevel.warning);
      throw Exception('User-Authentication erforderlich');
    }

    final authenticatedUserId = authInfo.localUserId;

    // 🔒 SECURITY: Prüfe ob User seine eigene Historie abruft
    if (userId != authenticatedUserId) {
      session.log(
          '❌ User $authenticatedUserId versucht fremde Historie von User $userId abzurufen',
          level: LogLevel.warning);
      throw Exception('Berechtigung verweigert');
    }

    try {
      session.log('📜 Lade Check-in Historie für User $userId (Limit: $limit)');

      // Suche alle Memberships des Users
      final userMemberships = await UserExternalMembership.db.find(
        session,
        where: (m) => m.userId.equals(userId),
      );

      if (userMemberships.isEmpty) {
        return [];
      }

      final membershipIds = userMemberships.map((m) => m.id!).toList();

      // Lade Check-in Logs für alle Memberships des Users
      return await ExternalCheckinLog.db.find(
        session,
        where: (log) => log.membershipId.inSet(membershipIds.toSet()),
        orderBy: (log) => log.checkinAt,
        orderDescending: true,
        limit: limit,
      );
    } catch (e) {
      session.log('Fehler beim Laden der Check-in Historie: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Hall Detection basierend auf GPS-Koordinaten (Client-App)
  Future<Gym?> detectHallByLocation(
    Session session,
    double latitude,
    double longitude, {
    double radiusKm = 10.0,
  }) async {
    try {
      session.log(
          '🌍 GPS Hall Detection: $latitude, $longitude (Radius: ${radiusKm}km)');

      // Alle verfügbaren Gyms laden
      final gyms = await HallDetectionHelper.getAvailableGyms(session);

      // Suche nächstgelegenes Gym
      Gym? nearestGym;
      double nearestDistance = double.infinity;

      for (final gym in gyms) {
        // TODO: Gym GPS-Koordinaten aus hall_info oder gym_config laden
        // Für jetzt: Hardcoded Basel und Zürich Koordinaten
        final gymLat = gym.id == 1 ? 47.5596 : 47.3769; // Basel : Zürich
        final gymLng = gym.id == 1 ? 7.5886 : 8.5417; // Basel : Zürich

        // Distanz berechnen (Haversine-Formel vereinfacht)
        final distance = _calculateDistance(
          latitude,
          longitude,
          gymLat,
          gymLng,
        );

        if (distance <= radiusKm && distance < nearestDistance) {
          nearestDistance = distance;
          nearestGym = gym;
        }
      }

      if (nearestGym != null) {
        session.log(
            '✅ Hall erkannt: ${nearestGym.name} (${nearestDistance.toStringAsFixed(2)}km)');
      } else {
        session.log('❌ Kein Gym in ${radiusKm}km Umkreis gefunden');
      }

      return nearestGym;
    } catch (e) {
      session.log('Fehler bei GPS Hall Detection: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Berechnet Distanz zwischen zwei GPS-Koordinaten (vereinfacht)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // Vereinfachte Distanz-Berechnung (für kurze Distanzen ausreichend)
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
