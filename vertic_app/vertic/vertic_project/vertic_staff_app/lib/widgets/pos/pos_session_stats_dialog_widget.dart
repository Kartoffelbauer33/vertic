import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';

/// **📊 POS SESSION STATS DIALOG WIDGET**
///
/// Eigenständige UI-Komponente für Session-Statistiken-Dialog im POS-System:
/// - ✅ Backend-Integration für Session-Statistiken
/// - ✅ Bereinigungsfunktion mit Feedback
/// - ✅ Callback-basierte Interaktion (keine Logik-Änderungen)
/// - ✅ Vollständige Fehlerbehandlung
/// - ✅ Responsive Layout mit ScrollView
class PosSessionStatsDialogWidget extends StatelessWidget {
  const PosSessionStatsDialogWidget({super.key});

  /// **📊 STATISCHE METHODE: Dialog anzeigen**
  static Future<void> show(BuildContext context) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final stats = await client.pos.getSessionStats();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => PosSessionStatsDialogWidget._buildDialog(
            context: context,
            stats: stats,
            client: client,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Laden der Statistiken: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// **🏗️ PRIVATER DIALOG-BUILDER**
  static Widget _buildDialog({
    required BuildContext context,
    required Map<String, dynamic> stats,
    required Client client,
  }) {
    return AlertDialog(
      title: const Text('📊 Session-Statistiken'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📋 Total Sessions: ${stats['total']}'),
            const SizedBox(height: 8),
            Text('✅ Aktive Sessions: ${stats['active']}'),
            Text('💰 Bezahlte Sessions: ${stats['completed']}'),
            Text('🗑️ Abandoned Sessions: ${stats['abandoned']}'),
            const SizedBox(height: 8),
            Text('👤 Mit Kunde: ${stats['with_customer']}'),
            Text('📦 Mit Artikeln: ${stats['with_items']}'),
            Text('🔄 Leer: ${stats['empty']}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _performCleanup(context, client);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('🧹 Bereinigen'),
        ),
      ],
    );
  }

  /// **🧹 PRIVATE BEREINIGUNGSFUNKTION**
  static Future<void> _performCleanup(BuildContext context, Client client) async {
    try {
      final cleanupStats = await client.pos.cleanupSessionsWithBusinessLogic();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Bereinigung: ${cleanupStats['deleted_from_db']} Sessions gelöscht',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
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
