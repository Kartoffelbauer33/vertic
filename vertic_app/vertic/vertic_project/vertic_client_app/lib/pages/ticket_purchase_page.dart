import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';
import 'package:test_server_client/test_server_client.dart';

import '../widgets/user_qr_display.dart';

class TicketPurchasePage extends StatefulWidget {
  final SessionManager sessionManager;
  final Client client;
  final AppUser user;

  const TicketPurchasePage({
    super.key,
    required this.sessionManager,
    required this.client,
    required this.user,
  });

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

class _TicketPurchasePageState extends State<TicketPurchasePage> {
  late List<Ticket> _tickets = [];
  List<TicketType> _availableTicketTypes = [];
  Map<int, PurchaseStatusResponse> _purchaseStatuses =
      {}; // TicketTypeId -> Status
  bool _isLoading = false;
  bool _isLoadingTicketTypes = true;
  bool _isPrinting = false;
  String? _errorMessage;
  int? _currentUserId; // <-- NEU: aktuelle User-ID aus Session

  @override
  void initState() {
    super.initState();
    TicketCard.setClient(widget.client);
    _initializeData();
  }

  /// Initialisiert die Daten in der korrekten Reihenfolge
  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _isLoadingTicketTypes = true;
      _errorMessage = null;
    });

    try {
      // 0. Hole aktuelle User-ID aus Session
      final identity = await widget.client.identity.getCurrentUserIdentity();
      _currentUserId = identity?.userId;
      if (_currentUserId == null) {
        setState(() {
          _errorMessage = 'Fehler: Keine gültige User-Session gefunden!';
        });
        return;
      }
      // 1. TicketTypes laden
      await _loadAvailableTicketTypes();
      // 2. Purchase-Status laden
      await _loadPurchaseStatuses();
      // 3. User-Tickets laden
      await _loadTickets();
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Daten: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingTicketTypes = false;
      });
    }
  }

  Future<void> _loadTickets() async {
    try {
      if (_currentUserId == null) return;
      // Debug-Print: User-ID und E-Mail
      debugPrint(
          'Client-App: Lade Tickets für User-ID: \\${_currentUserId}, Email: \\${widget.user.email}');
      final allTickets =
          await widget.client.ticket.getValidUserTickets(_currentUserId!);
      allTickets.sort((a, b) {
        final aValid = _isTicketValid(a);
        final bValid = _isTicketValid(b);
        if (aValid != bValid) {
          return bValid ? 1 : -1;
        }
        return a.expiryDate.compareTo(b.expiryDate);
      });
      setState(() {
        _tickets = allTickets;
      });
      // Debug-Print: Anzahl Tickets
      debugPrint(
          'Client-App: Für User-ID: \\${_currentUserId}, Email: \\${widget.user.email} wurden \\${_tickets.length} Tickets geladen');
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Tickets: $e';
      });
      debugPrint('❌ Fehler beim Laden der Tickets: $e');
    }
  }

  Future<void> _loadPurchaseStatuses() async {
    try {
      final statuses = <int, PurchaseStatusResponse>{};

      debugPrint(
          '🔍 Lade Purchase-Status für ${_availableTicketTypes.length} Ticket-Typen...');

      for (final ticketType in _availableTicketTypes) {
        try {
          debugPrint(
              '🎫 Prüfe Purchase-Status für: ${ticketType.name} (ID: ${ticketType.id})');

          final status =
              await widget.client.ticket.getUserPurchaseStatus(ticketType.id!);

          if (status != null) {
            debugPrint(
                '✅ Status erhalten für ${ticketType.name}: ${status.hasPurchased}');
            statuses[ticketType.id!] = status;
          } else {
            debugPrint('⚠️ Null Status für ${ticketType.name}, setze Fallback');
            statuses[ticketType.id!] = PurchaseStatusResponse(
              hasPurchased: false,
              canPurchaseAgain: true,
              isPrintingPending: false,
              lastPurchaseDate: null,
            );
          }
        } catch (e) {
          debugPrint(
              '❌ Fehler beim Laden des Purchase-Status für TicketType ${ticketType.id} (${ticketType.name}): $e');
          // Fallback: Standard-Status setzen
          statuses[ticketType.id!] = PurchaseStatusResponse(
            hasPurchased: false,
            canPurchaseAgain: true,
            isPrintingPending: false,
            lastPurchaseDate: null,
          );
        }
      }

      debugPrint(
          '🎯 Purchase-Status geladen für ${statuses.length} Ticket-Typen');

      setState(() {
        _purchaseStatuses = statuses;
      });
    } catch (e) {
      debugPrint('💥 Allgemeiner Fehler beim Laden der Purchase-Statuses: $e');
    }
  }

  Future<void> _loadAvailableTicketTypes() async {
    try {
      // 🎯 NEUE DB-BASIERTE HIERARCHISCHE DATEN VOM BACKEND LADEN
      Map<String, dynamic>? hierarchicalData;
      try {
        hierarchicalData =
            await widget.client.ticket.getTicketsHierarchicalDb();
        debugPrint('✅ Neue DB-basierte Hierarchie geladen');
      } catch (e) {
        debugPrint('❌ Neue DB-basierte Methode Fehler: $e');
        // Fallback: Lade alle TicketTypes direkt
        final allTicketTypes =
            await widget.client.ticketType.getAllTicketTypes();
        setState(() {
          _availableTicketTypes = allTicketTypes;
        });
        debugPrint('✅ ${allTicketTypes.length} TicketTypes geladen (Fallback)');
        return;
      }

      // 🎯 EXTRAHIERE TICKETS AUS NEUER DB-BASIERTER MAP-STRUKTUR
      final allVisibleTickets = <TicketType>[];

      if (hierarchicalData['success'] == true) {
        // Parse Tickets-Array aus der neuen Response-Struktur
        final ticketsData = hierarchicalData['tickets'] as List<dynamic>?;

        if (ticketsData != null) {
          for (final ticketData in ticketsData) {
            if (ticketData is Map<String, dynamic>) {
              try {
                // 🎯 ERSTELLE TICKETTYPE MIT KORREKTEN PARAMETERN
                final ticketType = TicketType(
                  id: ticketData['id'] as int?,
                  name: ticketData['name'] as String? ?? 'Unnamed Ticket',
                  description: ticketData['description'] as String? ??
                      'Keine Beschreibung',
                  validityPeriod: ticketData['validityPeriod'] as int? ??
                      30, // Standard: 30 Tage
                  defaultPrice: (ticketData['price'] ?? 0.0).toDouble(),
                  isPointBased: ticketData['isPointBased'] as bool? ?? false,
                  defaultPoints: ticketData['defaultPoints'] as int?,
                  isSubscription:
                      ticketData['isSubscription'] as bool? ?? false,
                  billingInterval: ticketData['billingInterval'] as int?,
                  gymId: ticketData['gymId'] as int?,
                  isVerticUniversal:
                      ticketData['isVerticUniversal'] as bool? ?? false,
                  createdAt: DateTime.now(),
                  updatedAt: null,
                );

                allVisibleTickets.add(ticketType);
              } catch (e) {
                debugPrint('⚠️ Fehler beim Parsen von Ticket: $e');
              }
            }
          }
        }

        debugPrint(
            '🎯 ${allVisibleTickets.length} Tickets aus neuer DB-Hierarchie extrahiert');
        debugPrint('📊 Kategorien: ${hierarchicalData['categories']}');
        debugPrint('👤 User-Level: ${hierarchicalData['userLevel']}');
      } else {
        debugPrint('❌ DB-Hierarchie Response nicht erfolgreich');
      }

      setState(() {
        _availableTicketTypes = allVisibleTickets;
      });

      debugPrint(
          '✅ ${allVisibleTickets.length} TicketTypes aus Hierarchie geladen');
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der hierarchischen Ticket-Typen: $e');
      setState(() {
        _availableTicketTypes = [];
      });
    }
  }

  bool _isTicketValid(Ticket ticket) {
    final now = DateTime.now();

    // Punktebasierte Tickets: gültig wenn Punkte übrig
    if (ticket.remainingPoints != null) {
      return ticket.remainingPoints! > 0;
    }

    // Abonnements: gültig wenn aktiv und nicht abgelaufen
    if (ticket.subscriptionStatus == 'ACTIVE') {
      return ticket.nextBillingDate == null ||
          ticket.nextBillingDate!.isAfter(now);
    }

    // Normale Tickets: gültig wenn nicht verwendet und nicht abgelaufen
    return !ticket.isUsed && ticket.expiryDate.isAfter(now);
  }

  // Filtert Ticket-Typen basierend auf Kategorie
  List<TicketType> _getFilteredTicketTypes() {
    // Vertic universelle Tickets (alle sichtbaren)
    return _availableTicketTypes;
  }

  // Findet das beste Ticket basierend auf Vertic-Typ und User-Status
  TicketType? _getBestTicketForVerticType(String verticType) {
    final filteredTypes = _getFilteredTicketTypes();

    switch (verticType) {
      case 'single':
        // Suche nach Einzeltickets (nicht Abonnement, nicht punktebasiert)
        final singleTickets = filteredTypes
            .where((type) => !type.isSubscription && !type.isPointBased)
            .toList();
        return singleTickets.isNotEmpty ? singleTickets.first : null;
      case 'monthly':
        // Suche nach Monatsabos
        final monthlyTickets = filteredTypes
            .where((type) => type.isSubscription && type.billingInterval == 30)
            .toList();
        return monthlyTickets.isNotEmpty ? monthlyTickets.first : null;
      case 'yearly':
        // Suche nach Jahresabos
        final yearlyTickets = filteredTypes
            .where((type) => type.isSubscription && type.billingInterval == 365)
            .toList();
        return yearlyTickets.isNotEmpty ? yearlyTickets.first : null;
      case 'points':
        // Suche nach Punktekarten
        final pointTickets =
            filteredTypes.where((type) => type.isPointBased).toList();
        return pointTickets.isNotEmpty ? pointTickets.first : null;
      default:
        return null;
    }
  }

  Future<void> _purchaseVerticTicket(String verticType) async {
    debugPrint('🛡️ Starte Kauf-Prüfung für Kategorie: $verticType');

    // 1. Finde alle TicketTypes der gewählten Kategorie
    final categoryTicketTypes = _availableTicketTypes.where((ticket) {
      switch (verticType.toLowerCase()) {
        case 'single':
          return !ticket.isPointBased && !ticket.isSubscription;
        case 'monthly':
          return ticket.isSubscription &&
              (ticket.billingInterval == 30 || ticket.billingInterval == null);
        case 'yearly':
          return ticket.isSubscription && ticket.billingInterval == 365;
        case 'points':
          return ticket.isPointBased;
        default:
          return false;
      }
    }).toList();

    debugPrint(
        '📋 Gefundene TicketTypes für Kategorie $verticType: ${categoryTicketTypes.map((t) => '${t.name} (ID: ${t.id})').join(', ')}');

    // 2. Prüfe ob bereits ein Ticket dieser Kategorie gekauft wurde
    bool alreadyPurchased = false;
    PurchaseStatusResponse? existingStatus;
    TicketType? existingTicketType;

    for (final ticketType in categoryTicketTypes) {
      final status = _purchaseStatuses[ticketType.id];
      debugPrint(
          '🔍 TicketType ${ticketType.name} (ID: ${ticketType.id}) - Status: hasPurchased=${status?.hasPurchased}');

      if (status != null && status.hasPurchased) {
        alreadyPurchased = true;
        existingStatus = status;
        existingTicketType = ticketType;
        debugPrint(
            '✅ Kategorie $verticType: Existing ticket found - TicketType ${ticketType.name}');
        break;
      }
    }

    // 3. Falls bereits gekauft, verhindere Mehrfachkauf
    if (alreadyPurchased &&
        existingStatus != null &&
        existingTicketType != null) {
      debugPrint('🚫 Kauf verhindert: Kategorie $verticType bereits gekauft');

      final isPrintingPending = existingStatus.isPrintingPending;
      final ticketId = existingStatus.ticketId;
      final ticketTypeName = existingTicketType.name;

      String message;
      if (isPrintingPending && ticketId != null) {
        message =
            'Sie haben bereits ein $ticketTypeName gekauft. Nutzen Sie "Drucken".';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Drucken',
              onPressed: () => _showPrintActionSheet(ticketId),
            ),
          ),
        );
      } else {
        message =
            'Sie haben bereits ein $ticketTypeName. Verwenden Sie Ihren User-QR-Code.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
      return; // ✅ STOPPE HIER - Kein Backend-Call!
    }

    // 4. Kauf ist erlaubt - führe Backend-Call durch
    debugPrint('✅ Kauf-Berechtigung bestätigt für Kategorie $verticType');

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(
          '🎫 Kaufe automatisch bestes Ticket für Kategorie: $verticType');

      final purchasedTicket =
          await widget.client.ticket.purchaseRecommendedTicket(verticType);

      if (purchasedTicket == null) {
        throw Exception('Ticket konnte nicht gekauft werden');
      }

      debugPrint('✅ Ticket gekauft mit ID: ${purchasedTicket.id}');

      // Daten neu laden
      await _loadTickets();
      await _loadPurchaseStatuses();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket erfolgreich gekauft!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Drucken',
            onPressed: () => _showPrintActionSheet(purchasedTicket.id!),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Ticketkauf: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Kaufen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPrintDialog(int ticketId) {
    // Finde gekauftes Ticket direkt über ticketId
    final purchasedTicket = _tickets.where((t) => t.id == ticketId).firstOrNull;

    if (purchasedTicket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket nicht gefunden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print, color: Colors.blue),
            SizedBox(width: 8),
            Text('Ticket drucken'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Möchten Sie Ihr Ticket jetzt am Bondrucker ausdrucken?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ticket #${purchasedTicket.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Preis: ${purchasedTicket.price.toStringAsFixed(2)} €'),
                  Text(
                      'Gültig bis: ${DateFormat('dd.MM.yyyy').format(purchasedTicket.expiryDate)}'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person,
                            color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Nutzen Sie Ihren User-QR-Code für den Einlass',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Später'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _printTicket(purchasedTicket.id!);
            },
            icon: const Icon(Icons.print),
            label: const Text('Jetzt drucken'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printTicket(int ticketId) async {
    setState(() {
      _isPrinting = true;
    });

    try {
      final result = await widget.client.printer.printTicket(ticketId, null);

      if (result.success == true) {
        // Markiere Ticket als gedruckt
        await widget.client.ticket
            .markTicketAsPrinted(ticketId, result.printJobId);

        // Purchase-Status und Tickets aktualisieren
        await _loadPurchaseStatuses();
        await _loadTickets();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ticket erfolgreich gedruckt!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'QR-Code anzeigen',
              onPressed: () {
                // Navigation zu einem anderen Tab oder zurück zum Hauptmenü
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Druckfehler: ${result.error ?? 'Unbekannter Fehler'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Drucken: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket kaufen'),
      ),
      body: _buildShopView(),
    );
  }

  Widget _buildShopView() {
    if (_isLoadingTicketTypes) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertic Tickets Sektion
          _buildVerticTicketsSection(),

          const SizedBox(height: 32),

          // Gyms Sektion
          _buildGymsSection(),
        ],
      ),
    );
  }

  Widget _buildVerticTicketsSection() {
    // Prüfe verfügbare Vertic Kategorien basierend auf echten Tickets
    final Map<String, bool> categoryAvailability = {
      'einzeltickets': false,
      'punktekarten': false,
      'zeitkarten': false,
    };

    // Analysiere verfügbare Tickets um Kategorien zu bestimmen
    for (final ticket in _availableTicketTypes) {
      // Nur Vertic Tickets berücksichtigen (nicht hallenspezifisch)
      if (!ticket.name.toLowerCase().contains('bregenz') &&
          !ticket.name.toLowerCase().contains('friedrichshafen')) {
        if (ticket.isPointBased) {
          categoryAvailability['punktekarten'] = true;
        } else if (ticket.isSubscription) {
          categoryAvailability['zeitkarten'] = true;
        } else {
          categoryAvailability['einzeltickets'] = true;
        }
      }
    }

    // Wenn keine Vertic Tickets verfügbar sind, zeige nichts an
    if (!categoryAvailability.values.any((available) => available)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Vertic Logo/Icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vertic Tickets',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Gültig in allen Vertic Hallen',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Kategorien nur anzeigen wenn sie verfügbar sind
        Column(
          children: [
            // Einzeltickets - nur anzeigen wenn verfügbar
            if (categoryAvailability['einzeltickets'] == true) ...[
              _buildVerticTicketOption(
                'Einzelticket',
                'Perfekt für gelegentliche Besuche',
                Icons.confirmation_number,
                Colors.blue,
                'single',
              ),
              const SizedBox(height: 12),
            ],

            // Zeitkarten/Abos - nur anzeigen wenn verfügbar
            if (categoryAvailability['zeitkarten'] == true) ...[
              _buildVerticTicketOption(
                'Monatsabo',
                'Unlimitiert für einen Monat',
                Icons.calendar_month,
                Colors.orange,
                'monthly',
              ),
              const SizedBox(height: 12),
              _buildVerticTicketOption(
                'Jahreskarte',
                'Das beste Angebot für Stammkunden',
                Icons.card_membership,
                Colors.purple,
                'yearly',
              ),
              const SizedBox(height: 12),
            ],

            // Punktekarten - nur anzeigen wenn verfügbar
            if (categoryAvailability['punktekarten'] == true) ...[
              _buildVerticTicketOption(
                '10er Punktekarte',
                'Zehn Eintritte zum Vorteilspreis',
                Icons.credit_card,
                Colors.green,
                'points',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildVerticTicketOption(
      String title, String subtitle, IconData icon, Color color, String type) {
    // KORRIGIERTE KATEGORIE-LOGIK: Nur EINES der relevanten Tickets berücksichtigen
    bool hasRelevantTicket = false;
    bool isPrintingPending = false;
    int? relevantTicketId;
    double? estimatedPrice;
    Ticket? relevantTicket;
    TicketType? existingTicketType;

    // Finde ALLE TicketTypes der gewählten Kategorie
    final categoryTicketTypes = _availableTicketTypes.where((ticket) {
      switch (type.toLowerCase()) {
        case 'single':
          return !ticket.isPointBased && !ticket.isSubscription;
        case 'monthly':
          return ticket.isSubscription &&
              (ticket.billingInterval == 30 || ticket.billingInterval == null);
        case 'yearly':
          return ticket.isSubscription && ticket.billingInterval == 365;
        case 'points':
          return ticket.isPointBased;
        default:
          return false;
      }
    }).toList();

    // Finde ALLE gekauften Tickets dieser Kategorie
    final List<Ticket> userTicketsOfCategory = _tickets
        .where((t) => categoryTicketTypes.any((tt) => tt.id == t.ticketTypeId))
        .toList();

    // Prüfe ob bereits EIN gültiges Ticket dieser Kategorie existiert
    for (final ticketType in categoryTicketTypes) {
      final status = _purchaseStatuses[ticketType.id];
      if (status != null && status.hasPurchased) {
        // ✅ GEFUNDEN: User hat bereits ein Ticket dieser Kategorie
        hasRelevantTicket = true;
        isPrintingPending = status.isPrintingPending;
        relevantTicketId = status.ticketId;
        estimatedPrice = ticketType.defaultPrice;

        // Finde das echte Ticket-Objekt für weitere Details
        if (relevantTicketId != null) {
          relevantTicket = _tickets.firstWhere(
            (t) => t.id == relevantTicketId,
            orElse: () => Ticket(
              id: relevantTicketId,
              userId: _currentUserId!,
              ticketTypeId: ticketType.id!,
              price: estimatedPrice!,
              purchaseDate: DateTime.now(),
              expiryDate: DateTime.now(),
              isUsed: false,
              qrCodeData: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
        break; // Stoppe bei erstem gefundenen Ticket dieser Kategorie
      }
    }

    // Falls kein gekauftes Ticket gefunden, nimm das erste verfügbare für Preis-Anzeige
    if (!hasRelevantTicket && categoryTicketTypes.isNotEmpty) {
      estimatedPrice = categoryTicketTypes.first.defaultPrice;
      existingTicketType = categoryTicketTypes.first;
    }

    // UI: Dropdown für gekaufte Tickets
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(icon, color: color, size: 32),
                title:
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subtitle),
                trailing: hasRelevantTicket
                    ? Icon(Icons.check_circle, color: Colors.green, size: 28)
                    : null,
                tileColor:
                    hasRelevantTicket ? Colors.green.withOpacity(0.08) : null,
                onTap: () => _purchaseVerticTicket(type),
              ),
            ),
            if (hasRelevantTicket)
              Positioned(
                right: 24,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Ticket vorhanden',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (userTicketsOfCategory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              backgroundColor: Colors.green.withOpacity(0.07),
              collapsedBackgroundColor: Colors.green.withOpacity(0.03),
              leading: const Icon(Icons.expand_more, color: Colors.green),
              title: Text(
                'Gekaufte Tickets (${userTicketsOfCategory.length})',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: userTicketsOfCategory.map((ticket) {
                return ListTile(
                  leading: Icon(Icons.confirmation_number, color: color),
                  title: Text('Ticket #${ticket.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Kaufdatum: ${DateFormat('dd.MM.yyyy').format(ticket.purchaseDate)}'),
                      Text(
                          'Gültig bis: ${DateFormat('dd.MM.yyyy').format(ticket.expiryDate)}'),
                      if (ticket.remainingPoints != null)
                        Text(
                            'Punkte: ${ticket.remainingPoints}/${ticket.initialPoints ?? ticket.remainingPoints}'),
                      if (ticket.subscriptionStatus != null)
                        Text('Abo-Status: ${ticket.subscriptionStatus}'),
                    ],
                  ),
                  trailing: ticket.isUsed
                      ? const Icon(Icons.check, color: Colors.grey)
                      : const Icon(Icons.check_circle, color: Colors.green),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _showPrintActionSheet(int ticketId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aktionen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('Ticket ausdrucken'),
              subtitle: const Text('Am Bondrucker in der Halle'),
              onTap: () {
                Navigator.of(context).pop();
                _printTicket(ticketId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.green),
              title: const Text('Meine Tickets anzeigen'),
              subtitle: const Text('Alle gekauften Tickets ansehen'),
              onTap: () {
                Navigator.of(context).pop();
                // Hier könnte eine spezielle Status-Seite geöffnet werden
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ticket ist aktiv und einsatzbereit!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGymsSection() {
    // Prüfe verfügbare Gym-spezifische Tickets
    final gymTickets = _availableTicketTypes
        .where((ticket) =>
            ticket.name.toLowerCase().contains('bregenz') ||
            ticket.name.toLowerCase().contains('friedrichshafen'))
        .toList();

    // Wenn keine Gym-spezifischen Tickets verfügbar sind, zeige nichts an
    if (gymTickets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Organisiere Tickets nach Standorten
    final bregenzTickets = gymTickets
        .where((ticket) => ticket.name.toLowerCase().contains('bregenz'))
        .toList();
    final friedrichshafenTickets = gymTickets
        .where(
            (ticket) => ticket.name.toLowerCase().contains('friedrichshafen'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Standort-spezifische Tickets',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Spezielle Angebote einzelner Standorte',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Standort-spezifische Ticket-Optionen
        Column(
          children: [
            // Bregenz Tickets
            if (bregenzTickets.isNotEmpty) ...[
              _buildGymLocationCard(
                'Greifbar Bregenz',
                '🇦🇹 Österreich',
                bregenzTickets,
                Colors.red,
              ),
              const SizedBox(height: 12),
            ],

            // Friedrichshafen Tickets
            if (friedrichshafenTickets.isNotEmpty) ...[
              _buildGymLocationCard(
                'Greifbar Friedrichshafen',
                '🇩🇪 Deutschland',
                friedrichshafenTickets,
                Colors.green,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildGymLocationCard(
      String gymName, String location, List<TicketType> tickets, Color color) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(
            Icons.fitness_center,
            color: Colors.white,
          ),
        ),
        title: Text(
          gymName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('$location • ${tickets.length} spezielle Angebote'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: tickets
                  .map((ticket) => _buildGymTicketOption(ticket, color))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGymTicketOption(TicketType ticket, Color color) {
    // Prüfe Purchase-Status
    final purchaseStatus = _purchaseStatuses[ticket.id];
    final hasPurchased = purchaseStatus?.hasPurchased == true;
    final isPrintingPending = purchaseStatus?.isPrintingPending == true;

    // Bestimme Button-Status
    Color buttonColor;
    IconData buttonIcon;
    VoidCallback? onTap;

    if (hasPurchased && isPrintingPending) {
      buttonColor = Colors.green;
      buttonIcon = Icons.print;
      onTap = () => _showPrintDialog(ticket.id!);
    } else if (hasPurchased) {
      buttonColor = Colors.green;
      buttonIcon = Icons.check_circle;
      onTap = () {
        // Zeige Erfolgsmeldung für gekaufte Tickets
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$ticket.name bereits gekauft und bereit!'),
            backgroundColor: Colors.green,
          ),
        );
      };
    } else {
      buttonColor = color;
      buttonIcon = _getTicketIcon(ticket);
      onTap = () => _purchaseGymTicket(ticket);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: hasPurchased ? Colors.green.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: buttonColor,
          radius: 20,
          child: Icon(buttonIcon, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                ticket.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasPurchased ? Colors.green.shade700 : null,
                ),
              ),
            ),
            if (hasPurchased) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPrintingPending ? Colors.orange : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPrintingPending ? 'ZUM DRUCKEN' : 'GEKAUFT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          ticket.description ??
              '${ticket.defaultPrice.toStringAsFixed(2)} € - ${_getTicketTypeDescription(ticket)}',
          style: TextStyle(
            color: hasPurchased ? Colors.green.shade600 : null,
          ),
        ),
        trailing: _isPrinting && hasPurchased && isPrintingPending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                hasPurchased
                    ? (isPrintingPending ? Icons.print : Icons.check_circle)
                    : Icons.arrow_forward_ios,
                color: buttonColor,
                size: hasPurchased ? 24 : 16,
              ),
        onTap: _isLoading || _isPrinting ? null : onTap,
      ),
    );
  }

  IconData _getTicketIcon(TicketType ticket) {
    if (ticket.isPointBased) {
      return Icons.credit_card;
    } else if (ticket.isSubscription) {
      return Icons.card_membership;
    } else {
      return Icons.confirmation_number;
    }
  }

  String _getTicketTypeDescription(TicketType ticket) {
    if (ticket.isPointBased) {
      return 'Punktekarte';
    } else if (ticket.isSubscription) {
      return 'Abonnement';
    } else {
      return 'Einzelticket';
    }
  }

  Future<void> _purchaseGymTicket(TicketType ticket) async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🎫 Kaufe Gym-Ticket: ${ticket.name} (ID: ${ticket.id})');
      await widget.client.ticket.purchaseTicket(ticket.id!);

      // Tickets und Purchase-Status neu laden
      await _loadTickets();
      await _loadPurchaseStatuses();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ticket.name} erfolgreich gekauft!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Drucken',
            onPressed: () => _showPrintDialog(ticket.id!),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Kaufen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class TicketCard extends StatelessWidget {
  final Ticket ticket;

  const TicketCard({
    super.key,
    required this.ticket,
  });

  // Statische Referenz für den Client (wird in main.dart gesetzt)
  static Client? _client;
  static void setClient(Client client) {
    _client = client;
  }

  // Cache für Ticket-Typ-Namen
  static final Map<int, String> _ticketTypeCache = <int, String>{};

  Future<String> _getTicketTypeName() async {
    // Cache prüfen
    if (_ticketTypeCache.containsKey(ticket.ticketTypeId)) {
      return _ticketTypeCache[ticket.ticketTypeId]!;
    }

    if (_client == null) {
      return 'Ticket-Typ ${ticket.ticketTypeId}';
    }

    try {
      // Aus Datenbank laden
      final ticketType =
          await _client!.ticketType.getTicketTypeById(ticket.ticketTypeId);
      final name = ticketType?.name ?? 'Unbekannt';

      // In Cache speichern
      _ticketTypeCache[ticket.ticketTypeId] = name;
      return name;
    } catch (e) {
      return 'Ticket-Typ ${ticket.ticketTypeId}';
    }
  }

  bool get isValid {
    final now = DateTime.now();

    // Punktebasierte Tickets: gültig wenn Punkte übrig
    if (ticket.remainingPoints != null) {
      return ticket.remainingPoints! > 0;
    }

    // Abonnements: gültig wenn aktiv und nicht abgelaufen
    if (ticket.subscriptionStatus == 'ACTIVE') {
      return ticket.nextBillingDate == null ||
          ticket.nextBillingDate!.isAfter(now);
    }

    // Normale Tickets: gültig wenn nicht verwendet und nicht abgelaufen
    return !ticket.isUsed && ticket.expiryDate.isAfter(now);
  }

  String get validityInfo {
    // Punktebasierte Tickets
    if (ticket.remainingPoints != null) {
      return '${ticket.remainingPoints} von ${ticket.initialPoints ?? 'N/A'} Punkten verbleibend';
    }

    // Abonnements
    if (ticket.subscriptionStatus == 'ACTIVE') {
      if (ticket.nextBillingDate != null) {
        return 'Gültig bis ${DateFormat('dd.MM.yyyy').format(ticket.nextBillingDate!)}';
      }
      return 'Aktives Abonnement';
    }

    // Normale Tickets
    if (ticket.isUsed) {
      return 'Bereits verwendet';
    }

    final now = DateTime.now();
    if (ticket.expiryDate.isBefore(now)) {
      return 'Abgelaufen am ${DateFormat('dd.MM.yyyy').format(ticket.expiryDate)}';
    }

    return 'Gültig bis ${DateFormat('dd.MM.yyyy').format(ticket.expiryDate)}';
  }

  String get gymInfo {
    // Vereinfacht - später durch echte Gym-Zuordnungen aus der Datenbank ersetzen
    return 'Vertic - Alle Standorte';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: isValid ? null : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status-Icon anstatt QR-Code
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isValid
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isValid ? Icons.check_circle : Icons.cancel,
                    size: 30,
                    color: isValid ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                // Ticket-Informationen
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _getTicketTypeName(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Laden...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isValid ? null : Colors.grey,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gymInfo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        validityInfo,
                        style: TextStyle(
                          fontSize: 14,
                          color: isValid ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Preis: ${ticket.price.toStringAsFixed(2)} €',
                        style: TextStyle(
                          color: isValid
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status-Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isValid
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isValid ? 'GÜLTIG' : 'UNGÜLTIG',
                    style: TextStyle(
                      color: isValid ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
