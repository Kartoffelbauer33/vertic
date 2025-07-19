import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'universal_search_compact.dart';

/// **🏪 POS-SYSTEM SUCHSEKTION**
///
/// Speziell für das POS-System entwickelt:
/// - ✅ Sucht nach Kunden UND Produkten
/// - ✅ Nutzt universelle Suchfunktion
/// - ✅ Saubere Callback-Struktur
/// - ✅ Auto-Focus für Scanner-Integration
class PosSearchSection extends StatelessWidget {
  final AppUser? selectedCustomer;
  final Function(AppUser customer) onCustomerSelected;
  final Function(Product product)? onProductSelected;
  final VoidCallback? onCustomerRemoved;
  final bool autofocus;
  final String hintText;

  const PosSearchSection({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    this.onProductSelected,
    this.onCustomerRemoved,
    this.autofocus = false,
    this.hintText = 'Kunde oder Produkt suchen...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Text(
                  'POS-Suche',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Suchbereich
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // 🔍 NEUE POS MULTI-ENTITY SUCHE
                PosSearchWidget(
                  hintText: hintText,
                  autofocus: autofocus,
                  onCustomerSelected: onCustomerSelected,
                  onProductSelected: onProductSelected,
                ),

                const SizedBox(height: 16),

                // Ausgewählter Kunde anzeigen
                if (selectedCustomer != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selectedCustomer!.firstName} ${selectedCustomer!.lastName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (selectedCustomer!.email != null)
                                Text(
                                  selectedCustomer!.email!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (onCustomerRemoved != null)
                          IconButton(
                            onPressed: onCustomerRemoved,
                            icon: const Icon(Icons.clear, color: Colors.red),
                            tooltip: 'Kunde entfernen',
                          ),
                      ],
                    ),
                  ),
                ],

                // Info-Text wenn kein Kunde ausgewählt
                if (selectedCustomer == null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kunden suchen für Warenkorb-Zuordnung oder Produkt für direkten Verkauf',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
