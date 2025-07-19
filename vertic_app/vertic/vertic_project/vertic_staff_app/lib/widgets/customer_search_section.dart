import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'universal_search_compact.dart';

/// **🔍 ISOLIERTE KUNDENSUCHE-SEKTION**
///
/// Vollständig unabhängiges Widget für Kundensuche:
/// - ✅ Nutzt universelle Suchfunktion
/// - ✅ Keine Abhängigkeiten zu POS-Seite
/// - ✅ Wiederverwendbar in anderen Seiten
/// - ✅ Saubere Callback-Struktur
class CustomerSearchSection extends StatelessWidget {
  final AppUser? selectedCustomer;
  final Function(AppUser customer) onCustomerSelected;
  final VoidCallback? onCustomerRemoved;
  final bool autofocus;
  final String hintText;

  const CustomerSearchSection({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    this.onCustomerRemoved,
    this.autofocus = false,
    this.hintText = 'Name, E-Mail oder Telefon eingeben...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.person_search, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Kundensuche',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
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
                // 🔍 NEUE UNIVERSELLE KUNDENSUCHE
                CustomerSearchWidget(
                  hintText: hintText,
                  autofocus: autofocus,
                  onCustomerSelected: onCustomerSelected,
                ),

                const SizedBox(height: 16),

                // Ausgewählter Kunde anzeigen
                if (selectedCustomer != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
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
                                  fontSize: 16,
                                ),
                              ),
                              if (selectedCustomer!.email != null)
                                Text(
                                  selectedCustomer!.email!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (onCustomerRemoved != null)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: onCustomerRemoved,
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
