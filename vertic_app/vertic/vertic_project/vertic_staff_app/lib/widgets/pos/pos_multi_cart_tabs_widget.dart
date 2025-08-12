import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import '../../pages/pos/pos_system_page.dart' show CartSession;

/// **🎨 POS MULTI-CART-TABS WIDGET - Reine UI-Komponente für Warenkorb-Tabs**
/// 
/// Diese Komponente ist eine 1:1-Extraktion der ursprünglichen _buildTopCartTabs() Methode.
/// KEINE LOGIK-ÄNDERUNGEN - nur UI-Code ausgelagert für bessere Wartbarkeit.
/// 
/// Alle State-Änderungen erfolgen weiterhin über Callbacks in der Haupt-Page.
class PosMultiCartTabsWidget extends StatelessWidget {
  final List<CartSession> activeCarts;
  final int currentCartIndex;
  final Function(int index) onSwitchToCart;
  final VoidCallback onCreateNewCart;
  final Function(int index) onShowRemoveCartDialog;

  const PosMultiCartTabsWidget({
    super.key,
    required this.activeCarts,
    required this.currentCartIndex,
    required this.onSwitchToCart,
    required this.onCreateNewCart,
    required this.onShowRemoveCartDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🛒 CART-TABS MIT HORIZONTALEM SCROLLING
          Expanded(
            child: activeCarts.isEmpty
                ? Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Noch keine Warenkörbe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: activeCarts.length,
                    itemBuilder: (context, index) {
                      final cart = activeCarts[index];
                      final isActive = index == currentCartIndex;
                      final isOnHold = cart.isOnHold;

                      return GestureDetector(
                        onTap: () => onSwitchToCart(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          constraints: const BoxConstraints(
                            maxWidth: 160,
                            minHeight: 36,
                            maxHeight: 40,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : isOnHold
                                ? Colors.amber[600]
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isActive
                                  ? Colors.blue[300]!
                                  : isOnHold
                                  ? Colors.amber[700]!
                                  : Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Status-Icon
                              Icon(
                                isOnHold
                                    ? Icons.pause_circle_filled
                                    : cart.customer != null
                                    ? Icons.person
                                    : Icons.shopping_cart,
                                size: 16,
                                color: isActive
                                    ? Colors.blue[700]
                                    : isOnHold
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              const SizedBox(width: 6),
                              // Cart-Name & Info
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    cart.displayName.length > 12
                                        ? '${cart.displayName.substring(0, 12)}...'
                                        : cart.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Colors.blue[800]
                                          : isOnHold
                                          ? Colors.white
                                          : Colors.grey[800],
                                      height: 1.2,
                                    ),
                                  ),
                                  if (cart.items.isNotEmpty)
                                    Text(
                                      '${cart.items.length} • ${cart.total.toStringAsFixed(2)}€',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isActive
                                            ? Colors.blue[600]
                                            : isOnHold
                                            ? Colors.white70
                                            : Colors.grey[600],
                                        height: 1.1,
                                      ),
                                    ),
                                ],
                              ),
                              // 🔧 X-Button für ALLE Warenkörbe (auch aktive), aber nicht bei nur einem Warenkorb
                              if (activeCarts.length > 1) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => onShowRemoveCartDialog(index),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: isActive
                                        ? Colors.red[600]!
                                        : isOnHold
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // 🛒 AKTIONS-BUTTONS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Neuer Warenkorb (mit Validierung)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    onPressed: onCreateNewCart,
                    tooltip: 'Neuer Warenkorb',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
