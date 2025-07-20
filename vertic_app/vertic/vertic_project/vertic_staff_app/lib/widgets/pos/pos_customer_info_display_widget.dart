import 'package:flutter/material.dart';
import 'package:test_server_client/test_server_client.dart';
import 'pos_search_section.dart';

/// **👤 POS CUSTOMER INFO DISPLAY WIDGET**
///
/// Eigenständige UI-Komponente für Kunden-Informations-Anzeige im POS-System:
/// - ✅ Integrierte Kundensuche mit PosSearchSection
/// - ✅ Live-Filter-Integration für Produktsuche
/// - ✅ Callback-basierte Interaktion (keine Logik-Änderungen)
/// - ✅ Scanner-Ready Suchfeld mit Auto-Focus
/// - ✅ Responsive Layout mit klarer Struktur
/// - ✅ Vollständige Integration in POS-Workflow
class PosCustomerInfoDisplayWidget extends StatelessWidget {
  final AppUser? selectedCustomer;
  final bool autofocus;
  final String hintText;
  final Function(AppUser) onCustomerSelected;
  final Function(Product) onProductSelected;
  final VoidCallback onCustomerRemoved;
  final Function(String) onLiveFilterChanged;
  final String liveFilterQuery;
  final bool isLiveFilterActive;
  final VoidCallback onLiveFilterReset;

  const PosCustomerInfoDisplayWidget({
    super.key,
    this.selectedCustomer,
    this.autofocus = true,
    this.hintText = 'Kunde oder Produkt suchen (Scanner bereit)...',
    required this.onCustomerSelected,
    required this.onProductSelected,
    required this.onCustomerRemoved,
    required this.onLiveFilterChanged,
    required this.liveFilterQuery,
    required this.isLiveFilterActive,
    required this.onLiveFilterReset,
  });

  @override
  Widget build(BuildContext context) {
    return PosSearchSection(
      selectedCustomer: selectedCustomer,
      autofocus: autofocus,
      hintText: hintText,
      onCustomerSelected: (customer) async {
        // 🧹 WARENKORB-SYNCHRONISATION: Bei Personenwechsel alles zurücksetzen
        onCustomerSelected(customer);
      },
      onProductSelected: (product) async {
        // 🛒 PRODUKT-DIREKTAUSWAHL: Produkt direkt zum aktuellen Warenkorb hinzufügen
        onProductSelected(product);
      },
      onCustomerRemoved: () async {
        // 🧹 WARENKORB-RESET: Bei Kunde entfernen
        onCustomerRemoved();
      },
      // 🔍 LIVE-FILTER INTEGRATION
      onLiveFilterChanged: onLiveFilterChanged,
      liveFilterQuery: liveFilterQuery,
      isLiveFilterActive: isLiveFilterActive,
      onLiveFilterReset: onLiveFilterReset,
    );
  }
}
