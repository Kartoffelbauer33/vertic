import 'package:serverpod/serverpod.dart';
import 'package:vertic_server_server/src/generated/protocol.dart';

class TicketTypeEndpoint extends Endpoint {
  // Alle Tickettypen abrufen
  Future<List<TicketType>> getAllTicketTypes(Session session) async {
    try {
      final types = await TicketType.db.find(
        session,
        orderBy: (t) => t.name,
      );
      return types;
    } catch (e) {
      session.log('Fehler beim Abrufen der Tickettypen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Einzelnen Tickettyp abrufen
  Future<TicketType?> getTicketTypeById(Session session, int id) async {
    try {
      return await TicketType.db.findById(session, id);
    } catch (e) {
      session.log('Fehler beim Abrufen des Tickettyps: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Neuen Tickettyp erstellen
  Future<TicketType?> createTicketType(
      Session session, TicketType ticketType) async {
    try {
      final now = DateTime.now().toUtc();
      ticketType.createdAt = now;
      ticketType.updatedAt = now;

      final savedType = await TicketType.db.insertRow(session, ticketType);
      return savedType;
    } catch (e) {
      session.log('Fehler beim Erstellen des Tickettyps: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Tickettyp aktualisieren
  Future<TicketType?> updateTicketType(
      Session session, TicketType ticketType) async {
    try {
      ticketType.updatedAt = DateTime.now().toUtc();
      return await TicketType.db.updateRow(session, ticketType);
    } catch (e) {
      session.log('Fehler beim Aktualisieren des Tickettyps: $e',
          level: LogLevel.error);
      return null;
    }
  }

  // Tickettyp löschen
  Future<bool> deleteTicketType(Session session, int id) async {
    try {
      await TicketType.db.deleteWhere(session, where: (t) => t.id.equals(id));
      return true;
    } catch (e) {
      session.log('Fehler beim Löschen des Tickettyps: $e',
          level: LogLevel.error);
      return false;
    }
  }

  // Alle punktebasierten Tickettypen abrufen
  Future<List<TicketType>> getPointBasedTicketTypes(Session session) async {
    try {
      final types = await TicketType.db.find(
        session,
        where: (t) => t.isPointBased.equals(true),
        orderBy: (t) => t.name,
      );
      return types;
    } catch (e) {
      session.log('Fehler beim Abrufen der punktebasierten Tickettypen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Alle abonnementbasierten Tickettypen abrufen
  Future<List<TicketType>> getSubscriptionTicketTypes(Session session) async {
    try {
      final types = await TicketType.db.find(
        session,
        where: (t) => t.isSubscription.equals(true),
        orderBy: (t) => t.name,
      );
      return types;
    } catch (e) {
      session.log('Fehler beim Abrufen der abonnementbasierten Tickettypen: $e',
          level: LogLevel.error);
      return [];
    }
  }

  // Neue Ticket-Typen hinzufügen
  Future<bool> createDefaultTicketTypes(Session session) async {
    try {
      // Prüfe ob bereits Ticket-Typen existieren
      final existingTypes = await TicketType.db.find(session);
      if (existingTypes.isNotEmpty) {
        session.log('Ticket-Typen bereits vorhanden, überspringe Erstellung');
        return true;
      }

      final now = DateTime.now().toUtc();

      // Standard Ticket-Typen erstellen
      final ticketTypes = [
        // Bestehende Tageskarten
        TicketType(
          name: 'Tageskarte Kind',
          description: 'Einmaliger Besuch für Kinder bis 12 Jahre',
          validityPeriod: 1,
          defaultPrice: 8.0,
          isPointBased: false,
          defaultPoints: null,
          isSubscription: false,
          billingInterval: null,
          createdAt: now,
        ),
        TicketType(
          name: 'Tageskarte Jugend',
          description: 'Einmaliger Besuch für Jugendliche 13-17 Jahre',
          validityPeriod: 1,
          defaultPrice: 12.0,
          isPointBased: false,
          defaultPoints: null,
          isSubscription: false,
          billingInterval: null,
          createdAt: now,
        ),
        TicketType(
          name: 'Tageskarte Erwachsen',
          description: 'Einmaliger Besuch für Erwachsene',
          validityPeriod: 1,
          defaultPrice: 14.0,
          isPointBased: false,
          defaultPoints: null,
          isSubscription: false,
          billingInterval: null,
          createdAt: now,
        ),
        TicketType(
          name: 'Tageskarte Senior',
          description: 'Einmaliger Besuch für Senioren ab 65',
          validityPeriod: 1,
          defaultPrice: 12.0,
          isPointBased: false,
          defaultPoints: null,
          isSubscription: false,
          billingInterval: null,
          createdAt: now,
        ),

        // Neue Jahreskarten
        TicketType(
          name: 'Jahreskarte Kind',
          description: 'Unbegrenzter Zugang für 1 Jahr - Kinder bis 12 Jahre',
          validityPeriod: 365,
          defaultPrice: 250.0,
          isPointBased: false,
          defaultPoints: null,
          isSubscription: true,
          billingInterval: 365,
          createdAt: now,
        ),
        TicketType(
          name: 'Jahreskarte Jugend',
          description:
              'Unbegrenzter Zugang für 1 Jahr - Jugendliche 13-17 Jahre',
          validityPeriod: 365,
          defaultPrice: 380.0,
          isPointBased: false,
          defaultPoints: null,
          isSubscription: true,
          billingInterval: 365,
          createdAt: now,
        ),
        TicketType(
          name: 'Jahreskarte Erwachsen',
          description: 'Unbegrenzter Zugang für 1 Jahr - Erwachsene',
          validityPeriod: 365,
          defaultPrice: 450.0,
          isPointBased: false,
          defaultPoints: null,
          isSubscription: true,
          billingInterval: 365,
          createdAt: now,
        ),
        TicketType(
          name: 'Jahreskarte Senior',
          description: 'Unbegrenzter Zugang für 1 Jahr - Senioren ab 65',
          validityPeriod: 365,
          defaultPrice: 380.0,
          isPointBased: false,
          defaultPoints: null,
          isSubscription: true,
          billingInterval: 365,
          createdAt: now,
        ),

        // Neue Punktekarten
        TicketType(
          name: 'Punktekarte Kind',
          description: '11 Besuche zum Preis von 10 - Kinder bis 12 Jahre',
          validityPeriod: 365, // 1 Jahr gültig
          defaultPrice: 80.0, // 10 Besuche à 8€
          isPointBased: true,
          defaultPoints: 11,
          isSubscription: false,
          billingInterval: null,
          createdAt: now,
        ),
        TicketType(
          name: 'Punktekarte Jugend',
          description: '11 Besuche zum Preis von 10 - Jugendliche 13-17 Jahre',
          validityPeriod: 365, // 1 Jahr gültig
          defaultPrice: 120.0, // 10 Besuche à 12€
          isPointBased: true,
          defaultPoints: 11,
          isSubscription: false,
          billingInterval: null,
          createdAt: now,
        ),
        TicketType(
          name: 'Punktekarte Erwachsen',
          description: '11 Besuche zum Preis von 10 - Erwachsene',
          validityPeriod: 365, // 1 Jahr gültig
          defaultPrice: 140.0, // 10 Besuche à 14€
          isPointBased: true,
          defaultPoints: 11,
          isSubscription: false,
          billingInterval: null,
          createdAt: now,
        ),
        TicketType(
          name: 'Punktekarte Senior',
          description: '11 Besuche zum Preis von 10 - Senioren ab 65',
          validityPeriod: 365, // 1 Jahr gültig
          defaultPrice: 120.0, // 10 Besuche à 12€
          isPointBased: true,
          defaultPoints: 11,
          isSubscription: false,
          billingInterval: null,
          createdAt: now,
        ),

        // Bestehende Sondertickets
        TicketType(
          name: 'Familienkarte',
          description: 'Für Familien mit Kindern',
          validityPeriod: 1,
          defaultPrice: 25.0,
          isPointBased: false,
          defaultPoints: null,
          isSubscription: false,
          billingInterval: null,
          createdAt: now,
        ),
        TicketType(
          name: 'Gruppenkarte',
          description: 'Für Gruppen ab 5 Personen',
          validityPeriod: 1,
          defaultPrice: 9.0,
          isPointBased: false,
          defaultPoints: null,
          isSubscription: false,
          billingInterval: null,
          createdAt: now,
        ),
      ];

      // Alle Ticket-Typen in die Datenbank einfügen
      for (final ticketType in ticketTypes) {
        await TicketType.db.insertRow(session, ticketType);
      }

      session.log(
          '${ticketTypes.length} Standard-Ticket-Typen erfolgreich erstellt');
      return true;
    } catch (e) {
      session.log('Fehler beim Erstellen der Standard-Ticket-Typen: $e',
          level: LogLevel.error);
      return false;
    }
  }
}
