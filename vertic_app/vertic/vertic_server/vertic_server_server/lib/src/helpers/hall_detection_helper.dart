import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// 🎯 HALL DETECTION HELPER
///
/// Ermittelt die passende Hall-ID für einen User basierend auf:
/// 1. GPS-Koordinaten (wenn verfügbar)
/// 2. User-Präferenzen (preferredHallId)
/// 3. Letzte bekannte Halle (lastKnownHallId)
/// 4. Registrierungs-Halle (registrationHallId)
/// 5. Fallback: Default Hall
class HallDetectionHelper {
  /// Hauptmethode: Ermittelt die beste Hall-ID für einen User
  static Future<int> detectHallForUser(
    Session session,
    int userId, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      // 1. GPS-basierte Erkennung (wenn Koordinaten verfügbar)
      if (latitude != null && longitude != null) {
        final gpsHallId = await _detectHallByGPS(session, latitude, longitude);
        if (gpsHallId != null) {
          session.log('📍 GPS Hall erkannt: $gpsHallId für User $userId');
          return gpsHallId;
        }
      }

      // 2. TODO Phase 2.5: User-Präferenzen aus erweiterten AppUser-Feldern
      // Nach Migration: preferredHallId, lastKnownHallId, registrationHallId

      // 3. Für jetzt: User muss auswählen (wird in Client-App implementiert)
      session.log(
          '❓ Keine GPS-Erkennung möglich - User $userId muss Gym auswählen');

      // 4. Fallback: Zeige verfügbare Gyms, Default Hall zurückgeben
      return _getDefaultHallId();
    } catch (e) {
      session.log('❌ Fehler bei Hall-Detection für User $userId: $e',
          level: LogLevel.error);
      return _getDefaultHallId();
    }
  }

  /// GPS-basierte Hall-Erkennung
  static Future<int?> _detectHallByGPS(
    Session session,
    double latitude,
    double longitude,
  ) async {
    try {
      // TODO: Implementiere GPS-Distanz-Berechnung zu allen Hallen
      // Für jetzt: Einfache Beispiel-Logik

      // Beispiel: Basel Area Detection
      if (_isInBaselArea(latitude, longitude)) {
        return 1; // Basel Hall
      }

      // Beispiel: Zürich Area Detection
      if (_isInZurichArea(latitude, longitude)) {
        return 2; // Zürich Hall
      }

      session.log(
          '📍 GPS Position ($latitude, $longitude) keiner bekannten Halle zugeordnet');
      return null;
    } catch (e) {
      session.log('❌ GPS Hall-Detection Fehler: $e', level: LogLevel.error);
      return null;
    }
  }

  /// Prüft ob Koordinaten im Basel-Bereich sind (vereinfacht)
  static bool _isInBaselArea(double lat, double lng) {
    // Basel: ~47.5596° N, 7.5886° E
    // Radius: ~10km
    const baselLat = 47.5596;
    const baselLng = 7.5886;
    const radius = 0.1; // ~10km in Grad-Näherung

    return (lat - baselLat).abs() < radius && (lng - baselLng).abs() < radius;
  }

  /// Prüft ob Koordinaten im Zürich-Bereich sind (vereinfacht)
  static bool _isInZurichArea(double lat, double lng) {
    // Zürich: ~47.3769° N, 8.5417° E
    const zurichLat = 47.3769;
    const zurichLng = 8.5417;
    const radius = 0.1; // ~10km in Grad-Näherung

    return (lat - zurichLat).abs() < radius && (lng - zurichLng).abs() < radius;
  }

  // Entfernt da nicht verwendet bis Phase 2.5 AppUser-Migration
  // TODO Phase 2.5: _updateUserHallPreference implementieren

  /// Prüft ob eine Hall-ID existiert und aktiv ist
  static Future<bool> _isValidHall(Session session, int hallId) async {
    try {
      final gym = await Gym.db.findById(session, hallId);
      return gym != null; // TODO: Erweitern um isActive-Check falls vorhanden
    } catch (e) {
      session.log('❌ Hall-Validierung fehlgeschlagen für Hall $hallId: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// Default Hall-ID (für Fallback-Fälle)
  static int _getDefaultHallId() {
    return 1; // Basel als Default
  }

  /// Holt alle verfügbaren Gyms für User-Auswahl (wenn GPS nicht funktioniert)
  static Future<List<Gym>> getAvailableGyms(Session session) async {
    try {
      final gyms = await Gym.db.find(
        session,
        where: (g) => g.isActive.equals(true),
        orderBy: (g) => g.name,
      );

      session.log('🏢 ${gyms.length} verfügbare Gyms geladen für User-Auswahl');
      return gyms;
    } catch (e) {
      session.log('❌ Fehler beim Laden der verfügbaren Gyms: $e',
          level: LogLevel.error);
      return [];
    }
  }

  /// Ermittelt Gym-Details für eine Hall-ID
  static Future<Gym?> getGymDetails(Session session, int hallId) async {
    try {
      final gym = await Gym.db.findById(session, hallId);
      if (gym == null) {
        session.log('⚠️ Gym mit ID $hallId nicht gefunden',
            level: LogLevel.warning);
      }
      return gym;
    } catch (e) {
      session.log('❌ Fehler beim Laden von Gym $hallId: $e',
          level: LogLevel.error);
      return null;
    }
  }

  /// Aktualisiert lastKnownHallId nach erfolgreichem Check-in
  /// TODO Phase 2.5: Nach AppUser-Migration implementieren
  static Future<void> updateLastKnownHall(
    Session session,
    int userId,
    int hallId,
  ) async {
    // TODO: Nach AppUser-Migration mit lastKnownHallId implementieren
    session.log('🕒 TODO: User $userId lastKnownHallId aktualisieren: $hallId');
  }

  /// Setzt User-Hall-Präferenz manuell (z.B. via App-Settings)
  /// TODO Phase 2.5: Nach AppUser-Migration implementieren
  static Future<bool> setUserHallPreference(
    Session session,
    int userId,
    int hallId,
  ) async {
    try {
      // Validierung
      final isValidHall = await _isValidHall(session, hallId);
      if (!isValidHall) {
        session.log('❌ Ungültige Hall-ID: $hallId', level: LogLevel.warning);
        return false;
      }

      // TODO: Nach AppUser-Migration mit preferredHallId implementieren
      session.log('⭐ TODO: User $userId Hall-Präferenz setzen: $hallId');
      return true;
    } catch (e) {
      session.log('❌ Fehler beim Setzen der Hall-Präferenz: $e',
          level: LogLevel.error);
      return false;
    }
  }
}
