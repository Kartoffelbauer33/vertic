import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';

/// **⚠️ POS CART VALIDATION DIALOG WIDGET**
///
/// Eigenständige UI-Komponente für Warenkorb-Validierungs-Dialog im POS-System:
/// - ✅ Warnt bei unbezahltem Warenkorb ohne Kunde
/// - ✅ Zeigt Warenkorb-Details (Anzahl Artikel, Gesamtwert)
/// - ✅ Callback-basierte Interaktion (keine Logik-Änderungen)
/// - ✅ Benutzerfreundliche Handlungsanweisungen
/// - ✅ Responsive Layout mit klarer Struktur
class PosCartValidationDialogWidget extends StatelessWidget {
  final List<PosCartItem> cartItems;
  final double cartTotal;
  final VoidCallback? onCustomerAssignRequested;

  const PosCartValidationDialogWidget({
    super.key,
    required this.cartItems,
    required this.cartTotal,
    this.onCustomerAssignRequested,
  });

  /// **⚠️ STATISCHE METHODE: Dialog anzeigen**
  static void show({
    required BuildContext context,
    required List<PosCartItem> cartItems,
    required double cartTotal,
    VoidCallback? onCustomerAssignRequested,
  }) {
    showDialog(
      context: context,
      builder: (context) => PosCartValidationDialogWidget(
        cartItems: cartItems,
        cartTotal: cartTotal,
        onCustomerAssignRequested: onCustomerAssignRequested,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          const Text('Warenkorb nicht abgeschlossen'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Der aktuelle Warenkorb enthält ${cartItems.length} unbezahlte Artikel im Wert von ${cartTotal.toStringAsFixed(2)}€.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Um einen neuen Warenkorb zu erstellen, müssen Sie:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('• Den Warenkorb bezahlen ODER'),
          const Text('• Einen Kunden zuordnen (für Zurückstellung)'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // 🎯 FOCUS-FIX: Handled by CustomerSearchSection Widget
          },
          child: const Text('Verstanden'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // 🎯 FOCUS-FIX: Nach Dialog-Schließung Suchfeld fokussieren für Kundenzuordnung
            // Auto-focus wird jetzt vom CustomerSearchSection Widget gehandhabt
            onCustomerAssignRequested?.call();
          },
          child: const Text('Kunde zuordnen'),
        ),
      ],
    );
  }
}
