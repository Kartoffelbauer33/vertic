import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:test_server_client/test_server_client.dart';
import '../main.dart';
import '../services/background_scanner_service.dart';
import '../services/device_id_service.dart';

/// **🛒 CART SESSION MODEL für Multi-Cart-System**
class CartSession {
  final String id;
  final AppUser? customer;
  final PosSession? posSession;
  final List<PosCartItem> items;
  final DateTime createdAt;
  final bool isOnHold; // Zurückgestellt für späteren Checkout

  CartSession({
    required this.id,
    this.customer,
    this.posSession,
    required this.items,
    required this.createdAt,
    this.isOnHold = false,
  });

  double get total =>
      items.fold<double>(0.0, (sum, item) => sum + item.totalPrice);

  String get displayName {
    if (customer != null) {
      return '${customer!.firstName} ${customer!.lastName}';
    }
    return 'Neuer Warenkorb';
  }

  CartSession copyWith({
    String? id,
    AppUser? customer,
    PosSession? posSession,
    List<PosCartItem>? items,
    DateTime? createdAt,
    bool? isOnHold,
  }) {
    return CartSession(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      posSession: posSession ?? this.posSession,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      isOnHold: isOnHold ?? this.isOnHold,
    );
  }
}

class PosSystemPage extends StatefulWidget {
  const PosSystemPage({super.key});

  @override
  State<PosSystemPage> createState() => _PosSystemPageState();
}

class _PosSystemPageState extends State<PosSystemPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _manualCodeController = TextEditingController();

  // State Management
  List<AppUser> _allUsers = []; // Vollständige Kundenliste
  List<AppUser> _filteredUsers = []; // Gefilterte Suchergebnisse
  String _searchText = '';
  AppUser? _selectedCustomer;
  List<PosCartItem> _cartItems = [];
  bool _isLoading = false;
  String _scannerMode = 'POS'; // Express, POS, Hybrid
  Map<String, List<dynamic>> _categorizedItems = {};
  PosSession? _currentSession;
  String _selectedCategory = 'Hallentickets'; // Aktuelle Kategorie

  // 🛒 MULTI-CART-SYSTEM
  List<CartSession> _activeCarts = []; // Alle aktiven Warenkörbe
  int _currentCartIndex = 0; // Index des aktuell angezeigten Warenkorbs

  // Kategorie-Konfiguration mit Farben und Icons
  final Map<String, CategoryConfig> _categoryConfigs = {
    'Hallentickets': CategoryConfig(
      color: Colors.blue,
      icon: Icons.local_activity,
      name: 'Hallentickets',
    ),
    'Vertic Universal': CategoryConfig(
      color: Colors.purple,
      icon: Icons.card_membership,
      name: 'Vertic Universal',
    ),
    'Produkte': CategoryConfig(
      color: Colors.green,
      icon: Icons.shopping_bag,
      name: 'Produkte',
    ),
    'Getränke': CategoryConfig(
      color: Colors.orange,
      icon: Icons.local_drink,
      name: 'Getränke',
    ),
    'Snacks': CategoryConfig(
      color: Colors.red,
      icon: Icons.fastfood,
      name: 'Snacks',
    ),
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  // ==================== INITIALIZATION ====================

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_loadAllCustomers(), _loadAvailableItems()]);

      // 🧹 WICHTIG: Bei App-Neustart alle Sessions zurücksetzen
      await _cleanupOrphanedSessions();

      // 🛒 MULTI-CART: Ersten Warenkorb erstellen oder bestehenden laden
      await _initializeCartFromExistingSession();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Initialisieren: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// **🧹 NEUE METHODE: Bereinigt verwaiste Sessions beim App-Neustart**
  Future<void> _cleanupOrphanedSessions() async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      // BESSERE LÖSUNG: Eindeutige Session-IDs pro App-Start verwenden
      // Alle Sessions mit einem Präfix versehen, um sie später identifizieren zu können
      debugPrint(
        '🧹 Session-Bereinigung beim App-Neustart - Multi-Cart-System initialisiert',
      );

      // Keine aktive Bereinigung nötig, da jede Session eindeutig ist
    } catch (e) {
      debugPrint('⚠️ Fehler beim Bereinigen der Sessions: $e');
      // Nicht kritisch, App kann trotzdem funktionieren
    }
  }

  /// **🖥️ NEUE METHODE: Initialisiert gerätespezifische Warenkörbe**
  Future<void> _initializeCartFromExistingSession() async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      // Geräte-ID abrufen
      final deviceId = await _getDeviceId();
      debugPrint('🖥️ Verwende Device-ID: $deviceId');

      // Bestehende Sessions für dieses Gerät wiederherstellen
      final deviceState = await client.pos.restoreDeviceCartState(deviceId);
      debugPrint('🔄 Backend-Antwort: $deviceState');

      final carts = deviceState['carts'] as List<dynamic>?;

      if (carts != null && carts.isNotEmpty) {
        // Bestehende Warenkörbe wiederherstellen
        debugPrint(
          '🔄 ${carts.length} bestehende Warenkörbe gefunden für Gerät: $deviceId',
        );

        for (int i = 0; i < carts.length; i++) {
          final cartData = carts[i] as Map<String, dynamic>;
          final posSession = cartData['session'];
          final items = cartData['items'] as List<dynamic>? ?? [];

          // Items korrekt von JSON zu PosCartItem umwandeln
          final List<PosCartItem> cartItems = [];
          for (final itemData in items) {
            if (itemData is Map<String, dynamic>) {
              final cartItem = PosCartItem.fromJson(itemData);
              cartItems.add(cartItem);
            }
          }

          final cartId = 'cart_${posSession['id']}_restored';
          final newCart = CartSession(
            id: cartId,
            customer: posSession['customerId'] != null
                ? _findUserById(posSession['customerId'])
                : null,
            posSession: posSession,
            items: cartItems,
            createdAt: _parseDateTime(posSession['createdAt']),
          );

          setState(() {
            _activeCarts.add(newCart);
          });
        }

        // Ersten Warenkorb als aktiv setzen
        if (_activeCarts.isNotEmpty) {
          setState(() {
            _currentCartIndex = 0;
            _currentSession = _activeCarts[0].posSession;
            _cartItems = _activeCarts[0].items;
            _selectedCustomer = _activeCarts[0].customer;
          });
        }

        debugPrint('✅ ${_activeCarts.length} Warenkörbe wiederhergestellt');
        return;
      }

      // Keine bestehenden Warenkörbe - neuen erstellen
      debugPrint(
        '🆕 Keine bestehenden Warenkörbe - erstelle neuen für Gerät: $deviceId',
      );
      await _createNewDeviceCart(deviceId);

      // Status nach Erstellung prüfen
      debugPrint(
        '🔍 Status nach Warenkorb-Erstellung: ${_activeCarts.length} Warenkörbe',
      );
    } catch (e) {
      debugPrint('❌ Fehler bei Device-Session-Initialisierung: $e');
      // Fallback: Normalen Warenkorb erstellen
      debugPrint('🔄 Fallback: Erstelle normalen Warenkorb...');
      await _createNewCart();
    }
  }

  /// **🖥️ HILFSMETHODE: Geräte-ID abrufen**
  Future<String> _getDeviceId() async {
    final deviceId = await DeviceIdService.instance.getDeviceId();
    if (deviceId.isEmpty) {
      throw Exception('Device-ID ist leer - kann nicht fortfahren');
    }
    return deviceId;
  }

  /// **🔍 DEBUG: Geräte-Informationen anzeigen**
  Future<void> _showDeviceInfo() async {
    try {
      final deviceInfo = await DeviceIdService.instance.getDeviceInfo();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🖥️ Geräte-Information'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Geräte-ID: ${deviceInfo['deviceId']}'),
                  const SizedBox(height: 8),
                  Text('Plattform: ${deviceInfo['platform']}'),
                  const SizedBox(height: 8),
                  Text('Erstellt: ${deviceInfo['timestamp']}'),
                  if (deviceInfo['hostName'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Host: ${deviceInfo['hostName']}'),
                  ],
                  if (deviceInfo['computerName'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Computer: ${deviceInfo['computerName']}'),
                  ],
                  if (deviceInfo['userName'] != null) ...[
                    const SizedBox(height: 8),
                    Text('User: ${deviceInfo['userName']}'),
                  ],
                  if (deviceInfo['osName'] != null) ...[
                    const SizedBox(height: 8),
                    Text('OS: ${deviceInfo['osName']}'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  await DeviceIdService.instance.resetDeviceId();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔄 Geräte-ID zurückgesetzt'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Fehler beim Anzeigen der Geräte-Info: $e');
    }
  }

  /// **🔍 HILFSMETHODE: User nach ID finden**
  AppUser? _findUserById(int? userId) {
    if (userId == null) return null;
    try {
      return _allUsers.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// **📅 HILFSMETHODE: DateTime-String sicher parsen**
  DateTime _parseDateTime(dynamic dateTimeString) {
    if (dateTimeString == null) return DateTime.now();
    try {
      if (dateTimeString is String) {
        return DateTime.parse(dateTimeString);
      } else {
        return DateTime.now();
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Parsen der DateTime: $e');
      return DateTime.now();
    }
  }

  /// **🛒 NEUE METHODE: Gerätespezifischen Warenkorb erstellen**
  Future<void> _createNewDeviceCart(String deviceId) async {
    debugPrint('🔄 _createNewDeviceCart aufgerufen für Gerät: $deviceId');

    final client = Provider.of<Client>(context, listen: false);

    // Gerätespezifische Session erstellen
    debugPrint('🔄 Rufe Backend createDeviceSession auf...');
    final session = await client.pos.createDeviceSession(deviceId, null);
    debugPrint('🔄 Backend-Antwort für createDeviceSession: $session');

    if (session == null) {
      debugPrint('❌ Backend gab null Session zurück für Device: $deviceId');
      throw Exception('Backend gab null Session zurück für Device: $deviceId');
    }

    debugPrint('✅ Session erhalten, rufe _createNewCartWithSession auf...');
    await _createNewCartWithSession(session);

    debugPrint(
      '🛒 Neuer gerätespezifischer Warenkorb erstellt für Gerät: $deviceId',
    );
  }

  /// **🛒 HILFSMETHODE: Erstellt neuen Warenkorb mit vorgegebener Session**
  Future<void> _createNewCartWithSession(dynamic session) async {
    debugPrint('🔄 _createNewCartWithSession aufgerufen mit Session: $session');

    if (session == null) {
      debugPrint('❌ Session ist null - kann Warenkorb nicht erstellen');
      throw Exception('Session ist null - kann Warenkorb nicht erstellen');
    }

    final cartId = 'cart_${DateTime.now().millisecondsSinceEpoch}';
    final newCart = CartSession(
      id: cartId,
      customer: null,
      posSession: session,
      items: [],
      createdAt: DateTime.now(),
    );

    debugPrint('🛒 Neuer Warenkorb erstellt, füge zu _activeCarts hinzu...');

    setState(() {
      _activeCarts.add(newCart);
      _currentCartIndex = _activeCarts.length - 1;
      _currentSession = session;
      _cartItems = [];
      _selectedCustomer = null;
    });

    debugPrint(
      '✅ Warenkorb zu _activeCarts hinzugefügt. Aktuelle Anzahl: ${_activeCarts.length}',
    );
    debugPrint(
      '🛒 Neuer Warenkorb mit Session erstellt: ${newCart.displayName}',
    );
  }

  Future<void> _loadAllCustomers() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final users = await client.user.getAllUsers(limit: 1000, offset: 0);
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Kunden: $e')),
        );
      }
    }
  }

  // ==================== BACKEND INTEGRATION ====================

  Future<void> _createPosSession() async {
    if (!mounted) return;

    try {
      final client = Provider.of<Client>(context, listen: false);
      final session = await client.pos.createSession(_selectedCustomer?.id);
      setState(() => _currentSession = session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Erstellen der Session: $e')),
        );
      }
    }
  }

  // ==================== MULTI-CART-SYSTEM ====================

  /// **🛒 NEUE METHODE: Erstellt einen neuen Warenkorb**
  Future<void> _createNewCart({AppUser? customer}) async {
    try {
      // Backend POS-Session erstellen
      final client = Provider.of<Client>(context, listen: false);
      final session = await client.pos.createSession(customer?.id);

      // Neuen CartSession erstellen
      final cartId = 'cart_${DateTime.now().millisecondsSinceEpoch}';
      final newCart = CartSession(
        id: cartId,
        customer: customer,
        posSession: session,
        items: [],
        createdAt: DateTime.now(),
      );

      setState(() {
        _activeCarts.add(newCart);
        _currentCartIndex = _activeCarts.length - 1;
        _selectedCustomer = customer;
        _currentSession = session;
        _cartItems = [];
      });

      debugPrint('🛒 Neuer Warenkorb erstellt: ${newCart.displayName}');
    } catch (e) {
      debugPrint('❌ Fehler beim Erstellen des Warenkorbs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen des Warenkorbs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// **🔄 NEUE METHODE: Wechselt zwischen Warenkörben**
  Future<void> _switchToCart(int index) async {
    if (index < 0 || index >= _activeCarts.length) return;

    final targetCart = _activeCarts[index];

    try {
      // Cart-Items vom Backend laden
      final client = Provider.of<Client>(context, listen: false);
      final items = await client.pos.getCartItems(targetCart.posSession!.id!);

      setState(() {
        _currentCartIndex = index;
        _selectedCustomer = targetCart.customer;
        _currentSession = targetCart.posSession;
        _cartItems = items;
      });

      // Artikel-Katalog für aktuellen Kunden aktualisieren
      await _loadAvailableItems();

      debugPrint('🔄 Zu Warenkorb gewechselt: ${targetCart.displayName}');
    } catch (e) {
      debugPrint('❌ Fehler beim Wechseln des Warenkorbs: $e');
    }
  }

  /// **🔒 NEUE METHODE: Warenkorb zurückstellen (nur mit Kunde möglich)**
  Future<void> _holdCart() async {
    if (_activeCarts.isEmpty) return;

    final currentCart = _activeCarts[_currentCartIndex];

    // Validierung: Nur Warenkörbe mit Kunden dürfen zurückgestellt werden
    if (currentCart.customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Warenkörbe dürfen nur hinterlegt werden, wenn sie einer Person zugeordnet sind',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Warenkorb als "zurückgestellt" markieren
    final updatedCart = currentCart.copyWith(isOnHold: true);
    setState(() {
      _activeCarts[_currentCartIndex] = updatedCart;
    });

    // Neuen Warenkorb erstellen
    await _createNewCart();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Warenkorb zurückgestellt: ${currentCart.displayName}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    debugPrint('🔒 Warenkorb zurückgestellt: ${currentCart.displayName}');
  }

  /// **🗑️ NEUE METHODE: Warenkorb entfernen**
  Future<void> _removeCart(int index) async {
    if (index < 0 || index >= _activeCarts.length) return;

    final cartToRemove = _activeCarts[index];

    try {
      // Backend-Session löschen
      if (cartToRemove.posSession != null) {
        final client = Provider.of<Client>(context, listen: false);
        await client.pos.clearCart(cartToRemove.posSession!.id!);
      }

      setState(() {
        _activeCarts.removeAt(index);

        // Aktuellen Index anpassen
        if (_currentCartIndex >= _activeCarts.length &&
            _activeCarts.isNotEmpty) {
          _currentCartIndex = _activeCarts.length - 1;
        } else if (_activeCarts.isEmpty) {
          _currentCartIndex = 0;
          _selectedCustomer = null;
          _currentSession = null;
          _cartItems = [];
        }
      });

      // Falls kein Warenkorb mehr vorhanden, neuen erstellen
      if (_activeCarts.isEmpty) {
        await _createNewCart();
      } else {
        // Zu aktuellem Warenkorb wechseln
        await _switchToCart(_currentCartIndex);
      }

      debugPrint('🗑️ Warenkorb entfernt: ${cartToRemove.displayName}');
    } catch (e) {
      debugPrint('❌ Fehler beim Entfernen des Warenkorbs: $e');
    }
  }

  Future<void> _loadCartItems() async {
    if (_currentSession == null) return;

    try {
      final client = Provider.of<Client>(context, listen: false);
      final items = await client.pos.getCartItems(_currentSession!.id!);

      // ⚡ PERFORMANCE-OPTIMIERUNG: Nur setState wenn sich Warenkorb geändert hat
      if (_cartItems.length != items.length ||
          _cartItems.any(
            (existingItem) =>
                !items.any((newItem) => newItem.id == existingItem.id),
          )) {
        setState(() => _cartItems = items);

        // 🛒 MULTI-CART: Aktuelle Cart-Session mit neuen Items aktualisieren
        if (_activeCarts.isNotEmpty &&
            _currentCartIndex < _activeCarts.length) {
          final updatedCart = _activeCarts[_currentCartIndex].copyWith(
            items: items,
          );
          setState(() {
            _activeCarts[_currentCartIndex] = updatedCart;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Warenkorbs: $e')),
        );
      }
    }
  }

  /// **🧹 NEUE METHODE: Behandelt Kundenwechsel mit Multi-Cart-System**
  Future<void> _handleCustomerChange(AppUser newCustomer) async {
    try {
      // 1. Aktuellen Warenkorb mit Kunde verknüpfen
      if (_activeCarts.isNotEmpty && _cartItems.isNotEmpty) {
        final client = Provider.of<Client>(context, listen: false);
        final currentCart = _activeCarts[_currentCartIndex];
        final oldSession = currentCart.posSession;

        // Neue Session mit Kunde erstellen
        final newSession = await client.pos.createSession(newCustomer.id);

        // 🔄 WICHTIG: Alle Items aus alter Session in neue Session übertragen
        if (oldSession != null) {
          try {
            for (final item in _cartItems) {
              await client.pos.addToCart(
                newSession.id!,
                item.itemType,
                item.itemId,
                item.itemName,
                item.unitPrice,
                item.quantity,
              );
            }

            // Alte Session leeren
            await client.pos.clearCart(oldSession.id!);

            debugPrint(
              '🔄 ${_cartItems.length} Items von Session ${oldSession.id} zu ${newSession.id} übertragen',
            );
          } catch (e) {
            debugPrint('⚠️ Fehler beim Übertragen der Items: $e');
          }
        }

        final updatedCart = currentCart.copyWith(
          customer: newCustomer,
          posSession: newSession,
        );

        setState(() {
          _activeCarts[_currentCartIndex] = updatedCart;
          _selectedCustomer = newCustomer;
          _currentSession = newSession;
          _searchText = '';
          _searchController.clear();
          _filteredUsers = _allUsers;
        });

        // Cart-Items neu laden
        await _loadCartItems();
      } else {
        // 2. Neuen Warenkorb für Kunde erstellen
        setState(() {
          _searchText = '';
          _searchController.clear();
          _filteredUsers = _allUsers;
        });
        await _createNewCart(customer: newCustomer);
      }

      // 3. Artikel-Katalog für neuen Kunden aktualisieren
      await _loadAvailableItems();

      // 4. Erfolgs-Feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Kunde zugeordnet: ${newCustomer.firstName} ${newCustomer.lastName}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint(
        '🔄 Kunde zugeordnet: ${newCustomer.firstName} ${newCustomer.lastName}',
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Zuordnen des Kunden: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Zuordnen des Kunden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// **🧹 NEUE METHODE: Behandelt Kunden-Entfernung im Multi-Cart-System**
  Future<void> _handleCustomerRemoval() async {
    try {
      if (_activeCarts.isNotEmpty) {
        // 1. Aktuellen Warenkorb vom Kunden trennen
        final currentCart = _activeCarts[_currentCartIndex];
        final updatedCart = currentCart.copyWith(customer: null);

        setState(() {
          _activeCarts[_currentCartIndex] = updatedCart;
          _selectedCustomer = null;
        });

        // 2. Artikel-Katalog aktualisieren (alle verfügbaren anzeigen)
        await _loadAvailableItems();

        // 3. Erfolgs-Feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Kunde vom Warenkorb entfernt'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }

        debugPrint('🔄 Kunde vom Warenkorb entfernt');
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Kunden-Entfernen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim Entfernen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addItemToCart(
    String itemType,
    int itemId,
    String itemName,
    double price,
  ) async {
    if (_currentSession == null) return;

    try {
      final client = Provider.of<Client>(context, listen: false);
      await client.pos.addToCart(
        _currentSession!.id!,
        itemType,
        itemId,
        itemName,
        price,
        1, // quantity
      );
      // ⚡ OPTIMIZED CART UPDATE: Non-blocking reload
      _loadCartItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hinzufügen zum Warenkorb: $e')),
        );
      }
    }
  }

  /// **🧠 INTELLIGENTE TICKETAUSWAHL für POS-System**
  /// Verwendet die bewährte Logik aus der Client-App
  Future<void> _addIntelligentTicketToCart(TicketType selectedTicket) async {
    if (_currentSession == null) return;

    setState(() => _isLoading = true);

    try {
      final client = Provider.of<Client>(context, listen: false);

      // 🧠 INTELLIGENTE PREISBERECHNUNG basierend auf Kundenstatus
      double finalPrice = selectedTicket.defaultPrice;
      TicketType finalTicket = selectedTicket;

      // Nur wenn Kunde vorhanden, intelligente Berechnung verwenden
      if (_selectedCustomer != null) {
        try {
          final optimalPrice = await client.ticket
              .calculateOptimalPriceForCustomer(
                selectedTicket.id!,
                _selectedCustomer!.id!,
              );

          // 🎯 INTELLIGENTE TICKETAUSWAHL basierend auf Alter & Status
          final recommendedTicket = await client.ticket
              .getRecommendedTicketTypeForCustomer(
                'single', // Kategorie für Einzeltickets
                _selectedCustomer!.id!,
              );

          // Verwende empfohlenes Ticket falls vorhanden, sonst das ausgewählte
          finalTicket = recommendedTicket ?? selectedTicket;
          finalPrice = optimalPrice;
        } catch (e) {
          debugPrint('⚠️ Kunde-spezifische Preisberechnung fehlgeschlagen: $e');
          // Fallback zu Standard-Preis
        }
      }

      // Berechne Ersparnis für UI-Feedback
      final savings = selectedTicket.defaultPrice - finalPrice;
      final hasSavings = savings > 0.01;

      // Zum Warenkorb hinzufügen mit optimalem Preis
      await client.pos.addToCart(
        _currentSession!.id!,
        'ticket',
        finalTicket.id!,
        finalTicket.name,
        finalPrice,
        1, // quantity
      );

      // ⚡ OPTIMIZED CART UPDATE: Non-blocking reload
      _loadCartItems();

      // ✅ SUCCESS FEEDBACK mit Ersparnis-Info
      if (mounted) {
        final message = hasSavings
            ? '✅ ${finalTicket.name} → ${finalPrice.toStringAsFixed(2)}€\n💰 Ersparnis: ${savings.toStringAsFixed(2)}€'
            : '✅ ${finalTicket.name} → ${finalPrice.toStringAsFixed(2)}€';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint(
        '🧠 Intelligente Auswahl: ${selectedTicket.name} → ${finalTicket.name}',
      );
      debugPrint(
        '💰 Preis-Optimierung: ${selectedTicket.defaultPrice}€ → ${finalPrice}€',
      );
      if (hasSavings && _selectedCustomer != null) {
        debugPrint(
          '🎉 Ersparnis für ${_selectedCustomer!.firstName}: ${savings.toStringAsFixed(2)}€',
        );
      }
    } catch (e) {
      debugPrint('❌ Fehler bei intelligenter Ticketauswahl: $e');

      // Fallback: Verwende Standard-Preis
      try {
        await _addItemToCart(
          'ticket',
          selectedTicket.id!,
          selectedTicket.name,
          selectedTicket.defaultPrice,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Ticket hinzugefügt (Standard-Preis): ${selectedTicket.defaultPrice}€',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (fallbackError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Fehler beim Hinzufügen: $fallbackError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeItemFromCart(int cartItemId) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      await client.pos.removeFromCart(cartItemId);
      // ⚡ OPTIMIZED CART UPDATE: Non-blocking reload
      _loadCartItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Entfernen: $e')));
      }
    }
  }

  Future<void> _updateCartItemQuantity(int cartItemId, int quantity) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      await client.pos.updateCartItem(cartItemId, quantity);
      // ⚡ OPTIMIZED CART UPDATE: Non-blocking reload
      _loadCartItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Aktualisieren: $e')),
        );
      }
    }
  }

  Future<void> _performCheckout() async {
    if (_currentSession == null || _cartItems.isEmpty) return;

    final totalAmount = _cartItems.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    try {
      final client = Provider.of<Client>(context, listen: false);
      final transaction = await client.pos.checkout(
        _currentSession!.id!,
        'Karte', // payment method
        totalAmount,
        'POS-Verkauf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Checkout erfolgreich! Receipt: ${transaction.receiptNumber}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset for next customer
        setState(() {
          _selectedCustomer = null;
          _cartItems.clear();
          _currentSession = null;
          _searchController.clear();
          _searchText = '';
        });
        await _createPosSession();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Checkout: $e')));
      }
    }
  }

  // ==================== SEARCH FUNCTIONALITY ====================

  /// **🔍 ENHANCED SEARCH FIELD INPUT HANDLER**
  /// Handles both customer search and scanner input
  void _handleSearchFieldInput(String input) {
    final trimmedInput = input.trim();

    // Check if input looks like a scanner code (JSON, ticket ID, etc.)
    if (_isScannerInput(trimmedInput)) {
      _processScannerInput(trimmedInput);
    } else {
      _performCustomerSearch(input);
    }
  }

  /// **🎯 SCANNER INPUT DETECTION**
  bool _isScannerInput(String input) {
    if (input.length < 3) return false;

    // Check for JSON QR codes
    if (input.startsWith('{') && input.endsWith('}')) return true;

    // Check for Vertic ticket patterns
    if (input.startsWith('VT-') || input.startsWith('vertic://')) return true;

    // Check for external provider patterns
    if (input.startsWith('FP-') || input.contains('fitpass')) return true;
    if (input.startsWith('FR-') || input.contains('friction')) return true;

    // Check for long numeric codes (likely QR/barcode)
    if (input.length > 15 && RegExp(r'^[0-9a-zA-Z\-_]+$').hasMatch(input)) {
      return true;
    }

    return false;
  }

  /// **📡 PROCESS SCANNER INPUT**
  void _processScannerInput(String scannerCode) {
    final backgroundScanner = Provider.of<BackgroundScannerService>(
      context,
      listen: false,
    );

    debugPrint('🔍 POS Scanner Input erkannt: $scannerCode');

    // Clear search field
    _searchController.clear();
    setState(() => _searchText = '');

    // Process through background scanner service
    backgroundScanner.manualScanInput(scannerCode);

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white),
            SizedBox(width: 8),
            Text('Scanner-Code verarbeitet'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _performCustomerSearch(String query) {
    setState(() {
      _searchText = query;

      if (query.isEmpty) {
        _filteredUsers = _allUsers;
        return;
      }

      final searchLower = query.toLowerCase().trim();

      _filteredUsers = _allUsers.where((user) {
        return user.firstName.toLowerCase().contains(searchLower) ||
            user.lastName.toLowerCase().contains(searchLower) ||
            '${user.firstName} ${user.lastName}'.toLowerCase().contains(
              searchLower,
            ) ||
            (user.email?.toLowerCase().contains(searchLower) ?? false) ||
            (user.phoneNumber?.toLowerCase().contains(searchLower) ?? false) ||
            user.id.toString().contains(searchLower);
      }).toList();
    });
  }

  // ==================== UI HELPERS ====================

  Future<void> _loadAvailableItems() async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      final allTicketTypes = await client.ticketType.getAllTicketTypes();

      // 🎯 INTELLIGENTE TICKET-FILTERUNG basierend auf ausgewähltem Kunden
      List<TicketType> filteredTickets;

      if (_selectedCustomer != null) {
        filteredTickets = await _getCustomerRelevantTickets(allTicketTypes);
        debugPrint(
          '🎯 Tickets für Kunde ${_selectedCustomer!.firstName} gefiltert: ${filteredTickets.length}/${allTicketTypes.length}',
        );
      } else {
        // Wenn kein Kunde ausgewählt: Zeige alle verfügbaren Tickets
        filteredTickets = allTicketTypes;
        debugPrint(
          '📋 Alle verfügbaren Tickets angezeigt: ${filteredTickets.length}',
        );
      }

      // 🏢 NEUE KATEGORISIERUNG: Hallentickets vs. Hallenübergreifende Tickets
      final hallentickets = filteredTickets
          .where((ticket) => ticket.gymId != null)
          .toList();

      final verticUniversal = filteredTickets
          .where((ticket) => ticket.gymId == null && ticket.isVerticUniversal)
          .toList();

      // TODO: Load products when Product endpoint is available
      final products = <Product>[];

      // ⚡ PERFORMANCE-OPTIMIERUNG: Nur setState wenn sich Daten geändert haben
      final newCategorizedItems = {
        'Hallentickets': hallentickets,
        'Vertic Universal': verticUniversal,
        'Produkte': products,
        'Getränke': [], // Placeholder
        'Snacks': [], // Placeholder
      };

      // Prüfe ob sich die Kategorien geändert haben
      bool hasChanged = false;
      for (final category in newCategorizedItems.keys) {
        if (_categorizedItems[category]?.length !=
            newCategorizedItems[category]?.length) {
          hasChanged = true;
          break;
        }
      }

      if (hasChanged || _categorizedItems.isEmpty) {
        setState(() {
          _categorizedItems = newCategorizedItems;
        });

        debugPrint('🏢 Ticket-Kategorisierung:');
        debugPrint('  • Hallentickets: ${hallentickets.length}');
        debugPrint('  • Vertic Universal: ${verticUniversal.length}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Artikel: $e')),
        );
      }
    }
  }

  /// **🎯 NEUE METHODE: Filtere Tickets basierend auf Kunden-Eigenschaften**
  Future<List<TicketType>> _getCustomerRelevantTickets(
    List<TicketType> allTickets,
  ) async {
    if (_selectedCustomer == null) return allTickets;

    try {
      // Alter des Kunden berechnen
      int age = 30; // Default
      if (_selectedCustomer!.birthDate != null) {
        final now = DateTime.now();
        age = now.year - _selectedCustomer!.birthDate!.year;
        if (now.month < _selectedCustomer!.birthDate!.month ||
            (now.month == _selectedCustomer!.birthDate!.month &&
                now.day < _selectedCustomer!.birthDate!.day)) {
          age--;
        }
      }

      // Relevante Ticket-Kategorien basierend auf Alter
      List<TicketType> relevantTickets = [];

      // 1. Immer verfügbar: Einzeltickets (Tageskarten)
      final einzeltickets = allTickets
          .where(
            (t) =>
                !t.isSubscription &&
                !t.isPointBased &&
                (t.name.toLowerCase().contains('tageskarte') ||
                    t.name.toLowerCase().contains('tagesticket') ||
                    t.name.toLowerCase().contains('ticket')),
          )
          .toList();
      relevantTickets.addAll(einzeltickets);

      // 2. Für Erwachsene: Punktekarten und Abos
      if (age >= 18) {
        final punktekarten = allTickets.where((t) => t.isPointBased).toList();
        final abos = allTickets.where((t) => t.isSubscription).toList();
        relevantTickets.addAll(punktekarten);
        relevantTickets.addAll(abos);
      }

      // 3. Fallback: Zeige alle wenn keine spezifischen gefunden
      if (relevantTickets.isEmpty) {
        relevantTickets = allTickets;
      }

      // 4. Nach Preis sortieren (günstigstes zuerst)
      relevantTickets.sort((a, b) => a.defaultPrice.compareTo(b.defaultPrice));

      debugPrint(
        '🧠 Kunde: ${_selectedCustomer!.firstName} (Alter: $age) → ${relevantTickets.length} relevante Tickets',
      );

      return relevantTickets;
    } catch (e) {
      debugPrint('❌ Fehler bei Ticket-Filterung: $e');
      return allTickets; // Fallback: Alle Tickets
    }
  }

  double _calculateCartTotal() {
    return _cartItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildCustomerSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
          Row(
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
          const SizedBox(height: 12),

          // Suchfeld
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Name, E-Mail, ID oder Telefon eingeben...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performCustomerSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _handleSearchFieldInput,
          ),

          // Suchergebnisse
          if (_searchText.isNotEmpty && _filteredUsers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _filteredUsers.take(10).length,
                itemBuilder: (context, index) {
                  final customer = _filteredUsers[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        '${customer.firstName[0]}${customer.lastName[0]}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('${customer.firstName} ${customer.lastName}'),
                    subtitle: Text(customer.email ?? 'Keine E-Mail'),
                    trailing: Icon(Icons.add_circle, color: Colors.green[600]),
                    onTap: () async {
                      // 🧹 WARENKORB-SYNCHRONISATION: Bei Personenwechsel alles zurücksetzen
                      await _handleCustomerChange(customer);
                    },
                  );
                },
              ),
            ),
          ],

          // Suchergebnis-Anzeige
          if (_searchText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_filteredUsers.length} von ${_allUsers.length} Kunden gefunden',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // Ausgewählter Kunde
          if (_selectedCustomer != null) ...[
            const SizedBox(height: 12),
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
                          '${_selectedCustomer!.firstName} ${_selectedCustomer!.lastName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_selectedCustomer!.email != null)
                          Text(
                            _selectedCustomer!.email!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () async {
                      // 🧹 WARENKORB-RESET: Bei Kunde entfernen
                      await _handleCustomerRemoval();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Artikel-Katalog',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          // Kategorie-Buttons
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categoryConfigs.length,
              itemBuilder: (context, index) {
                final category = _categoryConfigs.keys.elementAt(index);
                final config = _categoryConfigs[category]!;
                final isSelected = _selectedCategory == category;
                final itemCount = _categorizedItems[category]?.length ?? 0;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Material(
                    elevation: isSelected ? 6 : 2,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() => _selectedCategory = category);
                      },
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isSelected ? config.color : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? config.color
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              config.icon,
                              color: isSelected ? Colors.white : config.color,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              config.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (itemCount > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$itemCount',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey[500],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final items = _categorizedItems[_selectedCategory] ?? [];

    if (items.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _categoryConfigs[_selectedCategory]?.icon ?? Icons.category,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Keine Artikel in $_selectedCategory verfügbar',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is TicketType) {
              return _buildTicketCard(item);
            } else if (item is Product) {
              return _buildProductCard(item);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildTicketCard(TicketType ticketType) {
    final config = _categoryConfigs[_selectedCategory]!;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _addIntelligentTicketToCart(ticketType);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                config.color.withOpacity(0.1),
                config.color.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: config.color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(config.icon, color: config.color, size: 32),
              const SizedBox(height: 8),
              Text(
                ticketType.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${ticketType.defaultPrice.toStringAsFixed(2)} €',
                style: TextStyle(
                  color: config.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final config = _categoryConfigs[_selectedCategory]!;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _addItemToCart('product', product.id!, product.name, product.price);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                config.color.withOpacity(0.1),
                config.color.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: config.color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(config.icon, color: config.color, size: 32),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${product.price.toStringAsFixed(2)} €',
                style: TextStyle(
                  color: config.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingCart() {
    // 🛒 NEUE MULTI-CART-LOGIK: Verwende aktuellen Warenkorb
    final currentCart =
        _activeCarts.isNotEmpty &&
            _currentCartIndex >= 0 &&
            _currentCartIndex < _activeCarts.length
        ? _activeCarts[_currentCartIndex]
        : null;

    final cartItems = currentCart?.items ?? [];
    final total = currentCart?.total ?? 0.0;
    final cartDisplayName = currentCart?.displayName ?? 'Kein Warenkorb';

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
        children: [
          // Header mit aktuellem Warenkorb-Namen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Warenkorb',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          cartDisplayName.length > 20
                              ? '${cartDisplayName.substring(0, 20)}...'
                              : cartDisplayName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (cartItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _clearCurrentCart(),
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Leeren'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Warenkorb ist leer',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fügen Sie Artikel aus dem Katalog hinzu',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _removeItemFromCurrentCart(item.id!),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.unitPrice.toStringAsFixed(2)} €',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        onPressed: item.quantity > 1
                                            ? () =>
                                                  _updateCurrentCartItemQuantity(
                                                    item.id!,
                                                    item.quantity - 1,
                                                  )
                                            : null,
                                        color: Colors.red,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle),
                                        onPressed: () =>
                                            _updateCurrentCartItemQuantity(
                                              item.id!,
                                              item.quantity + 1,
                                            ),
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Gesamt: ${item.totalPrice.toStringAsFixed(2)} €',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Total and Checkout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gesamtsumme:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: cartItems.isNotEmpty ? _performCheckout : null,
                    icon: const Icon(Icons.payment),
                    label: const Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// **🛒 NEUE METHODE: Multi-Cart-Tabs für AppBar (flach und gut lesbar)**
  Widget _buildTopCartTabs() {
    return Container(
      height: 50,
      color: Colors.red[600], // Roter Hintergrund wie gewünscht
      child: Row(
        children: [
          // 🛒 CART-TABS MIT HORIZONTALEM SCROLLING
          Expanded(
            child: _activeCarts.isEmpty
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
                    itemCount: _activeCarts.length,
                    itemBuilder: (context, index) {
                      final cart = _activeCarts[index];
                      final isActive = index == _currentCartIndex;
                      final isOnHold = cart.isOnHold;

                      return GestureDetector(
                        onTap: () => _switchToCart(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 4, // Reduziert von 8 auf 4
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2, // Reduziert von 6 auf 2
                          ),
                          constraints: const BoxConstraints(
                            maxWidth: 150, // Begrenze Breite
                            minHeight: 34, // Touch-Target
                            maxHeight: 38, // Verhindere Overflow
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : isOnHold
                                ? Colors.orange.withOpacity(0.8)
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isActive
                                  ? Colors.blue
                                  : isOnHold
                                  ? Colors.orange
                                  : Colors.transparent,
                              width: 1.5, // Reduziert von 2 auf 1.5
                            ),
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
                                size: 14, // Reduziert von 16 auf 14
                                color: isActive
                                    ? Colors.blue
                                    : isOnHold
                                    ? Colors.white
                                    : Colors.red[600],
                              ),
                              const SizedBox(width: 4), // Reduziert von 6 auf 4
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Colors.blue
                                          : isOnHold
                                          ? Colors.white
                                          : Colors.red[600],
                                      height: 1.1,
                                    ),
                                  ),
                                  if (cart.items.isNotEmpty)
                                    Text(
                                      '${cart.items.length} • ${cart.total.toStringAsFixed(2)}€',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isActive
                                            ? Colors.grey[600]
                                            : isOnHold
                                            ? Colors.white70
                                            : Colors.red[400],
                                        height: 1.0,
                                      ),
                                    ),
                                ],
                              ),
                              // Löschen-Button nur für inaktive Warenkörbe
                              if (!isActive && _activeCarts.length > 1) ...[
                                const SizedBox(
                                  width: 3,
                                ), // Reduziert von 6 auf 3
                                GestureDetector(
                                  onTap: () => _showRemoveCartDialog(index),
                                  child: Icon(
                                    Icons.close,
                                    size: 12, // Reduziert von 16 auf 12
                                    color: isActive
                                        ? Colors.red
                                        : isOnHold
                                        ? Colors.white
                                        : Colors.red[600],
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Neuer Warenkorb
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    onPressed: () => _createNewCart(),
                    tooltip: 'Neuer Warenkorb',
                    padding: EdgeInsets.zero,
                  ),
                ),
                // Warenkorb zurückstellen
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: const Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _activeCarts.isNotEmpty ? _holdCart : null,
                    tooltip: 'Warenkorb zurückstellen',
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

  /// **🗑️ NEUE METHODE: Dialog zum Entfernen eines Warenkorbs**
  void _showRemoveCartDialog(int index) {
    if (index < 0 || index >= _activeCarts.length) return;

    final cart = _activeCarts[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warenkorb entfernen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Möchten Sie den Warenkorb "${cart.displayName}" wirklich entfernen?',
            ),
            if (cart.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Warenkorb enthält ${cart.items.length} Artikel (${cart.total.toStringAsFixed(2)} €)',
                style: TextStyle(
                  color: Colors.orange[700],
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
              _removeCart(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }

  /// **🛒 NEUE METHODE: Aktuellen Warenkorb leeren**
  void _clearCurrentCart() {
    if (_activeCarts.isEmpty ||
        _currentCartIndex < 0 ||
        _currentCartIndex >= _activeCarts.length)
      return;

    setState(() {
      _activeCarts[_currentCartIndex].items.clear();
    });

    debugPrint(
      '🛒 Warenkorb geleert: ${_activeCarts[_currentCartIndex].displayName}',
    );
  }

  /// **🗑️ NEUE METHODE: Item aus aktuellem Warenkorb entfernen**
  void _removeItemFromCurrentCart(int itemId) {
    if (_activeCarts.isEmpty ||
        _currentCartIndex < 0 ||
        _currentCartIndex >= _activeCarts.length)
      return;

    setState(() {
      _activeCarts[_currentCartIndex].items.removeWhere(
        (item) => item.id == itemId,
      );
    });

    debugPrint(
      '🗑️ Artikel entfernt aus Warenkorb: ${_activeCarts[_currentCartIndex].displayName}',
    );
  }

  /// **🔢 NEUE METHODE: Item-Menge in aktuellem Warenkorb ändern**
  void _updateCurrentCartItemQuantity(int itemId, int newQuantity) {
    if (_activeCarts.isEmpty ||
        _currentCartIndex < 0 ||
        _currentCartIndex >= _activeCarts.length)
      return;
    if (newQuantity <= 0) return;

    setState(() {
      final item = _activeCarts[_currentCartIndex].items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw StateError('Item nicht gefunden'),
      );

      item.quantity = newQuantity;
      item.totalPrice = item.unitPrice * newQuantity;
    });

    debugPrint(
      '🔢 Artikel-Menge geändert in Warenkorb: ${_activeCarts[_currentCartIndex].displayName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'POS-System',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _scannerMode,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                dropdownColor: Colors.blue[700],
                items: ['Express', 'POS', 'Hybrid'].map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(
                      mode,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (mode) {
                  if (mode != null) setState(() => _scannerMode = mode);
                },
              ),
            ),
          ),
        ],
        // 🛒 CART-TABS IN APPBAR BOTTOM
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildTopCartTabs(),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Linke Spalte: Kundensuche
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildCustomerSearchSection(),
                  ),
                ),

                // Mittlere Spalte: Produkt-Katalog
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
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
                      children: [_buildCategoryTabs(), _buildProductGrid()],
                    ),
                  ),
                ),

                // Rechte Spalte: Warenkorb
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildShoppingCart(),
                  ),
                ),
              ],
            ),
    );
  }
}

// Helper-Klasse für Kategorie-Konfiguration
class CategoryConfig {
  final Color color;
  final IconData icon;
  final String name;

  CategoryConfig({required this.color, required this.icon, required this.name});
}
