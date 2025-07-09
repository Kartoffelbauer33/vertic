import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import '../services/background_scanner_service.dart';
import '../services/device_id_service.dart';
import '../auth/permission_provider.dart';

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
  final FocusNode _searchFocusNode = FocusNode();

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

  // 🆕 BACKEND-INTEGRATION: Echte Kategorien und Produkte
  List<ProductCategory> _allCategories = [];
  List<Product> _allProducts = [];
  String? _selectedCategory; // Wird dynamisch gesetzt

  // 🛒 MULTI-CART-SYSTEM
  List<CartSession> _activeCarts = []; // Alle aktiven Warenkörbe
  int _currentCartIndex = 0; // Index des aktuell angezeigten Warenkorbs

  // 🎨 DYNAMISCHE ICON-MAPPING für Backend-Kategorien
  final Map<String, IconData> _iconMapping = {
    'category': Icons.category,
    'fastfood': Icons.fastfood,
    'local_drink': Icons.local_drink,
    'lunch_dining': Icons.lunch_dining,
    'sports': Icons.sports,
    'checkroom': Icons.checkroom,
    'build': Icons.build,
    'favorite': Icons.favorite,
    'shopping_bag': Icons.shopping_bag,
    'local_activity': Icons.local_activity,
    'card_membership': Icons.card_membership,
  };

  @override
  void initState() {
    super.initState();

    // 🎯 Focus-Listener für UI-Updates (grüne Icons etc.)
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {}); // UI-Update bei Fokus-Änderung
    });

    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualCodeController.dispose();
    _searchFocusNode.dispose();
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

      // 🎯 AUTO-FOKUS: Scanner-Input geht automatisch ins Suchfeld
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchFocusNode.canRequestFocus) {
          _searchFocusNode.requestFocus();
          debugPrint(
            '🎯 Auto-Fokus auf Suchfeld gesetzt für Scanner-Integration',
          );
        }
      });
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
      final activeSessions = await client.pos.restoreDeviceCartState(deviceId);
      debugPrint(
        '🔄 Backend-Antwort: ${activeSessions.length} Sessions gefunden',
      );

      if (activeSessions.isNotEmpty) {
        // Bestehende Warenkörbe wiederherstellen - aber nur mit Inhalt
        debugPrint(
          '🔄 ${activeSessions.length} bestehende Sessions gefunden für Gerät: $deviceId',
        );

        for (final posSession in activeSessions) {
          // Cart-Items für diese Session laden
          final cartItems = await client.pos.getCartItems(posSession.id!);

          // **🎯 NUR Sessions mit Artikeln oder Kunden wiederherstellen**
          final hasItems = cartItems.isNotEmpty;
          final hasCustomer = posSession.customerId != null;

          if (!hasItems && !hasCustomer) {
            debugPrint(
              '🗑️ Bereinige leere Session ${posSession.id} - keine Artikel und kein Kunde',
            );

            // **🧹 CLEANUP-FIX: Leere Sessions sofort löschen**
            try {
              await client.pos.clearCart(posSession.id!);
              debugPrint(
                '✅ Leere Session ${posSession.id} erfolgreich gelöscht',
              );
            } catch (e) {
              debugPrint(
                '⚠️ Fehler beim Löschen der leeren Session ${posSession.id}: $e',
              );
            }
            continue; // Leere Session überspringen
          }

          debugPrint(
            '✅ Stelle Session ${posSession.id} wieder her - ${cartItems.length} Artikel, Kunde: ${hasCustomer ? posSession.customerId : 'keiner'}',
          );

          final cartId = 'cart_${posSession.id}_restored';
          final newCart = CartSession(
            id: cartId,
            customer: posSession.customerId != null
                ? _findUserById(posSession.customerId)
                : null,
            posSession: posSession,
            items: cartItems,
            createdAt: posSession.createdAt,
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

          debugPrint('✅ ${_activeCarts.length} Warenkörbe wiederhergestellt');
          return;
        } else {
          debugPrint('ℹ️ Alle Sessions waren leer - erstelle neuen Warenkorb');
        }
      }

      // Keine bestehenden Warenkörbe - neuen erstellen
      debugPrint(
        '🆕 Keine bestehenden Sessions - erstelle neuen für Gerät: $deviceId',
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

  /// **✅ VALIDIERUNGSLOGIK: Prüft ob neuer Warenkorb erstellt werden darf**
  bool _canCreateNewCart() {
    // Kein aktiver Warenkorb vorhanden
    if (_activeCarts.isEmpty || _currentCartIndex < 0) return true;

    final currentCart = _activeCarts[_currentCartIndex];

    // Warenkorb ist leer
    if (_cartItems.isEmpty) return true;

    // Warenkorb hat Kunde zugeordnet (kann zurückgestellt werden)
    if (currentCart.customer != null) return true;

    // Warenkorb ist bezahlt (in dieser Implementation nicht implementiert, aber Platzhalter)
    // if (currentCart.isPaid) return true;

    return false;
  }

  /// **⚠️ VALIDIERUNGS-DIALOG: Warnt bei unbezahltem Warenkorb ohne Kunde**
  void _showCartValidationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              'Der aktuelle Warenkorb enthält ${_cartItems.length} unbezahlte Artikel im Wert von ${_calculateCartTotal().toStringAsFixed(2)}€.',
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
              // 🎯 FOCUS-FIX: Nach Dialog-Schließung Suchfeld fokussieren
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _searchFocusNode.canRequestFocus) {
                  _searchFocusNode.requestFocus();
                }
              });
            },
            child: const Text('Verstanden'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 🎯 FOCUS-FIX: Nach Dialog-Schließung Suchfeld fokussieren für Kundenzuordnung
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _searchFocusNode.canRequestFocus) {
                  _searchFocusNode.requestFocus();
                }
              });
            },
            child: const Text('Kunde zuordnen'),
          ),
        ],
      ),
    );
  }

  /// **🛒 KORRIGIERTE METHODE: Erstellt einen neuen Warenkorb mit gerätespezifischer Session**
  Future<void> _createNewCart({AppUser? customer}) async {
    // ✅ VALIDIERUNG: Prüfe ob neuer Warenkorb erstellt werden darf
    if (!_canCreateNewCart()) {
      _showCartValidationDialog();
      return;
    }

    try {
      // 🖥️ KRITISCH: Gerätespezifische Session erstellen mit deviceId
      final client = Provider.of<Client>(context, listen: false);
      final deviceId = await _getDeviceId();
      final session = await client.pos.createDeviceSession(
        deviceId,
        customer?.id,
      );

      debugPrint(
        '🖥️ Gerätespezifische Session erstellt: ${session.id} für Device: $deviceId',
      );

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

      // 🎯 WICHTIG: Artikel-Katalog für neuen Warenkorb aktualisieren
      await _loadAvailableItems();

      debugPrint(
        '🛒 Neuer gerätespezifischer Warenkorb erstellt: ${newCart.displayName}',
      );
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
        // 🎯 WICHTIG: Suchfeld zurücksetzen beim Warenkorb-Wechsel
        _searchText = '';
        _searchController.clear();
        _filteredUsers = _allUsers;
      });

      // 🎯 KRITISCH: Artikel-Katalog für aktuellen Kunden aktualisieren
      await _loadAvailableItems();

      debugPrint('🔄 Zu Warenkorb gewechselt: ${targetCart.displayName}');
    } catch (e) {
      debugPrint('❌ Fehler beim Wechseln des Warenkorbs: $e');
    }
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

        // 🖥️ KRITISCH: Gerätespezifische Session mit Kunde erstellen
        final deviceId = await _getDeviceId();
        final newSession = await client.pos.createDeviceSession(
          deviceId,
          newCustomer.id,
        );
        debugPrint(
          '🖥️ Gerätespezifische Session für Kundenwechsel erstellt: ${newSession.id}',
        );

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
          // 🎯 WICHTIG: Suchfeld zurücksetzen
          _searchText = '';
          _searchController.clear();
          _filteredUsers = _allUsers;
        });

        // 2. 🎯 KRITISCH: Artikel-Katalog aktualisieren (alle verfügbaren anzeigen)
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
  /// **🎯 VEREINFACHTE SCANNER-INTEGRATION: Auto-Fokus macht globale Listener überflüssig**
  void _handleSimplifiedSearchInput(String input) {
    final trimmedInput = input.trim();

    // ✅ EINFACHE SCANNER-ERKENNUNG: Scanner-Input ist meist länger und alphanumerisch
    if (_isLikelyScanner(trimmedInput)) {
      _processSimplifiedScannerInput(trimmedInput);
    } else {
      // Normale Kundensuche
      _performCustomerSearch(input);
    }
  }

  /// **🔍 VEREINFACHTE SCANNER-ERKENNUNG (ohne komplexe Pattern-Matching)**
  bool _isLikelyScanner(String input) {
    if (input.length < 3) return false;

    // Scanner-Input ist meist länger als normale Namen/Suchen
    if (input.length > 12) return true;

    // Scanner-Codes enthalten oft Sonderzeichen
    if (input.contains('-') ||
        input.contains('_') ||
        input.startsWith('{') ||
        input.startsWith('VT-') ||
        input.startsWith('FP-') ||
        input.startsWith('FR-')) {
      return true;
    }

    return false;
  }

  /// **📡 VEREINFACHTE SCANNER-VERARBEITUNG**
  void _processSimplifiedScannerInput(String scannerCode) {
    debugPrint('🎯 Scanner-Input erkannt (Auto-Fokus): $scannerCode');

    // Suchfeld leeren nach Scanner-Input
    _searchController.clear();
    setState(() => _searchText = '');

    // An Background Scanner Service weiterleiten
    final backgroundScanner = Provider.of<BackgroundScannerService>(
      context,
      listen: false,
    );
    backgroundScanner.manualScanInput(scannerCode);

    // Feedback anzeigen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white),
            SizedBox(width: 8),
            Text('Scanner-Code verarbeitet'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Fokus wieder auf Suchfeld für nächsten Scanner-Input
    Future.delayed(Duration(milliseconds: 500), () {
      _restoreScannerFocus();
    });
  }

  /// **🎯 HILFSMETHODE: Scanner-Fokus wiederherstellen**
  void _restoreScannerFocus() {
    if (mounted && _searchFocusNode.canRequestFocus) {
      _searchFocusNode.requestFocus();
      debugPrint('🎯 Scanner-Fokus wiederhergestellt');
    }
  }

  /// **📝 ALTE KOMPLEXE METHODE (kann entfernt werden)**
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

      // 🎯 1. TICKET-TYPES LADEN (bestehende Logik)
      final allTicketTypes = await client.ticketType.getAllTicketTypes();
      List<TicketType> filteredTickets;

      if (_selectedCustomer != null) {
        filteredTickets = await _getCustomerRelevantTickets(allTicketTypes);
        debugPrint(
          '🎯 Tickets für Kunde ${_selectedCustomer!.firstName} gefiltert: ${filteredTickets.length}/${allTicketTypes.length}',
        );
      } else {
        filteredTickets = allTicketTypes;
        debugPrint(
          '📋 Alle verfügbaren Tickets angezeigt: ${filteredTickets.length}',
        );
      }

      // 🆕 2. BACKEND-KATEGORIEN LADEN
      final categories = await client.productManagement.getProductCategories();
      final products = await client.productManagement.getProducts(
        onlyActive: true,
      );

      debugPrint('🏪 Backend-Daten geladen:');
      debugPrint('  • Kategorien: ${categories.length}');
      debugPrint('  • Produkte: ${products.length}');

      // 🆕 3. TICKET-KATEGORIEN erstellen (Tickets als spezielle Kategorien behandeln)
      final hallentickets = filteredTickets
          .where((ticket) => ticket.gymId != null)
          .toList();

      final verticUniversal = filteredTickets
          .where((ticket) => ticket.gymId == null && ticket.isVerticUniversal)
          .toList();

      // 🆕 4. ALLE DATEN KATEGORISIEREN
      final newCategorizedItems = <String, List<dynamic>>{};

      // Ticket-Kategorien (falls vorhanden)
      if (hallentickets.isNotEmpty) {
        newCategorizedItems['🎫 Hallentickets'] = hallentickets;
      }
      if (verticUniversal.isNotEmpty) {
        newCategorizedItems['🎟️ Vertic Universal'] = verticUniversal;
      }

      // Backend-Kategorien mit Produkten
      for (final category in categories) {
        final categoryProducts = products
            .where((product) => product.categoryId == category.id)
            .toList();

        if (categoryProducts.isNotEmpty || category.isActive) {
          // Icon-Emoji für bessere Darstellung
          final emoji = _getCategoryEmoji(category.iconName);
          final categoryName = '$emoji ${category.name}';
          newCategorizedItems[categoryName] = categoryProducts;
        }
      }

      // 🆕 5. ERSTE KATEGORIE AUTOMATISCH AUSWÄHLEN
      if (_selectedCategory == null && newCategorizedItems.isNotEmpty) {
        _selectedCategory = newCategorizedItems.keys.first;
        debugPrint('🎯 Auto-Select erste Kategorie: $_selectedCategory');
      }

      // 🆕 6. STATE AKTUALISIEREN
      setState(() {
        _allCategories = categories;
        _allProducts = products;
        _categorizedItems = newCategorizedItems;
      });

      debugPrint('🏪 Kategorisierung aktualisiert:');
      newCategorizedItems.forEach((categoryName, items) {
        debugPrint('  • $categoryName: ${items.length} Artikel');
      });
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Backend-Daten: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Artikel: $e')),
        );
      }
    }
  }

  /// **🎨 HILFSMETHODE: Emoji für Kategorie-Icons**
  String _getCategoryEmoji(String? iconName) {
    switch (iconName) {
      case 'fastfood':
        return '🍕';
      case 'local_drink':
        return '🥤';
      case 'lunch_dining':
        return '🥙';
      case 'sports':
        return '⚽';
      case 'checkroom':
        return '👕';
      case 'build':
        return '🔧';
      case 'favorite':
        return '⭐';
      case 'shopping_bag':
        return '🛍️';
      default:
        return '📦';
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

          // Suchfeld mit Auto-Fokus für Scanner-Integration
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText:
                  'Name, E-Mail, ID oder Telefon eingeben (Auto-Scanner bereit)...',
              prefixIcon: Icon(
                Icons.search,
                color: _searchFocusNode.hasFocus ? Colors.green : null,
              ),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performCustomerSearch('');
                        // Fokus wieder setzen nach Clear
                        _searchFocusNode.requestFocus();
                      },
                    )
                  : _searchFocusNode.hasFocus
                  ? Icon(Icons.qr_code_scanner, color: Colors.green)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _searchFocusNode.hasFocus ? Colors.green : Colors.grey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _handleSimplifiedSearchInput,
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

          // 🎯 Scanner-Status-Anzeige
          if (_searchFocusNode.hasFocus) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Scanner bereit',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
    return Consumer<PermissionProvider>(
      builder: (context, permissionProvider, _) {
        // Alle Kategorien sind immer sichtbar (Artikel-Verwaltung ist jetzt separater Tab)
        final visibleCategories = _categorizedItems.keys.toList();

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

              // Kategorie-Buttons mit RBAC-Filter
              SizedBox(
                height: 85, // Erhöht von 80 auf 85 für mehrzeilige Texte
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleCategories.length,
                  itemBuilder: (context, index) {
                    final category = visibleCategories[index];
                    final categoryData = _getCategoryDataByName(category);
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
                            width: 110, // Reduziert von 120 auf 110
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ), // Optimiert
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
                              mainAxisSize:
                                  MainAxisSize.min, // Wichtig für Overflow-Fix
                              children: [
                                Icon(
                                  config.icon,
                                  color: isSelected
                                      ? Colors.white
                                      : config.color,
                                  size: 24, // Reduziert von 28 auf 24
                                ),
                                const SizedBox(
                                  height: 3,
                                ), // Reduziert von 4 auf 3
                                Flexible(
                                  // Flexibler Text-Container
                                  child: Text(
                                    config.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10, // Reduziert von 12 auf 10
                                      height: 1.1, // Kompakter Line-Height
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2, // Max 2 Zeilen
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (itemCount > 0) ...[
                                  const SizedBox(height: 1), // Reduziert
                                  Text(
                                    '$itemCount',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : Colors.grey[500],
                                      fontSize: 9, // Reduziert von 10 auf 9
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
      },
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
            crossAxisCount: 4, // Erhöht von 3 auf 4 für kleinere Karten
            crossAxisSpacing: 8, // Reduziert von 12 auf 8
            mainAxisSpacing: 8, // Reduziert von 12 auf 8
            childAspectRatio:
                1.0, // Reduziert von 1.2 auf 1.0 für quadratische Form
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
          padding: const EdgeInsets.all(8), // Reduziert von 12 auf 8
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), // Reduziert von 12 auf 8
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
              Icon(
                config.icon,
                color: config.color,
                size: 24,
              ), // Reduziert von 32 auf 24
              const SizedBox(height: 4), // Reduziert von 8 auf 4
              Text(
                ticketType.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11, // Reduziert von 14 auf 11
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // Reduziert von 4 auf 2
              Text(
                '${ticketType.defaultPrice.toStringAsFixed(2)} €',
                style: TextStyle(
                  color: config.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13, // Reduziert von 16 auf 13
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
          padding: const EdgeInsets.all(8), // Reduziert von 12 auf 8
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), // Reduziert von 12 auf 8
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
              Icon(
                config.icon,
                color: config.color,
                size: 24,
              ), // Reduziert von 32 auf 24
              const SizedBox(height: 4), // Reduziert von 8 auf 4
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11, // Reduziert von 14 auf 11
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // Reduziert von 4 auf 2
              Text(
                '${product.price.toStringAsFixed(2)} €',
                style: TextStyle(
                  color: config.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13, // Reduziert von 16 auf 13
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

  /// **🎨 VERBESSERTE METHODE: Multi-Cart-Tabs mit besserer Sichtbarkeit**
  Widget _buildTopCartTabs() {
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                                : Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isActive
                                  ? Colors.blue[300]!
                                  : isOnHold
                                  ? Colors.amber[700]!
                                  : Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
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
                              if (_activeCarts.length > 1) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _showRemoveCartDialog(index),
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
                    onPressed: () => _createNewCart(),
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

  /// **🗑️ VERBESSERTE METHODE: Intelligente Warenkorb-Entfernung**
  void _showRemoveCartDialog(int index) {
    if (index < 0 || index >= _activeCarts.length) return;

    final cart = _activeCarts[index];

    // 🧹 INTELLIGENTE LOGIK: Leere Warenkörbe ohne Bestätigung entfernen
    final hasItems = cart.items.isNotEmpty;
    final hasCustomer = cart.customer != null;

    // Wenn Warenkorb leer und kein Kunde zugeordnet → direkt entfernen
    if (!hasItems && !hasCustomer) {
      debugPrint(
        '🧹 Leerer Warenkorb wird direkt entfernt: ${cart.displayName}',
      );
      _removeCart(index);
      return;
    }

    // Andernfalls: Bestätigung anfordern bei Inhalt oder Kundenzuordnung
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

  // ==================== ARTIKEL-MANAGEMENT ====================

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
        // ❌ Express/POS/Hybrid Einstellung entfernt - gehört in Admin-Einstellungen
        // 🛒 CART-TABS IN APPBAR BOTTOM
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildTopCartTabs(),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              // 🎯 QUICK-FOCUS: Tippen ins Leere setzt Fokus zurück auf Suchfeld
              onTap: () {
                if (!_searchFocusNode.hasFocus &&
                    _searchFocusNode.canRequestFocus) {
                  _searchFocusNode.requestFocus();
                  debugPrint('🎯 Quick-Focus: Suchfeld wieder fokussiert');
                }
              },
              child: Row(
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

/// **🆕 ARTIKEL-HINZUFÜGEN DIALOG**
class AddProductDialog extends StatefulWidget {
  final Function(Product) onProductCreated;

  const AddProductDialog({super.key, required this.onProductCreated});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  Map<String, dynamic>? _scannedData;
  BackgroundScannerService? _scannerService;

  // **🎯 SCANNER-STATE-TRACKING für Consumer**
  String? _lastProcessedScanCode;
  DateTime? _lastProcessedScanTime;

  // **🏷️ Kategorie-Verwaltung**
  List<ProductCategory> _availableCategories = [];
  ProductCategory? _selectedCategory;

  // **🏛️ DACH-Compliance: Steuerklassen-Verwaltung**
  List<TaxClass> _availableTaxClasses = [];
  TaxClass? _selectedTaxClass;
  bool _isTaxClassesLoading = true;
  Country? _facilityCountry; // Land der aktuellen Facility

  @override
  void initState() {
    super.initState();

    // **🎯 Scanner-Service für Dialog-Mode registrieren**
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scannerService = Provider.of<BackgroundScannerService>(
        context,
        listen: false,
      );

      _scannerService!.activateDialogMode();
      debugPrint('🎯 AddProductDialog: Scanner-Listener registriert');

      // **🏷️ Kategorien laden**
      _loadProductCategories();

      // **🏛️ Facility-Land ermitteln und Steuerklassen laden**
      _loadFacilityCountryAndTaxClasses();
    });
  }

  @override
  void dispose() {
    // **🔴 Scanner-Listener wieder abmelden**
    if (_scannerService != null) {
      _scannerService!.deactivateDialogMode();
      debugPrint('🔴 AddProductDialog: Scanner-Listener abgemeldet');
    }

    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // **🎯 SCANNER-CALLBACK ENTFERNT - Consumer-Pattern verwendet**

  /// **🏷️ Produktkategorien laden**
  Future<void> _loadProductCategories() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final categories = await client.productManagement.getProductCategories();

      if (mounted) {
        setState(() {
          _availableCategories = categories;
          _isCategoriesLoading = false;

          // Standard-Kategorie "Produkte" vorauswählen falls vorhanden
          if (categories.isNotEmpty) {
            _selectedCategory = categories.firstWhere(
              (cat) => cat.name.toLowerCase() == 'produkte',
              orElse: () => categories.first,
            );
          }
        });
        debugPrint(
          '🏷️ ${categories.length} Kategorien geladen, Standard: ${_selectedCategory?.name}',
        );
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Kategorien: $e');
      if (mounted) {
        setState(() {
          _isCategoriesLoading = false;
        });
      }
    }
  }

  /// **🏛️ Facility-Land ermitteln und Steuerklassen laden**
  Future<void> _loadFacilityCountryAndTaxClasses() async {
    try {
      final client = Provider.of<Client>(context, listen: false);

      // ✅ SESSION-BASIERTE FACILITY-ERMITTLUNG
      final currentFacility = await client.facility.getCurrentFacility();

      if (currentFacility != null) {
        if (currentFacility.countryId != null) {
          // Alle Länder laden und das Facility-Land finden
          final countries = await client.taxManagement.getAllCountries();
          final country = countries.firstWhere(
            (c) => c.id == currentFacility.countryId,
            orElse: () =>
                countries.first, // Falls nicht gefunden, nehme das erste Land
          );

          if (mounted) {
            setState(() {
              _facilityCountry = country;
            });

            // Steuerklassen für das Facility-Land laden
            await _loadTaxClassesForFacilityCountry(country.id!);

            debugPrint('🏛️ Facility-Land erkannt: ${country.displayName}');
          }
        } else {
          // Facility hat noch kein Land zugeordnet
          debugPrint(
            '⚠️ Facility hat noch kein Land zugeordnet - verwende Deutschland als Standard',
          );
          await _loadDefaultGermanyTaxClasses();
        }
      } else {
        debugPrint(
          '⚠️ Keine Facilities gefunden - verwende Deutschland als Standard',
        );
        await _loadDefaultGermanyTaxClasses();
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Laden des Facility-Landes: $e');
      // Fallback auf Deutschland
      await _loadDefaultGermanyTaxClasses();
    }
  }

  /// **🇩🇪 Standard Deutschland-Steuerklassen laden (Fallback)**
  Future<void> _loadDefaultGermanyTaxClasses() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final countries = await client.taxManagement.getAllCountries();

      if (countries.isNotEmpty) {
        final germany = countries.firstWhere(
          (country) => country.code == 'DE',
          orElse: () => countries.first,
        );

        if (mounted) {
          setState(() {
            _facilityCountry = germany;
          });

          await _loadTaxClassesForFacilityCountry(germany.id!);
          debugPrint('🇩🇪 Deutschland als Standard-Land geladen');
        }
      } else {
        debugPrint('⚠️ Keine Länder in der Datenbank gefunden');
        if (mounted) {
          setState(() {
            _isTaxClassesLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Standard-Steuerklassen: $e');
      if (mounted) {
        setState(() {
          _isTaxClassesLoading = false;
        });
      }
    }
  }

  /// **🏛️ Steuerklassen für Facility-Land laden**
  Future<void> _loadTaxClassesForFacilityCountry(int countryId) async {
    try {
      setState(() => _isTaxClassesLoading = true);

      final client = Provider.of<Client>(context, listen: false);
      final taxClasses = await client.taxManagement.getTaxClassesForCountry(
        countryId,
      );

      if (mounted) {
        setState(() {
          _availableTaxClasses = taxClasses;
          _isTaxClassesLoading = false;

          // Standard-Steuerklasse auswählen
          if (taxClasses.isNotEmpty) {
            _selectedTaxClass = taxClasses.firstWhere(
              (taxClass) => taxClass.isDefault,
              orElse: () => taxClasses.first,
            );
          }
        });

        debugPrint(
          '🏛️ ${taxClasses.length} Steuerklassen für ${_facilityCountry?.displayName} geladen',
        );
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Steuerklassen: $e');
      if (mounted) {
        setState(() {
          _isTaxClassesLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BackgroundScannerService>(
      builder: (context, scanner, child) {
        // **🎯 Scanner-State-Änderungen verarbeiten (OHNE setState)**
        if (scanner.dialogScannedCode != null &&
            scanner.dialogScanTime != null &&
            (scanner.dialogScannedCode != _lastProcessedScanCode ||
                scanner.dialogScanTime != _lastProcessedScanTime)) {
          // State-Tracking ohne setState
          _lastProcessedScanCode = scanner.dialogScannedCode;
          _lastProcessedScanTime = scanner.dialogScanTime;

          // Textfeld direkt updaten (ohne setState)
          _barcodeController.text = scanner.dialogScannedCode!;

          // Async-Operationen sicher ausführen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scanBarcode(scanner.dialogScannedCode!);
          });
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.add_shopping_cart,
                      color: Colors.indigo,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Neuen Artikel hinzufügen',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Barcode-Eingabe mit Scanner-Button
                Text(
                  'Barcode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          hintText: 'Barcode eingeben oder scannen',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        onChanged: (value) {
                          if (value.length >= 8) {
                            _scanBarcode(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _startHardwareScanning,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scannen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                // Gescannte Produktinformationen anzeigen
                if (_scannedData != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✅ Produktdaten gefunden',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_scannedData!['openFoodFactsData'] != null)
                          Text(
                            '📦 ${_scannedData!['openFoodFactsData']['name']}',
                          ),
                        if (_scannedData!['product'] != null)
                          Text('📦 ${_scannedData!['product'].name}'),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Produktinformationen
                Text(
                  'Produktinformationen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Produktname *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Preis (€) *',
                    hintText: 'z.B. 1,50 oder 1.50',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.euro),
                    helperText:
                        'Komma oder Punkt als Dezimaltrennzeichen möglich',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),

                // **🏷️ Kategorie-Auswahl**
                _isCategoriesLoading
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Kategorien werden geladen...'),
                        ],
                      )
                    : DropdownButtonFormField<ProductCategory>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategorie *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                          helperText: 'Wählen Sie eine Produktkategorie',
                        ),
                        items: _availableCategories.map((category) {
                          return DropdownMenuItem<ProductCategory>(
                            value: category,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        category.colorHex.replaceFirst(
                                          '#',
                                          '0xFF',
                                        ),
                                      ),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (category) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Bitte wählen Sie eine Kategorie';
                          }
                          return null;
                        },
                      ),

                const SizedBox(height: 16),

                // **🏛️ DACH-Compliance: Land-Auswahl**
                Text(
                  'Steuerliche Zuordnung',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // **🏛️ Facility-Land-Anzeige**
                if (_facilityCountry != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Standort-Land: ${_facilityCountry!.displayName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Text(
                                'Steuersystem: ${_facilityCountry!.taxSystemType.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (_facilityCountry!.requiresTSE)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'TSE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[800],
                                  ),
                                ),
                              ),
                            if (_facilityCountry!.requiresRKSV) ...[
                              if (_facilityCountry!.requiresTSE)
                                const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'RKSV',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                _availableTaxClasses.isEmpty
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Steuerklassen werden geladen...'),
                        ],
                      )
                    : DropdownButtonFormField<TaxClass>(
                        value: _selectedTaxClass,
                        decoration: const InputDecoration(
                          labelText: 'Steuerklasse *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt_long),
                          helperText: 'Steuersatz und Compliance-Einstellungen',
                        ),
                        items: _availableTaxClasses.map((taxClass) {
                          return DropdownMenuItem<TaxClass>(
                            value: taxClass,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        taxClass.colorHex.replaceFirst(
                                          '#',
                                          '0xFF',
                                        ),
                                      ),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${taxClass.name} (${taxClass.taxRate.toStringAsFixed(1)}%)',
                                  ),
                                ),
                                if (taxClass.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Standard',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (taxClass) {
                          setState(() {
                            _selectedTaxClass = taxClass;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Bitte wählen Sie eine Steuerklasse';
                          }
                          return null;
                        },
                      ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Abbrechen'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Artikel erstellen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// **🔍 Hardware-Scanner aktivieren**
  void _startHardwareScanning() {
    if (_scannerService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Scanner-Service nicht verfügbar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_scannerService!.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Hardware-Scanner nicht verbunden'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _scannerService!.isDialogMode
              ? '✅ Scanner bereit - Barcode scannen...'
              : '📡 Scanner aktiviert - Barcode scannen...',
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// **🔍 Barcode scannen und Produktdaten abrufen**
  Future<void> _scanBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return;

    // **🔧 FLUTTER-KONFORM: setState mit addPostFrameCallback umhüllen**
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoading = true);
    });

    try {
      final client = Provider.of<Client>(context, listen: false);
      final scanResult = await client.productManagement.scanBarcode(barcode);

      if (scanResult.found) {
        // **🔧 FLUTTER-KONFORM: setState sicher ausführen**
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _scannedData = {
                'found': true,
                'source': scanResult.source,
                'openFoodFactsData': scanResult.openFoodFactsName != null
                    ? {
                        'name': scanResult.openFoodFactsName,
                        'description': scanResult.openFoodFactsDescription,
                      }
                    : null,
                'product': scanResult.productId != null
                    ? {
                        'name': scanResult.productName,
                        'price': scanResult.productPrice,
                      }
                    : null,
              };

              // Automatisch Felder ausfüllen
              if (scanResult.openFoodFactsName != null) {
                _nameController.text = scanResult.openFoodFactsName ?? '';
              } else if (scanResult.productName != null) {
                _nameController.text = scanResult.productName!;
                _priceController.text =
                    scanResult.productPrice?.toString() ?? '';
              }
            });
          }
        });
      } else {
        // **🔧 FLUTTER-KONFORM: setState sicher ausführen**
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _scannedData = null);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                scanResult.message ??
                    'ℹ️ Produkt nicht gefunden - kann manuell erstellt werden',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Scanner-Fehler: $e')));
      }
    } finally {
      // **🔧 FLUTTER-KONFORM: setState sicher ausführen**
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  /// **🔧 Hilfsfunktion: Deutsche Dezimaltrennzeichen unterstützen**
  double? _parseGermanPrice(String priceText) {
    if (priceText.trim().isEmpty) return null;

    // Normalisiere deutsches Komma zu englischem Punkt
    final normalizedPrice = priceText.trim().replaceAll(',', '.');

    try {
      final price = double.parse(normalizedPrice);
      return price > 0 ? price : null;
    } catch (e) {
      return null;
    }
  }

  /// **✅ Neues Produkt erstellen**
  Future<void> _createProduct() async {
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _selectedCategory == null ||
        _selectedTaxClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Name, Preis, Kategorie, Land und Steuerklasse sind erforderlich',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = Provider.of<Client>(context, listen: false);

      final price = _parseGermanPrice(_priceController.text);
      if (price == null) {
        throw Exception(
          'Ungültiger Preis - verwenden Sie Format: 1,50 oder 1.50',
        );
      }

      final newProduct = await client.productManagement.createProduct(
        _nameController.text.trim(),
        price,
        barcode: _barcodeController.text.trim().isNotEmpty
            ? _barcodeController.text.trim()
            : null,
        description: _scannedData?['openFoodFactsData']?['description'],
        categoryId: _selectedCategory!.id,
        isFoodItem: _scannedData?['openFoodFactsData'] != null,
        // 🏛️ DACH-Compliance Parameter
        taxClassId: _selectedTaxClass!.id,
        defaultCountryId: _facilityCountry!.id,
        requiresTSESignature: _selectedTaxClass!.requiresTSESignature,
        requiresAgeVerification:
            false, // TODO: UI für Altersverifikation hinzufügen
        isSubjectToSpecialTax: false, // TODO: UI für Sondersteuern hinzufügen
      );

      widget.onProductCreated(newProduct);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Fehler beim Erstellen: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
