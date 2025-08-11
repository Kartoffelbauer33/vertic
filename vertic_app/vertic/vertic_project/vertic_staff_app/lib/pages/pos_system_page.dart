import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_server_client/test_server_client.dart';
import '../services/background_scanner_service.dart';
import '../services/device_id_service.dart';
import '../auth/permission_provider.dart';

import '../widgets/pos/pos_cart_widget.dart';
import '../widgets/pos/pos_multi_cart_tabs_widget.dart';
import '../widgets/pos/pos_category_navigation_widget.dart';
import '../widgets/pos/pos_product_grid_widget.dart';
import '../widgets/pos/pos_live_filter_results_widget.dart';
import '../widgets/pos/pos_product_card_widget.dart';
import '../widgets/pos/pos_ticket_card_widget.dart';
import '../widgets/pos/pos_session_stats_dialog_widget.dart';
import '../widgets/pos/pos_remove_cart_dialog_widget.dart';
import '../widgets/pos/pos_device_info_dialog_widget.dart';
import '../widgets/pos/pos_cart_validation_dialog_widget.dart';
import '../widgets/pos/pos_customer_info_display_widget.dart';

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
  final TextEditingController _manualCodeController = TextEditingController();

  // State Management - Kundensuche vereinfacht
  AppUser? _selectedCustomer;

  // 🗑️ DEPRECATED: Nur noch für Kompatibilität - neue Suche verwendet CustomerSearchSection
  List<AppUser> _allUsers = [];
  List<AppUser> _filteredUsers = [];
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<PosCartItem> _cartItems = [];
  bool _isLoading = false;
  String _scannerMode = 'POS'; // Express, POS, Hybrid
  Map<String, List<dynamic>> _categorizedItems = {};
  PosSession? _currentSession;

  // 🆕 BACKEND-INTEGRATION: Echte Kategorien und Produkte
  List<ProductCategory> _allCategories = [];
  List<Product> _allProducts = [];
  String? _selectedCategory; // Wird dynamisch gesetzt

  // 🆕 HIERARCHISCHE NAVIGATION
  List<String> _categoryBreadcrumb = []; // Navigation-Pfad
  Map<String, Map<String, dynamic>> _categoryHierarchy = {}; // Hierarchie-Daten
  String? _currentTopLevelCategory; // Aktuelle Überkategorie
  bool _showingSubCategories = false; // Zeigt Sub-Kategorien an

  // 🛒 MULTI-CART-SYSTEM
  List<CartSession> _activeCarts = []; // Alle aktiven Warenkörbe
  int _currentCartIndex = 0; // Index des aktuell angezeigten Warenkorbs

  // 🔍 LIVE-FILTER STATE
  String _liveSearchQuery = '';
  Timer? _searchDebounceTimer;
  List<Product> _filteredProducts = [];
  List<ProductCategory> _filteredCategories = [];
  Map<String, int> _categoryArticleCounts = {};
  bool _isLiveSearchActive = false;

  // 🛡️ RACE CONDITION PROTECTION
  int _lastCartSwitchId = 0; // Eindeutige ID für jeden Warenkorb-Wechsel
  final Map<int, bool> _activeSyncOperations = {}; // Tracking aktiver Sync-Operationen

  // 🎯 FILTER-OPTIONEN
  Set<String> _activeFilters = {};
  String _sortOption = 'relevance'; // relevance, alphabetical, price_asc, price_desc
  bool _showOnlyTickets = false;
  bool _showOnlyProducts = false;

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

    // 🔧 **FLUTTER-FIX: FocusNode-Listener entfernt**
    // Der direkte setState() im Focus-Listener verursachte endlose Build-Zyklen
    // Alternative: Focus-State wird über hasFocus-Property abgefragt (ohne setState)
    // _searchFocusNode.addListener(() {
    //   if (mounted) setState(() {}); // ❌ PROBLEMATISCH - Endlose Build-Zyklen
    // });

    _initializeData();

    // 🔄 EVENT-BASED REFRESH: Registriere für Artikel-Änderungen
    _registerForProductUpdates();
  }

  /// **🔄 INTELLIGENTES EVENT-SYSTEM: Reagiert auf Artikel-Änderungen**
  void _registerForProductUpdates() {
    // Registriere beim globalen Event-System
    ProductCatalogEvents().addListener(() {
      if (mounted) {
        refreshProductCatalog();
      }
    });
    debugPrint('📡 POS-System: Registriert für automatische Artikel-Updates');
  }

  /// **🔄 ÖFFENTLICHE METHODE: Refresh von anderen Seiten auslösen**
  static void triggerRefresh() {
    debugPrint('🔄 Event-Trigger: Artikel-Katalog wird aktualisiert...');
    // Trigger über das Event-System
    ProductCatalogEvents().notifyProductChanged();
  }

  /// **🔄 NEUE METHODE: Manueller Refresh bei Änderungen**
  Future<void> refreshProductCatalog() async {
    debugPrint('🔄 Artikel-Katalog: Refresh nach Änderung gestartet');
    try {
      await _loadAvailableItems();
      if (mounted) {
        setState(() {});
        debugPrint('✅ Artikel-Katalog erfolgreich aktualisiert');
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Artikel-Refresh: $e');
    }
  }

  @override
  void dispose() {
    // 🧹 **CLEANUP: Leere Warenkörbe beim App-Close löschen**
    _cleanupEmptyCartsOnClose();

    // 🔄 Event-Listener entfernen
    ProductCatalogEvents().removeListener(() {
      if (mounted) {
        refreshProductCatalog();
      }
    });

    // 🔍 Live-Filter Cleanup
    _searchDebounceTimer?.cancel();

    // 🛡️ RACE CONDITION CLEANUP: Alle aktiven Sync-Operationen abbrechen
    _activeSyncOperations.clear();
    debugPrint('🧹 Alle Sync-Operationen beim Widget-Dispose abgebrochen');

    _manualCodeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// **🧹 NEUE METHODE: Backend-Bereinigung beim App-Close**
  ///
  /// **FUNKTIONALITÄT:**
  /// - Ruft Backend-Bereinigung für alle leeren Sessions auf
  /// - Ordnungsgemäße Aufräumarbeiten beim App-Schließen
  /// - Verwendet die neue onAppClosing Backend-Methode
  void _cleanupEmptyCartsOnClose() {
    try {
      debugPrint('🧹 Aggressive Backend-Bereinigung beim App-Close...');

      // Backend-Bereinigung im Hintergrund ausführen
      (() async {
        try {
          final client = Provider.of<Client>(context, listen: false);

          // ✅ NEUE BUSINESS-LOGIC: Intelligente Bereinigung mit Statistiken
          final stats = await client.pos.cleanupSessionsWithBusinessLogic();
          debugPrint('✅ Backend-Bereinigung abgeschlossen: $stats');
        } catch (e) {
          debugPrint('⚠️ Fehler bei Backend-Bereinigung: $e');
          // Nicht kritisch für App-Close
        }
      })();
    } catch (e) {
      debugPrint('⚠️ Fehler beim App-Close Cleanup: $e');
      // Nicht kritisch - App kann trotzdem beendet werden
    }
  }

  // ==================== INITIALIZATION ====================

  // ==================== INITIALIZATION ====================

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_loadAllCustomers(), _loadAvailableItems()]);

      // 🧹 WICHTIG: Bei App-Neustart alle Sessions zurücksetzen
      await _cleanupOrphanedSessions();

      // 🛒 MULTI-CART: Ersten Warenkorb erstellen oder bestehenden laden
      await _initializeCartFromExistingSession();

      // 🎯 AUTO-FOKUS: Handled by CustomerSearchSection Widget
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Initialisieren: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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

      // ✅ KORREKTE IMPLEMENTIERUNG: Nur die richtige Methode verwenden
      final activeSessions = await client.pos.initializeAppStart(deviceId);
      debugPrint(
        '🔄 Backend-Antwort (bereits bereinigt): ${activeSessions.length} Sessions gefunden',
      );

      if (activeSessions.isNotEmpty) {
        // ✅ Sessions sind bereits bereinigt - alle haben Inhalt oder Kunden
        debugPrint(
          '🔄 ${activeSessions.length} bereinigte Sessions gefunden für Gerät: $deviceId',
        );

        for (final posSession in activeSessions) {
          // Cart-Items für diese Session laden
          final cartItems = await client.pos.getCartItems(posSession.id!);

          debugPrint(
            '✅ Stelle Session ${posSession.id} wieder her - ${cartItems.length} Artikel, Kunde: ${posSession.customerId != null ? posSession.customerId : 'keiner'}',
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

  /// **🔍 DEBUG: Geräte-Informationen anzeigen - Verwendet eigenständiges Widget**
  Future<void> _showDeviceInfo() async {
    await PosDeviceInfoDialogWidget.show(context);
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

  /// **🔍 KUNDENDATEN FÜR SESSION-WIEDERHERSTELLUNG**
  /// Notwendig für _findUserById() bei Session-Wiederherstellung
  Future<void> _loadAllCustomers() async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final users = await client.user.getAllUsers(limit: 1000, offset: 0);
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
      });
      debugPrint(
        '✅ ${users.length} Kunden für Session-Wiederherstellung geladen',
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Kunden: $e');
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
      // 🖥️ KRITISCH: Gerätespezifische Session verwenden
      final deviceId = await _getDeviceId();
      final session = await client.pos.createDeviceSession(
        deviceId,
        _selectedCustomer?.id,
      );
      setState(() => _currentSession = session);
      debugPrint('🖥️ Gerätespezifische Session erstellt: ${session.id}');
    } catch (e) {
      debugPrint('❌ Fehler beim Erstellen der Session: $e');
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

  /// **⚠️ VALIDIERUNGS-DIALOG: Warnt bei unbezahltem Warenkorb ohne Kunde - Verwendet eigenständiges Widget**
  void _showCartValidationDialog() {
    PosCartValidationDialogWidget.show(
      context: context,
      cartItems: _cartItems,
      cartTotal: _calculateCartTotal(),
      onCustomerAssignRequested: () {
        // 🎯 FOCUS-FIX: Auto-focus wird vom CustomerSearchSection Widget gehandhabt
      },
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

      // 🛡️ RACE CONDITION PROTECTION: Switch-ID für neuen Warenkorb generieren
      final switchId = ++_lastCartSwitchId;
      _activeSyncOperations.clear();
      _activeSyncOperations[switchId] = true;

      // 🚀 PERFORMANCE: Sofortiger UI-Update
      setState(() {
        _activeCarts.add(newCart);
        _currentCartIndex = _activeCarts.length - 1;
        _selectedCustomer = customer;
        _currentSession = session;
        _cartItems = [];
      });

      // ✅ Sofortiges visuelles Feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.add_shopping_cart, color: Colors.white),
                const SizedBox(width: 8),
                Text('Neuer Warenkorb erstellt: ${newCart.displayName}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // 🚀 PERFORMANCE: Artikel-Katalog im Hintergrund laden
      _loadAvailableItems().catchError((e) {
        debugPrint('⚠️ Hintergrund-Laden der Artikel fehlgeschlagen: $e');
      });

      debugPrint('🚀 Schnelle Warenkorb-Erstellung: ${newCart.displayName}');
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

  /// **🛡️ RACE CONDITION-GESCHÜTZT: Warenkorb-Wechsel mit Async-Guards**
  Future<void> _switchToCart(int index) async {
    if (index < 0 || index >= _activeCarts.length) return;
    if (index == _currentCartIndex) return; // Bereits aktiver Cart

    final targetCart = _activeCarts[index];
    
    // 🛡️ RACE CONDITION PROTECTION: Eindeutige Switch-ID generieren
    final switchId = ++_lastCartSwitchId;
    
    // 🛡️ Alle vorherigen Sync-Operationen als veraltet markieren
    _activeSyncOperations.clear();
    _activeSyncOperations[switchId] = true;

    // 🚀 PERFORMANCE: Sofortiger UI-Update ohne Backend-Call
    setState(() {
      _currentCartIndex = index;
      _selectedCustomer = targetCart.customer;
      _currentSession = targetCart.posSession;
      // Verwende gecachte Items aus dem CartSession-Objekt
      _cartItems = targetCart.items;
      // 🎯 Suchfeld zurücksetzen
      _searchText = '';
      _searchController.clear();
      _filteredUsers = _allUsers;
    });

    // 🚀 PERFORMANCE: Backend-Sync asynchron im Hintergrund mit Race Protection
    _syncCartInBackgroundSafe(targetCart, switchId);

    debugPrint('🛡️ Race-geschützter Warenkorb-Wechsel: ${targetCart.displayName} (ID: $switchId)');
  }

  /// **🛡️ RACE CONDITION-GESCHÜTZT: Hintergrund-Sync mit Async-Guards**
  Future<void> _syncCartInBackgroundSafe(CartSession targetCart, int switchId) async {
    try {
      // 🛡️ RACE PROTECTION: Prüfe ob diese Sync-Operation noch relevant ist
      if (!_activeSyncOperations.containsKey(switchId)) {
        debugPrint('🛡️ Sync-Operation $switchId wurde abgebrochen (neuer Warenkorb-Wechsel)');
        return;
      }

      final client = Provider.of<Client>(context, listen: false);
      final freshItems = await client.pos.getCartItems(targetCart.posSession!.id!);
      
      // 🛡️ DOUBLE-CHECK: Prüfe erneut ob diese Sync-Operation noch relevant ist
      if (!_activeSyncOperations.containsKey(switchId)) {
        debugPrint('🛡️ Sync-Operation $switchId wurde während Backend-Call abgebrochen');
        return;
      }

      // 🛡️ TRIPLE-CHECK: Prüfe ob der Warenkorb noch der aktuelle ist
      if (_currentCartIndex >= _activeCarts.length || 
          _activeCarts[_currentCartIndex].id != targetCart.id) {
        debugPrint('🛡️ Warenkorb $switchId ist nicht mehr aktiv, Sync übersprungen');
        return;
      }
      
      // Nur UI updaten wenn sich Daten geändert haben
      if (!_areCartItemsEqual(_cartItems, freshItems)) {
        setState(() {
          _cartItems = freshItems;
          // Update auch im CartSession-Cache
          final updatedCart = targetCart.copyWith(items: freshItems);
          _activeCarts[_currentCartIndex] = updatedCart;
        });
        debugPrint('🛡️ Cart-Daten sicher synchronisiert (ID: $switchId)');
      }
      
      // 🧹 Cleanup: Sync-Operation als abgeschlossen markieren
      _activeSyncOperations.remove(switchId);
      
    } catch (e) {
      debugPrint('⚠️ Hintergrund-Sync Fehler für ID $switchId (nicht kritisch): $e');
      // 🧹 Cleanup auch bei Fehlern
      _activeSyncOperations.remove(switchId);
    }
  }

  /// **🔍 HILFSMETHODE: Vergleicht Cart-Items auf Änderungen**
  bool _areCartItemsEqual(List<PosCartItem> items1, List<PosCartItem> items2) {
    if (items1.length != items2.length) return false;
    
    for (int i = 0; i < items1.length; i++) {
      final item1 = items1[i];
      final item2 = items2[i];
      if (item1.id != item2.id || 
          item1.quantity != item2.quantity || 
          item1.unitPrice != item2.unitPrice) {
        return false;
      }
    }
    return true;
  }





/// **🚀 PERFORMANCE-OPTIMIERT: Schnelle Warenkorb-Entfernung mit optimistischem UI**
Future<void> _removeCart(int index) async {
  if (index < 0 || index >= _activeCarts.length) return;

  final cartToRemove = _activeCarts[index];
  final cartBackup = List<CartSession>.from(_activeCarts); // Backup für Rollback
  final currentIndexBackup = _currentCartIndex;
  final sessionBackup = _currentSession;
  final customerBackup = _selectedCustomer;
  final itemsBackup = List<PosCartItem>.from(_cartItems);

  // 🛡️ RACE CONDITION PROTECTION: Switch-ID für Warenkorb-Entfernung generieren
  final switchId = ++_lastCartSwitchId;
  _activeSyncOperations.clear();
  _activeSyncOperations[switchId] = true;

  // 🚀 PERFORMANCE: Sofortiger optimistischer UI-Update
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
    } else if (index <= _currentCartIndex && _currentCartIndex > 0) {
      _currentCartIndex--; // Index nach links verschieben
    }

    // Zu neuem aktuellem Warenkorb wechseln (falls vorhanden)
    if (_activeCarts.isNotEmpty && _currentCartIndex < _activeCarts.length) {
      final newCurrentCart = _activeCarts[_currentCartIndex];
      _selectedCustomer = newCurrentCart.customer;
      _currentSession = newCurrentCart.posSession;
      _cartItems = newCurrentCart.items;
    }
  });

  // ✅ Sofortiges visuelles Feedback
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white),
            const SizedBox(width: 8),
            Text('Warenkorb entfernt: ${cartToRemove.displayName}'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🚀 PERFORMANCE: Backend-Sync und Fallback-Handling im Hintergrund
  _syncRemoveCartInBackground(
    cartToRemove, 
    cartBackup, 
    currentIndexBackup, 
    sessionBackup, 
    customerBackup, 
    itemsBackup
  );

  debugPrint('🚀 Schnelle Warenkorb-Entfernung: ${cartToRemove.displayName}');
}

/// **🔄 HINTERGRUND-SYNC: Warenkorb-Entfernung ohne UI-Blockierung**
Future<void> _syncRemoveCartInBackground(
  CartSession cartToRemove,
  List<CartSession> cartBackup,
  int currentIndexBackup,
  PosSession? sessionBackup,
  AppUser? customerBackup,
  List<PosCartItem> itemsBackup,
) async {
  try {
    final client = Provider.of<Client>(context, listen: false);
    
    // ✅ BACKEND-SESSION WIRKLICH LÖSCHEN (nicht nur leeren!)
    if (cartToRemove.posSession != null) {
      final deleted = await client.pos.deleteCart(
        cartToRemove.posSession!.id!,
      );
      if (deleted) {
        debugPrint(
          '🔄 Session ${cartToRemove.posSession!.id} erfolgreich im Backend gelöscht',
        );
      } else {
        debugPrint(
          '⚠️ Session ${cartToRemove.posSession!.id} konnte nicht gelöscht werden (bezahlt?)',
        );
        // Fallback: Session leeren
        await client.pos.clearCart(cartToRemove.posSession!.id!);
      }
    }

    // Falls kein Warenkorb mehr vorhanden, neuen erstellen
    if (_activeCarts.isEmpty) {
      await _createNewCart();
    }

    debugPrint('🔄 Warenkorb erfolgreich im Backend entfernt: ${cartToRemove.displayName}');
  } catch (e) {
    // ⚠️ Rollback bei Fehler: Stelle ursprünglichen Zustand wieder her
    setState(() {
      _activeCarts.clear();
      _activeCarts.addAll(cartBackup);
      _currentCartIndex = currentIndexBackup;
      _currentSession = sessionBackup;
      _selectedCustomer = customerBackup;
      _cartItems = itemsBackup;
    });

    debugPrint('❌ Warenkorb-Entfernung fehlgeschlagen, Rollback: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Entfernen: ${cartToRemove.displayName}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  /// **🚀 PERFORMANCE-OPTIMIERT: Schnelle Kundenzuordnung mit optimistischem UI**
  Future<void> _handleCustomerChange(AppUser newCustomer) async {
    // 🎯 SMARTE LOGIK: Prüfe aktuellen Warenkorb-Status
    final currentCart = _activeCarts.isNotEmpty
        ? _activeCarts[_currentCartIndex]
        : null;
    final hasItems = _cartItems.isNotEmpty;
    final hasCurrentCustomer = _selectedCustomer != null;
    final isDifferentCustomer =
        hasCurrentCustomer && _selectedCustomer!.id != newCustomer.id;

    // 🚀 PERFORMANCE: Sofortiger UI-Update für bessere UX
    setState(() {
      _selectedCustomer = newCustomer;
      // Sofortiges visuelles Feedback
      _searchText = '';
      _searchController.clear();
      _filteredUsers = _allUsers;
    });

    // Sofortiges Erfolgs-Feedback
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

    // 🚀 PERFORMANCE: Backend-Sync asynchron im Hintergrund
    _syncCustomerChangeInBackground(newCustomer, currentCart, hasItems, hasCurrentCustomer, isDifferentCustomer);

    debugPrint('🚀 Schnelle Kundenzuordnung: ${newCustomer.firstName} ${newCustomer.lastName}');
  }

  /// **🔄 HINTERGRUND-SYNC: Synchronisiert Kundenzuordnung ohne UI-Blockierung**
  Future<void> _syncCustomerChangeInBackground(
    AppUser newCustomer,
    CartSession? currentCart,
    bool hasItems,
    bool hasCurrentCustomer,
    bool isDifferentCustomer,
  ) async {
    try {
      // 1. SZENARIO: Leerer Warenkorb oder gleicher Kunde → Einfach zuordnen
      if (!hasItems || (!hasCurrentCustomer || !isDifferentCustomer)) {
        // 🖥️ Gerätespezifische Session mit Kunde erstellen/aktualisieren
        final client = Provider.of<Client>(context, listen: false);
        final deviceId = await _getDeviceId();
        final newSession = await client.pos.createDeviceSession(
          deviceId,
          newCustomer.id,
        );

        setState(() {
          _currentSession = newSession;
          if (currentCart != null) {
            _activeCarts[_currentCartIndex] = currentCart.copyWith(
              customer: newCustomer,
              posSession: newSession,
            );
          }
        });

        debugPrint('🔄 Kunde im Hintergrund synchronisiert: ${newSession.id}');
      }
      // 2. SZENARIO: Warenkorb mit anderem Kunden → Neuen Warenkorb erstellen
      else if (hasItems && isDifferentCustomer) {
        debugPrint('🆕 Neuen Warenkorb für anderen Kunden erstellen');
        await _createNewCart(customer: newCustomer);
      }
      // 3. FALLBACK: Warenkorb mit Items aber ohne Kunde → Session-Update nötig
      else {
        debugPrint('🔄 Kunde zu Warenkorb mit Items zuordnen - Session-Update');

        // 🖥️ KRITISCH: Neue Session für Kunde erstellen und Items übertragen
        final client = Provider.of<Client>(context, listen: false);
        final deviceId = await _getDeviceId();
        final oldSession = currentCart?.posSession;
        final newSession = await client.pos.createDeviceSession(
          deviceId,
          newCustomer.id,
        );

        // 🔄 WICHTIG: Alle Items aus alter Session in neue Session übertragen
        if (oldSession != null && _cartItems.isNotEmpty) {
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

        setState(() {
          _selectedCustomer = newCustomer;
          _currentSession = newSession;
          if (currentCart != null) {
            _activeCarts[_currentCartIndex] = currentCart.copyWith(
              customer: newCustomer,
              posSession: newSession,
            );
          }
        });

        // Cart-Items neu laden nach Session-Transfer
        await _loadCartItems();
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

  /// **🚀 PERFORMANCE-OPTIMIERT: Schnelles Artikel-Hinzufügen mit optimistischem UI**
/// **🔧 BUG-FIX: Prüft auf bestehende Items und erhöht Menge statt Duplikate zu erstellen**
  Future<void> _addItemToCart(
    String itemType,
    int itemId,
    String itemName,
    double price,
  ) async {
    if (_currentSession == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine aktive Session - bitte neu starten'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 🔧 BUG-FIX: Prüfe ob Item bereits im Warenkorb existiert
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.itemType == itemType && item.itemId == itemId,
    );

    if (existingItemIndex != -1) {
      // ✅ Item existiert bereits - erhöhe Menge
      final existingItem = _cartItems[existingItemIndex];
      final newQuantity = existingItem.quantity + 1;
      final newTotalPrice = existingItem.unitPrice * newQuantity;

      // 🚀 PERFORMANCE: Sofortiger optimistischer UI-Update
      setState(() {
        _cartItems[existingItemIndex] = PosCartItem(
          id: existingItem.id,
          sessionId: existingItem.sessionId,
          itemType: existingItem.itemType,
          itemId: existingItem.itemId,
          itemName: existingItem.itemName,
          unitPrice: existingItem.unitPrice,
          quantity: newQuantity,
          totalPrice: newTotalPrice,
          addedAt: existingItem.addedAt,
        );
        
        // Update auch im CartSession-Cache
        if (_currentCartIndex >= 0 && _currentCartIndex < _activeCarts.length) {
          final updatedCart = _activeCarts[_currentCartIndex].copyWith(
            items: List.from(_cartItems),
          );
          _activeCarts[_currentCartIndex] = updatedCart;
        }
      });

      // 🔄 Backend-Sync für Mengen-Update
      if (existingItem.id != null) {
        _updateCartItemQuantity(existingItem.id!, newQuantity);
      }

      debugPrint('🔢 Artikel-Menge erhöht: $itemName (${existingItem.quantity} → $newQuantity)');
      
      // ✅ Visuelles Feedback für Mengen-Erhöhung
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.add, color: Colors.white),
                const SizedBox(width: 8),
                Text('$itemName: ${existingItem.quantity} → $newQuantity'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    // 🆕 Item existiert noch nicht - neues Item hinzufügen
    final optimisticItem = PosCartItem(
      sessionId: _currentSession!.id!,
      itemType: itemType,
      itemId: itemId,
      itemName: itemName,
      unitPrice: price,
      quantity: 1,
      totalPrice: price,
      addedAt: DateTime.now(),
    );

    // 🚀 PERFORMANCE: Sofortiger UI-Update
    setState(() {
      _cartItems.add(optimisticItem);
      // Update auch im CartSession-Cache
      if (_currentCartIndex >= 0 && _currentCartIndex < _activeCarts.length) {
        final updatedCart = _activeCarts[_currentCartIndex].copyWith(
          items: List.from(_cartItems),
        );
        _activeCarts[_currentCartIndex] = updatedCart;
      }
    });

    // 🚀 PERFORMANCE: Backend-Sync asynchron im Hintergrund
    _syncAddItemInBackground(itemType, itemId, itemName, price, optimisticItem);

    debugPrint('🆕 Neuer Artikel hinzugefügt: $itemName');
  }

  /// **🔄 HINTERGRUND-SYNC: Synchronisiert Artikel-Hinzufügen ohne UI-Blockierung**
  Future<void> _syncAddItemInBackground(
    String itemType,
    int itemId,
    String itemName,
    double price,
    PosCartItem optimisticItem,
  ) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      final realItem = await client.pos.addToCart(
        _currentSession!.id!,
        itemType,
        itemId,
        itemName,
        price,
        1, // quantity
      );

      // Ersetze optimistisches Item durch echtes Backend-Item
      setState(() {
        final index = _cartItems.indexWhere((item) =>
          item.itemId == optimisticItem.itemId &&
          item.addedAt == optimisticItem.addedAt);

        if (index >= 0) {
          _cartItems[index] = realItem;
          // Update auch im CartSession-Cache
          if (_currentCartIndex >= 0 && _currentCartIndex < _activeCarts.length) {
            final updatedCart = _activeCarts[_currentCartIndex].copyWith(
              items: List.from(_cartItems),
            );
            _activeCarts[_currentCartIndex] = updatedCart;
          }
        }
      });

      debugPrint('🔄 Artikel im Hintergrund synchronisiert: $itemName');
    } catch (e) {
      // ⚠️ Rollback bei Fehler: Entferne optimistisches Item
      setState(() {
        _cartItems.removeWhere((item) =>
          item.itemId == optimisticItem.itemId &&
          item.addedAt == optimisticItem.addedAt);

        // Update auch im CartSession-Cache
        if (_currentCartIndex >= 0 && _currentCartIndex < _activeCarts.length) {
          final updatedCart = _activeCarts[_currentCartIndex].copyWith(
            items: List.from(_cartItems),
          );
          _activeCarts[_currentCartIndex] = updatedCart;
        }
      });

      debugPrint('❌ Artikel-Hinzufügen fehlgeschlagen, Rollback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Hinzufügen: $itemName'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// **🚀 PERFORMANCE-OPTIMIERT: Schnelles Artikel-Entfernen mit optimistischem UI**
  Future<void> _removeItemFromCart(int cartItemId) async {
    // Finde das zu entfernende Item für Rollback
    PosCartItem? itemToRemove;
    try {
      itemToRemove = _cartItems.firstWhere((item) => item.id == cartItemId);
    } catch (e) {
      debugPrint('⚠️ Item zum Entfernen nicht gefunden: $cartItemId');
      return;
    }

    // 🚀 PERFORMANCE: Sofortiger optimistischer UI-Update
    setState(() {
      _cartItems.removeWhere((item) => item.id == cartItemId);
      // Update auch im CartSession-Cache
      if (_currentCartIndex >= 0 && _currentCartIndex < _activeCarts.length) {
        final updatedCart = _activeCarts[_currentCartIndex].copyWith(
          items: List.from(_cartItems),
        );
        _activeCarts[_currentCartIndex] = updatedCart;
      }
    });

    // ✅ Sofortiges visuelles Feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete, color: Colors.white),
              const SizedBox(width: 8),
              Text('${itemToRemove.itemName} entfernt'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // 🔄 Backend-Sync im Hintergrund
    _syncRemoveItemInBackground(cartItemId, itemToRemove);

    debugPrint('🚀 Schnelles Artikel-Entfernen: ${itemToRemove.itemName}');
  }

  /// **🔄 HINTERGRUND-SYNC: Artikel-Entfernung ohne UI-Blockierung**
  Future<void> _syncRemoveItemInBackground(int cartItemId, PosCartItem itemToRemove) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      await client.pos.removeFromCart(cartItemId);
      
      debugPrint('🔄 Artikel erfolgreich im Backend entfernt: ${itemToRemove.itemName}');
    } catch (e) {
      // ⚠️ Rollback bei Fehler: Füge Item wieder hinzu
      setState(() {
        _cartItems.add(itemToRemove);
        // Update auch im CartSession-Cache
        if (_currentCartIndex >= 0 && _currentCartIndex < _activeCarts.length) {
          final updatedCart = _activeCarts[_currentCartIndex].copyWith(
            items: List.from(_cartItems),
          );
          _activeCarts[_currentCartIndex] = updatedCart;
        }
      });

      debugPrint('❌ Artikel-Entfernen fehlgeschlagen, Rollback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Entfernen: ${itemToRemove.itemName}'),
            backgroundColor: Colors.red,
          ),
        );
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

  /// **🚀 PERFORMANCE-OPTIMIERT: Schnelle intelligente Ticketauswahl mit optimistischem UI**
  Future<void> _addIntelligentTicketToCart(TicketType selectedTicket) async {
    if (_currentSession == null) return;

    // 🚀 PERFORMANCE: Sofortiger optimistischer UI-Update
    double finalPrice = selectedTicket.defaultPrice;
    TicketType finalTicket = selectedTicket;
    
    // Sofortiges optimistisches Item erstellen
    final optimisticItem = PosCartItem(
      sessionId: _currentSession!.id!,
      itemType: 'ticket',
      itemId: selectedTicket.id!,
      itemName: selectedTicket.name,
      unitPrice: finalPrice,
      quantity: 1,
      totalPrice: finalPrice,
      addedAt: DateTime.now(),
    );

    // Sofortiger UI-Update
    setState(() {
      _cartItems.add(optimisticItem);
      // Update auch im CartSession-Cache
      if (_currentCartIndex >= 0 && _currentCartIndex < _activeCarts.length) {
        final updatedCart = _activeCarts[_currentCartIndex].copyWith(
          items: List.from(_cartItems),
        );
        _activeCarts[_currentCartIndex] = updatedCart;
      }
    });

    // 🚀 PERFORMANCE: Intelligente Berechnung und Backend-Sync im Hintergrund
    _syncIntelligentTicketInBackground(selectedTicket, optimisticItem);

    debugPrint('🚀 Schnelles Ticket-Hinzufügen: ${selectedTicket.name}');
  }

  /// **🔄 HINTERGRUND-SYNC: Intelligente Ticketauswahl ohne UI-Blockierung**
  Future<void> _syncIntelligentTicketInBackground(
    TicketType selectedTicket,
    PosCartItem optimisticItem,
  ) async {
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
      final realItem = await client.pos.addToCart(
        _currentSession!.id!,
        'ticket',
        finalTicket.id!,
        finalTicket.name,
        finalPrice,
        1, // quantity
      );

      // Ersetze optimistisches Item durch echtes Backend-Item
      setState(() {
        final index = _cartItems.indexWhere((item) =>
          item.itemId == optimisticItem.itemId &&
          item.addedAt == optimisticItem.addedAt);

        if (index >= 0) {
          _cartItems[index] = realItem;
          // Update auch im CartSession-Cache
          if (_currentCartIndex >= 0 && _currentCartIndex < _activeCarts.length) {
            final updatedCart = _activeCarts[_currentCartIndex].copyWith(
              items: List.from(_cartItems),
            );
            _activeCarts[_currentCartIndex] = updatedCart;
          }
        }
      });

      // ✅ SUCCESS FEEDBACK mit Ersparnis-Info (nur bei Preisoptimierung)
      if (mounted && hasSavings) {
        final message = '💰 Ersparnis: ${savings.toStringAsFixed(2)}€ für ${finalTicket.name}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('🔄 Intelligentes Ticket im Hintergrund synchronisiert: ${finalTicket.name}');
      if (hasSavings && _selectedCustomer != null) {
        debugPrint('🎉 Ersparnis für ${_selectedCustomer!.firstName}: ${savings.toStringAsFixed(2)}€');
      }
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

  // 🗑️ ENTFERNT: Doppelte Methodendefinitionen (bereits weiter oben im Code definiert)

  // ==================== SEARCH FUNCTIONALITY ====================

  /// 🗑️ DEPRECATED: Search Input wird jetzt vom CustomerSearchSection Widget gehandhabt
  @deprecated
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

  /// 🗑️ DEPRECATED: Scanner-Fokus wird jetzt vom CustomerSearchSection Widget gehandhabt
  @deprecated
  void _restoreScannerFocus() {
    // Auto-focus wird jetzt vom CustomerSearchSection Widget gehandhabt
  }

  /// 🗑️ DEPRECATED: Search Field wird jetzt vom CustomerSearchSection Widget gehandhabt
  @deprecated
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

  /// 🗑️ DEPRECATED: Kundensuche erfolgt jetzt über CustomerSearchSection Widget
  @deprecated
  void _performCustomerSearch(String query) {
    // Leere Implementierung - neue Suche verwendet UniversalSearchEndpoint
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

      // 🆕 2. BACKEND-KATEGORIEN LADEN - MIT ROBUSTER FEHLERBEHANDLUNG
      List<ProductCategory> categories = [];
      List<Product> products = [];
      
      try {
        categories = await client.productManagement.getProductCategories(
          onlyActive: true,
        );
        debugPrint('✅ Kategorien erfolgreich geladen: ${categories.length}');
      } catch (categoryError) {
        debugPrint('⚠️ Fehler beim Laden der Kategorien: $categoryError');
        debugPrint('🔄 Verwende Fallback: Leere Kategorie-Liste');
        categories = []; // Fallback: Leere Liste
      }
      
      try {
        products = await client.productManagement.getProducts(
          onlyActive: true,
        );
        debugPrint('✅ Produkte erfolgreich geladen: ${products.length}');
      } catch (productError) {
        debugPrint('⚠️ Fehler beim Laden der Produkte: $productError');
        debugPrint('🔄 Verwende Fallback: Leere Produkt-Liste');
        products = []; // Fallback: Leere Liste
      }

      debugPrint('🏪 Backend-Daten geladen:');
      debugPrint('  • Kategorien: ${categories.length}');
      debugPrint('  • Produkte: ${products.length}');

      // 🆕 3. HIERARCHISCHE STRUKTUR AUFBAUEN
      await _buildCategoryHierarchy(categories, products, filteredTickets);

      // 🆕 4. STATE AKTUALISIEREN
      setState(() {
        _allCategories = categories;
        _allProducts = products;
      });

      debugPrint('🏗️ Hierarchische Kategorien-Struktur aufgebaut');
      _categoryHierarchy.forEach((topLevelName, data) {
        debugPrint(
          '  🏗️ $topLevelName: ${data['subCategories']?.length ?? 0} Sub-Kategorien',
        );
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

  /// **🏗️ NEUE METHODE: Hierarchische Kategorien-Struktur aufbauen**
  Future<void> _buildCategoryHierarchy(
    List<ProductCategory> categories,
    List<Product> products,
    List<TicketType> filteredTickets,
  ) async {
    debugPrint('🔧 DEBUG: _buildCategoryHierarchy START');
    debugPrint('🔧 DEBUG: Eingehende Daten:');
    debugPrint('   📦 Kategorien: ${categories.length}');
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      debugPrint(
        '     🏷️  Kategorie $i: ID=${cat.id}, Name="${cat.name}", Level=${cat.level}, Parent=${cat.parentCategoryId}',
      );
    }
    debugPrint('   📦 Produkte: ${products.length}');
    for (int i = 0; i < products.length; i++) {
      final prod = products[i];
      debugPrint(
        '     🛒 Produkt $i: ID=${prod.id}, Name="${prod.name}", KategorieID=${prod.categoryId}',
      );
    }
    debugPrint('   🎫 Tickets: ${filteredTickets.length}');

    final newCategorizedItems = <String, List<dynamic>>{};
    final newHierarchy = <String, Map<String, dynamic>>{};

    // 🎫 1. TICKET-KATEGORIEN (wie bisher)
    final hallentickets = filteredTickets
        .where((ticket) => ticket.gymId != null)
        .toList();
    final verticUniversal = filteredTickets
        .where((ticket) => ticket.gymId == null && ticket.isVerticUniversal)
        .toList();

    debugPrint('🎫 TICKET-KATEGORIEN:');
    debugPrint('   🏟️  Hallentickets: ${hallentickets.length}');
    debugPrint('   🌐 Vertic Universal: ${verticUniversal.length}');

    if (hallentickets.isNotEmpty) {
      final categoryName = '🎫 Hallentickets';
      newCategorizedItems[categoryName] = hallentickets;
      newHierarchy[categoryName] = {
        'type': 'tickets',
        'items': hallentickets,
        'subCategories': <String, List<dynamic>>{},
        'icon': Icons.local_activity,
        'color': Colors.blue,
      };

      // Auto-Select erste Kategorie wenn noch keine ausgewählt
      if (_currentTopLevelCategory?.isEmpty ?? true) {
        _currentTopLevelCategory = categoryName;
        _selectedCategory =
            categoryName; // ✅ Wichtig: Auch _selectedCategory setzen!
        debugPrint('🎯 Auto-Select erste Top-Level-Kategorie: $categoryName');
      }
    }

    if (verticUniversal.isNotEmpty) {
      final categoryName = '🎟️ Vertic Universal';
      newCategorizedItems[categoryName] = verticUniversal;
      newHierarchy[categoryName] = {
        'type': 'tickets',
        'items': verticUniversal,
        'subCategories': <String, List<dynamic>>{},
        'icon': Icons.card_membership,
        'color': Colors.purple,
      };
    }

    // 🏗️ 2. ECHTE HIERARCHISCHE PRODUKT-KATEGORIEN AUFBAUEN
    debugPrint('🏗️ HIERARCHISCHE PRODUKT-KATEGORIEN:');

    // Filtere Top-Level-Kategorien (level = 0 oder parentCategoryId = null)
    final topLevelCategories = categories
        .where((cat) => cat.level == 0 || cat.parentCategoryId == null)
        .toList();

    debugPrint(
      '🔍 Gefundene Top-Level-Kategorien: ${topLevelCategories.length}',
    );
    for (int i = 0; i < topLevelCategories.length; i++) {
      final cat = topLevelCategories[i];
      debugPrint(
        '   📂 Top-Level $i: ID=${cat.id}, Name="${cat.name}", Level=${cat.level}',
      );
    }

    for (final topCategory in topLevelCategories) {
      debugPrint(
        '\n🔍 VERARBEITE Top-Level-Kategorie: "${topCategory.name}" (ID: ${topCategory.id})',
      );

      // Icon und Farbe aus Kategorie-Daten
      final categoryIcon = _getIconFromName(topCategory.iconName);
      final categoryColor = _getColorFromHex(topCategory.colorHex);
      debugPrint('   🎨 Icon: ${topCategory.iconName} → $categoryIcon');
      debugPrint('   🎨 Farbe: ${topCategory.colorHex} → $categoryColor');

      // Produkte dieser Top-Level-Kategorie
      final categoryProducts = products
          .where((product) => product.categoryId == topCategory.id)
          .toList();
      debugPrint('   📦 Direkte Produkte: ${categoryProducts.length}');
      for (int i = 0; i < categoryProducts.length; i++) {
        final prod = categoryProducts[i];
        debugPrint('     🛒 Produkt $i: "${prod.name}" (€${prod.price})');
      }

      // Sub-Kategorien finden (parentCategoryId = topCategory.id)
      final subCategories = categories
          .where((cat) => cat.parentCategoryId == topCategory.id)
          .toList();
      debugPrint('   📁 Sub-Kategorien: ${subCategories.length}');

      final subCategoryData = <String, List<dynamic>>{};

      // Sub-Kategorien verarbeiten
      for (final subCategory in subCategories) {
        debugPrint(
          '     🔍 Verarbeite Sub-Kategorie: "${subCategory.name}" (ID: ${subCategory.id})',
        );
        final subProducts = products
            .where((product) => product.categoryId == subCategory.id)
            .toList();
        debugPrint('       📦 Sub-Produkte: ${subProducts.length}');

        // ✅ IMMER hinzufügen, auch wenn keine Produkte (für Navigation)
        subCategoryData[subCategory.name] = subProducts;
        debugPrint(
          '   📁 Sub-Kategorie: ${subCategory.name} (${subProducts.length} Produkte)',
        );
      }

      // Kategorie-Name mit Emoji für bessere Darstellung
      final displayName =
          '${_getCategoryEmoji(topCategory.iconName)} ${topCategory.name}';
      debugPrint('   🏷️  Display-Name: "$displayName"');

      // Alle Items dieser Top-Level-Kategorie (direkte Produkte + Sub-Kategorie-Produkte)
      final allItems = <dynamic>[...categoryProducts];
      for (final subItems in subCategoryData.values) {
        allItems.addAll(subItems);
      }
      debugPrint(
        '   📊 Gesamt-Items: ${allItems.length} (${categoryProducts.length} direkt + ${allItems.length - categoryProducts.length} aus Sub-Kategorien)',
      );

      newCategorizedItems[displayName] = allItems;
      newHierarchy[displayName] = {
        'type': 'products',
        'category': topCategory,
        'items': categoryProducts, // Direkte Produkte
        'subCategories': subCategoryData, // Sub-Kategorien mit ihren Produkten
        'icon': categoryIcon,
        'color': categoryColor,
        'hasSubCategories': subCategories.isNotEmpty,
      };

      debugPrint('✅ Top-Level-Kategorie aufgebaut: $displayName');
      debugPrint('   • Direkte Produkte: ${categoryProducts.length}');
      debugPrint('   • Sub-Kategorien: ${subCategories.length}');
      debugPrint('   • Gesamt-Items: ${allItems.length}');

      // Auto-Select erste Produkt-Kategorie wenn noch keine Tickets
      if (_currentTopLevelCategory?.isEmpty ?? true && allItems.isNotEmpty) {
        _currentTopLevelCategory = displayName;
        _selectedCategory =
            displayName; // ✅ Wichtig: Auch _selectedCategory setzen!
        debugPrint('🎯 Auto-Select erste Produkt-Kategorie: $displayName');
      }
    }

    // 3. STATE AKTUALISIEREN
    debugPrint('\n📊 FINALE ZUSAMMENFASSUNG:');
    debugPrint(
      '   🗂️  _categorizedItems: ${newCategorizedItems.keys.toList()}',
    );
    debugPrint('   🏗️ _categoryHierarchy: ${newHierarchy.keys.toList()}');
    debugPrint('   🎯 _currentTopLevelCategory: $_currentTopLevelCategory');
    debugPrint('   🎯 _selectedCategory: $_selectedCategory');

    setState(() {
      _categorizedItems = newCategorizedItems;
      _categoryHierarchy = newHierarchy;
    });

    debugPrint('🔧 DEBUG: _buildCategoryHierarchy ENDE\n');
  }

  /// **🎨 HILFSMETHODEN FÜR KATEGORIE-DARSTELLUNG**

  IconData _getIconFromName(String? iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'local_drink':
        return Icons.local_drink;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'sports':
        return Icons.sports;
      case 'checkroom':
        return Icons.checkroom;
      case 'build':
        return Icons.build;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.category;
    }
  }

  Color _getColorFromHex(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return Colors.grey;
    }
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _getCategoryEmoji(String? iconName) {
    switch (iconName) {
      case 'fastfood':
        return '🍔';
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
        return '❤️';
      default:
        return '📦';
    }
  }

  /// **🏗️ HILFSMETHODE: Top-Level-Gruppe für Kategorie bestimmen**
  /// TODO: Nach Migration durch echte parentCategoryId ersetzen
  String _getTopLevelGroupForCategory(ProductCategory category) {
    final name = category.name.toLowerCase();

    // Getränke-Gruppe
    if (name.contains('getränk') ||
        name.contains('drink') ||
        name.contains('bier') ||
        name.contains('wasser') ||
        category.iconName == 'local_drink') {
      return 'Getränke & Drinks';
    }

    // Essen-Gruppe
    if (name.contains('essen') ||
        name.contains('food') ||
        name.contains('snack') ||
        name.contains('lunch') ||
        category.iconName == 'fastfood' ||
        category.iconName == 'lunch_dining') {
      return 'Essen & Snacks';
    }

    // Kleidung-Gruppe
    if (name.contains('kleidung') ||
        name.contains('bekleidung') ||
        name.contains('shirt') ||
        name.contains('schuhe') ||
        category.iconName == 'checkroom') {
      return 'Bekleidung & Zubehör';
    }

    // Sport-Gruppe
    if (name.contains('sport') ||
        name.contains('fitness') ||
        name.contains('training') ||
        category.iconName == 'sports') {
      return 'Sport & Fitness';
    }

    // Standard-Gruppe
    return 'Shop Artikel';
  }

  /// **🎨 HILFSMETHODE: Kategorie-Daten für UI abrufen**
  Map<String, dynamic> _getCategoryDataByName(String categoryName) {
    // Für Ticket-Kategorien
    if (categoryName.contains('Hallentickets')) {
      return {
        'color': Colors.blue,
        'icon': Icons.local_activity,
        'name': 'Hallen-\ntickets',
      };
    }
    if (categoryName.contains('Vertic Universal')) {
      return {
        'color': Colors.purple,
        'icon': Icons.card_membership,
        'name': 'Vertic\nUniversal',
      };
    }

    // Für Backend-Kategorien
    final cleanName = categoryName.replaceAll(
      RegExp(r'^[^\s]+ '),
      '',
    ); // Emoji entfernen
    final category = _allCategories.firstWhere(
      (cat) => cat.name == cleanName,
      orElse: () => ProductCategory(
        name: cleanName,
        colorHex: '#607D8B',
        iconName: 'category',
        isActive: true,
        displayOrder: 0,
      ),
    );

    return {
      'color': Color(int.parse(category.colorHex.replaceFirst('#', '0xFF'))),
      'icon': _iconMapping[category.iconName] ?? Icons.category,
      'name': category.name,
    };
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

  // ==================== LIVE-FILTER METHODS ====================

  /// **🔍 LIVE-FILTER: Hauptmethode für Echtzeit-Suche**
  void _performLiveSearch(String query) {
    // Debounce Timer zurücksetzen
    if (_searchDebounceTimer?.isActive ?? false) {
      _searchDebounceTimer!.cancel();
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final cleanQuery = query.toLowerCase().trim();
      debugPrint('🔍 Live-Suche: "$cleanQuery"');

      setState(() {
        _liveSearchQuery = cleanQuery;
        _isLiveSearchActive = cleanQuery.isNotEmpty;

        if (_isLiveSearchActive) {
          // Filtere Produkte und Kategorien
          _filteredProducts = _filterProducts(cleanQuery);
          _filteredCategories = _filterCategories(cleanQuery);
          _categoryArticleCounts = _calculateCategoryCounts();
          
          debugPrint('🎯 Gefunden: ${_filteredProducts.length} Produkte, ${_filteredCategories.length} Kategorien');
        } else {
          // 🧹 UX-FIX: Vollständiger Reset bei leerer Suche
          _filteredProducts = [];
          _filteredCategories = [];
          _categoryArticleCounts = {};
          debugPrint('🧹 Live-Filter automatisch zurückgesetzt (Suchfeld leer)');
        }
      });
    });
  }

  /// **🎯 FILTER-ALGORITHMUS: Filtert Produkte basierend auf Suchbegriff**
  List<Product> _filterProducts(String query) {
    if (query.isEmpty) return _allProducts;

    final results = <Product>[];
    final exactMatches = <Product>[];
    final partialMatches = <Product>[];
    final categoryMatches = <Product>[];

    for (final product in _allProducts) {
      final productName = product.name.toLowerCase();
      final category = _getCategoryForProduct(product);
      final categoryName = category?.name.toLowerCase() ?? '';

      // 1. Exakte Treffer (Produktname beginnt mit Suchbegriff)
      if (productName.startsWith(query)) {
        exactMatches.add(product);
      }
      // 2. Teilstring-Treffer (Suchbegriff im Produktnamen)
      else if (productName.contains(query)) {
        partialMatches.add(product);
      }
      // 3. Kategorie-Treffer (Suchbegriff in Kategorie-Name)
      else if (categoryName.contains(query)) {
        categoryMatches.add(product);
      }
    }

    // Sortierung nach Relevanz
    exactMatches.sort((a, b) => a.name.compareTo(b.name));
    partialMatches.sort((a, b) => _calculateRelevanceScore(b, query).compareTo(_calculateRelevanceScore(a, query)));
    categoryMatches.sort((a, b) => a.name.compareTo(b.name));

    // Zusammenführen in Relevanz-Reihenfolge
    results.addAll(exactMatches);
    results.addAll(partialMatches);
    results.addAll(categoryMatches);

    return results;
  }

  /// **📂 KATEGORIE-FILTER: Filtert Kategorien basierend auf Suchbegriff**
  List<ProductCategory> _filterCategories(String query) {
    if (query.isEmpty) return _allCategories;

    return _allCategories.where((category) {
      final categoryName = category.name.toLowerCase();
      return categoryName.contains(query);
    }).toList();
  }

  /// **🔢 ARTIKEL-ZÄHLUNG: Berechnet Artikel-Anzahl pro Kategorie**
  Map<String, int> _calculateCategoryCounts() {
    final counts = <String, int>{};

    // Zähle gefilterte Produkte pro Kategorie
    for (final product in _filteredProducts) {
      final category = _getCategoryForProduct(product);
      if (category != null) {
        final topLevelGroup = _getTopLevelGroupForCategory(category);
        counts[topLevelGroup] = (counts[topLevelGroup] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// **⭐ RELEVANZ-SCORE: Berechnet Relevanz-Score für Sortierung**
  int _calculateRelevanceScore(Product product, String query) {
    final productName = product.name.toLowerCase();
    int score = 0;

    // Exakter Treffer am Anfang = höchste Relevanz
    if (productName.startsWith(query)) {
      score += 100;
    }

    // Anzahl der Übereinstimmungen
    final matches = query.split(' ').where((word) => productName.contains(word)).length;
    score += matches * 10;

    // Kürzere Namen = höhere Relevanz
    score += (100 - productName.length.clamp(0, 100));

    return score;
  }

  /// **🔗 HILFSMETHODE: Findet Kategorie für Produkt**
  ProductCategory? _getCategoryForProduct(Product product) {
    return _allCategories.firstWhere(
      (category) => category.id == product.categoryId,
      orElse: () => ProductCategory(
        name: 'Unbekannt',
        colorHex: '#607D8B',
        iconName: 'category',
        isActive: true,
        displayOrder: 999,
      ),
    );
  }

  /// **🎯 LIVE-FILTER CALLBACK: Wird von PosSearchSection aufgerufen**
  void _onLiveFilterChanged(String query) {
    _performLiveSearch(query);
  }

  /// **🧹 LIVE-FILTER RESET: Setzt Live-Filter zurück**
  void _resetLiveFilter() {
    setState(() {
      _liveSearchQuery = '';
      _isLiveSearchActive = false;
      _filteredProducts = [];
      _filteredCategories = [];
      _categoryArticleCounts = {};
    });
    debugPrint('🧹 Live-Filter zurückgesetzt');
  }



  // ==================== UI COMPONENTS ====================

  /// **👤 KUNDEN-INFORMATIONS-ANZEIGE - Verwendet eigenständiges Widget**
  Widget _buildCustomerSearchSection() {
    return PosCustomerInfoDisplayWidget(
      selectedCustomer: _selectedCustomer,
      autofocus: true,
      hintText: 'Kunde oder Produkt suchen (Scanner bereit)...',
      onCustomerSelected: (customer) async {
        // 🧹 WARENKORB-SYNCHRONISATION: Bei Personenwechsel alles zurücksetzen
        await _handleCustomerChange(customer);
      },
      onProductSelected: (product) async {
        // 🛒 PRODUKT-DIREKTAUSWAHL: Produkt direkt zum aktuellen Warenkorb hinzufügen
        await _handleProductSelection(product);
      },
      onCustomerRemoved: () async {
        // 🧹 WARENKORB-RESET: Bei Kunde entfernen
        await _handleCustomerRemoval();
      },
      // 🔍 LIVE-FILTER INTEGRATION
      onLiveFilterChanged: _onLiveFilterChanged,
      liveFilterQuery: _liveSearchQuery,
      isLiveFilterActive: _isLiveSearchActive,
      onLiveFilterReset: _resetLiveFilter,
    );
  }

  /// **🎯 NAVIGATION: Top-Level-Kategorie auswählen**
  void _selectTopLevelCategory(String categoryName) {
    debugPrint('🎯 Top-Level-Kategorie ausgewählt: $categoryName');

    // 🧹 UX-FIX: Live-Filter zurücksetzen bei Kategorie-Navigation
    if (_isLiveSearchActive) {
      _resetLiveFilter();
      debugPrint('🧹 Live-Filter automatisch zurückgesetzt bei Kategorie-Wechsel');
    }

    // Prüfe ob diese Kategorie Unterkategorien hat
    final hierarchyData = _categoryHierarchy[categoryName];
    final subCategories =
        hierarchyData?['subCategories'] as Map<String, List<dynamic>>? ?? {};
    final hasSubCategories = subCategories.isNotEmpty;

    debugPrint(
      '🔍 DEBUG: hasSubCategories für $categoryName: $hasSubCategories',
    );
    debugPrint('🔍 DEBUG: subCategories Anzahl: ${subCategories.length}');

    setState(() {
      _selectedCategory = categoryName;
      _currentTopLevelCategory = categoryName;
      _categoryBreadcrumb = [categoryName];

      // ✅ NEU: Automatisch Unterkategorien anzeigen wenn verfügbar
      if (hasSubCategories) {
        _showingSubCategories = true;
        // Erste Unterkategorie automatisch auswählen
        _selectedCategory = subCategories.keys.first;
        _categoryBreadcrumb = [categoryName, subCategories.keys.first];
        debugPrint(
          '📁 ✅ Unterkategorien automatisch angezeigt für: $categoryName',
        );
        debugPrint(
          '📁    → Erste Unterkategorie ausgewählt: ${subCategories.keys.first}',
        );
      } else {
        _showingSubCategories = false;
        debugPrint('📁 ❌ Keine Unterkategorien für: $categoryName');
      }
    });
  }

  /// **📁 NAVIGATION: Zu Sub-Kategorien wechseln**
  void _navigateToSubCategories(String topLevelCategory) {
    debugPrint(
      '🔍 DEBUG: _navigateToSubCategories aufgerufen für: $topLevelCategory',
    );

    // 🧹 UX-FIX: Live-Filter zurücksetzen bei Kategorie-Navigation
    if (_isLiveSearchActive) {
      _resetLiveFilter();
      debugPrint('🧹 Live-Filter automatisch zurückgesetzt bei Sub-Kategorie-Navigation');
    }

    final hierarchyData = _categoryHierarchy[topLevelCategory];
    debugPrint('🔍 DEBUG: hierarchyData gefunden: ${hierarchyData != null}');

    final subCategories =
        hierarchyData?['subCategories'] as Map<String, List<dynamic>>? ?? {};
    debugPrint('🔍 DEBUG: subCategories Anzahl: ${subCategories.length}');
    debugPrint('🔍 DEBUG: subCategories Keys: ${subCategories.keys.toList()}');

    if (subCategories.isNotEmpty) {
      setState(() {
        _currentTopLevelCategory = topLevelCategory;
        _showingSubCategories = true;
        _selectedCategory =
            subCategories.keys.first; // Erste Sub-Kategorie auswählen
        _categoryBreadcrumb = [topLevelCategory, subCategories.keys.first];
      });
      debugPrint('📁 ✅ Zu Sub-Kategorien gewechselt: $topLevelCategory');
      debugPrint('📁    → Zeige jetzt: $_selectedCategory');
      debugPrint('📁    → _showingSubCategories: $_showingSubCategories');
    } else {
      debugPrint('⚠️ Keine Sub-Kategorien gefunden für: $topLevelCategory');
    }
  }

  /// **📁 NAVIGATION: Sub-Kategorie auswählen**
  void _selectSubCategory(String subCategoryName) {
    // 🧹 UX-FIX: Live-Filter zurücksetzen bei Kategorie-Navigation
    if (_isLiveSearchActive) {
      _resetLiveFilter();
      debugPrint('🧹 Live-Filter automatisch zurückgesetzt bei Sub-Kategorie-Auswahl');
    }

    setState(() {
      _selectedCategory = subCategoryName;
      if (_categoryBreadcrumb.length >= 2) {
        _categoryBreadcrumb[1] = subCategoryName;
      } else {
        _categoryBreadcrumb = [_currentTopLevelCategory!, subCategoryName];
      }
    });
    debugPrint('📁 Sub-Kategorie ausgewählt: $subCategoryName');
  }

  /// **🏠 NAVIGATION: Zurück zu Top-Level**
  void _navigateToTopLevel() {
    // 🧹 UX-FIX: Live-Filter zurücksetzen bei Kategorie-Navigation
    if (_isLiveSearchActive) {
      _resetLiveFilter();
      debugPrint('🧹 Live-Filter automatisch zurückgesetzt bei Top-Level-Navigation');
    }

    setState(() {
      _showingSubCategories = false;
      _selectedCategory = _currentTopLevelCategory;
      _categoryBreadcrumb = [_currentTopLevelCategory!];
    });
    debugPrint('🏠 Zurück zu Top-Level: $_currentTopLevelCategory');
  }

  /// **🍞 NAVIGATION: Breadcrumb-Navigation**
  void _navigateToBreadcrumb(int index) {
    if (index == 0) {
      // Zurück zu Top-Level
      _navigateToTopLevel();
    } else if (index == 1 && _categoryBreadcrumb.length > 1) {
      // Sub-Kategorie auswählen
      _selectSubCategory(_categoryBreadcrumb[index]);
    }
  }



  /// **🎫 TICKET CARD BUILDER: Verwendet eigenständiges Widget**
  Widget _buildTicketCard(TicketType ticketType) {
    // Null-Safety: Fallback wenn keine Kategorie ausgewählt
    final selectedCat =
        _selectedCategory ?? _currentTopLevelCategory ?? 'Vertic Universal';
    final categoryData = _getCategoryDataByName(selectedCat);

    return PosTicketCardWidget(
      ticketType: ticketType,
      categoryData: categoryData,
      onTap: () {
        _addIntelligentTicketToCart(ticketType);
      },
    );
  }

  /// **🛒 PRODUCT CARD BUILDER: Verwendet eigenständiges Widget**
  Widget _buildProductCard(Product product) {
    // Null-Safety: Fallback wenn keine Kategorie ausgewählt
    final selectedCat =
        _selectedCategory ?? _currentTopLevelCategory ?? 'Vertic Universal';
    final categoryData = _getCategoryDataByName(selectedCat);

    return PosProductCardWidget(
      product: product,
      categoryData: categoryData,
      onTap: () {
        _addItemToCart('product', product.id!, product.name, product.price);
      },
    );
  }





  /// **🗑️ VERBESSERTE METHODE: Intelligente Warenkorb-Entfernung - Verwendet eigenständiges Widget**
  void _showRemoveCartDialog(int index) {
    if (index < 0 || index >= _activeCarts.length) return;

    final cart = _activeCarts[index];

    PosRemoveCartDialogWidget.show(
      context: context,
      cartIndex: index,
      cart: cart,
      onRemoveConfirmed: () => _removeCart(index),
    );
  }

  /// **🛒 NEUE METHODE: Aktuellen Warenkorb leeren**
  /// **🔧 BUG-FIX: Leert sowohl lokalen State als auch Backend-Session**
  Future<void> _clearCurrentCart() async {
    if (_activeCarts.isEmpty ||
        _currentCartIndex < 0 ||
        _currentCartIndex >= _activeCarts.length)
      return;

    final currentCart = _activeCarts[_currentCartIndex];
    
    // 🚀 PERFORMANCE: Sofortiger optimistischer UI-Update
    setState(() {
      _cartItems.clear();
      _activeCarts[_currentCartIndex] = currentCart.copyWith(items: []);
    });

    // ✅ Sofortiges visuelles Feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.clear_all, color: Colors.white),
              const SizedBox(width: 8),
              Text('Warenkorb geleert: ${currentCart.displayName}'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // 🔄 Backend-Sync im Hintergrund
    _syncClearCartInBackground(currentCart);

    debugPrint('🛒 Warenkorb geleert: ${currentCart.displayName}');
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

  /// **🔄 HINTERGRUND-SYNC: Warenkorb-Leerung ohne UI-Blockierung**
  Future<void> _syncClearCartInBackground(CartSession cartToClean) async {
    try {
      final client = Provider.of<Client>(context, listen: false);
      
      // Backend-Session komplett leeren
      if (cartToClean.posSession != null) {
        await client.pos.clearCart(cartToClean.posSession!.id!);
        debugPrint('🔄 Backend-Session geleert: ${cartToClean.posSession!.id}');
      }
      
      debugPrint('✅ Warenkorb erfolgreich im Backend geleert: ${cartToClean.displayName}');
    } catch (e) {
      debugPrint('❌ Fehler beim Leeren des Backend-Warenkorbs: $e');
      
      // Bei Fehler: Benutzer informieren, aber nicht rollback (da UI bereits geleert)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Warenkorb lokal geleert, Backend-Sync fehlgeschlagen: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
          child: PosMultiCartTabsWidget(
            activeCarts: _activeCarts,
            currentCartIndex: _currentCartIndex,
            onSwitchToCart: _switchToCart,
            onCreateNewCart: () => _createNewCart(),
            onShowRemoveCartDialog: _showRemoveCartDialog,
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              // 🎯 QUICK-FOCUS: Handled by CustomerSearchSection Widget
              onTap: () {
                // Auto-focus wird jetzt vom CustomerSearchSection Widget gehandhabt
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PosCategoryNavigationWidget(
                            categoryBreadcrumb: _categoryBreadcrumb,
                            showingSubCategories: _showingSubCategories,
                            currentTopLevelCategory: _currentTopLevelCategory,
                            selectedCategory: _selectedCategory,
                            categoryHierarchy: _categoryHierarchy,
                            onNavigateToTopLevel: _navigateToTopLevel,
                            onNavigateToBreadcrumb: _navigateToBreadcrumb,
                            onSelectTopLevelCategory: _selectTopLevelCategory,
                            onNavigateToSubCategories: _navigateToSubCategories,
                            onSelectSubCategory: _selectSubCategory,
                          ),
                          PosProductGridWidget(
                            isLiveSearchActive: _isLiveSearchActive,
                            filteredProducts: _filteredProducts,
                            showingSubCategories: _showingSubCategories,
                            currentTopLevelCategory: _currentTopLevelCategory,
                            selectedCategory: _selectedCategory,
                            categorizedItems: _categorizedItems,
                            categoryHierarchy: _categoryHierarchy,
                            onNavigateToTopLevel: _navigateToTopLevel,
                            onSelectSubCategory: _selectSubCategory,
                            buildLiveFilterResults: () => PosLiveFilterResultsWidget(
                              filteredProducts: _filteredProducts.cast<Product>(),
                              liveSearchQuery: _liveSearchQuery,
                              categoryArticleCounts: _categoryArticleCounts,
                              onResetLiveFilter: _resetLiveFilter,
                              buildProductCard: _buildProductCard,
                            ),
                            buildTicketCard: _buildTicketCard,
                            buildProductCard: _buildProductCard,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Rechte Spalte: Warenkorb
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: PosCartWidget(
                        cartItems: _cartItems,
                        selectedCustomer: _selectedCustomer,
                        onClearCart: _clearCurrentCart,
                        onRemoveItem: _removeItemFromCurrentCart,
                        onUpdateQuantity: _updateCurrentCartItemQuantity,
                        onCheckout: _performCheckout,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// **📊 DEBUG: Session-Statistiken anzeigen - Verwendet eigenständiges Widget**
  Future<void> _showSessionStats() async {
    await PosSessionStatsDialogWidget.show(context);
  }

  // ==================== SEARCH FUNCTIONALITY ====================

  /// 🔄 **INTELLIGENTE PRODUKTAUSWAHL ÜBER SUCHE**
  /// Fügt Produkt hinzu oder erhöht Menge bei bereits vorhandenem Produkt
  Future<void> _handleProductSelection(Product product) async {
    debugPrint(
      '🛒 Produkt über Suche ausgewählt: ${product.name} (€${product.price})',
    );

    try {
      // 🎯 Falls kein aktiver Warenkorb vorhanden, erstelle einen neuen
      if (_currentSession == null) {
        await _createPosSession();
      }

      final client = Provider.of<Client>(context, listen: false);

      // 🔍 SMART-LOGIC: Prüfe ob Produkt bereits im Warenkorb vorhanden
      PosCartItem? existingItem;
      try {
        existingItem = _cartItems.firstWhere(
          (item) => item.itemType == 'product' && item.itemId == product.id!,
        );
      } catch (e) {
        existingItem = null; // Produkt nicht gefunden
      }

      if (existingItem != null) {
        // 🚀 PERFORMANCE: Sofortiger UI-Update für Mengenänderung
        final nonNullItem = existingItem; // Null-Safety: Lokale non-null Variable
        setState(() {
          final index = _cartItems.indexOf(nonNullItem);
          if (index >= 0) {
            _cartItems[index] = nonNullItem.copyWith(
              quantity: nonNullItem.quantity + 1,
              totalPrice: nonNullItem.unitPrice * (nonNullItem.quantity + 1),
            );
            // Update auch im CartSession-Cache
            if (_currentCartIndex >= 0 && _currentCartIndex < _activeCarts.length) {
              final updatedCart = _activeCarts[_currentCartIndex].copyWith(
                items: List.from(_cartItems),
              );
              _activeCarts[_currentCartIndex] = updatedCart;
            }
          }
        });

        // 🔄 Backend-Sync im Hintergrund
        client.pos.updateCartItem(nonNullItem.id!, nonNullItem.quantity + 1).catchError((e) {
          debugPrint('⚠️ Hintergrund-Update fehlgeschlagen: $e');
        });

        debugPrint('🚀 Schnelle Mengenänderung: ${product.name} (${nonNullItem.quantity + 1})');
      } else {
        // 🚀 PERFORMANCE: Verwende optimierte _addItemToCart Methode
        await _addItemToCart('product', product.id!, product.name, product.price);
        debugPrint('🚀 Schnelles Produkt-Hinzufügen über Suche: ${product.name}');
      }

      // ✅ Sofortiges Feedback für User
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.search, color: Colors.white),
                const SizedBox(width: 8),
                Text('${product.name} über Suche hinzugefügt'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Hinzufügen des Produkts über Suche: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Helper-Klasse für Kategorie-Konfiguration
class CategoryConfig {
  final Color color;
  final IconData icon;
  final String name;

  CategoryConfig({required this.color, required this.icon, required this.name});
}

/// **🔄 GLOBALES EVENT-SYSTEM für Artikel-Updates**
class ProductCatalogEvents {
  static final _instance = ProductCatalogEvents._internal();
  factory ProductCatalogEvents() => _instance;
  ProductCatalogEvents._internal();

  final List<VoidCallback> _listeners = [];

  /// Registriere einen Listener für Artikel-Änderungen
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    debugPrint(
      '📡 ProductCatalogEvents: Listener registriert (${_listeners.length} total)',
    );
  }

  /// Entferne einen Listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    debugPrint(
      '📡 ProductCatalogEvents: Listener entfernt (${_listeners.length} total)',
    );
  }

  /// Benachrichtige alle Listener über Änderungen
  void notifyProductChanged() {
    debugPrint(
      '🔄 ProductCatalogEvents: Benachrichtige ${_listeners.length} Listener',
    );
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('❌ Fehler beim Benachrichtigen eines Listeners: $e');
      }
    }
  }

  /// Spezielle Benachrichtigung für neue Artikel
  void notifyProductCreated(String productName) {
    debugPrint('🆕 ProductCatalogEvents: Neuer Artikel erstellt: $productName');
    notifyProductChanged();
  }

  /// Spezielle Benachrichtigung für Artikel-Updates
  void notifyProductUpdated(String productName) {
    debugPrint('✏️ ProductCatalogEvents: Artikel aktualisiert: $productName');
    notifyProductChanged();
  }

  /// Spezielle Benachrichtigung für neue Kategorien
  void notifyCategoryCreated(String categoryName) {
    debugPrint(
      '🆕 ProductCatalogEvents: Neue Kategorie erstellt: $categoryName',
    );
    notifyProductChanged();
  }
}
