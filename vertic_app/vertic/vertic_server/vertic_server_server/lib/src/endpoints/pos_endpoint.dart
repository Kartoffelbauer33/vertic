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

  /// Cart-Items einer Session abrufen (Performance-optimiert)
  Future<List<PosCartItem>> getCartItems(Session session, int sessionId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    // 🚀 PERFORMANCE: Direkte DB-Abfrage ohne Debug-Overhead
    return await PosCartItem.db.find(
      session,
      where: (t) => t.sessionId.equals(sessionId),
      orderBy: (t) => t.addedAt,
    );
  }

  /// Cart-Items einer Session abrufen (Schnelle Version ohne Auth-Check für interne Calls)
  Future<List<PosCartItem>> getCartItemsFast(Session session, int sessionId) async {
    // 🚀 PERFORMANCE: Optimierte Version für häufige interne Aufrufe
    return await PosCartItem.db.find(
      session,
      where: (t) => t.sessionId.equals(sessionId),
      orderBy: (t) => t.addedAt,
    );
  }

  // ==================== 🧹 AUTOMATIC CLEANUP METHODS ====================

  /// **🧹 NEUE GESCHÄFTSLOGIK: Session-Bereinigung mit Status-System**
  ///
  /// **STATUS-DEFINITIONEN:**
  /// - 'active': Aktive Sessions die bearbeitet werden
  /// - 'completed': Bezahlte Sessions (für History behalten)
  /// - 'abandoned': Leere Sessions ohne Kunde (können gelöscht werden)
  /// - 'deleted': Gelöschte Sessions (können aus DB entfernt werden)
  ///
  /// **LÖSCHREGELN:**
  /// 1. Sessions mit totalAmount > 0 UND completedAt: Status 'completed' (History)
  /// 2. Sessions ohne Artikel UND ohne Kunde: Status 'abandoned' → Aus DB löschen
  /// 3. Sessions mit Kunde aber ohne Artikel: Behalten (Kunde könnte zurückkommen)
  /// 4. Sessions mit Artikeln: Behalten (unvollständiger Einkauf)
  Future<Map<String, int>> cleanupSessionsWithBusinessLogic(
      Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      session
          .log('🏢 BUSINESS-LOGIC: Starte intelligente Session-Bereinigung...');

      // **📊 STATISTIKEN**
      final stats = {
        'total': 0,
        'kept_active': 0,
        'kept_with_customer': 0,
        'kept_with_items': 0,
        'marked_abandoned': 0,
        'deleted_from_db': 0,
        'marked_completed': 0,
      };

      // **🔍 ALLE AKTIVEN SESSIONS LADEN**
      final allSessions = await PosSession.db.find(
        session,
        where: (t) =>
            t.staffUserId.equals(staffUserId) & t.status.equals('active'),
        orderBy: (t) => t.createdAt,
      );

      stats['total'] = allSessions.length;
      
      // 🚀 PERFORMANCE: Debug-Ausgaben nur bei Bedarf
      const bool enableBusinessLogicDebug = false; // Setze auf true für Debugging
      
      if (enableBusinessLogicDebug) {
        session.log(
            '🔍 BUSINESS-LOGIC: ${allSessions.length} aktive Sessions gefunden');
      }

      for (final posSession in allSessions) {
        if (enableBusinessLogicDebug) {
          session.log(
              '🔍 ANALYSE Session ${posSession.id}: Kunde=${posSession.customerId}, Total=${posSession.totalAmount}');
        }

        // **📦 CART-ITEMS LADEN (Performance-optimiert)**
        final cartItems = await getCartItemsFast(session, posSession.id!);

        final hasItems = cartItems.isNotEmpty;
        final hasCustomer = posSession.customerId != null;
        final isPaid =
            posSession.totalAmount > 0 && posSession.completedAt != null;
        final isEmpty = !hasItems && !hasCustomer;

        if (enableBusinessLogicDebug) {
          session.log(
              '🔍 ANALYSE Session ${posSession.id}: Items=${cartItems.length}, Customer=$hasCustomer, Paid=$isPaid, Empty=$isEmpty');
        }

        // **🎯 BUSINESS-RULE 1: Bezahlte Sessions → History**
        if (isPaid) {
          final completedSession = posSession.copyWith(
            status: 'completed',
            completedAt: posSession.completedAt ?? DateTime.now(),
          );
          await PosSession.db.updateRow(session, completedSession);
          stats['marked_completed'] = (stats['marked_completed']! + 1);
          session.log(
              '💰 COMPLETED: Session ${posSession.id} als bezahlt markiert (History)');
          continue;
        }

        // **🎯 BUSINESS-RULE 2: Komplett leere Sessions → Löschen**
        if (isEmpty) {
          try {
            // 1. Cart-Items löschen (falls welche da sind)
            await PosCartItem.db.deleteWhere(
              session,
              where: (t) => t.sessionId.equals(posSession.id!),
            );

            // 2. Session komplett aus DB löschen
            await PosSession.db.deleteWhere(
              session,
              where: (t) => t.id.equals(posSession.id!),
            );

            stats['deleted_from_db'] = (stats['deleted_from_db']! + 1);
            session.log(
                '🗑️ DELETED: Session ${posSession.id} komplett aus DB gelöscht (leer)');
          } catch (e) {
            session
                .log('❌ FEHLER beim Löschen von Session ${posSession.id}: $e');
            // Fallback: Als abandoned markieren
            final abandonedSession = posSession.copyWith(status: 'abandoned');
            await PosSession.db.updateRow(session, abandonedSession);
            stats['marked_abandoned'] = (stats['marked_abandoned']! + 1);
            session.log(
                '⚠️ FALLBACK: Session ${posSession.id} als abandoned markiert');
          }
          continue;
        }

        // **🎯 BUSINESS-RULE 3: Session mit Kunde aber ohne Artikel → Behalten**
        if (hasCustomer && !hasItems) {
          stats['kept_with_customer'] = (stats['kept_with_customer']! + 1);
          session.log(
              '👤 KEPT: Session ${posSession.id} behalten (Kunde ohne Artikel)');
          continue;
        }

        // **🎯 BUSINESS-RULE 4: Session mit Artikeln → Behalten**
        if (hasItems) {
          stats['kept_with_items'] = (stats['kept_with_items']! + 1);
          session
              .log('📦 KEPT: Session ${posSession.id} behalten (hat Artikel)');
          continue;
        }

        // **🎯 DEFAULT: Session bleibt aktiv**
        stats['kept_active'] = (stats['kept_active']! + 1);
        session.log('✅ ACTIVE: Session ${posSession.id} bleibt aktiv');
      }

      // **📊 STATISTIKEN AUSGEBEN**
      session.log('📊 BUSINESS-LOGIC Ergebnis:');
      session.log('   • Total analysiert: ${stats['total']}');
      session.log('   • Behalten (aktiv): ${stats['kept_active']}');
      session.log('   • Behalten (mit Kunde): ${stats['kept_with_customer']}');
      session.log('   • Behalten (mit Artikeln): ${stats['kept_with_items']}');
      session.log('   • Als bezahlt markiert: ${stats['marked_completed']}');
      session.log('   • Als abandoned markiert: ${stats['marked_abandoned']}');
      session.log('   • Komplett aus DB gelöscht: ${stats['deleted_from_db']}');

      return stats;
    } catch (e) {
      session.log('❌ BUSINESS-LOGIC Fehler: $e', level: LogLevel.error);
      return {'error': 1};
    }
  }

  /// **🧹 VEREINFACHTE Bereinigung - verwendet neue Business-Logic**
  Future<int> cleanupEmptySessions(Session session) async {
    final stats = await cleanupSessionsWithBusinessLogic(session);
    return stats['deleted_from_db'] ?? 0;
  }

  /// **🚀 App-Start Initialisierung**
  ///
  /// Stellt Sessions nach App-Neustart wieder her:
  /// 1. Bereinigt zuerst leere Sessions
  /// 2. Lädt aktive Sessions mit Inhalt
  /// 3. Erstellt neue Session falls keine vorhanden
  Future<List<PosSession>> initializeAppStart(
      Session session, String deviceId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      session.log(
          '🚀 DEBUG: App-Start Initialisierung für Gerät: $deviceId, Staff-User: $staffUserId');

      // **🔍 DEBUG: Sessions VOR Bereinigung zählen**
      final sessionsBeforeCleanup = await PosSession.db.find(
        session,
        where: (t) =>
            t.staffUserId.equals(staffUserId) &
            t.status.equals('active') &
            t.deviceId.equals(deviceId),
      );
      // 🚀 PERFORMANCE: Debug-Ausgaben nur bei Bedarf
      const bool enableDebugLogging = false; // Setze auf true für Debugging
      
      if (enableDebugLogging) {
        session.log(
            '🔍 DEBUG: Sessions VOR Bereinigung: ${sessionsBeforeCleanup.length}');
      }

      // 1. Zuerst leere Sessions bereinigen (wirklich löschen!)
      final cleanedCount = await cleanupEmptySessions(session);
      if (enableDebugLogging) {
        session.log('🧹 DEBUG: $cleanedCount leere Sessions wirklich gelöscht');
      }

      // **🔍 Sessions NACH Bereinigung laden (ohne Debug-Overhead)**
      final activeSessions = await PosSession.db.find(
        session,
        where: (t) =>
            t.staffUserId.equals(staffUserId) &
            t.status.equals('active') &
            t.deviceId.equals(deviceId),
        orderBy: (t) => t.createdAt,
      );

      if (enableDebugLogging) {
        session.log(
            '📋 DEBUG: ${activeSessions.length} aktive Sessions mit Inhalt gefunden nach Bereinigung');
        
        // **🔍 DEBUG: Jede Session detailliert loggen (nur wenn Debug aktiv)**
        for (final posSession in activeSessions) {
          final cartItems = await getCartItemsFast(session, posSession.id!);
          session.log(
              '📋 DEBUG: Session ${posSession.id} - ${cartItems.length} Items, Kunde: ${posSession.customerId}, Device: ${posSession.deviceId}');
        }
      }

      // 3. Falls keine Sessions vorhanden, neue erstellen
      if (activeSessions.isEmpty) {
        session.log('➕ DEBUG: Keine aktiven Sessions - erstelle neue Session');
        final newSession = await createDeviceSession(session, deviceId, null);
        session.log('➕ DEBUG: Neue Session erstellt: ${newSession.id}');
        return [newSession];
      }

      session.log(
          '✅ DEBUG: App-Start Initialisierung abgeschlossen - ${activeSessions.length} Sessions zurückgegeben');
      return activeSessions;
    } catch (e) {
      session.log('❌ DEBUG: Fehler bei App-Start Initialisierung: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// **📱 Stellt sicher, dass mindestens eine aktive Session existiert**
  ///
  /// Für Kassen-Apps: Garantiert, dass immer ein Warenkorb verfügbar ist
  Future<PosSession> ensureActiveSession(
      Session session, String deviceId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      // Prüfe ob bereits aktive Session für dieses Gerät existiert
      final existingSessions = await PosSession.db.find(
        session,
        where: (t) =>
            t.staffUserId.equals(staffUserId) &
            t.status.equals('active') &
            t.deviceId.equals(deviceId),
        limit: 1,
      );

      if (existingSessions.isNotEmpty) {
        session.log(
            '✅ Aktive Session bereits vorhanden: ${existingSessions.first.id}');
        return existingSessions.first;
      }

      // Keine aktive Session - neue erstellen
      session.log('➕ Erstelle neue Session für kontinuierliches Kassieren');
      return await createDeviceSession(session, deviceId, null);
    } catch (e) {
      session.log('❌ Fehler bei Session-Sicherstellung: $e',
          level: LogLevel.error);
      rethrow;
    }
  }

  /// **🔍 Prüft ob eine Session leer ist**
  ///
  /// Session ist leer wenn:
  /// - Keine Cart-Items vorhanden UND
  /// - Kein Kunde zugeordnet
  Future<bool> _isSessionEmpty(Session session, PosSession posSession) async {
    try {
      // Prüfe ob Kunde zugeordnet ist
      if (posSession.customerId != null) {
        return false; // Session hat Kunde - nicht leer
      }

      // Prüfe ob Cart-Items vorhanden sind
      final cartItems = await PosCartItem.db.find(
        session,
        where: (t) => t.sessionId.equals(posSession.id!),
        limit: 1,
      );

      // Session ist leer wenn keine Cart-Items vorhanden
      return cartItems.isEmpty;
    } catch (e) {
      session.log('❌ Fehler bei Session-Leer-Prüfung: $e',
          level: LogLevel.error);
      // Im Fehlerfall als nicht-leer behandeln (sicherer)
      return false;
    }
  }

  /// **🏪 App-Schließen Bereinigung**
  ///
  /// Wird beim ordnungsgemäßen App-Schließen aufgerufen
  Future<void> onAppClosing(Session session, String deviceId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      session.log('🏪 App wird geschlossen - Bereinigung für Gerät: $deviceId');

      // Bereinige alle leeren Sessions
      final cleanedCount = await cleanupEmptySessions(session);

      session.log(
          '✅ App-Schließen Bereinigung abgeschlossen: $cleanedCount Sessions bereinigt');
    } catch (e) {
      session.log('❌ Fehler bei App-Schließen Bereinigung: $e',
          level: LogLevel.error);
    }
  }

  /// **🧹 ALIAS: Bereinigt Sessions für ein bestimmtes Gerät**
  ///
  /// Wird vom generierten Code referenziert
  Future<int> cleanupDeviceSessions(Session session) async {
    return await cleanupEmptySessions(session);
  }

  /// **🧹 NEUE METHODE: Komplett-Bereinigung aller verwaisten Sessions**
  ///
  /// Diese Methode kann einmalig aufgerufen werden um alle alten,
  /// verwaisten Sessions und Cart-Items aus der Datenbank zu entfernen.
  /// Besonders nützlich nach der Umstellung auf echtes Löschen.
  Future<Map<String, int>> performCompleteCleanup(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      session
          .log('🧹 Starte KOMPLETT-BEREINIGUNG aller verwaisten Sessions...');

      int deletedSessions = 0;
      int deletedCartItems = 0;
      int processedSessions = 0;

      // 1. Alle Sessions des Staff-Users laden (egal welcher Status)
      final allSessions = await PosSession.db.find(
        session,
        where: (t) => t.staffUserId.equals(staffUserId),
      );

      session.log('🔍 Gefunden: ${allSessions.length} Sessions zum Prüfen');

      for (final posSession in allSessions) {
        processedSessions++;

        // Session ist leer wenn sie keine Cart-Items UND keinen Kunden hat
        final isEmpty = await _isSessionEmpty(session, posSession);

        if (isEmpty) {
          try {
            // Zuerst alle Cart-Items dieser Session löschen
            final cartItemsDeleted = await PosCartItem.db.deleteWhere(
              session,
              where: (t) => t.sessionId.equals(posSession.id!),
            );

            // Dann die Session selbst löschen
            final sessionDeleted = await PosSession.db.deleteWhere(
              session,
              where: (t) => t.id.equals(posSession.id!),
            );

            if (sessionDeleted.isNotEmpty) {
              deletedSessions++;
              deletedCartItems += cartItemsDeleted.length;
              session.log(
                  '🗑️ Session ${posSession.id} (${posSession.status}) + ${cartItemsDeleted.length} Cart-Items gelöscht');
            }
          } catch (e) {
            session.log(
                '❌ Fehler beim Löschen von Session ${posSession.id}: $e',
                level: LogLevel.error);
          }
        } else {
          session.log(
              '✅ Session ${posSession.id} behalten - hat ${posSession.customerId != null ? "Kunde" : "Artikel"}');
        }
      }

      // 2. Zusätzlich: Verwaiste Cart-Items ohne gültige Session löschen
      final allCartItems = await PosCartItem.db.find(session);
      int orphanedCartItems = 0;

      for (final cartItem in allCartItems) {
        final sessionExists =
            await PosSession.db.findById(session, cartItem.sessionId);
        if (sessionExists == null) {
          try {
            await PosCartItem.db.deleteWhere(
              session,
              where: (t) => t.id.equals(cartItem.id!),
            );
            orphanedCartItems++;
          } catch (e) {
            session.log(
                '❌ Fehler beim Löschen von verwaister Cart-Item ${cartItem.id}: $e');
          }
        }
      }

      final results = {
        'processedSessions': processedSessions,
        'deletedSessions': deletedSessions,
        'deletedCartItems': deletedCartItems,
        'orphanedCartItems': orphanedCartItems,
        'remainingSessions': allSessions.length - deletedSessions,
      };

      session.log('✅ KOMPLETT-BEREINIGUNG abgeschlossen:');
      session.log('   • Geprüfte Sessions: $processedSessions');
      session.log('   • Gelöschte Sessions: $deletedSessions');
      session.log('   • Gelöschte Cart-Items: $deletedCartItems');
      session.log('   • Verwaiste Cart-Items: $orphanedCartItems');
      session
          .log('   • Verbleibende Sessions: ${results['remainingSessions']}');

      return results;
    } catch (e) {
      session.log('❌ Fehler bei KOMPLETT-BEREINIGUNG: $e',
          level: LogLevel.error);
      rethrow;
    }
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
      session.log('🔄 Stelle Geräte-Status wieder her für: $deviceId');

      // 🧹 KRITISCH: Zuerst Bereinigung BEVOR Sessions geladen werden
      final cleanedCount = await cleanupEmptySessions(session);
      session
          .log('🧹 Vorab-Bereinigung: $cleanedCount leere Sessions gelöscht');

      // Nur noch Sessions mit Inhalt laden
      final activeSessions = await PosSession.db.find(
        session,
        where: (t) =>
            t.staffUserId.equals(staffUserId) &
            t.status.equals('active') &
            t.deviceId.equals(deviceId),
        orderBy: (t) => t.createdAt,
      );

      // ✅ ZUSÄTZLICHE VALIDIERUNG: Prüfe jede Session nochmals auf Inhalt
      final validatedSessions = <PosSession>[];

      for (final posSession in activeSessions) {
        final isEmpty = await _isSessionEmpty(session, posSession);
        if (!isEmpty) {
          validatedSessions.add(posSession);
          session.log('✅ Session ${posSession.id} hat Inhalt - behalten');
        } else {
          session
              .log('🗑️ Session ${posSession.id} ist doch leer - entferne sie');
          // Sofortiges Löschen falls doch leer
          try {
            await PosCartItem.db.deleteWhere(
              session,
              where: (t) => t.sessionId.equals(posSession.id!),
            );
            await PosSession.db.deleteWhere(
              session,
              where: (t) => t.id.equals(posSession.id!),
            );
          } catch (e) {
            session.log(
                '⚠️ Fehler beim Nachlöschen von Session ${posSession.id}: $e');
          }
        }
      }

      session.log(
          '🔄 Geräte-Status wiederhergestellt: ${validatedSessions.length} gültige Sessions für Gerät $deviceId');

      return validatedSessions;
    } catch (e) {
      session.log('❌ Fehler beim Wiederherstellen des Geräte-Status: $e',
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

  /// **🗑️ EXPLICIT: Warenkorb explizit löschen**
  ///
  /// Löscht eine Session komplett aus der DB (nur bei leeren Sessions erlaubt)
  Future<bool> deleteCart(Session session, int sessionId) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      // Session laden und prüfen
      final posSession = await PosSession.db.findById(session, sessionId);
      if (posSession == null) {
        session.log('❌ Session $sessionId nicht gefunden');
        return false;
      }

      // Sicherheitscheck: Nur eigene Sessions löschen
      if (posSession.staffUserId != staffUserId) {
        session.log('❌ Keine Berechtigung für Session $sessionId');
        return false;
      }

      // Cart-Items prüfen
      final cartItems = await PosCartItem.db.find(
        session,
        where: (t) => t.sessionId.equals(sessionId),
      );

      // Sicherheitscheck: Keine bezahlten Sessions löschen
      if (posSession.totalAmount > 0 && posSession.completedAt != null) {
        session.log(
            '❌ Bezahlte Session $sessionId kann nicht gelöscht werden (History)');
        return false;
      }

      session.log(
          '🗑️ EXPLICIT DELETE: Session $sessionId - ${cartItems.length} Items, Kunde: ${posSession.customerId}');

      // 1. Cart-Items löschen
      await PosCartItem.db.deleteWhere(
        session,
        where: (t) => t.sessionId.equals(sessionId),
      );

      // 2. Session löschen
      await PosSession.db.deleteWhere(
        session,
        where: (t) => t.id.equals(sessionId),
      );

      session.log(
          '✅ EXPLICIT DELETE: Session $sessionId komplett aus DB gelöscht');
      return true;
    } catch (e) {
      session.log('❌ EXPLICIT DELETE Fehler: $e', level: LogLevel.error);
      return false;
    }
  }

  /// **💰 EXPLICIT: Session als bezahlt markieren**
  ///
  /// Markiert eine Session als 'completed' für die History
  Future<bool> markSessionCompleted(Session session, int sessionId,
      String paymentMethod, double totalAmount) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      final posSession = await PosSession.db.findById(session, sessionId);
      if (posSession == null || posSession.staffUserId != staffUserId) {
        return false;
      }

      final completedSession = posSession.copyWith(
        status: 'completed',
        paymentMethod: paymentMethod,
        totalAmount: totalAmount,
        completedAt: DateTime.now(),
      );

      await PosSession.db.updateRow(session, completedSession);
      session.log(
          '💰 Session $sessionId als bezahlt markiert: $totalAmount via $paymentMethod');
      return true;
    } catch (e) {
      session.log('❌ Fehler beim Markieren als bezahlt: $e',
          level: LogLevel.error);
      return false;
    }
  }

  /// **📊 STATUS: Session-Status anzeigen**
  ///
  /// Gibt detaillierte Informationen über Sessions zurück
  Future<Map<String, dynamic>> getSessionStats(Session session) async {
    final staffUserId =
        await StaffAuthHelper.getAuthenticatedStaffUserId(session);
    if (staffUserId == null) {
      throw Exception('Authentication erforderlich');
    }

    try {
      // Alle Sessions des Staff-Users laden
      final allSessions = await PosSession.db.find(
        session,
        where: (t) => t.staffUserId.equals(staffUserId),
      );

      final stats = {
        'total': allSessions.length,
        'active': 0,
        'completed': 0,
        'abandoned': 0,
        'deleted': 0,
        'with_customer': 0,
        'with_items': 0,
        'empty': 0,
      };

      for (final posSession in allSessions) {
        // Status zählen
        switch (posSession.status) {
          case 'active':
            stats['active'] = (stats['active']! + 1);
            break;
          case 'completed':
            stats['completed'] = (stats['completed']! + 1);
            break;
          case 'abandoned':
            stats['abandoned'] = (stats['abandoned']! + 1);
            break;
          case 'deleted':
            stats['deleted'] = (stats['deleted']! + 1);
            break;
        }

        // Inhalt analysieren
        if (posSession.customerId != null) {
          stats['with_customer'] = (stats['with_customer']! + 1);
        }

        final cartItems = await PosCartItem.db.find(
          session,
          where: (t) => t.sessionId.equals(posSession.id!),
        );

        if (cartItems.isNotEmpty) {
          stats['with_items'] = (stats['with_items']! + 1);
        }

        if (cartItems.isEmpty && posSession.customerId == null) {
          stats['empty'] = (stats['empty']! + 1);
        }
      }

      session.log('📊 SESSION-STATS: $stats');
      return stats;
    } catch (e) {
      session.log('❌ SESSION-STATS Fehler: $e', level: LogLevel.error);
      return {'error': e.toString()};
    }
  }
}
