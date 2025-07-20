import 'package:flutter/material.dart';
import '../services/device_id_service.dart';

/// **🖥️ POS DEVICE INFO DIALOG WIDGET**
///
/// Eigenständige UI-Komponente für Geräte-Informationen-Dialog im POS-System:
/// - ✅ Service-Integration für Geräte-Informationen
/// - ✅ Reset-Funktion mit Feedback
/// - ✅ Callback-basierte Interaktion (keine Logik-Änderungen)
/// - ✅ Vollständige Fehlerbehandlung
/// - ✅ Responsive Layout mit ScrollView
/// - ✅ Dynamische Anzeige verfügbarer Informationen
class PosDeviceInfoDialogWidget extends StatelessWidget {
  const PosDeviceInfoDialogWidget({super.key});

  /// **🖥️ STATISCHE METHODE: Dialog anzeigen**
  static Future<void> show(BuildContext context) async {
    try {
      final deviceInfo = await DeviceIdService.instance.getDeviceInfo();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => PosDeviceInfoDialogWidget._buildDialog(
            context: context,
            deviceInfo: deviceInfo,
          ),
        );
      }
    } catch (e) {
      debugPrint('Fehler beim Anzeigen der Geräte-Info: $e');
    }
  }

  /// **🏗️ PRIVATER DIALOG-BUILDER**
  static Widget _buildDialog({
    required BuildContext context,
    required Map<String, dynamic> deviceInfo,
  }) {
    return AlertDialog(
      title: const Text('🖥️ Geräte-Information'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Geräte-ID: ${deviceInfo['deviceId']}'),
            const SizedBox(height: 8),
            Text('Plattform: ${deviceInfo['platform']}'),
            const SizedBox(height: 8),
            Text('Erstellt: ${deviceInfo['timestamp']}'),
            if (deviceInfo['hostName'] != null) ...[
              const SizedBox(height: 8),
              Text('Host: ${deviceInfo['hostName']}'),
            ],
            if (deviceInfo['computerName'] != null) ...[
              const SizedBox(height: 8),
              Text('Computer: ${deviceInfo['computerName']}'),
            ],
            if (deviceInfo['userName'] != null) ...[
              const SizedBox(height: 8),
              Text('User: ${deviceInfo['userName']}'),
            ],
            if (deviceInfo['osName'] != null) ...[
              const SizedBox(height: 8),
              Text('OS: ${deviceInfo['osName']}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () async {
            await _performDeviceReset(context);
          },
          child: const Text('Reset'),
        ),
      ],
    );
  }

  /// **🔄 PRIVATE RESET-FUNKTION**
  static Future<void> _performDeviceReset(BuildContext context) async {
    try {
      await DeviceIdService.instance.resetDeviceId();
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Geräte-ID zurückgesetzt'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dieser Widget wird nicht direkt verwendet, sondern über die statische show() Methode
    return const SizedBox.shrink();
  }
}
