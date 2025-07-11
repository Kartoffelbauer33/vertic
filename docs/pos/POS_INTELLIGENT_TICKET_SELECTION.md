# Intelligentes Ticketauswahlsystem für POS

## Übersicht

Das POS-System der Staff-App übernimmt die bewährte intelligente Ticketauswahl aus der Client-App und erweitert sie für den Verkauf an Kunden. Das System wählt automatisch das beste Ticket basierend auf Kundenalter, Status und gewählter Kategorie aus.

## Kernfunktionen

### 1. Automatische Altersbasierte Auswahl

**Altersgruppen:**
- **0-12 Jahre**: Tageskarte Kind / Tageskarte Kind Ermäßigt
- **13-17 Jahre**: Tageskarte Jugend / Tageskarte Jugend Ermäßigt  
- **18-64 Jahre**: Tageskarte Erwachsen / Tageskarte Erwachsen Ermäßigt
- **65+ Jahre**: Tageskarte Senior / Tageskarte Senior Ermäßigt

### 2. Statusbasierte Ermäßigungen

**Ermäßigungsprüfung:**
```dart
bool isErmaessigt = statusType.discountPercentage > 0 || 
                   (statusType.fixedDiscountAmount != null && 
                    statusType.fixedDiscountAmount! > 0);
```

**Beispiel-Status:**
- Standard (0% Rabatt)
- Student (20% Rabatt)
- Senior (15% Rabatt)
- Azubi (25% Rabatt)
- Sozial (30% Rabatt)

### 3. Kategoriebasierte Filterung

**Verfügbare Kategorien:**
- **Einzeltickets**: `!isSubscription && !isPointBased`
- **Monatsabos**: `isSubscription && billingInterval == 30`
- **Jahresabos**: `isSubscription && billingInterval == 365`
- **Punktekarten**: `isPointBased`

## Backend-Implementation

### Neue Endpoints für POS

```dart
/// POS-System: Kauft bestes Ticket für spezifischen Kunden
Future<Ticket?> purchaseRecommendedTicketForCustomer(
    Session session, String category, int customerId) async
```

```dart
/// Berechnet optimalen Preis für POS-Kunde basierend auf Status
Future<double> calculateOptimalPriceForCustomer(
    Session session, int ticketTypeId, int customerId) async
```

### Intelligente Auswahl-Logik

```dart
/// Altersbasierte Einzelticket-Auswahl für POS-System
Future<TicketType?> _getAgeBasedSingleTicketForPosCustomer(
    Session session,
    AppUser customer,
    List<TicketType> singleTickets,
    int userStatusTypeId) async {
  
  // 1. Alter berechnen
  int age = 30; // Default
  if (customer.birthDate != null) {
    final now = DateTime.now();
    age = now.year - customer.birthDate!.year;
    if (now.month < customer.birthDate!.month || 
        (now.month == customer.birthDate!.month && now.day < customer.birthDate!.day)) {
      age--;
    }
  }

  // 2. Ermäßigungsstatus prüfen
  bool isErmaessigt = false;
  final statusType = await UserStatusType.db.findById(session, userStatusTypeId);
  if (statusType != null) {
    isErmaessigt = statusType.discountPercentage > 0 || 
                   (statusType.fixedDiscountAmount != null && statusType.fixedDiscountAmount! > 0);
  }

  // 3. Passenden Ticket-Namen bestimmen
  String expectedTicketName;
  if (age <= 12) {
    expectedTicketName = isErmaessigt ? 'Tageskarte Kind Ermäßigt' : 'Tageskarte Kind';
  } else if (age <= 17) {
    expectedTicketName = isErmaessigt ? 'Tageskarte Jugend Ermäßigt' : 'Tageskarte Jugend';
  } else if (age >= 65) {
    expectedTicketName = isErmaessigt ? 'Tageskarte Senior Ermäßigt' : 'Tageskarte Senior';
  } else {
    expectedTicketName = isErmaessigt ? 'Tageskarte Erwachsen Ermäßigt' : 'Tageskarte Erwachsen';
  }

  // 4. Exakte Übereinstimmung suchen
  try {
    return singleTickets.firstWhere(
      (t) => t.name.toLowerCase() == expectedTicketName.toLowerCase()
    );
  } catch (_) {
    // 5. Fallback: Basis-Typ ohne "Ermäßigt"
    final baseTicketName = expectedTicketName.replaceAll(' Ermäßigt', '');
    try {
      return singleTickets.firstWhere(
        (t) => t.name.toLowerCase() == baseTicketName.toLowerCase()
      );
    } catch (_) {
      // 6. Letzter Fallback: Erstes verfügbares Einzelticket
      return singleTickets.isNotEmpty ? singleTickets.first : null;
    }
  }
}
```

## Frontend-Implementation

### POS-System UI

Das POS-System verwendet ein 3-Spalten-Layout:

```
┌──────────────┬──────────────────┬──────────────┐
│ Kunden &     │ Produktkatalog   │ Warenkorb    │
│ Scanner      │                  │              │
│              │ ┌─Einzeltickets─┐ │ ┌─Items────┐ │
│ ┌─Kunde────┐ │ │ Kind      8€  │ │ │ Ticket   │ │
│ │ Max M.   │ │ │ Jugend   12€  │ │ │ x1  12€  │ │
│ │ 15 Jahre │ │ │ Erwachsen 15€ │ │ └──────────┘ │
│ └──────────┘ │ │ Senior   10€  │ │              │
│              │ └───────────────┘ │ Gesamt: 12€  │
│ Scanner:     │                  │              │
│ Hybrid Mode  │ ┌─Monatsabos───┐ │ [Kassieren]  │
└──────────────┴──────────────────┴──────────────┘
```

### Intelligente Ticket-Auswahl im Frontend

```dart
/// Intelligente Ticket-Auswahl basierend auf Kunde und Kategorie
Future<TicketType?> _getBestTicketForCustomer(String category, AppUser customer) async {
  try {
    // 1. Filter Tickets by Category
    List<TicketType> categoryTickets;
    switch (category.toLowerCase()) {
      case 'einzeltickets':
      case 'single':
        categoryTickets = _availableTickets.where((t) => !t.isSubscription && !t.isPointBased).toList();
        break;
      case 'monatsabos':
      case 'monthly':
        categoryTickets = _availableTickets.where((t) => t.isSubscription && t.billingInterval == 30).toList();
        break;
      case 'jahresabos':
      case 'yearly':
        categoryTickets = _availableTickets.where((t) => t.isSubscription && t.billingInterval == 365).toList();
        break;
      case 'punktekarten':
      case 'points':
        categoryTickets = _availableTickets.where((t) => t.isPointBased).toList();
        break;
      default:
        categoryTickets = _availableTickets;
    }

    if (categoryTickets.isEmpty) return null;

    // 2. Für Einzeltickets: Intelligente Auswahl basierend auf Alter
    if (category.toLowerCase() == 'einzeltickets' || category.toLowerCase() == 'single') {
      return await _getAgeBasedSingleTicket(customer, categoryTickets);
    }

    // 3. Für andere Kategorien: Erstes verfügbares Ticket
    return categoryTickets.first;
  } catch (e) {
    debugPrint('Fehler bei intelligenter Ticket-Auswahl: $e');
    return null;
  }
}
```

### Warenkorb-Integration

```dart
Future<void> _addTicketToCart(TicketType ticket) async {
  if (_selectedCustomer == null) {
    _showError('Bitte wählen Sie zuerst einen Kunden aus');
    return;
  }

  try {
    // Intelligente Auswahl & Preisberechnung
    final selectedTicket = await _getBestTicketForCustomer('single', _selectedCustomer!) ?? ticket;
    final price = await _calculateBestPrice(selectedTicket, _selectedCustomer!);

    // Prüfe ob bereits im Warenkorb
    final existingIndex = _cartItems.indexWhere((item) => 
      item.itemType == 'ticket' && item.ticketTypeId == selectedTicket.id
    );

    setState(() {
      if (existingIndex >= 0) {
        // Erhöhe Menge
        _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
          quantity: _cartItems[existingIndex].quantity + 1
        );
      } else {
        // Neues Item
        _cartItems.add(PosCartItem(
          id: DateTime.now().millisecondsSinceEpoch,
          itemType: 'ticket',
          ticketTypeId: selectedTicket.id,
          productId: null,
          name: selectedTicket.name,
          price: price,
          quantity: 1,
          customerId: _selectedCustomer!.id!,
          addedAt: DateTime.now(),
        ));
      }
      _recalculateCart();
    });

    _showSuccess('${selectedTicket.name} zum Warenkorb hinzugefügt');
  } catch (e) {
    _showError('Fehler beim Hinzufügen: $e');
  }
}
```

## Scanner-Modi

### 1. Express Mode
- **Zweck**: Direkter Check-in (wie bisheriger Scanner)
- **Verhalten**: QR → sofortiger Check-in-Prozess
- **Verwendung**: Schneller Einlass ohne Verkauf

### 2. POS Mode  
- **Zweck**: QR → Warenkorb (Customer oder Item Detection)
- **Verhalten**: 
  - Customer QR → Kunde auswählen
  - Item QR → Artikel zum Warenkorb hinzufügen
- **Verwendung**: Aktiver Verkaufsmodus

### 3. Hybrid Mode
- **Zweck**: Intelligente Entscheidung basierend auf Kontext
- **Verhalten**:
  - Leerer Warenkorb + Customer QR → Kunde auswählen
  - Kunde ausgewählt + Item QR → Artikel hinzufügen
  - Sonst → Express Mode
- **Verwendung**: Flexibler Modus für alle Situationen

## Beispiel-Workflow

### Szenario: 15-jähriger Student kauft Einzelticket

1. **Kundenauswahl**: Staff scannt Customer-QR oder sucht "Max Müller"
2. **Kundendaten**: System erkennt Alter (15 Jahre) und Status (Student = 20% Rabatt)
3. **Kategorie-Auswahl**: Staff klickt auf "Einzeltickets" im Produktkatalog
4. **Intelligente Auswahl**: System wählt automatisch "Tageskarte Jugend Ermäßigt"
5. **Preisberechnung**: 12€ Standard - 20% = 9,60€
6. **Warenkorb**: "Tageskarte Jugend Ermäßigt - 9,60€" wird hinzugefügt
7. **Checkout**: Staff klickt "Kassieren" → Ticket wird für Max Müller erstellt

### Logging-Output im Backend

```
POS: Intelligente Auswahl für Max Müller (Alter: 15, Ermäßigt: true) → Tageskarte Jugend Ermäßigt
POS: Exakte Übereinstimmung gefunden: Tageskarte Jugend Ermäßigt
POS: Preisberechnung für Max Müller: Tageskarte Jugend Ermäßigt → 9.60€ (Status: 2)
[DEBUG] purchaseRecommendedTicketForCustomer: Gewählter TicketType: Tageskarte Jugend Ermäßigt (ID: 12) für Kunde Max Müller
```

## Vorteile des Systems

### 1. **Automatisierung**
- Keine manuellen Alters-/Status-Prüfungen erforderlich
- Reduziert Fehler bei der Ticket-Auswahl
- Beschleunigt den Verkaufsprozess

### 2. **Konsistenz**
- Einheitliche Preislogik zwischen Client-App und Staff-App
- Automatische Anwendung aller Ermäßigungen
- Verhindert vergessene Rabatte

### 3. **Flexibilität**
- Fallback-Mechanismen bei fehlenden spezifischen Tickets
- Unterstützt verschiedene Gym-Konfigurationen
- Erweiterbar für neue Ticket-Kategorien

### 4. **Benutzerfreundlichkeit**
- Intuitive 3-Spalten-Oberfläche
- Einfache Scanner-Modi
- Klare Preisanzeige mit Rabatten

## Migration und Kompatibilität

### Bestehende Tickets
- Alle bestehenden TicketTypes werden unterstützt
- Keine Datenmigration erforderlich
- Rückwärtskompatibel zu manueller Auswahl

### Neue Features
- POS-spezifische Endpoints erweitern bestehende API
- Client-App Funktionalität bleibt unverändert
- Shared Logic zwischen beiden Apps

## Nächste Schritte

1. **Server-Generierung**: Neue Endpoints zum Client hinzufügen
2. **UI-Feintuning**: Produktkarten-Design optimieren
3. **Scanner-Integration**: QR-Code-Erkennung implementieren
4. **Checkout-Prozess**: Zahlungsabwicklung und Belegdruck
5. **Reporting**: POS-spezifische Statistiken und Reports

Das intelligente Ticketauswahlsystem stellt sicher, dass Kunden automatisch das günstigste und passendste Ticket erhalten, während der Verkaufsprozess für das Staff-Personal vereinfacht wird.