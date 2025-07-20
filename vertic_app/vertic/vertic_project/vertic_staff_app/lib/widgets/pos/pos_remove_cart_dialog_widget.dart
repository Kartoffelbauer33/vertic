import 'package:flutter/material.dart';
import '../../pages/pos_system_page.dart';

/// **🗑️ POS REMOVE CART DIALOG WIDGET**
///
/// Eigenständige UI-Komponente für Warenkorb-Entfernung-Dialog im POS-System:
/// - ✅ Intelligente Logik für leere vs. gefüllte Warenkörbe
/// - ✅ Automatische Entfernung leerer Warenkörbe ohne Bestätigung
/// - ✅ Bestätigungsdialog für Warenkörbe mit Inhalt oder Kundenzuordnung
/// - ✅ Callback-basierte Interaktion (keine Logik-Änderungen)
/// - ✅ Detaillierte Informationen über Warenkorb-Inhalt
class PosRemoveCartDialogWidget extends StatelessWidget {
  final int cartIndex;
  final CartSession cart;
  final VoidCallback onRemoveConfirmed;

  const PosRemoveCartDialogWidget({
    super.key,
    required this.cartIndex,
    required this.cart,
    required this.onRemoveConfirmed,
  });

  /// **🗑️ STATISCHE METHODE: Dialog anzeigen mit intelligenter Logik**
  static void show({
    required BuildContext context,
    required int cartIndex,
    required CartSession cart,
    required VoidCallback onRemoveConfirmed,
  }) {
    // 🧹 INTELLIGENTE LOGIK: Leere Warenkörbe ohne Bestätigung entfernen
    final hasItems = cart.items.isNotEmpty;
    final hasCustomer = cart.customer != null;

    // Wenn Warenkorb leer und kein Kunde zugeordnet → direkt entfernen
    if (!hasItems && !hasCustomer) {
      debugPrint(
        '🧹 Leerer Warenkorb wird direkt entfernt: ${cart.displayName}',
      );
      onRemoveConfirmed();
      return;
    }

    // Andernfalls: Bestätigung anfordern bei Inhalt oder Kundenzuordnung
    showDialog(
      context: context,
      builder: (context) => PosRemoveCartDialogWidget(
        cartIndex: cartIndex,
        cart: cart,
        onRemoveConfirmed: onRemoveConfirmed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = cart.items.isNotEmpty;
    final hasCustomer = cart.customer != null;

    return AlertDialog(
      title: const Text('Warenkorb entfernen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Möchten Sie den Warenkorb "${cart.displayName}" wirklich entfernen?',
          ),
          if (hasItems) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ Warenkorb enthält ${cart.items.length} Artikel (${cart.total.toStringAsFixed(2)} €)',
              style: TextStyle(
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (hasCustomer) ...[
            const SizedBox(height: 8),
            Text(
              '👤 Warenkorb ist ${cart.customer!.firstName} ${cart.customer!.lastName} zugeordnet',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRemoveConfirmed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Entfernen'),
        ),
      ],
    );
  }
}
