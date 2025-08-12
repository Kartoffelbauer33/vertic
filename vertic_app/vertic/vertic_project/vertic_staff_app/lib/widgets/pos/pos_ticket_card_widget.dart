import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';

/// **🎫 POS TICKET CARD WIDGET**
///
/// Eigenständige UI-Komponente für Ticket-Karten im POS-System:
/// - ✅ Einheitliches Design mit Kategorie-spezifischen Farben und Icons
/// - ✅ Responsive Layout mit optimierten Größen
/// - ✅ Callback-basierte Interaktion (keine Logik-Änderungen)
/// - ✅ Null-Safety für Kategorie-Daten
class PosTicketCardWidget extends StatelessWidget {
  final TicketType ticketType;
  final Map<String, dynamic> categoryData;
  final VoidCallback onTap;

  const PosTicketCardWidget({
    super.key,
    required this.ticketType,
    required this.categoryData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2, // Reduziert von 3 auf 2
      borderRadius: BorderRadius.circular(8), // Reduziert von 12 auf 8
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6), // Reduziert von 8 auf 6
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryData['color'].withValues(alpha: 0.1),
                categoryData['color'].withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: categoryData['color'].withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                categoryData['icon'],
                color: categoryData['color'],
                size: 18, // Reduziert von 24 auf 18 (25% kleiner)
              ),
              const SizedBox(height: 3), // Reduziert von 4 auf 3
              Text(
                ticketType.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 9, // Reduziert von 11 auf 9 (ca. 20% kleiner)
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${ticketType.defaultPrice.toStringAsFixed(2)} €',
                style: TextStyle(
                  color: categoryData['color'],
                  fontWeight: FontWeight.bold,
                  fontSize: 10, // Reduziert von 13 auf 10 (ca. 25% kleiner)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
