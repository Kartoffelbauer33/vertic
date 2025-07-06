import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../helpers/staff_auth_helper.dart';

/// POS-System Endpoint für Session- und Cart-Management
class PosEndpoint extends Endpoint {
  /// Status-Check für POS-System
  Future<String> getStatus(Session session) async {
    return 'POS-System aktiv mit generierten Models';
  }

  /// Test-Funktion: POS-Session Model erstellen (ohne DB)
  Future<PosSession> createTestSession(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    // Erstelle Test-Session ohne DB-Zugriff
    return PosSession(
      staffUserId: staffUserId,
      customerId: null,
      hallId: 1,
      deviceId: 'test_device', // Temporär: Test-Device-ID
      status: 'active',
      totalAmount: 0.0,
      discountAmount: 0.0,
      createdAt: DateTime.now(),
    );
  }

  /// Test-Funktion: POS-CartItem Model erstellen (ohne DB)
  Future<PosCartItem> createTestCartItem(Session session) async {
    return PosCartItem(
      sessionId: 1,
      itemType: 'ticket',
      itemId: 1,
      itemName: 'Test Tageskarte',
      quantity: 1,
      unitPrice: 15.0,
      totalPrice: 15.0,
      discountAmount: 0.0,
      addedAt: DateTime.now(),
    );
  }

  // ==================== SESSION LIFECYCLE ====================

  /// Neue POS-Session erstellen oder aktive Session zurückgeben
  Future<PosSession> createSession(Session session, int? customerId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      // Prüfe ob bereits aktive Session existiert
      final existingSession = await PosSession.db.find(
        session,
        where: (t) =>
            t.staffUserId.equals(staffUserId) & t.status.equals('active'),
        limit: 1,
      );

      if (existingSession.isNotEmpty) {
        return existingSession.first;
      }

      // Neue Session erstellen - verwende korrekte Field-Namen
      final newSession = PosSession(
        staffUserId: staffUserId,
        customerId: customerId,
        hallId: 1, // Standard-Hall-ID, TODO: Dynamisch setzen
        deviceId: 'default_device', // Temporär: Standard-Device-ID
        status: 'active',
        totalAmount: 0.0,
        discountAmount: 0.0,
        createdAt: DateTime.now(),
      );

      final savedSession = await PosSession.db.insertRow(session, newSession);
      session.log('POS-Session erstellt: ${savedSession.id}');
      return savedSession;
    } catch (e) {
      session.log('Fehler beim Erstellen der POS-Session: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Aktive Session für Staff-User abrufen
  Future<PosSession?> getActiveSession(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final sessions = await PosSession.db.find(
      session,
      where: (t) =>
          t.staffUserId.equals(staffUserId) & t.status.equals('active'),
      limit: 1,
    );

    return sessions.isNotEmpty ? sessions.first : null;
  }

  /// Cart-Items einer Session abrufen
  Future<List<PosCartItem>> getCartItems(Session session, int sessionId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    return await PosCartItem.db.find(
      session,
      where: (t) => t.sessionId.equals(sessionId),
      orderBy: (t) => t.addedAt,
    );
  }

  // ==================== CART MANAGEMENT ====================

  /// Item zum Warenkorb hinzufügen (mit korrekten Model-Fields)
  Future<PosCartItem> addToCart(
    Session session,
    int sessionId,
    String itemType,
    int itemId, // Verwende itemId statt separater ticketTypeId/productId
    String itemName,
    double unitPrice,
    int quantity,
  ) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      // Prüfe ob Item bereits im Cart existiert
      final existingItems = await PosCartItem.db.find(
        session,
        where: (t) =>
            t.sessionId.equals(sessionId) &
            t.itemType.equals(itemType) &
            t.itemId.equals(itemId),
        limit: 1,
      );

      if (existingItems.isNotEmpty) {
        // Quantity erhöhen
        final existingItem = existingItems.first;
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
          totalPrice: (existingItem.quantity + quantity) * unitPrice,
        );
        return await PosCartItem.db.updateRow(session, updatedItem);
      } else {
        // Neues Item erstellen
        final newItem = PosCartItem(
          sessionId: sessionId,
          itemType: itemType,
          itemId: itemId,
          itemName: itemName,
          unitPrice: unitPrice,
          quantity: quantity,
          totalPrice: quantity * unitPrice,
          discountAmount: 0.0,
          addedAt: DateTime.now(),
        );
        return await PosCartItem.db.insertRow(session, newItem);
      }
    } catch (e) {
      session.log('Fehler beim Hinzufügen zum Cart: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Item aus Warenkorb entfernen
  Future<void> removeFromCart(Session session, int cartItemId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    await PosCartItem.db.deleteWhere(
      session,
      where: (t) => t.id.equals(cartItemId),
    );
    session.log('Cart-Item entfernt: $cartItemId');
  }

  /// Cart-Item Quantity aktualisieren
  Future<PosCartItem> updateCartItem(
      Session session, int cartItemId, int quantity) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final item = await PosCartItem.db.findById(session, cartItemId);
    if (item == null) {
      throw Exception('Cart-Item nicht gefunden');
    }

    final updatedItem = item.copyWith(
      quantity: quantity,
      totalPrice: quantity * item.unitPrice,
    );

    return await PosCartItem.db.updateRow(session, updatedItem);
  }

  /// Kompletten Warenkorb leeren
  Future<void> clearCart(Session session, int sessionId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    await PosCartItem.db.deleteWhere(
      session,
      where: (t) => t.sessionId.equals(sessionId),
    );
    session.log('Cart geleert für Session: $sessionId');
  }

  // ==================== CHECKOUT & TRANSACTION ====================

  /// Checkout durchführen und Transaction erstellen
  Future<PosTransaction> checkout(
    Session session,
    int sessionId,
    String paymentMethod,
    double paidAmount,
    String? notes,
  ) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      // Session validieren
      final posSession = await PosSession.db.findById(session, sessionId);
      if (posSession == null || posSession.status != 'active') {
        throw Exception('Session nicht aktiv oder nicht gefunden');
      }

      // Cart-Items abrufen
      final cartItems = await PosCartItem.db.find(
        session,
        where: (t) => t.sessionId.equals(sessionId),
      );

      if (cartItems.isEmpty) {
        throw Exception('Keine Items im Warenkorb');
      }

      // Gesamtbetrag berechnen
      final totalAmount = cartItems.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      // Receipt-Nummer generieren
      final receiptNumber = 'R${DateTime.now().millisecondsSinceEpoch}';

      // Transaction erstellen
      final transaction = PosTransaction(
        sessionId: sessionId,
        customerId: posSession.customerId,
        staffUserId: staffUserId,
        hallId: posSession.hallId,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        receiptNumber: receiptNumber,
        items: _cartItemsToJson(cartItems),
        completedAt: DateTime.now(),
      );

      final savedTransaction =
          await PosTransaction.db.insertRow(session, transaction);

      // Session als completed markieren
      final completedSession = posSession.copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
      );
      await PosSession.db.updateRow(session, completedSession);

      session.log(
          'Checkout abgeschlossen: Transaction ${savedTransaction.receiptNumber}');
      return savedTransaction;
    } catch (e) {
      session.log('Fehler beim Checkout: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Session abbrechen
  Future<void> cancelSession(Session session, int sessionId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final posSession = await PosSession.db.findById(session, sessionId);
    if (posSession == null) {
      throw Exception('Session nicht gefunden');
    }

    // Cart leeren
    await clearCart(session, sessionId);

    // Session als cancelled markieren
    final cancelledSession = posSession.copyWith(
      status: 'cancelled',
      completedAt: DateTime.now(),
    );
    await PosSession.db.updateRow(session, cancelledSession);

    session.log('Session abgebrochen: $sessionId');
  }

  // ==================== REPORTING & ANALYTICS ====================

  /// Tagesabschluss-Report erstellen
  Future<Map<String, dynamic>> getDailyReport(
      Session session, DateTime date) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Transactions des Tages
    final allTransactions = await PosTransaction.db.find(session);
    final transactions = allTransactions
        .where((t) =>
            t.completedAt.isAfter(startOfDay) &&
            t.completedAt.isBefore(endOfDay))
        .toList();

    // Statistiken berechnen
    final totalRevenue = transactions.fold<double>(
      0.0,
      (sum, transaction) => sum + transaction.totalAmount,
    );

    final transactionCount = transactions.length;

    return {
      'date': date.toIso8601String(),
      'totalRevenue': totalRevenue,
      'transactionCount': transactionCount,
      'averageTransaction':
          transactionCount > 0 ? totalRevenue / transactionCount : 0.0,
      'transactions': transactions,
    };
  }

  /// Session-Informationen abrufen
  Future<Map<String, dynamic>> getSessionInfo(
      Session session, int sessionId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    final posSession = await PosSession.db.findById(session, sessionId);
    if (posSession == null) {
      throw Exception('Session nicht gefunden');
    }

    final cartItems = await getCartItems(session, sessionId);
    final totalAmount = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    return {
      'session': posSession,
      'cartItems': cartItems,
      'itemCount': cartItems.length,
      'totalAmount': totalAmount,
    };
  }

  // ==================== HELPER METHODS ====================

  /// Konvertiert Cart-Items zu JSON für die Transaction
  String _cartItemsToJson(List<PosCartItem> items) {
    return items
        .map((item) => {
              'type': item.itemType,
              'id': item.itemId,
              'name': item.itemName,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'totalPrice': item.totalPrice,
            })
        .toString();
  }

  // ==================== DEVICE-SPECIFIC SESSION MANAGEMENT ====================

  /// 🖥️ Neue Methode: Alle aktiven Sessions für ein Gerät abrufen
  Future<List<PosSession>> getActiveSessionsForDevice(
      Session session, String deviceId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    return await PosSession.db.find(
      session,
      where: (t) => t.deviceId.equals(deviceId) & t.status.equals('active'),
      orderBy: (t) => t.createdAt,
    );
  }

  /// 🖥️ Neue Methode: Gerätespezifische Session erstellen
  Future<PosSession> createDeviceSession(
      Session session, String deviceId, int? customerId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      final newSession = PosSession(
        staffUserId: staffUserId,
        customerId: customerId,
        hallId: 1, // Standard-Hall-ID
        deviceId: deviceId, // Gerätespezifische ID
        status: 'active',
        totalAmount: 0.0,
        discountAmount: 0.0,
        createdAt: DateTime.now(),
      );

      final savedSession = await PosSession.db.insertRow(session, newSession);
      session.log(
          'Gerätespezifische POS-Session erstellt: ${savedSession.id} für Gerät: $deviceId');
      return savedSession;
    } catch (e) {
      session.log('Fehler beim Erstellen der gerätespezifischen Session: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// 🖥️ Neue Methode: Multi-Cart Daten für Gerät wiederherstellen - vereinfacht
  Future<List<PosSession>> restoreDeviceCartState(
      Session session, String deviceId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      // Alle aktiven Sessions für dieses Gerät zurückgeben
      final activeSessions =
          await getActiveSessionsForDevice(session, deviceId);

      session.log(
          'Geräte-Status wiederhergestellt: ${activeSessions.length} Sessions für Gerät $deviceId');

      return activeSessions;
    } catch (e) {
      session.log('Fehler beim Wiederherstellen des Geräte-Status: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// 🖥️ Neue Methode: Kassenabschluss für komplettes Gerät
  Future<void> closeDeviceDay(Session session, String deviceId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      // Alle aktiven Sessions für dieses Gerät schließen
      final activeSessions =
          await getActiveSessionsForDevice(session, deviceId);

      for (final posSession in activeSessions) {
        // Warenkörbe leeren
        await clearCart(session, posSession.id!);

        // Session als abgeschlossen markieren
        final closedSession = posSession.copyWith(
          status: 'day_closed',
          completedAt: DateTime.now(),
        );
        await PosSession.db.updateRow(session, closedSession);
      }

      session.log(
          'Kassenabschluss für Gerät $deviceId: ${activeSessions.length} Sessions geschlossen');
    } catch (e) {
      session.log('Fehler beim Kassenabschluss: $e', level: LogLevel.error);
      rethrow;
    }
  }
}
