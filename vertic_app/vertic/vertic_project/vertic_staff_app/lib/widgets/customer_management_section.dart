import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'universal_search_compact.dart';

/// **🔍 ISOLIERTE KUNDENVERWALTUNG-SUCHE-SEKTION**
///
/// Vollständig unabhängiges Widget für Kundenverwaltung:
/// - ✅ Nur Kundensuche (keine anderen Entitäten)
/// - ✅ Keine Abhängigkeiten zu CustomerManagementPage
/// - ✅ Wiederverwendbar und isoliert
/// - ✅ Saubere Callback-Struktur
class CustomerManagementSection extends StatelessWidget {
  final Function(AppUser customer) onCustomerSelected;
  final String hintText;

  const CustomerManagementSection({
    super.key,
    required this.onCustomerSelected,
    this.hintText = 'Name, E-Mail, ID oder Telefon eingeben...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // 🔍 NEUE UNIVERSELLE KUNDENSUCHE (nur Kunden)
          CustomerSearchWidget(
            hintText: hintText,
            autofocus: false,
            onCustomerSelected: onCustomerSelected,
          ),

          const SizedBox(height: 12),

          // Info-Text
          Text(
            'Wählen Sie einen Kunden aus der Suche aus, um Details anzuzeigen',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
