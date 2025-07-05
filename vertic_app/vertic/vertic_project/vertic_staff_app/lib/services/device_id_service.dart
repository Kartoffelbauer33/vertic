import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 🖥️ Service für gerätespezifische Identifikation
///
/// Generiert und verwaltet eine eindeutige Geräte-ID, die über
/// App-Neustarts und User-Wechsel hinweg persistent ist.
class DeviceIdService {
  static DeviceIdService? _instance;
  static DeviceIdService get instance => _instance ??= DeviceIdService._();

  DeviceIdService._();

  String? _cachedDeviceId;
  static const String _deviceIdKey = 'vertic_pos_device_id';

  /// Eindeutige Geräte-ID abrufen oder generieren
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();

    // Versuche gespeicherte Device-ID zu laden
    String? storedDeviceId = prefs.getString(_deviceIdKey);

    if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
      _cachedDeviceId = storedDeviceId;
      debugPrint(
        '🖥️ Gespeicherte Device-ID wiederhergestellt: $storedDeviceId',
      );
      return storedDeviceId;
    }

    // Neue Device-ID generieren
    String newDeviceId = await _generateDeviceId();

    // Device-ID speichern
    await prefs.setString(_deviceIdKey, newDeviceId);
    _cachedDeviceId = newDeviceId;

    debugPrint('🆕 Neue Device-ID generiert und gespeichert: $newDeviceId');
    return newDeviceId;
  }

  /// Generiert eine eindeutige Geräte-ID basierend auf Hardware-Informationen
  Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String baseId = '';

    try {
      if (kIsWeb) {
        // Web: Browser-basierte ID
        final webInfo = await deviceInfo.webBrowserInfo;
        baseId =
            'web_${webInfo.userAgent?.hashCode ?? DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isWindows) {
        // Windows: Computer-Name + Username
        final windowsInfo = await deviceInfo.windowsInfo;
        baseId = 'win_${windowsInfo.computerName}_${windowsInfo.userName}';
      } else if (Platform.isLinux) {
        // Linux: Machine-ID
        final linuxInfo = await deviceInfo.linuxInfo;
        baseId = 'linux_${linuxInfo.machineId ?? linuxInfo.name}';
      } else if (Platform.isMacOS) {
        // macOS: Computer-Name + Model
        final macInfo = await deviceInfo.macOsInfo;
        baseId = 'mac_${macInfo.computerName}_${macInfo.model}';
      } else if (Platform.isAndroid) {
        // Android: Device-ID
        final androidInfo = await deviceInfo.androidInfo;
        baseId = 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        // iOS: Identifier for Vendor
        final iosInfo = await deviceInfo.iosInfo;
        baseId = 'ios_${iosInfo.identifierForVendor ?? iosInfo.name}';
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Abrufen der Device-Info: $e');
      // Fallback: Timestamp-basierte ID
      baseId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Zusätzlicher Prefix für POS-System
    return 'vertic_pos_$baseId';
  }

  /// Device-ID zurücksetzen (für Testing/Debug)
  Future<void> resetDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    _cachedDeviceId = null;
    debugPrint('🔄 Device-ID zurückgesetzt');
  }

  /// Aktuelle Device-ID anzeigen (für Debug/Support)
  Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceId = await getDeviceId();
    final deviceInfo = DeviceInfoPlugin();

    Map<String, dynamic> info = {
      'deviceId': deviceId,
      'platform': Platform.operatingSystem,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        info.addAll({
          'computerName': windowsInfo.computerName,
          'userName': windowsInfo.userName,
          'systemMemory': windowsInfo.systemMemoryInMegabytes,
          'osName': windowsInfo.displayVersion,
          'hostName': windowsInfo.computerName,
        });
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        info.addAll({
          'hostName': linuxInfo.name,
          'osName': linuxInfo.prettyName,
          'machineId': linuxInfo.machineId,
        });
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        info.addAll({
          'hostName': macInfo.computerName,
          'osName': macInfo.osRelease,
          'model': macInfo.model,
        });
      } else if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        info.addAll({
          'browserName': webInfo.browserName?.name,
          'userAgent': webInfo.userAgent,
          'platform': webInfo.platform,
        });
      }
    } catch (e) {
      info['error'] = e.toString();
    }

    return info;
  }
}
