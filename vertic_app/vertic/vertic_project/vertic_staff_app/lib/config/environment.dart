/// Environment-Konfiguration für verschiedene Server-Endpunkte
class Environment {
  // Lokaler Entwicklungsserver
  static const String _localServer = 'http://localhost:8080/';

  // Hetzner VPS Staging-Server
  static const String _stagingServer = 'http://159.69.144.208:8080/';

  /// Aktueller Server-URL basierend auf Dart-Define Parameter
  ///
  /// Verwendung:
  /// - Lokal: `flutter run` (verwendet localhost)
  /// - Staging: `flutter run --dart-define=USE_STAGING=true`
  /// - Custom: `flutter run --dart-define=SERVER_URL=http://custom-url:8080/`
  static String get serverUrl {
    // Prüfe zuerst ob eine custom URL gesetzt ist
    const customUrl = String.fromEnvironment('SERVER_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }

    // Prüfe ob Staging-Modus aktiviert ist
    const useStaging = bool.fromEnvironment('USE_STAGING', defaultValue: false);
    if (useStaging) {
      return _stagingServer;
    }

    // Default: Lokaler Server
    return _localServer;
  }

  /// Hilfsmethoden für verschiedene Modi
  static bool get isLocal => serverUrl.contains('localhost');
  static bool get isStaging => serverUrl.contains('159.69.144.208');
  static bool get isSecure => serverUrl.startsWith('https://');

  /// Debug-Info für Entwicklung
  static String get environmentInfo {
    if (isLocal) return 'Lokal (localhost)';
    if (isStaging) return 'Staging (Hetzner VPS)';
    return 'Custom ($serverUrl)';
  }
}
